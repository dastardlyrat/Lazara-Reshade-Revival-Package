[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$ImagePath = (Join-Path $PSScriptRoot '..\docs\images\lazara-twin-lantern-two-way.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$panelWidth = 2560
$panelHeight = 1440

function Get-DecodedRegionHash {
    param(
        [System.Drawing.Bitmap]$Bitmap,
        [int]$X,
        [int]$Width,
        [int]$Height
    )

    $rectangle = [System.Drawing.Rectangle]::new($X, 0, $Width, $Height)
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

$leftImage = [System.Drawing.Bitmap]::new(
    (Join-Path $SourceDirectory 'Lazara-Twin-Lantern.png')
)
$rightImage = [System.Drawing.Bitmap]::new(
    (Join-Path $SourceDirectory 'BASEReFlexAgX-Lazara-Twin-Lantern.png')
)
$comparison = [System.Drawing.Bitmap]::new($ImagePath)

try {
    if ($comparison.Width -ne ($panelWidth * 2) -or $comparison.Height -ne $panelHeight) {
        throw "Unexpected comparison dimensions: $($comparison.Width)x$($comparison.Height)"
    }

    $checks = @(
        @{ Name = 'Lazara-Twin-Lantern'; Source = $leftImage; DestinationX = 0 },
        @{ Name = 'BASEReFlexAgX-Lazara-Twin-Lantern'; Source = $rightImage; DestinationX = $panelWidth }
    )
    foreach ($check in $checks) {
        if ($check.Source.Width -ne $panelWidth -or $check.Source.Height -ne $panelHeight) {
            throw "Unexpected source dimensions: $($check.Name)"
        }
        $sourceHash = Get-DecodedRegionHash -Bitmap $check.Source `
            -X 0 -Width $panelWidth -Height $panelHeight
        $destinationHash = Get-DecodedRegionHash -Bitmap $comparison `
            -X $check.DestinationX -Width $panelWidth -Height $panelHeight
        if ($sourceHash -ne $destinationHash) {
            throw "Decoded-pixel mismatch: $($check.Name)"
        }
        Write-Output "PASS|$($check.Name)|$sourceHash"
    }
}
finally {
    $comparison.Dispose()
    $rightImage.Dispose()
    $leftImage.Dispose()
}

Write-Output 'SUMMARY|decoded_source_regions=2|mismatches=0'
