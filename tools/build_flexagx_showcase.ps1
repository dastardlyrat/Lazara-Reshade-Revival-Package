[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\images\lazara-flexagx-side-by-side.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$panelWidth = 2560
$panelHeight = 1440
$canvasWidth = $panelWidth * 2
$canvasHeight = $panelHeight
$view1Path = Join-Path $SourceDirectory 'flexagx-view-1.png'
$view2Path = Join-Path $SourceDirectory 'flexagx-view-2.png'

foreach ($path in @($view1Path, $view2Path)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing source image: $path"
    }
}

function Copy-BitmapPixelsExact {
    param(
        [System.Drawing.Bitmap]$Source,
        [System.Drawing.Bitmap]$Destination,
        [int]$DestinationX
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
            $destinationOffset = ($y * $destinationData.Stride) + ($DestinationX * 3)
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

$view1 = [System.Drawing.Bitmap]::new($view1Path)
$view2 = [System.Drawing.Bitmap]::new($view2Path)
$canvas = [System.Drawing.Bitmap]::new(
    $canvasWidth,
    $canvasHeight,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)

try {
    foreach ($image in @($view1, $view2)) {
        if ($image.Width -ne $panelWidth -or $image.Height -ne $panelHeight) {
            throw "Unexpected source dimensions: $($image.Width)x$($image.Height)"
        }
    }

    Copy-BitmapPixelsExact -Source $view1 -Destination $canvas -DestinationX 0
    Copy-BitmapPixelsExact -Source $view2 -Destination $canvas -DestinationX $panelWidth
    $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $canvas.Dispose()
    $view2.Dispose()
    $view1.Dispose()
}

$result = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Output = $result.FullName
    Width = $canvasWidth
    Height = $canvasHeight
    Bytes = $result.Length
    SHA256 = (Get-FileHash -LiteralPath $result.FullName -Algorithm SHA256).Hash
}
