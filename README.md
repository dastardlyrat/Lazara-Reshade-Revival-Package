# Lazara ReShade Revival Package

**Color revival. Detail revival. Controlled.**

Lazara is a ReShade preset and curated effect package for scenes that lose
color separation, tonal presence, and readable surface detail under adverse
conditions. Its ordered chain guards difficult fog and light, revives
chromatic and tonal structure, captures color, luma, and reference detail
before intervening effects, and reapplies each signal under independent limits
later in the same frame.

This is not a blanket saturation pass or an attempt to invent detail that was
never present. Lazara is built to make existing color legible again and
existing detail present again—deliberately, inspectably, and with direct
before/after evidence.

## For Lis — wake lazara there is another life to live

## Featuring [FlexAgX](https://github.com/El-Greco1541/FlexAgX)

![Two supplied snow-city views presented side by side, featuring FlexAgX](docs/images/lazara-flexagx-side-by-side.png)

Featuring [FlexAgX by El-Greco1541](https://github.com/El-Greco1541/FlexAgX).
The two supplied views are presented in attachment order at native resolution.
This is a showcase credit and link; FlexAgX is not peddled in this package.

![Bidirectional split comparison: effects on then off, followed by effects off then on](docs/images/lazara-bidirectional-split-stitch.png)

The snow-fortress comparison uses Image 1 as OFF and Image 2 as ON. The left
panel is ON-left/OFF-right; the right panel is OFF-left/ON-right, exposing both
halves of both source images for side-by-side inspection.

## What Lazara revives

### Color under pressure

Lazara treats color as structure, not decoration. Its technique order combines
fog/light guarding, tone-detail richness, GI color bleed, bloom treatment, and an
edge chroma ward so that muted or hostile scenes can recover separation and
presence without reducing the package to a single saturation slider.

### Color, luma, and detail with a reference

Three independent Camera Obscura cache pairs capture relative chroma, Rec. 709
luma, and selected signed reference detail. They hold those signals through
the intervening color and lighting work, then reapply each one at its own point
and under its own limits. The result is revival tied to the actual source
frame—not free-floating saturation, sharpening, or fabricated texture.

### One deliberate chain

The preset coordinates 18 enabled techniques across 15 effect files. Color,
light, denoising, guided detail, and final edge treatment are ordered as one
reproducible image path rather than a loose pile of effects.

This repository is the temporary standalone installation surface while the
OpenSurface storefront is being finished.

> [!IMPORTANT]
> **Distribution status: perfunctive peddling.** All peddled files are
> presented as play-pretend staging for installation convenience, fun, and
> profitless humour. This is non-transactional and non-monetary; full terms and
> evidence boundaries appear below.

The package contains:

- the `Lazara.ini` preset;
- all 15 effect files enabled by the preset;
- the complete local header closure required by those effects;
- the Camera Obscura External Image Denoiser and independent Stabilized Color,
  Luma, and Detail caches;
- pinned temporary copies of Lazara, Occult Box, and Guided Detail source;
- on/off comparison images, hashes, and a reproducible stitch builder.

`ReShade.fxh` remains an external dependency supplied by ReShade. This package
does not replace it.

## Reference color, luma, and detail storage and reapplication

The preset uses three isolated Camera Obscura RGBA16F caches. Each one is an
ordered capture/reapply pair:

1. `CAMERA_OBSCURA_StabilizedColorCaptureV1` stores relative chroma;
   `CAMERA_OBSCURA_StabilizedColorReapplyV1` blends current chroma toward that
   reference while preserving current luma.
2. `CAMERA_OBSCURA_StabilizedLumaCaptureV1` stores Rec. 709 luma;
   `CAMERA_OBSCURA_StabilizedLumaReapplyV1` restores a bounded amount while
   retaining the current RGB channel separation.
3. `CAMERA_OBSCURA_StabilizedDetailCaptureV1` extracts selected signed detail;
   `CAMERA_OBSCURA_StabilizedDetailReapplyV1` adds it back under independent
   limits.

The capture passes do not change the displayed image. In the supplied preset,
luma reapplies first, color second, and detail third after the intervening
effects; the edge-chroma and ink passes remain last.

This is same-frame runtime storage, not persistent disk storage. A stale or
missing capture returns the current source unchanged.

## Earlier full-frame comparisons

![Two Lazara comparison sets, each showing effects off on the left and on on the right](docs/images/lazara-on-off-stitch.png)

The castle scene is Set 1 and the eclipse scene is Set 2. In both rows, OFF is
on the left and ON is on the right. Native-resolution source images, hashes,
and rebuild instructions are recorded in
[`docs/images/README.md`](docs/images/README.md).

## Install

No submodules or secondary repository downloads are required.

1. Download this repository as a ZIP, or clone it normally.
2. Copy `reshade-shaders` into the game directory and merge it with the
   existing `reshade-shaders` directory.
3. Copy `Lazara.ini` beside the game executable, or select it through ReShade's
   preset browser.
4. In ReShade, keep the standard recursive effect search path:

   ```text
   .\reshade-shaders\Shaders\**
   ```

5. Select `Lazara.ini` and reload effects.

Keep the installation's current `ReShade.fxh`. The package intentionally does
not include or overwrite that framework file.

## Perfunctive peddling and evidence boundary

The storefront source repositories remain authoritative. For installation
simplicity, this repository temporarily carries the exact effect/include
closure from three pinned public revisions:

- `dastardlyrat/lazara` at `2c28697a344fb988d784ed31f4d65b107821327b`;
- `dastardlyrat/Occult-Box` at `eef2b91b314ddc1a68547d0fb1daa2413adfce66`;
- `dastardlyrat/OpenSurface-CameraObscura-GuidedDetail` at
  `68850554650abe22cca029a65f7a807b6b3b3047`.

Within this package, **perfunctive peddling** is a deliberately play-pretend
staging convention used for installation convenience, fun, and profitless
humour. It is non-transactional and non-monetary: inclusion of these files does
not represent a sale, purchase, payment, fee, royalty, paid license, or
storefront transaction. The label describes this package's distribution
posture only; it does not change ownership or any underlying license terms.

The complete mapping is in [`DEPENDENCIES.md`](DEPENDENCIES.md), the
machine-readable source lock is [`dependencies.lock.json`](dependencies.lock.json),
and every copied byte is recorded in
[`VENDORED_SHA256SUMS.txt`](VENDORED_SHA256SUMS.txt).

Run the package validator from the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\validate_package.ps1
```

Validation establishes preset coverage, local include closure, pinned copied
bytes, and the absence of Git submodules. It does not substitute for a new live
ReShade compile, performance pass, or visual acceptance run.

## Licensing

Camera Obscura and Guided Detail files are published under MIT; their license
texts are retained in [`LICENSES`](LICENSES). Lazara and Occult Box do not
currently declare project-wide licenses. Their temporary inclusion here is
owner-authorized source distribution and does not invent or imply broader
license terms. See [`LICENSES/VENDORED-SOURCE-NOTICE.md`](LICENSES/VENDORED-SOURCE-NOTICE.md).
