# Dependency Registry

This registry records where every effect referenced by `Lazara.ini` is owned.
Submodules are pinned to the listed commits; updating a link requires a new
review and commit in this repository.

Recorded SHA-256 values cover the repository's canonical LF shader bytes.
`.gitattributes` enforces LF checkout for `*.fx` and `*.fxh` so the same values
are reproducible on Windows even when global `core.autocrlf` is enabled.

| Preset effect file | Source | Pinned revision or local identity |
|---|---|---|
| `OCCULT_lazara.fx` | [`dastardlyrat/lazara`](https://github.com/dastardlyrat/lazara) | `2c28697a344fb988d784ed31f4d65b107821327b` |
| `BlackWand_05_GI_ColorBleed.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_07_ToneDetail_Richness.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_10_FogLight_Guard.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_12_MicroDetail_Clarity.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_14_BloomBurst_Corona.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_21_EdgeChromaWard.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `FoolsGold.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `GoldenWeave_RMGI_Redux.fx` | [`dastardlyrat/Occult-Box`](https://github.com/dastardlyrat/Occult-Box) | `eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `OSCO_GuidedDetailReclamation.fx` | [`dastardlyrat/OpenSurface-CameraObscura-GuidedDetail`](https://github.com/dastardlyrat/OpenSurface-CameraObscura-GuidedDetail) | `68850554650abe22cca029a65f7a807b6b3b3047` |
| `OSCO_GuidedInkLines.fx` | [`dastardlyrat/OpenSurface-CameraObscura-GuidedDetail`](https://github.com/dastardlyrat/OpenSurface-CameraObscura-GuidedDetail) | `68850554650abe22cca029a65f7a807b6b3b3047` |
| `CAMERA_OBSCURA_ExternalImageDenoiseV1.fx` | This repository | SHA-256 `1E80B48C83FAF24B12D240F2575D56A49EBC1487FAD75ED55C829A4D05ED3802` |
| `CAMERA_OBSCURA_StabilizedDetailCacheV1.fx` | This repository | SHA-256 `AABCAE17124C4DF9BE076CDFC718F860A10568B5D6BBC3DA7737209FD984559B` |

The Stabilized Detail Cache effect exposes two techniques, capture and reapply,
which is why the preset has 14 techniques but only 13 effect files.

## Local Camera Obscura headers

| File | SHA-256 |
|---|---|
| `camera_obscura_external/api/CAMERA_OBSCURA_API_ExternalImageDenoise.fxh` | `21F27AD8729742A19CA2F861316CE177228584C9EF8346FEE934E41DCBAC9E50` |
| `camera_obscura_detail_cache/api/CAMERA_OBSCURA_API_StabilizedDetailCache.fxh` | `FBBCAF786B5C52D4A298CAF4D5A4604DD2CBE996104E3B3AFB16E2C5403B29F4` |

`ReShade.fxh` remains external and must come from the installed ReShade shader
package. The linked Lazara repository retains a copy for its own preprocessing
checks; the installed shader directory should precede linked source paths so a
current installation-provided version takes precedence.
