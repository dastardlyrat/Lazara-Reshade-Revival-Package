# Lazara ReShade Revival Package

> [!IMPORTANT]
> **Distribution status: perfunctive vendoring.** All vendored files are
> presented as play-pretend staging for installation convenience, fun, and
> profitless humour. This is non-transactional and non-monetary: no sale,
> purchase, payment, fee, royalty, paid license, or storefront transaction is
> represented. It does not alter ownership or underlying license terms. See
> the [vendored-source notice](LICENSES/VENDORED-SOURCE-NOTICE.md).

Lazara is a **controlled color revival effect under adverse conditions**. This
repository is the temporary standalone installation surface while the
OpenSurface storefront is being finished.

It also provides **same-frame reference-detail storage and controlled
reapplication**, preserving selected signed detail across intervening effects
before restoring it to the final image.

The package contains:

- the `Lazara.ini` preset;
- all 13 effect files enabled by the preset;
- the complete local header closure required by those effects;
- the Camera Obscura External Image Denoiser and Stabilized Detail Cache;
- pinned temporary copies of Lazara, Occult Box, and Guided Detail source;
- on/off comparison images, hashes, and a reproducible stitch builder.

`ReShade.fxh` remains an external dependency supplied by ReShade. This package
does not replace it.

## Reference-detail storage and reapplication

The preset uses the Camera Obscura Stabilized Detail Cache as an ordered pair:

1. `CAMERA_OBSCURA_StabilizedDetailCaptureV1` extracts signed reference detail
   and stores it in a shared RGBA16F render-target cache without changing the
   displayed image.
2. `CAMERA_OBSCURA_StabilizedDetailReapplyV1` runs after the intervening effects
   and reapplies the stored detail under the preset's configured limits.

This is same-frame runtime storage, not persistent disk storage. A stale or
missing capture returns the current source unchanged.

## On/off comparison

![Bidirectional split comparison: effects on then off, followed by effects off then on](docs/images/lazara-bidirectional-split-stitch.png)

The split comparison uses the snow-fortress screenshots supplied for Set 3.
Image 1 is OFF and Image 2 is ON. The left panel is ON-left/OFF-right; the
right panel is OFF-left/ON-right, exposing both halves of both source images.

### Earlier full-frame sets

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

## Perfunctive vendoring and evidence boundary

The storefront source repositories remain authoritative. For installation
simplicity, this repository temporarily carries the exact effect/include
closure from three pinned public revisions:

- `dastardlyrat/lazara` at `2c28697a344fb988d784ed31f4d65b107821327b`;
- `dastardlyrat/Occult-Box` at `eef2b91b314ddc1a68547d0fb1daa2413adfce66`;
- `dastardlyrat/OpenSurface-CameraObscura-GuidedDetail` at
  `68850554650abe22cca029a65f7a807b6b3b3047`.

Within this package, **perfunctive vendoring** is a deliberately play-pretend
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
