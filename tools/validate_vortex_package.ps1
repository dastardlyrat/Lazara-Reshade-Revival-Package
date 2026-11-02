[CmdletBinding()]
param(
    [string]$PackagePath = (Join-Path $PSScriptRoot '..\dist\Lazara-Reshade-Revival-Package-1.0.0-Vortex.zip'),
    [string]$ExpectedVersion = '1.0.0'
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$resolvedPackage = [IO.Path]::GetFullPath($PackagePath)
if (-not (Test-Path -LiteralPath $resolvedPackage)) {
    throw "Package not found: $resolvedPackage"
}

function Get-EntryText {
    param([IO.Compression.ZipArchiveEntry]$Entry)

    $reader = [IO.StreamReader]::new($Entry.Open(), [Text.Encoding]::UTF8)
    try {
        return $reader.ReadToEnd()
    }
    finally {
        $reader.Dispose()
    }
}

function Get-StreamHash {
    param([IO.Stream]$Stream)

    $sha = [Security.Cryptography.SHA256]::Create()
    try {
        return [Convert]::ToHexString($sha.ComputeHash($Stream))
    }
    finally {
        $sha.Dispose()
    }
}

$archive = [IO.Compression.ZipFile]::OpenRead($resolvedPackage)
try {
    $entries = @($archive.Entries | Where-Object { -not [string]::IsNullOrEmpty($_.Name) })
    $paths = @($entries | ForEach-Object { $_.FullName })
    $duplicates = @($paths | Group-Object | Where-Object Count -gt 1)
    if ($duplicates.Count -gt 0) {
        throw 'Archive contains duplicate paths.'
    }

    foreach ($required in @(
        'Lazara.ini',
        'Lazara-Package-Manifest.json',
        'vortex_override_instructions.json',
        'Lazara-Documentation/NEXUS_README.txt'
    )) {
        if ($required -notin $paths) {
            throw "Missing required root/package entry: $required"
        }
    }
    if (-not ($paths | Where-Object { $_ -like 'reshade-shaders/Shaders/*' })) {
        throw 'Missing reshade-shaders payload.'
    }

    $unsafe = @($paths | Where-Object {
        $_ -match '(^/|\\|(^|/)\.\.(/|$))'
    })
    if ($unsafe.Count -gt 0) {
        throw "Unsafe archive paths: $($unsafe -join ', ')"
    }

    $prohibited = @($paths | Where-Object {
        $_ -match '(?i)\.(zip|7z|rar|exe|dll|ps1|bat|cmd|com|scr)$'
    })
    if ($prohibited.Count -gt 0) {
        throw "Prohibited or nested package files: $($prohibited -join ', ')"
    }
    $images = @($paths | Where-Object { $_ -match '(?i)\.(png|jpe?g|gif|webp)$' })
    if ($images.Count -gt 0) {
        throw "Presentation images must not be in the runtime archive: $($images -join ', ')"
    }
    if ($paths -contains 'reshade-shaders/Shaders/ReShade.fxh') {
        throw 'ReShade.fxh must remain external.'
    }

    $overrideEntry = $archive.GetEntry('vortex_override_instructions.json')
    $override = @(Get-EntryText $overrideEntry | ConvertFrom-Json)
    if ($override.Count -ne 1 -or
        $override[0].type -ne 'setmodtype' -or
        $override[0].value -ne 'dinput') {
        throw 'Vortex override must assign the dinput game-root mod type.'
    }

    $manifestEntry = $archive.GetEntry('Lazara-Package-Manifest.json')
    $manifest = Get-EntryText $manifestEntry | ConvertFrom-Json
    if ($manifest.version -ne $ExpectedVersion -or
        $manifest.deployment_target -ne 'game-root' -or
        $manifest.vortex_minimum_version -ne '1.14.0' -or
        $manifest.vortex_mod_type -ne 'dinput' -or
        $manifest.vortex_collections_supported -ne $false) {
        throw 'Package manifest does not match the supported Vortex contract.'
    }

    $shaderEntries = @($entries | Where-Object {
        $_.FullName -match '^reshade-shaders/Shaders/.+\.(fx|fxh)$'
    })
    $effectEntries = @($shaderEntries | Where-Object { $_.FullName -match '\.fx$' })
    $headerEntries = @($shaderEntries | Where-Object { $_.FullName -match '\.fxh$' })
    if ($shaderEntries.Count -ne 110 -or
        $effectEntries.Count -ne 15 -or
        $headerEntries.Count -ne 95) {
        throw (
            "Unexpected shader counts: all=$($shaderEntries.Count), " +
            "effects=$($effectEntries.Count), headers=$($headerEntries.Count)"
        )
    }

    $sourceMappings = [ordered]@{
        'Lazara.ini' = 'Lazara.ini'
        'vortex_override_instructions.json' = 'packaging/vortex/vortex_override_instructions.json'
        'Lazara-Documentation/NEXUS_README.txt' = 'packaging/vortex/NEXUS_README.txt'
        'Lazara-Documentation/DEPENDENCIES.md' = 'DEPENDENCIES.md'
        'Lazara-Documentation/dependencies.lock.json' = 'dependencies.lock.json'
        'Lazara-Documentation/VENDORED_SHA256SUMS.txt' = 'VENDORED_SHA256SUMS.txt'
    }
    foreach ($entry in $shaderEntries) {
        $sourceMappings[$entry.FullName] = $entry.FullName
    }
    foreach ($license in Get-ChildItem -LiteralPath (Join-Path $repositoryRoot 'LICENSES') -File) {
        $sourceMappings["Lazara-Documentation/LICENSES/$($license.Name)"] =
            "LICENSES/$($license.Name)"
    }

    foreach ($mapping in $sourceMappings.GetEnumerator()) {
        $entry = $archive.GetEntry($mapping.Key)
        if ($null -eq $entry) {
            throw "Missing mapped package entry: $($mapping.Key)"
        }
        $stream = $entry.Open()
        try {
            $entryHash = Get-StreamHash $stream
        }
        finally {
            $stream.Dispose()
        }
        $sourceHash = (Get-FileHash `
            -LiteralPath (Join-Path $repositoryRoot $mapping.Value) `
            -Algorithm SHA256).Hash
        if ($entryHash -ne $sourceHash) {
            throw "Package/source hash mismatch: $($mapping.Key)"
        }
    }

    $packageHash = (Get-FileHash -LiteralPath $resolvedPackage -Algorithm SHA256).Hash
    $sidecarPath = "$resolvedPackage.sha256"
    if (Test-Path -LiteralPath $sidecarPath) {
        $sidecar = (Get-Content -LiteralPath $sidecarPath -Raw).Trim()
        $expected = "$packageHash  $([IO.Path]::GetFileName($resolvedPackage))"
        if ($sidecar -ne $expected) {
            throw 'SHA-256 sidecar does not match the package.'
        }
    }

    Write-Output 'PASS|archive_format=zip|nested_archives=0|executables=0'
    Write-Output 'PASS|deployment_target=game-root|vortex_mod_type=dinput|min_version=1.14.0'
    Write-Output (
        "PASS|shader_files=$($shaderEntries.Count)|effects=$($effectEntries.Count)|" +
        "headers=$($headerEntries.Count)|external=ReShade.fxh"
    )
    Write-Output "PASS|source_hashes=$($sourceMappings.Count)|mismatches=0"
    Write-Output "PASS|entries=$($entries.Count)|sha256=$packageHash"
    Write-Output 'SUMMARY|passed=5|failed=0'
}
finally {
    $archive.Dispose()
}
