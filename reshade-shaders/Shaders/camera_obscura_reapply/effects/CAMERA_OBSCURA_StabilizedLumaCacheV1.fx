// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#include "ReShade.fxh"

uniform bool CAMERA_OBSCURA_LUMA_ReapplyEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / Stabilized Luma Cache / Reapply"; ui_label = "Enable Stored Luma Reapply"; ui_tooltip = "Blends current luma toward the same-frame captured luma while retaining current RGB channel separation.\nOff returns the current source image exactly."; > = true;

uniform float CAMERA_OBSCURA_LUMA_ReapplyStrengthV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Luma Cache / Reapply"; ui_label = "Stored Luma Reapply Strength"; ui_min = 0.00; ui_max = 2.00; ui_step = 0.01; ui_tooltip = "Zero leaves current luma unchanged.\nOne targets the captured luma subject to the applied limit and output gamut."; > = 1.00;

uniform float CAMERA_OBSCURA_LUMA_AppliedLimitV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Luma Cache / Reapply"; ui_label = "Reapplied Luma Limit"; ui_min = 0.001; ui_max = 1.000; ui_step = 0.001; ui_tooltip = "Maximum positive or negative luma correction applied in one pass.\nOutput gamut can reduce the correction further without clipping."; > = 0.250;

uniform int CAMERA_OBSCURA_LUMA_ViewV1
< ui_type = "combo"; ui_category = "Camera Obscura / Stabilized Luma Cache / Reapply"; ui_label = "Luma Reapply View"; ui_items = "Reapplied Image\0Source Before Reapply\0Stored Luma\0Cache Freshness\0Applied Difference (16x)\0Applied Signed Luma\0"; ui_tooltip = "Applied Signed Luma encodes zero as middle gray.\nCache Freshness must be green when Capture ran earlier in the same frame."; > = 0;

uniform float CAMERA_OBSCURA_LUMA_FrameCount
< source = "framecount"; >;

texture2D CAMERA_OBSCURA_LUMA_CacheTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D CAMERA_OBSCURA_LUMA_CacheSampler
{
    Texture = CAMERA_OBSCURA_LUMA_CacheTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

float CAMERA_OBSCURA_LUMA_Luma(float3 rgb)
{
    return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

float CAMERA_OBSCURA_LUMA_FrameStamp()
{
    return frac(CAMERA_OBSCURA_LUMA_FrameCount / 1024.0);
}

float CAMERA_OBSCURA_LUMA_CacheFresh(float cachedStamp)
{
    float difference = abs(cachedStamp - CAMERA_OBSCURA_LUMA_FrameStamp());
    difference = min(difference, 1.0 - difference);
    float frameReady = step(0.5, CAMERA_OBSCURA_LUMA_FrameCount);
    return frameReady * (1.0 - step(0.0006, difference));
}

float4 CAMERA_OBSCURA_LUMA_Capture_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float sourceLuma = CAMERA_OBSCURA_LUMA_Luma(source);
    return float4(sourceLuma, 0.0, 0.0, CAMERA_OBSCURA_LUMA_FrameStamp());
}

float4 CAMERA_OBSCURA_LUMA_Reapply_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float4 cached = tex2D(CAMERA_OBSCURA_LUMA_CacheSampler, uv);
    float cacheFresh = CAMERA_OBSCURA_LUMA_CacheFresh(cached.a);
    float authority = cacheFresh *
        (CAMERA_OBSCURA_LUMA_ReapplyEnabledV1 ? 1.0 : 0.0);
    float currentLuma = CAMERA_OBSCURA_LUMA_Luma(source);
    float desiredDelta = (cached.r - currentLuma) *
        max(CAMERA_OBSCURA_LUMA_ReapplyStrengthV1, 0.0) * authority;
    float appliedLimit = max(CAMERA_OBSCURA_LUMA_AppliedLimitV1, 0.0);
    float minimumChannel = min(source.r, min(source.g, source.b));
    float maximumChannel = max(source.r, max(source.g, source.b));
    float lowerBound = max(-appliedLimit, -minimumChannel);
    float upperBound = min(appliedLimit, 1.0 - maximumChannel);
    float appliedDelta = clamp(desiredDelta, lowerBound, upperBound);
    float3 finalRgb = saturate(source + appliedDelta.xxx);
    float appliedDifference = abs(appliedDelta);

    float view = (float)CAMERA_OBSCURA_LUMA_ViewV1;
    if (view < 0.5) return float4(finalRgb, 1.0);
    if (view < 1.5) return float4(source, 1.0);
    if (view < 2.5) return float4(cached.rrr, 1.0);
    if (view < 3.5) return float4(0.05, cacheFresh, 0.10, 1.0);
    if (view < 4.5)
    {
        float differenceView = saturate(appliedDifference * 16.0);
        return float4(differenceView.xxx, 1.0);
    }
    float signedLumaView = saturate(0.5 + appliedDelta * 4.0);
    return float4(signedLumaView.xxx, 1.0);
}

technique CAMERA_OBSCURA_StabilizedLumaCaptureV1
< ui_label = "Camera Obscura - 1 Stabilized Luma Capture V1"; ui_tooltip = "Place at the luma reference point.\nStores same-frame Rec. 709 luma in an isolated RGBA16F cache.\nDoes not modify the displayed image."; >
{
    pass CaptureStabilizedLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_LUMA_Capture_PS;
        RenderTarget = CAMERA_OBSCURA_LUMA_CacheTex;
    }
}

technique CAMERA_OBSCURA_StabilizedLumaReapplyV1
< ui_label = "Camera Obscura - 2 Stabilized Luma Reapply V1"; ui_tooltip = "Place at the required luma restoration point.\nReapplies only same-frame cached luma while retaining current RGB channel separation.\nA stale or missing capture returns the source unchanged."; >
{
    pass ReapplyStabilizedLuma
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_LUMA_Reapply_PS;
    }
}
