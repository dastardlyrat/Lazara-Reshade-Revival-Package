// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#include "ReShade.fxh"

uniform float CAMERA_OBSCURA_COLOR_CaptureLumaFloorV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Color Cache / Capture"; ui_label = "Capture Luma Floor"; ui_min = 0.001; ui_max = 0.100; ui_step = 0.001; ui_tooltip = "Minimum source luma used to normalize stored chroma.\nDark pixels fade out below this floor to prevent unstable color ratios."; > = 0.020;

uniform float CAMERA_OBSCURA_COLOR_StoredRelativeLimitV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Color Cache / Capture"; ui_label = "Stored Relative Chroma Limit"; ui_min = 0.25; ui_max = 8.00; ui_step = 0.05; ui_tooltip = "Maximum signed source chroma stored relative to source luma.\nContains highly saturated or nearly black capture values."; > = 4.00;

uniform bool CAMERA_OBSCURA_COLOR_ReapplyEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / Stabilized Color Cache / Reapply"; ui_label = "Enable Stored Color Reapply"; ui_tooltip = "Blends current chroma toward the same-frame captured chroma while preserving current luma.\nOff returns the current source image exactly."; > = true;

uniform float CAMERA_OBSCURA_COLOR_ReapplyStrengthV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Color Cache / Reapply"; ui_label = "Stored Color Reapply Strength"; ui_min = 0.00; ui_max = 2.00; ui_step = 0.01; ui_tooltip = "Zero leaves current color unchanged.\nOne targets the captured relative chroma at the current luma."; > = 1.00;

uniform float CAMERA_OBSCURA_COLOR_AppliedLimitV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Color Cache / Reapply"; ui_label = "Reapplied Color Limit"; ui_min = 0.001; ui_max = 1.000; ui_step = 0.001; ui_tooltip = "Maximum per-channel color correction before gamut protection.\nThis independently contains high reapply strengths."; > = 0.250;

uniform int CAMERA_OBSCURA_COLOR_ViewV1
< ui_type = "combo"; ui_category = "Camera Obscura / Stabilized Color Cache / Reapply"; ui_label = "Color Reapply View"; ui_items = "Reapplied Image\0Source Before Reapply\0Stored Relative Chroma\0Cache Freshness\0Applied Difference (16x)\0Applied Signed Color\0"; ui_tooltip = "Stored Relative Chroma and Applied Signed Color encode zero as middle gray.\nCache Freshness must be green when Capture ran earlier in the same frame."; > = 0;

uniform float CAMERA_OBSCURA_COLOR_FrameCount
< source = "framecount"; >;

texture2D CAMERA_OBSCURA_COLOR_CacheTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D CAMERA_OBSCURA_COLOR_CacheSampler
{
    Texture = CAMERA_OBSCURA_COLOR_CacheTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

float CAMERA_OBSCURA_COLOR_Luma(float3 rgb)
{
    return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

float CAMERA_OBSCURA_COLOR_FrameStamp()
{
    return frac(CAMERA_OBSCURA_COLOR_FrameCount / 1024.0);
}

float CAMERA_OBSCURA_COLOR_CacheFresh(float cachedStamp)
{
    float difference = abs(cachedStamp - CAMERA_OBSCURA_COLOR_FrameStamp());
    difference = min(difference, 1.0 - difference);
    float frameReady = step(0.5, CAMERA_OBSCURA_COLOR_FrameCount);
    return frameReady * (1.0 - step(0.0006, difference));
}

float CAMERA_OBSCURA_COLOR_GamutScale(float3 source, float3 delta)
{
    float scaleValue = 1.0;
    if (delta.r > 0.000001) scaleValue = min(scaleValue, (1.0 - source.r) / delta.r);
    if (delta.r < -0.000001) scaleValue = min(scaleValue, source.r / -delta.r);
    if (delta.g > 0.000001) scaleValue = min(scaleValue, (1.0 - source.g) / delta.g);
    if (delta.g < -0.000001) scaleValue = min(scaleValue, source.g / -delta.g);
    if (delta.b > 0.000001) scaleValue = min(scaleValue, (1.0 - source.b) / delta.b);
    if (delta.b < -0.000001) scaleValue = min(scaleValue, source.b / -delta.b);
    return saturate(scaleValue);
}

float4 CAMERA_OBSCURA_COLOR_Capture_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float sourceLuma = CAMERA_OBSCURA_COLOR_Luma(source);
    float lumaFloor = max(CAMERA_OBSCURA_COLOR_CaptureLumaFloorV1, 0.000001);
    float captureMask = smoothstep(lumaFloor * 0.5, lumaFloor, sourceLuma);
    float3 chroma = source - sourceLuma.xxx;
    float storedLimit = max(CAMERA_OBSCURA_COLOR_StoredRelativeLimitV1, 0.0);
    float3 relativeChroma = clamp(
        chroma / max(sourceLuma, lumaFloor),
        -storedLimit.xxx,
        storedLimit.xxx) * captureMask;
    return float4(relativeChroma, CAMERA_OBSCURA_COLOR_FrameStamp());
}

float4 CAMERA_OBSCURA_COLOR_Reapply_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float4 cached = tex2D(CAMERA_OBSCURA_COLOR_CacheSampler, uv);
    float cacheFresh = CAMERA_OBSCURA_COLOR_CacheFresh(cached.a);
    float authority = cacheFresh *
        (CAMERA_OBSCURA_COLOR_ReapplyEnabledV1 ? 1.0 : 0.0);
    float currentLuma = CAMERA_OBSCURA_COLOR_Luma(source);
    float3 currentChroma = source - currentLuma.xxx;
    float3 targetChroma = cached.rgb * currentLuma;
    float3 delta = (targetChroma - currentChroma) *
        max(CAMERA_OBSCURA_COLOR_ReapplyStrengthV1, 0.0) * authority;

    // Both chroma terms are zero-luma in exact arithmetic. Project again after
    // finite-precision work and limit the signed correction before gamut fit.
    float deltaLuma = CAMERA_OBSCURA_COLOR_Luma(delta);
    delta -= deltaLuma.xxx;
    float appliedLimit = max(CAMERA_OBSCURA_COLOR_AppliedLimitV1, 0.0);
    float maximumDelta = max(abs(delta.r), max(abs(delta.g), abs(delta.b)));
    float limitScale = maximumDelta > appliedLimit && maximumDelta > 0.000001 ?
        appliedLimit / maximumDelta : 1.0;
    delta *= limitScale;
    delta *= CAMERA_OBSCURA_COLOR_GamutScale(source, delta);
    float3 finalRgb = saturate(source + delta);
    float appliedDifference = dot(abs(finalRgb - source), float3(0.333333, 0.333333, 0.333333));

    float view = (float)CAMERA_OBSCURA_COLOR_ViewV1;
    if (view < 0.5) return float4(finalRgb, 1.0);
    if (view < 1.5) return float4(source, 1.0);
    if (view < 2.5) return float4(saturate(0.5.xxx + cached.rgb * 0.125), 1.0);
    if (view < 3.5) return float4(0.05, cacheFresh, 0.10, 1.0);
    if (view < 4.5)
    {
        float differenceView = saturate(appliedDifference * 16.0);
        return float4(differenceView.xxx, 1.0);
    }
    return float4(saturate(0.5.xxx + delta * 2.0), 1.0);
}

technique CAMERA_OBSCURA_StabilizedColorCaptureV1
< ui_label = "Camera Obscura - 1 Stabilized Color Capture V1"; ui_tooltip = "Place at the color reference point.\nStores same-frame relative chroma in an isolated RGBA16F cache.\nDoes not modify the displayed image."; >
{
    pass CaptureStabilizedColor
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_COLOR_Capture_PS;
        RenderTarget = CAMERA_OBSCURA_COLOR_CacheTex;
    }
}

technique CAMERA_OBSCURA_StabilizedColorReapplyV1
< ui_label = "Camera Obscura - 2 Stabilized Color Reapply V1"; ui_tooltip = "Place at the required color restoration point.\nReapplies only same-frame cached chroma while preserving current luma.\nA stale or missing capture returns the source unchanged."; >
{
    pass ReapplyStabilizedColor
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_COLOR_Reapply_PS;
    }
}
