# Dependency Registry

`Lazara.ini` enables 14 techniques from 13 effect files. Its same-frame
reference-detail storage and reapplication cycle is supplied by two Stabilized
Detail Cache techniques, capture and reapply, which accounts for the different
totals.

## Temporarily vendored sources

| Preset effect file | Vendored path | Authoritative source revision |
|---|---|---|
| `OCCULT_lazara.fx` | `reshade-shaders/Shaders/vendor/lazara/rm/effects/OCCULT_lazara.fx` | `dastardlyrat/lazara@2c28697a344fb988d784ed31f4d65b107821327b` |
| `BlackWand_05_GI_ColorBleed.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_05_GI_ColorBleed.fx` | `dastardlyrat/Occult-Box@eef2b91b314ddc1a68547d0fb1daa2413adfce66` |
| `BlackWand_07_ToneDetail_Richness.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_07_ToneDetail_Richness.fx` | same Occult Box revision |
| `BlackWand_10_FogLight_Guard.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_10_FogLight_Guard.fx` | same Occult Box revision |
| `BlackWand_12_MicroDetail_Clarity.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_12_MicroDetail_Clarity.fx` | same Occult Box revision |
| `BlackWand_14_BloomBurst_Corona.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_14_BloomBurst_Corona.fx` | same Occult Box revision |
| `BlackWand_21_EdgeChromaWard.fx` | `reshade-shaders/Shaders/vendor/occult_box/black_wand/effects/BlackWand_21_EdgeChromaWard.fx` | same Occult Box revision |
| `FoolsGold.fx` | `reshade-shaders/Shaders/vendor/occult_box/book_of_death/effects/FoolsGold.fx` | same Occult Box revision |
| `GoldenWeave_RMGI_Redux.fx` | `reshade-shaders/Shaders/vendor/occult_box/golden_weave/effects/GoldenWeave_RMGI_Redux.fx` | same Occult Box revision |
| `OSCO_GuidedDetailReclamation.fx` | `reshade-shaders/Shaders/vendor/guided_detail/effects/OSCO_GuidedDetailReclamation.fx` | `dastardlyrat/OpenSurface-CameraObscura-GuidedDetail@68850554650abe22cca029a65f7a807b6b3b3047` |
| `OSCO_GuidedInkLines.fx` | `reshade-shaders/Shaders/vendor/guided_detail/effects/OSCO_GuidedInkLines.fx` | same Guided Detail revision |

The temporary closure contains 104 files: 11 effect files and 93 headers. It
excludes repository documentation, development artifacts, screenshots, and the
upstream `ReShade.fxh` preprocessing copy.

## Directly published Camera Obscura sources

| Effect file | Local path |
|---|---|
| `CAMERA_OBSCURA_ExternalImageDenoiseV1.fx` | `reshade-shaders/Shaders/camera_obscura_external/effects/CAMERA_OBSCURA_ExternalImageDenoiseV1.fx` |
| `CAMERA_OBSCURA_StabilizedDetailCacheV1.fx` | `reshade-shaders/Shaders/camera_obscura_detail_cache/effects/CAMERA_OBSCURA_StabilizedDetailCacheV1.fx` |

`ReShade.fxh` is the only external shader-framework dependency admitted by the
package validator.
