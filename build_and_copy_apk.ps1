$ErrorActionPreference = "Stop"

$env:FLUTTER_ROOT = "C:\flutter"
$env:FLUTTER_ALREADY_LOCKED = "true"
$env:JAVA_HOME = "C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot"
$env:ANDROID_HOME = "C:\Users\Admin\AppData\Local\Android\Sdk"
$env:PATH = "C:\flutter\bin;C:\Program Files\Microsoft\jdk-17.0.20.8-hotspot\bin;$env:PATH"

$dart = "C:\flutter\bin\cache\dart-sdk\bin\dart.exe"
$pkg = "C:\flutter\packages\flutter_tools\.dart_tool\package_config.json"
$script = "C:\flutter\packages\flutter_tools\bin\flutter_tools.dart"

Write-Host "==> [1/3] Downloading dependencies (flutter pub get)..." -ForegroundColor Cyan
& $dart --packages=$pkg $script pub get

Write-Host "==> [2/3] Building Release APK (flutter build apk --release)..." -ForegroundColor Cyan
& $dart --packages=$pkg $script build apk --release

$srcApk = "build\app\outputs\flutter-apk\app-release.apk"
$destFolder = "c:\Users\Admin\OneDrive\Máy tính\APP FINORA"
$destApkDesktop = Join-Path $destFolder "FINORA-Release-v7-CrystalIcon.apk"
$destApkFlutter = "d:\FINORA-\flutter\FINORA-Release-v7-CrystalIcon.apk"
$destApkRoot = "d:\FINORA-\FINORA-Release-v7-CrystalIcon.apk"

if (Test-Path $srcApk) {
    if (-not (Test-Path $destFolder)) {
        New-Item -ItemType Directory -Path $destFolder -Force | Out-Null
    }
    Copy-Item -Path $srcApk -Destination $destApkDesktop -Force
    Copy-Item -Path $srcApk -Destination $destApkFlutter -Force
    Copy-Item -Path $srcApk -Destination $destApkRoot -Force
    # Also update FrostedGlass and Latest aliases
    Copy-Item -Path $srcApk -Destination (Join-Path $destFolder "FINORA-Release-Latest.apk") -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $srcApk -Destination "d:\FINORA-\FINORA-Release-Latest.apk" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $srcApk -Destination "d:\FINORA-\app-release.apk" -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $srcApk -Destination (Join-Path $destFolder "FINORA-FrostedGlass-Release.apk") -Force -ErrorAction SilentlyContinue
    Copy-Item -Path $srcApk -Destination "d:\FINORA-\FINORA-FrostedGlass-Release.apk" -Force -ErrorAction SilentlyContinue
    Write-Host "==> [3/3] BUILD SUCCESS! Output copied to:" -ForegroundColor Green
    Write-Host "  1) $destApkDesktop" -ForegroundColor Yellow
    Write-Host "  2) $destApkFlutter" -ForegroundColor Yellow
    Write-Host "  3) $destApkRoot" -ForegroundColor Yellow
    Get-Item $destApkDesktop, $destApkFlutter, $destApkRoot | Select-Object Name, Length, LastWriteTime
    Get-FileHash -Path $destApkRoot -Algorithm SHA256 | Select-Object Hash, Path
} else {
    Write-Host "==> APK output not found at: $srcApk" -ForegroundColor Red
}
