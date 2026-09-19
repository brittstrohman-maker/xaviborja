# ==============================================================================
# CHALLENGER M2-IT2-1: EMPIRICAL STRESS TEST HARNESS FOR MILESTONE M2 REMEDIATION
# Target: Desktop Navigation (Left & Center), Mobile Viewports & Touch Targets
# Methodology: Real Headless Edge Browser Rendering + Static AST Analysis
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
Write-Host "   CHALLENGER M2-IT2-1: EMPIRICAL STRESS-TEST SUITE                  " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SUITE 1: STATIC CODEBASE & SCHEMA INTEGRITY
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Static Codebase & Schema Integrity ---" -ForegroundColor Yellow

$headerGroupPath = Join-Path $RepoRoot "sections/header-group.json"
$headerGroupJson = Get-Content -Raw -Encoding UTF8 $headerGroupPath | ConvertFrom-Json
$groupName = $headerGroupJson.name

Log-Assertion -TestId "S1-01" -Category "Integrity" `
    -Description "header-group.json section group name is reverted to clean 'Header'" `
    -Passed ($groupName -eq "Header") `
    -Expected "'Header'" `
    -Actual "'$groupName'"

$headerLiquidPath = Join-Path $RepoRoot "sections/header.liquid"
$headerLiquid = Get-Content -Raw -Encoding UTF8 $headerLiquidPath

# Balanced tags
$rawNoComments = [System.Text.RegularExpressions.Regex]::Replace($headerLiquid, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$rawNoSchema = [System.Text.RegularExpressions.Regex]::Replace($rawNoComments, '\{%-?\s*schema\s*-?%\}[\s\S]*?\{%-?\s*endschema\s*-?%\}', '')
$opensIf = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*(if|unless)\b')).Count
$closesIf = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*(endif|endunless)\b')).Count
$opensCapture = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*capture\b')).Count
$closesCapture = ([System.Text.RegularExpressions.Regex]::Matches($rawNoSchema, '\{%-?\s*endcapture\b')).Count

Log-Assertion -TestId "S1-02" -Category "Syntax" `
    -Description "header.liquid block tag balance (if/unless/capture)" `
    -Passed ($opensIf -eq $closesIf -and $opensCapture -eq $closesCapture) `
    -Expected "If: $opensIf == $closesIf, Capture: $opensCapture == $closesCapture" `
    -Actual "If: $opensIf/$closesIf, Capture: $opensCapture/$closesCapture"

# Nav captured and rendered in both layouts
$hasNavCapture = $headerLiquid -match '\{%-?\s*capture\s+nav_html\s*-?%\}'
$hasNavRenderCondition = ($headerLiquid -match 'layout\s*!=\s*[\x27\x22]center[\x27\x22][\s\S]*?\{\{\s*nav_html\s*\}\}') -and `
                         ($headerLiquid -match 'layout\s*==\s*[\x27\x22]center[\x27\x22][\s\S]*?\{\{\s*nav_html\s*\}\}')

Log-Assertion -TestId "S1-03" -Category "Navigation" `
    -Description "header.liquid renders nav_html conditionally for both left and center layouts" `
    -Passed ($hasNavCapture -and $hasNavRenderCondition) `
    -Expected "Nav captured and rendered for both layout != 'center' and layout == 'center'" `
    -Actual "Capture=$hasNavCapture, DualRender=$hasNavRenderCondition"

$baseCssPath = Join-Path $RepoRoot "assets/base.css"
$baseCss = Get-Content -Raw -Encoding UTF8 $baseCssPath

$hasCenterGrid = $baseCss -match '\.header--center\s*\{[^}]*grid-template-columns\s*:\s*1fr\s+auto\s+1fr'
$hasCenterLogo = $baseCss -match '\.header--center\s+\.header__logo\s*\{[^}]*justify-self\s*:\s*center'
$hasCenterDesktop = $baseCss -match '@media\s+screen\s+and\s+\(min-width:\s*990px\)\s*\{[\s\S]*?\.header--center\s+\.nav\s*\{[^}]*grid-column\s*:\s*1\s*/\s*-1'

Log-Assertion -TestId "S1-04" -Category "CSS" `
    -Description "base.css implements .header--center CSS grid, centered logo, and desktop nav grid-column: 1 / -1" `
    -Passed ($hasCenterGrid -and $hasCenterLogo -and $hasCenterDesktop) `
    -Expected "Grid 1fr auto 1fr, justify-self: center, nav grid-column: 1 / -1 on desktop" `
    -Actual "Grid=$hasCenterGrid, LogoJustify=$hasCenterLogo, DesktopNavSpan=$hasCenterDesktop"

# ------------------------------------------------------------------------------
# SUITE 2 & 3: REAL HEADLESS EDGE RENDERING
# ------------------------------------------------------------------------------

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}
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
@media screen and (min-width: 990px) {
  :root { --page-gutter: 2.5rem; }
}
.color-scheme-3 {
  --color-background: 17 17 17;
  --color-text: 247 243 235;
  --color-border: 42 29 23;
}
"@

# Helper function to generate child HTML for specific layout and sticky states
$fixtureTemplate = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot "tests/m2_it2_header_fixture.html")

$navHtmlMarkup = @"
<nav class="nav" id="HeaderNav" role="navigation" aria-label="Menu">
  <ul class="nav__list" id="NavList" role="list">
    <li class="nav__item" id="NavItem1"><a href="/collections/all" class="nav__link" id="NavLink1">Shop</a></li>
    <li class="nav__item" id="NavItem2"><a href="/collections/espresso-tools" class="nav__link" id="NavLink2">Espresso Tools</a></li>
    <li class="nav__item" id="NavItem3"><a href="/collections/coffee-station" class="nav__link" id="NavLink3">Coffee Station</a></li>
    <li class="nav__item" id="NavItem4"><a href="/collections/brewing" class="nav__link" id="NavLink4">Brewing</a></li>
    <li class="nav__item" id="NavItem5"><a href="/pages/about" class="nav__link" id="NavLink5">About</a></li>
  </ul>
</nav>
"@

$headerLeftMarkup = @"
<div class="header-wrapper color-scheme-1 color-scheme header-wrapper--sticky" id="HeaderWrapper">
  <header class="header page-width" id="HeaderEl">
    <button type="button" class="icon-button header__menu-toggle" id="MenuToggle" data-drawer-open="MenuDrawer" aria-label="Open menu">
      <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
    </button>
    <a href="/" class="header__logo" id="HeaderLogo">
      <span class="header__logo-text">Dose &amp; Dial</span>
    </a>
    $navHtmlMarkup
    <div class="header__actions" id="HeaderActions">
      <button type="button" class="icon-button" id="HeaderSearch" data-drawer-open="SearchDrawer" aria-label="Search">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
      </button>
      <a href="/account" class="icon-button" id="HeaderAccount" aria-label="Account">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
      </a>
      <a href="/cart" class="icon-button header__cart" id="CartIconBubble">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path></svg>
      </a>
    </div>
  </header>
</div>
"@

$headerCenterMarkup = @"
<div class="header-wrapper color-scheme-1 color-scheme header-wrapper--sticky" id="HeaderWrapper">
  <header class="header page-width header--center" id="HeaderEl">
    <div class="header__actions" id="HeaderActionsLeft" style="justify-content: flex-start;">
      <button type="button" class="icon-button header__menu-toggle" id="MenuToggle" data-drawer-open="MenuDrawer" aria-label="Open menu">
        <svg width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><line x1="3" y1="12" x2="21" y2="12"></line><line x1="3" y1="6" x2="21" y2="6"></line><line x1="3" y1="18" x2="21" y2="18"></line></svg>
      </button>
      <button type="button" class="icon-button" id="HeaderSearch" data-drawer-open="SearchDrawer" aria-label="Search">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="8"></circle><line x1="21" y1="21" x2="16.65" y2="16.65"></line></svg>
      </button>
    </div>

    <a href="/" class="header__logo" id="HeaderLogo">
      <span class="header__logo-text">Dose &amp; Dial</span>
    </a>

    <div class="header__actions" id="HeaderActionsRight">
      <a href="/account" class="icon-button" id="HeaderAccount" aria-label="Account">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2"></path><circle cx="12" cy="7" r="4"></circle></svg>
      </a>
      <a href="/cart" class="icon-button header__cart" id="CartIconBubble">
        <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z"></path><line x1="3" y1="6" x2="21" y2="6"></line><path d="M16 10a4 4 0 0 1-8 0"></path></svg>
      </a>
    </div>

    $navHtmlMarkup
  </header>
</div>
"@

$leftNormalHtml = $fixtureTemplate.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCss).Replace('<!-- INJECTED_HEADER -->', $headerLeftMarkup)
$leftStickyHtml = $leftNormalHtml.Replace('header-wrapper--sticky"', 'header-wrapper--sticky header-wrapper--scrolled"')

$centerNormalHtml = $fixtureTemplate.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCss).Replace('<!-- INJECTED_HEADER -->', $headerCenterMarkup)
$centerStickyHtml = $centerNormalHtml.Replace('header-wrapper--sticky"', 'header-wrapper--sticky header-wrapper--scrolled"')

# Write temporary files for Edge execution
$tempDir = $env:TEMP
$pathLeftNormal   = Join-Path $tempDir "m2_child_left_normal.html"
$pathLeftSticky   = Join-Path $tempDir "m2_child_left_sticky.html"
$pathCenterNormal = Join-Path $tempDir "m2_child_center_normal.html"
$pathCenterSticky = Join-Path $tempDir "m2_child_center_sticky.html"

[System.IO.File]::WriteAllText($pathLeftNormal,   $leftNormalHtml,   [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($pathLeftSticky,   $leftStickyHtml,   [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($pathCenterNormal, $centerNormalHtml, [System.Text.Encoding]::UTF8)
[System.IO.File]::WriteAllText($pathCenterSticky, $centerStickyHtml, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# BATCH 1: DESKTOP NAVIGATION STRESS TEST
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] Empirical Desktop Navigation Stress Test (Left & Center) ---" -ForegroundColor Yellow

$desktopParentSrc = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot "tests/m2_stress_desktop_parent.html")
$desktopParentPath = Join-Path $tempDir "m2_stress_desktop_parent.html"
[System.IO.File]::WriteAllText($desktopParentPath, $desktopParentSrc, [System.Text.Encoding]::UTF8)

$desktopOutFile = Join-Path $tempDir "m2_edge_desktop_out.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--window-size=1920,1080", "--virtual-time-budget=8000", "--dump-dom", $desktopParentPath -RedirectStandardOutput $desktopOutFile -Wait

$desktopRawOut = [System.IO.File]::ReadAllText($desktopOutFile, [System.Text.Encoding]::UTF8)
Remove-Item $desktopParentPath, $desktopOutFile -Force -ErrorAction SilentlyContinue

$desktopMetrics = $null
if ($desktopRawOut -match '<pre id="results">([\s\S]*?)</pre>') {
    $rawJson = $matches[1].Replace('<br>', "`n").Trim()
    try {
        $desktopMetrics = $rawJson | ConvertFrom-Json
    } catch {
        Write-Host "Desktop JSON parse error: $_" -ForegroundColor Red
    }
}

if ($desktopMetrics -eq $null) {
    Write-Host "FATAL: Failed to collect desktop browser metrics via Edge." -ForegroundColor Red
    exit 1
}

# --- 2.1 LEFT LAYOUT ON DESKTOP ---
foreach ($vp in @(1024, 1280, 1440)) {
    $m = $desktopMetrics."left_$vp"
    $idPrefix = "S2-L$vp"

    # 1. Nav is displayed as flex
    Log-Assertion -TestId "$idPrefix-01" -Category "DesktopNav-Left" `
        -Description "Left layout at ${vp}px: Desktop nav is displayed (display: flex)" `
        -Passed ($m.navComputedDisplay -eq 'flex') `
        -Expected "'flex'" `
        -Actual "'$($m.navComputedDisplay)'"

    # 2. Hamburger toggle is hidden
    Log-Assertion -TestId "$idPrefix-02" -Category "DesktopNav-Left" `
        -Description "Left layout at ${vp}px: Hamburger menu toggle is hidden (display: none)" `
        -Passed ($m.toggleComputedDisplay -eq 'none') `
        -Expected "'none'" `
        -Actual "'$($m.toggleComputedDisplay)'"

    # 3. Zero horizontal overflow
    $noOverflow = (-not $m.hasDocOverflow) -and (-not $m.hasHeaderOverflow) -and ($m.headerScrollWidth -le $m.headerClientWidth)
    Log-Assertion -TestId "$idPrefix-03" -Category "DesktopNav-Left" `
        -Description "Left layout at ${vp}px: Zero horizontal overflow in header and document" `
        -Passed $noOverflow `
        -Expected "scrollWidth <= clientWidth (<= ${vp}px)" `
        -Actual "header: $($m.headerScrollWidth)/$($m.headerClientWidth), doc: $($m.docScrollWidth)/$($m.docClientWidth)"

    # 4. Nav is positioned between logo and actions
    $isOrdered = ($m.logoRect.right -le $m.navRect.left) -and ($m.navRect.right -le ($m.actionsRect.left + 5))
    Log-Assertion -TestId "$idPrefix-04" -Category "DesktopNav-Left" `
        -Description "Left layout at ${vp}px: Logo (col 1), Nav (col 2), and Actions (col 3) horizontal ordering" `
        -Passed $isOrdered `
        -Expected "logo.right <= nav.left <= actions.left" `
        -Actual "logo.right=$($m.logoRect.right), nav.left=$($m.navRect.left), nav.right=$($m.navRect.right), actions.left=$($m.actionsRect.left)"

    # 5. All 5 nav links rendered with positive dimensions
    $linksValid = ($m.navLinks.Count -eq 5) -and ($m.navLinks | Where-Object { $_.rect.width -gt 0 -and $_.rect.height -gt 0 }).Count -eq 5
    Log-Assertion -TestId "$idPrefix-05" -Category "DesktopNav-Left" `
        -Description "Left layout at ${vp}px: All 5 nav links rendered and visible (Shop, Espresso Tools, Coffee Station, Brewing, About)" `
        -Passed $linksValid `
        -Expected "5 links with positive dimensions" `
        -Actual "$($m.navLinks.Count) links visible"
}

# --- 2.2 CENTER LAYOUT ON DESKTOP ---
foreach ($vp in @(1024, 1280, 1440)) {
    $m = $desktopMetrics."center_$vp"
    $idPrefix = "S2-C$vp"

    # 1. Nav is displayed as flex
    Log-Assertion -TestId "$idPrefix-01" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: Desktop nav is displayed (display: flex)" `
        -Passed ($m.navComputedDisplay -eq 'flex') `
        -Expected "'flex'" `
        -Actual "'$($m.navComputedDisplay)'"

    # 2. Hamburger toggle is hidden
    Log-Assertion -TestId "$idPrefix-02" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: Hamburger menu toggle is hidden (display: none)" `
        -Passed ($m.toggleComputedDisplay -eq 'none') `
        -Expected "'none'" `
        -Actual "'$($m.toggleComputedDisplay)'"

    # 3. Zero horizontal overflow
    $noOverflow = (-not $m.hasDocOverflow) -and (-not $m.hasHeaderOverflow) -and ($m.headerScrollWidth -le $m.headerClientWidth)
    Log-Assertion -TestId "$idPrefix-03" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: Zero horizontal overflow in header and document" `
        -Passed $noOverflow `
        -Expected "scrollWidth <= clientWidth (<= ${vp}px)" `
        -Actual "header: $($m.headerScrollWidth)/$($m.headerClientWidth), doc: $($m.docScrollWidth)/$($m.docClientWidth)"

    # 4. Logo is centered horizontally (delta < 20px relative to header midpoint)
    $logoCentered = $m.logoCenterDelta -ne $null -and $m.logoCenterDelta -lt 20
    Log-Assertion -TestId "$idPrefix-04" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: Logo is centered in header row (center delta < 20px)" `
        -Passed $logoCentered `
        -Expected "center delta < 20px" `
        -Actual "delta = $($m.logoCenterDelta)px"

    # 5. Nav occupies dedicated centered row below the logo
    $navRowValid = $m.isNavBelowLogo -and ($m.navComputedJustify -eq 'center')
    Log-Assertion -TestId "$idPrefix-05" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: Nav is in dedicated row below logo with justify-content: center" `
        -Passed $navRowValid `
        -Expected "isNavBelowLogo: True, justify-content: 'center'" `
        -Actual "isNavBelowLogo: $($m.isNavBelowLogo), justify-content: '$($m.navComputedJustify)'"

    # 6. All 5 nav links rendered with positive dimensions
    $linksValid = ($m.navLinks.Count -eq 5) -and ($m.navLinks | Where-Object { $_.rect.width -gt 0 -and $_.rect.height -gt 0 }).Count -eq 5
    Log-Assertion -TestId "$idPrefix-06" -Category "DesktopNav-Center" `
        -Description "Center layout at ${vp}px: All 5 nav links rendered and visible" `
        -Passed $linksValid `
        -Expected "5 links with positive dimensions" `
        -Actual "$($m.navLinks.Count) links visible"
}

# --- 2.3 STICKY COMPACT STATE ON DESKTOP ---
$mLeftSticky = $desktopMetrics."left_sticky_1280"
$mCenterSticky = $desktopMetrics."center_sticky_1280"

Log-Assertion -TestId "S2-STK-01" -Category "StickyHeader" `
    -Description "Left layout scrolled: Zero horizontal overflow with .header-wrapper--scrolled at 1280px" `
    -Passed (-not $mLeftSticky.hasHeaderOverflow -and $mLeftSticky.headerScrollWidth -le $mLeftSticky.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($mLeftSticky.headerScrollWidth), clientWidth=$($mLeftSticky.headerClientWidth)"

Log-Assertion -TestId "S2-STK-02" -Category "StickyHeader" `
    -Description "Center layout scrolled: Zero horizontal overflow with .header-wrapper--scrolled at 1280px" `
    -Passed (-not $mCenterSticky.hasHeaderOverflow -and $mCenterSticky.headerScrollWidth -le $mCenterSticky.headerClientWidth) `
    -Expected "header scrollWidth <= clientWidth" `
    -Actual "scrollWidth=$($mCenterSticky.headerScrollWidth), clientWidth=$($mCenterSticky.headerClientWidth)"

Log-Assertion -TestId "S2-STK-03" -Category "StickyHeader" `
    -Description "Center layout scrolled: Nav remains in dedicated row below centered logo when scrolled" `
    -Passed ($mCenterSticky.isNavBelowLogo -and $mCenterSticky.logoCenterDelta -lt 20) `
    -Expected "isNavBelowLogo: True, delta < 20px" `
    -Actual "isNavBelowLogo=$($mCenterSticky.isNavBelowLogo), delta=$($mCenterSticky.logoCenterDelta)px"


# ------------------------------------------------------------------------------
# BATCH 2: MOBILE VIEWPORTS & TOUCH TARGETS STRESS TEST
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Empirical Mobile Viewport & Touch Target Stress Test (Left & Center) ---" -ForegroundColor Yellow

$mobileParentSrc = Get-Content -Raw -Encoding UTF8 (Join-Path $RepoRoot "tests/m2_stress_mobile_parent.html")
$mobileParentPath = Join-Path $tempDir "m2_stress_mobile_parent.html"
[System.IO.File]::WriteAllText($mobileParentPath, $mobileParentSrc, [System.Text.Encoding]::UTF8)

$mobileOutFile = Join-Path $tempDir "m2_edge_mobile_out.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--window-size=1920,1080", "--virtual-time-budget=8000", "--dump-dom", $mobileParentPath -RedirectStandardOutput $mobileOutFile -Wait

$mobileRawOut = [System.IO.File]::ReadAllText($mobileOutFile, [System.Text.Encoding]::UTF8)
Remove-Item $mobileParentPath, $mobileOutFile -Force -ErrorAction SilentlyContinue
Remove-Item $pathLeftNormal, $pathLeftSticky, $pathCenterNormal, $pathCenterSticky -Force -ErrorAction SilentlyContinue

$mobileMetrics = $null
if ($mobileRawOut -match '<pre id="results">([\s\S]*?)</pre>') {
    $rawJson = $matches[1].Replace('<br>', "`n").Trim()
    try {
        $mobileMetrics = $rawJson | ConvertFrom-Json
    } catch {
        Write-Host "Mobile JSON parse error: $_" -ForegroundColor Red
    }
}

if ($mobileMetrics -eq $null) {
    Write-Host "FATAL: Failed to collect mobile browser metrics via Edge." -ForegroundColor Red
    exit 1
}

# --- 3.1 LEFT LAYOUT ON MOBILE & TABLET VIEWPORTS ---
foreach ($vp in @(320, 375, 390, 414, 768)) {
    $m = $mobileMetrics."left_$vp"
    $idPrefix = "S3-L$vp"

    # Header overflow
    Log-Assertion -TestId "$idPrefix-01" -Category "MobileOverflow-Left" `
        -Description "Left layout at ${vp}px: Zero Header Horizontal Overflow" `
        -Passed (-not $m.hasHeaderOverflow -and $m.headerScrollWidth -le $m.headerClientWidth) `
        -Expected "header scrollWidth <= clientWidth (<= ${vp}px)" `
        -Actual "scrollWidth=$($m.headerScrollWidth), clientWidth=$($m.headerClientWidth)"

    # Document overflow (for standard mobile >= 375px)
    if ($vp -ge 375) {
        Log-Assertion -TestId "$idPrefix-02" -Category "MobileOverflow-Left" `
            -Description "Left layout at ${vp}px: Zero Document Horizontal Overflow" `
            -Passed (-not $m.hasDocOverflow -and $m.docScrollWidth -le $m.docClientWidth) `
            -Expected "doc scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.docScrollWidth), clientWidth=$($m.docClientWidth)"

        Log-Assertion -TestId "$idPrefix-03" -Category "MobileOverflow-Left" `
            -Description "Left layout at ${vp}px: Zero Announcement Bar Horizontal Overflow" `
            -Passed (-not $m.hasAnnOverflow -and $m.annScrollWidth -le $m.annClientWidth) `
            -Expected "ann scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.annScrollWidth), clientWidth=$($m.annClientWidth)"

        Log-Assertion -TestId "$idPrefix-04" -Category "MobileOverflow-Left" `
            -Description "Left layout at ${vp}px: Zero Menu Drawer Horizontal Overflow" `
            -Passed (-not $m.hasDrawerOverflow -and $m.drawerScrollWidth -le $m.drawerClientWidth) `
            -Expected "drawer scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.drawerScrollWidth), clientWidth=$($m.drawerClientWidth)"
    }

    # Desktop nav is hidden on mobile/tablet (< 990px)
    Log-Assertion -TestId "$idPrefix-05" -Category "MobileNavState-Left" `
        -Description "Left layout at ${vp}px: Desktop nav is hidden (display: none)" `
        -Passed ($m.navComputedDisplay -eq 'none') `
        -Expected "'none'" `
        -Actual "'$($m.navComputedDisplay)'"

    # Hamburger menu toggle is visible on mobile/tablet (< 990px)
    Log-Assertion -TestId "$idPrefix-06" -Category "MobileNavState-Left" `
        -Description "Left layout at ${vp}px: Hamburger menu toggle is visible (display != 'none')" `
        -Passed ($m.toggleComputedDisplay -ne 'none') `
        -Expected "display != 'none'" `
        -Actual "'$($m.toggleComputedDisplay)'"
}

# --- 3.2 CENTER LAYOUT ON MOBILE & TABLET VIEWPORTS ---
foreach ($vp in @(320, 375, 390, 414, 768)) {
    $m = $mobileMetrics."center_$vp"
    $idPrefix = "S3-C$vp"

    # Header overflow
    Log-Assertion -TestId "$idPrefix-01" -Category "MobileOverflow-Center" `
        -Description "Center layout at ${vp}px: Zero Header Horizontal Overflow" `
        -Passed (-not $m.hasHeaderOverflow -and $m.headerScrollWidth -le $m.headerClientWidth) `
        -Expected "header scrollWidth <= clientWidth (<= ${vp}px)" `
        -Actual "scrollWidth=$($m.headerScrollWidth), clientWidth=$($m.headerClientWidth)"

    # Document overflow (for standard mobile >= 375px)
    if ($vp -ge 375) {
        Log-Assertion -TestId "$idPrefix-02" -Category "MobileOverflow-Center" `
            -Description "Center layout at ${vp}px: Zero Document Horizontal Overflow" `
            -Passed (-not $m.hasDocOverflow -and $m.docScrollWidth -le $m.docClientWidth) `
            -Expected "doc scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.docScrollWidth), clientWidth=$($m.docClientWidth)"

        Log-Assertion -TestId "$idPrefix-03" -Category "MobileOverflow-Center" `
            -Description "Center layout at ${vp}px: Zero Announcement Bar Horizontal Overflow" `
            -Passed (-not $m.hasAnnOverflow -and $m.annScrollWidth -le $m.annClientWidth) `
            -Expected "ann scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.annScrollWidth), clientWidth=$($m.annClientWidth)"

        Log-Assertion -TestId "$idPrefix-04" -Category "MobileOverflow-Center" `
            -Description "Center layout at ${vp}px: Zero Menu Drawer Horizontal Overflow" `
            -Passed (-not $m.hasDrawerOverflow -and $m.drawerScrollWidth -le $m.drawerClientWidth) `
            -Expected "drawer scrollWidth <= clientWidth" `
            -Actual "scrollWidth=$($m.drawerScrollWidth), clientWidth=$($m.drawerClientWidth)"
    }

    # Desktop nav is hidden on mobile/tablet (< 990px)
    Log-Assertion -TestId "$idPrefix-05" -Category "MobileNavState-Center" `
        -Description "Center layout at ${vp}px: Desktop nav is hidden (display: none)" `
        -Passed ($m.navComputedDisplay -eq 'none') `
        -Expected "'none'" `
        -Actual "'$($m.navComputedDisplay)'"

    # Hamburger menu toggle is visible on mobile/tablet (< 990px)
    Log-Assertion -TestId "$idPrefix-06" -Category "MobileNavState-Center" `
        -Description "Center layout at ${vp}px: Hamburger menu toggle is visible (display != 'none')" `
        -Passed ($m.toggleComputedDisplay -ne 'none') `
        -Expected "display != 'none'" `
        -Actual "'$($m.toggleComputedDisplay)'"
}

# --- 3.3 TOUCH TARGET MEASUREMENTS (>= 44px x 44px) ---
Write-Host "`n--- [SUITE 4] Touch Target Measurements on Mobile (375px) ---" -ForegroundColor Yellow

# Measure touch targets for Left layout (375px)
$tLeft = $mobileMetrics."left_375".targets

Log-Assertion -TestId "S4-L-01" -Category "TouchTarget-Left" `
    -Description "Left layout: Header Menu Toggle button >= 44x44px" `
    -Passed ($tLeft.menuToggle.width -ge 44 -and $tLeft.menuToggle.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tLeft.menuToggle.width)x$($tLeft.menuToggle.height)px"

Log-Assertion -TestId "S4-L-02" -Category "TouchTarget-Left" `
    -Description "Left layout: Header Search button >= 44x44px" `
    -Passed ($tLeft.headerSearch.width -ge 44 -and $tLeft.headerSearch.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tLeft.headerSearch.width)x$($tLeft.headerSearch.height)px"

Log-Assertion -TestId "S4-L-03" -Category "TouchTarget-Left" `
    -Description "Left layout: Header Account button >= 44x44px" `
    -Passed ($tLeft.headerAccount.width -ge 44 -and $tLeft.headerAccount.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tLeft.headerAccount.width)x$($tLeft.headerAccount.height)px"

Log-Assertion -TestId "S4-L-04" -Category "TouchTarget-Left" `
    -Description "Left layout: Cart Icon Bubble button >= 44x44px" `
    -Passed ($tLeft.cartBubble.width -ge 44 -and $tLeft.cartBubble.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tLeft.cartBubble.width)x$($tLeft.cartBubble.height)px"

# Measure touch targets for Center layout (375px)
$tCenter = $mobileMetrics."center_375".targets

Log-Assertion -TestId "S4-C-01" -Category "TouchTarget-Center" `
    -Description "Center layout: Header Menu Toggle button (left cluster) >= 44x44px" `
    -Passed ($tCenter.menuToggle.width -ge 44 -and $tCenter.menuToggle.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tCenter.menuToggle.width)x$($tCenter.menuToggle.height)px"

Log-Assertion -TestId "S4-C-02" -Category "TouchTarget-Center" `
    -Description "Center layout: Header Search button (left cluster) >= 44x44px" `
    -Passed ($tCenter.headerSearch.width -ge 44 -and $tCenter.headerSearch.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tCenter.headerSearch.width)x$($tCenter.headerSearch.height)px"

Log-Assertion -TestId "S4-C-03" -Category "TouchTarget-Center" `
    -Description "Center layout: Header Account button (right cluster) >= 44x44px" `
    -Passed ($tCenter.headerAccount.width -ge 44 -and $tCenter.headerAccount.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tCenter.headerAccount.width)x$($tCenter.headerAccount.height)px"

Log-Assertion -TestId "S4-C-04" -Category "TouchTarget-Center" `
    -Description "Center layout: Cart Icon Bubble button (right cluster) >= 44x44px" `
    -Passed ($tCenter.cartBubble.width -ge 44 -and $tCenter.cartBubble.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tCenter.cartBubble.width)x$($tCenter.cartBubble.height)px"

# Drawer common touch targets
Log-Assertion -TestId "S4-DW-01" -Category "TouchTarget-Drawer" `
    -Description "Menu Drawer Close button >= 44x44px" `
    -Passed ($tLeft.drawerClose.width -ge 44 -and $tLeft.drawerClose.height -ge 44) `
    -Expected ">= 44x44px" `
    -Actual "$($tLeft.drawerClose.width)x$($tLeft.drawerClose.height)px"

Log-Assertion -TestId "S4-DW-02" -Category "TouchTarget-Drawer" `
    -Description "Menu Drawer Search CTA button min-height >= 44px" `
    -Passed ($tLeft.drawerSearchBtn.height -ge 44) `
    -Expected ">= 44px" `
    -Actual "$($tLeft.drawerSearchBtn.height)px"

Log-Assertion -TestId "S4-DW-03" -Category "TouchTarget-Drawer" `
    -Description "Menu Drawer Account / Login button min-height >= 44px" `
    -Passed ($tLeft.drawerAccountBtn.height -ge 44) `
    -Expected ">= 44px" `
    -Actual "$($tLeft.drawerAccountBtn.height)px"

Log-Assertion -TestId "S4-DW-04" -Category "TouchTarget-Drawer" `
    -Description "Menu Drawer Nested Summary accordion toggle min-height >= 44px" `
    -Passed ($tLeft.drawerSummary.height -ge 44) `
    -Expected ">= 44px" `
    -Actual "$($tLeft.drawerSummary.height)px"

Log-Assertion -TestId "S4-DW-05" -Category "TouchTarget-Drawer" `
    -Description "Menu Drawer Sublink item min-height >= 44px" `
    -Passed ($tLeft.drawerSublink.height -ge 44) `
    -Expected ">= 44px" `
    -Actual "$($tLeft.drawerSublink.height)px"

$allDrawerLinksPass = ($tLeft.drawerLinks.Count -eq 5) -and (($tLeft.drawerLinks | Where-Object { $_.height -ge 44 }).Count -eq 5)
Log-Assertion -TestId "S4-DW-06" -Category "TouchTarget-Drawer" `
    -Description "All 5 Menu Drawer Fallback Links have min-height >= 44px" `
    -Passed $allDrawerLinksPass `
    -Expected "All 5 links >= 44px height" `
    -Actual "$($tLeft.drawerLinks.Count) links checked, all >= 44px: $allDrawerLinksPass"


# ------------------------------------------------------------------------------
# FINAL REPORT & VERDICT EVALUATION
# ------------------------------------------------------------------------------
$totalTests = $Report.Count
$passedCount = ($Report | Where-Object { $_.Passed }).Count
$failedCount = ($Report | Where-Object { -not $_.Passed }).Count
$passRate = if ($totalTests -gt 0) { [Math]::Round(($passedCount / $totalTests) * 100, 1) } else { 0 }

$criticalFailures = ($Report | Where-Object { -not $_.Passed -and $_.Severity -in @("CRITICAL","HIGH") }).Count
$verdict = if ($criticalFailures -eq 0 -and $passRate -eq 100.0) { "APPROVE" } else { "CHALLENGE_FAILED" }

Write-Host "`======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M2-IT2-1 STRESS-TEST RESULTS SUMMARY                   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "  TOTAL ASSERTIONS: $totalTests"
Write-Host "  PASSED:           $passedCount" -ForegroundColor Green
Write-Host "  FAILED:           $failedCount" -ForegroundColor $(if ($failedCount -eq 0) { "Green" } else { "Red" })
Write-Host "  COMPLIANCE RATE:  $passRate%"

$verdictColor = if ($verdict -eq "APPROVE") { "Green" } else { "Red" }
Write-Host "`n  FORMAL VERDICT:   $verdict" -ForegroundColor $verdictColor
Write-Host "======================================================================`n" -ForegroundColor Cyan

return [PSCustomObject]@{
    TotalTests = $totalTests
    Passed     = $passedCount
    Failed     = $failedCount
    PassRate   = $passRate
    Verdict    = $verdict
    Report     = $Report
}
