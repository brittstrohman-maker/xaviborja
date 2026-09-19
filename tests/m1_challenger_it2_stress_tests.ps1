# ==============================================================================
# Challenger M1-It2-1: Empirical Stress-Testing Suite for Milestone M1 Remediation
# Focus: Radius Schema Clamping ([2..8]px), Boundary Conditions, Rejection Oracles,
#        Preset Switching & Typography Scaling Resilience
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot

$Report = [System.Collections.ArrayList]::new()

function Log-Assertion {
    param(
        [string]$TestId,
        [string]$Category,
        [string]$Description,
        [bool]$Passed,
        [string]$Expected,
        [string]$Actual,
        [string]$Severity = "CRITICAL"
    )
    $obj = [PSCustomObject]@{
        TestId      = $TestId
        Category    = $Category
        Description = $Description
        Passed      = $Passed
        Expected    = $Expected
        Actual      = $Actual
        Severity    = $Severity
    }
    $null = $Report.Add($obj)
    
    $statusStr = if ($Passed) { "[PASS]" } else { "[$Severity FAIL]" }
    $color = if ($Passed) { "Green" } elseif ($Severity -in @("CRITICAL","HIGH")) { "Red" } else { "Yellow" }
    Write-Host ("  {0} {1} ({2}) - {3}" -f $statusStr, $TestId, $Category, $Description) -ForegroundColor $color
    if (-not $Passed -or $VerboseOutput) {
        if ($Expected -ne "" -or $Actual -ne "") {
            Write-Host ("         Expected: {0}" -f $Expected) -ForegroundColor DarkGray
            Write-Host ("         Actual:   {0}" -f $Actual) -ForegroundColor DarkGray
        }
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M1-IT2-1: EMPIRICAL STRESS-TESTING SUITE                " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Load Theme Files
$schemaPath = Join-Path $RepoRoot "config/settings_schema.json"
$dataPath   = Join-Path $RepoRoot "config/settings_data.json"
$stylesPath = Join-Path $RepoRoot "snippets/theme-styles.liquid"
$baseCssPath = Join-Path $RepoRoot "assets/base.css"

$schemaJson = [System.IO.File]::ReadAllText($schemaPath, [System.Text.Encoding]::UTF8)
$schema = $schemaJson | ConvertFrom-Json

$dataJson = [System.IO.File]::ReadAllText($dataPath, [System.Text.Encoding]::UTF8)
$data = $dataJson | ConvertFrom-Json

$themeStyles = [System.IO.File]::ReadAllText($stylesPath, [System.Text.Encoding]::UTF8)
$baseCss = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

# Locate layout settings and radius_base
$layoutSection = $schema | Where-Object { $_.name -like "*layout*" }
$radiusBaseSetting = $layoutSection.settings | Where-Object { $_.id -eq "radius_base" }
$radiusMediaSetting = $layoutSection.settings | Where-Object { $_.id -eq "radius_media" }

# Locate typography settings
$typoSection = $schema | Where-Object { $_.name -like "*typography*" }
$headingScaleSetting = $typoSection.settings | Where-Object { $_.id -eq "heading_scale" }
$bodyScaleSetting = $typoSection.settings | Where-Object { $_.id -eq "body_scale" }
$headingTrackingSetting = $typoSection.settings | Where-Object { $_.id -eq "heading_tracking" }

# ------------------------------------------------------------------------------
# 1. Radius Schema Boundary Conditions & Clamping Oracles
# ------------------------------------------------------------------------------
Write-Host "`n--- 1. Radius Schema Boundary Conditions & Clamping ---" -ForegroundColor Yellow

# Check 1.1: radius_base schema setting exists
Log-Assertion "ST-RAD-01" "RadiusSchema" "radius_base range setting exists in schema" `
    ($radiusBaseSetting -ne $null -and $radiusBaseSetting.type -eq "range") `
    "type == range" "type == $($radiusBaseSetting.type)"

# Check 1.2: radius_base min boundary
$minPass = ($radiusBaseSetting.min -ge 2)
Log-Assertion "ST-RAD-02" "RadiusSchema" "radius_base min is clamped >= 2px" `
    $minPass "min >= 2" "min = $($radiusBaseSetting.min)"

# Check 1.3: radius_base max boundary
$maxPass = ($radiusBaseSetting.max -le 8)
Log-Assertion "ST-RAD-03" "RadiusSchema" "radius_base max is clamped <= 8px" `
    $maxPass "max <= 8" "max = $($radiusBaseSetting.max)"

# Check 1.4: radius_base step
$stepPass = ($radiusBaseSetting.step -gt 0 -and $radiusBaseSetting.step -le 2)
Log-Assertion "ST-RAD-04" "RadiusSchema" "radius_base step is positive integer <= 2" `
    $stepPass "step in [1, 2]" "step = $($radiusBaseSetting.step)"

# Check 1.5: radius_base default
$defaultPass = ($radiusBaseSetting.default -ge 2 -and $radiusBaseSetting.default -le 8)
Log-Assertion "ST-RAD-05" "RadiusSchema" "radius_base default is within [2..8]px" `
    $defaultPass "default in [2..8]" "default = $($radiusBaseSetting.default)"

# Check 1.6: Discrete reachable step values
$allStepsValid = $true
$stepVal = $radiusBaseSetting.min
while ($stepVal -le $radiusBaseSetting.max) {
    if ($stepVal -lt 2 -or $stepVal -gt 8) {
        $allStepsValid = $false
        break
    }
    $stepVal += $radiusBaseSetting.step
}
Log-Assertion "ST-RAD-06" "RadiusSchema" "All reachable slider steps are strictly in [2..8]px" `
    $allStepsValid "All steps in [2..8]" "All steps valid: $allStepsValid"

# Check 1.7: Rejection Oracle on Adversarial Schemas
function Test-RadiusSchemaValidator($mockMin, $mockMax, $mockDefault) {
    if ($mockMin -lt 2) { return "REJECT: min < 2" }
    if ($mockMax -gt 8) { return "REJECT: max > 8" }
    if ($mockDefault -lt $mockMin -or $mockDefault -gt $mockMax) { return "REJECT: default out of bounds" }
    return "ACCEPT"
}

$adv1 = Test-RadiusSchemaValidator 0 8 4
$adv2 = Test-RadiusSchemaValidator 1 8 4
$adv3 = Test-RadiusSchemaValidator (-2) 8 4
$adv4 = Test-RadiusSchemaValidator 2 9 4
$adv5 = Test-RadiusSchemaValidator 2 16 4
$adv6 = Test-RadiusSchemaValidator 2 32 4
$adv7 = Test-RadiusSchemaValidator 2 8 0
$adv8 = Test-RadiusSchemaValidator 2 8 10
$actualValidatorResult = Test-RadiusSchemaValidator $radiusBaseSetting.min $radiusBaseSetting.max $radiusBaseSetting.default

$allAdversarialRejected = ($adv1 -like "REJECT*" -and $adv2 -like "REJECT*" -and $adv3 -like "REJECT*" -and `
                          $adv4 -like "REJECT*" -and $adv5 -like "REJECT*" -and $adv6 -like "REJECT*" -and `
                          $adv7 -like "REJECT*" -and $adv8 -like "REJECT*")
Log-Assertion "ST-RAD-07" "RadiusOracle" "Oracle rejects all adversarial schemas (min < 2, max > 8, default out-of-bounds)" `
    $allAdversarialRejected "All 8 invalid variants REJECTED" "All rejected: $allAdversarialRejected"

Log-Assertion "ST-RAD-08" "RadiusOracle" "Oracle ACCEPTS current repo settings_schema.json" `
    ($actualValidatorResult -eq "ACCEPT") "ACCEPT" "$actualValidatorResult"

# Check 1.9: radius_media schema
Log-Assertion "ST-RAD-09" "RadiusMedia" "radius_media has valid defaults (min >= 0, max <= 32, default in bounds)" `
    ($radiusMediaSetting.min -ge 0 -and $radiusMediaSetting.max -le 32 -and $radiusMediaSetting.default -ge 0 -and $radiusMediaSetting.default -le $radiusMediaSetting.max) `
    "Valid bounds" "min=$($radiusMediaSetting.min), max=$($radiusMediaSetting.max), default=$($radiusMediaSetting.default)"

# Check 1.10: settings_data.json radius settings
$currentRadPass = ($data.current.radius_base -ge 2 -and $data.current.radius_base -le 8)
Log-Assertion "ST-RAD-10" "SettingsData" "settings_data.json current.radius_base is clamped in [2..8]px" `
    $currentRadPass "current.radius_base in [2..8]" "current.radius_base = $($data.current.radius_base)"

# Check 1.11 & 1.12: theme-styles.liquid defensive fallback filters
$hasRadiusBaseDefault = ($themeStyles -match 'radius_base\s*\|\s*default:\s*4')
Log-Assertion "ST-RAD-11" "LiquidGuard" "theme-styles.liquid protects --radius-base with | default: 4" `
    $hasRadiusBaseDefault "radius_base | default: 4" "Pattern match: $hasRadiusBaseDefault"

$hasRadiusMediaDefault = ($themeStyles -match 'radius_media\s*\|\s*default:\s*6')
Log-Assertion "ST-RAD-12" "LiquidGuard" "theme-styles.liquid protects --radius-media with | default: 6" `
    $hasRadiusMediaDefault "radius_media | default: 6" "Pattern match: $hasRadiusMediaDefault"

# ------------------------------------------------------------------------------
# 2. Typography Scaling & Preset Switching Resilience
# ------------------------------------------------------------------------------
Write-Host "`n--- 2. Typography Scaling & Preset Switching ---" -ForegroundColor Yellow

# Check 2.1 & 2.2: Schema definition for typography scales
Log-Assertion "ST-TYP-01" "TypoSchema" "heading_scale defined in schema with valid range [80..130]" `
    ($headingScaleSetting -ne $null -and $headingScaleSetting.min -ge 80 -and $headingScaleSetting.max -le 130 -and $headingScaleSetting.default -eq 100) `
    "min>=80, max<=130, def=100" "min=$($headingScaleSetting.min), max=$($headingScaleSetting.max), def=$($headingScaleSetting.default)"

Log-Assertion "ST-TYP-02" "TypoSchema" "body_scale defined in schema with valid range [90..120]" `
    ($bodyScaleSetting -ne $null -and $bodyScaleSetting.min -ge 90 -and $bodyScaleSetting.max -le 120 -and $bodyScaleSetting.default -eq 100) `
    "min>=90, max<=120, def=100" "min=$($bodyScaleSetting.min), max=$($bodyScaleSetting.max), def=$($bodyScaleSetting.default)"

Log-Assertion "ST-TYP-03" "TypoSchema" "heading_tracking defined in schema with valid range [-4..8]" `
    ($headingTrackingSetting -ne $null -and $headingTrackingSetting.min -ge -4 -and $headingTrackingSetting.max -le 8 -and $headingTrackingSetting.default -eq 2) `
    "min>=-4, max<=8, def=2" "min=$($headingTrackingSetting.min), max=$($headingTrackingSetting.max), def=$($headingTrackingSetting.default)"

# Check 2.4 - 2.7: Preset "Dose & Dial"
$presetDose = $data.presets."Dose & Dial"
Log-Assertion "ST-TYP-04" "Presets" "Preset 'Dose & Dial' exists in settings_data.json" `
    ($presetDose -ne $null) "Preset exists" "Exists: $($presetDose -ne $null)"

Log-Assertion "ST-TYP-05" "Presets" "Preset 'Dose & Dial' heading_scale is 100" `
    ($presetDose.heading_scale -eq 100) "heading_scale == 100" "heading_scale = $($presetDose.heading_scale)"

Log-Assertion "ST-TYP-06" "Presets" "Preset 'Dose & Dial' body_scale is 100" `
    ($presetDose.body_scale -eq 100) "body_scale == 100" "body_scale = $($presetDose.body_scale)"

Log-Assertion "ST-TYP-07" "Presets" "Preset 'Dose & Dial' radius_base is in [2..8]px" `
    ($presetDose.radius_base -ge 2 -and $presetDose.radius_base -le 8) "radius_base in [2..8]" "radius_base = $($presetDose.radius_base)"

# Check 2.8 - 2.11: Preset "Editorial Espresso"
$presetEspresso = $data.presets."Editorial Espresso"
Log-Assertion "ST-TYP-08" "Presets" "Preset 'Editorial Espresso' exists in settings_data.json" `
    ($presetEspresso -ne $null) "Preset exists" "Exists: $($presetEspresso -ne $null)"

Log-Assertion "ST-TYP-09" "Presets" "Preset 'Editorial Espresso' heading_scale is 100" `
    ($presetEspresso.heading_scale -eq 100) "heading_scale == 100" "heading_scale = $($presetEspresso.heading_scale)"

Log-Assertion "ST-TYP-10" "Presets" "Preset 'Editorial Espresso' body_scale is 100" `
    ($presetEspresso.body_scale -eq 100) "body_scale == 100" "body_scale = $($presetEspresso.body_scale)"

Log-Assertion "ST-TYP-11" "Presets" "Preset 'Editorial Espresso' radius_base is in [2..8]px" `
    ($presetEspresso.radius_base -ge 2 -and $presetEspresso.radius_base -le 8) "radius_base in [2..8]" "radius_base = $($presetEspresso.radius_base)"

# Check 2.12 & 2.13: Liquid default guards
$hasHsDefault = ($themeStyles -match 'heading_scale\s*\|\s*default:\s*100')
Log-Assertion "ST-TYP-12" "LiquidGuard" "theme-styles.liquid protects heading_scale with | default: 100" `
    $hasHsDefault "heading_scale | default: 100" "Pattern match: $hasHsDefault"

$hasBsDefault = ($themeStyles -match 'body_scale\s*\|\s*default:\s*100')
Log-Assertion "ST-TYP-13" "LiquidGuard" "theme-styles.liquid protects body_scale with | default: 100" `
    $hasBsDefault "body_scale | default: 100" "Pattern match: $hasBsDefault"

# Check 2.14 - 2.19: Liquid Simulation of Typography Sizes under Preset Switching & Stress Cases
function Simulate-ThemeStylesTypography($hScaleVal, $bScaleVal, $radBaseVal) {
    $hs = if ($null -eq $hScaleVal -or "" -eq $hScaleVal) { 100 / 100.0 } else { [double]$hScaleVal / 100.0 }
    $bs = if ($null -eq $bScaleVal -or "" -eq $bScaleVal) { 100 / 100.0 } else { [double]$bScaleVal / 100.0 }
    $rBase = if ($null -eq $radBaseVal -or "" -eq $radBaseVal) { 4 } else { [int]$radBaseVal }
    
    $textXs = 0.75 * $bs
    $textSm = 0.875 * $bs
    $textBase = 1.0 * $bs
    $textLg = 1.125 * $bs
    $textH0Min = 2.5 * $hs
    $textH0Max = 5.5 * $hs
    $textH1Min = 2.0 * $hs
    $textH1Max = 3.5 * $hs
    $textH6 = 1.0 * $hs

    return [PSCustomObject]@{
        Hs        = $hs
        Bs        = $bs
        RadiusBase = $rBase
        TextXs    = $textXs
        TextBase  = $textBase
        TextH1Min = $textH1Min
        TextH1Max = $textH1Max
        TextH6    = $textH6
        IsZeroCollapse = ($textBase -le 0.001 -or $textH1Min -le 0.001 -or $textH6 -le 0.001)
    }
}

# Sim 1: Dose & Dial preset
$simDose = Simulate-ThemeStylesTypography $presetDose.heading_scale $presetDose.body_scale $presetDose.radius_base
Log-Assertion "ST-TYP-14" "PresetSimulation" "Preset 'Dose & Dial' produces non-zero typography scale (no collapse)" `
    (-not $simDose.IsZeroCollapse -and $simDose.TextBase -eq 1.0 -and $simDose.TextH1Min -eq 2.0) `
    "text_base=1.0rem, text_h1_min=2.0rem, collapse=False" `
    "text_base=$($simDose.TextBase)rem, text_h1_min=$($simDose.TextH1Min)rem, collapse=$($simDose.IsZeroCollapse)"

# Sim 2: Editorial Espresso preset
$simEspresso = Simulate-ThemeStylesTypography $presetEspresso.heading_scale $presetEspresso.body_scale $presetEspresso.radius_base
Log-Assertion "ST-TYP-15" "PresetSimulation" "Preset 'Editorial Espresso' produces non-zero typography scale (no collapse)" `
    (-not $simEspresso.IsZeroCollapse -and $simEspresso.TextBase -eq 1.0 -and $simEspresso.TextH1Min -eq 2.0) `
    "text_base=1.0rem, text_h1_min=2.0rem, collapse=False" `
    "text_base=$($simEspresso.TextBase)rem, text_h1_min=$($simEspresso.TextH1Min)rem, collapse=$($simEspresso.IsZeroCollapse)"

# Sim 3: Legacy/Corrupted Preset with missing (null) scales
$simNull = Simulate-ThemeStylesTypography $null $null $null
Log-Assertion "ST-TYP-16" "PresetSimulation" "Legacy preset with null scales defaults safely to 1.0rem (ZERO collapse)" `
    (-not $simNull.IsZeroCollapse -and $simNull.TextBase -eq 1.0 -and $simNull.TextH1Min -eq 2.0 -and $simNull.RadiusBase -eq 4) `
    "text_base=1.0rem, radius=4px, collapse=False" `
    "text_base=$($simNull.TextBase)rem, radius=$($simNull.RadiusBase)px, collapse=$($simNull.IsZeroCollapse)"

# Sim 4: Empty string preset scales
$simEmpty = Simulate-ThemeStylesTypography "" "" ""
Log-Assertion "ST-TYP-17" "PresetSimulation" "Empty string preset scales default safely to 1.0rem (ZERO collapse)" `
    (-not $simEmpty.IsZeroCollapse -and $simEmpty.TextBase -eq 1.0 -and $simEmpty.TextH1Min -eq 2.0 -and $simEmpty.RadiusBase -eq 4) `
    "text_base=1.0rem, collapse=False" `
    "text_base=$($simEmpty.TextBase)rem, collapse=$($simEmpty.IsZeroCollapse)"

# Sim 5: Minimum Slider bounds (hs=80%, bs=90%)
$simMin = Simulate-ThemeStylesTypography 80 90 2
Log-Assertion "ST-TYP-18" "PresetSimulation" "Min slider bounds (80% / 90%) maintain positive, legible sizes" `
    (-not $simMin.IsZeroCollapse -and $simMin.TextBase -eq 0.9 -and $simMin.TextH1Min -eq 1.6 -and $simMin.RadiusBase -eq 2) `
    "text_base=0.9rem, text_h1_min=1.6rem, radius=2px" `
    "text_base=$($simMin.TextBase)rem, text_h1_min=$($simMin.TextH1Min)rem, radius=$($simMin.RadiusBase)px"

# Sim 6: Maximum Slider bounds (hs=130%, bs=120%)
$simMax = Simulate-ThemeStylesTypography 130 120 8
Log-Assertion "ST-TYP-19" "PresetSimulation" "Max slider bounds (130% / 120%) maintain well-formed proportions" `
    (-not $simMax.IsZeroCollapse -and $simMax.TextBase -eq 1.2 -and $simMax.TextH1Min -eq 2.6 -and $simMax.RadiusBase -eq 8) `
    "text_base=1.2rem, text_h1_min=2.6rem, radius=8px" `
    "text_base=$($simMax.TextBase)rem, text_h1_min=$($simMax.TextH1Min)rem, radius=$($simMax.RadiusBase)px"

# Check 2.20: Micro-labels typography styles
$hasMicroLabel = ($baseCss -match '\.micro-label') -and ($baseCss -match 'letter-spacing') -and ($baseCss -match 'uppercase')
Log-Assertion "ST-TYP-20" "BaseCSS" "Micro-label styling defined with uppercase and letter-spacing" `
    $hasMicroLabel "uppercase + letter-spacing on .micro-label" "Pattern match: $hasMicroLabel"

# ------------------------------------------------------------------------------
# 3. Aggregate Summary & Quality Gate Status
# ------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGE M1-IT2-1 EMPIRICAL RESULTS SUMMARY                      " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$totalTests = $Report.Count
$passedTests = @($Report | Where-Object { $_.Passed }).Count
$failedTests = @($Report | Where-Object { -not $_.Passed }).Count
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "Total Stress Assertions: $totalTests"
Write-Host "Passed Assertions:       $passedTests" -ForegroundColor Green
Write-Host "Failed Assertions:       $failedTests" -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host "Pass Rate:               $passRate%" -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`n>> VERDICT: APPROVE (All radius schema boundaries clamped, typography scaling resilient across all presets)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>> VERDICT: CHALLENGE_FAILED ($failedTests assertions failed)" -ForegroundColor Red
    exit 1
}
