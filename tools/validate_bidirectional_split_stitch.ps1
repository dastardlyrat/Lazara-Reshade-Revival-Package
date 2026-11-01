[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$ImagePath = (Join-Path $PSScriptRoot '..\docs\images\lazara-bidirectional-split-stitch.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$sourceWidth = 2560
$sourceHeight = 1440
$halfWidth = 1280
$labelHeight = 96
$expectedWidth = 5120
$expectedHeight = 1536

function Get-DecodedRegionHash {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$X,
        [int]$Y,
        [int]$Width,
        [int]$Height
    )

    $rectangle = [System.Drawing.Rectangle]::new($X, $Y, $Width, $Height)
    $pixelFormat = [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    $data = $Bitmap.LockBits(
        $rectangle,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        $pixelFormat
    )
    $hasher = [Security.Cryptography.IncrementalHash]::CreateHash(
        [Security.Cryptography.HashAlgorithmName]::SHA256
    )

    try {
        $rowBytes = $Width * 3
        $row = [byte[]]::new($rowBytes)
        for ($rowIndex = 0; $rowIndex -lt $Height; $rowIndex++) {
            $pointer = [IntPtr]::Add($data.Scan0, $rowIndex * $data.Stride)
            [Runtime.InteropServices.Marshal]::Copy($pointer, $row, 0, $rowBytes)
            $hasher.AppendData($row)
        }
        return [Convert]::ToHexString($hasher.GetHashAndReset())
    }
    finally {
        $hasher.Dispose()
        $Bitmap.UnlockBits($data)
    }
}

$offImage = [System.Drawing.Bitmap]::new((Join-Path $SourceDirectory 'set-3-off.png'))
$onImage = [System.Drawing.Bitmap]::new((Join-Path $SourceDirectory 'set-3-on.png'))
$stitch = [System.Drawing.Bitmap]::new($ImagePath)

try {
    if ($offImage.Width -ne $sourceWidth -or $offImage.Height -ne $sourceHeight) {
        throw 'Unexpected OFF source dimensions.'
    }
    if ($onImage.Width -ne $sourceWidth -or $onImage.Height -ne $sourceHeight) {
        throw 'Unexpected ON source dimensions.'
    }
    if ($stitch.Width -ne $expectedWidth -or $stitch.Height -ne $expectedHeight) {
        throw "Unexpected stitch dimensions: $($stitch.Width)x$($stitch.Height)"
    }

    $regions = @(
        @{ Name = 'ON-left'; Source = $onImage; SourceX = 0; DestinationX = 0 },
        @{ Name = 'OFF-right'; Source = $offImage; SourceX = $halfWidth; DestinationX = $halfWidth },
        @{ Name = 'OFF-left'; Source = $offImage; SourceX = 0; DestinationX = $sourceWidth },
        @{ Name = 'ON-right'; Source = $onImage; SourceX = $halfWidth; DestinationX = ($sourceWidth + $halfWidth) }
    )

    foreach ($region in $regions) {
        $sourceHash = Get-DecodedRegionHash -Bitmap $region.Source `
            -X $region.SourceX -Y 0 -Width $halfWidth -Height $sourceHeight
        $destinationHash = Get-DecodedRegionHash -Bitmap $stitch `
            -X $region.DestinationX -Y $labelHeight `
            -Width $halfWidth -Height $sourceHeight
        if ($sourceHash -ne $destinationHash) {
            throw "Decoded-pixel mismatch: $($region.Name)"
        }
        Write-Output "PASS|$($region.Name)|$sourceHash"
    }
}
finally {
    $stitch.Dispose()
    $onImage.Dispose()
    $offImage.Dispose()
}

Write-Output 'SUMMARY|decoded_source_regions=4|mismatches=0'
