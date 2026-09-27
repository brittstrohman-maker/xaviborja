Add-Type -AssemblyName System.Drawing

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - LOGO & FAVICON INTEGRATION VERIFICATION              " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$assetsDir = "assets"
$failures = 0

function Assert-Check($name, $passed, $info = "") {
    if ($passed) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $name - $info" -ForegroundColor Red
        $script:failures++
    }
}

# 1. Check Vector and Raster Files Exist
$logoSvg = Join-Path $assetsDir "dose-dial-logo.svg"
$logoPng = Join-Path $assetsDir "dose-dial-logo.png"
$favSvg = Join-Path $assetsDir "favicon.svg"
$fav32 = Join-Path $assetsDir "favicon-32x32.png"
$fav16 = Join-Path $assetsDir "favicon-16x16.png"
$favPng = Join-Path $assetsDir "favicon.png"
$appleTouch = Join-Path $assetsDir "apple-touch-icon.png"
$favIco = Join-Path $assetsDir "favicon.ico"

Assert-Check "assets/dose-dial-logo.svg exists" (Test-Path $logoSvg)
Assert-Check "assets/dose-dial-logo.png exists" (Test-Path $logoPng)
Assert-Check "assets/favicon.svg exists" (Test-Path $favSvg)
Assert-Check "assets/favicon-32x32.png exists" (Test-Path $fav32)
Assert-Check "assets/favicon-16x16.png exists" (Test-Path $fav16)
Assert-Check "assets/apple-touch-icon.png exists" (Test-Path $appleTouch)
Assert-Check "assets/favicon.ico exists" (Test-Path $favIco)

# 2. Check XML Validity of SVGs
$logoXmlValid = $false
try {
    [xml]$xmlLogo = Get-Content $logoSvg -Raw
    $logoXmlValid = ($xmlLogo.svg.viewBox -eq "0 0 240 48")
} catch {
    $logoXmlValid = $false
}
Assert-Check "dose-dial-logo.svg is valid XML with 240x48 viewBox" $logoXmlValid

$favXmlValid = $false
try {
    [xml]$xmlFav = Get-Content $favSvg -Raw
    $favXmlValid = ($xmlFav.svg.viewBox -eq "0 0 64 64")
} catch {
    $favXmlValid = $false
}
Assert-Check "favicon.svg is valid XML with 64x64 viewBox" $favXmlValid

# 3. Check Dimensions of PNGs
$bmp32 = [System.Drawing.Bitmap]::FromFile((Resolve-Path $fav32).Path)
Assert-Check "favicon-32x32.png has exact 32x32 dimensions" ($bmp32.Width -eq 32 -and $bmp32.Height -eq 32)
$bmp32.Dispose()

$bmp16 = [System.Drawing.Bitmap]::FromFile((Resolve-Path $fav16).Path)
Assert-Check "favicon-16x16.png has exact 16x16 dimensions" ($bmp16.Width -eq 16 -and $bmp16.Height -eq 16)
$bmp16.Dispose()

$bmpTouch = [System.Drawing.Bitmap]::FromFile((Resolve-Path $appleTouch).Path)
Assert-Check "apple-touch-icon.png has exact 180x180 dimensions" ($bmpTouch.Width -eq 180 -and $bmpTouch.Height -eq 180)
$bmpTouch.Dispose()

# 4. Check layout/theme.liquid markup
$themeLiquid = Get-Content "layout/theme.liquid" -Raw
Assert-Check "theme.liquid links favicon.svg fallback" ($themeLiquid -match "favicon\.svg")
Assert-Check "theme.liquid links favicon-32x32.png fallback" ($themeLiquid -match "favicon-32x32\.png")
Assert-Check "theme.liquid links apple-touch-icon.png fallback" ($themeLiquid -match "apple-touch-icon\.png")
Assert-Check "theme.liquid links favicon.ico fallback" ($themeLiquid -match "favicon\.ico")

# 5. Check layout/password.liquid markup
$pwdLiquid = Get-Content "layout/password.liquid" -Raw
Assert-Check "password.liquid links favicon.svg fallback" ($pwdLiquid -match "favicon\.svg")

# 6. Check sections/header.liquid markup
$headerLiquid = Get-Content "sections/header.liquid" -Raw
Assert-Check "header.liquid renders dose-dial-logo.svg" ($headerLiquid -match "dose-dial-logo\.svg")
Assert-Check "header.liquid retains accessible visually-hidden brand text" ($headerLiquid -match "header__logo-text visually-hidden")
Assert-Check "header.liquid includes HeaderLogo id" ($headerLiquid -match 'id="HeaderLogo"')

# 7. Check assets/base.css rules
$baseCss = Get-Content "assets/base.css" -Raw
Assert-Check "base.css styles .header__logo-image with --logo-width" ($baseCss -match "\.header__logo-image")
Assert-Check "base.css contains mobile responsive rules for logo image" ($baseCss -match "max-width:\s*140px")

Write-Host ""
if ($failures -eq 0) {
    Write-Host "All Logo and Favicon assertions PASSED (100%)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed assertions: $failures" -ForegroundColor Red
    exit 1
}
