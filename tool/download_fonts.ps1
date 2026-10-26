$list = @(
    @{ name = 'BeVietnamPro.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro/BeVietnamPro-Regular.ttf' },
    @{ name = 'BeVietnamPro-Bold.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/bevietnampro/BeVietnamPro-Bold.ttf' },
    @{ name = 'Inter.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/inter/Inter%5Bopsz%2Cwght%5D.ttf' },
    @{ name = 'Outfit.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/outfit/Outfit%5Bwght%5D.ttf' },
    @{ name = 'Lexend.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/lexend/Lexend%5Bwght%5D.ttf' },
    @{ name = 'Manrope.ttf'; uri = 'https://raw.githubusercontent.com/google/fonts/main/ofl/manrope/Manrope%5Bwght%5D.ttf' }
)
foreach ($item in $list) {
    $dst = "d:\FINORA-\flutter\assets\fonts\" + $item.name
    Write-Host "Downloading $($item.name)..."
    Invoke-WebRequest -Uri $item.uri -OutFile $dst
    $len = (Get-Item $dst).Length
    Write-Host "$($item.name): $len bytes"
}
