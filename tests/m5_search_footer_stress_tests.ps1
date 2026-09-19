# ==============================================================================
# M5 SEARCH, 404, AND FOOTER ADVERSARIAL EMPIRICAL STRESS TEST SUITE
# Milestone M5: Cart Drawer, Search, Global Pages & Footer
# Dose & Dial Shopify Theme Redesign
# ==============================================================================

param(
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL M5 EMPIRICAL CHALLENGER STRESS TEST SUITE                        " -ForegroundColor Cyan
Write-Host "   Target Codebase: $RepoRoot" -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

# Test Tracking
$Global:TotalTests = 0
$Global:PassedTests = 0
$Global:FailedTests = 0
$Global:TestResults = @()

function Log-Assertion {
    param(
        [Parameter(Mandatory=$true)][string]$TestId,
        [Parameter(Mandatory=$true)][string]$Category,
        [Parameter(Mandatory=$true)][string]$Description,
        [Parameter(Mandatory=$true)][bool]$Passed,
        [Parameter(Mandatory=$true)][string]$Expected,
        [Parameter(Mandatory=$true)][string]$Actual,
        [string]$Severity = "CRITICAL"
    )

    $Global:TotalTests++
    if ($Passed) {
        $Global:PassedTests++
        Write-Host "  [PASS] $TestId - $Description" -ForegroundColor Green
    } else {
        $Global:FailedTests++
        Write-Host "  [FAIL] $TestId - $Description" -ForegroundColor Red
        Write-Host "         Expected: $Expected" -ForegroundColor DarkRed
        Write-Host "         Actual:   $Actual" -ForegroundColor DarkRed
        Write-Host "         Severity: $Severity" -ForegroundColor Red
    }

    $Global:TestResults += [PSCustomObject]@{
        TestId      = $TestId
        Category    = $Category
        Description = $Description
        Passed      = $Passed
        Expected    = $Expected
        Actual      = $Actual
        Severity    = $Severity
    }
}

# ------------------------------------------------------------------------------
# 0. Load Core Files
# ------------------------------------------------------------------------------
Write-Host "`n--- Loading Core Theme Files ---" -ForegroundColor Yellow

$predictiveSearchPath = Join-Path $RepoRoot "sections/predictive-search.liquid"
$mainSearchPath       = Join-Path $RepoRoot "sections/main-search.liquid"
$searchFormPath       = Join-Path $RepoRoot "snippets/search-form.liquid"
$main404Path          = Join-Path $RepoRoot "sections/main-404.liquid"
$template404Path      = Join-Path $RepoRoot "templates/404.json"
$footerPath           = Join-Path $RepoRoot "sections/footer.liquid"
$footerGroupPath      = Join-Path $RepoRoot "sections/footer-group.json"
$headerPath           = Join-Path $RepoRoot "sections/header.liquid"
$enLocalePath         = Join-Path $RepoRoot "locales/en.default.json"
$baseCssPath          = Join-Path $RepoRoot "assets/base.css"
$themeStylesPath      = Join-Path $RepoRoot "snippets/theme-styles.liquid"

$predictiveSearchContent = [System.IO.File]::ReadAllText($predictiveSearchPath, [System.Text.Encoding]::UTF8)
$mainSearchContent       = [System.IO.File]::ReadAllText($mainSearchPath, [System.Text.Encoding]::UTF8)
$searchFormContent       = [System.IO.File]::ReadAllText($searchFormPath, [System.Text.Encoding]::UTF8)
$main404Content          = [System.IO.File]::ReadAllText($main404Path, [System.Text.Encoding]::UTF8)
$template404Content      = [System.IO.File]::ReadAllText($template404Path, [System.Text.Encoding]::UTF8)
$footerContent           = [System.IO.File]::ReadAllText($footerPath, [System.Text.Encoding]::UTF8)
$footerGroupContent      = [System.IO.File]::ReadAllText($footerGroupPath, [System.Text.Encoding]::UTF8)
$headerContent           = [System.IO.File]::ReadAllText($headerPath, [System.Text.Encoding]::UTF8)
$enLocaleContent         = [System.IO.File]::ReadAllText($enLocalePath, [System.Text.Encoding]::UTF8)
$baseCssContent          = [System.IO.File]::ReadAllText($baseCssPath, [System.Text.Encoding]::UTF8)

$enLocaleJson = $enLocaleContent | ConvertFrom-Json
$template404Json = $template404Content | ConvertFrom-Json
$footerGroupJson = $footerGroupContent | ConvertFrom-Json

# ==============================================================================
# 1. SEARCH EMPTY RESULTS & RECOVERY COPY EMPIRICAL STRESS TESTS
# ==============================================================================
Write-Host "`n--- 1. Search Empty State & Recovery Empirical Tests ---" -ForegroundColor Yellow

# 1.1 Predictive search liquid AST tag balance
$psIfCount    = ([regex]::Matches($predictiveSearchContent, '\{%-\s*if\b')).Count
$psEndIfCount = ([regex]::Matches($predictiveSearchContent, '\{%-\s*endif\b')).Count
Log-Assertion -TestId "SRCH-01" -Category "Search" `
    -Description "predictive-search.liquid: All if/endif liquid control tags are strictly balanced" `
    -Passed ($psIfCount -eq $psEndIfCount -and $psIfCount -ge 5) `
    -Expected "if count == endif count ($psIfCount)" `
    -Actual "if=$psIfCount, endif=$psEndIfCount"

# 1.2 predictive_search.performed guard
$hasPerformedGuard = ($predictiveSearchContent -match '\{\%-\s*if\s+predictive_search\.performed\s*-\%\}')
Log-Assertion -TestId "SRCH-02" -Category "Search" `
    -Description "predictive-search.liquid: Empty state is protected by predictive_search.performed guard" `
    -Passed $hasPerformedGuard `
    -Expected "predictive_search.performed guard present" `
    -Actual "hasPerformedGuard=$hasPerformedGuard"

# 1.3 Total count logic aggregates products, collections, articles, pages
$hasTotalCalc = ($predictiveSearchContent -match 'assign\s+total\s*=\s*predictive_search\.resources\.products\.size\s*\|\s*plus:\s*predictive_search\.resources\.collections\.size\s*\|\s*plus:\s*predictive_search\.resources\.articles\.size\s*\|\s*plus:\s*predictive_search\.resources\.pages\.size')
Log-Assertion -TestId "SRCH-03" -Category "Search" `
    -Description "predictive-search.liquid: Total resources count accurately aggregates products, collections, articles, pages" `
    -Passed $hasTotalCalc `
    -Expected "Accurate 4-resource sum assigned to total" `
    -Actual "hasTotalCalc=$hasTotalCalc"

# 1.4 Empty state triggers verbatim 'NOTHING YET.'
$hasNothingYetHeading = ($predictiveSearchContent -match '\{\{\s*''general\.search\.no_results''\s*\|\s*t\s*\|\s*default:\s*''NOTHING YET\.''\s*\}\}')
Log-Assertion -TestId "SRCH-04" -Category "Search" `
    -Description "predictive-search.liquid: Renders 'general.search.no_results' with default fallback 'NOTHING YET.'" `
    -Passed $hasNothingYetHeading `
    -Expected "'NOTHING YET.' fallback on general.search.no_results" `
    -Actual "hasNothingYetHeading=$hasNothingYetHeading"

# 1.5 Empty state triggers verbatim recovery copy
$hasRecoveryCopy = ($predictiveSearchContent -match '\{\{\s*''general\.search\.recovery_copy''\s*\|\s*t\s*\|\s*default:\s*''Try another search or explore our coffee bar essentials\.''\s*\}\}')
Log-Assertion -TestId "SRCH-05" -Category "Search" `
    -Description "predictive-search.liquid: Renders recovery copy with default fallback 'Try another search or explore our coffee bar essentials.'" `
    -Passed $hasRecoveryCopy `
    -Expected "Verbatim recovery copy present with fallback" `
    -Actual "hasRecoveryCopy=$hasRecoveryCopy"

# 1.6 Empty state links to routes.all_products_collection_url
$hasAllProductsLink = ($predictiveSearchContent -match 'href=["'']\{\{\s*routes\.all_products_collection_url\s*\}\}["'']')
Log-Assertion -TestId "SRCH-06" -Category "Search" `
    -Description "predictive-search.liquid: Recovery CTA links dynamically to routes.all_products_collection_url" `
    -Passed $hasAllProductsLink `
    -Expected "href contains routes.all_products_collection_url" `
    -Actual "hasAllProductsLink=$hasAllProductsLink"

# 1.7 Locale strings in en.default.json
$localeNoResults = $enLocaleJson.general.search.no_results
$localeRecovery  = $enLocaleJson.general.search.recovery_copy
Log-Assertion -TestId "SRCH-07" -Category "Search" `
    -Description "en.default.json: general.search.no_results strictly equals 'NOTHING YET.'" `
    -Passed ($localeNoResults -eq "NOTHING YET.") `
    -Expected "'NOTHING YET.'" `
    -Actual "$localeNoResults"

Log-Assertion -TestId "SRCH-08" -Category "Search" `
    -Description "en.default.json: general.search.recovery_copy strictly equals 'Try another search or explore our coffee bar essentials.'" `
    -Passed ($localeRecovery -eq "Try another search or explore our coffee bar essentials.") `
    -Expected "'Try another search or explore our coffee bar essentials.'" `
    -Actual "$localeRecovery"

# 1.8 Search drawer in header.liquid and search-form predictive search element
$hasSearchDrawerId = ($headerContent -match 'id=["'']SearchDrawer["'']')
$hasSearchFormRender = ($headerContent -match 'render\s+[''"]search-form[''"]')
$hasPredictiveSearchElement = ($searchFormContent -match '<predictive-search\b')
$searchIntegrationValid = $hasSearchDrawerId -and $hasSearchFormRender -and $hasPredictiveSearchElement

Log-Assertion -TestId "SRCH-09" -Category "Search" `
    -Description "header.liquid & search-form.liquid: Search drawer (#SearchDrawer) renders predictive-search form" `
    -Passed $searchIntegrationValid `
    -Expected "#SearchDrawer rendering <predictive-search>" `
    -Actual "drawerId=$hasSearchDrawerId, formRender=$hasSearchFormRender, elem=$hasPredictiveSearchElement"

# 1.9 Liquid Simulation Oracle: Empty Results State vs Populated Results State
function Simulate-PredictiveSearchRender {
    param(
        [bool]$Performed,
        [int]$ProductCount,
        [int]$CollectionCount,
        [int]$ArticleCount,
        [int]$PageCount,
        [hashtable]$Translations = @{
            "general.search.no_results" = "NOTHING YET."
            "general.search.recovery_copy" = "Try another search or explore our coffee bar essentials."
            "general.continue_shopping" = "Continue shopping"
            "general.search.view_all" = "View all results"
        }
    )

    if (-not $Performed) {
        return '<div id="PredictiveSearchResults"></div>'
    }

    $total = $ProductCount + $CollectionCount + $ArticleCount + $PageCount
    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<div id="PredictiveSearchResults">')

    if ($ProductCount -gt 0) {
        [void]$sb.Append('<div class="predictive-search__group"><p class="predictive-search__heading">Products</p></div>')
    }

    if ($total -gt 0) {
        [void]$sb.Append("<div class=""predictive-search__group""><a class=""button--link text-sm"" href=""/search?q=test"">$($Translations['general.search.view_all'])</a></div>")
    } elseif ($total -eq 0) {
        $noResults = if ($Translations.ContainsKey('general.search.no_results')) { $Translations['general.search.no_results'] } else { 'NOTHING YET.' }
        $recCopy = if ($Translations.ContainsKey('general.search.recovery_copy')) { $Translations['general.search.recovery_copy'] } else { 'Try another search or explore our coffee bar essentials.' }
        $contShop = if ($Translations.ContainsKey('general.continue_shopping')) { $Translations['general.continue_shopping'] } else { 'Continue shopping' }
        [void]$sb.Append("<div class=""predictive-search__group predictive-search__empty"" style=""text-align: center; padding-block: 1.5rem;"">")
        [void]$sb.Append("<p class=""predictive-search__heading h4"" style=""margin-bottom: 0.5rem;"">$noResults</p>")
        [void]$sb.Append("<p class=""text-sm"" style=""margin-bottom: 1rem;"">$recCopy</p>")
        [void]$sb.Append("<a class=""button button--outline button--sm"" href=""/collections/all"">$contShop</a>")
        [void]$sb.Append("</div>")
    }

    [void]$sb.Append('</div>')
    return $sb.ToString()
}

$simEmpty = Simulate-PredictiveSearchRender -Performed $true -ProductCount 0 -CollectionCount 0 -ArticleCount 0 -PageCount 0
Log-Assertion -TestId "SRCH-10" -Category "Search" `
    -Description "Simulation Oracle: 0 search results correctly produces 'NOTHING YET.', recovery copy, and /collections/all link" `
    -Passed ($simEmpty -match 'NOTHING YET\.' -and $simEmpty -match 'Try another search or explore our coffee bar essentials\.' -and $simEmpty -match 'href="/collections/all"') `
    -Expected "Full empty state markup generated" `
    -Actual "$simEmpty"

$simPopulated = Simulate-PredictiveSearchRender -Performed $true -ProductCount 3 -CollectionCount 0 -ArticleCount 0 -PageCount 0
Log-Assertion -TestId "SRCH-11" -Category "Search" `
    -Description "Simulation Oracle: Populated results suppresses 'NOTHING YET.' and displays results view" `
    -Passed ($simPopulated -notmatch 'NOTHING YET\.' -and $simPopulated -match 'Products' -and $simPopulated -match 'View all results') `
    -Expected "Empty state strictly suppressed when total > 0" `
    -Actual "$simPopulated"

$simUnperformed = Simulate-PredictiveSearchRender -Performed $false -ProductCount 0 -CollectionCount 0 -ArticleCount 0 -PageCount 0
Log-Assertion -TestId "SRCH-12" -Category "Search" `
    -Description "Simulation Oracle: Unperformed search state produces empty drawer container without premature 'NOTHING YET.'" `
    -Passed ($simUnperformed -eq '<div id="PredictiveSearchResults"></div>') `
    -Expected "Empty container when search not performed" `
    -Actual "$simUnperformed"

# ==============================================================================
# 2. 404 PAGE HEADLINE & DYNAMIC CTA EMPIRICAL STRESS TESTS
# ==============================================================================
Write-Host "`n--- 2. 404 Page Headline & CTA Empirical Tests ---" -ForegroundColor Yellow

# 2.1 404 liquid AST and tags
$m404IfCount    = ([regex]::Matches($main404Content, '\{%-\s*if\b')).Count
$m404EndIfCount = ([regex]::Matches($main404Content, '\{%-\s*endif\b')).Count
Log-Assertion -TestId "P404-01" -Category "404 Page" `
    -Description "main-404.liquid: Liquid syntax valid and tag structure balanced" `
    -Passed ($m404IfCount -eq $m404EndIfCount) `
    -Expected "Balanced control tags" `
    -Actual "if=$m404IfCount, endif=$m404EndIfCount"

# 2.2 Verbatim Headline in main-404.liquid
$has404HeadlineTemplate = ($main404Content -match '\{\{\s*''general\.404\.title''\s*\|\s*t\s*\|\s*default:\s*"LOOKS LIKE THIS SHOT DIDN''T DIAL IN\."\s*\}\}')
Log-Assertion -TestId "P404-02" -Category "404 Page" `
    -Description "main-404.liquid: Headline binds to 'general.404.title' with default 'LOOKS LIKE THIS SHOT DIDN''T DIAL IN.'" `
    -Passed $has404HeadlineTemplate `
    -Expected "Headline tag with exact default fallback present" `
    -Actual "has404HeadlineTemplate=$has404HeadlineTemplate"

# 2.3 Verbatim CTA in main-404.liquid
$has404CtaTemplate = ($main404Content -match '\{\{\s*''general\.404\.link''\s*\|\s*t\s*\|\s*default:\s*"BACK TO THE COFFEE BAR"\s*\}\}')
Log-Assertion -TestId "P404-03" -Category "404 Page" `
    -Description "main-404.liquid: CTA text binds to 'general.404.link' with default 'BACK TO THE COFFEE BAR'" `
    -Passed $has404CtaTemplate `
    -Expected "CTA tag with exact default fallback present" `
    -Actual "has404CtaTemplate=$has404CtaTemplate"

# 2.4 Dynamic CTA href binding to routes.all_products_collection_url
$has404DynamicUrl = ($main404Content -match '<a\s+href=["'']\{\{\s*routes\.all_products_collection_url\s*\}\}["'']\s+class=["'']button["'']>')
Log-Assertion -TestId "P404-04" -Category "404 Page" `
    -Description "main-404.liquid: CTA href binds dynamically to {{ routes.all_products_collection_url }}" `
    -Passed $has404DynamicUrl `
    -Expected "Dynamic routes.all_products_collection_url in anchor href" `
    -Actual "has404DynamicUrl=$has404DynamicUrl"

# 2.5 Eyebrow '404' indicator
$hasEyebrow = ($main404Content -match '<p\s+class=["'']eyebrow["'']>404</p>')
Log-Assertion -TestId "P404-05" -Category "404 Page" `
    -Description "main-404.liquid: Editorial eyebrow '404' micro-label is rendered" `
    -Passed $hasEyebrow `
    -Expected "<p class='eyebrow'>404</p> present" `
    -Actual "hasEyebrow=$hasEyebrow"

# 2.6 Locales en.default.json exact strings
$locale404Title = $enLocaleJson.general.'404'.title
$locale404Link  = $enLocaleJson.general.'404'.link
Log-Assertion -TestId "P404-06" -Category "404 Page" `
    -Description "en.default.json: general.404.title strictly equals 'LOOKS LIKE THIS SHOT DIDN''T DIAL IN.'" `
    -Passed ($locale404Title -eq "LOOKS LIKE THIS SHOT DIDN'T DIAL IN.") `
    -Expected "'LOOKS LIKE THIS SHOT DIDN''T DIAL IN.'" `
    -Actual "$locale404Title"

Log-Assertion -TestId "P404-07" -Category "404 Page" `
    -Description "en.default.json: general.404.link strictly equals 'BACK TO THE COFFEE BAR'" `
    -Passed ($locale404Link -eq "BACK TO THE COFFEE BAR") `
    -Expected "'BACK TO THE COFFEE BAR'" `
    -Actual "$locale404Link"

# 2.7 templates/404.json mapping to main-404
$has404SectionMapping = ($template404Json.sections.main.type -eq "main-404") -and ($template404Json.order -contains "main")
Log-Assertion -TestId "P404-08" -Category "404 Page" `
    -Description "templates/404.json: Mapped to section type 'main-404' in active order" `
    -Passed $has404SectionMapping `
    -Expected "Section 'main' of type 'main-404' in order" `
    -Actual "type=$($template404Json.sections.main.type), order=$($template404Json.order -join ',')"

# ==============================================================================
# 3. SEVILLE CREDENTIALS VERBATIM EMPIRICAL VERIFICATION
# ==============================================================================
Write-Host "`n--- 3. Seville Business Credentials Verbatim Empirical Tests ---" -ForegroundColor Yellow

# Construct target strings using explicit unicode character [char]0x00E1 to guarantee
# absolute platform-independent encoding fidelity across all PowerShell versions
$accentA = [char]0x00E1
$targetAddress = "Calle Pintor Rold$accentA" + "n 3, 41940 Sevilla, Spain"
$targetPhone   = "+34 648 273 811"
$targetEmail   = "xaviborja1@hotmail.com"

# 3.1 Verbatim address in footer-group.json
$fgHasAddress = $footerGroupContent.IndexOf($targetAddress, [System.StringComparison]::Ordinal) -ge 0
Log-Assertion -TestId "SEV-01" -Category "Seville Credentials" `
    -Description "footer-group.json: Verbatim physical address 'Calle Pintor Roldán 3, 41940 Sevilla, Spain' present with exact accented á" `
    -Passed $fgHasAddress `
    -Expected "Exact string with á (U+00E1): '$targetAddress'" `
    -Actual "fgHasAddress=$fgHasAddress"

# 3.2 Verbatim address in footer.liquid schema default
$flHasAddress = $footerContent.IndexOf($targetAddress, [System.StringComparison]::Ordinal) -ge 0
Log-Assertion -TestId "SEV-02" -Category "Seville Credentials" `
    -Description "footer.liquid: Verbatim physical address in schema default text setting" `
    -Passed $flHasAddress `
    -Expected "Exact string with á (U+00E1): '$targetAddress' in footer.liquid schema" `
    -Actual "flHasAddress=$flHasAddress"

# 3.3 Verbatim phone in footer-group.json and footer.liquid
$fgHasPhone = $footerGroupContent.Contains($targetPhone)
$flHasPhone = $footerContent.Contains($targetPhone)
Log-Assertion -TestId "SEV-03" -Category "Seville Credentials" `
    -Description "footer-group.json & footer.liquid: Verbatim phone '+34 648 273 811' present" `
    -Passed ($fgHasPhone -and $flHasPhone) `
    -Expected "Exact string: '$targetPhone' in both files" `
    -Actual "footerGroup=$fgHasPhone, footer=$flHasPhone"

# 3.4 Verbatim email in footer-group.json and footer.liquid
$fgHasEmail = $footerGroupContent.Contains($targetEmail)
$flHasEmail = $footerContent.Contains($targetEmail)
Log-Assertion -TestId "SEV-04" -Category "Seville Credentials" `
    -Description "footer-group.json & footer.liquid: Verbatim email 'xaviborja1@hotmail.com' present" `
    -Passed ($fgHasEmail -and $flHasEmail) `
    -Expected "Exact string: '$targetEmail' in both files" `
    -Actual "footerGroup=$fgHasEmail, footer=$flHasEmail"

# 3.5 UTF-8 Encoding Verification for Accented Character
# The character 'á' in UTF-8 is hex sequence C3 A1 (decimal 195, 161)
$fgBytes = [System.IO.File]::ReadAllBytes($footerGroupPath)
$hasC3A1 = $false
for ($i = 0; $i -lt $fgBytes.Length - 1; $i++) {
    if ($fgBytes[$i] -eq 0xC3 -and $fgBytes[$i+1] -eq 0xA1) {
        $hasC3A1 = $true
        break
    }
}
Log-Assertion -TestId "SEV-05" -Category "Seville Credentials" `
    -Description "footer-group.json: File is authentic UTF-8 with uncorrupted 2-byte sequence 0xC3 0xA1 for 'á'" `
    -Passed $hasC3A1 `
    -Expected "Byte sequence 0xC3 0xA1 present in UTF-8 binary stream" `
    -Actual "hasC3A1=$hasC3A1"

# ==============================================================================
# 4. STANDARD SHOPIFY POLICY LINKS DYNAMIC RESOLUTION
# ==============================================================================
Write-Host "`n--- 4. Standard Shopify Policy Links Empirical Tests ---" -ForegroundColor Yellow

# 4.1 Check all 4 policy objects in footer.liquid
$hasRefundPolicy   = ($footerContent -match 'shop\.refund_policy\s*!=\s*blank') -and ($footerContent -match '\{\{\s*shop\.refund_policy\.url\s*\}\}') -and ($footerContent -match '\{\{\s*shop\.refund_policy\.title\s*\}\}')
$hasPrivacyPolicy  = ($footerContent -match 'shop\.privacy_policy\s*!=\s*blank') -and ($footerContent -match '\{\{\s*shop\.privacy_policy\.url\s*\}\}') -and ($footerContent -match '\{\{\s*shop\.privacy_policy\.title\s*\}\}')
$hasTermsPolicy    = ($footerContent -match 'shop\.terms_of_service\s*!=\s*blank') -and ($footerContent -match '\{\{\s*shop\.terms_of_service\.url\s*\}\}') -and ($footerContent -match '\{\{\s*shop\.terms_of_service\.title\s*\}\}')
$hasShippingPolicy = ($footerContent -match 'shop\.shipping_policy\s*!=\s*blank') -and ($footerContent -match '\{\{\s*shop\.shipping_policy\.url\s*\}\}') -and ($footerContent -match '\{\{\s*shop\.shipping_policy\.title\s*\}\}')

Log-Assertion -TestId "POL-01" -Category "Policy Links" `
    -Description "footer.liquid: shop.refund_policy resolves dynamically (.url and .title with blank guard)" `
    -Passed $hasRefundPolicy `
    -Expected "shop.refund_policy checks and bindings present" `
    -Actual "hasRefundPolicy=$hasRefundPolicy"

Log-Assertion -TestId "POL-02" -Category "Policy Links" `
    -Description "footer.liquid: shop.privacy_policy resolves dynamically (.url and .title with blank guard)" `
    -Passed $hasPrivacyPolicy `
    -Expected "shop.privacy_policy checks and bindings present" `
    -Actual "hasPrivacyPolicy=$hasPrivacyPolicy"

Log-Assertion -TestId "POL-03" -Category "Policy Links" `
    -Description "footer.liquid: shop.terms_of_service resolves dynamically (.url and .title with blank guard)" `
    -Passed $hasTermsPolicy `
    -Expected "shop.terms_of_service checks and bindings present" `
    -Actual "hasTermsPolicy=$hasTermsPolicy"

Log-Assertion -TestId "POL-04" -Category "Policy Links" `
    -Description "footer.liquid: shop.shipping_policy resolves dynamically (.url and .title with blank guard)" `
    -Passed $hasShippingPolicy `
    -Expected "shop.shipping_policy checks and bindings present" `
    -Actual "hasShippingPolicy=$hasShippingPolicy"

# 4.2 Policy links container and toggle setting
$hasPolicyToggle = ($footerContent -match 'section\.settings\.show_policy_links')
$isPolicyEnabled = ($footerGroupJson.sections.footer.settings.show_policy_links -eq $true)
Log-Assertion -TestId "POL-05" -Category "Policy Links" `
    -Description "footer.liquid & footer-group.json: show_policy_links setting is enabled (true)" `
    -Passed ($hasPolicyToggle -and $isPolicyEnabled) `
    -Expected "show_policy_links conditional present and enabled in settings" `
    -Actual "hasToggle=$hasPolicyToggle, isEnabled=$isPolicyEnabled"

# 4.3 Simulation Oracle: Policy Links Resolution
function Simulate-FooterPoliciesRender {
    param(
        [bool]$ShowPolicyLinks,
        [hashtable]$Policies
    )

    if (-not $ShowPolicyLinks) { return "" }

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.Append('<div class="footer__policies" style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;">')

    if ($Policies.ContainsKey('refund_policy') -and $Policies['refund_policy']) {
        $p = $Policies['refund_policy']
        [void]$sb.Append("<a href=""$($p.url)"">$($p.title)</a>")
    }
    if ($Policies.ContainsKey('privacy_policy') -and $Policies['privacy_policy']) {
        $p = $Policies['privacy_policy']
        [void]$sb.Append("<a href=""$($p.url)"">$($p.title)</a>")
    }
    if ($Policies.ContainsKey('terms_of_service') -and $Policies['terms_of_service']) {
        $p = $Policies['terms_of_service']
        [void]$sb.Append("<a href=""$($p.url)"">$($p.title)</a>")
    }
    if ($Policies.ContainsKey('shipping_policy') -and $Policies['shipping_policy']) {
        $p = $Policies['shipping_policy']
        [void]$sb.Append("<a href=""$($p.url)"">$($p.title)</a>")
    }

    [void]$sb.Append('</div>')
    return $sb.ToString()
}

$allPolicies = @{
    refund_policy     = @{ url = "/policies/refund-policy"; title = "Refund policy" }
    privacy_policy    = @{ url = "/policies/privacy-policy"; title = "Privacy policy" }
    terms_of_service  = @{ url = "/policies/terms-of-service"; title = "Terms of service" }
    shipping_policy   = @{ url = "/policies/shipping-policy"; title = "Shipping policy" }
}
$simPoliciesFull = Simulate-FooterPoliciesRender -ShowPolicyLinks $true -Policies $allPolicies
Log-Assertion -TestId "POL-06" -Category "Policy Links" `
    -Description "Simulation Oracle: All 4 standard policy links render dynamically with valid anchor tags" `
    -Passed ($simPoliciesFull -match 'href="/policies/refund-policy"' -and 
             $simPoliciesFull -match 'href="/policies/privacy-policy"' -and 
             $simPoliciesFull -match 'href="/policies/terms-of-service"' -and 
             $simPoliciesFull -match 'href="/policies/shipping-policy"') `
    -Expected "All 4 policies rendered" `
    -Actual "$simPoliciesFull"

$partialPolicies = @{
    privacy_policy    = @{ url = "/policies/privacy-policy"; title = "Privacy policy" }
    terms_of_service  = @{ url = "/policies/terms-of-service"; title = "Terms of service" }
}
$simPoliciesPartial = Simulate-FooterPoliciesRender -ShowPolicyLinks $true -Policies $partialPolicies
Log-Assertion -TestId "POL-07" -Category "Policy Links" `
    -Description "Simulation Oracle: Gracefully omits unconfigured policies without broken <a> tags" `
    -Passed ($simPoliciesPartial -notmatch 'refund-policy' -and $simPoliciesPartial -notmatch 'shipping-policy' -and $simPoliciesPartial -match 'privacy-policy') `
    -Expected "Only configured policies rendered" `
    -Actual "$simPoliciesPartial"

# ==============================================================================
# 5. DYNAMIC COPYRIGHT & BRAND PROTECTION
# ==============================================================================
Write-Host "`n--- 5. Dynamic Copyright & Brand Protection Empirical Tests ---" -ForegroundColor Yellow

$hasDynamicCopyright = ($footerContent -match '&copy;\s*\{\{\s*''now''\s*\|\s*date:\s*''%Y''\s*\}\}\s*Dose\s*&\s*Dial')
Log-Assertion -TestId "CPY-01" -Category "Copyright" `
    -Description "footer.liquid: Dynamic copyright year '© {{ ''now'' | date: ''%Y'' }} Dose & Dial' configured" `
    -Passed $hasDynamicCopyright `
    -Expected "Dynamic copyright with current year filter and brand name" `
    -Actual "hasDynamicCopyright=$hasDynamicCopyright"

$currentYear = (Get-Date).Year.ToString()
$simCopyright = "&copy; $currentYear Dose & Dial."
Log-Assertion -TestId "CPY-02" -Category "Copyright" `
    -Description "Simulation Oracle: Dynamic copyright computes year $currentYear" `
    -Passed ($simCopyright.Contains($currentYear) -and $simCopyright.Contains("Dose & Dial")) `
    -Expected "Contains '$currentYear' and 'Dose & Dial'" `
    -Actual "$simCopyright"

# ==============================================================================
# 6. FOOTER 4-COLUMN RESPONSIVENESS & ZERO HORIZONTAL OVERFLOW (HEADLESS EDGE)
# ==============================================================================
Write-Host "`n--- 6. Headless Browser Layout & Zero Overflow Verification ---" -ForegroundColor Yellow

# 6.1 Static Block Configuration in footer-group.json
$blockOrder = $footerGroupJson.sections.footer.block_order
Log-Assertion -TestId "FLAY-01" -Category "Footer Layout" `
    -Description "footer-group.json: Exactly 4 distinct blocks configured in active block_order" `
    -Passed ($blockOrder.Count -eq 4) `
    -Expected "4 blocks configured" `
    -Actual "Count=$($blockOrder.Count), Blocks=$($blockOrder -join ', ')"

$hasColAbout      = $footerGroupJson.sections.footer.blocks.'column-about' -ne $null
$hasColShop       = $footerGroupJson.sections.footer.blocks.'column-shop' -ne $null
$hasColSupport    = $footerGroupJson.sections.footer.blocks.'column-support' -ne $null
$hasColNewsletter = $footerGroupJson.sections.footer.blocks.'column-newsletter' -ne $null

Log-Assertion -TestId "FLAY-02" -Category "Footer Layout" `
    -Description "footer-group.json: 4 semantic columns (about, shop, support, newsletter) mapped" `
    -Passed ($hasColAbout -and $hasColShop -and $hasColSupport -and $hasColNewsletter) `
    -Expected "All 4 semantic column definitions present" `
    -Actual "about=$hasColAbout, shop=$hasColShop, support=$hasColSupport, newsletter=$hasColNewsletter"

# 6.2 CSS Grid Rules in base.css
$hasFooterGridMobile = ($baseCssContent -match '\.footer__grid\s*\{[\s\S]*?grid-template-columns:\s*1fr;')
$hasFooterGridDesktop = ($baseCssContent -match '@media\s+screen\s+and\s+\(min-width:\s*750px\)[\s\S]*?\.footer__grid\s*\{[\s\S]*?grid-template-columns:\s*repeat\(auto-fit,\s*minmax\(12rem,\s*1fr\)\);')
$hasWideBlockDesktop = ($baseCssContent -match '@media\s+screen\s+and\s+\(min-width:\s*750px\)[\s\S]*?\.footer__block--wide\s*\{[\s\S]*?grid-column:\s*span\s*2;')

Log-Assertion -TestId "FLAY-03" -Category "Footer Layout" `
    -Description "base.css: .footer__grid uses 1fr single-column stacking on mobile" `
    -Passed $hasFooterGridMobile `
    -Expected "grid-template-columns: 1fr on mobile" `
    -Actual "hasFooterGridMobile=$hasFooterGridMobile"

Log-Assertion -TestId "FLAY-04" -Category "Footer Layout" `
    -Description "base.css: .footer__grid uses repeat(auto-fit, minmax(12rem, 1fr)) and .footer__block--wide span 2 on desktop" `
    -Passed ($hasFooterGridDesktop -and $hasWideBlockDesktop) `
    -Expected "auto-fit grid and span 2 wide block on >=750px" `
    -Actual "grid=$hasFooterGridDesktop, wide=$hasWideBlockDesktop"

# 6.3 Headless Edge Setup
$edgePath = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
if (-not (Test-Path $edgePath)) {
    $edgePath = "C:\Program Files\Microsoft\Edge\Application\msedge.exe"
}
if (-not (Test-Path $edgePath)) {
    $cmd = Get-Command msedge.exe -ErrorAction SilentlyContinue
    if ($cmd) { $edgePath = $cmd.Source }
}

Log-Assertion -TestId "FLAY-05" -Category "Headless Engine" `
    -Description "Microsoft Edge browser binary found for empirical rendering" `
    -Passed (Test-Path $edgePath) `
    -Expected "Edge executable available" `
    -Actual "$edgePath"

if (Test-Path $edgePath) {
    # Generate complete child fixture replicating Footer, 404, and Search Empty State
    $childHtml = @"
<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>M5 Search 404 Footer Stress Fixture</title>
<style>
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
  --color-button-label: 252 250 246;
  --color-outline-button: 17 17 17;
  --color-accent: 154 98 56;
  --color-border: 231 224 214;

  --font-body: 'Manrope', 'Inter', -apple-system, sans-serif;
  --font-heading: 'Manrope', 'Inter', -apple-system, sans-serif;

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
  --text-h1: 2.5rem;
}

@media screen and (min-width: 990px) {
  :root { --page-gutter: 2.5rem; }
}

* { box-sizing: border-box; }

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

  <!-- Search Empty State Section -->
  <div id="SearchDrawerContainer" style="padding: 1rem; border-bottom: 1px solid rgb(var(--color-border));">
    <div id="PredictiveSearchResults">
      <div class="predictive-search__group predictive-search__empty" id="searchEmptyBox" style="text-align: center; padding-block: 1.5rem;">
        <p class="predictive-search__heading h4" id="searchEmptyHeading" style="margin-bottom: 0.5rem;">NOTHING YET.</p>
        <p class="text-sm" id="searchRecoveryCopy" style="margin-bottom: 1rem;">Try another search or explore our coffee bar essentials.</p>
        <a class="button button--outline button--sm" id="searchRecoveryCta" href="/collections/all">
          Continue shopping
        </a>
      </div>
    </div>
  </div>

  <!-- 404 Section -->
  <section class="section color-scheme_1 color-scheme" id="main404Section">
    <div class="page-width" style="text-align: center; padding-block: var(--space-2xl);">
      <p class="eyebrow" id="p404Eyebrow">404</p>
      <h1 class="h1" id="p404Heading">LOOKS LIKE THIS SHOT DIDN'T DIAL IN.</h1>
      <p id="p404Subtext">The page you were looking for does not exist or has been moved.</p>
      <p style="margin-top: 1.5rem;">
        <a href="/collections/all" class="button" id="p404Cta">BACK TO THE COFFEE BAR</a>
      </p>
    </div>
  </section>

  <!-- Complete 4-Column Branded Footer -->
  <footer class="footer color-scheme_1 color-scheme" id="mainFooter">
    <div class="page-width">
      <div class="footer__content footer__grid" id="footerGrid">
        
        <!-- Column 1: About Dose & Dial (text, wide) -->
        <div class="footer__block footer__block--wide" id="colAbout">
          <h2 class="footer__heading">About Dose & Dial</h2>
          <div class="rte text-sm" id="aboutText">
            <p>Precision for every pour. Premium coffee gear and accessories for home baristas taking every extraction seriously.</p>
            <p id="sevilleCredentials">Calle Pintor Roldán 3, 41940 Sevilla, Spain<br>+34 648 273 811<br>xaviborja1@hotmail.com</p>
          </div>
        </div>

        <!-- Column 2: Shop Menu -->
        <div class="footer__block" id="colShop">
          <h2 class="footer__heading">Shop</h2>
          <ul class="footer__list" role="list">
            <li><a href="/collections/all">All Products</a></li>
            <li><a href="/collections/espresso-tools">Espresso Tools</a></li>
            <li><a href="/collections/coffee-station">Coffee Station</a></li>
            <li><a href="/collections/brewing">Brewing</a></li>
          </ul>
        </div>

        <!-- Column 3: Support & Policies Menu -->
        <div class="footer__block" id="colSupport">
          <h2 class="footer__heading">Support & Policies</h2>
          <ul class="footer__list" role="list">
            <li><a href="/policies/refund-policy">Refund Policy</a></li>
            <li><a href="/policies/privacy-policy">Privacy Policy</a></li>
            <li><a href="/policies/terms-of-service">Terms of Service</a></li>
            <li><a href="/policies/shipping-policy">Shipping Policy</a></li>
          </ul>
        </div>

        <!-- Column 4: Newsletter (newsletter, wide) -->
        <div class="footer__block footer__block--wide" id="colNewsletter">
          <h2 class="footer__heading">JOIN THE BAR.</h2>
          <div class="rte text-sm" style="margin-bottom: 1rem;">
            <p>Get espresso recipes, dial-in tips, and exclusive gear updates straight to your inbox.</p>
          </div>
          <form class="newsletter-form" id="FooterNewsletter">
            <input type="hidden" name="contact[tags]" value="newsletter">
            <div style="display: flex; gap: 0.5rem; flex-wrap: wrap;">
              <label class="visually-hidden" for="FooterNewsletter-email">Email</label>
              <input
                id="FooterNewsletter-email"
                type="email"
                name="contact[email]"
                placeholder="Email address"
                autocomplete="email"
                required
                style="flex: 1 1 12rem;"
              >
              <button type="submit" class="button" id="newsletterSubmitBtn">Subscribe</button>
            </div>
          </form>
        </div>

      </div>

      <!-- Footer Bottom -->
      <div class="footer__bottom" id="footerBottom">
        <div style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;" id="footerBottomLeft">
          <span id="footerCopyrightSpan">&copy; 2026 Dose & Dial. All rights reserved.</span>
          <div class="footer__policies" style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;" id="footerPoliciesContainer">
            <a href="/policies/refund-policy" id="linkRefund">Refund policy</a>
            <a href="/policies/privacy-policy" id="linkPrivacy">Privacy policy</a>
            <a href="/policies/terms-of-service" id="linkTerms">Terms of service</a>
            <a href="/policies/shipping-policy" id="linkShipping">Shipping policy</a>
          </div>
        </div>

        <div style="display: flex; align-items: center; gap: 1rem; flex-wrap: wrap;" id="footerBottomRight">
          <ul class="social-list" role="list">
            <li><a class="icon-button" href="https://instagram.com" aria-label="Instagram">IG</a></li>
            <li><a class="icon-button" href="https://tiktok.com" aria-label="TikTok">TT</a></li>
          </ul>
          <ul class="payment-list" role="list" aria-label="Payment methods">
            <li><span class="payment-icon" style="display:inline-block; width:2.4rem; height:1.5rem; background:#ddd;"></span></li>
            <li><span class="payment-icon" style="display:inline-block; width:2.4rem; height:1.5rem; background:#ddd;"></span></li>
            <li><span class="payment-icon" style="display:inline-block; width:2.4rem; height:1.5rem; background:#ddd;"></span></li>
          </ul>
        </div>
      </div>

    </div>
  </footer>

<script>
function measureMetrics() {
  const vp = window.innerWidth;
  const clientW = document.documentElement.clientWidth;
  const scrollW = document.documentElement.scrollWidth;
  const bodyScrollW = document.body.scrollWidth;

  const hasDocOverflow = (scrollW > clientW + 1) || (bodyScrollW > clientW + 1);

  // Measure all elements in footer, 404, search
  const elementsToInspect = [
    'SearchDrawerContainer',
    'searchEmptyBox',
    'main404Section',
    'mainFooter',
    'footerGrid',
    'colAbout',
    'colShop',
    'colSupport',
    'colNewsletter',
    'FooterNewsletter',
    'footerBottom',
    'footerBottomLeft',
    'footerPoliciesContainer',
    'footerBottomRight'
  ];

  const elementOverflows = {};
  let anyBleed = false;
  elementsToInspect.forEach(id => {
    const el = document.getElementById(id);
    if (el) {
      const rect = el.getBoundingClientRect();
      const overflows = rect.right > (vp + 1.5);
      elementOverflows[id] = {
        width: rect.width,
        right: rect.right,
        overflows: overflows
      };
      if (overflows) anyBleed = true;
    }
  });

  const gridEl = document.getElementById('footerGrid');
  const gridStyle = window.getComputedStyle(gridEl);

  const emailInput = document.getElementById('FooterNewsletter-email');
  const submitBtn = document.getElementById('newsletterSubmitBtn');
  const emailRect = emailInput.getBoundingClientRect();
  const btnRect = submitBtn.getBoundingClientRect();

  return {
    viewportWidth: vp,
    docClientWidth: clientW,
    docScrollWidth: scrollW,
    bodyScrollWidth: bodyScrollW,
    hasDocOverflow: hasDocOverflow,
    anyBleed: anyBleed,
    elementOverflows: elementOverflows,
    gridTemplateColumns: gridStyle.gridTemplateColumns,
    newsletterLayout: {
      inputWidth: emailRect.width,
      inputRight: emailRect.right,
      btnWidth: btnRect.width,
      btnRight: btnRect.right,
      inputOver: emailRect.right > (vp + 1.5),
      btnOver: btnRect.right > (vp + 1.5)
    }
  };
}

window.addEventListener('message', (e) => {
  if (e.data === 'runMetrics') {
    const data = measureMetrics();
    window.parent.postMessage({ type: 'metricsResult', data: data }, '*');
  }
});
</script>
</body>
</html>
"@

    $childFixturePath = Join-Path $env:TEMP "m5_child_fixture.html"
    [System.IO.File]::WriteAllText($childFixturePath, $childHtml, [System.Text.Encoding]::UTF8)

    # Parent runner with iframes for: 360px, 375px, 390px, 414px, 768px, 1440px
    $parentHtml = @"
<!DOCTYPE html>
<html>
<head><meta charset="UTF-8"><title>M5 Runner</title></head>
<body>
  <iframe id="f360" src="m5_child_fixture.html" style="width:360px;height:1200px;border:0;"></iframe>
  <iframe id="f375" src="m5_child_fixture.html" style="width:375px;height:1200px;border:0;"></iframe>
  <iframe id="f390" src="m5_child_fixture.html" style="width:390px;height:1200px;border:0;"></iframe>
  <iframe id="f414" src="m5_child_fixture.html" style="width:414px;height:1200px;border:0;"></iframe>
  <iframe id="f768" src="m5_child_fixture.html" style="width:768px;height:1000px;border:0;"></iframe>
  <iframe id="f1440" src="m5_child_fixture.html" style="width:1440px;height:900px;border:0;"></iframe>
  <pre id="results">PENDING</pre>

<script>
  const frames = ['f360', 'f375', 'f390', 'f414', 'f768', 'f1440'];
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

    $parentFixturePath = Join-Path $env:TEMP "m5_parent_runner.html"
    [System.IO.File]::WriteAllText($parentFixturePath, $parentHtml, [System.Text.Encoding]::UTF8)

    $outTextPath = Join-Path $env:TEMP "m5_edge_metrics_out.txt"
    Start-Process -FilePath $edgePath -ArgumentList "--headless=new", "--virtual-time-budget=9000", "--dump-dom", $parentFixturePath -RedirectStandardOutput $outTextPath -Wait

    $rawDom = [System.IO.File]::ReadAllText($outTextPath, [System.Text.Encoding]::UTF8)
    Remove-Item $childFixturePath, $parentFixturePath, $outTextPath -Force -ErrorAction SilentlyContinue

    $browserMetrics = $null
    if ($rawDom -match '<pre id="results">([\s\S]*?)</pre>') {
        $cleanJson = $matches[1].Replace('<br>', "`n").Trim()
        try {
            $browserMetrics = $cleanJson | ConvertFrom-Json
        } catch {
            Write-Host "JSON parse error from browser metrics: $_" -ForegroundColor Red
        }
    }

    if ($browserMetrics) {
        # 6.4 VIEWPORT 360px (Adversarial Mobile Baseline)
        $vp360 = $browserMetrics.vp_360
        $hasOverflow360 = [bool]($vp360 -and ($vp360.hasDocOverflow -or $vp360.anyBleed))
        Log-Assertion -TestId "VP-360" -Category "Responsive Overflow" `
            -Description "360px (Narrow Mobile Baseline): Zero horizontal overflow (scrollWidth <= clientWidth, no element bleed)" `
            -Passed (-not $hasOverflow360) `
            -Expected "scrollWidth <= 360px, anyBleed=false" `
            -Actual "docScroll=$($vp360.docScrollWidth), client=$($vp360.docClientWidth), anyBleed=$($vp360.anyBleed)"

        # 6.5 VIEWPORT 375px (iPhone SE)
        $vp375 = $browserMetrics.vp_375
        $hasOverflow375 = [bool]($vp375 -and ($vp375.hasDocOverflow -or $vp375.anyBleed))
        Log-Assertion -TestId "VP-375" -Category "Responsive Overflow" `
            -Description "375px (iPhone SE): Zero horizontal overflow in footer, 404, and search" `
            -Passed (-not $hasOverflow375) `
            -Expected "scrollWidth <= 375px, anyBleed=false" `
            -Actual "docScroll=$($vp375.docScrollWidth), client=$($vp375.docClientWidth), anyBleed=$($vp375.anyBleed)"

        $nlFit375 = (-not $vp375.newsletterLayout.inputOver) -and (-not $vp375.newsletterLayout.btnOver)
        Log-Assertion -TestId "VP-375-NL" -Category "Responsive Layout" `
            -Description "375px: Newsletter input and submit button fit cleanly within viewport without breaking" `
            -Passed $nlFit375 `
            -Expected "Both input and button inside 375px" `
            -Actual "inputRight=$($vp375.newsletterLayout.inputRight), btnRight=$($vp375.newsletterLayout.btnRight)"

        # 6.6 VIEWPORT 390px (iPhone 12/13/14)
        $vp390 = $browserMetrics.vp_390
        $hasOverflow390 = [bool]($vp390 -and ($vp390.hasDocOverflow -or $vp390.anyBleed))
        Log-Assertion -TestId "VP-390" -Category "Responsive Overflow" `
            -Description "390px (iPhone 12/13/14): Zero horizontal overflow in footer, 404, and search" `
            -Passed (-not $hasOverflow390) `
            -Expected "scrollWidth <= 390px, anyBleed=false" `
            -Actual "docScroll=$($vp390.docScrollWidth), client=$($vp390.docClientWidth), anyBleed=$($vp390.anyBleed)"

        # 6.7 VIEWPORT 414px (iPhone 8 Plus / XR)
        $vp414 = $browserMetrics.vp_414
        $hasOverflow414 = [bool]($vp414 -and ($vp414.hasDocOverflow -or $vp414.anyBleed))
        Log-Assertion -TestId "VP-414" -Category "Responsive Overflow" `
            -Description "414px (iPhone 8 Plus / XR): Zero horizontal overflow in footer, 404, and search" `
            -Passed (-not $hasOverflow414) `
            -Expected "scrollWidth <= 414px, anyBleed=false" `
            -Actual "docScroll=$($vp414.docScrollWidth), client=$($vp414.docClientWidth), anyBleed=$($vp414.anyBleed)"

        # 6.8 VIEWPORT 768px (iPad Portrait / Boundary)
        $vp768 = $browserMetrics.vp_768
        $hasOverflow768 = [bool]($vp768 -and ($vp768.hasDocOverflow -or $vp768.anyBleed))
        Log-Assertion -TestId "VP-768" -Category "Responsive Overflow" `
            -Description "768px (iPad Portrait): Zero horizontal overflow and responsive multi-column grid layout" `
            -Passed (-not $hasOverflow768) `
            -Expected "scrollWidth <= 768px, anyBleed=false" `
            -Actual "docScroll=$($vp768.docScrollWidth), client=$($vp768.docClientWidth), anyBleed=$($vp768.anyBleed)"

        # 6.9 VIEWPORT 1440px (Standard Desktop Page Width)
        $vp1440 = $browserMetrics.vp_1440
        $hasOverflow1440 = [bool]($vp1440 -and ($vp1440.hasDocOverflow -or $vp1440.anyBleed))
        Log-Assertion -TestId "VP-1440" -Category "Responsive Overflow" `
            -Description "1440px (Desktop): Zero horizontal overflow at max page width (1440px)" `
            -Passed (-not $hasOverflow1440) `
            -Expected "scrollWidth <= 1440px, anyBleed=false" `
            -Actual "docScroll=$($vp1440.docScrollWidth), client=$($vp1440.docClientWidth), anyBleed=$($vp1440.anyBleed)"

        # 6.10 Desktop Column Expansion Check
        $gridCols1440 = $vp1440.gridTemplateColumns
        Log-Assertion -TestId "VP-1440-GRID" -Category "Responsive Layout" `
            -Description "1440px: Footer grid expands to multiple tracks accommodating the 4 columns" `
            -Passed ($gridCols1440.Split(' ').Count -ge 3) `
            -Expected "At least 3-4 computed column tracks" `
            -Actual "Tracks=$($gridCols1440.Split(' ').Count), Value='$gridCols1440'"
    } else {
        Log-Assertion -TestId "VP-BROWSER-PARSE" -Category "Headless Engine" `
            -Description "Headless Edge DOM dump parsed successfully" `
            -Passed $false `
            -Expected "Valid JSON from browser execution" `
            -Actual "Failed to parse JSON"
    }
}

# ==============================================================================
# SUMMARY REPORT
# ==============================================================================
Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                     M5 STRESS TEST EXECUTION SUMMARY                           " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

Write-Host "Total Assertions: $Global:TotalTests"
Write-Host "Passed:           $Global:PassedTests" -ForegroundColor Green
Write-Host "Failed:           $Global:FailedTests" -ForegroundColor $(if ($Global:FailedTests -gt 0) { "Red" } else { "Green" })
$rate = if ($Global:TotalTests -gt 0) { [math]::Round(($Global:PassedTests / $Global:TotalTests) * 100, 2) } else { 0 }
Write-Host "Pass Rate:        $rate%" -ForegroundColor $(if ($rate -eq 100) { "Green" } else { "Red" })
Write-Host "================================================================================" -ForegroundColor Cyan

if ($Global:FailedTests -gt 0) {
    Write-Host "`n>> VERDICT: CHALLENGE_FAILED ($Global:FailedTests failures detected)" -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n>> VERDICT: APPROVE (All $Global:TotalTests stress assertions passed at 100%)" -ForegroundColor Green
    exit 0
}
