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

if ($allPassed) {
    Write-Host "`nAll Hero Banner & Media Controls assertions PASSED (100%)" -ForegroundColor Green
} else {
    Write-Host "`nSome Hero Banner & Media Controls assertions FAILED!" -ForegroundColor Red
    exit 1
}
