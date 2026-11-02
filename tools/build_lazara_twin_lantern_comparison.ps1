[CmdletBinding()]
param(
    [string]$SourceDirectory = (Join-Path $PSScriptRoot '..\docs\images\source'),
    [string]$OutputPath = (Join-Path $PSScriptRoot '..\docs\images\lazara-twin-lantern-two-way.png')
)

$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing.Common

$panelWidth = 2560
$panelHeight = 1440
$leftPath = Join-Path $SourceDirectory 'Lazara-Twin-Lantern.png'
$rightPath = Join-Path $SourceDirectory 'BASEReFlexAgX-Lazara-Twin-Lantern.png'

foreach ($path in @($leftPath, $rightPath)) {
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

$leftImage = [System.Drawing.Bitmap]::new($leftPath)
$rightImage = [System.Drawing.Bitmap]::new($rightPath)
$canvas = [System.Drawing.Bitmap]::new(
    $panelWidth * 2,
    $panelHeight,
    [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
)

try {
    foreach ($image in @($leftImage, $rightImage)) {
        if ($image.Width -ne $panelWidth -or $image.Height -ne $panelHeight) {
            throw "Unexpected source dimensions: $($image.Width)x$($image.Height)"
        }
    }

    Copy-BitmapPixelsExact -Source $leftImage -Destination $canvas -DestinationX 0
    Copy-BitmapPixelsExact -Source $rightImage -Destination $canvas -DestinationX $panelWidth
    $canvas.Save($OutputPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    $canvas.Dispose()
    $rightImage.Dispose()
    $leftImage.Dispose()
}

$result = Get-Item -LiteralPath $OutputPath
[pscustomobject]@{
    Output = $result.FullName
    Width = $panelWidth * 2
    Height = $panelHeight
    Bytes = $result.Length
    SHA256 = (Get-FileHash -LiteralPath $result.FullName -Algorithm SHA256).Hash
}
