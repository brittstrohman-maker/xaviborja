# ==============================================================================
# CHALLENGER M3-1: EMPIRICAL STRESS-TESTING SUITE FOR MILESTONE M3
# Target: Editorial Homepage Sections (8 Sections)
# Methodology: Headless Edge (Chromium) Real Rendering + Empty-State Oracles + Reduced Motion
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
Write-Host "   CHALLENGER M3-1: EMPIRICAL HOMEPAGE STRESS-TESTING SUITE          " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SUITE 1: TEMPLATE STRUCTURE & SECTION SCHEMA INTEGRITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Template Sequence & Section Liquid Integrity ---" -ForegroundColor Yellow

$indexJsonPath = Join-Path $RepoRoot "templates/index.json"
$indexJsonRaw = [System.IO.File]::ReadAllText($indexJsonPath, [System.Text.Encoding]::UTF8)
$indexJson = $indexJsonRaw | ConvertFrom-Json

# 1. Exact 8-section sequence in templates/index.json
$expectedOrder = @(
    "hero",
    "marquee",
    "collection-list",
    "featured-collection",
    "image-with-text",
    "multicolumn",
    "workflow",
    "newsletter"
)
$actualOrder = @($indexJson.order)
$orderMatches = ($expectedOrder.Count -eq $actualOrder.Count)
if ($orderMatches) {
    for ($i = 0; $i -lt $expectedOrder.Count; $i++) {
        if ($expectedOrder[$i] -ne $actualOrder[$i]) {
            $orderMatches = $false
            break
        }
    }
}

Log-Assertion -TestId "S1-01" -Category "Template" `
    -Description "templates/index.json defines exact 8-section editorial order" `
    -Passed $orderMatches `
    -Expected ($expectedOrder -join " -> ") `
    -Actual ($actualOrder -join " -> ")

# 2. Tag balancing across all 8 section files
$sectionFiles = @(
    "sections/hero.liquid",
    "sections/marquee.liquid",
    "sections/collection-list.liquid",
    "sections/featured-collection.liquid",
    "sections/image-with-text.liquid",
    "sections/multicolumn.liquid",
    "sections/workflow.liquid",
    "sections/newsletter.liquid"
)

$allBalanced = $true
$balanceDetails = [System.Collections.ArrayList]::new()

foreach ($sf in $sectionFiles) {
    $fullPath = Join-Path $RepoRoot $sf
    if (-not (Test-Path $fullPath)) {
        $allBalanced = $false
        $null = $balanceDetails.Add("$sf missing")
        continue
    }
    $c = [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    $cNoComment = [System.Text.RegularExpressions.Regex]::Replace($c, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
    $cNoSchema = [System.Text.RegularExpressions.Regex]::Replace($cNoComment, '\{%-?\s*schema\s*-?%\}[\s\S]*?\{%-?\s*endschema\s*-?%\}', '')
    
    $opIf = ([System.Text.RegularExpressions.Regex]::Matches($cNoSchema, '\{%-?\s*(if|unless)\b')).Count
    $clIf = ([System.Text.RegularExpressions.Regex]::Matches($cNoSchema, '\{%-?\s*(endif|endunless)\b')).Count
    $opFor = ([System.Text.RegularExpressions.Regex]::Matches($cNoSchema, '\{%-?\s*for\b')).Count
    $clFor = ([System.Text.RegularExpressions.Regex]::Matches($cNoSchema, '\{%-?\s*endfor\b')).Count
    
    $balanced = ($opIf -eq $clIf -and $opFor -eq $clFor)
    if (-not $balanced) {
        $allBalanced = $false
        $null = $balanceDetails.Add("$sf (If:$opIf/$clIf, For:$opFor/$clFor)")
    }
}

Log-Assertion -TestId "S1-02" -Category "Syntax" `
    -Description "All 8 homepage section templates have balanced Liquid block tags" `
    -Passed $allBalanced `
    -Expected "All balanced (0 mismatches)" `
    -Actual (if ($balanceDetails.Count -eq 0) { "All 8 balanced" } else { $balanceDetails -join "; " })

# 3. Schema JSON validity in all 8 sections
$allSchemasValid = $true
$schemaErrors = [System.Collections.ArrayList]::new()

foreach ($sf in $sectionFiles) {
    $c = [System.IO.File]::ReadAllText((Join-Path $RepoRoot $sf), [System.Text.Encoding]::UTF8)
    if ($c -match '\{%-?\s*schema\s*-?%\}[\r\n]*([\s\S]*?)[\r\n]*\{%-?\s*endschema\s*-?%\}') {
        $schemaText = $matches[1].Trim()
        try {
            $null = $schemaText | ConvertFrom-Json
        } catch {
            $allSchemasValid = $false
            $null = $schemaErrors.Add("$($sf): $_")
        }
    } else {
        $allSchemasValid = $false
        $null = $schemaErrors.Add("$sf missing schema tag")
    }
}

Log-Assertion -TestId "S1-03" -Category "Schema" `
    -Description "All 8 homepage section schemas contain valid JSON" `
    -Passed $allSchemasValid `
    -Expected "8 valid schemas" `
    -Actual (if ($schemaErrors.Count -eq 0) { "8/8 valid" } else { $schemaErrors -join "; " })

# 4. Workflow section contract validation
$workflowPath = Join-Path $RepoRoot "sections/workflow.liquid"
$workflowContent = [System.IO.File]::ReadAllText($workflowPath, [System.Text.Encoding]::UTF8)
$hasWorkflowGrid = $workflowContent -match 'class=[\x27\x22]workflow-grid[\x27\x22]'
$hasWorkflowStep = $workflowContent -match 'class=[\x27\x22]workflow-step[\x27\x22]'
$hasStepNumber = $workflowContent -match 'workflow-step__number'
$hasTagline = $workflowContent -match 'workflow-step__tagline'

Log-Assertion -TestId "S1-04" -Category "Workflow" `
    -Description "sections/workflow.liquid implements required semantic markup classes" `
    -Passed ($hasWorkflowGrid -and $hasWorkflowStep -and $hasStepNumber -and $hasTagline) `
    -Expected "workflow-grid, workflow-step, workflow-step__number, workflow-step__tagline present" `
    -Actual "Grid=$hasWorkflowGrid, Step=$hasWorkflowStep, Number=$hasStepNumber, Tagline=$hasTagline"

# ------------------------------------------------------------------------------
# SUITE 2: REAL HEADLESS CHROMIUM MULTI-VIEWPORT OVERFLOW STRESS-TESTING
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] Headless Edge Multi-Viewport Overflow Oracle ---" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    Write-Host "FATAL: msedge.exe not found at $edgePath" -ForegroundColor Red
    exit 1
}

# Generate Token CSS and Base CSS
$baseCssContent = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "assets/base.css"), [System.Text.Encoding]::UTF8)
$tokenCss = @"
:root {
  --color-brand-cream: 247 243 235;
  --color-brand-offwhite: 252 250 246;
  --color-brand-white: 255 255 255;
  --color-brand-black: 17 17 17;
  --color-brand-espresso: 42 29 23;
  --color-brand-walnut: 122 87 54;
  --color-brand-copper: 154 98 56;
  --color-brand-taupe: 231 224 214;
  --color-brand-gray: 119 113 107;
  --color-background: 252 250 246;
  --color-text: 17 17 17;
  --color-button: 17 17 17;
  --color-button-label: 255 255 255;
  --color-outline-button: 17 17 17;
  --color-accent: 154 98 56;
  --color-border: 231 224 214;
  --font-body: 'Manrope', 'Inter', sans-serif;
  --font-heading: 'Manrope', 'Inter', sans-serif;
  --font-heading-weight: 800;
  --page-width: 1320px;
  --page-gutter: 1.25rem;
  --space-xs: 0.5rem;
  --space-sm: 1rem;
  --space-md: 1.5rem;
  --space-lg: 2.5rem;
  --space-xl: 4rem;
  --space-2xl: 6rem;
  --section-padding: clamp(2.5rem, 6vw, 5rem);
  --grid-gap: clamp(0.75rem, 2vw, 1.5rem);
  --radius-base: 4px;
  --radius-media: 6px;
  --logo-width: 140px;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
  --text-h0: clamp(2.5rem, 6vw, 5.5rem);
  --text-h1: clamp(2.0rem, 4.5vw, 3.5rem);
  --text-h2: clamp(1.6rem, 3.2vw, 2.5rem);
  --text-h3: 1.5rem;
  --text-h4: 1.25rem;
  --text-h5: 1.125rem;
  --text-h6: 1.0rem;
}
.color-scheme-1 {
  --color-background: 252 250 246;
  --color-text: 17 17 17;
  --color-border: 231 224 214;
}
.color-scheme-2 {
  --color-background: 247 243 235;
  --color-text: 17 17 17;
  --color-border: 231 224 214;
}
.color-scheme-3 {
  --color-background: 17 17 17;
  --color-text: 247 243 235;
  --color-border: 42 29 23;
}
"@

# Prepare child fixtures
$homepageFixtureRaw = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "tests/m3_homepage_fixture.html"), [System.Text.Encoding]::UTF8)
$homepageHtml = $homepageFixtureRaw.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCssContent)
$childHomePath = Join-Path $env:TEMP "m3_child_homepage.html"
[System.IO.File]::WriteAllText($childHomePath, $homepageHtml, [System.Text.Encoding]::UTF8)

$emptyFixtureRaw = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "tests/m3_empty_state_fixture.html"), [System.Text.Encoding]::UTF8)
$emptyHtml = $emptyFixtureRaw.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCssContent)
$childEmptyPath = Join-Path $env:TEMP "m3_child_empty.html"
[System.IO.File]::WriteAllText($childEmptyPath, $emptyHtml, [System.Text.Encoding]::UTF8)

$parentFixtureRaw = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "tests/m3_parent_runner.html"), [System.Text.Encoding]::UTF8)
$parentRunnerPath = Join-Path $env:TEMP "m3_parent_runner.html"
[System.IO.File]::WriteAllText($parentRunnerPath, $parentFixtureRaw, [System.Text.Encoding]::UTF8)

$outFile = Join-Path $env:TEMP "m3_edge_stress_out.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=8000", "--dump-dom", $parentRunnerPath -RedirectStandardOutput $outFile -Wait

$rawOut = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
Remove-Item $childHomePath, $childEmptyPath, $parentRunnerPath, $outFile -Force -ErrorAction SilentlyContinue

$metrics = $null
if ($rawOut -match '<pre id="results">([\s\S]*?)</pre>') {
    $rawJson = $matches[1].Replace('<br>', "`n").Trim()
    try {
        $metrics = $rawJson | ConvertFrom-Json
    } catch {
        Write-Host "JSON parse error on metrics: $_" -ForegroundColor Red
    }
}

if ($metrics -eq $null -or $metrics.standard -eq $null) {
    Write-Host "FATAL: Failed to collect headless browser metrics via Edge." -ForegroundColor Red
    exit 1
}

# Evaluate Viewports for Standard Homepage
# Including 360px (Adversarial Mobile Baseline) and 375, 390, 414, 1440
$viewports = @("360", "375", "390", "414", "1440")

foreach ($vp in $viewports) {
    $vpKey = "vp_$vp"
    $data = $metrics.standard.$vpKey
    if ($null -eq $data) {
        Log-Assertion -TestId "S2-VP$vp-00" -Category "Viewport-$vp" `
            -Description "Viewport $vp px metrics collection" `
            -Passed $false -Expected "Metrics collected" -Actual "Null"
        continue
    }

    $isStressBaseline = ($vp -eq "360")
    $vpSeverity = if ($isStressBaseline) { "HIGH" } else { "CRITICAL" }

    # 1. Document horizontal overflow
    Log-Assertion -TestId "S2-VP$vp-01" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Zero Document Horizontal Overflow" `
        -Passed (-not $data.hasDocOverflow -and $data.docScrollWidth -le ($data.docClientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth (<= $vp px)" `
        -Actual "scrollWidth=$($data.docScrollWidth), clientWidth=$($data.docClientWidth)" `
        -Severity $vpSeverity

    # 2. No child elements bleeding beyond viewport
    Log-Assertion -TestId "S2-VP$vp-02" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Zero Child Element Viewport Bleed" `
        -Passed (-not $data.anyElementOverflows) `
        -Expected "anyElementOverflows == false" `
        -Actual "Overflows=$($data.anyElementOverflows), Count=$($data.overflowingElementsCount)" `
        -Severity $vpSeverity

    # 3. Individual section scrollWidth checks
    $sHero = $data.sections.'section-hero'
    Log-Assertion -TestId "S2-VP$vp-03" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Hero Section Zero Horizontal Overflow" `
        -Passed (-not $sHero.hasOverflow -and $sHero.scrollWidth -le ($sHero.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sHero.scrollWidth), CW=$($sHero.clientWidth)" `
        -Severity $vpSeverity

    $sMarquee = $data.sections.'section-marquee'
    # Marquee container relies on overflow: hidden to clip its flex track
    $marqueePassed = $sMarquee.isClipped -and (-not $data.hasDocOverflow)
    Log-Assertion -TestId "S2-VP$vp-04" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Marquee Section Clips Overflow via overflow: hidden" `
        -Passed $marqueePassed `
        -Expected "isClipped == true and zero doc overflow" `
        -Actual "Clipped=$($sMarquee.isClipped), DocOverflow=$($data.hasDocOverflow)" `
        -Severity "CRITICAL"

    $sColl = $data.sections.'section-collection-list'
    Log-Assertion -TestId "S2-VP$vp-05" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Collection List Zero Horizontal Overflow" `
        -Passed (-not $sColl.hasOverflow -and $sColl.scrollWidth -le ($sColl.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sColl.scrollWidth), CW=$($sColl.clientWidth)"

    $sFeat = $data.sections.'section-featured-collection'
    Log-Assertion -TestId "S2-VP$vp-06" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Featured Collection (Best Sellers) Zero Horizontal Overflow" `
        -Passed (-not $sFeat.hasOverflow -and $sFeat.scrollWidth -le ($sFeat.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sFeat.scrollWidth), CW=$($sFeat.clientWidth)"

    $sBrand = $data.sections.'section-image-with-text'
    Log-Assertion -TestId "S2-VP$vp-07" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Brand Story (Image with Text) Zero Horizontal Overflow" `
        -Passed (-not $sBrand.hasOverflow -and $sBrand.scrollWidth -le ($sBrand.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sBrand.scrollWidth), CW=$($sBrand.clientWidth)"

    $sMulti = $data.sections.'section-multicolumn'
    Log-Assertion -TestId "S2-VP$vp-08" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Multicolumn (Why Dose & Dial) Zero Horizontal Overflow" `
        -Passed (-not $sMulti.hasOverflow -and $sMulti.scrollWidth -le ($sMulti.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sMulti.scrollWidth), CW=$($sMulti.clientWidth)"

    $sWork = $data.sections.'section-workflow'
    Log-Assertion -TestId "S2-VP$vp-09" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Workflow Ritual Section Zero Horizontal Overflow" `
        -Passed (-not $sWork.hasOverflow -and $sWork.scrollWidth -le ($sWork.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sWork.scrollWidth), CW=$($sWork.clientWidth)"

    $sNews = $data.sections.'section-newsletter'
    Log-Assertion -TestId "S2-VP$vp-10" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Newsletter Section Zero Horizontal Overflow" `
        -Passed (-not $sNews.hasOverflow -and $sNews.scrollWidth -le ($sNews.clientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth" `
        -Actual "SW=$($sNews.scrollWidth), CW=$($sNews.clientWidth)"
}

# ------------------------------------------------------------------------------
# SUITE 3: EMPTY-STATE BEHAVIOR & LIQUID FALLBACK ROBUSTNESS
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Empty-State Resilience & Liquid Fallbacks ---" -ForegroundColor Yellow

# Empty state headless browser overflow check
$eData375 = $metrics.empty.vp_375
$eData1440 = $metrics.empty.vp_1440

Log-Assertion -TestId "S3-01" -Category "Empty-State" `
    -Description "Empty-State 375px: Zero Document Horizontal Overflow" `
    -Passed (-not $eData375.hasDocOverflow -and $eData375.docScrollWidth -le ($eData375.docClientWidth + 1)) `
    -Expected "scrollWidth <= clientWidth" `
    -Actual "SW=$($eData375.docScrollWidth), CW=$($eData375.docClientWidth)"

Log-Assertion -TestId "S3-02" -Category "Empty-State" `
    -Description "Empty-State 1440px: Zero Document Horizontal Overflow" `
    -Passed (-not $eData1440.hasDocOverflow -and $eData1440.docScrollWidth -le ($eData1440.docClientWidth + 1)) `
    -Expected "scrollWidth <= clientWidth" `
    -Actual "SW=$($eData1440.docScrollWidth), CW=$($eData1440.docClientWidth)"

# Liquid Code Verification: Featured collection empty state loop
$featContent = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "sections/featured-collection.liquid"), [System.Text.Encoding]::UTF8)
$hasElseLoop = $featContent -match '\{%-?\s*for\s+product\s+in\s+products[^%]*%\}([\s\S]*?)\{%-?\s*else\s*-?%\}([\s\S]*?)\{%-?\s*endfor\s*-?%\}'
$elseBody = if ($hasElseLoop) { $matches[2] } else { "" }
$hasPlaceholderLoop = $elseBody -match 'for\s+i\s+in\s+\(1\.\.limit\)' -and $elseBody -match 'render\s+[\x27\x22]product-card[\x27\x22]'

Log-Assertion -TestId "S3-03" -Category "Empty-State" `
    -Description "sections/featured-collection.liquid provides {% else %} loop rendering product-card placeholders" `
    -Passed $hasPlaceholderLoop `
    -Expected "'for i in (1..limit)' with 'render product-card' in {% else %} block" `
    -Actual "HasPlaceholderLoop=$hasPlaceholderLoop"

# Product-card fallback when product is blank
$cardContent = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "snippets/product-card.liquid"), [System.Text.Encoding]::UTF8)
$hasBlankGuard = $cardContent -match '\{%-?\s*if\s+product\s*==\s*blank\s*-?%\}'
$hasPlaceholderSvg = $cardContent -match 'placeholder_svg_tag'

Log-Assertion -TestId "S3-04" -Category "Empty-State" `
    -Description "snippets/product-card.liquid gracefully handles product == blank with placeholder SVG" `
    -Passed ($hasBlankGuard -and $hasPlaceholderSvg) `
    -Expected "if product == blank guard + placeholder SVG" `
    -Actual "Guard=$hasBlankGuard, Svg=$hasPlaceholderSvg"

# Collection-list fallback for unassigned collection
$collContent = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "sections/collection-list.liquid"), [System.Text.Encoding]::UTF8)
$hasCollUrlDefault = $collContent -match 'collection\.url\s*\|\s*default\s*:\s*[\x27\x22]#'
$hasCollTitleDefault = $collContent -match 'default\s*:\s*collection\.title' -or $collContent -match 'default\s*:\s*[\x27\x22]Collection[\x27\x22]'
$hasCollSvgFallback = $collContent -match 'placeholder_svg_tag'

Log-Assertion -TestId "S3-05" -Category "Empty-State" `
    -Description "sections/collection-list.liquid falls back on url, title, and placeholder SVG when collection is unassigned" `
    -Passed ($hasCollUrlDefault -and $hasCollTitleDefault -and $hasCollSvgFallback) `
    -Expected "Default URL, default title, and placeholder SVG present" `
    -Actual "URL=$hasCollUrlDefault, Title=$hasCollTitleDefault, SVG=$hasCollSvgFallback"

# Hero fallback when image & video blank
$heroContent = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "sections/hero.liquid"), [System.Text.Encoding]::UTF8)
$hasHeroSvgFallback = $heroContent -match 'hero-apparel-1[\x27\x22]\s*\|\s*placeholder_svg_tag'

Log-Assertion -TestId "S3-06" -Category "Empty-State" `
    -Description "sections/hero.liquid falls back to placeholder SVG when image and video are blank" `
    -Passed $hasHeroSvgFallback `
    -Expected "hero-apparel-1 placeholder SVG fallback present" `
    -Actual "Found=$hasHeroSvgFallback"

# ------------------------------------------------------------------------------
# SUITE 4: HOVER ZOOM ANIMATIONS & REDUCED MOTION ANALYSIS
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] Hover Zoom Animation & Reduced Motion Oracle ---" -ForegroundColor Yellow

# 1. Static CSS verification
$hasHoverTransform = $baseCssContent -match '\.collection-card:hover\s+\.media\s+img[\s\S]*?transform\s*:\s*scale\(1\.05\)'
$hasTransitionCurve = $baseCssContent -match '\.collection-card\s+\.media\s+img[\s\S]*?transition\s*:\s*transform\s+0\.6s\s+cubic-bezier'

Log-Assertion -TestId "S4-01" -Category "Hover-Zoom" `
    -Description "base.css defines scale(1.05) hover zoom on .collection-card with 0.6s cubic-bezier transition" `
    -Passed ($hasHoverTransform -and $hasTransitionCurve) `
    -Expected "transform: scale(1.05) and transition: transform 0.6s cubic-bezier present" `
    -Actual "Transform=$hasHoverTransform, Transition=$hasTransitionCurve"

# 2. Reduced motion media query declaration
$hasReducedMotionBlock = $baseCssContent -match '@media\s*\(\s*prefers-reduced-motion\s*:\s*reduce\s*\)\s*\{[\s\S]*?\.collection-card\s+\.media\s+img[\s\S]*?transition\s*:\s*none'

Log-Assertion -TestId "S4-02" -Category "Reduced-Motion" `
    -Description "base.css includes @media (prefers-reduced-motion: reduce) disabling collection-card transitions" `
    -Passed $hasReducedMotionBlock `
    -Expected "transition: none inside prefers-reduced-motion query" `
    -Actual "Found=$hasReducedMotionBlock"

# 3. EMPIRICAL CHROMIUM PROBE: Hover state under --force-prefers-reduced-motion
$probeHtml = @"
<!DOCTYPE html>
<html>
<head>
<style>
$baseCssContent
</style>
</head>
<body>
<div class="collection-card" id="unhovered-card">
  <div class="media">
    <img id="unhovered-img" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk+A8AAQUBAScY42YAAAAASUVORK5CYII=" />
  </div>
</div>
<pre id="probe-results"></pre>
<script>
  const unhovered = document.getElementById('unhovered-img');
  const compUnhovered = window.getComputedStyle(unhovered);
  
  // Inspect stylesheet rules for specificity analysis
  let hoverSelector = '';
  let reducedMotionSelector = '';
  for (const sheet of document.styleSheets) {
    try {
      for (const rule of sheet.cssRules) {
        if (rule.selectorText && rule.selectorText.includes('.collection-card:hover') && rule.selectorText.includes('img')) {
          hoverSelector = rule.selectorText;
        }
        if (rule.media && rule.media.mediaText.includes('prefers-reduced-motion')) {
          for (const inner of rule.cssRules) {
            if (inner.selectorText && inner.selectorText.includes('.collection-card') && inner.selectorText.includes('img')) {
              reducedMotionSelector = inner.selectorText;
            }
          }
        }
      }
    } catch (e) {}
  }

  document.getElementById('probe-results').textContent = JSON.stringify({
    unhoveredTransition: compUnhovered.transition,
    unhoveredTransform: compUnhovered.transform,
    hoverSelector: hoverSelector,
    reducedMotionSelector: reducedMotionSelector,
    reducedIncludesHover: reducedMotionSelector.includes(':hover')
  });
</script>
</body>
</html>
"@

$probeFile = Join-Path $env:TEMP "m3_motion_probe.html"
[System.IO.File]::WriteAllText($probeFile, $probeHtml, [System.Text.Encoding]::UTF8)
$probeOut = Join-Path $env:TEMP "m3_motion_probe_out.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--force-prefers-reduced-motion", "--virtual-time-budget=2000", "--dump-dom", $probeFile -RedirectStandardOutput $probeOut -Wait

$probeRaw = [System.IO.File]::ReadAllText($probeOut, [System.Text.Encoding]::UTF8)
Remove-Item $probeFile, $probeOut -Force -ErrorAction SilentlyContinue

$probeMetrics = $null
if ($probeRaw -match '<pre id="probe-results">([\s\S]*?)</pre>') {
    try {
        $probeMetrics = $matches[1] | ConvertFrom-Json
    } catch {}
}

$unhoveredTransitionIsNone = ($probeMetrics.unhoveredTransition -match "none" -or $probeMetrics.unhoveredTransition -match "1e-05" -or $probeMetrics.unhoveredTransition -match "0\.01ms" -or $probeMetrics.unhoveredTransition -match "0\.00001s")
Log-Assertion -TestId "S4-03" -Category "Reduced-Motion" `
    -Description "Empirical Edge: Transition is suppressed under prefers-reduced-motion: reduce" `
    -Passed $unhoveredTransitionIsNone `
    -Expected "transition is none or 0.01ms (1e-05s)" `
    -Actual "Transition=$($probeMetrics.unhoveredTransition)"

# Check CSS specificity: did the reduced motion rule include :hover?
# If reducedMotionSelector lacks :hover, the hover rule (.collection-card:hover .media img) has higher specificity (0,3,1) than the reduced rule (0,2,1).
# We log this as a finding / observation.
$reducedCoversHover = [bool]$probeMetrics.reducedIncludesHover
Log-Assertion -TestId "S4-04" -Category "Reduced-Motion" `
    -Description "Specificity Check: Reduced motion block includes :hover to prevent transform: scale() jump on hover" `
    -Passed $reducedCoversHover `
    -Expected "Reduced motion block includes :hover selector" `
    -Actual "ReducedSelector='$($probeMetrics.reducedMotionSelector)', IncludesHover=$reducedCoversHover" `
    -Severity "MEDIUM"

# ------------------------------------------------------------------------------
# FINAL REPORT SUMMARY
# ------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "                       CHALLENGE EXECUTION SUMMARY                    " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$total = $Report.Count
$passed = ($Report | Where-Object { $_.Passed }).Count
$failed = ($Report | Where-Object { -not $_.Passed }).Count
$criticalFailed = ($Report | Where-Object { -not $_.Passed -and $_.Severity -eq "CRITICAL" }).Count
$highFailed = ($Report | Where-Object { -not $_.Passed -and $_.Severity -eq "HIGH" }).Count
$medFailed = ($Report | Where-Object { -not $_.Passed -and $_.Severity -eq "MEDIUM" }).Count

$failedColor = if ($failed -gt 0) { "Yellow" } else { "Green" }
$critColor = if ($criticalFailed -gt 0) { "Red" } else { "DarkGray" }
$highColor = if ($highFailed -gt 0) { "Red" } else { "DarkGray" }
$medColor = if ($medFailed -gt 0) { "Yellow" } else { "DarkGray" }

Write-Host ("Total Assertions: {0}" -f $total)
Write-Host ("Passed:           {0}" -f $passed) -ForegroundColor Green
Write-Host ("Failed:           {0}" -f $failed) -ForegroundColor $failedColor
if ($failed -gt 0) {
    Write-Host ("  - Critical:     {0}" -f $criticalFailed) -ForegroundColor $critColor
    Write-Host ("  - High:         {0}" -f $highFailed) -ForegroundColor $highColor
    Write-Host ("  - Medium:       {0}" -f $medFailed) -ForegroundColor $medColor
}

$verdict = if ($criticalFailed -eq 0 -and $highFailed -eq 0) { "APPROVE" } else { "CHALLENGE_FAILED" }
$verdictColor = if ($verdict -eq "APPROVE") { "Green" } else { "Red" }
Write-Host ("`nFINAL VERDICT:    {0}" -f $verdict) -ForegroundColor $verdictColor

Write-Host "`n--- Detailed Failing Assertions ---" -ForegroundColor Yellow
$failingList = $Report | Where-Object { -not $_.Passed }
if ($failingList.Count -eq 0) {
    Write-Host "None. All assertions passed!" -ForegroundColor Green
} else {
    foreach ($fItem in $failingList) {
        Write-Host ("  [{0}] {1}: {2}" -f $fItem.Severity, $fItem.TestId, $fItem.Description) -ForegroundColor Red
        Write-Host ("        Expected: {0}" -f $fItem.Expected) -ForegroundColor DarkGray
        Write-Host ("        Actual:   {0}" -f $fItem.Actual) -ForegroundColor DarkGray
    }
}

# Return verdict object
[PSCustomObject]@{
    Total          = $total
    Passed         = $passed
    Failed         = $failed
    CriticalFailed = $criticalFailed
    HighFailed     = $highFailed
    MediumFailed   = $medFailed
    Verdict        = $verdict
    Report         = $Report
}
