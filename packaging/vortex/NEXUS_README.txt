LAZARA RESHADE REVIVAL PACKAGE
Vortex / Nexus installation notes

Lazara is a controlled color revival effect under adverse conditions, with
same-frame reference-detail storage and reapplication.

REQUIREMENTS

- A working ReShade installation for the game.
- ReShade's standard ReShade.fxh file. This package does not replace it.
- Vortex 1.14.0 or newer for automatic game-root deployment.

VORTEX INSTALLATION

1. Use Mod Manager Download on the Nexus Mods file page.
2. Install, enable, and deploy the mod in Vortex.
3. Start the game and open ReShade.
4. Select Lazara.ini and reload effects.
5. Keep the recursive effect search path:
   .\reshade-shaders\Shaders\**

The archive contains a root-level vortex_override_instructions.json file that
assigns Vortex's universal Engine Injector (dinput) mod type. This deploys the
preset and reshade-shaders directory beside the game executable.

Vortex does not apply file-based override instructions when installing through
a Collection. Install this package directly from its Nexus Mods file page. For
older Vortex versions or Collection use, install manually instead.

MANUAL INSTALLATION

Extract the archive into the directory containing the game executable. Merge
the included reshade-shaders directory with the existing one, then select
Lazara.ini through ReShade.

CONTENTS AND BOUNDARIES

- Lazara.ini enables 14 techniques from 13 effect files.
- The archive carries the complete local shader/include closure.
- FlexAgX is credited in the repository showcase but is not included here.
- ReShade itself and ReShade.fxh are not included.
- No executable, DLL, nested archive, or installer script is included.

PEDDLING STATUS

Copied dependencies use the package-specific term perfunctive peddling:
play-pretend staging for installation convenience, fun, and profitless humour.
It is non-transactional and non-monetary and does not alter ownership,
copyright, or underlying license terms. See Lazara-Documentation for the exact
source revisions, checksums, and retained notices.

DISCLOSURE

AI assistance was used for repository organization, documentation, validation,
and deterministic packaging tooling. The runtime shader files and preset are
the pinned package payload recorded by the included manifests.

SOURCE

https://github.com/dastardlyrat/Lazara-Reshade-Revival-Package
