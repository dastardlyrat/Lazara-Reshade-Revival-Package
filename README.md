# Lazara ReShade Revival Package

Lazara is a **controlled color revival effect under adverse conditions**. This
repository is the temporary standalone installation surface while the
OpenSurface storefront is being finished.

The package contains:

- the `Lazara.ini` preset;
- all 13 effect files enabled by the preset;
- the complete local header closure required by those effects;
- the Camera Obscura External Image Denoiser and Stabilized Detail Cache;
- pinned temporary copies of Lazara, Occult Box, and Guided Detail source;
- on/off comparison images, hashes, and a reproducible stitch builder.

`ReShade.fxh` remains an external dependency supplied by ReShade. This package
does not replace it.

## On/off comparison

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

## Temporary vendoring and evidence boundary

The storefront source repositories remain authoritative. For installation
simplicity, this repository temporarily carries the exact effect/include
closure from three pinned public revisions:

- `dastardlyrat/lazara` at `2c28697a344fb988d784ed31f4d65b107821327b`;
- `dastardlyrat/Occult-Box` at `eef2b91b314ddc1a68547d0fb1daa2413adfce66`;
- `dastardlyrat/OpenSurface-CameraObscura-GuidedDetail` at
  `68850554650abe22cca029a65f7a807b6b3b3047`.

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
