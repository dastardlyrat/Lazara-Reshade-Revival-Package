[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\images\lazara-bidirectional-split-stitch.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$sourceWidth = 2560
$sourceHeight = 1440
$halfWidth = [int]($sourceWidth / 2)
$labelHeight = 96
$canvasWidth = $sourceWidth * 2
$canvasHeight = $labelHeight + $sourceHeight

$offPath = Join-Path $SourceDirectory 'set-3-off.png'
$onPath = Join-Path $SourceDirectory 'set-3-on.png'
foreach ($path in @($offPath, $onPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source image: $path"
    }
}

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

function Copy-BitmapRegionExact {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Bitmap]$Destination,
        [int]$SourceX,
        [int]$DestinationX,
        [int]$DestinationY,
        [int]$Width,
        [int]$Height
    )

    $sourceRectangle = [System.Drawing.Rectangle]::new(0, 0, $Source.Width, $Source.Height)
    $destinationRectangle = [System.Drawing.Rectangle]::new(
        0,
        0,
        $Destination.Width,
        $Destination.Height
    )
    $pixelFormat = [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
    $sourceData = $Source.LockBits(
        $sourceRectangle,
        [System.Drawing.Imaging.ImageLockMode]::ReadOnly,
        $pixelFormat
    )
    $destinationData = $Destination.LockBits(
        $destinationRectangle,
        [System.Drawing.Imaging.ImageLockMode]::ReadWrite,
        $pixelFormat
    )

    try {
        $rowBytes = $Width * 3
        $row = [byte[]]::new($rowBytes)
        for ($y = 0; $y -lt $Height; $y++) {
            $sourceOffset = ($y * $sourceData.Stride) + ($SourceX * 3)
            $sourcePointer = [IntPtr]::Add($sourceData.Scan0, $sourceOffset)
            $destinationOffset = (
                ($DestinationY + $y) * $destinationData.Stride
            ) + ($DestinationX * 3)
            $destinationPointer = [IntPtr]::Add($destinationData.Scan0, $destinationOffset)
            [Runtime.InteropServices.Marshal]::Copy($sourcePointer, $row, 0, $rowBytes)
            [Runtime.InteropServices.Marshal]::Copy($row, 0, $destinationPointer, $rowBytes)
        }
    }
    finally {
        $Destination.UnlockBits($destinationData)
        $Source.UnlockBits($sourceData)
    }
}

$offImage = [System.Drawing.Bitmap]::new($offPath)
$onImage = [System.Drawing.Bitmap]::new($onPath)
$canvas = [System.Drawing.Bitmap]::new(
    $canvasWidth,
    $canvasHeight,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)
$graphics = [System.Drawing.Graphics]::FromImage($canvas)
$labelFont = [System.Drawing.Font]::new(
    [System.Drawing.FontFamily]::GenericSansSerif,
    34,
    [System.Drawing.FontStyle]::Bold,
    [System.Drawing.GraphicsUnit]::Pixel
)
$labelBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)
$barBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::FromArgb(18, 18, 18))

try {
    foreach ($image in @($offImage, $onImage)) {
        if ($image.Width -ne $sourceWidth -or $image.Height -ne $sourceHeight) {
            throw "Unexpected source dimensions: $($image.Width)x$($image.Height)"
        }
    }

    $graphics.Clear([System.Drawing.Color]::FromArgb(18, 18, 18))
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
    $graphics.FillRectangle($barBrush, 0, 0, $sourceWidth, $labelHeight)
    $graphics.FillRectangle($barBrush, $sourceWidth, 0, $sourceWidth, $labelHeight)
    $graphics.DrawString('EFFECTS ON  ->  OFF', $labelFont, $labelBrush, 34, 22)
    $graphics.DrawString('EFFECTS OFF  ->  ON', $labelFont, $labelBrush, $sourceWidth + 34, 22)

    # Panel 1: ON-left then OFF-right.
    Copy-BitmapRegionExact -Source $onImage -Destination $canvas `
        -SourceX 0 -DestinationX 0 -DestinationY $labelHeight `
        -Width $halfWidth -Height $sourceHeight
    Copy-BitmapRegionExact -Source $offImage -Destination $canvas `
        -SourceX $halfWidth -DestinationX $halfWidth -DestinationY $labelHeight `
        -Width $halfWidth -Height $sourceHeight

    # Panel 2: OFF-left then ON-right.
    Copy-BitmapRegionExact -Source $offImage -Destination $canvas `
        -SourceX 0 -DestinationX $sourceWidth -DestinationY $labelHeight `
        -Width $halfWidth -Height $sourceHeight
    Copy-BitmapRegionExact -Source $onImage -Destination $canvas `
        -SourceX $halfWidth -DestinationX ($sourceWidth + $halfWidth) `
        -DestinationY $labelHeight -Width $halfWidth -Height $sourceHeight

    $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $barBrush.Dispose()
    $labelBrush.Dispose()
    $labelFont.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
    $onImage.Dispose()
    $offImage.Dispose()
}

$result = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Output = $result.FullName
    Width = $canvasWidth
    Height = $canvasHeight
    Bytes = $result.Length
    SHA256 = (Get-FileHash -LiteralPath $result.FullName -Algorithm SHA256).Hash
}
