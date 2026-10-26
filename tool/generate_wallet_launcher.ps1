param([string]$Source, [ValidatePattern('^[a-z0-9_]+$')][string]$Variant = 'wallet_letter_v5')
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing
$appRoot = Split-Path $PSScriptRoot -Parent
$repoRoot = Split-Path $appRoot -Parent
if (!$Source) { $Source = Join-Path $appRoot "assets/branding/finora_${Variant}_foreground.png" }
$resRoot = Join-Path $appRoot 'android/app/src/main/res'
$art = [System.Drawing.Bitmap]::new($Source)
try {
    if ($art.GetPixel(0, 0).A -ne 0) { throw 'Expected a transparent source image.' }
    $minX = $art.Width; $minY = $art.Height; $maxX = 0; $maxY = 0
    for ($y = 0; $y -lt $art.Height; $y += 2) {
        for ($x = 0; $x -lt $art.Width; $x += 2) {
            if ($art.GetPixel($x, $y).A -gt 24) {
                $minX = [Math]::Min($minX, $x); $maxX = [Math]::Max($maxX, $x)
                $minY = [Math]::Min($minY, $y); $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    $centerX = ($minX + $maxX) / 2; $centerY = ($minY + $maxY) / 2
    $radius = 1.0
    for ($y = 0; $y -lt $art.Height; $y += 2) {
        for ($x = 0; $x -lt $art.Width; $x += 2) {
            if ($art.GetPixel($x, $y).A -gt 24) {
                $radius = [Math]::Max($radius, [Math]::Sqrt([Math]::Pow($x - $centerX, 2) + [Math]::Pow($y - $centerY, 2)))
            }
        }
    }
    # Only package/resample the generated art; preserve its geometry and alpha.
    function Save-LauncherImage([string]$Path, [int]$Size, [double]$SafeRadius, [bool]$Transparent, [bool]$Round) {
        $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.Color]::Transparent)
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            if ($Round) {
                $mask = [System.Drawing.Drawing2D.GraphicsPath]::new()
                try { $mask.AddEllipse(0, 0, $Size, $Size); $graphics.SetClip($mask) } finally { $mask.Dispose() }
            }
            if (!$Transparent) {
                $brush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#0A1020'))
                try { $graphics.FillRectangle($brush, 0, 0, $Size, $Size) } finally { $brush.Dispose() }
            }
            $scale = ($Size * $SafeRadius) / ($radius + 4)
            $rectangle = [System.Drawing.RectangleF]::new(
                [single]($Size / 2 - $centerX * $scale), [single]($Size / 2 - $centerY * $scale),
                [single]($art.Width * $scale), [single]($art.Height * $scale))
            $graphics.DrawImage($art, $rectangle)
            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally { $graphics.Dispose(); $bitmap.Dispose() }
    }
    $backupRoot = Join-Path $repoRoot ('docs/branding/launcher-before-wallet-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
    New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null
    $sizes = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
    foreach ($density in $sizes.Keys) {
        $folder = Join-Path $resRoot "mipmap-$density"
        $backup = Join-Path $backupRoot "mipmap-$density"
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        foreach ($name in @('ic_launcher.png', 'ic_launcher_round.png')) {
            Copy-Item -LiteralPath (Join-Path $folder $name) -Destination (Join-Path $backup $name)
            Save-LauncherImage (Join-Path $folder $name) $sizes[$density] 0.43 $false ($name -eq 'ic_launcher_round.png')
        }
    }
    Save-LauncherImage (Join-Path $resRoot "drawable-nodpi/finora_launcher_${Variant}.png") 432 0.30 $true $false
    Save-LauncherImage (Join-Path $appRoot "assets/branding/finora_app_icon_${Variant}.png") 1024 0.43 $false $false
    foreach ($name in @('ic_launcher.xml', 'ic_launcher_round.xml')) {
        $path = Join-Path $resRoot "mipmap-anydpi-v26/$name"
        Copy-Item -LiteralPath $path -Destination (Join-Path $backupRoot $name)
        $xml = [System.IO.File]::ReadAllText($path)
        $xml = [regex]::Replace($xml, '(<foreground android:drawable=")[^"]+', '${1}@drawable/finora_launcher_' + $Variant)
        $xml = [regex]::Replace($xml, '(<monochrome android:drawable=")[^"]+', '${1}@drawable/finora_launcher_' + $Variant + '_mono')
        [System.IO.File]::WriteAllText($path, $xml, [System.Text.UTF8Encoding]::new($false))
    }
    Write-Output "Packed five Android densities, round variants, and adaptive foreground. Backup: $backupRoot"
} finally { $art.Dispose() }
