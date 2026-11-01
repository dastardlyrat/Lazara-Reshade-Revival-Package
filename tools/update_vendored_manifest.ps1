[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$vendorRoot = Join-Path $root 'reshade-shaders\Shaders\vendor'
$outputPath = Join-Path $root 'VENDORED_SHA256SUMS.txt'

$lines = Get-ChildItem -LiteralPath $vendorRoot -Recurse -File |
    Sort-Object FullName |
    ForEach-Object {
        $relative = $_.FullName.Substring($root.Length + 1).Replace('\', '/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash
        "$hash  $relative"
    }

$content = ($lines -join "`n") + "`n"
[IO.File]::WriteAllText($outputPath, $content, [Text.UTF8Encoding]::new($false))

[pscustomobject]@{
    Output = $outputPath
    Entries = $lines.Count
    SHA256 = (Get-FileHash -LiteralPath $outputPath -Algorithm SHA256).Hash
}
