Add-Type -AssemblyName System.Drawing

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

$root = (Get-Location).Path
$assetsDir = Join-Path $root "assets"

Write-Host "Generating Brand Assets for Dose & Dial..." -ForegroundColor Cyan

# 1. Verify SVGs exist
$logoSvg = Join-Path $assetsDir "dose-dial-logo.svg"
$faviconSvg = Join-Path $assetsDir "favicon.svg"

if (-not (Test-Path $logoSvg) -or -not (Test-Path $faviconSvg)) {
    Write-Error "SVG source files not found."
    exit 1
}

# 2. Render Apple Touch Icon (180x180) and Logo PNG via Headless Edge
$tempHtmlFavicon = Join-Path $root "tests\temp_favicon.html"
$favContent = Get-Content $faviconSvg -Raw
@"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: transparent; width: 512px; height: 512px; overflow: hidden; display: flex; align-items: center; justify-content: center; }
  svg { width: 512px; height: 512px; display: block; }
</style>
</head>
<body>
$favContent
</body>
</html>
"@ | Set-Content -Path $tempHtmlFavicon -Encoding UTF8

$tempFaviconPng512 = Join-Path $root "tests\temp_fav_512.png"
$argsFav = @(
    "--headless",
    "--disable-gpu",
    "--hide-scrollbars",
    "--window-size=512,512",
    "--default-background-color=00000000",
    "--screenshot=$tempFaviconPng512",
    "file:///$($tempHtmlFavicon.Replace('\', '/'))"
)
$pFav = Start-Process -FilePath $edgePath -ArgumentList $argsFav -PassThru -Wait
Start-Sleep -Milliseconds 800

if (Test-Path $tempFaviconPng512) {
    Write-Host "  [OK] Master Favicon 512x512 rendered" -ForegroundColor Green
    $masterBmp = [System.Drawing.Bitmap]::FromFile($tempFaviconPng512)

    # Resize helper function
    function Save-ResizedPng($srcBmp, $width, $height, $destPath) {
        $destBmp = New-Object System.Drawing.Bitmap($width, $height)
        $g = [System.Drawing.Graphics]::FromImage($destBmp)
        $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
        $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
        $g.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
        $g.Clear([System.Drawing.Color]::Transparent)
        $g.DrawImage($srcBmp, 0, 0, $width, $height)
        $g.Dispose()
        $destBmp.Save($destPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $destBmp.Dispose()
    }

    # Save apple-touch-icon.png (180x180)
    $appleTouch = Join-Path $assetsDir "apple-touch-icon.png"
    Save-ResizedPng $masterBmp 180 180 $appleTouch
    Write-Host "  [OK] Created $appleTouch (180x180)" -ForegroundColor Green

    # Save favicon-32x32.png
    $fav32 = Join-Path $assetsDir "favicon-32x32.png"
    Save-ResizedPng $masterBmp 32 32 $fav32
    Write-Host "  [OK] Created $fav32 (32x32)" -ForegroundColor Green

    # Save favicon-16x16.png
    $fav16 = Join-Path $assetsDir "favicon-16x16.png"
    Save-ResizedPng $masterBmp 16 16 $fav16
    Write-Host "  [OK] Created $fav16 (16x16)" -ForegroundColor Green

    # Also save favicon.png (32x32 fallback)
    $favPng = Join-Path $assetsDir "favicon.png"
    Save-ResizedPng $masterBmp 32 32 $favPng
    Write-Host "  [OK] Created $favPng (32x32)" -ForegroundColor Green

    # Build favicon.ico (containing 16x16 and 32x32 frames)
    $favIcoPath = Join-Path $assetsDir "favicon.ico"
    $favIcoRoot = Join-Path $root "favicon.ico" # also at root if supported
    
    # Save standard icon using 32x32 bitmap
    $bmp32 = New-Object System.Drawing.Bitmap(32, 32)
    $g32 = [System.Drawing.Graphics]::FromImage($bmp32)
    $g32.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g32.DrawImage($masterBmp, 0, 0, 32, 32)
    $g32.Dispose()
    $hIcon = $bmp32.GetHicon()
    $icon = [System.Drawing.Icon]::FromHandle($hIcon)
    $fs = New-Object System.IO.FileStream($favIcoPath, [System.IO.FileMode]::Create)
    $icon.Save($fs)
    $fs.Close()
    $icon.Dispose()
    $bmp32.Dispose()
    Write-Host "  [OK] Created $favIcoPath" -ForegroundColor Green

    $masterBmp.Dispose()
} else {
    Write-Error "Failed to generate master favicon PNG"
}

# 3. Render Logo to High-Res PNG (480x96)
$tempHtmlLogo = Join-Path $root "tests\temp_logo.html"
$logoContent = Get-Content $logoSvg -Raw
@"
<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<style>
  * { margin: 0; padding: 0; box-sizing: border-box; }
  body { background: transparent; width: 480px; height: 96px; overflow: hidden; display: flex; align-items: center; justify-content: center; }
  svg { width: 480px; height: 96px; display: block; }
</style>
</head>
<body>
$logoContent
</body>
</html>
"@ | Set-Content -Path $tempHtmlLogo -Encoding UTF8

$logoPng = Join-Path $assetsDir "dose-dial-logo.png"
$argsLogo = @(
    "--headless",
    "--disable-gpu",
    "--hide-scrollbars",
    "--window-size=480,96",
    "--default-background-color=00000000",
    "--screenshot=$logoPng",
    "file:///$($tempHtmlLogo.Replace('\', '/'))"
)
$pLogo = Start-Process -FilePath $edgePath -ArgumentList $argsLogo -PassThru -Wait
Start-Sleep -Milliseconds 800

if (Test-Path $logoPng) {
    Write-Host "  [OK] Created $logoPng (480x96)" -ForegroundColor Green
} else {
    Write-Error "Failed to generate logo PNG"
}

# Cleanup temp files
Remove-Item -Path $tempHtmlFavicon, $tempFaviconPng512, $tempHtmlLogo -ErrorAction SilentlyContinue

Write-Host "All Brand Assets generated successfully!" -ForegroundColor Green
