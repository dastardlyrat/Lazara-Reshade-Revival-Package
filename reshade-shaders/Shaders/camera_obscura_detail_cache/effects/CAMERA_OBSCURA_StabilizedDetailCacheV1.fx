// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#include "ReShade.fxh"
#include "../api/CAMERA_OBSCURA_API_StabilizedDetailCache.fxh"

#ifndef CAMERA_OBSCURA_DETAIL_CACHE_DIVISOR
#define CAMERA_OBSCURA_DETAIL_CACHE_DIVISOR 1
#endif

uniform float CAMERA_OBSCURA_DETAIL_CaptureRadiusV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Captured Detail Radius"; ui_min = 1.0; ui_max = 8.0; ui_step = 0.5; ui_tooltip = "Defines the source-image neighborhood used to separate detail from its local base.\nSmaller values capture finer structure.\nLarger values include broader detail."; > = 2.0;

uniform float CAMERA_OBSCURA_DETAIL_CaptureThresholdV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Captured Detail Threshold"; ui_min = 0.0001; ui_max = 0.1000; ui_step = 0.0005; ui_tooltip = "Minimum local signed RGB residual admitted into the cache.\nLower values retain subtler stabilized texture.\nHigher values isolate stronger detail."; > = 0.0040;

uniform float CAMERA_OBSCURA_DETAIL_CaptureGainV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Captured Detail Gain"; ui_min = 0.00; ui_max = 4.00; ui_step = 0.05; ui_tooltip = "Scales signed detail before it is stored.\nOne preserves the extracted residual.\nZero stores no visible detail."; > = 1.00;

uniform float CAMERA_OBSCURA_DETAIL_StoredLimitV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Stored Detail Limit"; ui_min = 0.001; ui_max = 0.250; ui_step = 0.001; ui_tooltip = "Maximum positive or negative RGB detail stored per channel.\nLimits extreme edges before later effects run."; > = 0.080;

uniform float CAMERA_OBSCURA_DETAIL_ColorToleranceV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Capture Color Tolerance"; ui_min = 0.010; ui_max = 0.500; ui_step = 0.005; ui_tooltip = "Rejects neighborhood support across strong color separation.\nLower values protect edges more strongly.\nHigher values admit broader texture transitions."; > = 0.150;

uniform bool CAMERA_OBSCURA_DETAIL_UseDepthV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Use Capture Depth Rejection"; ui_tooltip = "Rejects neighborhood support across depth discontinuities.\nDisable only when the title has no usable depth buffer."; > = true;

uniform float CAMERA_OBSCURA_DETAIL_DepthToleranceV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Capture"; ui_label = "Capture Depth Tolerance"; ui_min = 0.0005; ui_max = 0.0500; ui_step = 0.0005; ui_tooltip = "Maximum linear-depth separation admitted into the detail base.\nLower values protect silhouettes more aggressively."; > = 0.0100;

uniform bool CAMERA_OBSCURA_DETAIL_ReapplyEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / Stabilized Detail Cache / Reapply"; ui_label = "Enable Stored Detail Reapply"; ui_tooltip = "Adds same-frame stabilized detail after intervening effects.\nOff returns the current source image exactly."; > = true;

uniform float CAMERA_OBSCURA_DETAIL_ReapplyStrengthV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Reapply"; ui_label = "Stored Detail Reapply Strength"; ui_min = 0.00; ui_max = 4.00; ui_step = 0.05; ui_tooltip = "Scales cached signed detail when it is reapplied.\nOne restores the stored amount.\nValues above one accentuate it."; > = 1.00;

uniform float CAMERA_OBSCURA_DETAIL_AppliedLimitV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Reapply"; ui_label = "Reapplied Detail Limit"; ui_min = 0.001; ui_max = 0.250; ui_step = 0.001; ui_tooltip = "Maximum signed RGB detail applied per channel after all intervening effects.\nThis independently contains high reapply strengths."; > = 0.080;

uniform bool CAMERA_OBSCURA_DETAIL_TintEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / Stabilized Detail Cache / Proof Tint"; ui_label = "Show Reapplied Detail Tint"; ui_tooltip = "Colors pixels where cached detail reaches the final image.\nDisplay only; the tint is not stored in the cache."; > = false;

uniform float3 CAMERA_OBSCURA_DETAIL_TintColorV1
< ui_type = "color"; ui_category = "Camera Obscura / Stabilized Detail Cache / Proof Tint"; ui_label = "Reapplied Detail Tint Color"; ui_tooltip = "Bright proof color for pixels receiving stored detail."; > = float3(0.00, 1.00, 0.85);

uniform float CAMERA_OBSCURA_DETAIL_TintThresholdV1
< ui_type = "slider"; ui_category = "Camera Obscura / Stabilized Detail Cache / Proof Tint"; ui_label = "Reapplied Detail Tint Threshold"; ui_min = 0.0001; ui_max = 0.0500; ui_step = 0.0001; ui_tooltip = "Minimum applied luma difference that receives proof tint.\nLower values reveal subtler reapplication."; > = 0.0010;

uniform int CAMERA_OBSCURA_DETAIL_ViewV1
< ui_type = "combo"; ui_category = "Camera Obscura / Stabilized Detail Cache / Reapply"; ui_label = "Reapply View"; ui_items = "Reapplied Image\0Source Before Reapply\0Stored Signed Detail\0Cache Freshness\0Applied Difference (32x)\0Applied Signed Detail\0Reapply Tint Mask\0"; ui_tooltip = "Stored and Applied Signed Detail encode zero as middle gray.\nCache Freshness must be green when Capture ran earlier in the same frame.\nApplied Difference uses display-only 32x gain."; > = 0;

uniform float CAMERA_OBSCURA_DETAIL_FrameCount
< source = "framecount"; >;

texture2D CAMERA_OBSCURA_DETAIL_CacheTex
{
    Width = BUFFER_WIDTH / CAMERA_OBSCURA_DETAIL_CACHE_DIVISOR;
    Height = BUFFER_HEIGHT / CAMERA_OBSCURA_DETAIL_CACHE_DIVISOR;
    Format = RGBA16F;
};

sampler2D CAMERA_OBSCURA_DETAIL_CacheSampler
{
    Texture = CAMERA_OBSCURA_DETAIL_CacheTex;
    MinFilter = LINEAR;
    MagFilter = LINEAR;
    MipFilter = POINT;
};

float CAMERA_OBSCURA_DETAIL_Coverage(float2 requestedUv)
{
    return step(0.0, requestedUv.x) * step(requestedUv.x, 1.0) *
        step(0.0, requestedUv.y) * step(requestedUv.y, 1.0);
}

float CAMERA_OBSCURA_DETAIL_LoadDepth(float2 uv)
{
    return CAMERA_OBSCURA_DETAIL_UseDepthV1 ?
        ReShade::GetLinearizedDepth(uv) : 0.5;
}

float CAMERA_OBSCURA_DETAIL_DepthSupport(
    float centerDepth,
    float tapDepth)
{
    if (!CAMERA_OBSCURA_DETAIL_UseDepthV1)
    {
        return 1.0;
    }
    float tolerance = max(
        CAMERA_OBSCURA_DETAIL_DepthToleranceV1, 0.000001);
    return 1.0 - CAMERA_OBSCURA_DETAIL_SmoothGate(
        abs(centerDepth - tapDepth), tolerance * 0.5, tolerance);
}

float3 CAMERA_OBSCURA_DETAIL_LoadTap(
    float2 requestedUv,
    float3 centerRgb,
    float centerDepth,
    out float weight)
{
    float coverage = CAMERA_OBSCURA_DETAIL_Coverage(requestedUv);
    weight = 0.0;
    [branch]
    if (coverage < 0.5)
    {
        return centerRgb;
    }
    float3 tapRgb = saturate(tex2D(ReShade::BackBuffer, requestedUv).rgb);
    float tapDepth = CAMERA_OBSCURA_DETAIL_LoadDepth(requestedUv);
    float colorTolerance = max(
        CAMERA_OBSCURA_DETAIL_ColorToleranceV1, 0.000001);
    float colorSupport = 1.0 - CAMERA_OBSCURA_DETAIL_SmoothGate(
        abs(CAMERA_OBSCURA_DETAIL_Luma(tapRgb) -
            CAMERA_OBSCURA_DETAIL_Luma(centerRgb)),
        colorTolerance * 0.5,
        colorTolerance);
    weight = coverage * colorSupport *
        CAMERA_OBSCURA_DETAIL_DepthSupport(centerDepth, tapDepth);
    return tapRgb;
}

float CAMERA_OBSCURA_DETAIL_FrameStamp()
{
    return frac(CAMERA_OBSCURA_DETAIL_FrameCount / 1024.0);
}

float3 CAMERA_OBSCURA_DETAIL_DebugHeat(float value)
{
    float t = saturate(value);
    float3 cold = float3(0.02, 0.05, 0.20);
    float3 middle = float3(0.05, 0.85, 0.55);
    float3 hot = float3(1.00, 0.82, 0.12);
    return t < 0.5 ?
        lerp(cold, middle, t * 2.0) :
        lerp(middle, hot, (t - 0.5) * 2.0);
}

float4 CAMERA_OBSCURA_DETAIL_Capture_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float centerDepth = CAMERA_OBSCURA_DETAIL_LoadDepth(uv);
    float2 offset = float2(
        BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT) *
        max(CAMERA_OBSCURA_DETAIL_CaptureRadiusV1, 1.0);
    float leftWeight;
    float rightWeight;
    float upperWeight;
    float lowerWeight;
    float3 leftRgb = CAMERA_OBSCURA_DETAIL_LoadTap(
        uv - float2(offset.x, 0.0), source, centerDepth, leftWeight);
    float3 rightRgb = CAMERA_OBSCURA_DETAIL_LoadTap(
        uv + float2(offset.x, 0.0), source, centerDepth, rightWeight);
    float3 upperRgb = CAMERA_OBSCURA_DETAIL_LoadTap(
        uv - float2(0.0, offset.y), source, centerDepth, upperWeight);
    float3 lowerRgb = CAMERA_OBSCURA_DETAIL_LoadTap(
        uv + float2(0.0, offset.y), source, centerDepth, lowerWeight);
    float totalWeight = 4.0 + leftWeight + rightWeight +
        upperWeight + lowerWeight;
    float3 baseRgb = (
        source * 4.0 +
        leftRgb * leftWeight + rightRgb * rightWeight +
        upperRgb * upperWeight + lowerRgb * lowerWeight) /
        max(totalWeight, 1.0);
    CAMERA_OBSCURA_API_DetailCaptureEvidence evidence =
        CAMERA_OBSCURA_API_BuildDetailCapture(
            source,
            baseRgb,
            CAMERA_OBSCURA_DETAIL_CaptureThresholdV1,
            CAMERA_OBSCURA_DETAIL_CaptureGainV1,
            CAMERA_OBSCURA_DETAIL_StoredLimitV1);
    return float4(
        evidence.stored_detail_rgb,
        CAMERA_OBSCURA_DETAIL_FrameStamp());
}

float4 CAMERA_OBSCURA_DETAIL_Reapply_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float4 cached = tex2D(CAMERA_OBSCURA_DETAIL_CacheSampler, uv);
    float currentStamp = CAMERA_OBSCURA_DETAIL_FrameStamp();
    float stampDifference = abs(cached.a - currentStamp);
    stampDifference = min(stampDifference, 1.0 - stampDifference);
    float frameReady = step(0.5, CAMERA_OBSCURA_DETAIL_FrameCount);
    float cacheFresh = frameReady *
        (1.0 - step(0.0006, stampDifference));
    CAMERA_OBSCURA_API_DetailReapplyEvidence evidence =
        CAMERA_OBSCURA_API_BuildDetailReapply(
            source,
            cached.rgb,
            cacheFresh,
            CAMERA_OBSCURA_DETAIL_ReapplyEnabledV1 ? 1.0 : 0.0,
            CAMERA_OBSCURA_DETAIL_ReapplyStrengthV1,
            CAMERA_OBSCURA_DETAIL_AppliedLimitV1);
    float tintThreshold = max(
        CAMERA_OBSCURA_DETAIL_TintThresholdV1, 0.000001);
    float tintMask = CAMERA_OBSCURA_DETAIL_SmoothGate(
        evidence.applied_difference,
        tintThreshold,
        tintThreshold * 4.0);
    float3 tinted = lerp(
        evidence.final_rgb,
        saturate(CAMERA_OBSCURA_DETAIL_TintColorV1),
        tintMask);
    float view = (float)CAMERA_OBSCURA_DETAIL_ViewV1;
    if (view < 0.5) return float4(
        CAMERA_OBSCURA_DETAIL_TintEnabledV1 ? tinted : evidence.final_rgb,
        1.0);
    if (view < 1.5) return float4(evidence.source_rgb, 1.0);
    if (view < 2.5) return float4(
        saturate(0.5.xxx + evidence.cached_detail_rgb * 4.0), 1.0);
    if (view < 3.5) return float4(
        0.05, evidence.cache_fresh, 0.10, 1.0);
    if (view < 4.5) return float4(
        CAMERA_OBSCURA_DETAIL_DebugHeat(
            evidence.applied_difference * 32.0), 1.0);
    if (view < 5.5) return float4(
        saturate(0.5.xxx + evidence.applied_detail_rgb * 4.0), 1.0);
    return float4(
        saturate(CAMERA_OBSCURA_DETAIL_TintColorV1) * tintMask,
        1.0);
}

technique CAMERA_OBSCURA_StabilizedDetailCaptureV1
< ui_label = "Camera Obscura - 1 Stabilized Detail Capture V1"; ui_tooltip = "Place immediately after Detail Reclamation and External Denoiser.\nStores same-frame signed detail in one shared RGBA16F cache.\nDoes not modify the displayed image."; >
{
    pass CaptureStabilizedDetail
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_DETAIL_Capture_PS;
        RenderTarget = CAMERA_OBSCURA_DETAIL_CacheTex;
    }
}

technique CAMERA_OBSCURA_StabilizedDetailReapplyV1
< ui_label = "Camera Obscura - 2 Stabilized Detail Reapply V1"; ui_tooltip = "Place after all intervening effects.\nReapplies only same-frame cached detail.\nA stale or missing capture returns the source unchanged."; >
{
    pass ReapplyStabilizedDetail
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_DETAIL_Reapply_PS;
    }
}
