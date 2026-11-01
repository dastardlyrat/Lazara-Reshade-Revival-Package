// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#ifndef CAMERA_OBSCURA_API_STABILIZED_DETAIL_CACHE_FXH
#define CAMERA_OBSCURA_API_STABILIZED_DETAIL_CACHE_FXH

float CAMERA_OBSCURA_DETAIL_Luma(float3 rgb)
{
    return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

float CAMERA_OBSCURA_DETAIL_SmoothGate(
    float value,
    float startValue,
    float fullValue)
{
    float safeStart = max(startValue, 0.0);
    float safeFull = max(fullValue, safeStart + 0.000001);
    float t = saturate((value - safeStart) / (safeFull - safeStart));
    return t * t * (3.0 - 2.0 * t);
}

struct CAMERA_OBSCURA_API_DetailCaptureEvidence
{
    float3 source_rgb;
    float3 base_rgb;
    float3 stored_detail_rgb;
    float detail_magnitude;
    float capture_mask;
};

CAMERA_OBSCURA_API_DetailCaptureEvidence
CAMERA_OBSCURA_API_DefaultDetailCaptureEvidence()
{
    CAMERA_OBSCURA_API_DetailCaptureEvidence evidence;
    evidence.source_rgb = float3(0.0, 0.0, 0.0);
    evidence.base_rgb = float3(0.0, 0.0, 0.0);
    evidence.stored_detail_rgb = float3(0.0, 0.0, 0.0);
    evidence.detail_magnitude = 0.0;
    evidence.capture_mask = 0.0;
    return evidence;
}

CAMERA_OBSCURA_API_DetailCaptureEvidence
CAMERA_OBSCURA_API_BuildDetailCapture(
    float3 sourceRgb,
    float3 baseRgb,
    float captureThreshold,
    float captureGain,
    float detailLimit)
{
    CAMERA_OBSCURA_API_DetailCaptureEvidence evidence =
        CAMERA_OBSCURA_API_DefaultDetailCaptureEvidence();
    float3 source = saturate(sourceRgb);
    float3 base = saturate(baseRgb);
    float3 rawDetail = source - base;
    float magnitude = CAMERA_OBSCURA_DETAIL_Luma(abs(rawDetail));
    float threshold = max(captureThreshold, 0.000001);
    float mask = CAMERA_OBSCURA_DETAIL_SmoothGate(
        magnitude, threshold * 0.5, threshold);
    float safeLimit = max(detailLimit, 0.0);
    float3 storedDetail = clamp(
        rawDetail * max(captureGain, 0.0),
        -safeLimit.xxx,
        safeLimit.xxx) * mask;
    evidence.source_rgb = source;
    evidence.base_rgb = base;
    evidence.stored_detail_rgb = storedDetail;
    evidence.detail_magnitude = magnitude;
    evidence.capture_mask = mask;
    return evidence;
}

struct CAMERA_OBSCURA_API_DetailReapplyEvidence
{
    float3 source_rgb;
    float3 cached_detail_rgb;
    float3 applied_detail_rgb;
    float3 final_rgb;
    float cache_fresh;
    float applied_difference;
};

CAMERA_OBSCURA_API_DetailReapplyEvidence
CAMERA_OBSCURA_API_DefaultDetailReapplyEvidence()
{
    CAMERA_OBSCURA_API_DetailReapplyEvidence evidence;
    evidence.source_rgb = float3(0.0, 0.0, 0.0);
    evidence.cached_detail_rgb = float3(0.0, 0.0, 0.0);
    evidence.applied_detail_rgb = float3(0.0, 0.0, 0.0);
    evidence.final_rgb = float3(0.0, 0.0, 0.0);
    evidence.cache_fresh = 0.0;
    evidence.applied_difference = 0.0;
    return evidence;
}

CAMERA_OBSCURA_API_DetailReapplyEvidence
CAMERA_OBSCURA_API_BuildDetailReapply(
    float3 sourceRgb,
    float3 cachedDetailRgb,
    float cacheFresh,
    float enabled,
    float reapplyStrength,
    float appliedDetailLimit)
{
    CAMERA_OBSCURA_API_DetailReapplyEvidence evidence =
        CAMERA_OBSCURA_API_DefaultDetailReapplyEvidence();
    float3 source = saturate(sourceRgb);
    float authority = saturate(cacheFresh) * saturate(enabled);
    float safeLimit = max(appliedDetailLimit, 0.0);
    float3 appliedDetail = clamp(
        cachedDetailRgb * max(reapplyStrength, 0.0),
        -safeLimit.xxx,
        safeLimit.xxx) * authority;
    float3 finalRgb = saturate(source + appliedDetail);
    evidence.source_rgb = source;
    evidence.cached_detail_rgb = cachedDetailRgb;
    evidence.applied_detail_rgb = appliedDetail;
    evidence.final_rgb = finalRgb;
    evidence.cache_fresh = authority;
    evidence.applied_difference = saturate(
        CAMERA_OBSCURA_DETAIL_Luma(abs(finalRgb - source)));
    return evidence;
}

#endif // CAMERA_OBSCURA_API_STABILIZED_DETAIL_CACHE_FXH
