# Lazara ReShade Package

This repository combines the `Lazara.ini` preset with its project-owned
ReShade effects without copying source that already has an authoritative public
repository.

- Camera Obscura External Image Denoiser and Stabilized Detail Cache are
  published directly in `reshade-shaders/Shaders`.
- Lazara, Occult Box, and Guided Detail are pinned as Git submodules under
  `upstream`.
- `ReShade.fxh` is an external dependency supplied by the installed ReShade
  shader package. This repository does not replace it.

## Install

Do not use GitHub's **Download ZIP** for this repository: source archives do
not populate the linked submodule repositories.

Clone with the links populated:

```powershell
git clone --recurse-submodules https://github.com/dastardlyrat/Lazara-Reshade-Package.git
```

If the repository was already cloned:

```powershell
git submodule update --init --recursive
```

In ReShade, add these recursive effect search paths, replacing `<package>` with
the cloned repository directory. Keep the installed ReShade shader directory
first so its current `ReShade.fxh` takes precedence:

```text
.\reshade-shaders\Shaders\**
<package>\reshade-shaders\Shaders\**
<package>\upstream\lazara\reshade-shaders\Shaders\**
<package>\upstream\Occult-Box\**
<package>\upstream\OpenSurface-CameraObscura-GuidedDetail\**
```

Then select `Lazara.ini` as the preset and reload effects.

The linked Lazara source repository contains a `ReShade.fxh` for its own local
preprocessing checks. Do not copy that file over a newer installation-provided
version.

## Contents and evidence boundary

`Lazara.ini` enables 14 techniques from 13 effect files. The complete mapping,
pinned revisions, and local file hashes are recorded in
[`DEPENDENCIES.md`](DEPENDENCIES.md) and
[`dependencies.lock.json`](dependencies.lock.json).

The two directly published Camera Obscura effects were taken from the validated
OpenSurface public export dated 2026-10-31. Its repository validator passed
16/16 structural and publication checks. This publication step verifies file
identity and dependency closure; it is not a new live ReShade compile or visual
acceptance run.

## Licensing

The directly published Camera Obscura shader and header files carry MIT SPDX
metadata and are covered by
[`LICENSES/Camera-Obscura-MIT.txt`](LICENSES/Camera-Obscura-MIT.txt).
Linked repositories retain their own authorship and license terms. No
project-wide license is asserted here for material that has not received one.
