# ==============================================================================
# CHALLENGER M2-1: EMPIRICAL STRESS-TESTING SUITE FOR MILESTONE M2
# Target: Header, Announcement Bar, Navigation, Touch Targets & Mobile Viewports
# Methodology: Real Headless Chromium (Microsoft Edge) Rendering + Static AST Analysis
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
Write-Host "   CHALLENGER M2-1: EMPIRICAL STRESS-TESTING & ORACLE SUITE           " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SUITE 1: LIQUID PARSING & FALLBACK NAVIGATION ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Liquid Syntax & Navigation Fallback Oracles ---" -ForegroundColor Yellow

$headerLiquidPath = Join-Path $RepoRoot "sections/header.liquid"
$headerContent = [System.IO.File]::ReadAllText($headerLiquidPath, [System.Text.Encoding]::UTF8)

# 1. Liquid tag balancing in header.liquid
$rawNoComments = [System.Text.RegularExpressions.Regex]::Replace($headerContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$rawNoSchema = [System.Text.RegularExpressions.Regex]::Replace($rawNoComments, '\{%-?\s*schema\s*-?%\}[\s\S]*?\{%-?\s*endschema\s*-?%\}', '')
$opensIf = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*(if|unless)\b')).Count
$closesIf = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*(endif|endunless)\b')).Count
$opensFor = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*for\b')).Count
$closesFor = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*endfor\b')).Count

Log-Assertion -TestId "S1-01" -Category "Syntax" `
    -Description "header.liquid tag balance (if/unless/for)" `
    -Passed ($opensIf -eq $closesIf -and $opensFor -eq $closesFor) `
    -Expected "Opens == Closes (If: $opensIf == $closesIf, For: $opensFor == $closesFor)" `
    -Actual "If=$opensIf/$closesIf, For=$opensFor/$closesFor"

# 2. Announcement bar tag balancing
$annLiquidPath = Join-Path $RepoRoot "sections/announcement-bar.liquid"
$annContent = [System.IO.File]::ReadAllText($annLiquidPath, [System.Text.Encoding]::UTF8)
$annNoComments = [System.Text.RegularExpressions.Regex]::Replace($annContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$annNoSchema = [System.Text.RegularExpressions.Regex]::Replace($annNoComments, '\{%-?\s*schema\s*-?%\}[\s\S]*?\{%-?\s*endschema\s*-?%\}', '')
$annOpensIf = ([System.Text.RegularExpressions.Regex]::Matches($annNoSchema, '\{%-?\s*(if|unless)\b')).Count
$annClosesIf = ([System.Text.RegularExpressions.Regex]::Matches($annNoSchema, '\{%-?\s*(endif|endunless)\b')).Count

Log-Assertion -TestId "S1-02" -Category "Syntax" `
    -Description "announcement-bar.liquid tag balance" `
    -Passed ($annOpensIf -eq $annClosesIf) `
    -Expected "Opens == Closes (If: $annOpensIf == $annClosesIf)" `
    -Actual "If=$annOpensIf/$annClosesIf"

# 3. Fallback trigger guard in desktop nav
$hasDesktopGuard = $headerContent -match '\{%-?\s*if\s+menu\s*!=\s*blank\s+and\s+menu\.links\.size\s*>\s*0\s*-?%\}'
Log-Assertion -TestId "S1-03" -Category "Navigation" `
    -Description "Desktop nav guards menu with 'if menu != blank and menu.links.size > 0'" `
    -Passed ([bool]$hasDesktopGuard) `
    -Expected "Guard condition matches 'if menu != blank and menu.links.size > 0'" `
    -Actual "Found: $hasDesktopGuard"

# 4. Fallback trigger guard in mobile drawer
$hasDrawerGuard = $headerContent -match 'menu-drawer__list[\s\S]*?\{%-?\s*if\s+menu\s*!=\s*blank\s+and\s+menu\.links\.size\s*>\s*0\s*-?%\}'
Log-Assertion -TestId "S1-04" -Category "Navigation" `
    -Description "Mobile drawer nav guards menu with 'if menu != blank and menu.links.size > 0'" `
    -Passed ([bool]$hasDrawerGuard) `
    -Expected "Drawer guard condition present in menu-drawer__list" `
    -Actual "Found: $hasDrawerGuard"

# 5. Extract fallback block in desktop navigation
    $desktopFallbackMatches = [System.Text.RegularExpressions.Regex]::Matches($headerContent, '\{%-?\s*endfor\s*-?%\}\s*\{%-?\s*else\s*-?%\}([\s\S]*?)\{%-?\s*endif\s*-?%\}\s*</ul>\s*</nav>')
$desktopFallbackHtml = if ($desktopFallbackMatches.Count -gt 0) { $desktopFallbackMatches[0].Groups[1].Value } else { "" }

$desktopHasShop = $desktopFallbackHtml -match 'Shop' -and ($desktopFallbackHtml -match 'routes\.all_products_collection_url' -or $desktopFallbackHtml -match '/collections/all')
$desktopHasEspresso = $desktopFallbackHtml -match 'Espresso Tools' -and $desktopFallbackHtml -match '/collections/espresso-tools'
$desktopHasStation = $desktopFallbackHtml -match 'Coffee Station' -and $desktopFallbackHtml -match '/collections/coffee-station'
$desktopHasBrewing = $desktopFallbackHtml -match 'Brewing' -and $desktopFallbackHtml -match '/collections/brewing'
$desktopHasAbout = $desktopFallbackHtml -match 'About' -and $desktopFallbackHtml -match '/pages/about'

Log-Assertion -TestId "S1-05" -Category "Navigation" `
    -Description "Desktop fallback renders all 5 links with valid URLs (Shop, Espresso Tools, Coffee Station, Brewing, About)" `
    -Passed ($desktopHasShop -and $desktopHasEspresso -and $desktopHasStation -and $desktopHasBrewing -and $desktopHasAbout) `
    -Expected "All 5 links present with valid relative URLs" `
    -Actual "Shop=$desktopHasShop, Espresso=$desktopHasEspresso, Station=$desktopHasStation, Brewing=$desktopHasBrewing, About=$desktopHasAbout"

# 6. Extract fallback block in mobile drawer navigation
    $drawerFallbackMatches = [System.Text.RegularExpressions.Regex]::Matches($headerContent, 'menu-drawer__list[\s\S]*?\{%-?\s*endfor\s*-?%\}\s*\{%-?\s*else\s*-?%\}([\s\S]*?)\{%-?\s*endif\s*-?%\}\s*</ul>')
$drawerFallbackHtml = if ($drawerFallbackMatches.Count -gt 0) { $drawerFallbackMatches[0].Groups[1].Value } else { "" }

$drawerHasShop = $drawerFallbackHtml -match 'Shop' -and ($drawerFallbackHtml -match 'routes\.all_products_collection_url' -or $drawerFallbackHtml -match '/collections/all')
$drawerHasEspresso = $drawerFallbackHtml -match 'Espresso Tools' -and $drawerFallbackHtml -match '/collections/espresso-tools'
$drawerHasStation = $drawerFallbackHtml -match 'Coffee Station' -and $drawerFallbackHtml -match '/collections/coffee-station'
$drawerHasBrewing = $drawerFallbackHtml -match 'Brewing' -and $drawerFallbackHtml -match '/collections/brewing'
$drawerHasAbout = $drawerFallbackHtml -match 'About' -and $drawerFallbackHtml -match '/pages/about'

Log-Assertion -TestId "S1-06" -Category "Navigation" `
    -Description "Mobile drawer fallback renders all 5 links with valid URLs" `
    -Passed ($drawerHasShop -and $drawerHasEspresso -and $drawerHasStation -and $drawerHasBrewing -and $drawerHasAbout) `
    -Expected "All 5 drawer links present with valid relative URLs" `
    -Actual "Shop=$drawerHasShop, Espresso=$drawerHasEspresso, Station=$drawerHasStation, Brewing=$drawerHasBrewing, About=$drawerHasAbout"

# 7. Semantic class usage in desktop fallback
$desktopUsesNavClasses = $desktopFallbackHtml -match 'nav__item' -and $desktopFallbackHtml -match 'nav__link'
Log-Assertion -TestId "S1-07" -Category "Navigation" `
    -Description "Desktop fallback items use standard semantic classes (nav__item, nav__link)" `
    -Passed ([bool]$desktopUsesNavClasses) `
    -Expected "nav__item and nav__link classes applied" `
    -Actual "Applied: $desktopUsesNavClasses"

# 8. Negative Oracle: Iteration branch executes when menu.links is non-empty
$hasLinkIteration = $headerContent -match 'for\s+link\s+in\s+menu\.links'
Log-Assertion -TestId "S1-08" -Category "Navigation" `
    -Description "Negative Oracle: Custom menu iteration loop preserved for non-empty linklists" `
    -Passed ([bool]$hasLinkIteration) `
    -Expected "'for link in menu.links' preserved" `
    -Actual "Found: $hasLinkIteration"


# ------------------------------------------------------------------------------
# SUITE 2: CSS STATIC RULES & TOUCH TARGET DEFINITIONS
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] CSS Rule Enforcements & Media Queries ---" -ForegroundColor Yellow

$baseCssPath = Join-Path $RepoRoot "assets/base.css"
$baseCssContent = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

# 1. .icon-button touch target rules
$iconButtonTouch = $baseCssContent -match '\.icon-button\s*\{[^}]*min-width\s*:\s*44px' -and $baseCssContent -match '\.icon-button\s*\{[^}]*min-height\s*:\s*44px'
Log-Assertion -TestId "S2-01" -Category "CSS" `
    -Description ".icon-button enforces min-width: 44px and min-height: 44px" `
    -Passed ([bool]$iconButtonTouch) `
    -Expected "min-width: 44px and min-height: 44px on .icon-button" `
    -Actual "Found: $iconButtonTouch"

# 2. .menu-drawer__list a touch target rule
$menuListTouch = $baseCssContent -match '\.menu-drawer__list\s+a[\s\S]*?min-height\s*:\s*44px'
Log-Assertion -TestId "S2-02" -Category "CSS" `
    -Description ".menu-drawer__list a enforces min-height: 44px" `
    -Passed ([bool]$menuListTouch) `
    -Expected "min-height: 44px on .menu-drawer__list a" `
    -Actual "Found: $menuListTouch"

# 3. .menu-drawer__summary touch target rule
$menuSummaryTouch = $baseCssContent -match '\.menu-drawer__summary[\s\S]*?min-height\s*:\s*44px'
Log-Assertion -TestId "S2-03" -Category "CSS" `
    -Description ".menu-drawer__summary enforces min-height: 44px" `
    -Passed ([bool]$menuSummaryTouch) `
    -Expected "min-height: 44px on .menu-drawer__summary" `
    -Actual "Found: $menuSummaryTouch"

# 4. .menu-drawer__sublist a touch target rule
$sublistTouch = $baseCssContent -match '\.menu-drawer__sublist\s+a[\s\S]*?min-height\s*:\s*44px'
Log-Assertion -TestId "S2-04" -Category "CSS" `
    -Description ".menu-drawer__sublist a enforces min-height: 44px" `
    -Passed ([bool]$sublistTouch) `
    -Expected "min-height: 44px on .menu-drawer__sublist a" `
    -Actual "Found: $sublistTouch"

# 5. Sticky header scrolled styling
$scrolledCompact = $baseCssContent -match '\.header-wrapper--scrolled\s+\.header\s*\{[^}]*padding-block\s*:\s*0\.5rem'
$scrolledBlur = $baseCssContent -match '\.header-wrapper--scrolled\s*\{[^}]*backdrop-filter\s*:\s*blur\(12px\)'
$scrolledBorder = $baseCssContent -match '\.header-wrapper--scrolled\s*\{[^}]*border-bottom\s*:'
$scrolledShadow = $baseCssContent -match '\.header-wrapper--scrolled\s*\{[^}]*box-shadow\s*:'

Log-Assertion -TestId "S2-05" -Category "CSS" `
    -Description ".header-wrapper--scrolled implements compact padding, blur, border, and shadow" `
    -Passed ($scrolledCompact -and $scrolledBlur -and $scrolledBorder -and $scrolledShadow) `
    -Expected "Compact padding, blur(12px), border-bottom, and box-shadow defined" `
    -Actual "Padding=$scrolledCompact, Blur=$scrolledBlur, Border=$scrolledBorder, Shadow=$scrolledShadow"

# 6. Prefers-reduced-motion for sticky transitions
$reducedMotion = $baseCssContent -match '@media\s*\(\s*prefers-reduced-motion\s*:\s*reduce\s*\)\s*\{[\s\S]*?\.header-wrapper--sticky[\s\S]*?transition\s*:\s*none'
Log-Assertion -TestId "S2-06" -Category "CSS" `
    -Description "prefers-reduced-motion media query disables sticky transitions" `
    -Passed ([bool]$reducedMotion) `
    -Expected "transition: none on sticky header in reduced motion" `
    -Actual "Found: $reducedMotion"

# 7. Mobile responsive header overrides (< 750px)
$mobileHeaderRules = $baseCssContent -match '@media\s+screen\s+and\s+\(max-width:\s*749px\)\s*\{[\s\S]*?\.header\s*\{[\s\S]*?gap:\s*0\.5rem[\s\S]*?\.header__actions\s*\{[\s\S]*?gap:\s*0'
Log-Assertion -TestId "S2-07" -Category "CSS" `
    -Description "Mobile media query (<750px) adjusts header gaps (header gap: 0.5rem, actions gap: 0)" `
    -Passed ([bool]$mobileHeaderRules) `
    -Expected "Mobile gaps configured to avoid overflow" `
    -Actual "Found: $mobileHeaderRules"


# ------------------------------------------------------------------------------
# SUITE 3: JS SCROLL TRANSITION BEHAVIOR
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Theme.js Scroll Listener Verification ---" -ForegroundColor Yellow

$themeJsPath = Join-Path $RepoRoot "assets/theme.js"
$themeJsContent = [System.IO.File]::ReadAllText($themeJsPath, [System.Text.Encoding]::UTF8)

$hasStickySelector = $themeJsContent -match 'document\.querySelector\(\s*[\x27\x22]\.header-wrapper--sticky[\x27\x22]\s*\)'
$hasScrollListener = $themeJsContent -match 'window\.addEventListener\(\s*[\x27\x22]scroll[\x27\x22]'
$hasPassiveOption = $themeJsContent -match 'addEventListener\(\s*[\x27\x22]scroll[\x27\x22][^)]*passive\s*:\s*true'
$hasThresholdCheck = $themeJsContent -match 'window\.scrollY\s*>\s*20'
$hasToggleClass = $themeJsContent -match 'classList\.toggle\(\s*[\x27\x22]header-wrapper--scrolled[\x27\x22]'

Log-Assertion -TestId "S3-01" -Category "JavaScript" `
    -Description "Sticky scroll handler observes window.scrollY > 20 with passive listener" `
    -Passed ($hasStickySelector -and $hasScrollListener -and $hasPassiveOption -and $hasThresholdCheck -and $hasToggleClass) `
    -Expected "Sticky selector + scroll listener + passive: true + scrollY > 20 threshold + toggle class" `
    -Actual "Selector=$hasStickySelector, Listener=$hasScrollListener, Passive=$hasPassiveOption, Threshold=$hasThresholdCheck, Toggle=$hasToggleClass"

# ------------------------------------------------------------------------------
# SUITE 4: EMPIRICAL HEADLESS CHROMIUM VIEWPORT & TOUCH TARGET TESTS
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] Headless Browser Multi-Viewport & Touch Target Engine ---" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    Write-Host "FATAL: msedge.exe not found at $edgePath" -ForegroundColor Red
    exit 1
}

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
  --space-md: 1.5rem;
  --space-xs: 0.5rem;
  --radius-base: 4px;
  --radius-media: 6px;
  --logo-width: 140px;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.125rem;
}
.color-scheme-3 {
  --color-background: 17 17 17;
  --color-text: 247 243 235;
  --color-border: 42 29 23;
}
"@

$headerFixturePath = Join-Path $RepoRoot "tests/m2_header_fixture.html"
$parentFixturePath = Join-Path $RepoRoot "tests/m2_parent_fixture.html"

$headerFixtureRaw = [System.IO.File]::ReadAllText($headerFixturePath, [System.Text.Encoding]::UTF8)
$childHtml = $headerFixtureRaw.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCssContent)

$childPath = Join-Path $env:TEMP "m2_child_header_test.html"
[System.IO.File]::WriteAllText($childPath, $childHtml, [System.Text.Encoding]::UTF8)

$parentFixtureRaw = [System.IO.File]::ReadAllText($parentFixturePath, [System.Text.Encoding]::UTF8)
$parentPath = Join-Path $env:TEMP "m2_parent_header_test.html"
[System.IO.File]::WriteAllText($parentPath, $parentFixtureRaw, [System.Text.Encoding]::UTF8)

$outFile = Join-Path $env:TEMP "m2_edge_stress_out.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=6000", "--dump-dom", $parentPath -RedirectStandardOutput $outFile -Wait

$rawOut = [System.IO.File]::ReadAllText($outFile, [System.Text.Encoding]::UTF8)
Remove-Item $childPath, $parentPath, $outFile -Force -ErrorAction SilentlyContinue

$metrics = $null
if ($rawOut -match '<pre id="results">([\s\S]*?)</pre>') {
    $rawJson = $matches[1].Replace('<br>', "`n").Trim()
    try {
        $metrics = $rawJson | ConvertFrom-Json
    } catch {
        Write-Host "JSON parse error: $_" -ForegroundColor Red
    }
}

if ($metrics -eq $null) {
    Write-Host "FATAL: Failed to collect browser metrics via Edge." -ForegroundColor Red
    exit 1
}

# --- EVALUATE 375px VIEWPORT ---
$m375 = $metrics.vp_375
Log-Assertion -TestId "S4-01" -Category "Viewport-375px" `
    -Description "375px (iPhone SE/mini): Zero Document Horizontal Overflow" `
    -Passed (-not $m375.hasDocOverflow -and $m375.docScrollWidth -le $m375.docClientWidth) `
    -Expected "scrollWidth <= clientWidth (<= 375px)" `
    -Actual "scrollWidth=$($m375.docScrollWidth), clientWidth=$($m375.docClientWidth)"

Log-Assertion -TestId "S4-02" -Category "Viewport-375px" `
    -Description "375px (iPhone SE/mini): Zero Header Horizontal Overflow" `
    -Passed (-not $m375.hasHeaderOverflow -and $m375.headerScrollWidth -le $m375.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m375.headerScrollWidth), clientWidth=$($m375.headerClientWidth)"

Log-Assertion -TestId "S4-03" -Category "Viewport-375px" `
    -Description "375px (iPhone SE/mini): Zero Announcement Bar Horizontal Overflow" `
    -Passed (-not $m375.hasAnnOverflow -and $m375.annScrollWidth -le $m375.annClientWidth) `
    -Expected "announcement scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m375.annScrollWidth), clientWidth=$($m375.annClientWidth)"

Log-Assertion -TestId "S4-04" -Category "Viewport-375px" `
    -Description "375px (iPhone SE/mini): Zero Menu Drawer Horizontal Overflow" `
    -Passed (-not $m375.hasDrawerOverflow -and $m375.drawerScrollWidth -le $m375.drawerClientWidth) `
    -Expected "drawer scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m375.drawerScrollWidth), clientWidth=$($m375.drawerClientWidth)"

# --- EVALUATE 390px VIEWPORT ---
$m390 = $metrics.vp_390
Log-Assertion -TestId "S4-05" -Category "Viewport-390px" `
    -Description "390px (iPhone 12/13/14): Zero Document Horizontal Overflow" `
    -Passed (-not $m390.hasDocOverflow -and $m390.docScrollWidth -le $m390.docClientWidth) `
    -Expected "scrollWidth <= clientWidth (<= 390px)" `
    -Actual "scrollWidth=$($m390.docScrollWidth), clientWidth=$($m390.docClientWidth)"

Log-Assertion -TestId "S4-06" -Category "Viewport-390px" `
    -Description "390px (iPhone 12/13/14): Zero Header Horizontal Overflow" `
    -Passed (-not $m390.hasHeaderOverflow -and $m390.headerScrollWidth -le $m390.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m390.headerScrollWidth), clientWidth=$($m390.headerClientWidth)"

Log-Assertion -TestId "S4-07" -Category "Viewport-390px" `
    -Description "390px (iPhone 12/13/14): Zero Announcement Bar Horizontal Overflow" `
    -Passed (-not $m390.hasAnnOverflow -and $m390.annScrollWidth -le $m390.annClientWidth) `
    -Expected "announcement scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m390.annScrollWidth), clientWidth=$($m390.annClientWidth)"

Log-Assertion -TestId "S4-08" -Category "Viewport-390px" `
    -Description "390px (iPhone 12/13/14): Zero Menu Drawer Horizontal Overflow" `
    -Passed (-not $m390.hasDrawerOverflow -and $m390.drawerScrollWidth -le $m390.drawerClientWidth) `
    -Expected "drawer scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m390.drawerScrollWidth), clientWidth=$($m390.drawerClientWidth)"

# --- EVALUATE 414px VIEWPORT ---
$m414 = $metrics.vp_414
Log-Assertion -TestId "S4-09" -Category "Viewport-414px" `
    -Description "414px (iPhone 11/XR/Plus): Zero Document Horizontal Overflow" `
    -Passed (-not $m414.hasDocOverflow -and $m414.docScrollWidth -le $m414.docClientWidth) `
    -Expected "scrollWidth <= clientWidth (<= 414px)" `
    -Actual "scrollWidth=$($m414.docScrollWidth), clientWidth=$($m414.docClientWidth)"

Log-Assertion -TestId "S4-10" -Category "Viewport-414px" `
    -Description "414px (iPhone 11/XR/Plus): Zero Header Horizontal Overflow" `
    -Passed (-not $m414.hasHeaderOverflow -and $m414.headerScrollWidth -le $m414.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m414.headerScrollWidth), clientWidth=$($m414.headerClientWidth)"

Log-Assertion -TestId "S4-11" -Category "Viewport-414px" `
    -Description "414px (iPhone 11/XR/Plus): Zero Announcement Bar Horizontal Overflow" `
    -Passed (-not $m414.hasAnnOverflow -and $m414.annScrollWidth -le $m414.annClientWidth) `
    -Expected "announcement scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m414.annScrollWidth), clientWidth=$($m414.annClientWidth)"

Log-Assertion -TestId "S4-12" -Category "Viewport-414px" `
    -Description "414px (iPhone 11/XR/Plus): Zero Menu Drawer Horizontal Overflow" `
    -Passed (-not $m414.hasDrawerOverflow -and $m414.drawerScrollWidth -le $m414.drawerClientWidth) `
    -Expected "drawer scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m414.drawerScrollWidth), clientWidth=$($m414.drawerClientWidth)"

# --- BOUNDARY VIEWPORT: 320px ---
$m320 = $metrics.vp_320
Log-Assertion -TestId "S4-13" -Category "Viewport-320px" `
    -Description "Boundary 320px (iPhone 5/SE1 extreme): Zero Header Horizontal Overflow" `
    -Passed (-not $m320.hasHeaderOverflow -and $m320.headerScrollWidth -le $m320.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($m320.headerScrollWidth), clientWidth=$($m320.headerClientWidth)"

# --- TOUCH TARGET MEASUREMENTS (ON 375px VIEWPORT) ---
$t375 = $m375.targets

# Menu toggle
$togglePass = $t375.menuToggle.width -ge 44 -and $t375.menuToggle.height -ge 44
Log-Assertion -TestId "S4-14" -Category "TouchTarget" `
    -Description "Header Menu Toggle button is >= 44px x 44px" `
    -Passed $togglePass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.menuToggle.width)x$($t375.menuToggle.height)px"

# Search icon button
$searchPass = $t375.headerSearch.width -ge 44 -and $t375.headerSearch.height -ge 44
Log-Assertion -TestId "S4-15" -Category "TouchTarget" `
    -Description "Header Search icon button is >= 44px x 44px" `
    -Passed $searchPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.headerSearch.width)x$($t375.headerSearch.height)px"

# Account icon button
$accountPass = $t375.headerAccount.width -ge 44 -and $t375.headerAccount.height -ge 44
Log-Assertion -TestId "S4-16" -Category "TouchTarget" `
    -Description "Header Account icon button is >= 44px x 44px" `
    -Passed $accountPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.headerAccount.width)x$($t375.headerAccount.height)px"

# Cart icon button
$cartPass = $t375.cartBubble.width -ge 44 -and $t375.cartBubble.height -ge 44
Log-Assertion -TestId "S4-17" -Category "TouchTarget" `
    -Description "Header Cart icon button is >= 44px x 44px" `
    -Passed $cartPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.cartBubble.width)x$($t375.cartBubble.height)px"

# Drawer close button
$closePass = $t375.drawerClose.width -ge 44 -and $t375.drawerClose.height -ge 44
Log-Assertion -TestId "S4-18" -Category "TouchTarget" `
    -Description "Menu Drawer Close button is >= 44px x 44px" `
    -Passed $closePass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.drawerClose.width)x$($t375.drawerClose.height)px"

# Drawer search button
$drawerSearchPass = $t375.drawerSearchBtn.width -ge 44 -and $t375.drawerSearchBtn.height -ge 44
Log-Assertion -TestId "S4-19" -Category "TouchTarget" `
    -Description "Menu Drawer Search CTA button is >= 44px x 44px" `
    -Passed $drawerSearchPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.drawerSearchBtn.width)x$($t375.drawerSearchBtn.height)px"

# Drawer account button
$drawerAccPass = $t375.drawerAccountBtn.width -ge 44 -and $t375.drawerAccountBtn.height -ge 44
Log-Assertion -TestId "S4-20" -Category "TouchTarget" `
    -Description "Menu Drawer Account / Login button is >= 44px x 44px" `
    -Passed $drawerAccPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.drawerAccountBtn.width)x$($t375.drawerAccountBtn.height)px"

# Drawer summary (nested group)
$drawerSumPass = $t375.drawerSummary.width -ge 44 -and $t375.drawerSummary.height -ge 44
Log-Assertion -TestId "S4-21" -Category "TouchTarget" `
    -Description "Menu Drawer Summary (nested accordion toggle) is >= 44px x 44px" `
    -Passed $drawerSumPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.drawerSummary.width)x$($t375.drawerSummary.height)px"

# Drawer sublink
$drawerSubPass = $t375.drawerSublink.width -ge 44 -and $t375.drawerSublink.height -ge 44
Log-Assertion -TestId "S4-22" -Category "TouchTarget" `
    -Description "Menu Drawer Sublink item is >= 44px x 44px" `
    -Passed $drawerSubPass `
    -Expected ">= 44x44px" `
    -Actual "$($t375.drawerSublink.width)x$($t375.drawerSublink.height)px"

# Drawer fallback navigation links (all 5)
$allLinksPass = $true
$linkActuals = @()
foreach ($l in $t375.drawerLinks) {
    if ($l.width -lt 44 -or $l.height -lt 44) {
        $allLinksPass = $false
    }
    $linkActuals += "$($l.width)x$($l.height)px"
}
Log-Assertion -TestId "S4-23" -Category "TouchTarget" `
    -Description "All 5 Menu Drawer Fallback Links are >= 44px x 44px" `
    -Passed $allLinksPass `
    -Expected "Each link >= 44x44px" `
    -Actual ($linkActuals -join ", ")


# ------------------------------------------------------------------------------
# SUITE 5: ANNOUNCEMENT BAR BRANDING & SYNCHRONIZATION
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 5] Announcement Bar Branding & Synchronization ---" -ForegroundColor Yellow

$headerGroupJson = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "sections/header-group.json"), [System.Text.Encoding]::UTF8)
$headerGroup = $headerGroupJson | ConvertFrom-Json

$annBlock = $headerGroup.sections.'announcement-bar'.blocks.'announcement-1'
$annGroupText = if ($annBlock) { $annBlock.settings.text } else { "" }

$expectedAnnText = "FREE STANDARD SHIPPING ON ORDERS OVER €55"
$annGroupMatches = $annGroupText -eq $expectedAnnText

Log-Assertion -TestId "S5-01" -Category "Branding" `
    -Description "sections/header-group.json announcement text is verbatim '$expectedAnnText'" `
    -Passed $annGroupMatches `
    -Expected $expectedAnnText `
    -Actual $annGroupText

$annDefaultMatches = $annContent -match 'default":\s*"FREE STANDARD SHIPPING ON ORDERS OVER €55"'
Log-Assertion -TestId "S5-02" -Category "Branding" `
    -Description "sections/announcement-bar.liquid schema default text is verbatim '$expectedAnnText'" `
    -Passed ([bool]$annDefaultMatches) `
    -Expected "default: '$expectedAnnText'" `
    -Actual "Found: $annDefaultMatches"

$annScheme3Matches = $headerGroup.sections.'announcement-bar'.settings.color_scheme -eq "scheme_3"
Log-Assertion -TestId "S5-03" -Category "Branding" `
    -Description "Announcement bar section is assigned color scheme 'scheme_3' (espresso/black bg with cream text)" `
    -Passed ([bool]$annScheme3Matches) `
    -Expected "scheme_3" `
    -Actual "$($headerGroup.sections.'announcement-bar'.settings.color_scheme)"


# ------------------------------------------------------------------------------
# FINAL REPORT SUMMARY
# ------------------------------------------------------------------------------
$totalTests = $Report.Count
$totalPassed = ($Report | Where-Object { $_.Passed }).Count
$totalFailed = $totalTests - $totalPassed
$passRate = [Math]::Round(($totalPassed / $totalTests) * 100, 1)

Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M2-1 STRESS-TEST RESULTS SUMMARY                       " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host ("  TOTAL ASSERTIONS: {0}" -f $totalTests)
Write-Host ("  PASSED:           {0}" -f $totalPassed) -ForegroundColor Green
Write-Host ("  FAILED:           {0}" -f $totalFailed) -ForegroundColor $(if ($totalFailed -eq 0) { "Green" } else { "Red" })
Write-Host ("  COMPLIANCE RATE:  {0}%" -f $passRate) -ForegroundColor $(if ($passRate -eq 100.0) { "Green" } else { "Red" })

$verdict = if ($totalFailed -eq 0) { "APPROVE" } else { "CHALLENGE_FAILED" }
Write-Host ("`n  FORMAL VERDICT:   {0}" -f $verdict) -ForegroundColor $(if ($verdict -eq "APPROVE") { "Green" } else { "Red" })
Write-Host "======================================================================`n" -ForegroundColor Cyan

return [PSCustomObject]@{
    TotalTests  = $totalTests
    Passed      = $totalPassed
    Failed      = $totalFailed
    PassRate    = $passRate
    Verdict     = $verdict
    Report      = $Report
}
