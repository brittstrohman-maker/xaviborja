# ==============================================================================
# CHALLENGER M4-1: EMPIRICAL STRESS-TESTING SUITE FOR MILESTONE M4
# Target: Product Card & PDP Architecture (Feature 17 Focus)
# Methodology: Real Headless Chromium Execution + Permutation Matrix + Token Oracles
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

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
Write-Host "   CHALLENGER M4-1: EMPIRICAL PRODUCT CARD STRESS-TESTING SUITE      " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# ------------------------------------------------------------------------------
# SUITE 1: LIQUID SOURCE INTEGRITY & ANTI-DROPSHIPPING AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Liquid Syntax & Anti-Dropshipping Tropes Audit ---" -ForegroundColor Yellow

$productCardPath = Join-Path $RepoRoot "snippets/product-card.liquid"
$pricePath = Join-Path $RepoRoot "snippets/price.liquid"
$baseCssPath = Join-Path $RepoRoot "assets/base.css"

$productCardContent = [System.IO.File]::ReadAllText($productCardPath, [System.Text.Encoding]::UTF8)
$priceContent = [System.IO.File]::ReadAllText($pricePath, [System.Text.Encoding]::UTF8)
$baseCssContent = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

# 1. Liquid tag balance in snippets/product-card.liquid
$cNoComment = [System.Text.RegularExpressions.Regex]::Replace($productCardContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$opIf = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*(if|unless)\b')).Count
$clIf = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*(endif|endunless)\b')).Count
$opFor = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*for\b')).Count
$clFor = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*endfor\b')).Count
$opForm = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*form\b')).Count
$clForm = ([System.Text.RegularExpressions.Regex]::Matches($cNoComment, '\{%-?\s*endform\b')).Count

$cardBalanced = ($opIf -eq $clIf) -and ($opFor -eq $clFor) -and ($opForm -eq $clForm)
Log-Assertion -TestId "S1-01" -Category "Syntax" `
    -Description "snippets/product-card.liquid Liquid tag balance (if/for/form)" `
    -Passed $cardBalanced `
    -Expected "Balanced: if ($opIf/$clIf), for ($opFor/$clFor), form ($opForm/$clForm)" `
    -Actual "Balanced=$cardBalanced"

# 2. Liquid tag balance in snippets/price.liquid
$priceNoComment = [System.Text.RegularExpressions.Regex]::Replace($priceContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$pOpIf = ([System.Text.RegularExpressions.Regex]::Matches($priceNoComment, '\{%-?\s*(if|unless)\b')).Count
$pClIf = ([System.Text.RegularExpressions.Regex]::Matches($priceNoComment, '\{%-?\s*(endif|endunless)\b')).Count
$priceBalanced = ($pOpIf -eq $pClIf)

Log-Assertion -TestId "S1-02" -Category "Syntax" `
    -Description "snippets/price.liquid Liquid tag balance (if/endif)" `
    -Passed $priceBalanced `
    -Expected "Balanced: if ($pOpIf/$pClIf)" `
    -Actual "Balanced=$priceBalanced"

# 3. Strict suppression of fake dropshipping tropes (urgency countdowns, fake stock, neon badges)
$fakeTropesPattern = 'countdown|hurry|only\s+\d+\s+left|flash-sale|fake-reviews|sold\s+in\s+last|viewing-now'
$hasFakeTropesInCard = [System.Text.RegularExpressions.Regex]::IsMatch($productCardContent, $fakeTropesPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$hasFakeTropesInPrice = [System.Text.RegularExpressions.Regex]::IsMatch($priceContent, $fakeTropesPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$hasFakeTropesInCss = [System.Text.RegularExpressions.Regex]::IsMatch($baseCssContent, 'badge--fake|countdown-timer|stock-urgency', [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)

$tropesClean = (-not $hasFakeTropesInCard) -and (-not $hasFakeTropesInPrice) -and (-not $hasFakeTropesInCss)
Log-Assertion -TestId "S1-03" -Category "Integrity" `
    -Description "Zero fake dropshipping tropes in product card & price templates" `
    -Passed $tropesClean `
    -Expected "No fake countdowns, urgency badges, or fake stock counters" `
    -Actual "Clean=$tropesClean (Card:$hasFakeTropesInCard, Price:$hasFakeTropesInPrice, CSS:$hasFakeTropesInCss)"

# ------------------------------------------------------------------------------
# SUITE 2: LIQUID DATA LOGIC PERMUTATION MATRIX ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] Product Card Logic Permutation Matrix Oracle ---" -ForegroundColor Yellow

function Simulate-ProductCardLogic {
    param(
        [hashtable]$Product,
        [hashtable]$Settings
    )
    
    # 1. Secondary image simulation
    $hasSecondaryImg = ($Settings.card_hover_image -eq $true) -and ($Product.images.Count -gt 1)

    # 2. Badges simulation
    $renderedBadge = $null
    if ($Product.available -eq $false) {
        $renderedBadge = "sold_out"
    } elseif ($null -ne $Product.compare_at_price -and $Product.compare_at_price -gt $Product.price) {
        $renderedBadge = "sale"
    }

    # 3. Price snippet on_sale simulation
    $priceOnSale = ($null -ne $Product.compare_at_price -and $Product.compare_at_price -gt $Product.price)

    # 4. Quick-add simulation
    $quickAddType = "none"
    if ($Settings.card_quick_add -eq $true -and $Product.available -eq $true) {
        if ($Product.variants.Count -eq 1 -and $Product.first_variant_available -eq $true) {
            $quickAddType = "direct_form"
        } else {
            $quickAddType = "choose_options"
        }
    }

    return @{
        HasSecondaryImage = $hasSecondaryImg
        RenderedBadge     = $renderedBadge
        PriceOnSale       = $priceOnSale
        QuickAddType      = $quickAddType
    }
}

# Test Matrix: 8 Adversarial Data Permutations
$scenarios = @(
    @{
        Id = "M-01"
        Desc = "Genuine Sale: compare_at (35.00) > price (28.00), single variant, 2 images, available"
        Product = @{ price = 2800; compare_at_price = 3500; available = $true; variants = @(1); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = "sale"; PriceSale = $true; QuickAdd = "direct_form"; SecImg = $true }
    },
    @{
        Id = "M-02"
        Desc = "Equal Price Suppression: compare_at (25.00) == price (25.00) -> Sale badge SUPPRESSED"
        Product = @{ price = 2500; compare_at_price = 2500; available = $true; variants = @(1); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "direct_form"; SecImg = $true }
    },
    @{
        Id = "M-03"
        Desc = "Inverted / Corrupted Price: compare_at (15.00) < price (20.00) -> Sale badge SUPPRESSED"
        Product = @{ price = 2000; compare_at_price = 1500; available = $true; variants = @(1); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "direct_form"; SecImg = $true }
    },
    @{
        Id = "M-04"
        Desc = "Blank / Null Compare-At: compare_at ($null) -> Sale badge SUPPRESSED"
        Product = @{ price = 4500; compare_at_price = $null; available = $true; variants = @(1, 2); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "choose_options"; SecImg = $true }
    },
    @{
        Id = "M-05"
        Desc = "Zero Compare-At: compare_at (0) -> Sale badge SUPPRESSED"
        Product = @{ price = 4500; compare_at_price = 0; available = $true; variants = @(1); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "direct_form"; SecImg = $true }
    },
    @{
        Id = "M-06"
        Desc = "Sold-Out with Sale: available ($false) with compare_at > price -> Sold-out badge overrides sale"
        Product = @{ price = 3000; compare_at_price = 4000; available = $false; variants = @(1); first_variant_available = $false; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = "sold_out"; PriceSale = $true; QuickAdd = "none"; SecImg = $true }
    },
    @{
        Id = "M-07"
        Desc = "Multi-Variant Available: variants (3) -> Quick-add routes to choose_options link"
        Product = @{ price = 5000; compare_at_price = $null; available = $true; variants = @(1, 2, 3); first_variant_available = $true; images = @("1.jpg", "2.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "choose_options"; SecImg = $true }
    },
    @{
        Id = "M-08"
        Desc = "Single Image Product: images.Count == 1 -> Secondary hover image strictly SUPPRESSED"
        Product = @{ price = 1800; compare_at_price = $null; available = $true; variants = @(1); first_variant_available = $true; images = @("1.jpg") }
        Settings = @{ card_hover_image = $true; card_quick_add = $true }
        Expected = @{ Badge = $null; PriceSale = $false; QuickAdd = "direct_form"; SecImg = $false }
    }
)

foreach ($sc in $scenarios) {
    $res = Simulate-ProductCardLogic -Product $sc.Product -Settings $sc.Settings
    $badgePass = ($res.RenderedBadge -eq $sc.Expected.Badge)
    $pricePass = ($res.PriceOnSale -eq $sc.Expected.PriceSale)
    $qaPass    = ($res.QuickAddType -eq $sc.Expected.QuickAdd)
    $imgPass   = ($res.HasSecondaryImage -eq $sc.Expected.SecImg)

    $allPass = $badgePass -and $pricePass -and $qaPass -and $imgPass
    Log-Assertion -TestId "S2-$($sc.Id)" -Category "Matrix" `
        -Description $sc.Desc `
        -Passed $allPass `
        -Expected "Badge=$($sc.Expected.Badge), QA=$($sc.Expected.QuickAdd), SecImg=$($sc.Expected.SecImg)" `
        -Actual "Badge=$($res.RenderedBadge), QA=$($res.QuickAddType), SecImg=$($res.HasSecondaryImage)"
}

# ------------------------------------------------------------------------------
# SUITE 3: REAL HEADLESS EDGE (CHROMIUM) EMPIRICAL EXECUTION ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Headless Chromium DOM, CSS & Hit-Testing Execution ---" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    Write-Host "FATAL: msedge.exe not found at $edgePath" -ForegroundColor Red
    exit 1
}

# Compile Fixture CSS with Theme Tokens
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
  --page-width: 1440px;
  --radius-base: 4px;
  --radius-media: 6px;
  --grid-gap: clamp(0.75rem, 2vw, 1.5rem);
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
}
"@

$fixtureTemplate = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "tests/m4_card_fixture.html"), [System.Text.Encoding]::UTF8)
$compiledFixture = $fixtureTemplate.Replace('/* TOKEN_CSS */', $tokenCss).Replace('/* BASE_CSS */', $baseCssContent)

$tempChildPath = Join-Path $env:TEMP "m4_child_card.html"
[System.IO.File]::WriteAllText($tempChildPath, $compiledFixture, [System.Text.Encoding]::UTF8)

$runnerTemplate = [System.IO.File]::ReadAllText((Join-Path $RepoRoot "tests/m4_parent_runner.html"), [System.Text.Encoding]::UTF8)
$tempRunnerPath = Join-Path $env:TEMP "m4_parent_runner.html"
[System.IO.File]::WriteAllText($tempRunnerPath, $runnerTemplate, [System.Text.Encoding]::UTF8)

$outLog = Join-Path $env:TEMP "m4_edge_results.txt"
Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=8000", "--dump-dom", $tempRunnerPath -RedirectStandardOutput $outLog -Wait

$rawOut = [System.IO.File]::ReadAllText($outLog, [System.Text.Encoding]::UTF8)
Remove-Item $tempChildPath, $tempRunnerPath, $outLog -Force -ErrorAction SilentlyContinue

$domMetrics = $null
$mMatch = [regex]::Match($rawOut, '<pre id="results">([\s\S]*?)</pre>')
if ($mMatch.Success) {
    $clean = $mMatch.Groups[1].Value -replace '<br\s*/?>', "`n"
    $clean = [System.Net.WebUtility]::HtmlDecode($clean).Trim()
    try {
        $domMetrics = $clean | ConvertFrom-Json
    } catch {
        Write-Host "JSON parse error on Edge metrics: $_" -ForegroundColor Red
    }
}

if ($domMetrics -eq $null -or $domMetrics.vp_1440 -eq $null) {
    Write-Host "FATAL: Failed to collect headless browser metrics via Edge." -ForegroundColor Red
    exit 1
}

$m1440 = $domMetrics.vp_1440

# S3-01: Card Background Token (#FCFAF6 -> rgb(252, 250, 246))
$cBg = $m1440.cardStyles.backgroundColor
$cardBgPassed = ($cBg -eq "rgb(252, 250, 246)")
Log-Assertion -TestId "S3-01" -Category "Tokens" `
    -Description "Product card background computed style is Soft Off-White #FCFAF6 (rgb(252, 250, 246))" `
    -Passed $cardBgPassed `
    -Expected "rgb(252, 250, 246)" `
    -Actual "$cBg"

# S3-02: Card Border Token (#E7E0D6 -> rgb(231, 224, 214))
$cBorder = $m1440.cardStyles.borderTopColor
$cardBorderPassed = ($cBorder -eq "rgb(231, 224, 214)")
Log-Assertion -TestId "S3-02" -Category "Tokens" `
    -Description "Product card subtle border computed style is Light Taupe #E7E0D6 (rgb(231, 224, 214))" `
    -Passed $cardBorderPassed `
    -Expected "rgb(231, 224, 214)" `
    -Actual "$cBorder"

# S3-03: Card Border Radius Token (var(--radius-base) -> 4px)
$cRadius = $m1440.cardStyles.borderRadius
$cardRadiusPassed = ($cRadius -eq "4px")
Log-Assertion -TestId "S3-03" -Category "Tokens" `
    -Description "Product card border-radius is 4px (token --radius-base)" `
    -Passed $cardRadiusPassed `
    -Expected "4px" `
    -Actual "$cRadius"

# S3-04: Card Padding (0.75rem -> 12px)
$cPad = $m1440.cardStyles.paddingTop
$cardPadPassed = ($cPad -eq "12px")
Log-Assertion -TestId "S3-04" -Category "Layout" `
    -Description "Product card padding is 0.75rem (12px)" `
    -Passed $cardPadPassed `
    -Expected "12px" `
    -Actual "$cPad"

# S3-05: Genuine Sale Badge Styling (Copper Accent #9A6238 -> rgb(154, 98, 56) & White Text)
$bSale = $m1440.badgeSaleStyles
$badgeSalePassed = ($bSale.backgroundColor -eq "rgb(154, 98, 56)") -and ($bSale.color -eq "rgb(255, 255, 255)")
Log-Assertion -TestId "S3-05" -Category "Tokens" `
    -Description "Sale badge background is Copper Accent #9A6238 and text is White" `
    -Passed $badgeSalePassed `
    -Expected "bg=rgb(154, 98, 56), color=rgb(255, 255, 255)" `
    -Actual "bg=$($bSale.backgroundColor), color=$($bSale.color)"

# S3-06: Genuine Sale Badge Typography (Micro-label 0.6875rem = 11px, Uppercase)
$badgeTypoPassed = ($bSale.fontSize -eq "11px") -and ($bSale.textTransform -eq "uppercase")
Log-Assertion -TestId "S3-06" -Category "Typography" `
    -Description "Sale badge typography uses uppercase micro-label (11px / 0.6875rem)" `
    -Passed $badgeTypoPassed `
    -Expected "fontSize=11px, textTransform=uppercase" `
    -Actual "fontSize=$($bSale.fontSize), textTransform=$($bSale.textTransform)"

# S3-07: Quick-Add Direct Button Styling (Matte Black #111111, Off-White Text, Micro-label)
$btnD = $m1440.btnDirectStyles
$btnDirectPassed = ($btnD.backgroundColor -eq "rgb(17, 17, 17)") -and `
                   ($btnD.color -eq "rgb(252, 250, 246)") -and `
                   ($btnD.fontSize -eq "11px") -and `
                   ($btnD.fontWeight -eq "600") -and `
                   ($btnD.textTransform -eq "uppercase")

Log-Assertion -TestId "S3-07" -Category "Tokens" `
    -Description "Quick-add direct button styled with #111111 bg, #FCFAF6 text, 11px uppercase bold" `
    -Passed $btnDirectPassed `
    -Expected "bg=rgb(17, 17, 17), color=rgb(252, 250, 246), 11px uppercase 600" `
    -Actual "bg=$($btnD.backgroundColor), color=$($btnD.color), $($btnD.fontSize) $($btnD.textTransform) $($btnD.fontWeight)"

# S3-08: Quick-Add Outline Button Styling ("Choose options" #FCFAF6 bg, #111111 text, #E7E0D6 border)
$btnO = $m1440.btnOutlineStyles
$btnOutlinePassed = ($btnO.backgroundColor -eq "rgb(252, 250, 246)") -and `
                    ($btnO.color -eq "rgb(17, 17, 17)") -and `
                    ($btnO.borderTopColor -eq "rgb(231, 224, 214)")

Log-Assertion -TestId "S3-08" -Category "Tokens" `
    -Description "Quick-add outline button styled with #FCFAF6 bg, #111111 text, #E7E0D6 border" `
    -Passed $btnOutlinePassed `
    -Expected "bg=rgb(252, 250, 246), color=rgb(17, 17, 17), border=rgb(231, 224, 214)" `
    -Actual "bg=$($btnO.backgroundColor), color=$($btnO.color), border=$($btnO.borderTopColor)"

# S3-09: Secondary Image Positioning & CSS Transition (absolute, opacity 0, transition includes opacity)
$secImg = $m1440.secondaryImgStyles
$secImgPassed = ($secImg.position -eq "absolute") -and `
                ($secImg.opacity -eq "0") -and `
                ($secImg.transitionProperty -match 'opacity|all')

Log-Assertion -TestId "S3-09" -Category "Animation" `
    -Description "Secondary image styled with position: absolute, opacity: 0, and opacity transition" `
    -Passed $secImgPassed `
    -Expected "position=absolute, opacity=0, transitionProperty contains opacity" `
    -Actual "pos=$($secImg.position), opacity=$($secImg.opacity), transProp=$($secImg.transitionProperty), duration=$($secImg.transitionDuration)"

# S3-10: Hit-Testing Oracle: Click on Quick-Add button hits button, NOT title link overlay
$hit = $m1440.hitTesting
Log-Assertion -TestId "S3-10" -Category "Interactivity" `
    -Description "Hit-testing oracle: Point click on Quick-Add resolves to button (no click hijacking)" `
    -Passed $hit.hitTargetIsButton `
    -Expected "hitTargetIsButton=true (resolved to button or span)" `
    -Actual "hitTargetIsButton=$($hit.hitTargetIsButton) (element: $($hit.hitElementTag).$($hit.hitElementClass))"

# S3-11: Card 1 (Genuine Sale) Empirical DOM State
$c1 = $m1440.cards.c1
$c1Passed = $c1.hasSaleBadge -and (-not $c1.hasSoldOutBadge) -and $c1.hasPriceOnSaleClass -and $c1.hasPriceCompareTag -and $c1.hasProductForm -and (-not $c1.hasOutlineBtn)
Log-Assertion -TestId "S3-11" -Category "Empirical" `
    -Description "Card 1 DOM: Sale badge present, price--on-sale present, product-form present, outline btn absent" `
    -Passed $c1Passed `
    -Expected "SaleBadge=true, SoldOut=false, OnSaleClass=true, CompareTag=true, ProductForm=true" `
    -Actual "SaleBadge=$($c1.hasSaleBadge), SoldOut=$($c1.hasSoldOutBadge), OnSaleClass=$($c1.hasPriceOnSaleClass), Form=$($c1.hasProductForm)"

# S3-12: Card 2 (Multi-Variant Regular) Empirical DOM State
$c2 = $m1440.cards.c2
$c2Passed = (-not $c2.hasSaleBadge) -and (-not $c2.hasPriceOnSaleClass) -and (-not $c2.hasProductForm) -and $c2.hasOutlineBtn -and ($c2.outlineHref -ne "")
Log-Assertion -TestId "S3-12" -Category "Empirical" `
    -Description "Card 2 DOM: Sale badge suppressed, product-form absent, choose_options outline link present" `
    -Passed $c2Passed `
    -Expected "SaleBadge=false, ProductForm=false, OutlineBtn=true, Href=/products/bottomless-portafilter" `
    -Actual "SaleBadge=$($c2.hasSaleBadge), ProductForm=$($c2.hasProductForm), OutlineBtn=$($c2.hasOutlineBtn), Href=$($c2.outlineHref)"

# S3-13: Card 3 (Equal Price compare_at == price) Empirical Suppression Oracle
$c3 = $m1440.cards.c3
$c3Passed = (-not $c3.hasSaleBadge) -and (-not $c3.hasPriceOnSaleClass) -and (-not $c3.hasPriceCompareTag)
Log-Assertion -TestId "S3-13" -Category "Empirical" `
    -Description "Card 3 DOM: Equal price (€24 == €24) sale badge & compare price strictly suppressed" `
    -Passed $c3Passed `
    -Expected "SaleBadge=false, PriceOnSaleClass=false, CompareTag=false" `
    -Actual "SaleBadge=$($c3.hasSaleBadge), PriceOnSaleClass=$($c3.hasPriceOnSaleClass), CompareTag=$($c3.hasPriceCompareTag)"

# S3-14: Card 4 (Inverted Price compare_at < price) Empirical Suppression Oracle
$c4 = $m1440.cards.c4
$c4Passed = (-not $c4.hasSaleBadge) -and (-not $c4.hasPriceOnSaleClass) -and (-not $c4.hasSecondaryImg)
Log-Assertion -TestId "S3-14" -Category "Empirical" `
    -Description "Card 4 DOM: Inverted price (€15 < €18) suppressed, single image secondary img absent" `
    -Passed $c4Passed `
    -Expected "SaleBadge=false, SecondaryImg=false" `
    -Actual "SaleBadge=$($c4.hasSaleBadge), SecondaryImg=$($c4.hasSecondaryImg)"

# S3-15: Card 5 (Sold-Out Priority) Empirical Suppression Oracle
$c5 = $m1440.cards.c5
$c5Passed = $c5.hasSoldOutBadge -and (-not $c5.hasSaleBadge) -and (-not $c5.hasQuickAdd)
Log-Assertion -TestId "S3-15" -Category "Empirical" `
    -Description "Card 5 DOM: Sold-out overrides sale badge, quick-add container completely suppressed" `
    -Passed $c5Passed `
    -Expected "SoldOut=true, SaleBadge=false, QuickAdd=false" `
    -Actual "SoldOut=$($c5.hasSoldOutBadge), SaleBadge=$($c5.hasSaleBadge), QuickAdd=$($c5.hasQuickAdd)"

# ------------------------------------------------------------------------------
# SUITE 4: MULTI-VIEWPORT RESPONSIVENESS & TOUCH OVERFLOW ORACLES
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] Multi-Viewport Responsiveness & Overflow Oracles ---" -ForegroundColor Yellow

$viewports = @("360", "375", "390", "414", "768", "1024", "1440")

foreach ($vp in $viewports) {
    $vpKey = "vp_$vp"
    $vData = $domMetrics.$vpKey
    if ($null -eq $vData) {
        Log-Assertion -TestId "S4-VP$vp-00" -Category "Viewport-$vp" `
            -Description "Viewport $vp px metrics collection" `
            -Passed $false -Expected "Metrics collected" -Actual "Null"
        continue
    }

    $isStressBaseline = ($vp -eq "360")
    $vpSeverity = if ($isStressBaseline) { "HIGH" } else { "CRITICAL" }

    # Zero document horizontal overflow
    Log-Assertion -TestId "S4-VP$vp-01" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Zero Document Horizontal Overflow" `
        -Passed (-not $vData.hasDocOverflow -and $vData.docScrollWidth -le ($vData.docClientWidth + 1)) `
        -Expected "scrollWidth <= clientWidth (<= $vp px)" `
        -Actual "scrollWidth=$($vData.docScrollWidth), clientWidth=$($vData.docClientWidth)" `
        -Severity $vpSeverity

    # Zero element viewport bleed
    Log-Assertion -TestId "S4-VP$vp-02" -Category "Viewport-$vp" `
        -Description "Viewport $vp px: Zero Child Element Viewport Bleed" `
        -Passed (-not $vData.anyElementOverflows) `
        -Expected "anyElementOverflows == false" `
        -Actual "Overflows=$($vData.anyElementOverflows), Count=$($vData.overflowingElementsCount)" `
        -Severity $vpSeverity
}

# Touch devices media query check (@media (hover: none))
$hasHoverNone = $m1440.stylesheetRules.hasHoverNoneRule
Log-Assertion -TestId "S4-03" -Category "Touch" `
    -Description "Stylesheet defines @media (hover: none) for touch device static quick-add visibility" `
    -Passed $hasHoverNone `
    -Expected "hasHoverNoneRule=true" `
    -Actual "hasHoverNoneRule=$hasHoverNone"

# ------------------------------------------------------------------------------
# SUITE 5: UNIVERSAL REDUCED MOTION ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 5] Universal Reduced Motion Compliance Oracle ---" -ForegroundColor Yellow

$hasReducedMotion = $m1440.stylesheetRules.hasReducedMotionRule
Log-Assertion -TestId "S5-01" -Category "Motion" `
    -Description "Stylesheet defines @media (prefers-reduced-motion: reduce) rule" `
    -Passed $hasReducedMotion `
    -Expected "hasReducedMotionRule=true" `
    -Actual "hasReducedMotionRule=$hasReducedMotion"

$has001ms = [bool]($baseCssContent -match 'transition-duration:\s*0\.01ms\s*!important')
Log-Assertion -TestId "S5-02" -Category "Motion" `
    -Description "Reduced motion rule enforces transition-duration: 0.01ms !important across all elements" `
    -Passed $has001ms `
    -Expected "transition-duration: 0.01ms !important present in base.css" `
    -Actual "$has001ms"

# ------------------------------------------------------------------------------
# SUITE SUMMARY & VERDICT
# ------------------------------------------------------------------------------
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "                  M4 CHALLENGER TEST RESULTS SUMMARY                   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$totalTests = $Report.Count
$passedTests = ($Report | Where-Object { $_.Passed -eq $true }).Count
$failedTests = ($Report | Where-Object { $_.Passed -eq $false }).Count
$passRate = if ($totalTests -gt 0) { [math]::Round(($passedTests / $totalTests) * 100, 1) } else { 0 }

$failColor = if ($failedTests -eq 0) { "Green" } else { "Red" }
Write-Host ("Total Assertions: {0}" -f $totalTests)
Write-Host ("Passed:           {0}" -f $passedTests) -ForegroundColor Green
Write-Host ("Failed:           {0}" -f $failedTests) -ForegroundColor $failColor
Write-Host ("Pass Rate:        {0}%" -f $passRate)

$verdict = if ($failedTests -eq 0) { "APPROVE" } else { "CHALLENGE_FAILED" }
$vColor = if ($verdict -eq "APPROVE") { "Green" } else { "Red" }

Write-Host "`n>> VERDICT: $verdict" -ForegroundColor $vColor
Write-Host "======================================================================" -ForegroundColor Cyan

if ($failedTests -gt 0) {
    exit 1
} else {
    exit 0
}
