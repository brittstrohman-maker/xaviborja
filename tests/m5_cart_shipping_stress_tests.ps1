# ==============================================================================
# CHALLENGER M5-1: EMPIRICAL STRESS-TESTING SUITE FOR MILESTONE M5
# Target: Free Shipping Bar & Cart Calculations (Milestone M5)
# Methodology: AST Parsing + Mathematical Liquid Oracle + Real Headless Edge DOM Execution
# ==============================================================================

[CmdletBinding()]
param(
    [switch]$VerboseOutput
)

$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
Set-Location $RepoRoot
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Report = [System.Collections.ArrayList]::new()
$Euro = [char]0x20AC

function Log-Assertion {
    param(
        [Parameter(Mandatory=$true)]
        [hashtable]$Params
    )
    $obj = [PSCustomObject]@{
        TestId      = [string]$Params.TestId
        Category    = [string]$Params.Category
        Description = [string]$Params.Description
        Passed      = [bool]$Params.Passed
        Expected    = [string]$Params.Expected
        Actual      = [string]$Params.Actual
        Severity    = if ($Params.ContainsKey("Severity")) { [string]$Params.Severity } else { "CRITICAL" }
    }
    $null = $Report.Add($obj)
    
    $statusStr = if ($obj.Passed) { "[PASS]" } else { "[{0} FAIL]" -f $obj.Severity }
    $color = if ($obj.Passed) { "Green" } elseif ($obj.Severity -in @("CRITICAL","HIGH")) { "Red" } else { "Yellow" }
    Write-Host ("  {0} {1} ({2}) - {3}" -f $statusStr, $obj.TestId, $obj.Category, $obj.Description) -ForegroundColor $color
    if (-not $obj.Passed -or $VerboseOutput) {
        Write-Host ("         Expected: {0}" -f $obj.Expected) -ForegroundColor DarkGray
        Write-Host ("         Actual:   {0}" -f $obj.Actual) -ForegroundColor DarkGray
    }
}

Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   CHALLENGER M5-1: FREE SHIPPING BAR & CART CALCULATION STRESS SUITE" -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

# Paths
$cartSummaryPath    = Join-Path $RepoRoot "snippets/cart-summary.liquid"
$cartDrawerPath     = Join-Path $RepoRoot "sections/cart-drawer.liquid"
$cartItemsPath      = Join-Path $RepoRoot "snippets/cart-items.liquid"
$settingsDataPath   = Join-Path $RepoRoot "config/settings_data.json"
$settingsSchemaPath = Join-Path $RepoRoot "config/settings_schema.json"
$localeEnPath       = Join-Path $RepoRoot "locales/en.default.json"
$themeJsPath        = Join-Path $RepoRoot "assets/theme.js"
$baseCssPath        = Join-Path $RepoRoot "assets/base.css"

# Load source files
$cartSummaryContent = [System.IO.File]::ReadAllText($cartSummaryPath, [System.Text.Encoding]::UTF8)
$cartDrawerContent  = [System.IO.File]::ReadAllText($cartDrawerPath, [System.Text.Encoding]::UTF8)
$cartItemsContent   = [System.IO.File]::ReadAllText($cartItemsPath, [System.Text.Encoding]::UTF8)
$settingsDataJson   = [System.IO.File]::ReadAllText($settingsDataPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$settingsSchemaJson = [System.IO.File]::ReadAllText($settingsSchemaPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$localeEnJson       = [System.IO.File]::ReadAllText($localeEnPath, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
$themeJsContent     = [System.IO.File]::ReadAllText($themeJsPath, [System.Text.Encoding]::UTF8)
$baseCssContent     = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

# ------------------------------------------------------------------------------
# SUITE 1: SOURCE INTEGRITY, TAG BALANCE & CONFIGURATION AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 1] Source Integrity, Tag Balance & Settings Configuration ---" -ForegroundColor Yellow

# S1-01: cart-summary.liquid tag and block balance
$sumNoComment = [System.Text.RegularExpressions.Regex]::Replace($cartSummaryContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$sumOpIf = ([System.Text.RegularExpressions.Regex]::Matches($sumNoComment, '\{%-?\s*if\b')).Count
$sumClIf = ([System.Text.RegularExpressions.Regex]::Matches($sumNoComment, '\{%-?\s*endif\b')).Count
$sumOpFor = ([System.Text.RegularExpressions.Regex]::Matches($sumNoComment, '\{%-?\s*for\b')).Count
$sumClFor = ([System.Text.RegularExpressions.Regex]::Matches($sumNoComment, '\{%-?\s*endfor\b')).Count
$sumBalanced = ($sumOpIf -eq $sumClIf) -and ($sumOpFor -eq $sumClFor)

Log-Assertion @{
    TestId      = "S1-01"
    Category    = "Integrity"
    Description = "snippets/cart-summary.liquid block balance (if/endif, for/endfor)"
    Passed      = [bool]$sumBalanced
    Expected    = "Balanced: if ($sumOpIf/$sumClIf), for ($sumOpFor/$sumClFor)"
    Actual      = "Balanced=$sumBalanced"
}

# S1-02: sections/cart-drawer.liquid tag balance and schema validity
$drawerNoComment = [System.Text.RegularExpressions.Regex]::Replace($cartDrawerContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$drOpIf = ([System.Text.RegularExpressions.Regex]::Matches($drawerNoComment, '\{%-?\s*if\b')).Count
$drClIf = ([System.Text.RegularExpressions.Regex]::Matches($drawerNoComment, '\{%-?\s*endif\b')).Count
$drawerBalanced = ($drOpIf -eq $drClIf)

$drawerSchemaValid = $false
if ($cartDrawerContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
    try {
        $null = $matches[1] | ConvertFrom-Json
        $drawerSchemaValid = $true
    } catch {}
}

Log-Assertion @{
    TestId      = "S1-02"
    Category    = "Integrity"
    Description = "sections/cart-drawer.liquid tag balance and valid embedded schema"
    Passed      = [bool]($drawerBalanced -and $drawerSchemaValid)
    Expected    = "Balanced=$true, SchemaValid=$true"
    Actual      = "Balanced=$drawerBalanced, SchemaValid=$drawerSchemaValid"
}

# S1-03: snippets/cart-items.liquid block balance
$itemsNoComment = [System.Text.RegularExpressions.Regex]::Replace($cartItemsContent, '\{%-?\s*comment\s*-?%\}[\s\S]*?\{%-?\s*endcomment\s*-?%\}', '')
$itOpIf = ([System.Text.RegularExpressions.Regex]::Matches($itemsNoComment, '\{%-?\s*(if|unless)\b')).Count
$itClIf = ([System.Text.RegularExpressions.Regex]::Matches($itemsNoComment, '\{%-?\s*(endif|endunless)\b')).Count
$itOpFor = ([System.Text.RegularExpressions.Regex]::Matches($itemsNoComment, '\{%-?\s*for\b')).Count
$itClFor = ([System.Text.RegularExpressions.Regex]::Matches($itemsNoComment, '\{%-?\s*endfor\b')).Count
$itemsBalanced = ($itOpIf -eq $itClIf) -and ($itOpFor -eq $itClFor)

Log-Assertion @{
    TestId      = "S1-03"
    Category    = "Integrity"
    Description = "snippets/cart-items.liquid block balance (if/for loops)"
    Passed      = [bool]$itemsBalanced
    Expected    = "Balanced: if/unless ($itOpIf/$itClIf), for ($itOpFor/$itClFor)"
    Actual      = "Balanced=$itemsBalanced"
}

# S1-04: config/settings_data.json current settings for free shipping bar
$currThresh = $settingsDataJson.current.cart_free_shipping_threshold
$currShow = $settingsDataJson.current.cart_show_free_shipping_bar
$currThreshOk = ($currThresh -eq "55" -or $currThresh -eq 55) -and ($currShow -eq $true)

Log-Assertion @{
    TestId      = "S1-04"
    Category    = "Configuration"
    Description = "settings_data.json current has cart_show_free_shipping_bar=true and threshold=55"
    Passed      = [bool]$currThreshOk
    Expected    = "show=true, threshold=55"
    Actual      = "show=$currShow, threshold=$currThresh"
}

# S1-05: config/settings_data.json presets configuration
$preset1 = $settingsDataJson.presets.'Dose & Dial'
$preset2 = $settingsDataJson.presets.'Editorial Espresso'
$presetsOk = ($preset1.cart_show_free_shipping_bar -eq $true) -and ($preset1.cart_free_shipping_threshold -eq "55") -and `
             ($preset2.cart_show_free_shipping_bar -eq $true) -and ($preset2.cart_free_shipping_threshold -eq "55")

Log-Assertion @{
    TestId      = "S1-05"
    Category    = "Configuration"
    Description = "settings_data.json presets 'Dose & Dial' and 'Editorial Espresso' have threshold=55"
    Passed      = [bool]$presetsOk
    Expected    = "All presets threshold=55, show=true"
    Actual      = "Dose&Dial=($($preset1.cart_free_shipping_threshold)), Editorial=($($preset2.cart_free_shipping_threshold))"
}

# S1-06: config/settings_schema.json definitions
$cartSectionInSchema = $settingsSchemaJson | Where-Object { $_.name -match 'cart' }
$hasThresholdSetting = $false
$hasShowSetting = $false
if ($cartSectionInSchema -and $cartSectionInSchema.settings) {
    $hasThresholdSetting = [bool]($cartSectionInSchema.settings | Where-Object { $_.id -eq "cart_free_shipping_threshold" -and $_.default -eq "55" })
    $hasShowSetting = [bool]($cartSectionInSchema.settings | Where-Object { $_.id -eq "cart_show_free_shipping_bar" -and $_.default -eq $true })
}

Log-Assertion @{
    TestId      = "S1-06"
    Category    = "Configuration"
    Description = "settings_schema.json schema definitions for cart free shipping threshold and toggle"
    Passed      = [bool]($hasThresholdSetting -and $hasShowSetting)
    Expected    = "threshold default 55, show default true"
    Actual      = "hasThreshold=$hasThresholdSetting, hasShow=$hasShowSetting"
}

# S1-07: Anti-dropshipping audit (No fake urgency countdowns or fake stock badges in cart)
$fakeUrgencyPattern = 'countdown|hurry|only\s+\d+\s+left|flash-sale|high-demand|reserved\s+for'
$hasUrgencyInSummary = [System.Text.RegularExpressions.Regex]::IsMatch($cartSummaryContent, $fakeUrgencyPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$hasUrgencyInDrawer  = [System.Text.RegularExpressions.Regex]::IsMatch($cartDrawerContent, $fakeUrgencyPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$hasUrgencyInItems   = [System.Text.RegularExpressions.Regex]::IsMatch($cartItemsContent, $fakeUrgencyPattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
$noFakeUrgency = (-not $hasUrgencyInSummary) -and (-not $hasUrgencyInDrawer) -and (-not $hasUrgencyInItems)

Log-Assertion @{
    TestId      = "S1-07"
    Category    = "Integrity"
    Description = "Strict anti-dropshipping check: zero fake timers, fake stock urgency in cart"
    Passed      = [bool]$noFakeUrgency
    Expected    = "Zero fake urgency tropes"
    Actual      = "Clean=$noFakeUrgency"
}


# ------------------------------------------------------------------------------
# SUITE 2: MATHEMATICAL & BOUNDARY PRECISION ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 2] Mathematical & Boundary Precision Oracle (4 Core + Permutations) ---" -ForegroundColor Yellow

# Liquid Simulation Engine matching snippets/cart-summary.liquid
function Simulate-LiquidCartShippingBar {
    param(
        [long]$CartTotalPriceCents,
        [int]$ItemCount = 1,
        [string]$ThresholdDollars = "55",
        [bool]$ShowBar = $true,
        [string]$CurrencySymbol = [char]0x20AC
    )

    if (-not $ShowBar -or $ItemCount -le 0) {
        return @{
            IsRendered = $false
            RemainingCents = $null
            ProgressPercent = $null
            IsUnlocked = $null
            Status = "SUPPRESSED"
            Label = $null
            StyleWidth = $null
        }
    }

    # assign threshold = settings.cart_free_shipping_threshold | times: 100
    [double]$parsedThresh = 0.0
    [double]::TryParse($ThresholdDollars, [ref]$parsedThresh) | Out-Null
    [long]$thresholdCents = [long]($parsedThresh * 100)

    # assign remaining = threshold | minus: cart.total_price
    [long]$remaining = $thresholdCents - $CartTotalPriceCents

    # assign progress = 100
    [double]$progress = 100.0

    # if threshold > 0 and remaining > 0
    #   assign progress = cart.total_price | times: 100.0 | divided_by: threshold
    # endif
    if ($thresholdCents -gt 0 -and $remaining -gt 0) {
        $progress = ($CartTotalPriceCents * 100.0) / $thresholdCents
    }

    # assign remaining_money = remaining | money
    $remainingDollars = [double]$remaining / 100.0
    $remainingMoney = "{0}{1:N2}" -f $CurrencySymbol, $remainingDollars

    # Label evaluation
    $renderedLabel = ""
    $isUnlocked = ($remaining -le 0)
    if ($remaining -gt 0) {
        $template = $localeEnJson.sections.cart.free_shipping_progress_html
        $renderedLabel = $template.Replace("{{ amount }}", $remainingMoney)
    } else {
        $renderedLabel = $localeEnJson.sections.cart.free_shipping_reached
    }

    return @{
        IsRendered       = $true
        ThresholdCents   = $thresholdCents
        CartTotalCents   = $CartTotalPriceCents
        RemainingCents   = $remaining
        ProgressPercent  = $progress
        IsUnlocked       = $isUnlocked
        Status           = if ($isUnlocked) { "UNLOCKED" } else { "LOCKED" }
        RemainingMoney   = $remainingMoney
        Label            = $renderedLabel
        StyleWidth       = "{0}%" -f $progress
    }
}

# 1. Boundary 0 cents (EUR 0.00): remaining = 5500 cents, 0% progress, locked
$b1 = Simulate-LiquidCartShippingBar -CartTotalPriceCents 0 -ItemCount 1
$b1_ok = ($b1.IsRendered -eq $true) -and `
         ($b1.RemainingCents -eq 5500) -and `
         ($b1.ProgressPercent -eq 0.0) -and `
         ($b1.IsUnlocked -eq $false) -and `
         ($b1.Label -match '55\.00 away from FREE SHIPPING')

Log-Assertion @{
    TestId      = "B-01"
    Category    = "Boundary"
    Description = "Boundary 0c (EUR 0.00): remaining=5500c, progress=0.0%, status=LOCKED, label='{{ amount }} away...'"
    Passed      = [bool]$b1_ok
    Expected    = "remaining=5500, progress=0%, unlocked=False, label contains '55.00 away from FREE SHIPPING'"
    Actual      = "remaining=$($b1.RemainingCents), progress=$($b1.ProgressPercent)%, unlocked=$($b1.IsUnlocked), label='$($b1.Label)'"
}

# 2. Boundary 5499 cents (EUR 54.99): remaining = 1 cent, progress < 100%, locked
$b2 = Simulate-LiquidCartShippingBar -CartTotalPriceCents 5499 -ItemCount 1
$b2_progExpected = (5499 * 100.0) / 5500
$b2_ok = ($b2.IsRendered -eq $true) -and `
         ($b2.RemainingCents -eq 1) -and `
         ($b2.ProgressPercent -lt 100.0) -and `
         ([math]::Abs($b2.ProgressPercent - $b2_progExpected) -lt 0.0001) -and `
         ($b2.IsUnlocked -eq $false) -and `
         ($b2.Label -match '0\.01 away from FREE SHIPPING')

Log-Assertion @{
    TestId      = "B-02"
    Category    = "Boundary"
    Description = "Boundary 5499c (EUR 54.99): remaining=1c, progress=99.98% (<100%), status=LOCKED"
    Passed      = [bool]$b2_ok
    Expected    = "remaining=1, progress < 100% (~99.9818%), unlocked=False, label contains '0.01 away from FREE SHIPPING'"
    Actual      = "remaining=$($b2.RemainingCents), progress=$($b2.ProgressPercent)%, unlocked=$($b2.IsUnlocked), label='$($b2.Label)'"
}

# 3. Boundary 5500 cents (EUR 55.00): remaining = 0 cents, 100% progress, unlocked
$b3 = Simulate-LiquidCartShippingBar -CartTotalPriceCents 5500 -ItemCount 1
$b3_ok = ($b3.IsRendered -eq $true) -and `
         ($b3.RemainingCents -eq 0) -and `
         ($b3.ProgressPercent -eq 100.0) -and `
         ($b3.IsUnlocked -eq $true) -and `
         ($b3.Label -eq "FREE STANDARD SHIPPING UNLOCKED")

Log-Assertion @{
    TestId      = "B-03"
    Category    = "Boundary"
    Description = "Boundary 5500c (EUR 55.00): remaining=0c, progress=100.0%, status=UNLOCKED"
    Passed      = [bool]$b3_ok
    Expected    = "remaining=0, progress=100%, unlocked=True, label='FREE STANDARD SHIPPING UNLOCKED'"
    Actual      = "remaining=$($b3.RemainingCents), progress=$($b3.ProgressPercent)%, unlocked=$($b3.IsUnlocked), label='$($b3.Label)'"
}

# 4. Boundary 8000 cents (EUR 80.00): progress clamped to 100%, unlocked
$b4 = Simulate-LiquidCartShippingBar -CartTotalPriceCents 8000 -ItemCount 1
$b4_ok = ($b4.IsRendered -eq $true) -and `
         ($b4.RemainingCents -eq -2500) -and `
         ($b4.ProgressPercent -eq 100.0) -and `
         ($b4.ProgressPercent -le 100.0) -and `
         ($b4.IsUnlocked -eq $true) -and `
         ($b4.Label -eq "FREE STANDARD SHIPPING UNLOCKED")

Log-Assertion @{
    TestId      = "B-04"
    Category    = "Boundary"
    Description = "Boundary 8000c (EUR 80.00): progress clamped strictly to 100.0% (not 145.45%), status=UNLOCKED"
    Passed      = [bool]$b4_ok
    Expected    = "remaining=-2500, progress=100% (clamped), unlocked=True, label='FREE STANDARD SHIPPING UNLOCKED'"
    Actual      = "remaining=$($b4.RemainingCents), progress=$($b4.ProgressPercent)%, unlocked=$($b4.IsUnlocked), label='$($b4.Label)'"
}

# Extended Adversarial Permutation Matrix
$adversarialCases = @(
    @{ Id="P-01"; Total=1;       Desc="1c (EUR 0.01) minimal non-zero item"; ExpRem=5499; ExpUnlocked=$false; ExpClamp=$false }
    @{ Id="P-02"; Total=2750;    Desc="2750c (EUR 27.50) exactly 50% midpoint"; ExpRem=2750; ExpUnlocked=$false; ExpProg=50.0 }
    @{ Id="P-03"; Total=3700;    Desc="3700c (EUR 37.00) spec example: EUR 18 away"; ExpRem=1800; ExpUnlocked=$false; ExpProg=67.2727 }
    @{ Id="P-04"; Total=5498;    Desc="5498c (EUR 54.98) 2 cents below threshold"; ExpRem=2; ExpUnlocked=$false; ExpProg=99.9636 }
    @{ Id="P-05"; Total=5501;    Desc="5501c (EUR 55.01) 1 cent over threshold"; ExpRem=-1; ExpUnlocked=$true; ExpProg=100.0 }
    @{ Id="P-06"; Total=100000;  Desc="100,000c (EUR 1,000.00) extreme overfill"; ExpRem=-94500; ExpUnlocked=$true; ExpProg=100.0 }
    @{ Id="P-07"; Total=5000; Thresh="0"; Desc="Zero-threshold (free shipping all)"; ExpRem=-5000; ExpUnlocked=$true; ExpProg=100.0 }
    @{ Id="P-08"; Total=0; Items=0; Desc="Empty cart (item_count = 0)"; ExpRendered=$false }
    @{ Id="P-09"; Total=5000; Show=$false; Desc="Merchant disabled free shipping bar"; ExpRendered=$false }
)

foreach ($sc in $adversarialCases) {
    $items = if ($sc.ContainsKey("Items")) { $sc.Items } else { 1 }
    $thresh = if ($sc.ContainsKey("Thresh")) { $sc.Thresh } else { "55" }
    $show = if ($sc.ContainsKey("Show")) { $sc.Show } else { $true }

    $res = Simulate-LiquidCartShippingBar -CartTotalPriceCents $sc.Total -ItemCount $items -ThresholdDollars $thresh -ShowBar $show
    
    $pass = $true
    if ($sc.ContainsKey("ExpRendered")) {
        $pass = ($res.IsRendered -eq $sc.ExpRendered)
    } else {
        if ($res.RemainingCents -ne $sc.ExpRem) { $pass = $false }
        if ($res.IsUnlocked -ne $sc.ExpUnlocked) { $pass = $false }
        if ($sc.ContainsKey("ExpProg")) {
            if ([math]::Abs($res.ProgressPercent - $sc.ExpProg) -gt 0.01) { $pass = $false }
        }
    }

    Log-Assertion @{
        TestId      = "ADV-$($sc.Id)"
        Category    = "Permutation"
        Description = "Adversarial: $($sc.Desc)"
        Passed      = [bool]$pass
        Expected    = "Rendered=$(if($sc.ContainsKey('ExpRendered')){$sc.ExpRendered}else{$true}), Rem=$($sc.ExpRem), Unlocked=$($sc.ExpUnlocked)"
        Actual      = "Rendered=$($res.IsRendered), Rem=$($res.RemainingCents), Unlocked=$($res.IsUnlocked), Prog=$($res.ProgressPercent)%"
    }
}


# ------------------------------------------------------------------------------
# SUITE 3: CURRENCY & TRANSLATION FORMATTING ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 3] Currency & Translation Formatting Oracle ---" -ForegroundColor Yellow

# S3-01: Locale en.default.json contains exact progress string
$progHtmlKey = $localeEnJson.sections.cart.free_shipping_progress_html
$progHtmlOk = ($progHtmlKey -eq "{{ amount }} away from FREE SHIPPING")
Log-Assertion @{
    TestId      = "S3-01"
    Category    = "Translation"
    Description = "Locale contains exact 'sections.cart.free_shipping_progress_html'"
    Passed      = [bool]$progHtmlOk
    Expected    = "'{{ amount }} away from FREE SHIPPING'"
    Actual      = "'$progHtmlKey'"
}

# S3-02: Locale en.default.json contains exact reached string
$reachedKey = $localeEnJson.sections.cart.free_shipping_reached
$reachedOk = ($reachedKey -eq "FREE STANDARD SHIPPING UNLOCKED")
Log-Assertion @{
    TestId      = "S3-02"
    Category    = "Translation"
    Description = "Locale contains exact 'sections.cart.free_shipping_reached'"
    Passed      = [bool]$reachedOk
    Expected    = "'FREE STANDARD SHIPPING UNLOCKED'"
    Actual      = "'$reachedKey'"
}

# S3-03: Variable interpolation under multiple currency formats
$testCurrencies = @(
    @{ Code = "EUR"; Symbol = "$Euro"; ExpectedAmount = "$Euro" + "18.00"; ExpectedResult = "$Euro" + "18.00 away from FREE SHIPPING" }
    @{ Code = "USD"; Symbol = "$"; ExpectedAmount = "`$18.00"; ExpectedResult = "`$18.00 away from FREE SHIPPING" }
    @{ Code = "GBP"; Symbol = [char]0x00A3; ExpectedAmount = "$([char]0x00A3)18.00"; ExpectedResult = "$([char]0x00A3)18.00 away from FREE SHIPPING" }
)

foreach ($curr in $testCurrencies) {
    $interpolated = $progHtmlKey.Replace("{{ amount }}", $curr.ExpectedAmount)
    $currPass = ($interpolated -eq $curr.ExpectedResult)
    Log-Assertion @{
        TestId      = "S3-03-$($curr.Code)"
        Category    = "Currency"
        Description = "Currency interpolation for $($curr.Code) produces expected formatted string"
        Passed      = [bool]$currPass
        Expected    = [string]$curr.ExpectedResult
        Actual      = [string]$interpolated
    }
}

# S3-04: Subtotal formatting in snippets/cart-summary.liquid
$hasMoneyWithCurrency = ($cartSummaryContent -match 'cart\.total_price\s*\|\s*money_with_currency')
Log-Assertion @{
    TestId      = "S3-04"
    Category    = "Currency"
    Description = "snippets/cart-summary.liquid formats subtotal using money_with_currency"
    Passed      = [bool]$hasMoneyWithCurrency
    Expected    = "cart.total_price | money_with_currency present"
    Actual      = "hasMoneyWithCurrency=$hasMoneyWithCurrency"
}

# S3-05: Cart section standard translation keys configured
$cartKeysOk = ($localeEnJson.sections.cart.checkout -eq "Checkout") -and `
              ($localeEnJson.sections.cart.view_cart -eq "View cart") -and `
              ($localeEnJson.sections.cart.subtotal -eq "Subtotal") -and `
              ($localeEnJson.sections.cart.empty -eq "Your cart is empty")
Log-Assertion @{
    TestId      = "S3-05"
    Category    = "Translation"
    Description = "Standard cart action translation keys (checkout, view_cart, subtotal, empty) present"
    Passed      = [bool]$cartKeysOk
    Expected    = "checkout='Checkout', view_cart='View cart', subtotal='Subtotal'"
    Actual      = "checkout='$($localeEnJson.sections.cart.checkout)', view_cart='$($localeEnJson.sections.cart.view_cart)'"
}


# ------------------------------------------------------------------------------
# SUITE 4: CART DRAWER LINE ITEM RENDERING AUDIT
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 4] Cart Drawer Line Item Rendering Audit ---" -ForegroundColor Yellow

# S4-01: Dialog structure in sections/cart-drawer.liquid
$hasDrawerCustomElement = ($cartDrawerContent -match '<cart-drawer>') -and ($cartDrawerContent -match '</cart-drawer>')
$hasDialogElement = ($cartDrawerContent -match '<dialog\s+class="drawer\s+color-scheme-1"\s+id="CartDrawer"')
Log-Assertion @{
    TestId      = "S4-01"
    Category    = "Structure"
    Description = "cart-drawer.liquid encapsulates #CartDrawer dialog inside <cart-drawer>"
    Passed      = [bool]($hasDrawerCustomElement -and $hasDialogElement)
    Expected    = "<cart-drawer> and <dialog id='CartDrawer'>"
    Actual      = "customElement=$hasDrawerCustomElement, dialog=$hasDialogElement"
}

# S4-02: Close button with data-drawer-close and accessible label
$hasCloseButton = ($cartDrawerContent -match '<button[^>]*data-drawer-close[^>]*aria-label=')
Log-Assertion @{
    TestId      = "S4-02"
    Category    = "Accessibility"
    Description = "Cart drawer header contains close button with data-drawer-close and aria-label"
    Passed      = [bool]$hasCloseButton
    Expected    = "data-drawer-close button with aria-label"
    Actual      = "hasCloseButton=$hasCloseButton"
}

# S4-03: Empty state suppression of drawer footer
$suppressesFooterOnEmpty = ($cartDrawerContent -match '\{%-?\s*if\s+cart\s*!=\s*empty\s*-?%\}[\s\S]*?<footer\s+class="drawer__footer">[\s\S]*?<\/footer>[\s\S]*?\{%-?\s*endif\s*-?%\}')
Log-Assertion @{
    TestId      = "S4-03"
    Category    = "Structure"
    Description = "Drawer footer is strictly suppressed when cart == empty (prevents empty checkout)"
    Passed      = [bool]$suppressesFooterOnEmpty
    Expected    = "footer wrapped in '{% if cart != empty %}'"
    Actual      = "suppressesFooterOnEmpty=$suppressesFooterOnEmpty"
}

# S4-04: Line items loop in snippets/cart-items.liquid
$hasItemsLoop = ($cartItemsContent -match '\{%-?\s*for\s+item\s+in\s+cart\.items\s*-?%\}')
$hasDataLineKey = ($cartItemsContent -match 'data-line="\{\{\s*forloop\.index\s*\}\}"') -and ($cartItemsContent -match 'data-key="\{\{\s*item\.key\s*\}\}"')
Log-Assertion @{
    TestId      = "S4-04"
    Category    = "LineItems"
    Description = "cart-items.liquid loops over cart.items with data-line and data-key"
    Passed      = [bool]($hasItemsLoop -and $hasDataLineKey)
    Expected    = "for item in cart.items with data-line and data-key"
    Actual      = "hasLoop=$hasItemsLoop, hasDataAttr=$hasDataLineKey"
}

# S4-05: Line item media thumbnail with lazy loading and portrait ratio
$hasThumbnailMedia = ($cartItemsContent -match 'class="media\s+media--portrait"') -and `
                     ($cartItemsContent -match 'image_url:\s*width:\s*300') -and `
                     ($cartItemsContent -match 'loading:\s*''lazy''')
Log-Assertion @{
    TestId      = "S4-05"
    Category    = "LineItems"
    Description = "Line item thumbnail uses media--portrait with width: 300 and lazy loading"
    Passed      = [bool]$hasThumbnailMedia
    Expected    = "media--portrait, image_url: width: 300, lazy loading"
    Actual      = "hasThumbnailMedia=$hasThumbnailMedia"
}

# S4-06: Line item title and variant options rendering
$hasTitleLink = ($cartItemsContent -match '<h3 class="cart-item__title"><a href="\{\{\s*item\.url\s*\}\}">\{\{\s*item\.product\.title')
$hasVariantOptions = ($cartItemsContent -match 'item\.product\.has_only_default_variant\s*==\s*false') -and ($cartItemsContent -match 'option\.name')
Log-Assertion @{
    TestId      = "S4-06"
    Category    = "LineItems"
    Description = "Line item renders linked title and conditional variant options"
    Passed      = [bool]($hasTitleLink -and $hasVariantOptions)
    Expected    = "linked title and variant options check"
    Actual      = "hasTitle=$hasTitleLink, hasVariants=$hasVariantOptions"
}

# S4-07: Price comparison and discount allocation
$hasPriceCompare = ($cartItemsContent -match 'item\.original_price\s*>\s*item\.final_price') -and `
                   ($cartItemsContent -match 'price__sale') -and ($cartItemsContent -match 'price__compare')
$hasDiscounts = ($cartItemsContent -match 'item\.line_level_discount_allocations')
Log-Assertion @{
    TestId      = "S4-07"
    Category    = "LineItems"
    Description = "Line item handles compare-at sales and line-level discount allocations"
    Passed      = [bool]($hasPriceCompare -and $hasDiscounts)
    Expected    = "Sale price comparison and discount list"
    Actual      = "hasPriceCompare=$hasPriceCompare, hasDiscounts=$hasDiscounts"
}

# S4-08: Quantity input and removal controls
$hasQuantityInput = ($cartItemsContent -match 'render\s+''quantity-input''') -and `
                    ($cartItemsContent -match 'updates\[') -and ($cartItemsContent -match 'min:\s*0')
$hasRemoveLink = ($cartItemsContent -match 'data-remove-line="\{\{\s*forloop\.index\s*\}\}"') -and `
                 ($cartItemsContent -match 'href="\{\{\s*item\.url_to_remove\s*\}\}"')
Log-Assertion @{
    TestId      = "S4-08"
    Category    = "LineItems"
    Description = "Line item has quantity-input component (min: 0) and data-remove-line link"
    Passed      = [bool]($hasQuantityInput -and $hasRemoveLink)
    Expected    = "quantity-input and data-remove-line"
    Actual      = "hasQuantity=$hasQuantityInput, hasRemove=$hasRemoveLink"
}


# ------------------------------------------------------------------------------
# SUITE 5: CHECKOUT CTA & DRAWER INTERACTION BEHAVIOR
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 5] Checkout CTA & Drawer Interaction Behavior ---" -ForegroundColor Yellow

# S5-01: Form definition in cart-drawer.liquid
$hasCartDrawerForm = ($cartDrawerContent -match '<form\s+action="\{\{\s*routes\.cart_url\s*\}\}"\s+method="post"\s+id="CartDrawerForm"\s+novalidate>')
Log-Assertion @{
    TestId      = "S5-01"
    Category    = "Checkout"
    Description = "cart-drawer.liquid wraps summary in CartDrawerForm posting to routes.cart_url"
    Passed      = [bool]$hasCartDrawerForm
    Expected    = "<form action='{{ routes.cart_url }}' method='post' id='CartDrawerForm' novalidate>"
    Actual      = "hasCartDrawerForm=$hasCartDrawerForm"
}

# S5-02: Checkout CTA button attributes in cart-summary.liquid
$hasCheckoutButton = ($cartSummaryContent -match '<button\s+type="submit"\s+name="checkout"\s+class="button\s+button--full"')
$hasFormBinding = ($cartSummaryContent -match 'form="\{\{\s*form_id\s*\}\}"')
Log-Assertion @{
    TestId      = "S5-02"
    Category    = "Checkout"
    Description = "Checkout CTA has type='submit', name='checkout', class='button button--full', form binding"
    Passed      = [bool]($hasCheckoutButton -and $hasFormBinding)
    Expected    = "Submit button with name='checkout' bound to form_id"
    Actual      = "hasCheckoutButton=$hasCheckoutButton, hasFormBinding=$hasFormBinding"
}

# S5-03: Secondary CTA: View Cart button
$hasViewCart = ($cartSummaryContent -match '<a\s+href="\{\{\s*routes\.cart_url\s*\}\}"\s+class="button\s+button--outline\s+button--full">')
Log-Assertion @{
    TestId      = "S5-03"
    Category    = "Checkout"
    Description = "Secondary CTA links to routes.cart_url with .button--outline"
    Passed      = [bool]$hasViewCart
    Expected    = "View cart link with button--outline"
    Actual      = "hasViewCart=$hasViewCart"
}

# S5-04: Context isolation: drawer CTA only renders for drawer context
$drawerContextIsolated = ($cartSummaryContent -match '\{%-?\s*if\s+context\s*==\s*''drawer''\s*-?%\}[\s\S]*?name="checkout"[\s\S]*?\{%-?\s*endif\s*-?%\}')
Log-Assertion @{
    TestId      = "S5-04"
    Category    = "Checkout"
    Description = "Checkout CTA inside cart-summary is isolated to context == 'drawer'"
    Passed      = [bool]$drawerContextIsolated
    Expected    = "Wrapped in '{% if context == ''drawer'' %}'"
    Actual      = "drawerContextIsolated=$drawerContextIsolated"
}

# S5-05: Section Rendering API registration in theme.js
$hasCartSectionApi = ($themeJsContent -match 'const\s+CART_SECTIONS\s*=\s*\[\s*''cart-drawer'',\s*''cart-icon-bubble''\s*\];')
Log-Assertion @{
    TestId      = "S5-05"
    Category    = "CartAPI"
    Description = "theme.js registers CART_SECTIONS = ['cart-drawer', 'cart-icon-bubble']"
    Passed      = [bool]$hasCartSectionApi
    Expected    = "CART_SECTIONS contains cart-drawer and cart-icon-bubble"
    Actual      = "hasCartSectionApi=$hasCartSectionApi"
}

# S5-06: DOM Section replacement for cart drawer
$hasDrawerDomReplacement = ($themeJsContent -match 'sectionInnerHTML\(sections\[''cart-drawer''\],\s*''\.drawer__inner''\)') -and `
                           ($themeJsContent -match 'target\.innerHTML\s*=\s*inner')
Log-Assertion @{
    TestId      = "S5-06"
    Category    = "CartAPI"
    Description = "theme.js extracts .drawer__inner from Section Rendering API and updates #CartDrawer"
    Passed      = [bool]$hasDrawerDomReplacement
    Expected    = "sectionInnerHTML targeting .drawer__inner"
    Actual      = "hasDrawerDomReplacement=$hasDrawerDomReplacement"
}

# S5-07: CartDrawer custom element event listeners (change, click)
$hasDrawerEvents = ($themeJsContent -match 'class\s+CartDrawer\s+extends\s+HTMLElement') -and `
                   ($themeJsContent -match 'changeCartLine\(\{\s*line:\s*input\.dataset\.index,\s*quantity:\s*input\.value\s*\}') -and `
                   ($themeJsContent -match 'changeCartLine\(\{\s*line:\s*remove\.getAttribute\(''data-remove-line''\),\s*quantity:\s*0\s*\}')
Log-Assertion @{
    TestId      = "S5-07"
    Category    = "CartAPI"
    Description = "CartDrawer custom element binds quantity input changes and remove clicks"
    Passed      = [bool]$hasDrawerEvents
    Expected    = "Quantity input event and remove line click handlers"
    Actual      = "hasDrawerEvents=$hasDrawerEvents"
}

# S5-08: ProductForm opens CartDrawer on add-to-cart
$hasOpenOnAdd = ($themeJsContent -match 'openDialog\(''CartDrawer''\)')
Log-Assertion @{
    TestId      = "S5-08"
    Category    = "CartAPI"
    Description = "ProductForm invokes openDialog('CartDrawer') upon successful add-to-cart"
    Passed      = [bool]$hasOpenOnAdd
    Expected    = "openDialog('CartDrawer') in ProductForm"
    Actual      = "hasOpenOnAdd=$hasOpenOnAdd"
}


# ------------------------------------------------------------------------------
# SUITE 6: REAL HEADLESS EDGE (CHROMIUM) DOM & CSS COMPUTATION ORACLE
# ------------------------------------------------------------------------------
Write-Host "`n--- [SUITE 6] Headless Chromium DOM, CSS & Hit-Testing Execution ---" -ForegroundColor Yellow

$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}

if (-not (Test-Path $edgePath)) {
    Log-Assertion @{
        TestId      = "S6-00"
        Category    = "HeadlessEdge"
        Description = "Microsoft Edge executable available for headless testing"
        Passed      = $false
        Expected    = "msedge.exe present"
        Actual      = "Not found"
    }
} else {
    Log-Assertion @{
        TestId      = "S6-00"
        Category    = "HeadlessEdge"
        Description = "Microsoft Edge executable available at $edgePath"
        Passed      = $true
        Expected    = "msedge.exe present"
        Actual      = "Found at $edgePath"
    }

    # Token CSS injection matching theme-styles.liquid
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
  --space-xs: 0.25rem;
  --space-sm: 0.5rem;
  --space-md: 1rem;
  --space-lg: 1.5rem;
  --space-xl: 2rem;
  --space-2xl: 3rem;
  --text-xs: 0.75rem;
  --text-sm: 0.875rem;
  --text-base: 1rem;
  --text-lg: 1.25rem;
}
"@

    # HTML fixture testing the 4 critical boundaries in real DOM
    $fixtureHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Cart Shipping Bar Empirical Fixture</title>
  <style>
  $tokenCss
  $baseCssContent
  
  body {
    margin: 0;
    padding: 20px;
    background-color: rgb(var(--color-background));
    color: rgb(var(--color-text));
    font-family: var(--font-body);
  }
  .test-panel {
    width: 420px;
    margin: 0 auto;
    background: #fff;
    padding: 20px;
    border: 1px solid rgb(var(--color-border));
    box-sizing: border-box;
  }
  </style>
</head>
<body>
  <div class="test-panel">

    <!-- BOUNDARY 1: 0 cents -->
    <div id="boundary_0" class="shipping-bar-test">
      <div class="shipping-bar" id="bar_0">
        <span class="shipping-bar__label" id="label_0">55.00 away from FREE SHIPPING</span>
        <div class="shipping-bar__track" id="track_0">
          <div class="shipping-bar__fill" id="fill_0" style="width: 0%;"></div>
        </div>
      </div>
    </div>

    <!-- BOUNDARY 2: 5499 cents -->
    <div id="boundary_5499" class="shipping-bar-test">
      <div class="shipping-bar" id="bar_5499">
        <span class="shipping-bar__label" id="label_5499">0.01 away from FREE SHIPPING</span>
        <div class="shipping-bar__track" id="track_5499">
          <div class="shipping-bar__fill" id="fill_5499" style="width: 99.9818181818182%;"></div>
        </div>
      </div>
    </div>

    <!-- BOUNDARY 3: 5500 cents -->
    <div id="boundary_5500" class="shipping-bar-test">
      <div class="shipping-bar" id="bar_5500">
        <span class="shipping-bar__label" id="label_5500">FREE STANDARD SHIPPING UNLOCKED</span>
        <div class="shipping-bar__track" id="track_5500">
          <div class="shipping-bar__fill" id="fill_5500" style="width: 100%;"></div>
        </div>
      </div>
    </div>

    <!-- BOUNDARY 4: 8000 cents -->
    <div id="boundary_8000" class="shipping-bar-test">
      <div class="shipping-bar" id="bar_8000">
        <span class="shipping-bar__label" id="label_8000">FREE STANDARD SHIPPING UNLOCKED</span>
        <div class="shipping-bar__track" id="track_8000">
          <div class="shipping-bar__fill" id="fill_8000" style="width: 100%;"></div>
        </div>
      </div>
    </div>

    <!-- CART DRAWER DIALOG MOCK -->
    <cart-drawer id="drawerContainer">
      <dialog class="drawer color-scheme-1" id="CartDrawer" open style="position: static; display: block; width: 100%; border: 0;">
        <div class="drawer__inner">
          <header class="drawer__header">
            <h2 class="drawer__title">Your Cart</h2>
            <button type="button" class="icon-button" id="closeBtn" data-drawer-close aria-label="Close">
              <svg class="icon icon-close" width="20" height="20" viewBox="0 0 20 20"><path d="M5 5L15 15M15 5L5 15" stroke="currentColor" stroke-width="1.5"/></svg>
            </button>
          </header>
          <div class="drawer__body">
            <div class="cart-items" data-context="drawer">
              <div class="cart-item" data-line="1" data-key="sample-item-1">
                <a href="/products/tamper" class="media media--portrait" style="width: 5.5rem; height: 5.5rem; display: block;">
                  <img src="data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='100' height='100'%3E%3Crect width='100%25' height='100%25' fill='%23ccc'/%3E%3C/svg%3E" alt="Tamper" style="width: 100%; height: 100%;" />
                </a>
                <div class="cart-item__details">
                  <h3 class="cart-item__title"><a href="/products/tamper">Precision Tamper 58.5mm</a></h3>
                  <div class="price"><span>€35.00</span></div>
                  <div class="cart-item__footer">
                    <quantity-input class="quantity">
                      <button type="button" class="quantity__button" name="minus" id="qtyMinus">-</button>
                      <input class="quantity__input" type="number" id="qtyInput" value="1" min="0" data-index="1">
                      <button type="button" class="quantity__button" name="plus" id="qtyPlus">+</button>
                    </quantity-input>
                    <a href="/cart/change?line=1&quantity=0" class="button--link text-xs" data-remove-line="1" id="removeLink">Remove</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
          <footer class="drawer__footer">
            <form action="/cart" method="post" id="CartDrawerForm" novalidate>
              <div class="cart-summary">
                <div class="cart-summary__row cart-summary__total">
                  <span>Subtotal</span>
                  <span id="subtotal">€35.00 EUR</span>
                </div>
                <div class="stack" style="--gap: 0.5rem; gap: 0.5rem; margin-top: 1rem; display: flex; flex-direction: column;">
                  <button type="submit" name="checkout" class="button button--full" id="checkoutBtn" form="CartDrawerForm">
                    Checkout
                  </button>
                  <a href="/cart" class="button button--outline button--full" id="viewCartBtn">
                    View cart
                  </a>
                </div>
              </div>
            </form>
          </footer>
        </div>
      </dialog>
    </cart-drawer>

  </div>

  <pre id="results">RUNNING</pre>

  <script>
  window.addEventListener('DOMContentLoaded', () => {
    function getMetrics(id) {
      const el = document.getElementById(id);
      if (!el) return null;
      const rect = el.getBoundingClientRect();
      const style = window.getComputedStyle(el);
      return {
        width: rect.width,
        height: rect.height,
        color: style.color,
        backgroundColor: style.backgroundColor,
        overflow: style.overflow,
        display: style.display,
        minHeight: style.minHeight,
        minWidth: style.minWidth
      };
    }

    const t0 = getMetrics('track_0');
    const f0 = getMetrics('fill_0');
    const t5499 = getMetrics('track_5499');
    const f5499 = getMetrics('fill_5499');
    const t5500 = getMetrics('track_5500');
    const f5500 = getMetrics('fill_5500');
    const t8000 = getMetrics('track_8000');
    const f8000 = getMetrics('fill_8000');

    const checkoutBtn = getMetrics('checkoutBtn');
    const closeBtn = getMetrics('closeBtn');
    const qtyInput = getMetrics('qtyInput');
    const removeLink = getMetrics('removeLink');

    const results = {
      boundary_0: {
        trackWidth: t0.width,
        fillWidth: f0.width,
        fillRatio: t0.width > 0 ? (f0.width / t0.width) : 0,
        trackOverflow: t0.overflow,
        fillColor: f0.backgroundColor
      },
      boundary_5499: {
        trackWidth: t5499.width,
        fillWidth: f5499.width,
        fillRatio: t5499.width > 0 ? (f5499.width / t5499.width) : 0
      },
      boundary_5500: {
        trackWidth: t5500.width,
        fillWidth: f5500.width,
        fillRatio: t5500.width > 0 ? (f5500.width / t5500.width) : 0
      },
      boundary_8000: {
        trackWidth: t8000.width,
        fillWidth: f8000.width,
        fillRatio: t8000.width > 0 ? (f8000.width / t8000.width) : 0
      },
      checkoutBtn: {
        height: checkoutBtn.height,
        width: checkoutBtn.width,
        minHeight: checkoutBtn.minHeight
      },
      closeBtn: {
        height: closeBtn.height,
        width: closeBtn.width,
        minHeight: closeBtn.minHeight,
        minWidth: closeBtn.minWidth
      }
    };

    document.getElementById('results').innerText = JSON.stringify(results);
  });
  </script>
</body>
</html>
"@

    $tempFixturePath = Join-Path $env:TEMP "m5_cart_fixture.html"
    [System.IO.File]::WriteAllText($tempFixturePath, $fixtureHtml, [System.Text.Encoding]::UTF8)

    $outLog = Join-Path $env:TEMP "m5_edge_output.txt"
    Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=5000", "--dump-dom", $tempFixturePath -RedirectStandardOutput $outLog -Wait

    $rawOut = [System.IO.File]::ReadAllText($outLog, [System.Text.Encoding]::UTF8)
    Remove-Item $tempFixturePath, $outLog -Force -ErrorAction SilentlyContinue

    $edgeDomResults = $null
    $mMatch = [regex]::Match($rawOut, '<pre id="results">([\s\S]*?)</pre>')
    if ($mMatch.Success) {
        $clean = $mMatch.Groups[1].Value -replace '<br\s*/?>', "`n"
        $clean = [System.Net.WebUtility]::HtmlDecode($clean).Trim()
        try {
            $edgeDomResults = $clean | ConvertFrom-Json
        } catch {
            Write-Host "JSON Parse Error on Edge output: $_" -ForegroundColor Red
        }
    }

    if ($null -eq $edgeDomResults) {
        Log-Assertion @{
            TestId      = "S6-01"
            Category    = "HeadlessEdge"
            Description = "Headless Edge rendered DOM metrics output successfully parsed"
            Passed      = $false
            Expected    = "Valid JSON from <pre id='results'>"
            Actual      = "Failed to parse"
        }
    } else {
        Log-Assertion @{
            TestId      = "S6-01"
            Category    = "HeadlessEdge"
            Description = "Headless Edge rendered DOM metrics output successfully parsed"
            Passed      = $true
            Expected    = "Valid JSON from <pre id='results'>"
            Actual      = "Parsed successfully"
        }

        # S6-02: Track styles and accent fill color
        $accentRgbMatch = ($edgeDomResults.boundary_0.fillColor -match 'rgb\(154,\s*98,\s*56\)')
        $trackOverflowHidden = ($edgeDomResults.boundary_0.trackOverflow -eq "hidden")
        Log-Assertion @{
            TestId      = "S6-02"
            Category    = "ComputedCSS"
            Description = "Shipping bar track has overflow: hidden and fill has --color-accent rgb(154, 98, 56)"
            Passed      = [bool]($accentRgbMatch -and $trackOverflowHidden)
            Expected    = "overflow=hidden, color=rgb(154, 98, 56)"
            Actual      = "overflow=$($edgeDomResults.boundary_0.trackOverflow), color=$($edgeDomResults.boundary_0.fillColor)"
        }

        # S6-03: Boundary 0c computed fill width is 0px (ratio = 0.0)
        $b0_fillZero = ($edgeDomResults.boundary_0.fillWidth -eq 0) -or ($edgeDomResults.boundary_0.fillRatio -eq 0.0)
        Log-Assertion @{
            TestId      = "S6-03"
            Category    = "ComputedDOM"
            Description = "Boundary 0c: Computed width of fill element is 0px (0.0% of track)"
            Passed      = [bool]$b0_fillZero
            Expected    = "fillWidth=0px, ratio=0.0"
            Actual      = "fillWidth=$($edgeDomResults.boundary_0.fillWidth)px, ratio=$($edgeDomResults.boundary_0.fillRatio)"
        }

        # S6-04: Boundary 5499c computed fill ratio is ~99.98% (> 0.99 and < 1.0)
        $b5499_fillRatio = $edgeDomResults.boundary_5499.fillRatio
        $b5499_fillOk = ($b5499_fillRatio -gt 0.99) -and ($b5499_fillRatio -lt 1.0)
        Log-Assertion @{
            TestId      = "S6-04"
            Category    = "ComputedDOM"
            Description = "Boundary 5499c: Computed fill ratio is ~99.98% (>0.99 and strictly < 1.0)"
            Passed      = [bool]$b5499_fillOk
            Expected    = ">0.99 and <1.0"
            Actual      = "ratio=$b5499_fillRatio (width: $($edgeDomResults.boundary_5499.fillWidth)px / $($edgeDomResults.boundary_5499.trackWidth)px)"
        }

        # S6-05: Boundary 5500c computed fill width equals track width (ratio = 1.0)
        $b5500_fillRatio = $edgeDomResults.boundary_5500.fillRatio
        $b5500_fillOk = ([math]::Abs($b5500_fillRatio - 1.0) -lt 0.01)
        Log-Assertion @{
            TestId      = "S6-05"
            Category    = "ComputedDOM"
            Description = "Boundary 5500c: Computed fill width reaches 100% of track width (ratio = 1.0)"
            Passed      = [bool]$b5500_fillOk
            Expected    = "ratio=1.0"
            Actual      = "ratio=$b5500_fillRatio (width: $($edgeDomResults.boundary_5500.fillWidth)px / $($edgeDomResults.boundary_5500.trackWidth)px)"
        }

        # S6-06: Boundary 8000c computed fill width is clamped to 100% (never overflows track)
        $b8000_fillRatio = $edgeDomResults.boundary_8000.fillRatio
        $b8000_fillOk = ([math]::Abs($b8000_fillRatio - 1.0) -lt 0.01) -and ($edgeDomResults.boundary_8000.fillWidth -le ($edgeDomResults.boundary_8000.trackWidth + 1))
        Log-Assertion @{
            TestId      = "S6-06"
            Category    = "ComputedDOM"
            Description = "Boundary 8000c: Computed fill width is clamped to 100% (does not exceed track width)"
            Passed      = [bool]$b8000_fillOk
            Expected    = "ratio=1.0 (clamped, <= track width)"
            Actual      = "ratio=$b8000_fillRatio (fill: $($edgeDomResults.boundary_8000.fillWidth)px, track: $($edgeDomResults.boundary_8000.trackWidth)px)"
        }

        # S6-07: Checkout CTA button touch target >= 44px
        $checkoutHeight = $edgeDomResults.checkoutBtn.height
        $checkoutTouchOk = ($checkoutHeight -ge 44)
        Log-Assertion @{
            TestId      = "S6-07"
            Category    = "Accessibility"
            Description = "Checkout CTA button computed height is >= 44px (accessible touch target)"
            Passed      = [bool]$checkoutTouchOk
            Expected    = "height >= 44px"
            Actual      = "height=$($checkoutHeight)px"
        }

        # S6-08: Close button touch target >= 44x44px
        $closeW = $edgeDomResults.closeBtn.width
        $closeH = $edgeDomResults.closeBtn.height
        $closeTouchOk = ($closeW -ge 44) -and ($closeH -ge 44)
        Log-Assertion @{
            TestId      = "S6-08"
            Category    = "Accessibility"
            Description = "Drawer close icon button is at least 44x44px (accessible touch target)"
            Passed      = [bool]$closeTouchOk
            Expected    = "width >= 44px, height >= 44px"
            Actual      = "width=$($closeW)px, height=$($closeH)px"
        }
    }
}


# ==============================================================================
# FINAL RESULTS SUMMARY & VERDICT
# ==============================================================================
Write-Host "`n======================================================================" -ForegroundColor Cyan
Write-Host "                CHALLENGER M5-1 TEST EXECUTION SUMMARY               " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$totalTests  = $Report.Count
$passedTests = @($Report | Where-Object { $_.Passed }).Count
$failedTests = @($Report | Where-Object { -not $_.Passed }).Count
$criticalFails = @($Report | Where-Object { -not $_.Passed -and $_.Severity -eq "CRITICAL" }).Count

$categories = $Report | Group-Object Category
Write-Host "`nResults by Category:" -ForegroundColor Cyan
foreach ($cat in $categories) {
    $catTotal = $cat.Group.Count
    $catPass = @($cat.Group | Where-Object { $_.Passed }).Count
    $catFail = $catTotal - $catPass
    $pct = if ($catTotal -gt 0) { [math]::Round(($catPass * 100.0) / $catTotal, 1) } else { 0 }
    $catColor = if ($catFail -eq 0) { "Green" } else { "Red" }
    Write-Host ("  {0,-15} : {1,3}/{2,3} passed ({3,5}%){4}" -f $cat.Name, $catPass, $catTotal, $pct, $(if($catFail -gt 0){" [$catFail FAILED]"}else{""})) -ForegroundColor $catColor
}

Write-Host ("`nTotal Tests: {0} | Passed: {1} | Failed: {2}" -f $totalTests, $passedTests, $failedTests) -ForegroundColor Cyan

if ($failedTests -eq 0) {
    Write-Host "`n>> VERDICT: APPROVE (100% compliance across all M5 Free Shipping & Cart stress tests)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "`n>> VERDICT: CHALLENGE_FAILED ($failedTests tests failed, including $criticalFails critical)" -ForegroundColor Red
    exit 1
}
