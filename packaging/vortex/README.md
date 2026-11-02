# Nexus/Vortex package

This directory defines the Nexus upload artifact for Lazara. The generated ZIP
has no wrapper directory: `Lazara.ini`, `reshade-shaders`, and
`vortex_override_instructions.json` are at the archive root.

## Vortex deployment

Vortex 1.14.0 and newer supports root-level
[`vortex_override_instructions.json`](https://github.com/Nexus-Mods/Vortex/wiki/File-Based-Override-Instructions).
The package assigns the universal `dinput` (Engine Injector) mod type, which
deploys files to the game root. Vortex does not apply this override when a mod
is installed through a Collection, so the Nexus page must retain the direct
download and manual-install fallback instructions.

This package does not need a FOMOD: it has one required payload and no install
choices. Avoid adding nested archives; Nexus recommends ZIP or 7z and may
quarantine uploads containing an archive inside another archive.

## Build and validate

From the repository root:

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\build_vortex_package.ps1
powershell -ExecutionPolicy Bypass -File .\tools\validate_vortex_package.ps1
```

The default generated artifact is:

```text
dist/Lazara-Reshade-Revival-Package-1.0.0-Vortex.zip
```

Upload the ZIP as a Nexus **Main File** with version `1.0.0`. Keep the generated
SHA-256 sidecar locally or publish its hash in the file description; do not put
the sidecar inside the upload ZIP.

## Upload notes

- Target page: the supported game's Nexus Mods section.
- File category: Main Files.
- File name: `Lazara ReShade Revival Package 1.0.0 - Vortex`.
- State that ReShade is required and not bundled.
- State that Vortex 1.14+ direct installation targets the game root.
- State that Collections and older Vortex versions require manual installation.
- Disclose the AI-assisted documentation and packaging workflow.
- Do not describe static package validation as universal live-game validation.
