// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#include "ReShade.fxh"
#include "../api/CAMERA_OBSCURA_API_ExternalImageDenoise.fxh"

uniform bool CAMERA_OBSCURA_EXT_EnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / External Denoiser"; ui_label = "Enable Denoise"; ui_tooltip = "Filters the already-composited image only.\nOff returns the source image exactly.\nThis effect generates no lighting or GI."; > = true;

uniform bool CAMERA_OBSCURA_EXT_TemporalEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / External Denoiser / Temporal"; ui_label = "Enable Temporal Path"; ui_tooltip = "Reuses matched previous denoised image history.\nHistory is rejected by source mismatch, depth mismatch, residual disagreement, and the current local envelope."; > = true;

uniform float CAMERA_OBSCURA_EXT_TemporalStrengthV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Temporal"; ui_label = "Temporal Strength"; ui_min = 0.00; ui_max = 0.95; ui_step = 0.01; ui_tooltip = "Maximum trusted-history blend.\nHigher values settle persistent image noise faster but require careful ghosting checks."; > = 0.45;

uniform bool CAMERA_OBSCURA_EXT_SpatialEnabledV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / External Denoiser / Spatial"; ui_label = "Enable Spatial Path"; ui_tooltip = "Uses a center-weighted four-neighbor image estimate.\nColor edges, depth edges, unsupported borders, and incoherent opposite taps reduce authority."; > = true;

uniform float CAMERA_OBSCURA_EXT_SpatialStrengthV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Spatial"; ui_label = "Spatial Strength"; ui_min = 0.00; ui_max = 0.95; ui_step = 0.01; ui_tooltip = "Maximum current-frame multiscale reconstruction blend.\nHigher values remove more admitted scale energy but require edge inspection."; > = 0.55;

uniform int CAMERA_OBSCURA_EXT_CombineModeV1
< ui_type = "combo"; ui_category = "Camera Obscura / External Denoiser / Combination"; ui_label = "Combination Mode"; ui_items = "Concurrent\0Agreement Only\0Temporal Only\0Spatial Only\0"; ui_tooltip = "Concurrent permits either path and is the V2 default.\nAgreement Only requires both paths and similar candidates.\nTemporal or Spatial Only isolates one path for testing."; > = 0;

uniform float CAMERA_OBSCURA_EXT_NoiseThresholdV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Detection"; ui_label = "Noise Threshold"; ui_min = 0.001; ui_max = 0.100; ui_step = 0.001; ui_tooltip = "Minimum isolated source-domain residual treated as noise.\nLower values target subtler variation and require more edge inspection."; > = 0.018;

uniform float CAMERA_OBSCURA_EXT_TinyScaleResponseV2
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Noise Size"; ui_label = "Tiny Noise Response"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Targets approximately one-pixel variation.\nZero disables this frequency band.\nUse with any combination of the other size responses."; > = 1.00;

uniform float CAMERA_OBSCURA_EXT_SmallScaleResponseV2
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Noise Size"; ui_label = "Small Noise Response"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Targets variation revealed between one- and two-pixel neighborhoods.\nZero disables this frequency band.\nUse with any combination of the other size responses."; > = 1.00;

uniform float CAMERA_OBSCURA_EXT_MediumScaleResponseV2
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Noise Size"; ui_label = "Medium Noise Response"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Targets variation revealed between two- and four-pixel neighborhoods.\nZero disables this frequency band.\nUse with any combination of the other size responses."; > = 1.00;

uniform float CAMERA_OBSCURA_EXT_LargeScaleResponseV2
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Noise Size"; ui_label = "Large Noise Response"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Targets variation revealed between four- and eight-pixel neighborhoods.\nZero disables this frequency band.\nInspect broad gradients and silhouettes when increasing it."; > = 0.75;

uniform float CAMERA_OBSCURA_EXT_ExtraLargeScaleResponseV2
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Noise Size"; ui_label = "Extra Large Noise Response"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Targets variation revealed between eight- and sixteen-pixel neighborhoods.\nZero disables this frequency band.\nThis is the broadest and most conservative band."; > = 0.50;

uniform float CAMERA_OBSCURA_EXT_OutputMultiplierV3
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Output"; ui_label = "Denoise Output Multiplier"; ui_min = 0.00; ui_max = 4.00; ui_step = 0.05; ui_tooltip = "Multiplies the final correction away from the source image.\nOne preserves the bounded V2 result.\nZero returns the source exactly.\nValues above one provide proof and aggressive headroom and may clip or oversoften detail."; > = 1.00;

uniform bool CAMERA_OBSCURA_EXT_AppliedTintEnabledV3
< ui_type = "checkbox"; ui_category = "Camera Obscura / External Denoiser / Applied Pixel Tint"; ui_label = "Show Applied Pixels Tint"; ui_tooltip = "Colors pixels where the denoiser changes the image.\nThis is a display-only proof overlay.\nIt is not written into temporal history and does not change denoising authority."; > = false;

uniform float3 CAMERA_OBSCURA_EXT_AppliedTintColorV3
< ui_type = "color"; ui_category = "Camera Obscura / External Denoiser / Applied Pixel Tint"; ui_label = "Applied Pixel Tint Color"; ui_tooltip = "Bright proof color painted over pixels with an applied correction.\nUse a color that strongly contrasts the current scene."; > = float3(1.00, 0.00, 0.85);

uniform float CAMERA_OBSCURA_EXT_AppliedTintOpacityV3
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Applied Pixel Tint"; ui_label = "Applied Pixel Tint Opacity"; ui_min = 0.00; ui_max = 1.00; ui_step = 0.01; ui_tooltip = "Controls proof-color coverage after the tint threshold is crossed.\nOne produces the brightest and clearest applied-pixel display."; > = 1.00;

uniform float CAMERA_OBSCURA_EXT_AppliedTintThresholdV3
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Applied Pixel Tint"; ui_label = "Applied Pixel Tint Threshold"; ui_min = 0.0001; ui_max = 0.0500; ui_step = 0.0001; ui_tooltip = "Minimum absolute luma correction that begins tinting a pixel.\nLower values reveal subtler work.\nRaise it to isolate stronger changes."; > = 0.0010;

uniform float CAMERA_OBSCURA_EXT_ColorEdgeToleranceV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Detection"; ui_label = "Color Edge Tolerance"; ui_min = 0.010; ui_max = 0.250; ui_step = 0.005; ui_tooltip = "Maximum local luma separation admitted as same-region support.\nLower values protect edges more aggressively."; > = 0.080;

uniform bool CAMERA_OBSCURA_EXT_UseDepthV1
< ui_type = "checkbox"; ui_category = "Camera Obscura / External Denoiser / Detection"; ui_label = "Use Depth Rejection"; ui_tooltip = "Rejects spatial and temporal support across depth discontinuities.\nDisable only when a title has no usable depth buffer."; > = true;

uniform float CAMERA_OBSCURA_EXT_DepthToleranceV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Detection"; ui_label = "Depth Tolerance"; ui_min = 0.0005; ui_max = 0.0500; ui_step = 0.0005; ui_tooltip = "Maximum linear-depth separation admitted as same-surface support.\nLower values protect silhouettes more strongly."; > = 0.0100;

uniform float CAMERA_OBSCURA_EXT_GhostingProtectionV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Temporal"; ui_label = "Ghosting Protection"; ui_min = 0.000; ui_max = 0.050; ui_step = 0.001; ui_tooltip = "Padding around the current local color envelope used to clamp history.\nLower is stricter and resists trails."; > = 0.005;

uniform float CAMERA_OBSCURA_EXT_AgreementToleranceV1
< ui_type = "slider"; ui_category = "Camera Obscura / External Denoiser / Combination"; ui_label = "Agreement Tolerance"; ui_min = 0.001; ui_max = 0.100; ui_step = 0.001; ui_tooltip = "Maximum luma separation between temporal and spatial candidates in Agreement Only mode."; > = 0.020;

uniform int CAMERA_OBSCURA_EXT_ViewV1
< ui_type = "combo"; ui_category = "Camera Obscura / External Denoiser"; ui_label = "View"; ui_items = "Denoised Image\0Source Only\0Combined Noise Target\0Temporal Trust\0Temporal Authority\0Spatial Authority\0Applied Difference (32x)\0Agreement Authority\0History Clamp Activity\0Inferred Motion Offset\0Final Authority\0Candidate Difference (32x)\0Tiny Noise\0Small Noise\0Medium Noise\0Large Noise\0Extra Large Noise\0Combined Scale Target\0Dominant Noise Size\0Active Scale Coverage\0Applied Tint Mask\0"; ui_tooltip = "The five size views show independent frequency-band admission.\nCombined Scale Target is their bounded union.\nDominant Noise Size runs from tiny through extra large.\nApplied and Candidate Difference use display-only 32x gain.\nApplied Tint Mask shows the exact proof overlay mask."; > = 0;

uniform float CAMERA_OBSCURA_EXT_FrameCount
< source = "framecount"; >;

static const float CAMERA_OBSCURA_EXT_HistoryScoreStart = 0.25;
static const float CAMERA_OBSCURA_EXT_HistoryScoreFull = 1.25;
static const float CAMERA_OBSCURA_EXT_HistoryResidualStart = 0.004;
static const float CAMERA_OBSCURA_EXT_HistoryResidualFull = 0.080;

texture2D CAMERA_OBSCURA_EXT_DenoisedTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_EvidenceTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_DetailTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_ScaleBandsTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_ScaleSummaryTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_HistorySourceTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

texture2D CAMERA_OBSCURA_EXT_HistoryDenoisedTex
{
    Width = BUFFER_WIDTH;
    Height = BUFFER_HEIGHT;
    Format = RGBA16F;
};

sampler2D CAMERA_OBSCURA_EXT_DenoisedSampler
{
    Texture = CAMERA_OBSCURA_EXT_DenoisedTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_EvidenceSampler
{
    Texture = CAMERA_OBSCURA_EXT_EvidenceTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_DetailSampler
{
    Texture = CAMERA_OBSCURA_EXT_DetailTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_ScaleBandsSampler
{
    Texture = CAMERA_OBSCURA_EXT_ScaleBandsTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_ScaleSummarySampler
{
    Texture = CAMERA_OBSCURA_EXT_ScaleSummaryTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_HistorySourceSampler
{
    Texture = CAMERA_OBSCURA_EXT_HistorySourceTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

sampler2D CAMERA_OBSCURA_EXT_HistoryDenoisedSampler
{
    Texture = CAMERA_OBSCURA_EXT_HistoryDenoisedTex;
    MinFilter = POINT;
    MagFilter = POINT;
    MipFilter = POINT;
};

float CAMERA_OBSCURA_EXT_Coverage(float2 requestedUv)
{
    return step(0.0, requestedUv.x) * step(requestedUv.x, 1.0) *
        step(0.0, requestedUv.y) * step(requestedUv.y, 1.0);
}

float CAMERA_OBSCURA_EXT_LoadDepth(float2 uv)
{
    return CAMERA_OBSCURA_EXT_UseDepthV1 ?
        ReShade::GetLinearizedDepth(uv) : 0.5;
}

float CAMERA_OBSCURA_EXT_DepthValid(float depth)
{
    if (!CAMERA_OBSCURA_EXT_UseDepthV1)
    {
        return 1.0;
    }
    return step(0.000001, depth) * (1.0 - step(0.999999, depth));
}

float CAMERA_OBSCURA_EXT_DepthSupport(float centerDepth, float tapDepth)
{
    if (!CAMERA_OBSCURA_EXT_UseDepthV1)
    {
        return 1.0;
    }
    float tolerance = max(CAMERA_OBSCURA_EXT_DepthToleranceV1, 0.000001);
    return 1.0 - CAMERA_OBSCURA_EXT_SmoothGate(
        abs(centerDepth - tapDepth), tolerance * 0.5, tolerance);
}

float3 CAMERA_OBSCURA_EXT_LoadCurrentTap(
    float2 requestedUv,
    float3 centerRgb,
    float centerDepth,
    out float coverage,
    out float tapDepth)
{
    coverage = CAMERA_OBSCURA_EXT_Coverage(requestedUv);
    tapDepth = centerDepth;
    [branch]
    if (coverage < 0.5)
    {
        return centerRgb;
    }
    tapDepth = CAMERA_OBSCURA_EXT_LoadDepth(requestedUv);
    return tex2D(ReShade::BackBuffer, requestedUv).rgb;
}

float CAMERA_OBSCURA_EXT_SpatialWeight(
    float3 centerRgb,
    float3 tapRgb,
    float centerDepth,
    float tapDepth,
    float coverage)
{
    float colorTolerance = max(
        CAMERA_OBSCURA_EXT_ColorEdgeToleranceV1, 0.000001);
    float colorSupport = 1.0 - CAMERA_OBSCURA_EXT_SmoothGate(
        abs(CAMERA_OBSCURA_EXT_Luma(tapRgb) -
            CAMERA_OBSCURA_EXT_Luma(centerRgb)),
        colorTolerance * 0.5,
        colorTolerance);
    return coverage * colorSupport *
        CAMERA_OBSCURA_EXT_DepthSupport(centerDepth, tapDepth);
}

void CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
    float2 requestedUv,
    float3 currentRgb,
    float currentDepth,
    inout float bestScore,
    inout float2 bestUv,
    inout float bestValid)
{
    float coverage = CAMERA_OBSCURA_EXT_Coverage(requestedUv);
    [branch]
    if (coverage > 0.5)
    {
        float4 historyValue = tex2D(
            CAMERA_OBSCURA_EXT_HistorySourceSampler, requestedUv);
        float depthValid = CAMERA_OBSCURA_EXT_DepthValid(historyValue.a);
        [branch]
        if (depthValid > 0.5)
        {
            float colorTolerance = max(
                CAMERA_OBSCURA_EXT_ColorEdgeToleranceV1, 0.000001);
            float depthTolerance = max(
                CAMERA_OBSCURA_EXT_DepthToleranceV1, 0.000001);
            float sourceError = CAMERA_OBSCURA_EXT_Luma(
                abs(currentRgb - historyValue.rgb)) / colorTolerance;
            float depthError = CAMERA_OBSCURA_EXT_UseDepthV1 ?
                abs(currentDepth - historyValue.a) / depthTolerance : 0.0;
            float candidateScore = sourceError * 0.75 + depthError * 0.25;
            [branch]
            if (bestValid < 0.5 || candidateScore < bestScore)
            {
                bestScore = candidateScore;
                bestUv = requestedUv;
                bestValid = 1.0;
            }
        }
    }
}

float3 CAMERA_OBSCURA_EXT_DebugHeat(float value)
{
    float t = saturate(value);
    float3 cold = float3(0.02, 0.05, 0.20);
    float3 middle = float3(0.05, 0.85, 0.55);
    float3 hot = float3(1.00, 0.82, 0.12);
    return t < 0.5 ?
        lerp(cold, middle, t * 2.0) :
        lerp(middle, hot, (t - 0.5) * 2.0);
}

struct CAMERA_OBSCURA_EXT_ScaleEvidence
{
    float3 candidate_rgb;
    float3 minimum_rgb;
    float3 maximum_rgb;
    float admission;
};

CAMERA_OBSCURA_EXT_ScaleEvidence CAMERA_OBSCURA_EXT_DefaultScaleEvidence(
    float3 source)
{
    CAMERA_OBSCURA_EXT_ScaleEvidence evidence;
    evidence.candidate_rgb = source;
    evidence.minimum_rgb = source;
    evidence.maximum_rgb = source;
    evidence.admission = 0.0;
    return evidence;
}

CAMERA_OBSCURA_EXT_ScaleEvidence CAMERA_OBSCURA_EXT_EvaluateScale(
    float2 uv,
    float3 source,
    float centerDepth,
    float2 pixel,
    float radius)
{
    CAMERA_OBSCURA_EXT_ScaleEvidence evidence =
        CAMERA_OBSCURA_EXT_DefaultScaleEvidence(source);
    float2 horizontalOffset = float2(pixel.x * radius, 0.0);
    float2 verticalOffset = float2(0.0, pixel.y * radius);
    float leftCoverage;
    float rightCoverage;
    float upperCoverage;
    float lowerCoverage;
    float leftDepth;
    float rightDepth;
    float upperDepth;
    float lowerDepth;
    float3 leftRgb = CAMERA_OBSCURA_EXT_LoadCurrentTap(
        uv - horizontalOffset, source, centerDepth,
        leftCoverage, leftDepth);
    float3 rightRgb = CAMERA_OBSCURA_EXT_LoadCurrentTap(
        uv + horizontalOffset, source, centerDepth,
        rightCoverage, rightDepth);
    float3 upperRgb = CAMERA_OBSCURA_EXT_LoadCurrentTap(
        uv - verticalOffset, source, centerDepth,
        upperCoverage, upperDepth);
    float3 lowerRgb = CAMERA_OBSCURA_EXT_LoadCurrentTap(
        uv + verticalOffset, source, centerDepth,
        lowerCoverage, lowerDepth);

    float leftWeight = CAMERA_OBSCURA_EXT_SpatialWeight(
        source, leftRgb, centerDepth, leftDepth, leftCoverage);
    float rightWeight = CAMERA_OBSCURA_EXT_SpatialWeight(
        source, rightRgb, centerDepth, rightDepth, rightCoverage);
    float upperWeight = CAMERA_OBSCURA_EXT_SpatialWeight(
        source, upperRgb, centerDepth, upperDepth, upperCoverage);
    float lowerWeight = CAMERA_OBSCURA_EXT_SpatialWeight(
        source, lowerRgb, centerDepth, lowerDepth, lowerCoverage);
    float totalWeight = 2.0 + leftWeight + rightWeight +
        upperWeight + lowerWeight;
    evidence.candidate_rgb = (
        source * 2.0 +
        leftRgb * leftWeight + rightRgb * rightWeight +
        upperRgb * upperWeight + lowerRgb * lowerWeight) /
        max(totalWeight, 1.0);

    float leftAccepted = step(0.000001, leftWeight);
    float rightAccepted = step(0.000001, rightWeight);
    float upperAccepted = step(0.000001, upperWeight);
    float lowerAccepted = step(0.000001, lowerWeight);
    evidence.minimum_rgb = min(
        min(source, lerp(source, leftRgb, leftAccepted)),
        min(lerp(source, rightRgb, rightAccepted),
            min(lerp(source, upperRgb, upperAccepted),
                lerp(source, lowerRgb, lowerAccepted))));
    evidence.maximum_rgb = max(
        max(source, lerp(source, leftRgb, leftAccepted)),
        max(lerp(source, rightRgb, rightAccepted),
            max(lerp(source, upperRgb, upperAccepted),
                lerp(source, lowerRgb, lowerAccepted))));

    float pairAvailability = min(leftAccepted, rightAccepted) *
        min(upperAccepted, lowerAccepted);
    float pairDifference = max(
        abs(CAMERA_OBSCURA_EXT_Luma(leftRgb) -
            CAMERA_OBSCURA_EXT_Luma(rightRgb)),
        abs(CAMERA_OBSCURA_EXT_Luma(upperRgb) -
            CAMERA_OBSCURA_EXT_Luma(lowerRgb)));
    float colorTolerance = max(
        CAMERA_OBSCURA_EXT_ColorEdgeToleranceV1, 0.000001);
    float coherence = 1.0 - CAMERA_OBSCURA_EXT_SmoothGate(
        pairDifference, colorTolerance * 0.5, colorTolerance);
    float support = saturate(
        (leftWeight + rightWeight + upperWeight + lowerWeight) * 0.25);
    evidence.admission = coherence * support * pairAvailability *
        CAMERA_OBSCURA_EXT_DepthValid(centerDepth);
    return evidence;
}

float CAMERA_OBSCURA_EXT_EvaluateBandTarget(
    float3 fineCandidate,
    float3 coarseCandidate,
    float fineAdmission,
    float coarseAdmission,
    float response)
{
    float amplitude = CAMERA_OBSCURA_EXT_Luma(
        abs(fineCandidate - coarseCandidate));
    float threshold = max(CAMERA_OBSCURA_EXT_NoiseThresholdV1, 0.000001);
    return CAMERA_OBSCURA_EXT_SmoothGate(
        amplitude, threshold * 0.5, threshold) *
        min(fineAdmission, coarseAdmission) * saturate(response);
}

CAMERA_OBSCURA_API_ExternalDenoiseEvidence
CAMERA_OBSCURA_EXT_Evaluate(
    float2 uv,
    out float motionOffset,
    out float4 scaleBands,
    out float4 scaleSummary)
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float centerDepth = CAMERA_OBSCURA_EXT_LoadDepth(uv);
    float centerValid = CAMERA_OBSCURA_EXT_DepthValid(centerDepth);
    float2 pixel = float2(BUFFER_RCP_WIDTH, BUFFER_RCP_HEIGHT);

    CAMERA_OBSCURA_EXT_ScaleEvidence tinyScale =
        CAMERA_OBSCURA_EXT_EvaluateScale(
            uv, source, centerDepth, pixel, 1.0);
    CAMERA_OBSCURA_EXT_ScaleEvidence smallScale =
        CAMERA_OBSCURA_EXT_EvaluateScale(
            uv, source, centerDepth, pixel, 2.0);
    CAMERA_OBSCURA_EXT_ScaleEvidence mediumScale =
        CAMERA_OBSCURA_EXT_EvaluateScale(
            uv, source, centerDepth, pixel, 4.0);
    CAMERA_OBSCURA_EXT_ScaleEvidence largeScale =
        CAMERA_OBSCURA_EXT_EvaluateScale(
            uv, source, centerDepth, pixel, 8.0);
    CAMERA_OBSCURA_EXT_ScaleEvidence extraLargeScale =
        CAMERA_OBSCURA_EXT_EvaluateScale(
            uv, source, centerDepth, pixel, 16.0);

    float3 tinyCandidate = tinyScale.candidate_rgb;
    float3 smallCandidate = (
        tinyScale.candidate_rgb + smallScale.candidate_rgb) * 0.5;
    float3 mediumCandidate = (
        tinyScale.candidate_rgb + smallScale.candidate_rgb +
        mediumScale.candidate_rgb) / 3.0;
    float3 largeCandidate = (
        tinyScale.candidate_rgb + smallScale.candidate_rgb +
        mediumScale.candidate_rgb + largeScale.candidate_rgb) * 0.25;
    float3 extraLargeCandidate = (
        tinyScale.candidate_rgb + smallScale.candidate_rgb +
        mediumScale.candidate_rgb + largeScale.candidate_rgb +
        extraLargeScale.candidate_rgb) * 0.2;

    float tinyTarget = CAMERA_OBSCURA_EXT_EvaluateBandTarget(
        source, tinyCandidate,
        tinyScale.admission, tinyScale.admission,
        CAMERA_OBSCURA_EXT_TinyScaleResponseV2);
    float smallTarget = CAMERA_OBSCURA_EXT_EvaluateBandTarget(
        tinyCandidate, smallCandidate,
        tinyScale.admission, smallScale.admission,
        CAMERA_OBSCURA_EXT_SmallScaleResponseV2);
    float mediumTarget = CAMERA_OBSCURA_EXT_EvaluateBandTarget(
        smallCandidate, mediumCandidate,
        smallScale.admission, mediumScale.admission,
        CAMERA_OBSCURA_EXT_MediumScaleResponseV2);
    float largeTarget = CAMERA_OBSCURA_EXT_EvaluateBandTarget(
        mediumCandidate, largeCandidate,
        mediumScale.admission, largeScale.admission,
        CAMERA_OBSCURA_EXT_LargeScaleResponseV2);
    float extraLargeTarget = CAMERA_OBSCURA_EXT_EvaluateBandTarget(
        largeCandidate, extraLargeCandidate,
        largeScale.admission, extraLargeScale.admission,
        CAMERA_OBSCURA_EXT_ExtraLargeScaleResponseV2);

    float noiseTarget = saturate(1.0 -
        (1.0 - tinyTarget) * (1.0 - smallTarget) *
        (1.0 - mediumTarget) * (1.0 - largeTarget) *
        (1.0 - extraLargeTarget));
    float3 selectedCorrection =
        (source - tinyCandidate) * tinyTarget +
        (tinyCandidate - smallCandidate) * smallTarget +
        (smallCandidate - mediumCandidate) * mediumTarget +
        (mediumCandidate - largeCandidate) * largeTarget +
        (largeCandidate - extraLargeCandidate) * extraLargeTarget;
    float3 spatialCandidate = saturate(noiseTarget > 0.000001 ?
        source - selectedCorrection / noiseTarget : source);
    float3 localMinimum = min(
        min(source, tinyScale.minimum_rgb),
        min(smallScale.minimum_rgb,
            min(mediumScale.minimum_rgb,
                min(largeScale.minimum_rgb,
                    extraLargeScale.minimum_rgb))));
    float3 localMaximum = max(
        max(source, tinyScale.maximum_rgb),
        max(smallScale.maximum_rgb,
            max(mediumScale.maximum_rgb,
                max(largeScale.maximum_rgb,
                    extraLargeScale.maximum_rgb))));
    localMinimum = min(localMinimum, spatialCandidate);
    localMaximum = max(localMaximum, spatialCandidate);

    float dominantTarget = tinyTarget;
    float dominantScale = 0.2;
    if (smallTarget > dominantTarget)
    {
        dominantTarget = smallTarget;
        dominantScale = 0.4;
    }
    if (mediumTarget > dominantTarget)
    {
        dominantTarget = mediumTarget;
        dominantScale = 0.6;
    }
    if (largeTarget > dominantTarget)
    {
        dominantTarget = largeTarget;
        dominantScale = 0.8;
    }
    if (extraLargeTarget > dominantTarget)
    {
        dominantTarget = extraLargeTarget;
        dominantScale = 1.0;
    }
    dominantScale *= step(0.000001, dominantTarget);
    float activeScaleCoverage = (
        step(0.000001, tinyTarget) + step(0.000001, smallTarget) +
        step(0.000001, mediumTarget) + step(0.000001, largeTarget) +
        step(0.000001, extraLargeTarget)) * 0.2;
    scaleBands = float4(
        tinyTarget, smallTarget, mediumTarget, largeTarget);
    scaleSummary = float4(
        extraLargeTarget, noiseTarget, dominantScale, activeScaleCoverage);

    float historyReady = step(1.5, CAMERA_OBSCURA_EXT_FrameCount);
    float bestScore = 1000000.0;
    float2 bestUv = uv;
    float bestValid = 0.0;
    CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
        uv, source, centerDepth, bestScore, bestUv, bestValid);
    CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
        uv - float2(pixel.x, 0.0), source, centerDepth,
        bestScore, bestUv, bestValid);
    CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
        uv + float2(pixel.x, 0.0), source, centerDepth,
        bestScore, bestUv, bestValid);
    CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
        uv - float2(0.0, pixel.y), source, centerDepth,
        bestScore, bestUv, bestValid);
    CAMERA_OBSCURA_EXT_ConsiderHistoryCandidate(
        uv + float2(0.0, pixel.y), source, centerDepth,
        bestScore, bestUv, bestValid);
    float historyMatchConfidence = 1.0 -
        CAMERA_OBSCURA_EXT_SmoothGate(
            bestScore,
            CAMERA_OBSCURA_EXT_HistoryScoreStart,
            CAMERA_OBSCURA_EXT_HistoryScoreFull);
    float historyValid = historyReady * bestValid * centerValid;
    float3 historyCandidate = source;
    [branch]
    if (historyValid > 0.5)
    {
        historyCandidate = tex2D(
            CAMERA_OBSCURA_EXT_HistoryDenoisedSampler, bestUv).rgb;
    }
    float historyResidual = CAMERA_OBSCURA_EXT_Luma(
        abs(source - historyCandidate));
    motionOffset = saturate(length(float2(
        (bestUv.x - uv.x) / max(BUFFER_RCP_WIDTH, 0.000001),
        (bestUv.y - uv.y) / max(BUFFER_RCP_HEIGHT, 0.000001))));

    float master = CAMERA_OBSCURA_EXT_EnabledV1 ? 1.0 : 0.0;
    float temporalStrength = master *
        (CAMERA_OBSCURA_EXT_TemporalEnabledV1 ?
            CAMERA_OBSCURA_EXT_TemporalStrengthV1 : 0.0);
    float spatialStrength = master *
        (CAMERA_OBSCURA_EXT_SpatialEnabledV1 ?
            CAMERA_OBSCURA_EXT_SpatialStrengthV1 : 0.0);
    CAMERA_OBSCURA_API_ExternalDenoiseEvidence evidence =
        CAMERA_OBSCURA_API_BuildExternalDenoise(
        source,
        spatialCandidate,
        historyCandidate,
        localMinimum,
        localMaximum,
        noiseTarget,
        historyValid,
        historyMatchConfidence,
        historyResidual,
        CAMERA_OBSCURA_EXT_HistoryResidualStart,
        CAMERA_OBSCURA_EXT_HistoryResidualFull,
        temporalStrength,
        spatialStrength,
        CAMERA_OBSCURA_EXT_GhostingProtectionV1,
        CAMERA_OBSCURA_EXT_AgreementToleranceV1,
        (float)CAMERA_OBSCURA_EXT_CombineModeV1);
    float outputMultiplier = max(
        CAMERA_OBSCURA_EXT_OutputMultiplierV3, 0.0);
    evidence.final_rgb = saturate(
        evidence.source_rgb +
        (evidence.final_rgb - evidence.source_rgb) * outputMultiplier);
    evidence.applied_difference = saturate(
        CAMERA_OBSCURA_EXT_Luma(
            abs(evidence.final_rgb - evidence.source_rgb)));
    return evidence;
}

void CAMERA_OBSCURA_EXT_Denoise_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD,
    out float4 denoisedValue : SV_Target0,
    out float4 evidenceValue : SV_Target1,
    out float4 detailValue : SV_Target2,
    out float4 scaleBandsValue : SV_Target3,
    out float4 scaleSummaryValue : SV_Target4)
{
    float motionOffset = 0.0;
    float4 scaleBands = 0.0;
    float4 scaleSummary = 0.0;
    CAMERA_OBSCURA_API_ExternalDenoiseEvidence evidence =
        CAMERA_OBSCURA_EXT_Evaluate(
            uv, motionOffset, scaleBands, scaleSummary);
    denoisedValue = float4(evidence.final_rgb, evidence.final_authority);
    evidenceValue = float4(
        evidence.noise_target,
        evidence.temporal_trust,
        evidence.temporal_authority,
        evidence.spatial_authority);
    detailValue = float4(
        evidence.applied_difference,
        evidence.agreement_authority,
        evidence.history_clamp_activity,
        motionOffset);
    scaleBandsValue = scaleBands;
    scaleSummaryValue = scaleSummary;
}

float4 CAMERA_OBSCURA_EXT_CaptureSource_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float depth = CAMERA_OBSCURA_EXT_LoadDepth(uv);
    float valid = CAMERA_OBSCURA_EXT_DepthValid(depth);
    return float4(
        saturate(tex2D(ReShade::BackBuffer, uv).rgb),
        lerp(0.0, depth, valid));
}

float4 CAMERA_OBSCURA_EXT_CaptureDenoised_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float depth = CAMERA_OBSCURA_EXT_LoadDepth(uv);
    float valid = CAMERA_OBSCURA_EXT_DepthValid(depth);
    return float4(
        tex2D(CAMERA_OBSCURA_EXT_DenoisedSampler, uv).rgb,
        lerp(0.0, depth, valid));
}

float4 CAMERA_OBSCURA_EXT_Display_PS(
    float4 position : SV_Position,
    float2 uv : TEXCOORD) : SV_Target
{
    float3 source = saturate(tex2D(ReShade::BackBuffer, uv).rgb);
    float4 denoised = tex2D(CAMERA_OBSCURA_EXT_DenoisedSampler, uv);
    float4 evidence = tex2D(CAMERA_OBSCURA_EXT_EvidenceSampler, uv);
    float4 detail = tex2D(CAMERA_OBSCURA_EXT_DetailSampler, uv);
    float4 scaleBands = tex2D(CAMERA_OBSCURA_EXT_ScaleBandsSampler, uv);
    float4 scaleSummary = tex2D(CAMERA_OBSCURA_EXT_ScaleSummarySampler, uv);
    float tintThreshold = max(
        CAMERA_OBSCURA_EXT_AppliedTintThresholdV3, 0.000001);
    float tintMask = CAMERA_OBSCURA_EXT_SmoothGate(
        detail.r, tintThreshold, tintThreshold * 4.0);
    float tintOpacity = saturate(
        CAMERA_OBSCURA_EXT_AppliedTintOpacityV3) * tintMask;
    float3 tintedDenoised = lerp(
        denoised.rgb,
        saturate(CAMERA_OBSCURA_EXT_AppliedTintColorV3),
        tintOpacity);
    float view = (float)CAMERA_OBSCURA_EXT_ViewV1;
    if (view < 0.5) return float4(
        CAMERA_OBSCURA_EXT_AppliedTintEnabledV3 ?
            tintedDenoised : denoised.rgb,
        1.0);
    if (view < 1.5) return float4(source, 1.0);
    if (view < 2.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(evidence.r), 1.0);
    if (view < 3.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(evidence.g), 1.0);
    if (view < 4.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(evidence.b), 1.0);
    if (view < 5.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(evidence.a), 1.0);
    if (view < 6.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(detail.r * 32.0), 1.0);
    if (view < 7.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(detail.g), 1.0);
    if (view < 8.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(detail.b), 1.0);
    if (view < 9.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(detail.a), 1.0);
    if (view < 10.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(denoised.a), 1.0);
    float candidateDifference = denoised.a > 0.000001 ?
        detail.r / denoised.a : 0.0;
    if (view < 11.5) return float4(
        CAMERA_OBSCURA_EXT_DebugHeat(candidateDifference * 32.0), 1.0);
    if (view < 12.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleBands.r), 1.0);
    if (view < 13.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleBands.g), 1.0);
    if (view < 14.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleBands.b), 1.0);
    if (view < 15.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleBands.a), 1.0);
    if (view < 16.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleSummary.r), 1.0);
    if (view < 17.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleSummary.g), 1.0);
    if (view < 18.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleSummary.b), 1.0);
    if (view < 19.5) return float4(CAMERA_OBSCURA_EXT_DebugHeat(scaleSummary.a), 1.0);
    return float4(
        saturate(CAMERA_OBSCURA_EXT_AppliedTintColorV3) * tintMask,
        1.0);
}

technique CAMERA_OBSCURA_ExternalImageDenoiseV1
< ui_label = "Camera Obscura - External Image Denoiser V2.1 Multiscale"; ui_tooltip = "Source-domain denoiser for an already-composited image.\nSeparately detects and removes tiny through extra-large frequency bands.\nV2.1 adds final correction multiplication and a bright display-only applied-pixel tint.\nContains no ray traversal, donor transport, reconstruction, indirect lighting, or additive GI composite."; >
{
    pass ExternalDenoise
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_EXT_Denoise_PS;
        RenderTarget0 = CAMERA_OBSCURA_EXT_DenoisedTex;
        RenderTarget1 = CAMERA_OBSCURA_EXT_EvidenceTex;
        RenderTarget2 = CAMERA_OBSCURA_EXT_DetailTex;
        RenderTarget3 = CAMERA_OBSCURA_EXT_ScaleBandsTex;
        RenderTarget4 = CAMERA_OBSCURA_EXT_ScaleSummaryTex;
    }
    pass CaptureSourceHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_EXT_CaptureSource_PS;
        RenderTarget = CAMERA_OBSCURA_EXT_HistorySourceTex;
    }
    pass CaptureDenoisedHistory
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_EXT_CaptureDenoised_PS;
        RenderTarget = CAMERA_OBSCURA_EXT_HistoryDenoisedTex;
    }
    pass Display
    {
        VertexShader = PostProcessVS;
        PixelShader = CAMERA_OBSCURA_EXT_Display_PS;
    }
}
