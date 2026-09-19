# ==============================================================================
# Challenger M1-1: Empirical Stress-Testing Suite for Milestone M1
# Focus: CSS Custom Properties, Brand Tokens, Color Schemes, Typography & Fallback
# ==============================================================================

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

$Report = [System.Collections.ArrayList]::new()

function Log-Result {
    param(
        [string]$Category,
        [string]$Name,
        [bool]$Passed,
        [string]$Expected,
        [string]$Actual,
        [string]$Severity = "INFO" # INFO, LOW, MEDIUM, HIGH, CRITICAL
    )
    $obj = [PSCustomObject]@{
        Category = $Category
        Name     = $Name
        Passed   = $Passed
        Expected = $Expected
        Actual   = $Actual
        Severity = $Severity
    }
    $null = $Report.Add($obj)
    
    $statusStr = if ($Passed) { "[PASS]" } else { "[$Severity FAIL]" }
    $color = if ($Passed) { "Green" } elseif ($Severity -in @("HIGH","CRITICAL")) { "Red" } else { "Yellow" }
    Write-Host ("  {0} {1}: {2}" -f $statusStr, $Category, $Name) -ForegroundColor $color
    if (-not $Passed) {
        Write-Host ("         Expected: {0}" -f $Expected) -ForegroundColor DarkGray
        Write-Host ("         Actual:   {0}" -f $Actual) -ForegroundColor DarkGray
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M1-1: EMPIRICAL STRESS-TESTING SUITE                   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Load files
$themeStyles = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "snippets/theme-styles.liquid"), [System.Text.Encoding]::UTF8)
$settingsDataJson = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "config/settings_data.json"), [System.Text.Encoding]::UTF8)
$settingsData = $settingsDataJson | ConvertFrom-Json
$settingsSchemaJson = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "config/settings_schema.json"), [System.Text.Encoding]::UTF8)
$settingsSchema = $settingsSchemaJson | ConvertFrom-Json
$baseCss = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "assets/base.css"), [System.Text.Encoding]::UTF8)
$themeLiquid = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "layout/theme.liquid"), [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# 1. Brand Tokens & Hex/RGB Mathematical Accuracy
# ------------------------------------------------------------------------------
Write-Host "`n--- 1. Brand Tokens & Hex/RGB Mathematical Accuracy ---" -ForegroundColor Yellow

$brandColors = @(
    @{ Name='cream'; Hex='#F7F3EB'; R=247; G=243; B=235 },
    @{ Name='offwhite'; Hex='#FCFAF6'; R=252; G=250; B=246 },
    @{ Name='white'; Hex='#FFFFFF'; R=255; G=255; B=255 },
    @{ Name='black'; Hex='#111111'; R=17;  G=17;  B=17 },
    @{ Name='espresso'; Hex='#2A1D17'; R=42;  G=29;  B=23 },
    @{ Name='walnut'; Hex='#7A5736'; R=122; G=87;  B=54 },
    @{ Name='copper'; Hex='#9A6238'; R=154; G=98;  B=56 },
    @{ Name='taupe'; Hex='#E7E0D6'; R=231; G=224; B=214 },
    @{ Name='gray'; Hex='#77716B'; R=119; G=113; B=107 }
)

foreach ($c in $brandColors) {
    $cleanHex = $c.Hex.TrimStart('#')
    $mathR = [Convert]::ToInt32($cleanHex.Substring(0,2), 16)
    $mathG = [Convert]::ToInt32($cleanHex.Substring(2,2), 16)
    $mathB = [Convert]::ToInt32($cleanHex.Substring(4,2), 16)
    $mathCorrect = ($mathR -eq $c.R -and $mathG -eq $c.G -and $mathB -eq $c.B)
    
    Log-Result -Category "BrandColorMath" -Name ("Hex2RGB arithmetic: " + $c.Name + " (" + $c.Hex + ")") `
        -Passed $mathCorrect -Expected ("R=$($c.R) G=$($c.G) B=$($c.B)") -Actual ("R=$mathR G=$mathG B=$mathB") -Severity "HIGH"
        
    $hasRgbDef = $themeStyles -match ("--color-brand-" + $c.Name + ":\s*([0-9]+)\s+([0-9]+)\s+([0-9]+);")
    $actR = if ($hasRgbDef) { [int]$matches[1] } else { -1 }
    $actG = if ($hasRgbDef) { [int]$matches[2] } else { -1 }
    $actB = if ($hasRgbDef) { [int]$matches[3] } else { -1 }
    $rgbValid = ($hasRgbDef -and $actR -eq $c.R -and $actG -eq $c.G -and $actB -eq $c.B)
    Log-Result -Category "BrandTokenRGB" -Name ("Snippet RGB definition: --color-brand-" + $c.Name) `
        -Passed $rgbValid -Expected ("$($c.R) $($c.G) $($c.B)") -Actual ("$actR $actG $actB") -Severity "HIGH"
        
    $hasHexDef = $themeStyles -match ("--color-brand-" + $c.Name + "-hex:\s*([^;]+);")
    $actHex = if ($hasHexDef) { $matches[1].Trim() } else { "" }
    $hexValid = ($hasHexDef -and $actHex.ToUpper() -eq $c.Hex.ToUpper())
    Log-Result -Category "BrandTokenHex" -Name ("Snippet Hex definition: --color-brand-" + $c.Name + "-hex") `
        -Passed $hexValid -Expected $c.Hex -Actual $actHex -Severity "MEDIUM"
}

# ------------------------------------------------------------------------------
# 2. Color Schemes 1-4 RGB Triplet Validity & Liquid Extraction Simulation
# ------------------------------------------------------------------------------
Write-Host "`n--- 2. Color Schemes 1-4 RGB Triplet Validity ---" -ForegroundColor Yellow

$schemes = $settingsData.current.color_schemes
$expectedSchemes = @("scheme_1", "scheme_2", "scheme_3", "scheme_4")
$tokenFields = @("background", "text", "button", "button_label", "outline_button", "accent", "border")

foreach ($sName in $expectedSchemes) {
    $sProp = $schemes.$sName
    $schemeExists = ($sProp -ne $null -and $sProp.settings -ne $null)
    Log-Result -Category "SchemeConfig" -Name ("Scheme presence: " + $sName) `
        -Passed $schemeExists -Expected "Defined in settings_data.json" -Actual $(if ($schemeExists) { "Found" } else { "Missing" }) -Severity "CRITICAL"
        
    if ($schemeExists) {
        $st = $sProp.settings
        foreach ($tf in $tokenFields) {
            $hex = [string]$st.$tf
            $hasHex = ($hex -match '^#([0-9A-Fa-f]{6})$')
            Log-Result -Category "SchemeToken" -Name ("$sName.$tf hex format") `
                -Passed $hasHex -Expected "#RRGGBB format" -Actual $hex -Severity "HIGH"
                
            if ($hasHex) {
                $rawH = $hex.TrimStart('#')
                $r = [Convert]::ToInt32($rawH.Substring(0,2), 16)
                $g = [Convert]::ToInt32($rawH.Substring(2,2), 16)
                $b = [Convert]::ToInt32($rawH.Substring(4,2), 16)
                $inRange = ($r -ge 0 -and $r -le 255 -and $g -ge 0 -and $g -le 255 -and $b -ge 0 -and $b -le 255)
                Log-Result -Category "RGBChannels" -Name ("$sName.$tf RGB channel range [0..255]") `
                    -Passed $inRange -Expected "0..255" -Actual "$r $g $b" -Severity "CRITICAL"
            }
        }
    }
}

# ------------------------------------------------------------------------------
# 3. CSS Variable Selector Consistency (.color-scheme_X vs .color-scheme-X)
# ------------------------------------------------------------------------------
Write-Host "`n--- 3. CSS Variable Selector Consistency ---" -ForegroundColor Yellow

# In snippets/theme-styles.liquid: line 42 outputs {% if forloop.first %}:root, {% endif %}.color-{{ scheme.id }}
# In settings_data.json: schemes are keyed as scheme_1, scheme_2, etc. (underscore)
# Therefore, theme-styles generates: .color-scheme_1, .color-scheme_2, .color-scheme_3, .color-scheme_4
$generatesUnderscore = ($themeStyles -match '\.color-\{\{\s*scheme\.id\s*\}\}')
Log-Result -Category "SelectorSyntax" -Name "theme-styles generates .color-{{ scheme.id }} classes" `
    -Passed $generatesUnderscore -Expected ".color-{{ scheme.id }} present" -Actual "$generatesUnderscore" -Severity "MEDIUM"

# Does base.css or any section use hyphenated .color-scheme-1 or .color-scheme-3?
$baseCssHasScheme3Hyphen = ($baseCss -match '\.color-scheme-3\b')
Log-Result -Category "SelectorSyntax" -Name "base.css uses hyphenated .color-scheme-3 selector" `
    -Passed $baseCssHasScheme3Hyphen -Expected ".color-scheme-3 present" -Actual "$baseCssHasScheme3Hyphen" -Severity "LOW"

# Check if .color-scheme class exists to apply background-color and color
$hasColorSchemeApply = ($themeStyles -match '\.color-scheme\s*\{[^}]*(color:[^}]*background-color:|background-color:[^}]*color:)') -or `
                       ($baseCss -match '\.color-scheme\b[^{]*\{[^}]*(color:[^}]*background-color:|background-color:[^}]*color:)')
Log-Result -Category "SelectorSyntax" -Name ".color-scheme class applies background-color & color" `
    -Passed $hasColorSchemeApply -Expected ".color-scheme applies bg and text color" -Actual "$hasColorSchemeApply" -Severity "HIGH"

# ------------------------------------------------------------------------------
# 4. Font Stack & Fallback Chain Stress-Testing
# ------------------------------------------------------------------------------
Write-Host "`n--- 4. Font Fallback Chain & Typography Stress-Testing ---" -ForegroundColor Yellow

# 4.1 Google Fonts Loading
$googleLinkMatch = $themeLiquid -match 'https://fonts\.googleapis\.com/css2\?family=([^"''\s>]+)'
$loadedFonts = if ($googleLinkMatch) { $matches[1] } else { "" }
$hasInter = $loadedFonts -match 'Inter:wght@400;500;600;700'
$hasManrope = $loadedFonts -match 'Manrope:wght@300;400;500;600;700;800'
Log-Result -Category "FontLoading" -Name "Google Fonts loads Inter (weights 400, 500, 600, 700)" `
    -Passed ([bool]$hasInter) -Expected "Inter 400-700 in link" -Actual "$loadedFonts" -Severity "HIGH"
Log-Result -Category "FontLoading" -Name "Google Fonts loads Manrope (weights 300, 400, 500, 600, 700, 800)" `
    -Passed ([bool]$hasManrope) -Expected "Manrope 300-800 in link" -Actual "$loadedFonts" -Severity "HIGH"

# 4.2 Font token ordering in snippets/theme-styles.liquid
$bodyFontRule = if ($themeStyles -match '--font-body:\s*([^;]+);') { $matches[1] } else { "" }
$headingFontRule = if ($themeStyles -match '--font-heading:\s*([^;]+);') { $matches[1] } else { "" }

$manropeFirstBody = $bodyFontRule.Trim().StartsWith("'Manrope'")
$manropeFirstHead = $headingFontRule.Trim().StartsWith("'Manrope'")
Log-Result -Category "FontPriority" -Name "--font-body prioritizes Manrope first" `
    -Passed $manropeFirstBody -Expected "Starts with 'Manrope'" -Actual "$bodyFontRule" -Severity "HIGH"
Log-Result -Category "FontPriority" -Name "--font-heading prioritizes Manrope first" `
    -Passed $manropeFirstHead -Expected "Starts with 'Manrope'" -Actual "$headingFontRule" -Severity "HIGH"

# 4.3 Check Inter immediately follows Manrope
$interSecondBody = ($bodyFontRule -match "'Manrope',\s*'Inter'")
$interSecondHead = ($headingFontRule -match "'Manrope',\s*'Inter'")
Log-Result -Category "FontPriority" -Name "--font-body prioritizes Inter as second fallback" `
    -Passed $interSecondBody -Expected "'Manrope', 'Inter'" -Actual "$bodyFontRule" -Severity "MEDIUM"
Log-Result -Category "FontPriority" -Name "--font-heading prioritizes Inter as second fallback" `
    -Passed $interSecondHead -Expected "'Manrope', 'Inter'" -Actual "$headingFontRule" -Severity "MEDIUM"

# 4.4 Empirical stress-test on generic fallback positioning:
# If body_font.fallback_families expands to 'sans-serif', does generic sans-serif appear before -apple-system?
# Note: In standard CSS, once a generic family like sans-serif is encountered, browser matches immediately.
# System fonts placed AFTER a generic family are technically shadowed.
$shadowCheck = ($bodyFontRule -match 'fallback_families.*-apple-system')
Log-Result -Category "FontFallbackRisk" -Name "Fallback generic family placement analysis" `
    -Passed $true -Expected "Analyzed" -Actual $(if ($shadowCheck) { "Generic fallback_families precedes system stack (-apple-system), creating shadowing if fallback_families evaluates to sans-serif" } else { "System stack placed before generic" }) -Severity "INFO"

# 4.5 Typography utility classes in base.css
$hasMicroLabel = ($baseCss -match '\.micro-label[^{]*\{[^}]*text-transform:\s*uppercase')
$hasMicroEyebrow = ($baseCss -match '\.micro-eyebrow[^{]*\{[^}]*text-transform:\s*uppercase')
$hasLetterSpacingMicro = ($baseCss -match '\.micro-(label|eyebrow)[^{]*\{[^}]*letter-spacing:\s*0\.[0-9]+em')
Log-Result -Category "TypographyCSS" -Name ".micro-label utility class uppercase defined" `
    -Passed $hasMicroLabel -Expected "text-transform: uppercase" -Actual "$hasMicroLabel" -Severity "HIGH"
Log-Result -Category "TypographyCSS" -Name ".micro-eyebrow utility class uppercase defined" `
    -Passed $hasMicroEyebrow -Expected "text-transform: uppercase" -Actual "$hasMicroEyebrow" -Severity "HIGH"
Log-Result -Category "TypographyCSS" -Name ".micro-label has subtle letter-spacing" `
    -Passed $hasLetterSpacingMicro -Expected "letter-spacing: 0.14em" -Actual "$hasLetterSpacingMicro" -Severity "MEDIUM"

# ------------------------------------------------------------------------------
# 5. Token Override & Removal Resilience
# ------------------------------------------------------------------------------
Write-Host "`n--- 5. Token Override & Removal Resilience ---" -ForegroundColor Yellow

# 5.1 Test fallback for --color-text-secondary:
$hasSecondaryFallback = ($baseCss -match 'var\(--color-text-secondary,\s*var\(--color-text\)\)')
Log-Result -Category "Resilience" -Name "--color-text-secondary has safe fallback to var(--color-text)" `
    -Passed $hasSecondaryFallback -Expected "var(--color-text-secondary, var(--color-text))" -Actual "$hasSecondaryFallback" -Severity "MEDIUM"

# 5.2 Test banner text fallback:
$hasBannerFallback = ($baseCss -match 'var\(--color-banner-text,\s*var\(--color-text\)\)')
Log-Result -Category "Resilience" -Name "--color-banner-text has safe fallback to var(--color-text)" `
    -Passed $hasBannerFallback -Expected "var(--color-banner-text, var(--color-text))" -Actual "$hasBannerFallback" -Severity "MEDIUM"

# 5.3 Button radius resilience:
$radiusBase = $settingsData.current.radius_base
$radiusInRange = ($radiusBase -ne $null -and [int]$radiusBase -ge 2 -and [int]$radiusBase -le 8)
Log-Result -Category "Resilience" -Name "Button radius setting conforms to 2-8px brand boundary" `
    -Passed $radiusInRange -Expected "2..8px" -Actual "$radiusBase px" -Severity "HIGH"

# 5.4 Media radius resilience:
$radiusMedia = $settingsData.current.radius_media
$mediaRadiusInRange = ($radiusMedia -ne $null -and [int]$radiusMedia -ge 0 -and [int]$radiusMedia -le 24)
Log-Result -Category "Resilience" -Name "Media radius setting conforms to sensible boundary" `
    -Passed $mediaRadiusInRange -Expected "0..24px" -Actual "$radiusMedia px" -Severity "MEDIUM"

# 5.5 Check WCAG AA Contrast Ratio on brand combinations
Write-Host "`n--- 6. Contrast & Color Accessibility Stress-Testing ---" -ForegroundColor Yellow

function Get-Luminance($r, $g, $b) {
    $vals = @($r, $g, $b) | ForEach-Object {
        $v = $_ / 255.0
        if ($v -le 0.03928) { $v / 12.92 } else { [Math]::Pow((($v + 0.055) / 1.055), 2.4) }
    }
    return 0.2126 * $vals[0] + 0.7152 * $vals[1] + 0.0722 * $vals[2]
}

function Get-ContrastRatio($c1Hex, $c2Hex) {
    $h1 = $c1Hex.TrimStart('#')
    $r1 = [Convert]::ToInt32($h1.Substring(0,2), 16)
    $g1 = [Convert]::ToInt32($h1.Substring(2,2), 16)
    $b1 = [Convert]::ToInt32($h1.Substring(4,2), 16)
    $l1 = Get-Luminance $r1 $g1 $b1
    
    $h2 = $c2Hex.TrimStart('#')
    $r2 = [Convert]::ToInt32($h2.Substring(0,2), 16)
    $g2 = [Convert]::ToInt32($h2.Substring(2,2), 16)
    $b2 = [Convert]::ToInt32($h2.Substring(4,2), 16)
    $l2 = Get-Luminance $r2 $g2 $b2
    
    $brightest = [Math]::Max($l1, $l2)
    $darkest = [Math]::Min($l1, $l2)
    return [Math]::Round((($brightest + 0.05) / ($darkest + 0.05)), 2)
}

# Scheme 1: Text (#111111) on Background (#FCFAF6)
$crScheme1 = Get-ContrastRatio "#111111" "#FCFAF6"
$passScheme1 = ($crScheme1 -ge 4.5)
Log-Result -Category "WCAG_Contrast" -Name "Scheme 1: Body Text (#111111) on Off-White (#FCFAF6)" `
    -Passed $passScheme1 -Expected ">= 4.5:1" -Actual "$crScheme1 : 1" -Severity "HIGH"

# Scheme 2: Text (#111111) on Cream (#F7F3EB)
$crScheme2 = Get-ContrastRatio "#111111" "#F7F3EB"
$passScheme2 = ($crScheme2 -ge 4.5)
Log-Result -Category "WCAG_Contrast" -Name "Scheme 2: Body Text (#111111) on Cream (#F7F3EB)" `
    -Passed $passScheme2 -Expected ">= 4.5:1" -Actual "$crScheme2 : 1" -Severity "HIGH"

# Scheme 3: Text (#F7F3EB) on Matte Black (#111111)
$crScheme3 = Get-ContrastRatio "#F7F3EB" "#111111"
$passScheme3 = ($crScheme3 -ge 4.5)
Log-Result -Category "WCAG_Contrast" -Name "Scheme 3: Inverted Text (#F7F3EB) on Black (#111111)" `
    -Passed $passScheme3 -Expected ">= 4.5:1" -Actual "$crScheme3 : 1" -Severity "HIGH"

# Scheme 4: Text (#F7F3EB) on Deep Espresso (#2A1D17)
$crScheme4 = Get-ContrastRatio "#F7F3EB" "#2A1D17"
$passScheme4 = ($crScheme4 -ge 4.5)
Log-Result -Category "WCAG_Contrast" -Name "Scheme 4: Inverted Text (#F7F3EB) on Espresso (#2A1D17)" `
    -Passed $passScheme4 -Expected ">= 4.5:1" -Actual "$crScheme4 : 1" -Severity "HIGH"

# Primary Button Scheme 1: White text (#FFFFFF) on Black button (#111111)
$crBtn1 = Get-ContrastRatio "#FFFFFF" "#111111"
$passBtn1 = ($crBtn1 -ge 4.5)
Log-Result -Category "WCAG_Contrast" -Name "Button Scheme 1: White (#FFFFFF) on Black (#111111)" `
    -Passed $passBtn1 -Expected ">= 4.5:1" -Actual "$crBtn1 : 1" -Severity "HIGH"

# Accent Button Scheme 3: White text (#FFFFFF) on Copper button (#9A6238)
$crBtnCopper = Get-ContrastRatio "#FFFFFF" "#9A6238"
$passBtnCopper = ($crBtnCopper -ge 3.0) # 3.0:1 for large/UI components, 4.5 for text
Log-Result -Category "WCAG_Contrast" -Name "Button Scheme 3: White (#FFFFFF) on Copper (#9A6238)" `
    -Passed ($crBtnCopper -ge 4.5) -Expected ">= 4.5:1 (WCAG AA)" -Actual "$crBtnCopper : 1" -Severity "LOW"

# Secondary Gray Text (#77716B) on Cream (#F7F3EB)
$crGrayCream = Get-ContrastRatio "#77716B" "#F7F3EB"
Log-Result -Category "WCAG_Contrast" -Name "Secondary Text: Medium Gray (#77716B) on Cream (#F7F3EB)" `
    -Passed ($crGrayCream -ge 4.5) -Expected ">= 4.5:1 (WCAG AA)" -Actual "$crGrayCream : 1" -Severity "LOW"

# Secondary Gray Text (#77716B) on Black (#111111) (Dark scheme risk)
$crGrayBlack = Get-ContrastRatio "#77716B" "#111111"
Log-Result -Category "WCAG_Contrast" -Name "Secondary Text: Medium Gray (#77716B) on Black (#111111)" `
    -Passed ($crGrayBlack -ge 4.5) -Expected ">= 4.5:1 (WCAG AA)" -Actual "$crGrayBlack : 1" -Severity "LOW"

# ------------------------------------------------------------------------------
# 7. Investigation of Test F04-04 in run_e2e_tests.ps1
# ------------------------------------------------------------------------------
Write-Host "`n--- 7. Investigation of F04-04 in run_e2e_tests.ps1 ---" -ForegroundColor Yellow

# Check how run_e2e_tests.ps1 tests F04-04:
# ($settingsData -and ($settingsData | Out-String) -match '(?i)(Dose|Dial|F7F3EB|FCFAF6)')
# Verify why it failed:
$outString = $settingsData | Out-String
$outStringMatch = ($outString -match '(?i)(Dose|Dial|F7F3EB|FCFAF6)')
$rawContentMatch = ($settingsDataJson -match '(?i)(Dose|Dial|F7F3EB|FCFAF6)')

Log-Result -Category "E2E_TestHarness" -Name "F04-04 Test Harness Out-String limitation verified" `
    -Passed ($outStringMatch -eq $false -and $rawContentMatch -eq $true) `
    -Expected "Out-String truncates nested PSCustomObject while raw JSON contains brand tokens" `
    -Actual ("Out-String match: $outStringMatch, Raw JSON match: $rawContentMatch") -Severity "INFO"

# Summary
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGE STRESS TEST SUMMARY                                      " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$totalTests = $Report.Count
$passedTests = ($Report | Where-Object { $_.Passed }).Count
$failedTests = ($Report | Where-Object { -not $_.Passed }).Count

Write-Host ("Total Empirical Assertions: {0}" -f $totalTests) -ForegroundColor White
Write-Host ("Passed Assertions:          {0}" -f $passedTests) -ForegroundColor Green
Write-Host ("Failed/Flagged Assertions:  {0}" -f $failedTests) -ForegroundColor $(if ($failedTests -eq 0) { "Green" } else { "Yellow" })

Write-Host "======================================================================" -ForegroundColor Cyan


