# ==============================================================================
# Hero Banner & Media Controls Acceptance Verification
# ==============================================================================

$heroPath = "sections/hero.liquid"
$iwtPath = "sections/image-with-text.liquid"
$heroContent = Get-Content $heroPath -Raw
$iwtContent = Get-Content $iwtPath -Raw

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - HERO BANNER & MEDIA CONTROLS VERIFICATION           " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$allPassed = $true

function Assert-Check($name, $condition, $details) {
    if ($condition) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $($name): $details" -ForegroundColor Red
        $script:allPassed = $false
    }
}

# 1. Hero banner responsive image pickers
$heroHasDesktopPicker = ($heroContent -match '"id":\s*"image"')
$heroHasMobilePicker = ($heroContent -match '"id":\s*"image_mobile"')
Assert-Check "Hero section has desktop image picker" $heroHasDesktopPicker "Missing desktop image picker"
Assert-Check "Hero section has mobile image picker" $heroHasMobilePicker "Missing mobile image picker"

# 2. Hero overlay opacity range slider (0% to 90%)
$heroOverlayMin0 = ($heroContent -match '"id":\s*"overlay_opacity"[^}]+"min":\s*0')
$heroOverlayMax90 = ($heroContent -match '"id":\s*"overlay_opacity"[^}]+"max":\s*90')
Assert-Check "Hero overlay opacity min is 0%" $heroOverlayMin0 "Hero overlay min not 0"
Assert-Check "Hero overlay opacity max is 90%" $heroOverlayMax90 "Hero overlay max not 90"

# 3. Hero content alignment options
$heroHasAlignment = ($heroContent -match '"id":\s*"content_position"')
Assert-Check "Hero content position alignment options exposed" $heroHasAlignment "Missing content_position setting"

# 4. Hero fallback vs uploaded image precedence
$heroPrecedence = ($heroContent -match 'image != blank or section\.settings\.image_mobile != blank')
$heroBrandedFallback = ($heroContent -match 'hero-banner\.jpg')
Assert-Check "Hero uploaded images take precedence" $heroPrecedence "Precedence condition missing"
Assert-Check "Hero preserves branded fallback 'hero-banner.jpg'" $heroBrandedFallback "Missing hero-banner.jpg fallback"

# 5. Image-with-text responsive image pickers
$iwtHasDesktopPicker = ($iwtContent -match '"id":\s*"image"')
$iwtHasMobilePicker = ($iwtContent -match '"id":\s*"image_mobile"')
Assert-Check "Image-with-text has desktop image picker" $iwtHasDesktopPicker "Missing desktop image picker"
Assert-Check "Image-with-text has mobile image picker" $iwtHasMobilePicker "Missing mobile image picker"

# 6. Image-with-text overlay opacity range slider (0% to 90%)
$iwtOverlayMin0 = ($iwtContent -match '"id":\s*"overlay_opacity"[^}]+"min":\s*0')
$iwtOverlayMax90 = ($iwtContent -match '"id":\s*"overlay_opacity"[^}]+"max":\s*90')
Assert-Check "Image-with-text overlay opacity min is 0%" $iwtOverlayMin0 "IWT overlay min not 0"
Assert-Check "Image-with-text overlay opacity max is 90%" $iwtOverlayMax90 "IWT overlay max not 90"

# 7. Image-with-text content alignment options
$iwtHasAlignment = ($iwtContent -match '"id":\s*"content_alignment"')
Assert-Check "Image-with-text content alignment option exposed" $iwtHasAlignment "Missing content_alignment setting"

# 8. Image-with-text fallback vs uploaded image precedence
$iwtPrecedence = ($iwtContent -match 'image != blank or section\.settings\.image_mobile != blank')
$iwtBrandedFallback = ($iwtContent -match 'brand-story\.jpg')
Assert-Check "Image-with-text uploaded images take precedence" $iwtPrecedence "Precedence condition missing"
Assert-Check "Image-with-text preserves branded fallback 'brand-story.jpg'" $iwtBrandedFallback "Missing brand-story.jpg fallback"

# 9. Responsive picture CSS rules in base.css
$baseCssContent = Get-Content "assets/base.css" -Raw
$mediaPictureBlock = ($baseCssContent -match '\.media picture\s*\{[^}]*display:\s*block')
$pictureImgDisplay = ($baseCssContent -match 'picture img\s*\{\s*display:\s*block\s*!important;')
$pictureClassSpecificity = ($baseCssContent -match 'picture\s+\.banner__image--desktop')
Assert-Check ".media picture is styled as display: block" $mediaPictureBlock "Missing .media picture display: block"
Assert-Check "picture img is guarded against display: none toggles" $pictureImgDisplay "Missing picture img display: block !important"
Assert-Check "picture .banner__image--desktop specificity guard is active" $pictureClassSpecificity "Missing picture .banner__image--desktop specificity guard"

# 10. Empirical Headless Browser Verification of Hero Picture Rendering
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }

if (Test-Path $edgePath) {
    $browserFixture = @"
<!DOCTYPE html>
<html>
<head>
<style>
$baseCssContent
</style>
</head>
<body>
<div class="banner">
  <div class="banner__media">
    <picture id="testPic">
      <source media="(max-width: 749px)" class="banner__image--mobile" srcset="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7">
      <img id="testPicImg" class="banner__image--desktop" src="data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///yH5BAEAAAAALAAAAAABAAEAAAIBRAA7" alt="Hero">
    </picture>
  </div>
</div>
<script>
window.onload = function() {
  var img = document.getElementById('testPicImg');
  var d = window.getComputedStyle(img).display;
  document.title = 'DISP:' + d;
};
</script>
</body>
</html>
"@
    $tmpFixture = [System.IO.Path]::GetTempFileName() + ".html"
    [System.IO.File]::WriteAllText($tmpFixture, $browserFixture, [System.Text.Encoding]::UTF8)

    # Mobile test (375px)
    $psiMobile = New-Object System.Diagnostics.ProcessStartInfo
    $psiMobile.FileName = $edgePath
    $psiMobile.Arguments = "--headless --disable-gpu --dump-dom --window-size=375,667 `"$tmpFixture`""
    $psiMobile.RedirectStandardOutput = $true
    $psiMobile.UseShellExecute = $false
    $procMobile = [System.Diagnostics.Process]::Start($psiMobile)
    $outMobile = $procMobile.StandardOutput.ReadToEnd()
    $procMobile.WaitForExit()

    $mobilePass = ($outMobile -match 'DISP:block')
    Assert-Check "Headless Edge: Hero picture img computes display:block on mobile viewport" $mobilePass "Got: $outMobile"

    # Desktop test (1440px)
    $psiDesktop = New-Object System.Diagnostics.ProcessStartInfo
    $psiDesktop.FileName = $edgePath
    $psiDesktop.Arguments = "--headless --disable-gpu --dump-dom --window-size=1440,900 `"$tmpFixture`""
    $psiDesktop.RedirectStandardOutput = $true
    $psiDesktop.UseShellExecute = $false
    $procDesktop = [System.Diagnostics.Process]::Start($psiDesktop)
    $outDesktop = $procDesktop.StandardOutput.ReadToEnd()
    $procDesktop.WaitForExit()

    $desktopPass = ($outDesktop -match 'DISP:block')
    Assert-Check "Headless Edge: Hero picture img computes display:block on desktop viewport" $desktopPass "Got: $outDesktop"

    Remove-Item $tmpFixture -ErrorAction SilentlyContinue
} else {
    Write-Host "  [SKIP] Microsoft Edge binary not found for empirical headless browser test" -ForegroundColor Yellow
}

if ($allPassed) {
    Write-Host "`nAll Hero Banner & Media Controls assertions PASSED (100%)" -ForegroundColor Green
} else {
    Write-Host "`nSome Hero Banner & Media Controls assertions FAILED!" -ForegroundColor Red
    exit 1
}
