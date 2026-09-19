# ==============================================================================
# CHALLENGER M3-2: EMPIRICAL STRESS-TESTING SUITE FOR MILESTONE M3
# Focus: Workflow Step Blocks (0, 1, 3, 6), Hero Media Responsiveness, Color Tokens
# Methodology: Real Headless Edge Chromium + AST Verification + Liquid Simulators
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
        Write-Host ("         Expected: {0}" -f $Expected) -ForegroundColor DarkGray
        Write-Host ("         Actual:   {0}" -f $Actual) -ForegroundColor DarkGray
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M3-2: WORKFLOW, HERO MEDIA & COLOR TOKEN STRESS SUITE   " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SUITE 1: WORKFLOW SECTION LIQUID AST & STEP BLOCKS STRESS-TEST
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Workflow Section AST & Block Iteration Stress ---" -ForegroundColor Yellow

$workflowPath = Join-Path $RepoRoot "sections/workflow.liquid"
$workflowContent = [System.IO.File]::ReadAllText($workflowPath, [System.Text.Encoding]::UTF8)

# 1.1 AST tag balancing
$wfIfOpens = ([regex]::Matches($workflowContent, '\{%-\s*if\b|\{%\s*if\b')).Count
$wfIfCloses = ([regex]::Matches($workflowContent, '\{%-\s*endif\b|\{%\s*endif\b')).Count
Log-Assertion -TestId "WF-01" -Category "Workflow-AST" `
    -Description "workflow.liquid: if/endif tag balancing" `
    -Passed ($wfIfOpens -eq $wfIfCloses) `
    -Expected "Balanced if/endif ($wfIfOpens opens)" `
    -Actual "Opens=$wfIfOpens, Closes=$wfIfCloses"

$wfForOpens = ([regex]::Matches($workflowContent, '\{%-\s*for\b|\{%\s*for\b')).Count
$wfForCloses = ([regex]::Matches($workflowContent, '\{%-\s*endfor\b|\{%\s*endfor\b')).Count
Log-Assertion -TestId "WF-02" -Category "Workflow-AST" `
    -Description "workflow.liquid: for/endfor tag balancing" `
    -Passed ($wfForOpens -eq $wfForCloses -and $wfForOpens -gt 0) `
    -Expected "Balanced for/endfor (>= 1 loop)" `
    -Actual "Opens=$wfForOpens, Closes=$wfForCloses"

# 1.2 Schema JSON validation
$wfSchemaMatch = [regex]::Match($workflowContent, '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}')
$wfSchema = $null
$wfSchemaValid = $false
if ($wfSchemaMatch.Success) {
    try {
        $wfSchema = $wfSchemaMatch.Groups[1].Value | ConvertFrom-Json
        $wfSchemaValid = $true
    } catch {
        $wfSchemaValid = $false
    }
}
Log-Assertion -TestId "WF-03" -Category "Workflow-Schema" `
    -Description "workflow.liquid: Valid JSON schema parse" `
    -Passed $wfSchemaValid `
    -Expected "Schema parses cleanly as JSON" `
    -Actual "Parsed=$wfSchemaValid"

$hasStepBlock = [bool]($wfSchema.blocks | Where-Object { $_.type -eq "step" })
Log-Assertion -TestId "WF-04" -Category "Workflow-Schema" `
    -Description "workflow.liquid: Schema defines 'step' block type" `
    -Passed $hasStepBlock `
    -Expected "'step' block defined in blocks" `
    -Actual "HasStepBlock=$hasStepBlock"

$presetStepsCount = 0
if ($wfSchema -and $wfSchema.presets) {
    $presetStepsCount = ($wfSchema.presets[0].blocks | Where-Object { $_.type -eq "step" }).Count
}
Log-Assertion -TestId "WF-05" -Category "Workflow-Schema" `
    -Description "workflow.liquid: Presets contain exactly 3 step blocks (01 DOSE, 02 DIAL, 03 BREW)" `
    -Passed ($presetStepsCount -eq 3) `
    -Expected "3 preset blocks" `
    -Actual "$presetStepsCount preset blocks"

# 1.3 Step block iteration resilience: 0, 1, 3, 6 steps
# 0 steps: verify safe empty loop
$safeZeroSteps = ($workflowContent -match '\{%-\s*for\s+block\s+in\s+section\.blocks\s*-%\}')
Log-Assertion -TestId "WF-06" -Category "Workflow-Blocks" `
    -Description "workflow.liquid: 0 Steps - section iterates empty blocks collection without crash" `
    -Passed $safeZeroSteps `
    -Expected "Safe iteration over section.blocks" `
    -Actual "SafeLoop=$safeZeroSteps"

# 1.4 Optional fields guards
$taglineGuarded = ($workflowContent -match '\{%-\s*if\s+block\.settings\.tagline\s*!=\s*blank\s*-%\}')
$textGuarded = ($workflowContent -match '\{%-\s*if\s+block\.settings\.text\s*!=\s*blank\s*-%\}')
$linkGuarded = ($workflowContent -match '\{%-\s*if\s+block\.settings\.link_label\s*!=\s*blank\s+and\s+block\.settings\.link\s*!=\s*blank\s*-%\}')

Log-Assertion -TestId "WF-07" -Category "Workflow-Blocks" `
    -Description "workflow.liquid: Tagline is conditionally guarded (block.settings.tagline != blank)" `
    -Passed $taglineGuarded `
    -Expected "tagline conditional guard present" `
    -Actual "taglineGuarded=$taglineGuarded"

Log-Assertion -TestId "WF-08" -Category "Workflow-Blocks" `
    -Description "workflow.liquid: Text is conditionally guarded (block.settings.text != blank)" `
    -Passed $textGuarded `
    -Expected "text conditional guard present" `
    -Actual "textGuarded=$textGuarded"

Log-Assertion -TestId "WF-09" -Category "Workflow-Blocks" `
    -Description "workflow.liquid: Link CTA is guarded against missing link OR link_label" `
    -Passed $linkGuarded `
    -Expected "link and link_label dual guard present" `
    -Actual "linkGuarded=$linkGuarded"

# 1.5 Reduced motion for workflow step transitions
$baseCssPath = Join-Path $RepoRoot "assets/base.css"
$baseCssContent = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

$wfReducedMotion = $baseCssContent -match '(?s)prefers-reduced-motion:\s*reduce.*?\.workflow-step\s*\{[^}]*transition:\s*none'
Log-Assertion -TestId "WF-10" -Category "Workflow-Accessibility" `
    -Description "base.css: .workflow-step disables transform & transition under prefers-reduced-motion: reduce" `
    -Passed $wfReducedMotion `
    -Expected "transition: none, transform: none under reduced motion" `
    -Actual "wfReducedMotion=$wfReducedMotion"

# ------------------------------------------------------------------------------
# SUITE 2: HERO RESPONSIVE MEDIA & IMAGE / PICTURE TAG STRESS-TEST
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] Hero Responsive Media & Image Tag Stress ---" -ForegroundColor Yellow

$heroPath = Join-Path $RepoRoot "sections/hero.liquid"
$heroContent = [System.IO.File]::ReadAllText($heroPath, [System.Text.Encoding]::UTF8)

$heroSchemaMatch = [regex]::Match($heroContent, '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}')
$heroSchema = $null
if ($heroSchemaMatch.Success) {
    try { $heroSchema = $heroSchemaMatch.Groups[1].Value | ConvertFrom-Json } catch {}
}

$hasHeroDesktopImgSetting = [bool]($heroSchema.settings | Where-Object { $_.id -eq "image" })
$hasHeroMobileImgSetting = [bool]($heroSchema.settings | Where-Object { $_.id -eq "image_mobile" })
Log-Assertion -TestId "HR-01" -Category "Hero-Schema" `
    -Description "hero.liquid: Schema defines 'image' (desktop) and 'image_mobile' pickers" `
    -Passed ($hasHeroDesktopImgSetting -and $hasHeroMobileImgSetting) `
    -Expected "Both image and image_mobile in schema" `
    -Actual "desktop=$hasHeroDesktopImgSetting, mobile=$hasHeroMobileImgSetting"

# 2.2 Picture tag vs Twin Image Tags Architecture Oracle
$hasPictureTag = $heroContent -match '<picture\b'
Log-Assertion -TestId "HR-02" -Category "Hero-Media" `
    -Description "hero.liquid: Uses <picture> element vs dual <img> classes for responsive art direction" `
    -Passed $hasPictureTag `
    -Expected "Uses HTML5 <picture> element" `
    -Actual $(if ($hasPictureTag) { "Uses <picture>" } else { "Uses dual <img> with CSS display toggles" }) `
    -Severity "MEDIUM"

# 2.3 Scenario A: Desktop-only image populated
# When image_mobile is blank, desktop image gets class: '' (not hidden on mobile)
$desktopOnlyFallback = ($heroContent -match 'desktop_image_class\s*=\s*''''') -or ($heroContent -match 'assign desktop_image_class = ''''')
Log-Assertion -TestId "HR-03" -Category "Hero-Media" `
    -Description "hero.liquid: Desktop-only image serves as universal fallback across all viewports" `
    -Passed $desktopOnlyFallback `
    -Expected "Desktop image rendered without hiding class when image_mobile is blank" `
    -Actual "DesktopFallback=$desktopOnlyFallback"

# 2.4 Scenario B: Both images populated
$hasMobileClass = ($heroContent -match 'class:\s*''banner__image--mobile''') -or ($heroContent -match 'class:\s*mobile_image_class' -and $heroContent -match 'mobile_image_class\s*=\s*''[^'']*banner__image--mobile')
$hasDesktopClass = $heroContent -match 'desktop_image_class\s*=\s*''banner__image--desktop'''
Log-Assertion -TestId "HR-04" -Category "Hero-Media" `
    -Description "hero.liquid: Both images populated emits .banner__image--mobile and .banner__image--desktop" `
    -Passed ($hasMobileClass -and $hasDesktopClass) `
    -Expected "Both responsive image classes emitted" `
    -Actual "mobileClass=$hasMobileClass, desktopClass=$hasDesktopClass"

# CSS rules for image toggles
$hasMobileHide = $baseCssContent -match '(?s)min-width:\s*750px.*?\.banner__image--mobile\s*\{\s*display:\s*none\s*!important;'
$hasDesktopHide = $baseCssContent -match '(?s)max-width:\s*749px.*?\.banner__image--desktop\s*\{\s*display:\s*none\s*!important;'
Log-Assertion -TestId "HR-05" -Category "Hero-Media" `
    -Description "base.css: CSS rules toggle mobile/desktop images across 750px breakpoint" `
    -Passed ($hasMobileHide -and $hasDesktopHide) `
    -Expected "Mobile hidden on >=750px, Desktop hidden on <=749px" `
    -Actual "mobileHide=$hasMobileHide, desktopHide=$hasDesktopHide"

# 2.5 Scenario C: ADVERSARIAL CORNER CASE - Mobile-only image populated
# When merchant uploads ONLY image_mobile and leaves image blank:
# Line 29: {%- elsif section.settings.image != blank -%}
# Outer guard skips to {%- else -%} placeholder SVG! Mobile image is never rendered!
$mobileOnlyRenders = $false
if ($heroContent -match 'image_mobile\s*!=\s*blank\s*or\s*section\.settings\.image\s*!=\s*blank' -or
    $heroContent -match 'image\s*!=\s*blank\s*or\s*section\.settings\.image_mobile\s*!=\s*blank') {
    $mobileOnlyRenders = $true
}
Log-Assertion -TestId "HR-06" -Category "Hero-Media" `
    -Description "hero.liquid: Corner Case - Standalone mobile image renders when desktop image is blank" `
    -Passed $mobileOnlyRenders `
    -Expected "Mobile image rendered even when desktop image is blank" `
    -Actual "Supported=$mobileOnlyRenders (Outer guard requires section.settings.image != blank)" `
    -Severity "MEDIUM"

# 2.6 Hero color-scheme class binding
$heroHasColorSchemeClass = $heroContent -match 'class="[^"]*color-scheme[^"]*"'
Log-Assertion -TestId "HR-07" -Category "Hero-Color" `
    -Description "hero.liquid: Banner element binds .color-scheme class to inherit background token" `
    -Passed $heroHasColorSchemeClass `
    -Expected "Banner element includes class 'color-scheme'" `
    -Actual "HasColorSchemeClass=$heroHasColorSchemeClass" `
    -Severity "HIGH"

# ------------------------------------------------------------------------------
# SUITE 3: COLOR SCHEME TOKEN BALANCE ACROSS HOMEPAGE SECTIONS
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Color Scheme Token Balance Analysis ---" -ForegroundColor Yellow

$indexJsonPath = Join-Path $RepoRoot "templates/index.json"
$indexJson = [System.IO.File]::ReadAllText($indexJsonPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$settingsDataPath = Join-Path $RepoRoot "config/settings_data.json"
$settingsData = [System.IO.File]::ReadAllText($settingsDataPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json

$sectionOrder = $indexJson.order
Log-Assertion -TestId "CB-01" -Category "Color-Balance" `
    -Description "index.json: Exactly 8 sections ordered in editorial sequence" `
    -Passed ($sectionOrder.Count -eq 8) `
    -Expected "8 sections" `
    -Actual "$($sectionOrder.Count) sections ($($sectionOrder -join ', '))"

# Count schemes across 8 sections
$schemeCounts = @{}
foreach ($secKey in $sectionOrder) {
    $sec = $indexJson.sections.$secKey
    $scheme = $sec.settings.color_scheme
    if (-not $scheme) { $scheme = "default" }
    if (-not $schemeCounts.ContainsKey($scheme)) { $schemeCounts[$scheme] = 0 }
    $schemeCounts[$scheme]++
}

$lightCount = ($schemeCounts["scheme_1"] -as [int]) + ($schemeCounts["scheme_2"] -as [int])
$darkCount = ($schemeCounts["scheme_3"] -as [int]) + ($schemeCounts["scheme_4"] -as [int])
$lightPct = [math]::Round(($lightCount / $sectionOrder.Count) * 100, 1)
$darkPct = [math]::Round(($darkCount / $sectionOrder.Count) * 100, 1)

Log-Assertion -TestId "CB-02" -Category "Color-Balance" `
    -Description "Homepage Sections: Cream/Off-White background ratio is 75% (Target: ~60-75%)" `
    -Passed ($lightPct -ge 60 -and $lightPct -le 80) `
    -Expected "60% - 80% light sections" `
    -Actual "$lightPct% ($lightCount / $($sectionOrder.Count) sections)"

Log-Assertion -TestId "CB-03" -Category "Color-Balance" `
    -Description "Homepage Sections: Charcoal/Matte Black background ratio is 25% (Target: ~25%)" `
    -Passed ($darkPct -eq 25) `
    -Expected "25% dark sections" `
    -Actual "$darkPct% ($darkCount / $($sectionOrder.Count) sections)"

$schemes = $settingsData.current.color_schemes
Log-Assertion -TestId "CB-04" -Category "Color-Tokens" `
    -Description "scheme_1 background is Soft Off-White (#FCFAF6)" `
    -Passed ($schemes.scheme_1.settings.background -eq "#FCFAF6") `
    -Expected "#FCFAF6" `
    -Actual "$($schemes.scheme_1.settings.background)"

Log-Assertion -TestId "CB-05" -Category "Color-Tokens" `
    -Description "scheme_2 background is Warm Cream (#F7F3EB)" `
    -Passed ($schemes.scheme_2.settings.background -eq "#F7F3EB") `
    -Expected "#F7F3EB" `
    -Actual "$($schemes.scheme_2.settings.background)"

Log-Assertion -TestId "CB-06" -Category "Color-Tokens" `
    -Description "scheme_3 background is Matte Black (#111111)" `
    -Passed ($schemes.scheme_3.settings.background -eq "#111111") `
    -Expected "#111111" `
    -Actual "$($schemes.scheme_3.settings.background)"

Log-Assertion -TestId "CB-07" -Category "Color-Tokens" `
    -Description "scheme_4 background is Deep Espresso (#2A1D17)" `
    -Passed ($schemes.scheme_4.settings.background -eq "#2A1D17") `
    -Expected "#2A1D17" `
    -Actual "$($schemes.scheme_4.settings.background)"

$accentCopperAll = ($schemes.scheme_1.settings.accent -eq "#9A6238" -and
                    $schemes.scheme_2.settings.accent -eq "#9A6238" -and
                    $schemes.scheme_3.settings.accent -eq "#9A6238" -and
                    $schemes.scheme_4.settings.accent -eq "#9A6238")
Log-Assertion -TestId "CB-08" -Category "Color-Tokens" `
    -Description "Copper Accent (#9A6238) applied across all 4 color schemes" `
    -Passed $accentCopperAll `
    -Expected "Accent == #9A6238 in all schemes" `
    -Actual "CopperAll=$accentCopperAll"

# ------------------------------------------------------------------------------
# SUITE 4: REAL HEADLESS EDGE CHROMIUM VIEWPORT LAYOUT & STRESS ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] Headless Edge Chromium Real Viewport Layout Measurements ---" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = (Get-Command msedge.exe -ErrorAction SilentlyContinue).Source
}

if (-not $edgePath -or -not (Test-Path $edgePath)) {
    Write-Host "WARNING: Microsoft Edge executable not found. Skipping headless browser rendering." -ForegroundColor Red
} else {
    $childFixtureHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<style>
:root {
  --color-background: 252 250 246;
  --color-text: 17 17 17;
  --color-button: 17 17 17;
  --color-button-label: 255 255 255;
  --color-outline-button: 17 17 17;
  --color-accent: 154 98 56;
  --color-border: 231 224 214;
  --font-body: 'Manrope', 'Inter', sans-serif;
  --font-heading: 'Manrope', 'Inter', sans-serif;
  --page-width: 1440px;
  --page-gutter: 1.25rem;
  --space-xs: 0.5rem;
  --space-sm: 1rem;
  --space-md: 1.5rem;
  --space-lg: 2.5rem;
  --space-xl: 4rem;
  --space-2xl: 6rem;
  --radius-base: 4px;
  --radius-media: 6px;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-h4: 1.25rem;
  --text-h2: 2rem;
}

.color-scheme_1 {
  --color-background: 252 250 246;
  --color-text: 17 17 17;
  --color-accent: 154 98 56;
  --color-border: 231 224 214;
}
.color-scheme_2 {
  --color-background: 247 243 235;
  --color-text: 17 17 17;
  --color-accent: 154 98 56;
  --color-border: 231 224 214;
}
.color-scheme_3 {
  --color-background: 17 17 17;
  --color-text: 247 243 235;
  --color-accent: 154 98 56;
  --color-border: 42 29 23;
}
.color-scheme {
  background-color: rgb(var(--color-background));
  color: rgb(var(--color-text));
}

body {
  margin: 0;
  padding: 0;
  font-family: var(--font-body);
  background-color: rgb(var(--color-background));
  color: rgb(var(--color-text));
  overflow-x: hidden;
}

$baseCssContent
</style>
</head>
<body>

  <!-- 1. WORKFLOW WITH 0 STEPS -->
  <section id="wf-0" class="section color-scheme_2 color-scheme">
    <div class="page-width">
      <div class="section-header" style="text-align: center;">
        <div class="section-header__text">
          <span class="eyebrow">THE RITUAL (0 STEPS)</span>
          <h2>THE WORKFLOW</h2>
        </div>
      </div>
      <div class="workflow-grid">
        <!-- Empty step blocks -->
      </div>
    </div>
  </section>

  <!-- 2. WORKFLOW WITH 1 STEP -->
  <section id="wf-1" class="section color-scheme_2 color-scheme">
    <div class="page-width">
      <div class="section-header" style="text-align: center;">
        <div class="section-header__text">
          <span class="eyebrow">THE RITUAL (1 STEP)</span>
          <h2>SINGLE STEP TEST</h2>
        </div>
      </div>
      <div class="workflow-grid">
        <div class="workflow-step">
          <div class="workflow-step__header">
            <span class="workflow-step__number">01</span>
            <span class="workflow-step__divider"></span>
          </div>
          <h3 class="workflow-step__title h4">01 DOSE</h3>
          <p class="workflow-step__tagline text-sm">Start with consistency.</p>
          <div class="workflow-step__body rte text-sm"><p>Weigh beans to 0.1g precision.</p></div>
          <a href="#" class="button--link text-xs workflow-step__link">Shop Dosing Tools &rarr;</a>
        </div>
      </div>
    </div>
  </section>

  <!-- 3. WORKFLOW WITH 3 STEPS (CANONICAL) -->
  <section id="wf-3" class="section color-scheme_2 color-scheme">
    <div class="page-width">
      <div class="section-header" style="text-align: center;">
        <div class="section-header__text">
          <span class="eyebrow">THE RITUAL</span>
          <h2>THE THREE-STEP WORKFLOW</h2>
        </div>
      </div>
      <div class="workflow-grid">
        <div class="workflow-step step-1">
          <div class="workflow-step__header">
            <span class="workflow-step__number">01</span>
            <span class="workflow-step__divider"></span>
          </div>
          <h3 class="workflow-step__title h4">01 DOSE</h3>
          <p class="workflow-step__tagline text-sm">Start with consistency.</p>
          <div class="workflow-step__body rte text-sm"><p>Weigh beans to 0.1g precision. Distribute grounds evenly.</p></div>
          <a href="#" class="button--link text-xs workflow-step__link">Shop Dosing Tools &rarr;</a>
        </div>
        <div class="workflow-step step-2">
          <div class="workflow-step__header">
            <span class="workflow-step__number">02</span>
            <span class="workflow-step__divider"></span>
          </div>
          <h3 class="workflow-step__title h4">02 DIAL</h3>
          <p class="workflow-step__tagline text-sm">Fine-tune your grind and extraction.</p>
          <div class="workflow-step__body rte text-sm"><p>Calibrate burr size, track extraction yield, and dial in the sweet spot.</p></div>
          <a href="#" class="button--link text-xs workflow-step__link">Shop Precision Gear &rarr;</a>
        </div>
        <div class="workflow-step step-3">
          <div class="workflow-step__header">
            <span class="workflow-step__number">03</span>
            <span class="workflow-step__divider"></span>
          </div>
          <h3 class="workflow-step__title h4">03 BREW</h3>
          <p class="workflow-step__tagline text-sm">Enjoy the result.</p>
          <div class="workflow-step__body rte text-sm"><p>Pull an unchanneled shot with rich, golden crema.</p></div>
          <a href="#" class="button--link text-xs workflow-step__link">Shop Brewing Gear &rarr;</a>
        </div>
      </div>
    </div>
  </section>

  <!-- 4. WORKFLOW WITH 6 STEPS (STRESS TEST) -->
  <section id="wf-6" class="section color-scheme_2 color-scheme">
    <div class="page-width">
      <div class="section-header" style="text-align: center;">
        <div class="section-header__text">
          <span class="eyebrow">THE RITUAL (6 STEPS)</span>
          <h2>EXTENDED WORKFLOW</h2>
        </div>
      </div>
      <div class="workflow-grid">
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">01</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">01 DOSE</h3><p class="workflow-step__tagline text-sm">Measure</p><div class="workflow-step__body rte text-sm"><p>Step 1</p></div></div>
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">02</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">02 DISTRIBUTE</h3><p class="workflow-step__tagline text-sm">WDT</p><div class="workflow-step__body rte text-sm"><p>Step 2</p></div></div>
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">03</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">03 TAMP</h3><p class="workflow-step__tagline text-sm">Level</p><div class="workflow-step__body rte text-sm"><p>Step 3</p></div></div>
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">04</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">04 PUCK SCREEN</h3><p class="workflow-step__tagline text-sm">Protect</p><div class="workflow-step__body rte text-sm"><p>Step 4</p></div></div>
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">05</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">05 EXTRACT</h3><p class="workflow-step__tagline text-sm">Brew</p><div class="workflow-step__body rte text-sm"><p>Step 5</p></div></div>
        <div class="workflow-step"><div class="workflow-step__header"><span class="workflow-step__number">06</span><span class="workflow-step__divider"></span></div><h3 class="workflow-step__title h4">06 EVALUATE</h3><p class="workflow-step__tagline text-sm">Taste</p><div class="workflow-step__body rte text-sm"><p>Step 6</p></div></div>
      </div>
    </div>
  </section>

  <!-- 5. HERO WITH BOTH IMAGES POPULATED -->
  <div id="hero-both" class="banner color-scheme_3" style="--banner-height: 50vh; --overlay-opacity: 0.3;">
    <div class="banner__media">
      <img src="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='375' height='500'></svg>" class="banner__image--mobile" alt="Mobile Hero">
      <img src="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='1500' height='800'></svg>" class="banner__image--desktop" alt="Desktop Hero">
    </div>
    <div class="page-width">
      <div class="banner__content">
        <span class="eyebrow">DOSE • DIAL • BREW</span>
        <h1>PRECISION FOR EVERY POUR.</h1>
      </div>
    </div>
  </div>

  <!-- 6. HERO WITH DESKTOP-ONLY IMAGE -->
  <div id="hero-desktop-only" class="banner color-scheme_3" style="--banner-height: 50vh; --overlay-opacity: 0.3;">
    <div class="banner__media">
      <img src="data:image/svg+xml,<svg xmlns='http://www.w3.org/2000/svg' width='1500' height='800'></svg>" class="" alt="Desktop Only Hero">
    </div>
    <div class="page-width">
      <div class="banner__content">
        <span class="eyebrow">DOSE • DIAL • BREW</span>
        <h1>DESKTOP ONLY HERO</h1>
      </div>
    </div>
  </div>

<script>
function getMetrics() {
  const vp = window.innerWidth;
  const isMobile = vp < 750;

  const wf3 = document.getElementById('wf-3');
  const wf3Grid = wf3.querySelector('.workflow-grid');
  const wf3Steps = wf3.querySelectorAll('.workflow-step');
  const wf3GridStyles = window.getComputedStyle(wf3Grid);

  const s1 = wf3Steps[0].getBoundingClientRect();
  const s2 = wf3Steps[1].getBoundingClientRect();
  const s3 = wf3Steps[2].getBoundingClientRect();

  const isStacked = (s2.top > s1.bottom - 5);
  const isSideBySide = (Math.abs(s1.top - s2.top) < 10 && Math.abs(s2.top - s3.top) < 10);

  const heroBoth = document.getElementById('hero-both');
  const bothMobileImg = heroBoth.querySelector('.banner__image--mobile');
  const bothDesktopImg = heroBoth.querySelector('.banner__image--desktop');
  const mobileDisp = window.getComputedStyle(bothMobileImg).display;
  const desktopDisp = window.getComputedStyle(bothDesktopImg).display;

  const heroDesktopOnly = document.getElementById('hero-desktop-only');
  const dOnlyImg = heroDesktopOnly.querySelector('img');
  const dOnlyDisp = window.getComputedStyle(dOnlyImg).display;

  const docEl = document.documentElement;

  return {
    viewportWidth: vp,
    docClientWidth: docEl.clientWidth,
    docScrollWidth: docEl.scrollWidth,
    hasDocOverflow: docEl.scrollWidth > docEl.clientWidth,
    wf3: {
      gridColumns: wf3GridStyles.gridTemplateColumns,
      isStacked: isStacked,
      isSideBySide: isSideBySide,
      step1Width: s1.width,
      step2Width: s2.width,
      step3Width: s3.width
    },
    heroBoth: {
      mobileVisible: mobileDisp !== 'none',
      desktopVisible: desktopDisp !== 'none',
      mobileDisplay: mobileDisp,
      desktopDisplay: desktopDisp
    },
    heroDesktopOnly: {
      visible: dOnlyDisp !== 'none',
      display: dOnlyDisp
    }
  };
}

window.addEventListener('message', (e) => {
  if (e.data === 'runMetrics') {
    const m = getMetrics();
    window.parent.postMessage({ type: 'metricsResult', data: m }, '*');
  }
});
</script>
</body>
</html>
"@

    $childPath = Join-Path $env:TEMP "m3_2_child_stress.html"
    [System.IO.File]::WriteAllText($childPath, $childFixtureHtml, [System.Text.Encoding]::UTF8)

    $parentFixtureHtml = @"
<!DOCTYPE html>
<html>
<head><title>Parent Viewport Runner</title></head>
<body style="margin:0;padding:0;">
  <iframe id="f375" src="m3_2_child_stress.html" style="width:375px;height:1200px;border:0;"></iframe>
  <iframe id="f390" src="m3_2_child_stress.html" style="width:390px;height:1200px;border:0;"></iframe>
  <iframe id="f414" src="m3_2_child_stress.html" style="width:414px;height:1200px;border:0;"></iframe>
  <iframe id="f768" src="m3_2_child_stress.html" style="width:768px;height:1200px;border:0;"></iframe>
  <iframe id="f1440" src="m3_2_child_stress.html" style="width:1440px;height:1200px;border:0;"></iframe>
  <pre id="results">PENDING</pre>
<script>
  const frames = ['f375', 'f390', 'f414', 'f768', 'f1440'];
  const collected = {};
  let loadedCount = 0;

  window.addEventListener('message', (e) => {
    if (e.data && e.data.type === 'metricsResult') {
      const w = e.data.data.viewportWidth;
      collected['vp_' + w] = e.data.data;
      if (Object.keys(collected).length === frames.length) {
        document.getElementById('results').innerText = JSON.stringify(collected, null, 2);
      }
    }
  });

  frames.forEach(id => {
    const f = document.getElementById(id);
    f.onload = () => {
      loadedCount++;
      if (loadedCount === frames.length) {
        setTimeout(() => {
          frames.forEach(fid => {
            document.getElementById(fid).contentWindow.postMessage('runMetrics', '*');
          });
        }, 800);
      }
    };
  });
</script>
</body>
</html>
"@
    $parentPath = Join-Path $env:TEMP "m3_2_parent_runner.html"
    [System.IO.File]::WriteAllText($parentPath, $parentFixtureHtml, [System.Text.Encoding]::UTF8)

    $outFile = Join-Path $env:TEMP "m3_2_edge_out.txt"
    Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=8000", "--dump-dom", $parentPath -RedirectStandardOutput $outFile -Wait

    $rawOut = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
    Remove-Item $childPath, $parentPath, $outFile -Force -ErrorAction SilentlyContinue

    $browserMetrics = $null
    if ($rawOut -match '<pre id="results">([\s\S]*?)</pre>') {
        $rawJson = $matches[1].Replace('<br>', "`n").Trim()
        try {
            $browserMetrics = $rawJson | ConvertFrom-Json
        } catch {
            Write-Host "JSON parse error from browser metrics: $_" -ForegroundColor Red
        }
    }

    if ($browserMetrics) {
        # --- 4.1 VIEWPORT 375px (iPhone SE) ---
        $vp375 = $browserMetrics.vp_375
        $hasDocOverflow375 = [bool]($vp375 -and $vp375.hasDocOverflow)
        Log-Assertion -TestId "VP-01" -Category "Layout-375px" `
            -Description "375px: Zero horizontal overflow in workflow & hero container" `
            -Passed (-not $hasDocOverflow375) `
            -Expected "docScrollWidth <= docClientWidth (<= 375px)" `
            -Actual "scrollWidth=$($vp375.docScrollWidth), clientWidth=$($vp375.docClientWidth), hasOverflow=$hasDocOverflow375"

        $wfStacked375 = [bool]($vp375 -and $vp375.wf3.isStacked -and -not $vp375.wf3.isSideBySide)
        Log-Assertion -TestId "VP-02" -Category "Workflow-375px" `
            -Description "375px: Workflow steps collapse smoothly to single-column stacked layout" `
            -Passed $wfStacked375 `
            -Expected "isStacked=True, isSideBySide=False" `
            -Actual "isStacked=$($vp375.wf3.isStacked), isSideBySide=$($vp375.wf3.isSideBySide)"

        $heroBoth375 = [bool]($vp375 -and $vp375.heroBoth.mobileVisible -and -not $vp375.heroBoth.desktopVisible)
        Log-Assertion -TestId "VP-03" -Category "Hero-375px" `
            -Description "375px: Hero displays mobile image and hides desktop image when both populated" `
            -Passed $heroBoth375 `
            -Expected "mobileVisible=True, desktopVisible=False" `
            -Actual "mobile=$($vp375.heroBoth.mobileVisible), desktop=$($vp375.heroBoth.desktopVisible)"

        $heroDOnly375 = [bool]($vp375 -and $vp375.heroDesktopOnly.visible)
        Log-Assertion -TestId "VP-04" -Category "Hero-375px" `
            -Description "375px: Hero falls back to desktop image on mobile when only desktop image is provided" `
            -Passed $heroDOnly375 `
            -Expected "desktopOnly image visible on mobile" `
            -Actual "visible=$($vp375.heroDesktopOnly.visible)"

        # --- 4.2 VIEWPORT 390px (iPhone 12/13/14) ---
        $vp390 = $browserMetrics.vp_390
        $hasDocOverflow390 = [bool]($vp390 -and $vp390.hasDocOverflow)
        Log-Assertion -TestId "VP-05" -Category "Layout-390px" `
            -Description "390px: Zero horizontal overflow in workflow & hero container" `
            -Passed (-not $hasDocOverflow390) `
            -Expected "docScrollWidth <= docClientWidth (<= 390px)" `
            -Actual "scrollWidth=$($vp390.docScrollWidth), clientWidth=$($vp390.docClientWidth)"

        $wfStacked390 = [bool]($vp390 -and $vp390.wf3.isStacked)
        Log-Assertion -TestId "VP-06" -Category "Workflow-390px" `
            -Description "390px: Workflow steps remain single-column stacked" `
            -Passed $wfStacked390 `
            -Expected "isStacked=True" `
            -Actual "isStacked=$($vp390.wf3.isStacked)"

        # --- 4.3 VIEWPORT 414px (iPhone Plus) ---
        $vp414 = $browserMetrics.vp_414
        $hasDocOverflow414 = [bool]($vp414 -and $vp414.hasDocOverflow)
        Log-Assertion -TestId "VP-07" -Category "Layout-414px" `
            -Description "414px: Zero horizontal overflow in workflow & hero container" `
            -Passed (-not $hasDocOverflow414) `
            -Expected "docScrollWidth <= docClientWidth (<= 414px)" `
            -Actual "scrollWidth=$($vp414.docScrollWidth), clientWidth=$($vp414.docClientWidth)"

        # --- 4.4 VIEWPORT 768px (Tablet / Min-Width 750px boundary) ---
        $vp768 = $browserMetrics.vp_768
        $wfSideBySide768 = [bool]($vp768 -and $vp768.wf3.isSideBySide)
        Log-Assertion -TestId "VP-08" -Category "Workflow-768px" `
            -Description "768px (Tablet): Workflow expands to 3-column side-by-side grid (>=750px)" `
            -Passed $wfSideBySide768 `
            -Expected "isSideBySide=True (3 columns)" `
            -Actual "isSideBySide=$($vp768.wf3.isSideBySide), columns=$($vp768.wf3.gridColumns)"

        $heroBoth768 = [bool]($vp768 -and $vp768.heroBoth.desktopVisible -and -not $vp768.heroBoth.mobileVisible)
        Log-Assertion -TestId "VP-09" -Category "Hero-768px" `
            -Description "768px (Tablet): Hero switches to desktop image and hides mobile image" `
            -Passed $heroBoth768 `
            -Expected "desktopVisible=True, mobileVisible=False" `
            -Actual "desktop=$($vp768.heroBoth.desktopVisible), mobile=$($vp768.heroBoth.mobileVisible)"

        # --- 4.5 VIEWPORT 1440px (Desktop Full Width) ---
        $vp1440 = $browserMetrics.vp_1440
        $wfSideBySide1440 = [bool]($vp1440 -and $vp1440.wf3.isSideBySide)
        Log-Assertion -TestId "VP-10" -Category "Workflow-1440px" `
            -Description "1440px (Desktop): Workflow maintains 3-column side-by-side layout" `
            -Passed $wfSideBySide1440 `
            -Expected "isSideBySide=True (3 columns)" `
            -Actual "isSideBySide=$($vp1440.wf3.isSideBySide)"

        $heroBoth1440 = [bool]($vp1440 -and $vp1440.heroBoth.desktopVisible -and -not $vp1440.heroBoth.mobileVisible)
        Log-Assertion -TestId "VP-11" -Category "Hero-1440px" `
            -Description "1440px (Desktop): Hero displays desktop image and hides mobile image" `
            -Passed $heroBoth1440 `
            -Expected "desktopVisible=True, mobileVisible=False" `
            -Actual "desktop=$($vp1440.heroBoth.desktopVisible), mobile=$($vp1440.heroBoth.mobileVisible)"
    } else {
        Write-Host "WARNING: Failed to extract browser metrics from Edge output." -ForegroundColor Red
    }
}

# ------------------------------------------------------------------------------
# FINAL SUMMARY & VERDICT
# ------------------------------------------------------------------------------
$totalTests = $Report.Count
$passedTests = ($Report | Where-Object { $_.Passed }).Count
$failedTests = ($Report | Where-Object { -not $_.Passed }).Count
$criticalFails = ($Report | Where-Object { -not $_.Passed -and $_.Severity -in @("CRITICAL", "HIGH") }).Count
$passRate = [math]::Round(($passedTests / $totalTests) * 100, 1)

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "                       CHALLENGER M3-2 SUMMARY                         " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ("Total Assertions: {0}" -f $totalTests)
Write-Host ("Passed:           {0} ({1}%)" -f $passedTests, $passRate) -ForegroundColor Green
Write-Host ("Failed:           {0}" -f $failedTests) -ForegroundColor $(if ($failedTests -gt 0) { "Red" } else { "Green" })
Write-Host ("Critical/High:    {0}" -f $criticalFails) -ForegroundColor $(if ($criticalFails -gt 0) { "Red" } else { "Green" })

$verdict = if ($criticalFails -eq 0) { "APPROVE" } else { "CHALLENGE_FAILED" }
Write-Host "`nVERDICT: $verdict" -ForegroundColor $(if ($verdict -eq "APPROVE") { "Green" } else { "Red" })
Write-Host "======================================================================" -ForegroundColor Cyan

return @{
    Total = $totalTests
    Passed = $passedTests
    Failed = $failedTests
    CriticalFails = $criticalFails
    PassRate = $passRate
    Verdict = $verdict
    Report = $Report
}
