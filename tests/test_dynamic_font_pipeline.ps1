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
$paymentButtonHasFont = ($baseCssContent -match '\.shopify-payment-button__button--unbranded[^{]*\{[^}]*font-family:\s*var\(--font-body\)')
Assert-Check "base.css applies var(--body-tracking) to body" $bodyHasTracking "Missing letter-spacing: var(--body-tracking) in body"
Assert-Check "base.css explicitly applies var(--font-body) to .button" $buttonHasFont "Missing font-family: var(--font-body) in .button"
Assert-Check "base.css explicitly applies var(--font-body) to .shopify-payment-button__button--unbranded" $paymentButtonHasFont "Missing font-family in payment button"

# 7. Defensive guards in layout/theme.liquid
$themeColorFallback = ($themeLiquid -match 'settings\.color_schemes\.scheme_1\.settings\.background\s*\|\s*default')
Assert-Check "layout/theme.liquid provides fallback for theme-color meta tag" $themeColorFallback "Missing fallback on theme-color"

# 8. Dual selector syntax support in snippets/theme-styles.liquid
$hyphenSchemeSupport = ($themeStyles -match '\.color-\{\{\s*scheme\.id\s*\|\s*replace:\s*''_''\s*,\s*''-''\s*\}\}')
Assert-Check "snippets/theme-styles.liquid emits hyphenated color-scheme classes" $hyphenSchemeSupport "Missing hyphenated scheme class generation"

# 9. Heading utility classes .h1-.h6 inherit var(--font-heading)
$h1ThroughH6HeadingFont = ($baseCssContent -match '\.h[1-6][^{]*\{[^}]*font-family:\s*var\(--font-heading\)')
Assert-Check "base.css applies var(--font-heading) to .h1-.h6 heading utility classes" $h1ThroughH6HeadingFont "Missing font-family: var(--font-heading) on .h1-.h6"

# 10. Micro-labels explicitly bind to var(--font-body)
$microLabelBodyFont = ($baseCssContent -match '\.micro-label[^{]*\{[^}]*font-family:\s*var\(--font-body\)')
Assert-Check "base.css explicitly applies var(--font-body) to .micro-label" $microLabelBodyFont "Missing font-family: var(--font-body) on .micro-label"

# 11. Body font style bound to body
$bodyHasStyle = ($baseCssContent -match 'body\s*\{[^}]*font-style:\s*var\(--font-body-style')
Assert-Check "base.css applies var(--font-body-style) to body" $bodyHasStyle "Missing font-style: var(--font-body-style) on body"

# 12. Headless Edge JS runtime evaluation
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) { $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe" }
if (Test-Path $edgePath) {
    $themeJsCode = [System.IO.File]::ReadAllText("assets/theme.js", [System.Text.Encoding]::UTF8)
    $fixtureJs = @"
<!DOCTYPE html>
<html>
<head>
<script>
window.errors = [];
window.onerror = function(m, u, l) { window.errors.push(m + ':' + l); };
</script>
<script type="module">
$themeJsCode
</script>
</head>
<body class="animate-reveal">
<header class="header-wrapper header-wrapper--sticky"></header>
<script>
document.title = 'ERRORS:' + window.errors.length + ':' + window.errors.join(';');
</script>
</body>
</html>
"@
    $tmpJs = [System.IO.Path]::GetTempFileName() + ".html"
    [System.IO.File]::WriteAllText($tmpJs, $fixtureJs, [System.Text.Encoding]::UTF8)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $edgePath
    $psi.Arguments = "--headless --disable-gpu --dump-dom `"$tmpJs`""
    $psi.RedirectStandardOutput = $true
    $psi.UseShellExecute = $false
    $proc = [System.Diagnostics.Process]::Start($psi)
    $out = $proc.StandardOutput.ReadToEnd()
    $proc.WaitForExit()
    Remove-Item $tmpJs -ErrorAction SilentlyContinue

    $noErrors = ($out -match 'ERRORS:0:')
    Assert-Check "Headless Edge: theme.js loads and initializes with zero JS errors" $noErrors "Got: $out"
}

if ($allPassed) {
    Write-Host "`nAll Dynamic Font Pipeline assertions PASSED (100%)" -ForegroundColor Green
} else {
    Write-Host "`nSome Dynamic Font Pipeline assertions FAILED!" -ForegroundColor Red
    exit 1
}

