$ErrorActionPreference = "Stop"

$env:FLUTTER_ROOT = "C:\flutter"
$env:FLUTTER_ALREADY_LOCKED = "true"
$env:JAVA_HOME = "C:\jdk17\jdk-17.0.12+7"
$env:ANDROID_HOME = "C:\Users\Admin\AppData\Local\Android\Sdk"
$env:PATH = "C:\flutter\bin;C:\jdk17\jdk-17.0.12+7\bin;$env:PATH"

$dart = "C:\flutter\bin\cache\dart-sdk\bin\dart.exe"
$pkg = "C:\flutter\packages\flutter_tools\.dart_tool\package_config.json"
$script = "C:\flutter\packages\flutter_tools\bin\flutter_tools.dart"

Write-Host "==> [1/3] Cấu hình Android SDK..." -ForegroundColor Cyan
& $dart --packages=$pkg $script config --android-sdk "C:\Users\Admin\AppData\Local\Android\Sdk"

Write-Host "==> [2/3] Tải dependencies (flutter pub get)..." -ForegroundColor Cyan
& $dart --packages=$pkg $script pub get

Write-Host "==> [3/3] Đang biên dịch APK (flutter build apk --debug)..." -ForegroundColor Cyan
& $dart --packages=$pkg $script build apk --debug

Write-Host "==> Hoàn tất! File APK đã sẵn sàng tại:" -ForegroundColor Green
Get-ChildItem -Path "build\app\outputs\flutter-apk\*.apk" | Select-Object FullName, Length, LastWriteTime
