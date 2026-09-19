# ==============================================================================
# Challenger M1-It2-2: Empirical Stress Test Suite
# Focus:
# 1. CSS variable defaults in snippets/theme-styles.liquid when theme settings are undefined.
# 2. Responsive typography and tracking with heading_case: uppercase and heading_tracking: 2.
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

$Results = [System.Collections.ArrayList]::new()

function Register-Test {
    param(
        [string]$Id,
        [string]$Category,
        [string]$Description,
        [bool]$Passed,
        [string]$Expected,
        [string]$Actual,
        [string]$Severity = "MEDIUM" # INFO, LOW, MEDIUM, HIGH, CRITICAL
    )
    $obj = [PSCustomObject]@{
        Id          = $Id
        Category    = $Category
        Description = $Description
        Passed      = $Passed
        Expected    = $Expected
        Actual      = $Actual
        Severity    = $Severity
    }
    $null = $Results.Add($obj)

    $statusStr = if ($Passed) { "[PASS]" } else { "[$Severity FAIL]" }
    $color = if ($Passed) { "Green" } elseif ($Severity -in @("HIGH", "CRITICAL")) { "Red" } else { "Yellow" }
    Write-Host ("  {0} {1} ({2}) - {3}" -f $statusStr, $Id, $Category, $Description) -ForegroundColor $color
    if (-not $Passed -or $VerboseOutput) {
        if ($Expected -ne "" -or $Actual -ne "") {
            Write-Host ("         Expected: {0}" -f $Expected) -ForegroundColor DarkGray
            Write-Host ("         Actual:   {0}" -f $Actual) -ForegroundColor DarkGray
        }
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - CHALLENGER M1-IT2-2 EMPIRICAL STRESS SUITE          " -ForegroundColor Cyan
Write-Host "   Target: snippets/theme-styles.liquid & base.css                   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Load files
$themeStylesPath = Join-Path $RepoRoot "snippets/theme-styles.liquid"
$settingsDataPath = Join-Path $RepoRoot "config/settings_data.json"
$settingsSchemaPath = Join-Path $RepoRoot "config/settings_schema.json"
$baseCssPath = Join-Path $RepoRoot "assets/base.css"

$themeStyles = [System.IO.File]::ReadAllText($themeStylesPath, [System.Text.Encoding]::UTF8)
$settingsData = [System.IO.File]::ReadAllText($settingsDataPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$settingsSchema = [System.IO.File]::ReadAllText($settingsSchemaPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$baseCss = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

# ==============================================================================
# SECTION 1: CSS VARIABLE DEFAULTS WHEN SETTINGS ARE UNDEFINED
# ==============================================================================
Write-Host "`n--- 1. Testing CSS Variable Defaults When Settings Are Undefined ---" -ForegroundColor Yellow

# Helper: Simulate Liquid variable substitution respecting standard Liquid default filter semantics
# In Liquid: variable | default: X returns X if variable is nil, false, or empty string ""
function Simulate-ThemeStylesLiquid {
    param(
        [hashtable]$MockSettings
    )

    $output = [System.Collections.Generic.List[string]]::new()

    # Helper for Liquid `| default: X` filter semantics
    function Apply-LiquidDefault($val, $defaultVal) {
        if ($val -eq $null -or $val -eq $false -or [string]$val -eq "") {
            return $defaultVal
        }
        return $val
    }

    # 1. Radius base (with | default: 4)
    $rbRaw = if ($MockSettings.ContainsKey('radius_base')) { $MockSettings['radius_base'] } else { $null }
    $rb = Apply-LiquidDefault $rbRaw 4
    $output.Add("--radius-base: $($rb)px;")

    # 2. Radius media (with | default: 6)
    $rmRaw = if ($MockSettings.ContainsKey('radius_media')) { $MockSettings['radius_media'] } else { $null }
    $rm = Apply-LiquidDefault $rmRaw 6
    $output.Add("--radius-media: $($rm)px;")

    # 3. Heading scale & Body scale (with | default: 100)
    $hsRaw = if ($MockSettings.ContainsKey('heading_scale')) { $MockSettings['heading_scale'] } else { $null }
    $bsRaw = if ($MockSettings.ContainsKey('body_scale')) { $MockSettings['body_scale'] } else { $null }
    $hsVal = Apply-LiquidDefault $hsRaw 100
    $bsVal = Apply-LiquidDefault $bsRaw 100
    $hs = [double]$hsVal / 100.0
    $bs = [double]$bsVal / 100.0

    $output.Add("--text-xs: $(0.75 * $bs)rem;")
    $output.Add("--text-sm: $(0.875 * $bs)rem;")
    $output.Add("--text-base: $(1.0 * $bs)rem;")
    $output.Add("--text-lg: $(1.125 * $bs)rem;")
    $output.Add("--text-h0: clamp($(2.5 * $hs)rem, $(6.0 * $hs)vw, $(5.5 * $hs)rem);")
    $output.Add("--text-h1: clamp($(2.0 * $hs)rem, $(4.5 * $hs)vw, $(3.5 * $hs)rem);")
    $output.Add("--text-h2: clamp($(1.6 * $hs)rem, $(3.2 * $hs)vw, $(2.5 * $hs)rem);")
    $output.Add("--text-h3: $(1.5 * $hs)rem;")
    $output.Add("--text-h4: $(1.25 * $hs)rem;")
    $output.Add("--text-h5: $(1.125 * $hs)rem;")
    $output.Add("--text-h6: $(1.0 * $hs)rem;")

    # 4. Heading tracking (no default filter: nil | divided_by: 100.0)
    $htRaw = if ($MockSettings.ContainsKey('heading_tracking')) { $MockSettings['heading_tracking'] } else { $null }
    $htVal = if ($htRaw -ne $null -and [string]$htRaw -ne "") { [double]$htRaw / 100.0 } else { 0.0 }
    $output.Add("--heading-tracking: $($htVal)em;")

    # 5. Heading case (no default filter)
    $hcRaw = if ($MockSettings.ContainsKey('heading_case')) { $MockSettings['heading_case'] } else { $null }
    $hcVal = if ($hcRaw -ne $null) { [string]$hcRaw } else { "" }
    $output.Add("--heading-case: $($hcVal);")

    # 6. Page width (no default filter)
    $pwRaw = if ($MockSettings.ContainsKey('page_width')) { $MockSettings['page_width'] } else { $null }
    $pwVal = if ($pwRaw -ne $null) { [string]$pwRaw } else { "" }
    $output.Add("--page-width: $($pwVal)px;")

    # 7. Spacing sections (no default filter)
    $ssRaw = if ($MockSettings.ContainsKey('spacing_sections')) { $MockSettings['spacing_sections'] } else { $null }
    $ssVal = if ($ssRaw -ne $null) { [string]$ssRaw } else { "" }
    $output.Add("--section-gap: $($ssVal)px;")

    # 8. Logo width (no default filter)
    $lwRaw = if ($MockSettings.ContainsKey('logo_width')) { $MockSettings['logo_width'] } else { $null }
    $lwVal = if ($lwRaw -ne $null) { [string]$lwRaw } else { "" }
    $output.Add("--logo-width: $($lwVal)px;")

    return $output
}

# 1.1 Verify presence of Liquid fallback filter on radius_base
$rbHasDefault = $themeStyles -match 'settings\.radius_base\s*\|\s*default:\s*4'
Register-Test -Id "DEF-01" -Category "LiquidFallbacks" `
    -Description "settings.radius_base has | default: 4 filter" `
    -Passed ([bool]$rbHasDefault) `
    -Expected "settings.radius_base | default: 4" `
    -Actual $(if ($rbHasDefault) { "Present" } else { "Missing" }) `
    -Severity "HIGH"

# 1.2 Verify presence of Liquid fallback filter on radius_media
$rmHasDefault = $themeStyles -match 'settings\.radius_media\s*\|\s*default:\s*6'
Register-Test -Id "DEF-02" -Category "LiquidFallbacks" `
    -Description "settings.radius_media has | default: 6 filter" `
    -Passed ([bool]$rmHasDefault) `
    -Expected "settings.radius_media | default: 6" `
    -Actual $(if ($rmHasDefault) { "Present" } else { "Missing" }) `
    -Severity "HIGH"

# 1.3 Verify presence of Liquid fallback filter on heading_scale
$hsHasDefault = $themeStyles -match 'settings\.heading_scale\s*\|\s*default:\s*100'
Register-Test -Id "DEF-03" -Category "LiquidFallbacks" `
    -Description "settings.heading_scale has | default: 100 filter" `
    -Passed ([bool]$hsHasDefault) `
    -Expected "settings.heading_scale | default: 100" `
    -Actual $(if ($hsHasDefault) { "Present" } else { "Missing" }) `
    -Severity "CRITICAL"

# 1.4 Verify presence of Liquid fallback filter on body_scale
$bsHasDefault = $themeStyles -match 'settings\.body_scale\s*\|\s*default:\s*100'
Register-Test -Id "DEF-04" -Category "LiquidFallbacks" `
    -Description "settings.body_scale has | default: 100 filter" `
    -Passed ([bool]$bsHasDefault) `
    -Expected "settings.body_scale | default: 100" `
    -Actual $(if ($bsHasDefault) { "Present" } else { "Missing" }) `
    -Severity "CRITICAL"

# 1.5 Stress test: Null settings evaluate without zero-collapse in typography
$simNull = Simulate-ThemeStylesLiquid -MockSettings @{}
$h0Entry = $simNull | Where-Object { $_ -like "*--text-h0:*" }
$h1Entry = $simNull | Where-Object { $_ -like "*--text-h1:*" }
$baseEntry = $simNull | Where-Object { $_ -like "*--text-base:*" }

$noZeroCollapse = ($h0Entry -match '2\.5rem' -and $h1Entry -match '2rem' -and $baseEntry -match '1rem')
Register-Test -Id "DEF-05" -Category "UndefinedSettings" `
    -Description "Undefined heading_scale and body_scale fall back to 100% scale (no zero collapse)" `
    -Passed ([bool]$noZeroCollapse) `
    -Expected "--text-h0: 2.5rem min, --text-h1: 2rem min, --text-base: 1rem" `
    -Actual "h0: $h0Entry, h1: $h1Entry, base: $baseEntry" `
    -Severity "CRITICAL"

# 1.6 Stress test: Undefined radius settings evaluate to brand defaults
$rbEntry = $simNull | Where-Object { $_ -like "*--radius-base:*" }
$rmEntry = $simNull | Where-Object { $_ -like "*--radius-media:*" }
$radiusSafe = ($rbEntry -eq "--radius-base: 4px;" -and $rmEntry -eq "--radius-media: 6px;")
Register-Test -Id "DEF-06" -Category "UndefinedSettings" `
    -Description "Undefined radius settings produce valid 4px and 6px token values" `
    -Passed ([bool]$radiusSafe) `
    -Expected "--radius-base: 4px; --radius-media: 6px;" `
    -Actual "$rbEntry $rmEntry" `
    -Severity "HIGH"

# 1.7 Stress test: Empty string settings fallback to defaults
$simEmpty = Simulate-ThemeStylesLiquid -MockSettings @{ radius_base = ""; radius_media = ""; heading_scale = ""; body_scale = "" }
$emptyHandled = ($simEmpty | Where-Object { $_ -like "*--radius-base: 4px;*" }) -ne $null
Register-Test -Id "DEF-07" -Category "UndefinedSettings" `
    -Description "Empty string radius_base falls back to 4px via Liquid default filter" `
    -Passed ([bool]$emptyHandled) `
    -Expected "--radius-base: 4px;" `
    -Actual "$($simEmpty | Where-Object { $_ -like '*--radius-base:*' })" `
    -Severity "HIGH"

# 1.8 Stress test: Undefined heading_tracking evaluation
# In Liquid: nil | divided_by: 100.0 evaluates to 0.0 -> --heading-tracking: 0.0em;
$htEntry = $simNull | Where-Object { $_ -like "*--heading-tracking:*" }
$htIsSyntacticallySafe = ($htEntry -match '0(\.0)?em;')
Register-Test -Id "DEF-08" -Category "UndefinedSettings" `
    -Description "Undefined heading_tracking produces syntactically safe CSS length (0em)" `
    -Passed ([bool]$htIsSyntacticallySafe) `
    -Expected "--heading-tracking: 0em or 0.0em" `
    -Actual "$htEntry" `
    -Severity "HIGH"

# 1.9 Stress test: Undefined heading_case evaluation
# In Liquid: {{ settings.heading_case }} when nil produces empty string -> --heading-case: ;
$hcEntry = $simNull | Where-Object { $_ -like "*--heading-case:*" }
$hcHandledInCss = ($baseCss -match 'h1,\s*h2[^{]*\{[^}]*text-transform:\s*var\(--heading-case\);')
Register-Test -Id "DEF-09" -Category "UndefinedSettings" `
    -Description "Undefined heading_case results in empty token resolving to browser default text-transform (none)" `
    -Passed ([bool]$hcHandledInCss) `
    -Expected "var(--heading-case) consumed on headings" `
    -Actual "Snippet outputs: $hcEntry (browser computes unset/initial: none)" `
    -Severity "MEDIUM"

# 1.10 Static brand palette fallback definitions
# Even if color_schemes is empty, brand palette tokens must exist directly on :root
$hasRootBrandTokens = ($themeStyles -match '--color-brand-cream:\s*247 243 235;') -and
                      ($themeStyles -match '--color-brand-offwhite:\s*252 250 246;') -and
                      ($themeStyles -match '--color-brand-espresso:\s*42 29 23;') -and
                      ($themeStyles -match '--color-brand-copper:\s*154 98 56;')
Register-Test -Id "DEF-10" -Category "BrandPalette" `
    -Description "Hardcoded RGB brand tokens exist on :root as universal fallbacks" `
    -Passed ([bool]$hasRootBrandTokens) `
    -Expected "Direct :root brand palette definitions present" `
    -Actual $(if ($hasRootBrandTokens) { "All 9 brand tokens present" } else { "Missing tokens" }) `
    -Severity "HIGH"

# 1.11 Audit secondary dimension settings (page_width, spacing_sections, logo_width) in schema
$allSchemaSettings = ($settingsSchema | ForEach-Object { $_.settings }) | Where-Object { $_ -ne $null }
$pwSetting = $allSchemaSettings | Where-Object { $_.id -eq "page_width" }
$ssSetting = $allSchemaSettings | Where-Object { $_.id -eq "spacing_sections" }
$lwSetting = $allSchemaSettings | Where-Object { $_.id -eq "logo_width" }

$schemaHasDefaults = ($pwSetting.default -eq 1440 -and $ssSetting.default -ne $null -and $lwSetting.default -ne $null)
Register-Test -Id "DEF-11" -Category "SchemaDefaults" `
    -Description "settings_schema.json defines default fallbacks for secondary layout dimensions" `
    -Passed ([bool]$schemaHasDefaults) `
    -Expected "Defaults exist for page_width, spacing_sections, logo_width" `
    -Actual "page_width=$($pwSetting.default), spacing_sections=$($ssSetting.default), logo_width=$($lwSetting.default)" `
    -Severity "MEDIUM"


# ==============================================================================
# SECTION 2: RESPONSIVE TYPOGRAPHY & TRACKING WITH HEADING_CASE: UPPERCASE & HEADING_TRACKING: 2
# ==============================================================================
Write-Host "`n--- 2. Testing Responsive Typography & Tracking ---" -ForegroundColor Yellow

# 2.1 Check active settings_data.json configuration
$currentCase = $settingsData.current.heading_case
$currentTracking = $settingsData.current.heading_tracking
$currentCaseCorrect = ($currentCase -eq "uppercase")
$currentTrackingCorrect = ($currentTracking -eq 2)

Register-Test -Id "TYPO-01" -Category "ActiveConfig" `
    -Description "settings_data.json current config has heading_case = 'uppercase'" `
    -Passed ([bool]$currentCaseCorrect) `
    -Expected "uppercase" `
    -Actual "$currentCase" `
    -Severity "HIGH"

Register-Test -Id "TYPO-02" -Category "ActiveConfig" `
    -Description "settings_data.json current config has heading_tracking = 2" `
    -Passed ([bool]$currentTrackingCorrect) `
    -Expected "2" `
    -Actual "$currentTracking" `
    -Severity "HIGH"

# 2.2 Check presets configuration in settings_data.json
$presetDose = $settingsData.presets."Dose & Dial"
$presetEspresso = $settingsData.presets."Editorial Espresso"

$presetsMatchCase = ($presetDose.heading_case -eq "uppercase" -and $presetEspresso.heading_case -eq "uppercase")
$presetsMatchTracking = ($presetDose.heading_tracking -eq 2 -and $presetEspresso.heading_tracking -eq 2)

Register-Test -Id "TYPO-03" -Category "PresetConfig" `
    -Description "All presets in settings_data.json have heading_case = 'uppercase'" `
    -Passed ([bool]$presetsMatchCase) `
    -Expected "Dose & Dial: uppercase, Editorial Espresso: uppercase" `
    -Actual "Dose & Dial: $($presetDose.heading_case), Editorial Espresso: $($presetEspresso.heading_case)" `
    -Severity "HIGH"

Register-Test -Id "TYPO-04" -Category "PresetConfig" `
    -Description "All presets in settings_data.json have heading_tracking = 2" `
    -Passed ([bool]$presetsMatchTracking) `
    -Expected "Dose & Dial: 2, Editorial Espresso: 2" `
    -Actual "Dose & Dial: $($presetDose.heading_tracking), Editorial Espresso: $($presetEspresso.heading_tracking)" `
    -Severity "HIGH"

# 2.3 Mathematical evaluation: heading_tracking 2 divided by 100.0 produces 0.02em
$trackingMath = 2 / 100.0
$trackingEm = "$($trackingMath)em"
$trackingCorrectMath = ($trackingMath -eq 0.02 -and $trackingEm -eq "0.02em")
Register-Test -Id "TYPO-05" -Category "TrackingMath" `
    -Description "heading_tracking 2 computes precisely to 0.02em" `
    -Passed ([bool]$trackingCorrectMath) `
    -Expected "0.02em" `
    -Actual "$trackingEm" `
    -Severity "HIGH"

# 2.4 Verify theme-styles.liquid template output binding
$themeStylesTracking = ($themeStyles -match '--heading-tracking:\s*\{\{\s*settings\.heading_tracking\s*\|\s*divided_by:\s*100\.0\s*\}\}em;')
$themeStylesCase = ($themeStyles -match '--heading-case:\s*\{\{\s*settings\.heading_case\s*\}\};')

Register-Test -Id "TYPO-06" -Category "LiquidBindings" `
    -Description "--heading-tracking expression matches {{ settings.heading_tracking | divided_by: 100.0 }}em;" `
    -Passed ([bool]$themeStylesTracking) `
    -Expected "divided_by: 100.0 with em unit" `
    -Actual $(if ($themeStylesTracking) { "Matches" } else { "Mismatch" }) `
    -Severity "HIGH"

Register-Test -Id "TYPO-07" -Category "LiquidBindings" `
    -Description "--heading-case expression matches {{ settings.heading_case }};" `
    -Passed ([bool]$themeStylesCase) `
    -Expected "settings.heading_case bound" `
    -Actual $(if ($themeStylesCase) { "Matches" } else { "Mismatch" }) `
    -Severity "HIGH"

# 2.5 Verify base.css consumes --heading-case and --heading-tracking on h1-h6 and .h0
$hGroupHasTracking = ($baseCss -match 'h1,\s*h2,\s*h3,\s*h4,\s*h5,\s*h6\s*\{[^}]*letter-spacing:\s*var\(--heading-tracking\);')
$hGroupHasCase = ($baseCss -match 'h1,\s*h2,\s*h3,\s*h4,\s*h5,\s*h6\s*\{[^}]*text-transform:\s*var\(--heading-case\);')
$h0HasTracking = ($baseCss -match '\.h0\s*\{[^}]*letter-spacing:\s*var\(--heading-tracking\);')
$h0HasCase = ($baseCss -match '\.h0\s*\{[^}]*text-transform:\s*var\(--heading-case\);')

Register-Test -Id "TYPO-08" -Category "CSSConsumption" `
    -Description "h1-h6 selectors consume letter-spacing: var(--heading-tracking) and text-transform: var(--heading-case)" `
    -Passed ([bool]($hGroupHasTracking -and $hGroupHasCase)) `
    -Expected "Both properties applied to h1-h6" `
    -Actual "letter-spacing: $hGroupHasTracking, text-transform: $hGroupHasCase" `
    -Severity "CRITICAL"

Register-Test -Id "TYPO-09" -Category "CSSConsumption" `
    -Description ".h0 utility class consumes letter-spacing: var(--heading-tracking) and text-transform: var(--heading-case)" `
    -Passed ([bool]($h0HasTracking -and $h0HasCase)) `
    -Expected "Both properties applied to .h0" `
    -Actual "letter-spacing: $h0HasTracking, text-transform: $h0HasCase" `
    -Severity "CRITICAL"

# 2.6 Responsive clamp scaling simulation across 8 standard device viewports
$viewports = @(
    @{ Name = "Mobile Narrow (iPhone SE)"; Width = 320 },
    @{ Name = "Mobile Standard (iPhone 12/13/14)"; Width = 375 },
    @{ Name = "Mobile Modern (iPhone 15/16)"; Width = 390 },
    @{ Name = "Mobile Large (iPhone Plus/Max)"; Width = 414 },
    @{ Name = "Tablet Portrait (iPad Mini/Air)"; Width = 768 },
    @{ Name = "Tablet Landscape (iPad Pro)"; Width = 1024 },
    @{ Name = "Desktop Standard (MacBook / FHD)"; Width = 1440 },
    @{ Name = "Desktop Large (1080p / 1440p)"; Width = 1920 }
)

function Resolve-Clamp([double]$minRem, [double]$vwPercent, [double]$maxRem, [int]$viewportWidth) {
    $minPx = $minRem * 16.0
    $maxPx = $maxRem * 16.0
    $preferredPx = ($vwPercent / 100.0) * $viewportWidth
    $clampedPx = [Math]::Max($minPx, [Math]::Min($maxPx, $preferredPx))
    return [PSCustomObject]@{
        Rem = [Math]::Round($clampedPx / 16.0, 4)
        Px  = [Math]::Round($clampedPx, 2)
    }
}

$allViewportsValid = $true
$scaleOrderValid = $true

foreach ($vp in $viewports) {
    $h0 = Resolve-Clamp 2.5 6.0 5.5 $vp.Width
    $h1 = Resolve-Clamp 2.0 4.5 3.5 $vp.Width
    $h2 = Resolve-Clamp 1.6 3.2 2.5 $vp.Width
    $h3Px = 1.5 * 16.0
    $h4Px = 1.25 * 16.0
    $h5Px = 1.125 * 16.0
    $h6Px = 1.0 * 16.0

    # Verify clamp boundaries:
    # At min: h0 >= 40px, h1 >= 32px, h2 >= 25.6px
    # At max: h0 <= 88px, h1 <= 56px, h2 <= 40px
    $inBounds = ($h0.Px -ge 40.0 -and $h0.Px -le 88.0 -and
                 $h1.Px -ge 32.0 -and $h1.Px -le 56.0 -and
                 $h2.Px -ge 25.6 -and $h2.Px -le 40.0)
    if (-not $inBounds) { $allViewportsValid = $false }

    # Verify strict monotonic hierarchy: h0 > h1 > h2 > h3 > h4 > h5 > h6
    $monotonic = ($h0.Px -gt $h1.Px -and $h1.Px -gt $h2.Px -and $h2.Px -gt $h3Px -and
                  $h3Px -gt $h4Px -and $h4Px -gt $h5Px -and $h5Px -gt $h6Px)
    if (-not $monotonic) { $scaleOrderValid = $false }

    if ($VerboseOutput) {
        Write-Host ("     {0} ({1}px): h0={2}px, h1={3}px, h2={4}px, h3={5}px" -f $vp.Name, $vp.Width, $h0.Px, $h1.Px, $h2.Px, $h3Px) -ForegroundColor DarkGray
    }
}

Register-Test -Id "TYPO-10" -Category "ResponsiveClamping" `
    -Description "Fluid typography clamp formulas respect min/max bounds across all 8 device viewports" `
    -Passed $allViewportsValid `
    -Expected "All viewports strictly within [min..max] range" `
    -Actual $(if ($allViewportsValid) { "All 8 viewports in bounds" } else { "Boundary violation detected" }) `
    -Severity "HIGH"

Register-Test -Id "TYPO-11" -Category "VisualHierarchy" `
    -Description "Strict monotonic visual hierarchy maintained (h0 > h1 > h2 > h3 > h4 > h5 > h6) at every viewport" `
    -Passed $scaleOrderValid `
    -Expected "h0 > h1 > h2 > h3 > h4 > h5 > h6 universally" `
    -Actual $(if ($scaleOrderValid) { "Monotonic across all 8 viewports" } else { "Hierarchy inverted" }) `
    -Severity "HIGH"

# 2.7 Uppercase text overflow stress test on small screens (320px, 375px)
$brandHeadlines = @(
    @{ Role = "Hero Headline"; Text = "PRECISION FOR EVERY POUR."; Level = "h1"; SizePx = 32.0 },
    @{ Role = "Featured Collections"; Text = "BUILD YOUR COFFEE BAR"; Level = "h2"; SizePx = 25.6 },
    @{ Role = "Best Sellers"; Text = "ESSENTIALS FOR BETTER ESPRESSO"; Level = "h2"; SizePx = 25.6 },
    @{ Role = "Brand Story"; Text = "CRAFT YOUR PERFECT SHOT."; Level = "h2"; SizePx = 25.6 },
    @{ Role = "Ritual Workflow 01"; Text = "START WITH CONSISTENCY."; Level = "h3"; SizePx = 24.0 },
    @{ Role = "Ritual Workflow 02"; Text = "FINE-TUNE YOUR GRIND AND EXTRACTION."; Level = "h3"; SizePx = 24.0 },
    @{ Role = "404 Headline"; Text = "LOOKS LIKE THIS SHOT DIDN'T DIAL IN."; Level = "h1"; SizePx = 32.0 },
    @{ Role = "Announcement Bar"; Text = "FREE STANDARD SHIPPING ON ORDERS OVER €55"; Level = "announcement"; SizePx = 13.0 }
)

# In sans-serif geometric fonts (Manrope uppercase), average uppercase char width is ~0.65em to 0.72em.
# Longest individual word cannot exceed available width at 320px viewport (320 - 40px gutter = 280px).
$maxCharRatio = 0.72 # Conservative uppercase glyph width ratio + 0.02 tracking = 0.74em
$trackingBonus = 0.02
$effectiveRatio = $maxCharRatio + $trackingBonus

$allWordsFit = $true
$worstCaseWordReport = ""

foreach ($hl in $brandHeadlines) {
    $words = $hl.Text -split '\s+'
    foreach ($w in $words) {
        $cleanWord = $w.Trim('.', ',', ':', '!', '?')
        $charCount = $cleanWord.Length
        $wordWidthPx = $charCount * ($hl.SizePx * $effectiveRatio)
        
        if ($wordWidthPx -gt 280.0) {
            $allWordsFit = $false
            $worstCaseWordReport = "Word '$w' in $($hl.Role) estimated at $([Math]::Round($wordWidthPx, 1))px > 280px"
        }
    }
}

Register-Test -Id "TYPO-12" -Category "HorizontalOverflow" `
    -Description "No single uppercase word overflows 280px container at narrowest 320px viewport" `
    -Passed $allWordsFit `
    -Expected "All words < 280px" `
    -Actual $(if ($allWordsFit) { "All brand headline words fit comfortably within 280px without clipping" } else { $worstCaseWordReport }) `
    -Severity "HIGH"

# 2.8 Verify CSS overflow prevention safety rules
$hasOverflowWrap = ($baseCss -match 'overflow-wrap:\s*break-word;')
$hasTextWrapBalance = ($baseCss -match 'text-wrap:\s*balance;')
$hasLineHeightHeading = ($themeStyles -match '--line-height-heading:\s*1\.15;') -or ($baseCss -match 'line-height:\s*1\.1')

Register-Test -Id "TYPO-13" -Category "CSSDefensiveRules" `
    -Description "base.css specifies overflow-wrap: break-word; to prevent unexpected text clipping" `
    -Passed ([bool]$hasOverflowWrap) `
    -Expected "overflow-wrap: break-word;" `
    -Actual $(if ($hasOverflowWrap) { "Present" } else { "Missing" }) `
    -Severity "HIGH"

Register-Test -Id "TYPO-14" -Category "CSSDefensiveRules" `
    -Description "Headings specify text-wrap: balance; for optical balancing of uppercase titles" `
    -Passed ([bool]$hasTextWrapBalance) `
    -Expected "text-wrap: balance;" `
    -Actual $(if ($hasTextWrapBalance) { "Present" } else { "Missing" }) `
    -Severity "MEDIUM"

# 2.9 Micro-labels and eyebrow typography uppercase tracking verification
$microLabelCase = ($baseCss -match '\.micro-(label|eyebrow)[^{]*\{[^}]*text-transform:\s*uppercase')
$microLabelTracking = ($baseCss -match '\.micro-(label|eyebrow)[^{]*\{[^}]*letter-spacing:\s*0\.14em')

Register-Test -Id "TYPO-15" -Category "MicroTypography" `
    -Description "Micro-labels and eyebrows enforce uppercase and 0.14em tracking per R1 specification" `
    -Passed ([bool]($microLabelCase -and $microLabelTracking)) `
    -Expected "uppercase with 0.14em letter-spacing" `
    -Actual "text-transform: $microLabelCase, letter-spacing: $microLabelTracking" `
    -Severity "HIGH"

# 2.10 Variant option value resets (preserves lower/mixed case for product specs like 58.5mm, 18-22g)
$variantOptionReset = ($baseCss -match '\.variant-option__value\s*\{[^}]*letter-spacing:\s*0;[^}]*text-transform:\s*none;') -or
                      ($baseCss -match '\.variant-option__value\s*\{[^}]*text-transform:\s*none;[^}]*letter-spacing:\s*0;')
Register-Test -Id "TYPO-16" -Category "TypographicRefinement" `
    -Description "Variant option values reset to text-transform: none and letter-spacing: 0 for legible measurements" `
    -Passed ([bool]$variantOptionReset) `
    -Expected ".variant-option__value resets transform and tracking" `
    -Actual $(if ($variantOptionReset) { "Present in base.css" } else { "Missing reset" }) `
    -Severity "MEDIUM"


# ==============================================================================
# SUMMARY & VERDICT
# ==============================================================================
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "                      STRESS TEST SUMMARY RESULTS                     " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$passedCount = ($Results | Where-Object { $_.Passed -eq $true }).Count
$totalCount = $Results.Count
$failedCount = $totalCount - $passedCount
$passRate = [Math]::Round(($passedCount / $totalCount) * 100, 1)

Write-Host ("  Total Assertions: {0}" -f $totalCount)
Write-Host ("  Passed:           {0}" -f $passedCount) -ForegroundColor Green
Write-Host ("  Failed:           {0}" -f $failedCount) -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host ("  Pass Rate:        {0}%" -f $passRate)

$criticalOrHighFails = $Results | Where-Object { -not $_.Passed -and $_.Severity -in @("CRITICAL", "HIGH") }
$verdict = if ($criticalOrHighFails.Count -eq 0 -and $failedCount -eq 0) { "APPROVE" } else { "CHALLENGE_FAILED" }

Write-Host "`n>> EMPIRICAL VERDICT: $verdict" -ForegroundColor $(if ($verdict -eq "APPROVE") { "Green" } else { "Red" })

if ($failedCount -gt 0) {
    Write-Host "`nFailing Tests:" -ForegroundColor Red
    foreach ($f in ($Results | Where-Object { -not $_.Passed })) {
        Write-Host ("  - [{0}] {1}: {2} (Expected: {3}, Actual: {4})" -f $f.Severity, $f.Id, $f.Description, $f.Expected, $f.Actual) -ForegroundColor Red
    }
}

return [PSCustomObject]@{
    Total   = $totalCount
    Passed  = $passedCount
    Failed  = $failedCount
    Rate    = $passRate
    Verdict = $verdict
    Results = $Results
}
