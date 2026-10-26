# apply_v10_app_icon.ps1
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Drawing

$appRoot = 'D:\FINORA-\flutter'
$repoRoot = 'D:\FINORA-'
$resRoot = Join-Path $appRoot 'android/app/src/main/res'
$webPublic = Join-Path $repoRoot 'web/public'

$fgSourcePath = Join-Path $repoRoot 'docs/branding/finora-f-halo-wallet-v9-preview.png'
$bgSourcePath = Join-Path $repoRoot 'docs/branding/finora-f-halo-bg-clean-test.png'
$masterSourcePath = Join-Path $repoRoot 'docs/branding/finora-f-halo-background-v10-preview.png'

$variant = 'wallet_halo_v10'

# Backup existing launcher resources
$timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$backupRoot = Join-Path $repoRoot "docs/branding/launcher-before-v10-$timestamp"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

Write-Host "Backing up current launcher to $backupRoot..."

$densities = @{ mdpi = 48; hdpi = 72; xhdpi = 96; xxhdpi = 144; xxxhdpi = 192 }
foreach ($density in $densities.Keys) {
    $folder = Join-Path $resRoot "mipmap-$density"
    $backupFolder = Join-Path $backupRoot "mipmap-$density"
    New-Item -ItemType Directory -Path $backupFolder -Force | Out-Null
    foreach ($file in @('ic_launcher.png', 'ic_launcher_round.png')) {
        $p = Join-Path $folder $file
        if (Test-Path $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $backupFolder $file) }
    }
}
foreach ($xml in @('ic_launcher.xml', 'ic_launcher_round.xml')) {
    $p = Join-Path $resRoot "mipmap-anydpi-v26/$xml"
    if (Test-Path $p) { Copy-Item -LiteralPath $p -Destination (Join-Path $backupRoot $xml) }
}

# Copy master foreground & background into assets/branding
Copy-Item -LiteralPath $fgSourcePath -Destination (Join-Path $appRoot "assets/branding/finora_${variant}_foreground.png") -Force
Copy-Item -LiteralPath $bgSourcePath -Destination (Join-Path $appRoot "assets/branding/finora_${variant}_background.png") -Force

# Load sources
$fgArt = [System.Drawing.Bitmap]::new($fgSourcePath)
$bgArt = [System.Drawing.Bitmap]::new($bgSourcePath)

try {
    # Compute foreground center and radius
    $minX = $fgArt.Width; $minY = $fgArt.Height; $maxX = 0; $maxY = 0
    for ($y = 0; $y -lt $fgArt.Height; $y += 2) {
        for ($x = 0; $x -lt $fgArt.Width; $x += 2) {
            if ($fgArt.GetPixel($x, $y).A -gt 24) {
                $minX = [Math]::Min($minX, $x); $maxX = [Math]::Max($maxX, $x)
                $minY = [Math]::Min($minY, $y); $maxY = [Math]::Max($maxY, $y)
            }
        }
    }
    $centerX = ($minX + $maxX) / 2.0
    $centerY = ($minY + $maxY) / 2.0
    $radius = 1.0
    for ($y = 0; $y -lt $fgArt.Height; $y += 2) {
        for ($x = 0; $x -lt $fgArt.Width; $x += 2) {
            if ($fgArt.GetPixel($x, $y).A -gt 24) {
                $r = [Math]::Sqrt([Math]::Pow($x - $centerX, 2) + [Math]::Pow($y - $centerY, 2))
                $radius = [Math]::Max($radius, $r)
            }
        }
    }
    Write-Host "Foreground Center: ($centerX, $centerY), Radius: $radius"

    # Function to create composite image (background + scaled foreground)
    function Save-CompositeImage([string]$Path, [int]$Size, [double]$SafeRadius, [bool]$Round) {
        $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
        $g = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            if ($Round) {
                $mask = [System.Drawing.Drawing2D.GraphicsPath]::new()
                try { $mask.AddEllipse(0, 0, $Size, $Size); $g.SetClip($mask) } finally { $mask.Dispose() }
            }

            # 1. Base fill with corner navy color to guarantee 100% opacity at edges
            $baseBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#03144F'))
            try { $g.FillRectangle($baseBrush, 0, 0, $Size, $Size) } finally { $baseBrush.Dispose() }

            # 2. Draw background full bleed
            $bgRect = [System.Drawing.RectangleF]::new(0, 0, $Size, $Size)
            $g.DrawImage($bgArt, $bgRect)

            # 3. Draw scaled foreground
            $scale = ($Size * $SafeRadius) / ($radius + 4)
            $fgRect = [System.Drawing.RectangleF]::new(
                [single]($Size / 2.0 - $centerX * $scale),
                [single]($Size / 2.0 - $centerY * $scale),
                [single]($fgArt.Width * $scale),
                [single]($fgArt.Height * $scale)
            )
            $g.DrawImage($fgArt, $fgRect)

            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $g.Dispose()
            $bitmap.Dispose()
        }
    }

    # Function to save transparent foreground for adaptive icon
    function Save-AdaptiveForeground([string]$Path, [int]$Size, [double]$SafeRadius) {
        $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
        $g = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            $scale = ($Size * $SafeRadius) / ($radius + 4)
            $fgRect = [System.Drawing.RectangleF]::new(
                [single]($Size / 2.0 - $centerX * $scale),
                [single]($Size / 2.0 - $centerY * $scale),
                [single]($fgArt.Width * $scale),
                [single]($fgArt.Height * $scale)
            )
            $g.DrawImage($fgArt, $fgRect)

            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $g.Dispose()
            $bitmap.Dispose()
        }
    }

    # Function to save background for adaptive icon
    function Save-AdaptiveBackground([string]$Path, [int]$Size) {
        $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
        $g = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $g.Clear([System.Drawing.Color]::Transparent)
            $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
            $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

            # Base fill with corner navy color to guarantee 100% opacity at edges
            $baseBrush = [System.Drawing.SolidBrush]::new([System.Drawing.ColorTranslator]::FromHtml('#03144F'))
            try { $g.FillRectangle($baseBrush, 0, 0, $Size, $Size) } finally { $baseBrush.Dispose() }

            $bgRect = [System.Drawing.RectangleF]::new(0, 0, $Size, $Size)
            $g.DrawImage($bgArt, $bgRect)

            $bitmap.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
        } finally {
            $g.Dispose()
            $bitmap.Dispose()
        }
    }

    # 1. Generate Mipmap densities
    foreach ($density in $densities.Keys) {
        $folder = Join-Path $resRoot "mipmap-$density"
        $sz = $densities[$density]
        Save-CompositeImage (Join-Path $folder 'ic_launcher.png') $sz 0.43 $false
        Save-CompositeImage (Join-Path $folder 'ic_launcher_round.png') $sz 0.43 $true
        Write-Host "Generated mipmap-$density ($sz x $sz)"
    }

    # 2. Generate Adaptive drawables (432x432 for nodpi)
    $fgNodpi = Join-Path $resRoot "drawable-nodpi/finora_launcher_${variant}_fg.png"
    $bgNodpi = Join-Path $resRoot "drawable-nodpi/finora_launcher_${variant}_bg.png"
    Save-AdaptiveForeground $fgNodpi 432 0.30
    Save-AdaptiveBackground $bgNodpi 432
    Write-Host "Generated adaptive foreground and background (432x432) in drawable-nodpi"

    # 3. Generate Master Branding Icon (1024x1024)
    $masterAppIcon = Join-Path $appRoot "assets/branding/finora_app_icon_${variant}.png"
    Save-CompositeImage $masterAppIcon 1024 0.43 $false
    Write-Host "Generated 1024x1024 master icon: $masterAppIcon"

    # 4. Generate Web Public icons
    if (Test-Path $webPublic) {
        Save-CompositeImage (Join-Path $webPublic 'finora-app-icon-512.png') 512 0.43 $false
        Save-CompositeImage (Join-Path $webPublic 'finora-app-icon-192.png') 192 0.43 $false
        Save-CompositeImage (Join-Path $webPublic 'finora-app-icon-180.png') 180 0.43 $false
        Save-CompositeImage (Join-Path $webPublic 'finora-app-icon-32.png') 32 0.43 $false
        Write-Host "Generated web public icons (512, 192, 180, 32)"
    }

    # 5. Create Monochrome XML
    $monoXmlPath = Join-Path $resRoot "drawable/finora_launcher_${variant}_mono.xml"
    $monoContent = @'
<vector xmlns:android="http://schemas.android.com/apk/res/android"
    android:width="108dp" android:height="108dp"
    android:viewportWidth="108" android:viewportHeight="108">
    <path android:pathData="M35,39 L72,39 Q77,39 77,44 L77,69 Q77,74 72,74 L36,74 Q31,74 31,69 L31,44 Q31,39 35,39 Z M35,39 L35,35 Q35,32 40,32 L69,32 M67,51 L77,51 M67,51 L67,61 L77,61"
        android:strokeWidth="4" android:strokeColor="#FFFFFFFF"
        android:strokeLineCap="round" android:strokeLineJoin="round"
        android:fillColor="@android:color/transparent"/>
    <path android:pathData="M 50,43.5 A 13,13 0 0,0 50,69.5 A 13,13 0 0,0 50,43.5"
        android:strokeWidth="2" android:strokeColor="#FFFFFFFF"
        android:strokeLineCap="round"
        android:fillColor="@android:color/transparent"/>
    <path android:pathData="M42,46 L58,46 L58,51 L47,51 L47,55 L56,55 L56,60 L47,60 L47,67 L42,67 Z"
        android:fillColor="#FFFFFFFF"/>
</vector>
'@
    [System.IO.File]::WriteAllText($monoXmlPath, $monoContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Generated monochrome vector: $monoXmlPath"

    # 6. Update Adaptive XMLs in mipmap-anydpi-v26
    $adaptiveXmlContent = @"
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/finora_launcher_${variant}_bg"/>
    <foreground android:drawable="@drawable/finora_launcher_${variant}_fg"/>
    <monochrome android:drawable="@drawable/finora_launcher_${variant}_mono"/>
</adaptive-icon>
"@
    foreach ($xmlName in @('ic_launcher.xml', 'ic_launcher_round.xml')) {
        $xmlPath = Join-Path $resRoot "mipmap-anydpi-v26/$xmlName"
        [System.IO.File]::WriteAllText($xmlPath, $adaptiveXmlContent, [System.Text.UTF8Encoding]::new($false))
        Write-Host "Updated $xmlPath"
    }

    # 7. Update values/colors.xml
    $colorsPath = Join-Path $resRoot 'values/colors.xml'
    $colorsContent = @'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="finora_launcher_background">#03144F</color>
</resources>
'@
    [System.IO.File]::WriteAllText($colorsPath, $colorsContent, [System.Text.UTF8Encoding]::new($false))
    Write-Host "Updated $colorsPath"

    Write-Host "SUCCESS: App icon $variant applied across Android mipmaps, adaptive drawables, mono vector, and web!"
} finally {
    $fgArt.Dispose()
    $bgArt.Dispose()
}
