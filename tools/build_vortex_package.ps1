[CmdletBinding()]
param(
    [string]$Version = '1.0.0',
    [string]$OutputDirectory = (Join-Path $PSScriptRoot '..\dist'),
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$repositoryRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$artifactName = "Lazara-Reshade-Revival-Package-$Version-Vortex.zip"
$outputRoot = [IO.Path]::GetFullPath($OutputDirectory)
$artifactPath = Join-Path $outputRoot $artifactName
$sidecarPath = "$artifactPath.sha256"

if ($Version -notmatch '^\d+\.\d+\.\d+$') {
    throw "Version must use semantic versioning (for example, 1.0.0): $Version"
}

if ((Test-Path -LiteralPath $artifactPath) -and -not $Force) {
    throw "Artifact already exists. Use -Force to replace it: $artifactPath"
}

& (Join-Path $PSScriptRoot 'validate_package.ps1')
if ($LASTEXITCODE -ne 0) {
    throw 'Base package validation failed.'
}

New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null
$stagingRoot = Join-Path ([IO.Path]::GetTempPath()) (
    'lazara-vortex-stage-' + [guid]::NewGuid().ToString('N')
)
New-Item -ItemType Directory -Path $stagingRoot | Out-Null

function Copy-PackageFile {
    param(
        [string]$Source,
        [string]$Destination
    )

    $parent = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $parent)) {
        New-Item -ItemType Directory -Path $parent -Force | Out-Null
    }
    Copy-Item -LiteralPath $Source -Destination $Destination
}

try {
    Copy-PackageFile `
        -Source (Join-Path $repositoryRoot 'Lazara.ini') `
        -Destination (Join-Path $stagingRoot 'Lazara.ini')
    Copy-Item `
        -LiteralPath (Join-Path $repositoryRoot 'reshade-shaders') `
        -Destination (Join-Path $stagingRoot 'reshade-shaders') `
        -Recurse
    Copy-PackageFile `
        -Source (Join-Path $repositoryRoot 'packaging\vortex\vortex_override_instructions.json') `
        -Destination (Join-Path $stagingRoot 'vortex_override_instructions.json')

    $documentationRoot = Join-Path $stagingRoot 'Lazara-Documentation'
    New-Item -ItemType Directory -Path $documentationRoot | Out-Null
    foreach ($name in @(
        'DEPENDENCIES.md',
        'dependencies.lock.json',
        'VENDORED_SHA256SUMS.txt'
    )) {
        Copy-PackageFile `
            -Source (Join-Path $repositoryRoot $name) `
            -Destination (Join-Path $documentationRoot $name)
    }
    Copy-PackageFile `
        -Source (Join-Path $repositoryRoot 'packaging\vortex\NEXUS_README.txt') `
        -Destination (Join-Path $documentationRoot 'NEXUS_README.txt')
    Copy-Item `
        -LiteralPath (Join-Path $repositoryRoot 'LICENSES') `
        -Destination (Join-Path $documentationRoot 'LICENSES') `
        -Recurse

    $sourceCommit = (& git -C $repositoryRoot rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $sourceCommit -notmatch '^[0-9a-f]{40}$') {
        throw 'Could not resolve the source Git commit.'
    }

    $manifest = [ordered]@{
        schema_version = 1
        package_name = 'Lazara ReShade Revival Package'
        version = $Version
        source_repository = 'https://github.com/dastardlyrat/Lazara-Reshade-Revival-Package'
        source_commit = $sourceCommit
        deployment_target = 'game-root'
        vortex_minimum_version = '1.14.0'
        vortex_mod_type = 'dinput'
        vortex_collections_supported = $false
        preset = 'Lazara.ini'
        shader_files = 108
        effect_files = 13
        external_framework_files = @('ReShade.fxh')
        vendoring_status = 'perfunctive peddling; non-transactional; non-monetary'
        ai_assisted_packaging = $true
    }
    $manifestJson = ($manifest | ConvertTo-Json -Depth 5) + "`n"
    [IO.File]::WriteAllText(
        (Join-Path $stagingRoot 'Lazara-Package-Manifest.json'),
        $manifestJson,
        [Text.UTF8Encoding]::new($false)
    )

    if (Test-Path -LiteralPath $artifactPath) {
        [IO.File]::Delete($artifactPath)
    }
    if (Test-Path -LiteralPath $sidecarPath) {
        [IO.File]::Delete($sidecarPath)
    }

    $archiveStream = [IO.File]::Open(
        $artifactPath,
        [IO.FileMode]::CreateNew,
        [IO.FileAccess]::ReadWrite,
        [IO.FileShare]::None
    )
    $archive = [IO.Compression.ZipArchive]::new(
        $archiveStream,
        [IO.Compression.ZipArchiveMode]::Create,
        $false
    )
    try {
        $files = Get-ChildItem -LiteralPath $stagingRoot -File -Recurse |
            Sort-Object FullName
        foreach ($file in $files) {
            $relative = $file.FullName.Substring($stagingRoot.Length + 1).Replace('\', '/')
            $entry = $archive.CreateEntry(
                $relative,
                [IO.Compression.CompressionLevel]::Optimal
            )
            $entry.LastWriteTime = [DateTimeOffset]::new(
                2000,
                1,
                1,
                0,
                0,
                0,
                [TimeSpan]::Zero
            )
            $input = [IO.File]::OpenRead($file.FullName)
            $output = $entry.Open()
            try {
                $input.CopyTo($output)
            }
            finally {
                $output.Dispose()
                $input.Dispose()
            }
        }
        $entryCount = $files.Count
    }
    finally {
        $archive.Dispose()
        $archiveStream.Dispose()
    }

    $hash = (Get-FileHash -LiteralPath $artifactPath -Algorithm SHA256).Hash
    [IO.File]::WriteAllText(
        $sidecarPath,
        "$hash  $artifactName`n",
        [Text.UTF8Encoding]::new($false)
    )

    [pscustomobject]@{
        Artifact = $artifactPath
        Version = $Version
        SourceCommit = $sourceCommit
        Entries = $entryCount
        Bytes = (Get-Item -LiteralPath $artifactPath).Length
        SHA256 = $hash
        Sidecar = $sidecarPath
    }
}
finally {
    if (Test-Path -LiteralPath $stagingRoot) {
        Get-ChildItem -LiteralPath $stagingRoot -File -Recurse -Force |
            ForEach-Object { $_.Attributes = [IO.FileAttributes]::Normal }
        [IO.Directory]::Delete($stagingRoot, $true)
    }
}
