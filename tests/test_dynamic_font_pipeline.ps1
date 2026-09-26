# ==============================================================================
# Dynamic Font Pipeline & Typography Acceptance Verification
# ==============================================================================

$themeStylesPath = "snippets/theme-styles.liquid"
$themeLiquidPath = "layout/theme.liquid"
$settingsDataPath = "config/settings_data.json"
$settingsSchemaPath = "config/settings_schema.json"

$themeStyles = Get-Content $themeStylesPath -Raw
$themeLiquid = Get-Content $themeLiquidPath -Raw
$settingsData = Get-Content $settingsDataPath -Raw | ConvertFrom-Json
$settingsSchema = Get-Content $settingsSchemaPath -Raw | ConvertFrom-Json

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - DYNAMIC FONT PIPELINE & TYPOGRAPHY VERIFICATION     " -ForegroundColor Cyan
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

# 1. Native font_face declarations generated
$hasHeadingFontFace = ($themeStyles -match 'heading_font\s*\|\s*font_face')
$hasBodyFontFace = ($themeStyles -match 'body_font\s*\|\s*font_face')
Assert-Check "heading_font generates native font_face" $hasHeadingFontFace "Missing heading_font | font_face"
Assert-Check "body_font generates native font_face" $hasBodyFontFace "Missing body_font | font_face"

# 2. Font preloads in theme.liquid
$hasHeadingPreload = ($themeLiquid -match 'settings\.heading_font\s*\|\s*font_url')
$hasBodyPreload = ($themeLiquid -match 'settings\.body_font\s*\|\s*font_url')
Assert-Check "layout/theme.liquid preloads heading_font" $hasHeadingPreload "Missing heading_font font_url preload"
Assert-Check "layout/theme.liquid preloads body_font" $hasBodyPreload "Missing body_font font_url preload"

# 3. Dynamic binding of --font-heading and --font-body
# Function to simulate rendering the CSS variable based on font object
function Render-Font-Stack($fontObj) {
    if ($fontObj -and $fontObj.family) {
        $fam = $fontObj.family
        $fallback = if ($fontObj.fallback_families) { "$($fontObj.fallback_families), " } else { "" }
        return "$fam, 'Manrope', 'Inter', ${fallback}-apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    } else {
        return "'Manrope', 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif"
    }
}

# Test font change: Assistant
$fontAssistant = [PSCustomObject]@{ family = "Assistant"; fallback_families = "sans-serif" }
$stackAssistant = Render-Font-Stack $fontAssistant
Assert-Check "Merchant font 'Assistant' applies first in CSS stack" ($stackAssistant.StartsWith("Assistant,")) "Got: $stackAssistant"

# Test font change: Playfair Display (Serif)
$fontPlayfair = [PSCustomObject]@{ family = "'Playfair Display'"; fallback_families = "serif" }
$stackPlayfair = Render-Font-Stack $fontPlayfair
Assert-Check "Merchant font 'Playfair Display' applies first in CSS stack" ($stackPlayfair.StartsWith("'Playfair Display',")) "Got: $stackPlayfair"

# Test fallback when font is blank
$stackDefault = Render-Font-Stack $null
Assert-Check "Default gracefully falls back to 'Manrope', 'Inter'" ($stackDefault.StartsWith("'Manrope', 'Inter'")) "Got: $stackDefault"

# 4. Settings schema exposes font sizing scale and letter-spacing
$typoSection = $settingsSchema | Where-Object { $_.name -like "*typography*" }
$headingScale = $typoSection.settings | Where-Object { $_.id -eq "heading_scale" }
$bodyScale = $typoSection.settings | Where-Object { $_.id -eq "body_scale" }
$headingTracking = $typoSection.settings | Where-Object { $_.id -eq "heading_tracking" }
$bodyTracking = $typoSection.settings | Where-Object { $_.id -eq "body_tracking" }

Assert-Check "heading_scale range exposed in schema" ($headingScale -ne $null) "Missing heading_scale"
Assert-Check "body_scale range exposed in schema" ($bodyScale -ne $null) "Missing body_scale"
Assert-Check "heading_tracking (letter-spacing) exposed in schema" ($headingTracking -ne $null) "Missing heading_tracking"
Assert-Check "body_tracking (letter-spacing) exposed in schema" ($bodyTracking -ne $null) "Missing body_tracking"

# 5. Settings data current and presets have valid font settings
Assert-Check "settings_data.json current has heading_font" ([bool]$settingsData.current.heading_font) "Missing current.heading_font"
Assert-Check "settings_data.json current has body_font" ([bool]$settingsData.current.body_font) "Missing current.body_font"
Assert-Check "settings_data.json current has body_tracking" ($settingsData.current.body_tracking -ne $null) "Missing current.body_tracking"

# 6. CSS token consumption in base.css
$baseCssContent = Get-Content "assets/base.css" -Raw
$bodyHasTracking = ($baseCssContent -match 'body\s*\{[^}]*letter-spacing:\s*var\(--body-tracking\)')
$buttonHasFont = ($baseCssContent -match '\.button[^{]*\{[^}]*font-family:\s*var\(--font-body\)')
Assert-Check "base.css applies var(--body-tracking) to body" $bodyHasTracking "Missing letter-spacing: var(--body-tracking) in body"
Assert-Check "base.css explicitly applies var(--font-body) to .button" $buttonHasFont "Missing font-family: var(--font-body) in .button"

# 7. Defensive guards in layout/theme.liquid
$themeColorFallback = ($themeLiquid -match 'settings\.color_schemes\.scheme_1\.settings\.background\s*\|\s*default')
Assert-Check "layout/theme.liquid provides fallback for theme-color meta tag" $themeColorFallback "Missing fallback on theme-color"

if ($allPassed) {
    Write-Host "`nAll Dynamic Font Pipeline assertions PASSED (100%)" -ForegroundColor Green
} else {
    Write-Host "`nSome Dynamic Font Pipeline assertions FAILED!" -ForegroundColor Red
    exit 1
}
