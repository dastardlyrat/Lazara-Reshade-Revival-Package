[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\images\lazara-on-off-stitch.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$panelWidth = 2560
$panelHeight = 1440
$labelHeight = 96
$rowHeight = $labelHeight + $panelHeight
$canvasWidth = $panelWidth * 2
$canvasHeight = $rowHeight * 2

$panels = @(
    @{ File = 'set-1-off.png'; Label = 'SET 1  |  OFF'; Column = 0; Row = 0 },
    @{ File = 'set-1-on.png';  Label = 'SET 1  |  ON';  Column = 1; Row = 0 },
    @{ File = 'set-2-off.png'; Label = 'SET 2  |  OFF'; Column = 0; Row = 1 },
    @{ File = 'set-2-on.png';  Label = 'SET 2  |  ON';  Column = 1; Row = 1 }
)

$outputDirectory = Split-Path -Parent $OutputPath
if (-not (Test-Path -LiteralPath $outputDirectory)) {
    New-Item -ItemType Directory -Path $outputDirectory | Out-Null
}

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
$loadedImages = [System.Collections.Generic.List[System.Drawing.Image]]::new()

function Copy-BitmapPixelsExact {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Bitmap]$Destination,
        [int]$DestinationX,
        [int]$DestinationY
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
        $rowBytes = $Source.Width * 3
        $row = [byte[]]::new($rowBytes)
        for ($y = 0; $y -lt $Source.Height; $y++) {
            $sourcePointer = [IntPtr]::Add($sourceData.Scan0, $y * $sourceData.Stride)
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

try {
    $graphics.Clear([System.Drawing.Color]::FromArgb(18, 18, 18))
    $graphics.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    foreach ($panel in $panels) {
        $sourcePath = Join-Path $SourceDirectory $panel.File
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            throw "Missing source image: $sourcePath"
        }

        $image = [System.Drawing.Bitmap]::new($sourcePath)
        $loadedImages.Add($image)
        if ($image.Width -ne $panelWidth -or $image.Height -ne $panelHeight) {
            throw "Unexpected dimensions for $($panel.File): $($image.Width)x$($image.Height)"
        }

        $x = $panel.Column * $panelWidth
        $labelY = $panel.Row * $rowHeight
        $imageY = $labelY + $labelHeight
        $graphics.FillRectangle($barBrush, $x, $labelY, $panelWidth, $labelHeight)
        $graphics.DrawString($panel.Label, $labelFont, $labelBrush, $x + 34, $labelY + 22)
        Copy-BitmapPixelsExact -Source $image -Destination $canvas -DestinationX $x -DestinationY $imageY
    }

    $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    foreach ($image in $loadedImages) {
        $image.Dispose()
    }
    $barBrush.Dispose()
    $labelBrush.Dispose()
    $labelFont.Dispose()
    $graphics.Dispose()
    $canvas.Dispose()
}

$result = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Output = $result.FullName
    Width = $canvasWidth
    Height = $canvasHeight
    Bytes = $result.Length
    SHA256 = (Get-FileHash -LiteralPath $result.FullName -Algorithm SHA256).Hash
}
