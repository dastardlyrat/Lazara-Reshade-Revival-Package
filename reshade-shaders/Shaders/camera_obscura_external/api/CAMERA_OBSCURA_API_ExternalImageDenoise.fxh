// SPDX-FileCopyrightText: 2026 dastardlyrat and OpenSurface contributors
// SPDX-License-Identifier: MIT

#ifndef CAMERA_OBSCURA_API_EXTERNAL_IMAGE_DENOISE_FXH
#define CAMERA_OBSCURA_API_EXTERNAL_IMAGE_DENOISE_FXH

float CAMERA_OBSCURA_EXT_Luma(float3 rgb)
{
    return dot(rgb, float3(0.2126, 0.7152, 0.0722));
}

float CAMERA_OBSCURA_EXT_SmoothGate(
    float value,
    float startValue,
    float fullValue)
{
    float safeStart = max(startValue, 0.0);
    float safeFull = max(fullValue, safeStart + 0.000001);
    float t = saturate((value - safeStart) / (safeFull - safeStart));
    return t * t * (3.0 - 2.0 * t);
}

struct CAMERA_OBSCURA_API_ExternalDenoiseEvidence
{
    float3 source_rgb;
    float3 spatial_candidate_rgb;
    float3 history_candidate_rgb;
    float3 temporal_rgb;
    float3 spatial_rgb;
    float3 final_rgb;
    float noise_target;
    float temporal_trust;
    float temporal_authority;
    float spatial_authority;
    float agreement_confidence;
    float agreement_authority;
    float final_authority;
    float history_clamp_activity;
    float applied_difference;
};

CAMERA_OBSCURA_API_ExternalDenoiseEvidence
CAMERA_OBSCURA_API_DefaultExternalDenoiseEvidence()
{
    CAMERA_OBSCURA_API_ExternalDenoiseEvidence evidence;
    evidence.source_rgb = float3(0.0, 0.0, 0.0);
    evidence.spatial_candidate_rgb = float3(0.0, 0.0, 0.0);
    evidence.history_candidate_rgb = float3(0.0, 0.0, 0.0);
    evidence.temporal_rgb = float3(0.0, 0.0, 0.0);
    evidence.spatial_rgb = float3(0.0, 0.0, 0.0);
    evidence.final_rgb = float3(0.0, 0.0, 0.0);
    evidence.noise_target = 0.0;
    evidence.temporal_trust = 0.0;
    evidence.temporal_authority = 0.0;
    evidence.spatial_authority = 0.0;
    evidence.agreement_confidence = 0.0;
    evidence.agreement_authority = 0.0;
    evidence.final_authority = 0.0;
    evidence.history_clamp_activity = 0.0;
    evidence.applied_difference = 0.0;
    return evidence;
}

CAMERA_OBSCURA_API_ExternalDenoiseEvidence
CAMERA_OBSCURA_API_BuildExternalDenoise(
    float3 sourceRgb,
    float3 spatialCandidateRgb,
    float3 historyCandidateRgb,
    float3 localMinimumRgb,
    float3 localMaximumRgb,
    float noiseTarget,
    float historyValid,
    float historyMatchConfidence,
    float historyResidual,
    float residualStart,
    float residualFull,
    float temporalStrength,
    float spatialStrength,
    float clampPadding,
    float agreementTolerance,
    float combineMode)
{
    CAMERA_OBSCURA_API_ExternalDenoiseEvidence evidence =
        CAMERA_OBSCURA_API_DefaultExternalDenoiseEvidence();
    float3 source = saturate(sourceRgb);
    float3 rangeMinimum = min(localMinimumRgb, localMaximumRgb);
    float3 rangeMaximum = max(localMinimumRgb, localMaximumRgb);
    float3 padding = max(clampPadding, 0.0).xxx;
    float3 clampedHistory = clamp(
        historyCandidateRgb,
        max(rangeMinimum - padding, 0.0),
        min(rangeMaximum + padding, 1.0));
    float3 clampedSpatial = clamp(
        spatialCandidateRgb,
        rangeMinimum,
        rangeMaximum);
    float target = saturate(noiseTarget);
    float residualTrust = 1.0 - CAMERA_OBSCURA_EXT_SmoothGate(
        max(historyResidual, 0.0),
        max(residualStart, 0.0),
        max(residualFull, residualStart + 0.000001));
    float temporalTrust = saturate(
        historyValid * historyMatchConfidence * residualTrust);
    float temporalAuthority = saturate(
        target * temporalTrust * saturate(temporalStrength));
    float spatialAuthority = saturate(
        target * saturate(spatialStrength));
    float3 temporalRgb = lerp(
        source, clampedHistory, temporalAuthority);
    float3 spatialRgb = lerp(
        source, clampedSpatial, spatialAuthority);

    float authoritySum = temporalAuthority + spatialAuthority;
    float unionAuthority = saturate(
        1.0 - (1.0 - temporalAuthority) * (1.0 - spatialAuthority));
    float3 concurrentCandidate = authoritySum > 0.000001 ?
        (clampedHistory * temporalAuthority +
            clampedSpatial * spatialAuthority) / authoritySum :
        source;
    float3 concurrentRgb = lerp(
        source, concurrentCandidate, unionAuthority);

    float safeAgreement = max(agreementTolerance, 0.000001);
    float candidateDifference = CAMERA_OBSCURA_EXT_Luma(
        abs(clampedHistory - clampedSpatial));
    float agreementConfidence = 1.0 - CAMERA_OBSCURA_EXT_SmoothGate(
        candidateDifference,
        safeAgreement * 0.5,
        safeAgreement);
    float agreementAuthority =
        min(temporalAuthority, spatialAuthority) * agreementConfidence;
    float3 agreementCandidate =
        (clampedHistory + clampedSpatial) * 0.5;
    float3 agreementRgb = lerp(
        source, agreementCandidate, agreementAuthority);

    float3 finalRgb = concurrentRgb;
    float finalAuthority = unionAuthority;
    if (combineMode >= 0.5 && combineMode < 1.5)
    {
        finalRgb = agreementRgb;
        finalAuthority = agreementAuthority;
    }
    else if (combineMode >= 1.5 && combineMode < 2.5)
    {
        finalRgb = temporalRgb;
        finalAuthority = temporalAuthority;
    }
    else if (combineMode >= 2.5)
    {
        finalRgb = spatialRgb;
        finalAuthority = spatialAuthority;
    }

    evidence.source_rgb = source;
    evidence.spatial_candidate_rgb = clampedSpatial;
    evidence.history_candidate_rgb = clampedHistory;
    evidence.temporal_rgb = temporalRgb;
    evidence.spatial_rgb = spatialRgb;
    evidence.final_rgb = saturate(finalRgb);
    evidence.noise_target = target;
    evidence.temporal_trust = temporalTrust;
    evidence.temporal_authority = temporalAuthority;
    evidence.spatial_authority = spatialAuthority;
    evidence.agreement_confidence = agreementConfidence;
    evidence.agreement_authority = agreementAuthority;
    evidence.final_authority = finalAuthority;
    evidence.history_clamp_activity = saturate(
        CAMERA_OBSCURA_EXT_Luma(abs(historyCandidateRgb - clampedHistory)));
    evidence.applied_difference = saturate(
        CAMERA_OBSCURA_EXT_Luma(abs(evidence.final_rgb - source)));
    return evidence;
}

#endif // CAMERA_OBSCURA_API_EXTERNAL_IMAGE_DENOISE_FXH
