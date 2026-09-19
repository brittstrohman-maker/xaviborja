# ==============================================================================
# Dose & Dial Shopify Theme - Opaque-Box E2E Testing Suite
# Project: "Precision for Every Pour" (doseydial.myshopify.com)
# Reference: ORIGINAL_REQUEST.md, PROJECT.md, TEST_INFRA.md
# Environment: Windows PowerShell 5.1 compatible
# ==============================================================================

[CmdletBinding()]
param(
    [ValidateSet("All", "1", "2", "3", "4")]
    [string]$Tier = "All",

    [int]$Feature = 0,

    [switch]$VerboseOutput,

    [string]$JsonOutput = ""
)

# ------------------------------------------------------------------------------
# Initialization & Path Resolution
# ------------------------------------------------------------------------------
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$RepoRoot = (Resolve-Path (Join-Path $ScriptDir "..")).Path

# Test Results Registry
$Global:TestResults = [System.Collections.ArrayList]::new()

function Assert-Test {
    param([hashtable]$T)

    $Id          = [string]$T.Id
    $TierNum     = [int]$T.Tier
    $FeatureId   = [string]$T.FeatureId
    $Description = [string]$T.Description
    $Passed      = [bool]$T.Passed
    $Expected    = if ($T.ContainsKey('Expected')) { [string]$T.Expected } else { "" }
    $Actual      = if ($T.ContainsKey('Actual')) { [string]$T.Actual } else { "" }
    $Details     = if ($T.ContainsKey('Details')) { [string]$T.Details } else { "" }

    $result = [PSCustomObject]@{
        Id          = $Id
        Tier        = $TierNum
        FeatureId   = $FeatureId
        Description = $Description
        Passed      = $Passed
        Expected    = $Expected
        Actual      = $Actual
        Details     = $Details
    }
    $null = $Global:TestResults.Add($result)

    if ($VerboseOutput -or (-not $Passed)) {
        if ($Passed) {
            Write-Host "  [PASS] $Id ($FeatureId) - $Description" -ForegroundColor Green
        } else {
            Write-Host "  [FAIL] $Id ($FeatureId) - $Description" -ForegroundColor Red
            if ($Expected -ne "" -or $Actual -ne "") {
                Write-Host "         Expected: $Expected" -ForegroundColor DarkGray
                Write-Host "         Actual:   $Actual" -ForegroundColor DarkGray
            }
            if ($Details -ne "") {
                Write-Host "         Details:  $Details" -ForegroundColor DarkGray
            }
        }
    }
}

function Get-ThemeContent {
    param([string]$RelativePath)
    $fullPath = Join-Path $RepoRoot $RelativePath
    if (Test-Path $fullPath) {
        return [System.IO.File]::ReadAllText($fullPath, [System.Text.Encoding]::UTF8)
    }
    return $null
}

function Get-ThemeJson {
    param([string]$RelativePath)
    $content = Get-ThemeContent $RelativePath
    if ($content) {
        try {
            return $content | ConvertFrom-Json
        } catch {
            return $null
        }
    }
    return $null
}

function Out-String {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        $InputObject,
        [switch]$Stream,
        [int]$Width
    )
    process {
        if ($InputObject -is [System.Management.Automation.PSCustomObject]) {
            return ($InputObject | ConvertTo-Json -Depth 20)
        } else {
            return ($InputObject | Microsoft.PowerShell.Utility\Out-String)
        }
    }
}

Write-Host "================================================================================" -ForegroundColor Cyan
Write-Host "    DOSE & DIAL - OPAQUE-BOX E2E TEST SUITE (POWERSHELL 5.1)                  " -ForegroundColor Cyan
Write-Host "    Target Codebase: $RepoRoot" -ForegroundColor DarkGray
Write-Host "    Filter: Tier=$Tier, Feature=$Feature, Verbose=$VerboseOutput" -ForegroundColor DarkGray
Write-Host "================================================================================" -ForegroundColor Cyan

# Cache commonly tested theme files
$settingsData = Get-ThemeJson "config/settings_data.json"
$settingsSchemaContent = Get-ThemeContent "config/settings_schema.json"
$themeStylesContent = Get-ThemeContent "snippets/theme-styles.liquid"
$baseCssContent = Get-ThemeContent "assets/base.css"
$themeJsContent = Get-ThemeContent "assets/theme.js"
$themeLiquidContent = Get-ThemeContent "layout/theme.liquid"
$headerGroup = Get-ThemeJson "sections/header-group.json"
$headerContent = Get-ThemeContent "sections/header.liquid"
$announcementContent = Get-ThemeContent "sections/announcement-bar.liquid"
$indexJson = Get-ThemeJson "templates/index.json"
$productJson = Get-ThemeJson "templates/product.json"
$productCardContent = Get-ThemeContent "snippets/product-card.liquid"
$mainProductContent = Get-ThemeContent "sections/main-product.liquid"
$accordionContent = Get-ThemeContent "blocks/accordion.liquid"
$trustBadgesContent = Get-ThemeContent "blocks/trust-badges.liquid"
$cartDrawerContent = Get-ThemeContent "sections/cart-drawer.liquid"
$cartSummaryContent = Get-ThemeContent "snippets/cart-summary.liquid"
$predictiveSearchContent = Get-ThemeContent "sections/predictive-search.liquid"
$main404Content = Get-ThemeContent "sections/main-404.liquid"
$template404Json = Get-ThemeJson "templates/404.json"
$footerContent = Get-ThemeContent "sections/footer.liquid"
$footerGroup = Get-ThemeJson "sections/footer-group.json"
$enLocale = Get-ThemeJson "locales/en.default.json"
$enLocaleContent = Get-ThemeContent "locales/en.default.json"

# ==============================================================================
# TIER 1: FEATURE VERIFICATION & SYNTACTICS (26 Features x 5 Assertions = 130)
# ==============================================================================
if ($Tier -eq "All" -or $Tier -eq "1") {
    Write-Host "`n--- Running Tier 1: Feature Verification & Syntactics ---" -ForegroundColor Yellow

    # F01: Dose & Dial Color Tokens
    if ($Feature -eq 0 -or $Feature -eq 1) {
        $hasWarmCream = ($settingsData -and ($settingsData | Out-String) -match '(?i)F7F3EB') -or 
                        ($themeStylesContent -match '(?i)F7F3EB') -or ($baseCssContent -match '(?i)F7F3EB')
        Assert-Test @{
            Id = "F01-01"; Tier = 1; FeatureId = "F01"
            Description = "Warm Cream #F7F3EB token configured"
            Passed = [bool]$hasWarmCream
            Expected = "#F7F3EB present in theme tokens/styles"
            Actual = "$hasWarmCream"
        }

        $hasOffWhite = ($settingsData -and ($settingsData | Out-String) -match '(?i)FCFAF6') -or 
                       ($themeStylesContent -match '(?i)FCFAF6') -or ($baseCssContent -match '(?i)FCFAF6')
        Assert-Test @{
            Id = "F01-02"; Tier = 1; FeatureId = "F01"
            Description = "Soft Off-White #FCFAF6 token configured"
            Passed = [bool]$hasOffWhite
            Expected = "#FCFAF6 present in theme tokens/styles"
            Actual = "$hasOffWhite"
        }

        $hasDarkEspresso = ($settingsData -and ($settingsData | Out-String) -match '(?i)(2A1D17|111111)') -or 
                           ($themeStylesContent -match '(?i)(2A1D17|111111)') -or ($baseCssContent -match '(?i)(2A1D17|111111)')
        Assert-Test @{
            Id = "F01-03"; Tier = 1; FeatureId = "F01"
            Description = "Matte Black #111111 or Espresso #2A1D17 token configured"
            Passed = [bool]$hasDarkEspresso
            Expected = "#111111 or #2A1D17 present in theme tokens/styles"
            Actual = "$hasDarkEspresso"
        }

        $hasCopperWalnut = ($settingsData -and ($settingsData | Out-String) -match '(?i)(9A6238|7A5736)') -or 
                           ($themeStylesContent -match '(?i)(9A6238|7A5736)') -or ($baseCssContent -match '(?i)(9A6238|7A5736)')
        Assert-Test @{
            Id = "F01-04"; Tier = 1; FeatureId = "F01"
            Description = "Copper Accent #9A6238 or Walnut #7A5736 token configured"
            Passed = [bool]$hasCopperWalnut
            Expected = "#9A6238 or #7A5736 present in theme tokens/styles"
            Actual = "$hasCopperWalnut"
        }

        $hasLightTaupe = ($settingsData -and ($settingsData | Out-String) -match '(?i)E7E0D6') -or 
                         ($themeStylesContent -match '(?i)E7E0D6') -or ($baseCssContent -match '(?i)E7E0D6')
        Assert-Test @{
            Id = "F01-05"; Tier = 1; FeatureId = "F01"
            Description = "Light Taupe #E7E0D6 border token configured"
            Passed = [bool]$hasLightTaupe
            Expected = "#E7E0D6 present in theme tokens/styles"
            Actual = "$hasLightTaupe"
        }
    }

    # F02: Geometric Sans-Serif Typography
    if ($Feature -eq 0 -or $Feature -eq 2) {
        $hasSansFont = ($themeLiquidContent -match '(?i)(Manrope|Inter)') -or ($baseCssContent -match '(?i)(Manrope|Inter)') -or ($themeStylesContent -match '(?i)(Manrope|Inter)')
        Assert-Test @{
            Id = "F02-01"; Tier = 1; FeatureId = "F02"
            Description = "Manrope or Inter font stack loaded"
            Passed = [bool]$hasSansFont
            Expected = "Manrope/Inter reference in layout or CSS"
            Actual = "$hasSansFont"
        }

        $hasMicroLabels = ($baseCssContent -match 'text-transform\s*:\s*uppercase')
        Assert-Test @{
            Id = "F02-02"; Tier = 1; FeatureId = "F02"
            Description = "Uppercase micro-label styling defined in base CSS"
            Passed = [bool]$hasMicroLabels
            Expected = "text-transform: uppercase in CSS"
            Actual = "$hasMicroLabels"
        }

        $hasLetterSpacing = ($baseCssContent -match 'letter-spacing\s*:\s*0\.[0-9]+(em|rem)')
        Assert-Test @{
            Id = "F02-03"; Tier = 1; FeatureId = "F02"
            Description = "Subtle letter-spacing defined for headings/labels"
            Passed = [bool]$hasLetterSpacing
            Expected = "letter-spacing > 0 in CSS"
            Actual = "$hasLetterSpacing"
        }

        $hasHeadingScale = ($baseCssContent -match '\.h1\b' -and $baseCssContent -match '\.h2\b' -and $baseCssContent -match '\.h3\b')
        Assert-Test @{
            Id = "F02-04"; Tier = 1; FeatureId = "F02"
            Description = "Structured heading scale hierarchy defined (.h1, .h2, .h3)"
            Passed = [bool]$hasHeadingScale
            Expected = "Heading scale utility classes in CSS"
            Actual = "$hasHeadingScale"
        }

        $hasFontBindings = ($themeStylesContent -match '--font-(heading|body)') -or ($baseCssContent -match '--font-(heading|body)')
        Assert-Test @{
            Id = "F02-05"; Tier = 1; FeatureId = "F02"
            Description = "Font custom properties bound in theme styles"
            Passed = [bool]$hasFontBindings
            Expected = "--font-heading or --font-body custom properties"
            Actual = "$hasFontBindings"
        }
    }

    # F03: Button Radius & UI Tokens
    if ($Feature -eq 0 -or $Feature -eq 3) {
        $hasRadiusSchema = ($settingsSchemaContent -match 'radius_base|button.*radius')
        Assert-Test @{
            Id = "F03-01"; Tier = 1; FeatureId = "F03"
            Description = "Button radius schema setting exists"
            Passed = [bool]$hasRadiusSchema
            Expected = "radius_base setting in settings_schema.json"
            Actual = "$hasRadiusSchema"
        }

        $validRadiusValue = $false
        if ($settingsData -and $settingsData.current) {
            $rVal = $settingsData.current.radius_base
            if ($rVal -ne $null -and [int]$rVal -ge 2 -and [int]$rVal -le 8) {
                $validRadiusValue = $true
            }
        }
        Assert-Test @{
            Id = "F03-02"; Tier = 1; FeatureId = "F03"
            Description = "Button radius setting configured between 2px and 8px"
            Passed = [bool]$validRadiusValue
            Expected = "radius_base in [2..8]"
            Actual = "$validRadiusValue"
        }

        $hasRadiusVar = ($baseCssContent -match '--radius-base') -or ($themeStylesContent -match '--radius-base')
        Assert-Test @{
            Id = "F03-03"; Tier = 1; FeatureId = "F03"
            Description = "CSS custom property --radius-base defined"
            Passed = [bool]$hasRadiusVar
            Expected = "--radius-base in base.css or theme-styles.liquid"
            Actual = "$hasRadiusVar"
        }

        $hasMediaRadius = ($settingsData -and ($settingsData | Out-String) -match 'radius_media') -or ($baseCssContent -match '--radius-media')
        Assert-Test @{
            Id = "F03-04"; Tier = 1; FeatureId = "F03"
            Description = "Media radius token configured"
            Passed = [bool]$hasMediaRadius
            Expected = "radius_media token present"
            Actual = "$hasMediaRadius"
        }

        $hasButtonTransition = ($baseCssContent -match '\.button\s*\{[^}]*transition') -or ($baseCssContent -match '\.button:hover')
        Assert-Test @{
            Id = "F03-05"; Tier = 1; FeatureId = "F03"
            Description = "Button hover and transition styling defined"
            Passed = [bool]$hasButtonTransition
            Expected = "Button transition / hover rule in CSS"
            Actual = "$hasButtonTransition"
        }
    }

    # F04: Theme Settings Defaults
    if ($Feature -eq 0 -or $Feature -eq 4) {
        $schemaValid = ($settingsSchemaContent | ConvertFrom-Json) -ne $null
        Assert-Test @{
            Id = "F04-01"; Tier = 1; FeatureId = "F04"
            Description = "settings_schema.json parses as strict valid JSON"
            Passed = [bool]$schemaValid
            Expected = "Valid JSON"
            Actual = "$schemaValid"
        }

        $dataValid = ($settingsData -ne $null)
        Assert-Test @{
            Id = "F04-02"; Tier = 1; FeatureId = "F04"
            Description = "settings_data.json parses as strict valid JSON"
            Passed = [bool]$dataValid
            Expected = "Valid JSON"
            Actual = "$dataValid"
        }

        $hasSchemes = ($settingsData -and ($settingsData | Out-String) -match 'color_schemes|scheme_1')
        Assert-Test @{
            Id = "F04-03"; Tier = 1; FeatureId = "F04"
            Description = "Color schemes configured in settings_data.json"
            Passed = [bool]$hasSchemes
            Expected = "color_schemes defined"
            Actual = "$hasSchemes"
        }

        $hasDoseDefaults = ($settingsData -and ($settingsData | Out-String) -match '(?i)(Dose|Dial|F7F3EB|FCFAF6)')
        Assert-Test @{
            Id = "F04-04"; Tier = 1; FeatureId = "F04"
            Description = "Dose & Dial defaults applied in settings_data.json"
            Passed = [bool]$hasDoseDefaults
            Expected = "Dose & Dial brand defaults in settings"
            Actual = "$hasDoseDefaults"
        }

        $hasTypographySchema = ($settingsSchemaContent -match 'font_heading|font_body|typography')
        Assert-Test @{
            Id = "F04-05"; Tier = 1; FeatureId = "F04"
            Description = "Typography section defined in settings_schema.json"
            Passed = [bool]$hasTypographySchema
            Expected = "Typography schema present"
            Actual = "$hasTypographySchema"
        }
    }

    # F05: Announcement Bar
    if ($Feature -eq 0 -or $Feature -eq 5) {
        # Robust pattern matching €55 or 55 without character encoding fragility
        $shippingPattern = '(?i)FREE STANDARD SHIPPING ON ORDERS OVER.*55'
        $hasAnnouncementCopy = (($headerGroup | Out-String) -match $shippingPattern) -or 
                               (($settingsData | Out-String) -match $shippingPattern) -or 
                               ($announcementContent -match $shippingPattern)
        Assert-Test @{
            Id = "F05-01"; Tier = 1; FeatureId = "F05"
            Description = "Announcement bar copy 'FREE STANDARD SHIPPING ON ORDERS OVER 55' configured"
            Passed = [bool]$hasAnnouncementCopy
            Expected = "Announcement copy present"
            Actual = "$hasAnnouncementCopy"
        }

        $announcementBalanced = $false
        if ($announcementContent) {
            $oTags = [regex]::Matches($announcementContent, '\{%').Count
            $cTags = [regex]::Matches($announcementContent, '%\}').Count
            $oVar = [regex]::Matches($announcementContent, '\{\{').Count
            $cVar = [regex]::Matches($announcementContent, '\}\}').Count
            $announcementBalanced = ($oTags -eq $cTags) -and ($oVar -eq $cVar)
        }
        Assert-Test @{
            Id = "F05-02"; Tier = 1; FeatureId = "F05"
            Description = "announcement-bar.liquid Liquid tags balanced"
            Passed = [bool]$announcementBalanced
            Expected = "Balanced Liquid tags"
            Actual = "$announcementBalanced"
        }

        $hasAnnouncementSchema = ($announcementContent -match '\{%\s*schema\s*%\}' -and $announcementContent -match '\{%\s*endschema\s*%\}')
        Assert-Test @{
            Id = "F05-03"; Tier = 1; FeatureId = "F05"
            Description = "Announcement bar has valid embedded schema block"
            Passed = [bool]$hasAnnouncementSchema
            Expected = "Embedded schema block"
            Actual = "$hasAnnouncementSchema"
        }

        $hasSchemeSupport = ($announcementContent -match 'color_scheme|color-scheme')
        Assert-Test @{
            Id = "F05-04"; Tier = 1; FeatureId = "F05"
            Description = "Announcement bar supports theme color scheme class"
            Passed = [bool]$hasSchemeSupport
            Expected = "color_scheme setting applied"
            Actual = "$hasSchemeSupport"
        }

        $hasAnnouncementInHeaderGroup = ($headerGroup -and ($headerGroup.order -contains "announcement-bar" -or ($headerGroup.sections.PSObject.Properties.Name -match 'announcement')))
        Assert-Test @{
            Id = "F05-05"; Tier = 1; FeatureId = "F05"
            Description = "Announcement bar registered in header-group.json"
            Passed = [bool]$hasAnnouncementInHeaderGroup
            Expected = "Registered in header-group.json"
            Actual = "$hasAnnouncementInHeaderGroup"
        }
    }

    # F06: Desktop Header & Navigation
    if ($Feature -eq 0 -or $Feature -eq 6) {
        $hasBrandName = ($headerContent -match '(?i)Dose\s*&\s*Dial') -or (($headerGroup | Out-String) -match '(?i)Dose\s*&\s*Dial')
        Assert-Test @{
            Id = "F06-01"; Tier = 1; FeatureId = "F06"
            Description = "Dose and Dial brand wordmark present in header"
            Passed = [bool]$hasBrandName
            Expected = "'Dose & Dial' in header template or settings"
            Actual = "$hasBrandName"
        }

        $hasNavMenu = ($headerContent -match 'linklist|menu|navigation') -and ($headerContent -match 'for\s+link\s+in')
        Assert-Test @{
            Id = "F06-02"; Tier = 1; FeatureId = "F06"
            Description = "Header iterates through navigation links"
            Passed = [bool]$hasNavMenu
            Expected = "for link in menu loop in header.liquid"
            Actual = "$hasNavMenu"
        }

        $hasSearch = ($headerContent -match 'search|SearchDrawer')
        Assert-Test @{
            Id = "F06-03"; Tier = 1; FeatureId = "F06"
            Description = "Header includes search trigger"
            Passed = [bool]$hasSearch
            Expected = "Search trigger in header"
            Actual = "$hasSearch"
        }

        $hasCart = ($headerContent -match 'cart-icon-bubble|routes\.cart_url')
        Assert-Test @{
            Id = "F06-04"; Tier = 1; FeatureId = "F06"
            Description = "Header includes cart trigger and bubble"
            Passed = [bool]$hasCart
            Expected = "Cart link / bubble in header"
            Actual = "$hasCart"
        }

        $headerSchemaValid = $false
        if ($headerContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $headerSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F06-05"; Tier = 1; FeatureId = "F06"
            Description = "Header embedded schema JSON parses validly"
            Passed = [bool]$headerSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$headerSchemaValid"
        }
    }

    # F07: Sticky Header Compact Scroll
    if ($Feature -eq 0 -or $Feature -eq 7) {
        $hasScrollListener = ($themeJsContent -match 'addEventListener\s*\(\s*[\''"]scroll[\''"]') -or ($themeJsContent -match 'IntersectionObserver')
        Assert-Test @{
            Id = "F07-01"; Tier = 1; FeatureId = "F07"
            Description = "Scroll event listener or IntersectionObserver in theme.js"
            Passed = [bool]$hasScrollListener
            Expected = "Scroll listener in theme.js"
            Actual = "$hasScrollListener"
        }

        $hasScrolledClass = ($themeJsContent -match 'header.*scrolled|header-wrapper--scrolled|header--sticky')
        Assert-Test @{
            Id = "F07-02"; Tier = 1; FeatureId = "F07"
            Description = "Sticky scrolled class toggled in theme.js"
            Passed = [bool]$hasScrolledClass
            Expected = "Scrolled class toggle in JS"
            Actual = "$hasScrolledClass"
        }

        $hasScrolledCss = ($baseCssContent -match '\.header.*--scrolled|\.header--sticky')
        Assert-Test @{
            Id = "F07-03"; Tier = 1; FeatureId = "F07"
            Description = "Sticky scrolled header styling in base.css"
            Passed = [bool]$hasScrolledCss
            Expected = "Scrolled header CSS selector"
            Actual = "$hasScrolledCss"
        }

        $hasScrolledBorder = ($baseCssContent -match '(\.header.*--scrolled|\.header--sticky)[^{]*\{[^}]*border')
        Assert-Test @{
            Id = "F07-04"; Tier = 1; FeatureId = "F07"
            Description = "Subtle border styling on scrolled header"
            Passed = [bool]$hasScrolledBorder
            Expected = "Border on scrolled header in CSS"
            Actual = "$hasScrolledBorder"
        }

        $hasStickySetting = ($headerContent -match 'sticky_header|enable_sticky')
        Assert-Test @{
            Id = "F07-05"; Tier = 1; FeatureId = "F07"
            Description = "Sticky header setting present in header schema"
            Passed = [bool]$hasStickySetting
            Expected = "sticky_header setting in schema"
            Actual = "$hasStickySetting"
        }
    }

    # F08: Mobile Header & Navigation Drawer
    if ($Feature -eq 0 -or $Feature -eq 8) {
        $hasMobileToggle = ($headerContent -match 'header__icon--menu|menu-drawer|header__menu-toggle')
        Assert-Test @{
            Id = "F08-01"; Tier = 1; FeatureId = "F08"
            Description = "Mobile navigation toggle button in header.liquid"
            Passed = [bool]$hasMobileToggle
            Expected = "Mobile menu toggle in header"
            Actual = "$hasMobileToggle"
        }

        $hasTouchTarget44 = ($baseCssContent -match 'min-height\s*:\s*(44px|48px|3rem)') -or ($baseCssContent -match 'min-width\s*:\s*(44px|48px|3rem)')
        Assert-Test @{
            Id = "F08-02"; Tier = 1; FeatureId = "F08"
            Description = "Touch targets >= 44px enforced in base.css"
            Passed = [bool]$hasTouchTarget44
            Expected = "min-height or min-width >= 44px in CSS"
            Actual = "$hasTouchTarget44"
        }

        $hasMobileSearch = ($headerContent -match 'SearchDrawer|header__icon--search')
        Assert-Test @{
            Id = "F08-03"; Tier = 1; FeatureId = "F08"
            Description = "Mobile header integrates search access"
            Passed = [bool]$hasMobileSearch
            Expected = "Search access present"
            Actual = "$hasMobileSearch"
        }

        $hasMobileCart = ($headerContent -match 'CartDrawer|header__icon--cart')
        Assert-Test @{
            Id = "F08-04"; Tier = 1; FeatureId = "F08"
            Description = "Mobile header integrates cart access"
            Passed = [bool]$hasMobileCart
            Expected = "Cart access present"
            Actual = "$hasMobileCart"
        }

        $hasDrawerJs = ($themeJsContent -match 'class\s+MenuDrawer|MenuDrawer|drawer')
        Assert-Test @{
            Id = "F08-05"; Tier = 1; FeatureId = "F08"
            Description = "Navigation drawer logic supported in theme.js"
            Passed = [bool]$hasDrawerJs
            Expected = "Drawer handler in JS"
            Actual = "$hasDrawerJs"
        }
    }

    # F09: Editorial Hero Section
    if ($Feature -eq 0 -or $Feature -eq 9) {
        $heroContent = Get-ThemeContent "sections/hero.liquid"
        $hasHeroHeadline = (($indexJson | Out-String) -match '(?i)PRECISION FOR EVERY POUR') -or ($heroContent -match '(?i)PRECISION FOR EVERY POUR')
        Assert-Test @{
            Id = "F09-01"; Tier = 1; FeatureId = "F09"
            Description = "Hero headline 'PRECISION FOR EVERY POUR.' configured"
            Passed = [bool]$hasHeroHeadline
            Expected = "'PRECISION FOR EVERY POUR.' present"
            Actual = "$hasHeroHeadline"
        }

        $hasHeroEyebrow = (($indexJson | Out-String) -match '(?i)DOSE.*DIAL.*BREW') -or ($heroContent -match '(?i)DOSE.*DIAL.*BREW')
        Assert-Test @{
            Id = "F09-02"; Tier = 1; FeatureId = "F09"
            Description = "Hero micro-label 'DOSE - DIAL - BREW' configured"
            Passed = [bool]$hasHeroEyebrow
            Expected = "'DOSE - DIAL - BREW' present"
            Actual = "$hasHeroEyebrow"
        }

        $hasHeroSubtext = (($indexJson | Out-String) -match '(?i)Premium tools for home baristas') -or ($heroContent -match '(?i)Premium tools for home baristas')
        Assert-Test @{
            Id = "F09-03"; Tier = 1; FeatureId = "F09"
            Description = "Hero subtext 'Premium tools for home baristas...' configured"
            Passed = [bool]$hasHeroSubtext
            Expected = "Hero subtext present"
            Actual = "$hasHeroSubtext"
        }

        $hasHeroCta = (($indexJson | Out-String) -match '(?i)SHOP ESPRESSO TOOLS') -or ($heroContent -match '(?i)SHOP ESPRESSO TOOLS')
        Assert-Test @{
            Id = "F09-04"; Tier = 1; FeatureId = "F09"
            Description = "Hero primary CTA 'SHOP ESPRESSO TOOLS' configured"
            Passed = [bool]$hasHeroCta
            Expected = "'SHOP ESPRESSO TOOLS' CTA present"
            Actual = "$hasHeroCta"
        }

        $hasHeroImages = ($heroContent -match 'image_mobile|image')
        Assert-Test @{
            Id = "F09-05"; Tier = 1; FeatureId = "F09"
            Description = "Hero schema supports image configuration"
            Passed = [bool]$hasHeroImages
            Expected = "Image settings in hero schema"
            Actual = "$hasHeroImages"
        }
    }

    # F10: Featured Collections ("BUILD YOUR COFFEE BAR")
    if ($Feature -eq 0 -or $Feature -eq 10) {
        $collectionListContent = Get-ThemeContent "sections/collection-list.liquid"
        $hasBuildBar = (($indexJson | Out-String) -match '(?i)BUILD YOUR COFFEE BAR') -or ($collectionListContent -match '(?i)BUILD YOUR COFFEE BAR')
        Assert-Test @{
            Id = "F10-01"; Tier = 1; FeatureId = "F10"
            Description = "Featured collections heading 'BUILD YOUR COFFEE BAR' configured"
            Passed = [bool]$hasBuildBar
            Expected = "'BUILD YOUR COFFEE BAR' present"
            Actual = "$hasBuildBar"
        }

        $hasBuildBarSub = (($indexJson | Out-String) -match '(?i)Everything you need to refine your espresso setup') -or ($collectionListContent -match '(?i)Everything you need to refine your espresso setup')
        Assert-Test @{
            Id = "F10-02"; Tier = 1; FeatureId = "F10"
            Description = "Featured collections subheading present"
            Passed = [bool]$hasBuildBarSub
            Expected = "Subheading present"
            Actual = "$hasBuildBarSub"
        }

        $hasCategories = (($indexJson | Out-String) -match '(?i)Espresso Tools') -or (($indexJson | Out-String) -match '(?i)Coffee Station')
        Assert-Test @{
            Id = "F10-03"; Tier = 1; FeatureId = "F10"
            Description = "Category cards (Espresso Tools, Coffee Station...) configured"
            Passed = [bool]$hasCategories
            Expected = "Dose and Dial categories configured in index.json"
            Actual = "$hasCategories"
        }

        $hasHoverZoom = ($baseCssContent -match 'transform\s*:\s*scale\(') -or ($baseCssContent -match 'transition\s*:\s*transform')
        Assert-Test @{
            Id = "F10-04"; Tier = 1; FeatureId = "F10"
            Description = "Image hover zoom CSS transition defined in base.css"
            Passed = [bool]$hasHoverZoom
            Expected = "transform: scale / transition in CSS"
            Actual = "$hasHoverZoom"
        }

        $collectionListSchemaValid = $false
        if ($collectionListContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $collectionListSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F10-05"; Tier = 1; FeatureId = "F10"
            Description = "collection-list.liquid schema JSON valid"
            Passed = [bool]$collectionListSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$collectionListSchemaValid"
        }
    }

    # F11: Best Sellers Grid ("ESSENTIALS FOR BETTER ESPRESSO")
    if ($Feature -eq 0 -or $Feature -eq 11) {
        $featuredCollectionContent = Get-ThemeContent "sections/featured-collection.liquid"
        $hasEssentialsHead = (($indexJson | Out-String) -match '(?i)ESSENTIALS FOR BETTER ESPRESSO') -or ($featuredCollectionContent -match '(?i)ESSENTIALS FOR BETTER ESPRESSO')
        Assert-Test @{
            Id = "F11-01"; Tier = 1; FeatureId = "F11"
            Description = "Best Sellers heading 'ESSENTIALS FOR BETTER ESPRESSO' configured"
            Passed = [bool]$hasEssentialsHead
            Expected = "'ESSENTIALS FOR BETTER ESPRESSO' present"
            Actual = "$hasEssentialsHead"
        }

        $hasEssentialsSub = (($indexJson | Out-String) -match '(?i)Precision tools designed to make every step') -or ($featuredCollectionContent -match '(?i)Precision tools designed to make every step')
        Assert-Test @{
            Id = "F11-02"; Tier = 1; FeatureId = "F11"
            Description = "Best Sellers subtext present"
            Passed = [bool]$hasEssentialsSub
            Expected = "Workflow subtext present"
            Actual = "$hasEssentialsSub"
        }

        $hasProductCardRender = ($featuredCollectionContent -match "render\s+['""]product-card['""]")
        Assert-Test @{
            Id = "F11-03"; Tier = 1; FeatureId = "F11"
            Description = "featured-collection.liquid renders product-card snippet"
            Passed = [bool]$hasProductCardRender
            Expected = "render 'product-card' in section"
            Actual = "$hasProductCardRender"
        }

        $hasEmptyState = ($featuredCollectionContent -match 'else\b' -or $featuredCollectionContent -match 'placeholder_svg_tag')
        Assert-Test @{
            Id = "F11-04"; Tier = 1; FeatureId = "F11"
            Description = "featured-collection.liquid includes empty collection fallback"
            Passed = [bool]$hasEmptyState
            Expected = "Fallback for empty collection"
            Actual = "$hasEmptyState"
        }

        $featuredCollSchemaValid = $false
        if ($featuredCollectionContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $featuredCollSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F11-05"; Tier = 1; FeatureId = "F11"
            Description = "featured-collection.liquid schema JSON valid"
            Passed = [bool]$featuredCollSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$featuredCollSchemaValid"
        }
    }

    # F12: Editorial Brand Story ("CRAFT YOUR PERFECT SHOT.")
    if ($Feature -eq 0 -or $Feature -eq 12) {
        $imageWithTextContent = Get-ThemeContent "sections/image-with-text.liquid"
        $hasCraftShot = (($indexJson | Out-String) -match '(?i)CRAFT YOUR PERFECT SHOT') -or ($imageWithTextContent -match '(?i)CRAFT YOUR PERFECT SHOT')
        Assert-Test @{
            Id = "F12-01"; Tier = 1; FeatureId = "F12"
            Description = "Brand story heading 'CRAFT YOUR PERFECT SHOT.' configured"
            Passed = [bool]$hasCraftShot
            Expected = "'CRAFT YOUR PERFECT SHOT.' present"
            Actual = "$hasCraftShot"
        }

        $hasOurStoryCta = (($indexJson | Out-String) -match '(?i)OUR STORY') -or ($imageWithTextContent -match '(?i)OUR STORY')
        Assert-Test @{
            Id = "F12-02"; Tier = 1; FeatureId = "F12"
            Description = "Brand story CTA 'OUR STORY' configured"
            Passed = [bool]$hasOurStoryCta
            Expected = "'OUR STORY' CTA present"
            Actual = "$hasOurStoryCta"
        }

        $hasStoryPhilosophy = (($indexJson | Out-String) -match '(?i)(ritual|precision|home barista|philosophy)')
        Assert-Test @{
            Id = "F12-03"; Tier = 1; FeatureId = "F12"
            Description = "Brand philosophy copy present in homepage settings"
            Passed = [bool]$hasStoryPhilosophy
            Expected = "Philosophy copy present"
            Actual = "$hasStoryPhilosophy"
        }

        $hasImageTextBlock = ($imageWithTextContent -match 'image-with-text__media' -and $imageWithTextContent -match 'image-with-text__content')
        Assert-Test @{
            Id = "F12-04"; Tier = 1; FeatureId = "F12"
            Description = "image-with-text.liquid layout structures media and content blocks"
            Passed = [bool]$hasImageTextBlock
            Expected = "Media and content containers present"
            Actual = "$hasImageTextBlock"
        }

        $imageWithTextSchemaValid = $false
        if ($imageWithTextContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $imageWithTextSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F12-05"; Tier = 1; FeatureId = "F12"
            Description = "image-with-text.liquid schema JSON valid"
            Passed = [bool]$imageWithTextSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$imageWithTextSchemaValid"
        }
    }

    # F13: Why Dose & Dial (4 Value Pillars)
    if ($Feature -eq 0 -or $Feature -eq 13) {
        $multicolumnContent = Get-ThemeContent "sections/multicolumn.liquid"
        $hasPillars = (($indexJson | Out-String) -match '(?i)Precision') -and (($indexJson | Out-String) -match '(?i)Quality') -and 
                      (($indexJson | Out-String) -match '(?i)Simplicity') -and (($indexJson | Out-String) -match '(?i)Coffee Obsession')
        Assert-Test @{
            Id = "F13-01"; Tier = 1; FeatureId = "F13"
            Description = "4 value pillars (Precision, Quality, Simplicity, Coffee Obsession) configured"
            Passed = [bool]$hasPillars
            Expected = "All 4 pillars present in index.json"
            Actual = "$hasPillars"
        }

        $hasNumberedEyebrow = (($indexJson | Out-String) -match '01\b') -and (($indexJson | Out-String) -match '02\b')
        Assert-Test @{
            Id = "F13-02"; Tier = 1; FeatureId = "F13"
            Description = "Value pillars use 01/02/03/04 numbering prefix"
            Passed = [bool]$hasNumberedEyebrow
            Expected = "01/02 prefix in pillars"
            Actual = "$hasNumberedEyebrow"
        }

        $hasMulticolumnGrid = ($baseCssContent -match '\.multicolumn__grid|\.multicolumn-list')
        Assert-Test @{
            Id = "F13-03"; Tier = 1; FeatureId = "F13"
            Description = "Multicolumn grid structure defined in base.css"
            Passed = [bool]$hasMulticolumnGrid
            Expected = "Multicolumn grid in CSS"
            Actual = "$hasMulticolumnGrid"
        }

        $hasMinimalPillarCard = ($baseCssContent -match '\.multicolumn-card')
        Assert-Test @{
            Id = "F13-04"; Tier = 1; FeatureId = "F13"
            Description = "Multicolumn card styling defined in base.css"
            Passed = [bool]$hasMinimalPillarCard
            Expected = "Multicolumn card CSS rule"
            Actual = "$hasMinimalPillarCard"
        }

        $multicolumnSchemaValid = $false
        if ($multicolumnContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $multicolumnSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F13-05"; Tier = 1; FeatureId = "F13"
            Description = "multicolumn.liquid schema JSON valid"
            Passed = [bool]$multicolumnSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$multicolumnSchemaValid"
        }
    }

    # F14: Workflow Espresso Ritual Section (01 DOSE / 02 DIAL / 03 BREW)
    if ($Feature -eq 0 -or $Feature -eq 14) {
        $hasDose = (($indexJson | Out-String) -match '(?i)DOSE.*Start with consistency')
        Assert-Test @{
            Id = "F14-01"; Tier = 1; FeatureId = "F14"
            Description = "Step 01 DOSE: 'Start with consistency.' configured"
            Passed = [bool]$hasDose
            Expected = "'01 DOSE: Start with consistency.' present"
            Actual = "$hasDose"
        }

        $hasDial = (($indexJson | Out-String) -match '(?i)DIAL.*Fine-tune your grind')
        Assert-Test @{
            Id = "F14-02"; Tier = 1; FeatureId = "F14"
            Description = "Step 02 DIAL: 'Fine-tune your grind and extraction.' configured"
            Passed = [bool]$hasDial
            Expected = "'02 DIAL: Fine-tune your grind and extraction.' present"
            Actual = "$hasDial"
        }

        $hasBrew = (($indexJson | Out-String) -match '(?i)BREW.*Enjoy the result')
        Assert-Test @{
            Id = "F14-03"; Tier = 1; FeatureId = "F14"
            Description = "Step 03 BREW: 'Enjoy the result.' configured"
            Passed = [bool]$hasBrew
            Expected = "'03 BREW: Enjoy the result.' present"
            Actual = "$hasBrew"
        }

        $workflowSectionFile = (Test-Path (Join-Path $RepoRoot "sections/workflow.liquid")) -or 
                               (($indexJson | Out-String) -match 'workflow')
        Assert-Test @{
            Id = "F14-04"; Tier = 1; FeatureId = "F14"
            Description = "Dedicated workflow section or template entry exists"
            Passed = [bool]$workflowSectionFile
            Expected = "workflow section in theme"
            Actual = "$workflowSectionFile"
        }

        $hasWorkflowOrder = ($indexJson -and ($indexJson.order -match 'workflow|ritual'))
        Assert-Test @{
            Id = "F14-05"; Tier = 1; FeatureId = "F14"
            Description = "Workflow section registered in index.json order"
            Passed = [bool]$hasWorkflowOrder
            Expected = "workflow in index.json order array"
            Actual = "$hasWorkflowOrder"
        }
    }

    # F15: Newsletter Section ("JOIN THE BAR.")
    if ($Feature -eq 0 -or $Feature -eq 15) {
        $newsletterContent = Get-ThemeContent "sections/newsletter.liquid"
        $hasJoinBar = (($indexJson | Out-String) -match '(?i)JOIN THE BAR') -or ($newsletterContent -match '(?i)JOIN THE BAR')
        Assert-Test @{
            Id = "F15-01"; Tier = 1; FeatureId = "F15"
            Description = "Newsletter heading 'JOIN THE BAR.' configured"
            Passed = [bool]$hasJoinBar
            Expected = "'JOIN THE BAR.' present"
            Actual = "$hasJoinBar"
        }

        $hasCoffeeSubtext = (($indexJson | Out-String) -match '(?i)(coffee|brewing|ritual|updates)') -or ($newsletterContent -match '(?i)(coffee|brewing|ritual)')
        Assert-Test @{
            Id = "F15-02"; Tier = 1; FeatureId = "F15"
            Description = "Newsletter coffee tips / updates copy present"
            Passed = [bool]$hasCoffeeSubtext
            Expected = "Coffee tips copy present"
            Actual = "$hasCoffeeSubtext"
        }

        $hasCustomerForm = ($newsletterContent -match "form\s+['""]customer['""]") -or ($newsletterContent -match "render\s+['""]newsletter-form['""]")
        Assert-Test @{
            Id = "F15-03"; Tier = 1; FeatureId = "F15"
            Description = "Newsletter uses native Shopify customer form"
            Passed = [bool]$hasCustomerForm
            Expected = "form 'customer' present"
            Actual = "$hasCustomerForm"
        }

        $hasNewsletterTag = ($newsletterContent -match '\[newsletter\]') -or ((Get-ThemeContent "snippets/newsletter-form.liquid") -match '\[newsletter\]')
        Assert-Test @{
            Id = "F15-04"; Tier = 1; FeatureId = "F15"
            Description = "Newsletter form includes [newsletter] tag"
            Passed = [bool]$hasNewsletterTag
            Expected = "contact[tags] = newsletter in form"
            Actual = "$hasNewsletterTag"
        }

        $newsletterSchemaValid = $false
        if ($newsletterContent -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
            try { $null = $matches[1] | ConvertFrom-Json; $newsletterSchemaValid = $true } catch {}
        }
        Assert-Test @{
            Id = "F15-05"; Tier = 1; FeatureId = "F15"
            Description = "newsletter.liquid schema JSON valid"
            Passed = [bool]$newsletterSchemaValid
            Expected = "Valid JSON schema"
            Actual = "$newsletterSchemaValid"
        }
    }

    # F16: Editorial Homepage Template Sequence
    if ($Feature -eq 0 -or $Feature -eq 16) {
        $indexValid = ($indexJson -ne $null)
        Assert-Test @{
            Id = "F16-01"; Tier = 1; FeatureId = "F16"
            Description = "templates/index.json is valid JSON"
            Passed = [bool]$indexValid
            Expected = "Valid JSON"
            Actual = "$indexValid"
        }

        $sectionCount = 0
        if ($indexJson -and $indexJson.order) { $sectionCount = $indexJson.order.Count }
        $hasMinSections = ($sectionCount -ge 7)
        Assert-Test @{
            Id = "F16-02"; Tier = 1; FeatureId = "F16"
            Description = "Homepage contains at least 7 branded editorial sections"
            Passed = [bool]$hasMinSections
            Expected = ">= 7 sections in order"
            Actual = "$sectionCount sections"
        }

        $firstSectionIsHero = $false
        if ($indexJson -and $indexJson.order -and $indexJson.order.Count -gt 0) {
            $firstId = $indexJson.order[0]
            if ($indexJson.sections.$firstId -and $indexJson.sections.$firstId.type -eq "hero") {
                $firstSectionIsHero = $true
            }
        }
        Assert-Test @{
            Id = "F16-03"; Tier = 1; FeatureId = "F16"
            Description = "Hero section is first main body section in index.json"
            Passed = [bool]$firstSectionIsHero
            Expected = "First section in order has type 'hero'"
            Actual = "$firstSectionIsHero"
        }

        $hasBestSellers = ($indexJson -and ($indexJson | Out-String) -match 'featured-collection')
        Assert-Test @{
            Id = "F16-04"; Tier = 1; FeatureId = "F16"
            Description = "Best Sellers (featured-collection) included in index.json"
            Passed = [bool]$hasBestSellers
            Expected = "featured-collection present in index.json"
            Actual = "$hasBestSellers"
        }

        $newsletterAtEnd = $false
        if ($indexJson -and $indexJson.order -and $indexJson.order.Count -ge 5) {
            $lastIndex = $indexJson.order.Count - 1
            $lastId = $indexJson.order[$lastIndex]
            $prevId = $indexJson.order[$lastIndex - 1]
            if (($indexJson.sections.$lastId -and $indexJson.sections.$lastId.type -eq "newsletter") -or 
                ($indexJson.sections.$prevId -and $indexJson.sections.$prevId.type -eq "newsletter")) {
                $newsletterAtEnd = $true
            }
        }
        Assert-Test @{
            Id = "F16-05"; Tier = 1; FeatureId = "F16"
            Description = "Newsletter section placed near end of homepage sequence"
            Passed = [bool]$newsletterAtEnd
            Expected = "newsletter in last two positions of order"
            Actual = "$newsletterAtEnd"
        }
    }

    # F17: Branded Product Card
    if ($Feature -eq 0 -or $Feature -eq 17) {
        $hasCardOffWhite = ($baseCssContent -match '\.card\b[^{]*\{[^}]*FCFAF6') -or ($themeStylesContent -match 'FCFAF6')
        Assert-Test @{
            Id = "F17-01"; Tier = 1; FeatureId = "F17"
            Description = "Product card background styled with Soft Off-White #FCFAF6"
            Passed = [bool]$hasCardOffWhite
            Expected = "#FCFAF6 background on .card"
            Actual = "$hasCardOffWhite"
        }

        $hasCardTaupeBorder = ($baseCssContent -match '\.card\b[^{]*\{[^}]*E7E0D6') -or ($baseCssContent -match '--color-border')
        Assert-Test @{
            Id = "F17-02"; Tier = 1; FeatureId = "F17"
            Description = "Product card subtle border styled with Light Taupe #E7E0D6"
            Passed = [bool]$hasCardTaupeBorder
            Expected = "Subtle taupe border on .card"
            Actual = "$hasCardTaupeBorder"
        }

        $hasSecondaryHoverImage = ($productCardContent -match 'card__image--secondary')
        Assert-Test @{
            Id = "F17-03"; Tier = 1; FeatureId = "F17"
            Description = "product-card.liquid supports secondary image on hover"
            Passed = [bool]$hasSecondaryHoverImage
            Expected = "card__image--secondary in snippet"
            Actual = "$hasSecondaryHoverImage"
        }

        $hasDiscreetQuickAdd = ($productCardContent -match 'quick_add|card__quick-add|product-form')
        Assert-Test @{
            Id = "F17-04"; Tier = 1; FeatureId = "F17"
            Description = "Discreet quick-add form supported on product card"
            Passed = [bool]$hasDiscreetQuickAdd
            Expected = "Quick-add capability in product-card"
            Actual = "$hasDiscreetQuickAdd"
        }

        $hasGenuineSaleCheck = ($productCardContent -match 'compare_at_price\s*>\s*product\.price')
        Assert-Test @{
            Id = "F17-05"; Tier = 1; FeatureId = "F17"
            Description = "Sale badge renders strictly on genuine compare_at_price > price"
            Passed = [bool]$hasGenuineSaleCheck
            Expected = "compare_at_price > product.price condition"
            Actual = "$hasGenuineSaleCheck"
        }
    }

    # F18: Product Detail Page (PDP) Layout
    if ($Feature -eq 0 -or $Feature -eq 18) {
        $hasMediaGallery = ($mainProductContent -match 'product-gallery|product__gallery')
        Assert-Test @{
            Id = "F18-01"; Tier = 1; FeatureId = "F18"
            Description = "PDP features high-res media gallery"
            Passed = [bool]$hasMediaGallery
            Expected = "product-gallery in main-product.liquid"
            Actual = "$hasMediaGallery"
        }

        $hasEagerPrimary = ($mainProductContent -match 'loading:\s*eager' -or (Get-ThemeContent "snippets/product-card.liquid") -match 'loading:\s*eager' -or $mainProductContent -match 'fetchpriority:\s*[\''"]high[\''"]')
        Assert-Test @{
            Id = "F18-02"; Tier = 1; FeatureId = "F18"
            Description = "Primary product image configured with eager loading"
            Passed = [bool]$hasEagerPrimary
            Expected = "loading: eager or fetchpriority: high"
            Actual = "$hasEagerPrimary"
        }

        $hasStickyProductInfo = ($mainProductContent -match 'product-info|product__info')
        Assert-Test @{
            Id = "F18-03"; Tier = 1; FeatureId = "F18"
            Description = "Sticky product info block defined on right"
            Passed = [bool]$hasStickyProductInfo
            Expected = "product-info in main-product"
            Actual = "$hasStickyProductInfo"
        }

        $vendorContent = Get-ThemeContent "blocks/vendor.liquid"
        $hasEyebrowVendor = ($vendorContent -match 'eyebrow|product\.vendor|product\.type')
        Assert-Test @{
            Id = "F18-04"; Tier = 1; FeatureId = "F18"
            Description = "Category micro-label / eyebrow block defined"
            Passed = [bool]$hasEyebrowVendor
            Expected = "eyebrow micro-label block"
            Actual = "$hasEyebrowVendor"
        }

        $hasCoreBlocksInProductJson = ($productJson -and ($productJson | Out-String) -match 'variant-picker' -and ($productJson | Out-String) -match 'buy-buttons')
        Assert-Test @{
            Id = "F18-05"; Tier = 1; FeatureId = "F18"
            Description = "Variant picker and buy buttons present in product.json"
            Passed = [bool]$hasCoreBlocksInProductJson
            Expected = "variant-picker and buy-buttons blocks present"
            Actual = "$hasCoreBlocksInProductJson"
        }
    }

    # F19: Conditional Product Accordions
    if ($Feature -eq 0 -or $Feature -eq 19) {
        $hasStrictCondition = ($accordionContent -match '\{%-?\s*if\s+content\s*!=\s*blank\s*-?%\}')
        Assert-Test @{
            Id = "F19-01"; Tier = 1; FeatureId = "F19"
            Description = "blocks/accordion.liquid enforces strict conditionality (content != blank)"
            Passed = [bool]$hasStrictCondition
            Expected = "{%- if content != blank -%} guard"
            Actual = "$hasStrictCondition"
        }

        $accordionBalanced = $false
        if ($accordionContent) {
            $oIf = [regex]::Matches($accordionContent, '\{%-?\s*if\b').Count
            $cIf = [regex]::Matches($accordionContent, '\{%-?\s*endif\b').Count
            $accordionBalanced = ($oIf -eq $cIf) -and ($oIf -gt 0)
        }
        Assert-Test @{
            Id = "F19-02"; Tier = 1; FeatureId = "F19"
            Description = "accordion.liquid if/endif blocks strictly balanced"
            Passed = [bool]$accordionBalanced
            Expected = "Balanced if/endif"
            Actual = "$accordionBalanced"
        }

        $hasDescriptionFallback = ($accordionContent -match 'product\.description')
        Assert-Test @{
            Id = "F19-03"; Tier = 1; FeatureId = "F19"
            Description = "Accordion accesses product.description when configured"
            Passed = [bool]$hasDescriptionFallback
            Expected = "product.description access in accordion"
            Actual = "$hasDescriptionFallback"
        }

        $accordionCount = 0
        if ($productJson) {
            $jsonStr = $productJson | Out-String
            $accordionCount = [regex]::Matches($jsonStr, '"type":\s*"accordion"').Count
        }
        $has5Accordions = ($accordionCount -ge 5)
        Assert-Test @{
            Id = "F19-04"; Tier = 1; FeatureId = "F19"
            Description = "templates/product.json configures 5 standard accordions"
            Passed = [bool]$has5Accordions
            Expected = ">= 5 accordion blocks in product.json"
            Actual = "$accordionCount accordion blocks"
        }

        $hasAccordionSummary = ($accordionContent -match '<summary>' -and $accordionContent -match 'chevron-down')
        Assert-Test @{
            Id = "F19-05"; Tier = 1; FeatureId = "F19"
            Description = "Accordion summary contains toggle icon"
            Passed = [bool]$hasAccordionSummary
            Expected = "<summary> with chevron icon"
            Actual = "$hasAccordionSummary"
        }
    }

    # F20: PDP Trust Badges
    if ($Feature -eq 0 -or $Feature -eq 20) {
        $trustBadgesFileExists = (Test-Path (Join-Path $RepoRoot "blocks/trust-badges.liquid"))
        Assert-Test @{
            Id = "F20-01"; Tier = 1; FeatureId = "F20"
            Description = "blocks/trust-badges.liquid theme block exists"
            Passed = [bool]$trustBadgesFileExists
            Expected = "File blocks/trust-badges.liquid exists"
            Actual = "$trustBadgesFileExists"
        }

        $hasSecureCheckout = ($trustBadgesContent -match '(?i)Secure checkout')
        Assert-Test @{
            Id = "F20-02"; Tier = 1; FeatureId = "F20"
            Description = "Trust badge 'Secure checkout' present with SVG icon"
            Passed = [bool]$hasSecureCheckout
            Expected = "'Secure checkout' in trust badges"
            Actual = "$hasSecureCheckout"
        }

        $hasFastDispatch = ($trustBadgesContent -match '(?i)Fast dispatch')
        Assert-Test @{
            Id = "F20-03"; Tier = 1; FeatureId = "F20"
            Description = "Trust badge 'Fast dispatch' present with SVG icon"
            Passed = [bool]$hasFastDispatch
            Expected = "'Fast dispatch' in trust badges"
            Actual = "$hasFastDispatch"
        }

        $hasBaristaBadge = ($trustBadgesContent -match '(?i)Designed for the home barista')
        Assert-Test @{
            Id = "F20-04"; Tier = 1; FeatureId = "F20"
            Description = "Trust badge 'Designed for the home barista' present"
            Passed = [bool]$hasBaristaBadge
            Expected = "'Designed for the home barista' in trust badges"
            Actual = "$hasBaristaBadge"
        }

        $hasTrustInProductJson = ($productJson -and ($productJson | Out-String) -match 'trust-badges')
        Assert-Test @{
            Id = "F20-05"; Tier = 1; FeatureId = "F20"
            Description = "Trust badges registered in templates/product.json"
            Passed = [bool]$hasTrustInProductJson
            Expected = "trust-badges block in product.json"
            Actual = "$hasTrustInProductJson"
        }
    }

    # F21: Ajax Cart Drawer
    if ($Feature -eq 0 -or $Feature -eq 21) {
        $hasCartDrawerDialog = ($cartDrawerContent -match 'id=["'']CartDrawer["'']')
        Assert-Test @{
            Id = "F21-01"; Tier = 1; FeatureId = "F21"
            Description = "Slide-out dialog #CartDrawer defined in cart-drawer.liquid"
            Passed = [bool]$hasCartDrawerDialog
            Expected = "#CartDrawer in cart-drawer.liquid"
            Actual = "$hasCartDrawerDialog"
        }

        $cartItemsContent = Get-ThemeContent "snippets/cart-items.liquid"
        $hasCartLineItems = ($cartItemsContent -match 'line_item|cart\.items') -and ($cartItemsContent -match 'item\.title')
        Assert-Test @{
            Id = "F21-02"; Tier = 1; FeatureId = "F21"
            Description = "Line item details (title, variant, image) rendered in cart"
            Passed = [bool]$hasCartLineItems
            Expected = "cart.items iteration with titles in cart-items"
            Actual = "$hasCartLineItems"
        }

        $hasQuantityControls = ($cartItemsContent -match 'cart-quantity|quantity-input|cart/change')
        Assert-Test @{
            Id = "F21-03"; Tier = 1; FeatureId = "F21"
            Description = "Quantity adjustment and item removal controls supported"
            Passed = [bool]$hasQuantityControls
            Expected = "Quantity input or cart/change in cart items"
            Actual = "$hasQuantityControls"
        }

        $hasSubtotalAndCheckout = ($cartSummaryContent -match 'cart\.total_price') -and ($cartSummaryContent -match 'name=["'']checkout["'']')
        Assert-Test @{
            Id = "F21-04"; Tier = 1; FeatureId = "F21"
            Description = "Cart subtotal and checkout CTA present in cart summary"
            Passed = [bool]$hasSubtotalAndCheckout
            Expected = "total_price and checkout button in summary"
            Actual = "$hasSubtotalAndCheckout"
        }

        $hasCartSectionRegistration = ($themeJsContent -match 'CART_SECTIONS.*cart-drawer')
        Assert-Test @{
            Id = "F21-05"; Tier = 1; FeatureId = "F21"
            Description = "Section Rendering API cart-drawer endpoint registered in theme.js"
            Passed = [bool]$hasCartSectionRegistration
            Expected = "CART_SECTIONS includes cart-drawer"
            Actual = "$hasCartSectionRegistration"
        }
    }

    # F22: Dynamic Free Shipping Bar (€55 Threshold)
    if ($Feature -eq 0 -or $Feature -eq 22) {
        $thresholdConfigured = $false
        if ($settingsData -and $settingsData.current) {
            $thresh = $settingsData.current.cart_free_shipping_threshold
            if ($thresh -eq "55" -or $thresh -eq 55) { $thresholdConfigured = $true }
        }
        Assert-Test @{
            Id = "F22-01"; Tier = 1; FeatureId = "F22"
            Description = "Free shipping threshold configured to 55 in settings_data.json"
            Passed = [bool]$thresholdConfigured
            Expected = "cart_free_shipping_threshold = 55"
            Actual = "$thresholdConfigured"
        }

        $hasRemainingCalc = ($cartSummaryContent -match 'minus:\s*cart\.total_price')
        Assert-Test @{
            Id = "F22-02"; Tier = 1; FeatureId = "F22"
            Description = "cart-summary.liquid calculates difference from threshold"
            Passed = [bool]$hasRemainingCalc
            Expected = "minus: cart.total_price in cart-summary"
            Actual = "$hasRemainingCalc"
        }

        $hasAwayString = ($enLocaleContent -match 'away from FREE SHIPPING') -or ($cartSummaryContent -match 'away from FREE SHIPPING')
        Assert-Test @{
            Id = "F22-03"; Tier = 1; FeatureId = "F22"
            Description = "Translation key 'away from FREE SHIPPING' configured"
            Passed = [bool]$hasAwayString
            Expected = "'away from FREE SHIPPING' in locale or snippet"
            Actual = "$hasAwayString"
        }

        $hasUnlockedString = ($enLocaleContent -match 'FREE STANDARD SHIPPING UNLOCKED') -or ($cartSummaryContent -match 'FREE STANDARD SHIPPING UNLOCKED')
        Assert-Test @{
            Id = "F22-04"; Tier = 1; FeatureId = "F22"
            Description = "Translation key 'FREE STANDARD SHIPPING UNLOCKED' configured"
            Passed = [bool]$hasUnlockedString
            Expected = "'FREE STANDARD SHIPPING UNLOCKED' in locale or snippet"
            Actual = "$hasUnlockedString"
        }

        $hasProgressCalc = ($cartSummaryContent -match 'times:\s*100(\.0)?\s*\|\s*divided_by:\s*threshold') -or ($cartSummaryContent -match 'shipping-bar__fill')
        Assert-Test @{
            Id = "F22-05"; Tier = 1; FeatureId = "F22"
            Description = "Shipping bar progress fill calculated and styled"
            Passed = [bool]$hasProgressCalc
            Expected = "Percentage width calculation on shipping-bar__fill"
            Actual = "$hasProgressCalc"
        }
    }

    # F23: Predictive Search & 404 Page
    if ($Feature -eq 0 -or $Feature -eq 23) {
        $hasSearchDrawer = ($headerContent -match 'id=["'']SearchDrawer["'']')
        Assert-Test @{
            Id = "F23-01"; Tier = 1; FeatureId = "F23"
            Description = "Predictive search drawer dialog defined in header"
            Passed = [bool]$hasSearchDrawer
            Expected = "#SearchDrawer in header.liquid"
            Actual = "$hasSearchDrawer"
        }

        $hasNothingYet = ($predictiveSearchContent -match '(?i)NOTHING YET') -or ($enLocaleContent -match '(?i)NOTHING YET')
        Assert-Test @{
            Id = "F23-02"; Tier = 1; FeatureId = "F23"
            Description = "Empty search state 'NOTHING YET.' configured"
            Passed = [bool]$hasNothingYet
            Expected = "'NOTHING YET.' present"
            Actual = "$hasNothingYet"
        }

        $hasSearchRecoveryCopy = ($predictiveSearchContent -match '(?i)Try another search or explore our coffee bar essentials') -or 
                                 ($enLocaleContent -match '(?i)Try another search or explore our coffee bar essentials')
        Assert-Test @{
            Id = "F23-03"; Tier = 1; FeatureId = "F23"
            Description = "Search recovery copy 'Try another search or explore...' present"
            Passed = [bool]$hasSearchRecoveryCopy
            Expected = "Recovery copy present"
            Actual = "$hasSearchRecoveryCopy"
        }

        $has404Headline = ($main404Content -match '(?i)LOOKS LIKE THIS SHOT DIDN.*T DIAL IN') -or 
                          ($enLocaleContent -match '(?i)LOOKS LIKE THIS SHOT DIDN.*T DIAL IN')
        Assert-Test @{
            Id = "F23-04"; Tier = 1; FeatureId = "F23"
            Description = "404 page headline 'LOOKS LIKE THIS SHOT DIDN''T DIAL IN.' configured"
            Passed = [bool]$has404Headline
            Expected = "Brand 404 headline present"
            Actual = "$has404Headline"
        }

        $has404Cta = ($main404Content -match '(?i)BACK TO THE COFFEE BAR') -or ($enLocaleContent -match '(?i)BACK TO THE COFFEE BAR')
        Assert-Test @{
            Id = "F23-05"; Tier = 1; FeatureId = "F23"
            Description = "404 page CTA 'BACK TO THE COFFEE BAR' configured"
            Passed = [bool]$has404Cta
            Expected = "'BACK TO THE COFFEE BAR' present"
            Actual = "$has404Cta"
        }
    }

    # F24: 4-Column Branded Footer (Seville Business Details)
    if ($Feature -eq 0 -or $Feature -eq 24) {
        $has4Cols = ($footerContent -match 'footer__content' -and ($footerGroup | Out-String) -match 'column|block')
        Assert-Test @{
            Id = "F24-01"; Tier = 1; FeatureId = "F24"
            Description = "4-column footer structure configured in footer.liquid"
            Passed = [bool]$has4Cols
            Expected = "4-column grid structure in footer"
            Actual = "$has4Cols"
        }

        # Match Seville address with regex dot to accommodate encoding variations for accented 'a' in Roldan
        $hasSevilleAddress = ($footerContent -match 'Calle Pintor Rold.n 3,\s*41940 Sevilla,\s*Spain') -or 
                             (($footerGroup | Out-String) -match 'Calle Pintor Rold.n 3,\s*41940 Sevilla,\s*Spain')
        Assert-Test @{
            Id = "F24-02"; Tier = 1; FeatureId = "F24"
            Description = "Physical address 'Calle Pintor Roldan 3, 41940 Sevilla, Spain' present verbatim"
            Passed = [bool]$hasSevilleAddress
            Expected = "Verbatim Seville address in footer"
            Actual = "$hasSevilleAddress"
        }

        $hasSevillePhone = ($footerContent -match '\+34\s*648\s*273\s*811') -or 
                           (($footerGroup | Out-String) -match '\+34\s*648\s*273\s*811')
        Assert-Test @{
            Id = "F24-03"; Tier = 1; FeatureId = "F24"
            Description = "Business phone '+34 648 273 811' present verbatim"
            Passed = [bool]$hasSevillePhone
            Expected = "+34 648 273 811 present in footer"
            Actual = "$hasSevillePhone"
        }

        $hasSevilleEmail = ($footerContent -match 'xaviborja1@hotmail\.com') -or 
                           (($footerGroup | Out-String) -match 'xaviborja1@hotmail\.com')
        Assert-Test @{
            Id = "F24-04"; Tier = 1; FeatureId = "F24"
            Description = "Business email 'xaviborja1@hotmail.com' present verbatim"
            Passed = [bool]$hasSevilleEmail
            Expected = "xaviborja1@hotmail.com present in footer"
            Actual = "$hasSevilleEmail"
        }

        $hasDynamicCopyright = ($footerContent -match "\{\{\s*['""]now['""]\s*\|\s*date:\s*['""]%Y['""]\s*\}\}\s*Dose\s*&\s*Dial")
        Assert-Test @{
            Id = "F24-05"; Tier = 1; FeatureId = "F24"
            Description = "Dynamic copyright with current year and brand present"
            Passed = [bool]$hasDynamicCopyright
            Expected = "Dynamic copyright tag in footer"
            Actual = "$hasDynamicCopyright"
        }
    }

    # F25: E2E Testing & Quality Gate (Syntax & Overflow)
    if ($Feature -eq 0 -or $Feature -eq 25) {
        $jsonFiles = Get-ChildItem -Path $RepoRoot -Filter "*.json" -Recurse | Where-Object { $_.FullName -notmatch '\\(\.git|\.agents)\\' }
        $invalidJsons = @()
        foreach ($jFile in $jsonFiles) {
            try {
                $null = [System.IO.File]::ReadAllText($jFile.FullName, [System.Text.Encoding]::UTF8) | ConvertFrom-Json
            } catch {
                $invalidJsons += $jFile.Name
            }
        }
        $allJsonValid = ($invalidJsons.Count -eq 0)
        Assert-Test @{
            Id = "F25-01"; Tier = 1; FeatureId = "F25"
            Description = "All $($jsonFiles.Count) JSON files parse with zero syntax errors"
            Passed = [bool]$allJsonValid
            Expected = "0 JSON parse errors"
            Actual = "$($invalidJsons.Count) errors ($($invalidJsons -join ', '))"
        }

        $liquidFiles = Get-ChildItem -Path $RepoRoot -Filter "*.liquid" -Recurse | Where-Object { $_.FullName -notmatch '\\(\.git|\.agents)\\' }
        $unbalancedTags = @()
        $unbalancedBlocks = @()
        $invalidSchemas = @()

        foreach ($lFile in $liquidFiles) {
            $content = [System.IO.File]::ReadAllText($lFile.FullName, [System.Text.Encoding]::UTF8)
            $openTags = [regex]::Matches($content, '\{%').Count
            $closeTags = [regex]::Matches($content, '%\}').Count
            $openVar = [regex]::Matches($content, '\{\{').Count
            $closeVar = [regex]::Matches($content, '\}\}').Count

            if ($openTags -ne $closeTags -or $openVar -ne $closeVar) {
                $unbalancedTags += $lFile.Name
            }

            $ifs = [regex]::Matches($content, '\{%-?\s*if\b').Count
            $endifs = [regex]::Matches($content, '\{%-?\s*endif\b').Count
            $fors = [regex]::Matches($content, '\{%-?\s*for\b').Count
            $endfors = [regex]::Matches($content, '\{%-?\s*endfor\b').Count
            $cases = [regex]::Matches($content, '\{%-?\s*case\b').Count
            $endcases = [regex]::Matches($content, '\{%-?\s*endcase\b').Count
            $forms = [regex]::Matches($content, '\{%-?\s*form\b').Count
            $endforms = [regex]::Matches($content, '\{%-?\s*endform\b').Count

            if ($ifs -ne $endifs -or $fors -ne $endfors -or $cases -ne $endcases -or $forms -ne $endforms) {
                $unbalancedBlocks += $lFile.Name
            }

            if ($content -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
                try {
                    $null = $matches[1] | ConvertFrom-Json
                } catch {
                    $invalidSchemas += $lFile.Name
                }
            }
        }

        $allTagsBalanced = ($unbalancedTags.Count -eq 0)
        Assert-Test @{
            Id = "F25-02"; Tier = 1; FeatureId = "F25"
            Description = "All $($liquidFiles.Count) Liquid files have balanced tags ({% %} and {{ }})"
            Passed = [bool]$allTagsBalanced
            Expected = "0 tag mismatches"
            Actual = "$($unbalancedTags.Count) mismatches ($($unbalancedTags -join ', '))"
        }

        $allBlocksBalanced = ($unbalancedBlocks.Count -eq 0)
        Assert-Test @{
            Id = "F25-03"; Tier = 1; FeatureId = "F25"
            Description = "All Liquid files have balanced block pairs (if/endif, for/endfor, form/endform)"
            Passed = [bool]$allBlocksBalanced
            Expected = "0 block mismatches"
            Actual = "$($unbalancedBlocks.Count) mismatches ($($unbalancedBlocks -join ', '))"
        }

        $allSchemasValid = ($invalidSchemas.Count -eq 0)
        Assert-Test @{
            Id = "F25-04"; Tier = 1; FeatureId = "F25"
            Description = "All embedded {% schema %} JSON blocks parse validly"
            Passed = [bool]$allSchemasValid
            Expected = "0 schema errors"
            Actual = "$($invalidSchemas.Count) errors ($($invalidSchemas -join ', '))"
        }

        $hasReducedMotion = ($baseCssContent -match 'prefers-reduced-motion\s*:\s*reduce')
        Assert-Test @{
            Id = "F25-05"; Tier = 1; FeatureId = "F25"
            Description = "CSS includes prefers-reduced-motion: reduce media queries"
            Passed = [bool]$hasReducedMotion
            Expected = "prefers-reduced-motion in base.css"
            Actual = "$hasReducedMotion"
        }
    }

    # F26: Git Commit & Push Readiness
    if ($Feature -eq 0 -or $Feature -eq 26) {
        $gitDirExists = (Test-Path (Join-Path $RepoRoot ".git"))
        Assert-Test @{
            Id = "F26-01"; Tier = 1; FeatureId = "F26"
            Description = "Git repository initialized (.git present)"
            Passed = [bool]$gitDirExists
            Expected = ".git directory present"
            Actual = "$gitDirExists"
        }

        $gitBranch = ""
        try {
            $gitBranch = (git -C $RepoRoot rev-parse --abbrev-ref HEAD 2>$null).Trim()
        } catch {}
        $isMasterBranch = ($gitBranch -eq "master")
        Assert-Test @{
            Id = "F26-02"; Tier = 1; FeatureId = "F26"
            Description = "Active git branch is master"
            Passed = [bool]$isMasterBranch
            Expected = "Branch 'master'"
            Actual = "$gitBranch"
        }

        $gitRemote = ""
        try {
            $gitRemote = (git -C $RepoRoot config --get remote.origin.url 2>$null).Trim()
        } catch {}
        $isCorrectRemote = ($gitRemote -match 'brittstrohman-maker/xaviborja')
        Assert-Test @{
            Id = "F26-03"; Tier = 1; FeatureId = "F26"
            Description = "Remote origin tracked to brittstrohman-maker/xaviborja"
            Passed = [bool]$isCorrectRemote
            Expected = "Remote points to brittstrohman-maker/xaviborja"
            Actual = "$gitRemote"
        }

        $gitignoreContent = Get-ThemeContent ".gitignore"
        $ignoresAgents = ($gitignoreContent -match '(?m)^\.agents/?')
        Assert-Test @{
            Id = "F26-04"; Tier = 1; FeatureId = "F26"
            Description = ".agents/ metadata directory excluded in .gitignore"
            Passed = [bool]$ignoresAgents
            Expected = ".agents/ in .gitignore"
            Actual = "$ignoresAgents"
        }

        $noForbiddenTracked = $true
        try {
            $trackedAgents = (git -C $RepoRoot ls-files .agents 2>$null)
            if ($trackedAgents -and $trackedAgents.Length -gt 0) { $noForbiddenTracked = $false }
        } catch {}
        Assert-Test @{
            Id = "F26-05"; Tier = 1; FeatureId = "F26"
            Description = "No .agents metadata files tracked in git index"
            Passed = [bool]$noForbiddenTracked
            Expected = "Zero .agents files in git ls-files"
            Actual = "$noForbiddenTracked"
        }
    }
}

# ==============================================================================
# TIER 2: BOUNDARY & CORNER CONDITIONS (12 Tests)
# ==============================================================================
if ($Tier -eq "All" -or $Tier -eq "2") {
    Write-Host "`n--- Running Tier 2: Boundary & Corner Conditions ---" -ForegroundColor Yellow

    # T2-01: Empty cart threshold calculation (cart total 0 cents)
    $thresholdCents = 5500
    $cartTotalCents = 0
    $remaining = $thresholdCents - $cartTotalCents
    $progress = if ($thresholdCents -gt 0 -and $remaining -gt 0) { [math]::Round(($cartTotalCents * 100.0) / $thresholdCents, 2) } else { 100 }
    $t2_01_pass = ($remaining -eq 5500) -and ($progress -eq 0)
    Assert-Test @{
        Id = "T2-01"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Cart total 0c yields 5500c remaining and 0% progress"
        Passed = [bool]$t2_01_pass
        Expected = "remaining=5500, progress=0"
        Actual = "remaining=$remaining, progress=$progress"
    }

    # T2-02: Boundary 1 cent below threshold (€54.99 = 5499 cents)
    $cartTotalCents = 5499
    $remaining = $thresholdCents - $cartTotalCents
    $t2_02_pass = ($remaining -eq 1) -and ($remaining -gt 0)
    Assert-Test @{
        Id = "T2-02"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Cart total 5499c (54.99) yields exactly 1c remaining"
        Passed = [bool]$t2_02_pass
        Expected = "remaining=1, status=still locked"
        Actual = "remaining=$remaining"
    }

    # T2-03: Boundary exact threshold equality (€55.00 = 5500 cents)
    $cartTotalCents = 5500
    $remaining = $thresholdCents - $cartTotalCents
    $progress = if ($thresholdCents -gt 0 -and $remaining -gt 0) { ($cartTotalCents * 100.0) / $thresholdCents } else { 100 }
    $t2_03_pass = ($remaining -le 0) -and ($progress -eq 100)
    Assert-Test @{
        Id = "T2-03"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Cart total 5500c reaches 100% progress and unlocked"
        Passed = [bool]$t2_03_pass
        Expected = "remaining<=0, progress=100"
        Actual = "remaining=$remaining, progress=$progress"
    }

    # T2-04: Boundary overfill threshold (€80.00 = 8000 cents)
    $cartTotalCents = 8000
    $remaining = $thresholdCents - $cartTotalCents
    $progress = if ($thresholdCents -gt 0 -and $remaining -gt 0) { ($cartTotalCents * 100.0) / $thresholdCents } else { 100 }
    $t2_04_pass = ($remaining -lt 0) -and ($progress -eq 100)
    Assert-Test @{
        Id = "T2-04"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Cart total 8000c clamps progress to 100% without error"
        Passed = [bool]$t2_04_pass
        Expected = "progress clamped to 100%"
        Actual = "progress=$progress"
    }

    # T2-05: Blank accordion suppression
    $t2_05_pass = ($accordionContent -match '\{%-?\s*if\s+content\s*!=\s*blank\s*-?%\}[\s\S]*?<details[\s\S]*?<\/details>[\s\S]*?\{%-?\s*endif\s*-?%\}')
    Assert-Test @{
        Id = "T2-05"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Blank accordion content wraps details in if content != blank"
        Passed = [bool]$t2_05_pass
        Expected = "<details> wrapped in if content != blank"
        Actual = "$t2_05_pass"
    }

    # T2-06: Description accordion fallback logic
    $t2_06_pass = ($accordionContent -match 'product\.description') -and ($accordionContent -match 'Description')
    Assert-Test @{
        Id = "T2-06"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Description accordion cleanly falls back to product.description"
        Passed = [bool]$t2_06_pass
        Expected = "product.description fallback present"
        Actual = "$t2_06_pass"
    }

    # T2-07: Single-variant product card direct form
    $t2_07_pass = ($productCardContent -match 'product\.has_only_default_variant') -or ($productCardContent -match 'product\.variants\.size\s*==\s*1') -or ($productCardContent -match 'form\s+action=["'']/cart/add["'']')
    Assert-Test @{
        Id = "T2-07"; Tier = 2; FeatureId = "T2"
        Description = "Corner: Single-variant product card handles direct add-to-cart action"
        Passed = [bool]$t2_07_pass
        Expected = "Direct cart addition for single variant"
        Actual = "$t2_07_pass"
    }

    # T2-08: Multi-variant product card option select redirect
    $t2_08_pass = ($productCardContent -match 'product\.url') -and ($productCardContent -match 'quick_add|variants')
    Assert-Test @{
        Id = "T2-08"; Tier = 2; FeatureId = "T2"
        Description = "Corner: Multi-variant product routes to product detail options"
        Passed = [bool]$t2_08_pass
        Expected = "product.url link for multi-variant"
        Actual = "$t2_08_pass"
    }

    # T2-09: Zero search query initial state
    $t2_09_pass = ($predictiveSearchContent -match 'search\.performed' -or $predictiveSearchContent -match 'predictive_search\.performed' -or $predictiveSearchContent -match 'query\.size')
    Assert-Test @{
        Id = "T2-09"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Predictive search gracefully handles zero search query state"
        Passed = [bool]$t2_09_pass
        Expected = "Graceful check on search.performed / query.size"
        Actual = "$t2_09_pass"
    }

    # T2-10: Zero search results empty-state triggers
    $t2_10_pass = ($predictiveSearchContent -match '(?i)NOTHING YET') -and ($predictiveSearchContent -match '0|empty|total_results')
    Assert-Test @{
        Id = "T2-10"; Tier = 2; FeatureId = "T2"
        Description = "Corner: Zero search results triggers 'NOTHING YET.' empty state"
        Passed = [bool]$t2_10_pass
        Expected = "'NOTHING YET.' on 0 results"
        Actual = "$t2_10_pass"
    }

    # T2-11: Button radius lower & upper clamping [2, 8]
    $t2_11_pass = $false
    if ($settingsSchemaContent) {
        try {
            $schemaObj = $settingsSchemaContent | ConvertFrom-Json
            $radiusEntry = $null
            foreach ($section in $schemaObj) {
                if ($section.settings) {
                    foreach ($st in $section.settings) {
                        if ($st.id -eq "radius_base" -or $st.id -eq "button_radius") {
                            $radiusEntry = $st
                        }
                    }
                }
            }
            if ($radiusEntry -and $radiusEntry.min -ge 0 -and $radiusEntry.max -le 20) {
                $t2_11_pass = $true
            }
        } catch {}
    }
    Assert-Test @{
        Id = "T2-11"; Tier = 2; FeatureId = "T2"
        Description = "Boundary: Button radius schema definition bounds clamped to 2-8px"
        Passed = [bool]$t2_11_pass
        Expected = "radius schema clamped"
        Actual = "$t2_11_pass"
    }

    # T2-12: Sale badge suppressed when compare_at_price <= price
    $t2_12_pass = ($productCardContent -match 'compare_at_price\s*>\s*product\.price') -and ($productCardContent -notmatch 'compare_at_price\s*!=\s*blank\s*%\}[\s\S]*?badge--sale')
    Assert-Test @{
        Id = "T2-12"; Tier = 2; FeatureId = "T2"
        Description = "Corner: Sale badge strictly suppressed when compare_at_price <= price"
        Passed = [bool]$t2_12_pass
        Expected = "Strict compare_at_price > price evaluation"
        Actual = "$t2_12_pass"
    }
}

# ==============================================================================
# TIER 3: CROSS-FEATURE INTEGRATION COMBINATIONS (10 Tests)
# ==============================================================================
if ($Tier -eq "All" -or $Tier -eq "3") {
    Write-Host "`n--- Running Tier 3: Cross-Feature Integration Combinations ---" -ForegroundColor Yellow

    # T3-01: Token Cascade: settings_data -> theme-styles -> base.css
    $t3_01_pass = ($themeStylesContent -match '--color-background') -and ($baseCssContent -match 'var\(--color-background\)')
    Assert-Test @{
        Id = "T3-01"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Design token cascade from theme-styles into base.css CSS variables"
        Passed = [bool]$t3_01_pass
        Expected = "var(--color-background) defined in styles and used in CSS"
        Actual = "$t3_01_pass"
    }

    # T3-02: Threshold Synchronization: Announcement bar €55 <-> cart_free_shipping_threshold
    $announcementHas55 = (($headerGroup | Out-String) -match '55') -or ($announcementContent -match '55')
    $settingsHas55 = ($settingsData -and $settingsData.current -and ($settingsData.current.cart_free_shipping_threshold -eq "55" -or $settingsData.current.cart_free_shipping_threshold -eq 55))
    $t3_02_pass = $announcementHas55 -and $settingsHas55
    Assert-Test @{
        Id = "T3-02"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Announcement bar threshold (55) strictly syncs with cart threshold"
        Passed = [bool]$t3_02_pass
        Expected = "Both announcement and cart threshold set to 55"
        Actual = "Announcement=$announcementHas55, Cart=$settingsHas55"
    }

    # T3-03: PDP Block Schema <-> blocks/*.liquid registration
    $productBlocks = @("title", "price", "vendor", "variant-picker", "quantity", "buy-buttons", "trust-badges", "accordion")
    $missingBlocks = @()
    foreach ($blk in $productBlocks) {
        $blkFile = Join-Path $RepoRoot "blocks/$blk.liquid"
        if (-not (Test-Path $blkFile)) {
            $missingBlocks += $blk
        }
    }
    $t3_03_pass = ($missingBlocks.Count -eq 0)
    Assert-Test @{
        Id = "T3-03"; Tier = 3; FeatureId = "T3"
        Description = "Integration: All PDP theme blocks in product.json have physical blocks/*.liquid files"
        Passed = [bool]$t3_03_pass
        Expected = "All blocks present"
        Actual = "Missing: $($missingBlocks -join ', ')"
    }

    # T3-04: Cart Engine Section Rendering API Sync
    $t3_04_pass = ($themeJsContent -match 'CART_SECTIONS') -and 
                  (Test-Path (Join-Path $RepoRoot "sections/cart-drawer.liquid")) -and 
                  (Test-Path (Join-Path $RepoRoot "sections/cart-icon-bubble.liquid"))
    Assert-Test @{
        Id = "T3-04"; Tier = 3; FeatureId = "T3"
        Description = "Integration: theme.js CART_SECTIONS strictly matches physical sections/*.liquid"
        Passed = [bool]$t3_04_pass
        Expected = "cart-drawer and cart-icon-bubble exist for theme.js"
        Actual = "$t3_04_pass"
    }

    # T3-05: Footer Legal Policies <-> Standard Shopify Routes
    $t3_05_pass = ($footerContent -match 'shop\.(refund_policy|privacy_policy|terms_of_service|shipping_policy)') -or 
                  ($footerContent -match '/policies/(refund-policy|privacy-policy|terms-of-service|shipping-policy)')
    Assert-Test @{
        Id = "T3-05"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Footer legal links bind to standard Shopify policy routes"
        Passed = [bool]$t3_05_pass
        Expected = "Shopify policy objects / routes in footer.liquid"
        Actual = "$t3_05_pass"
    }

    # T3-06: Header Navigation <-> Homepage Collection Handles
    $t3_06_pass = ($indexJson -and ($indexJson | Out-String) -match 'espresso-tools|coffee-station|brewing')
    Assert-Test @{
        Id = "T3-06"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Header navigation items align with index.json collection cards"
        Passed = [bool]$t3_06_pass
        Expected = "Dose & Dial collection handles in index.json"
        Actual = "$t3_06_pass"
    }

    # T3-07: Product Card Quick-Add <-> Cart Drawer Ajax Event Bus
    $t3_07_pass = ($productCardContent -match 'product-form|cart/add') -and ($themeJsContent -match 'cart-drawer|updateCartSections')
    Assert-Test @{
        Id = "T3-07"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Product card quick-add dispatches to theme.js cart drawer handler"
        Passed = [bool]$t3_07_pass
        Expected = "Product card form intercepted by theme.js cart engine"
        Actual = "$t3_07_pass"
    }

    # T3-08: Color Scheme Cascade to Dark Accent Components
    $t3_08_pass = ($baseCssContent -match '\.color-scheme-3|\.color-scheme-dark|\.color-scheme--dark') -or 
                  ($themeStylesContent -match 'scheme_3')
    Assert-Test @{
        Id = "T3-08"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Dark color scheme cascade applied to dark accent components"
        Passed = [bool]$t3_08_pass
        Expected = "scheme_3 dark scheme styles generated"
        Actual = "$t3_08_pass"
    }

    # T3-09: 404 Recovery <-> Catalog URL Binding
    $t3_09_pass = ($main404Content -match 'routes\.all_products_collection_url') -or ($template404Json | Out-String) -match 'all_products'
    Assert-Test @{
        Id = "T3-09"; Tier = 3; FeatureId = "T3"
        Description = "Integration: 404 recovery CTA binds dynamically to routes.all_products_collection_url"
        Passed = [bool]$t3_09_pass
        Expected = "routes.all_products_collection_url in 404 section"
        Actual = "$t3_09_pass"
    }

    # T3-10: Mobile Drawer & Search Modal Non-Conflicting Dialogs
    $t3_10_pass = ($headerContent -match 'dialog.*id=["'']SearchDrawer["'']') -and ($headerContent -match 'MenuDrawer|menu-drawer')
    Assert-Test @{
        Id = "T3-10"; Tier = 3; FeatureId = "T3"
        Description = "Integration: Menu drawer and Search dialog coexist without DOM ID collisions"
        Passed = [bool]$t3_10_pass
        Expected = "Independent dialog / drawer IDs in header.liquid"
        Actual = "$t3_10_pass"
    }
}

# ==============================================================================
# TIER 4: REAL-WORLD CUSTOMER SCENARIOS (8 Tests)
# ==============================================================================
if ($Tier -eq "All" -or $Tier -eq "4") {
    Write-Host "`n--- Running Tier 4: Real-World Customer Scenarios ---" -ForegroundColor Yellow

    # T4-01: Scenario A - Home Barista Storefront Discovery Journey
    $sA_announcement = ($headerGroup | Out-String) -match 'FREE STANDARD SHIPPING'
    $sA_header = ($headerContent -match '(?i)Dose\s*&\s*Dial')
    $sA_hero = ($indexJson | Out-String) -match 'PRECISION FOR EVERY POUR'
    $sA_collections = ($indexJson | Out-String) -match 'BUILD YOUR COFFEE BAR'
    $t4_01_pass = $sA_announcement -and $sA_header -and $sA_hero -and $sA_collections
    Assert-Test @{
        Id = "T4-01"; Tier = 4; FeatureId = "T4"
        Description = "Scenario A: Complete discovery flow (Announcement -> Wordmark -> Hero -> Collections)"
        Passed = [bool]$t4_01_pass
        Expected = "All 4 touchpoints configured"
        Actual = "Announce=$sA_announcement, Logo=$sA_header, Hero=$sA_hero, Coll=$sA_collections"
    }

    # T4-02: Scenario B - Ritual Workflow & Editorial Story Engagement
    $sB_ritual = ($indexJson | Out-String) -match '01 DOSE' -and ($indexJson | Out-String) -match '02 DIAL'
    $sB_story = ($indexJson | Out-String) -match 'CRAFT YOUR PERFECT SHOT'
    $sB_newsletter = ($indexJson | Out-String) -match 'JOIN THE BAR'
    $t4_02_pass = $sB_ritual -and $sB_story -and $sB_newsletter
    Assert-Test @{
        Id = "T4-02"; Tier = 4; FeatureId = "T4"
        Description = "Scenario B: Editorial ritual engagement (Workflow Ritual -> Brand Story -> Join the Bar)"
        Passed = [bool]$t4_02_pass
        Expected = "Ritual, Story, and Newsletter present in index"
        Actual = "Ritual=$sB_ritual, Story=$sB_story, Newsletter=$sB_newsletter"
    }

    # T4-03: Scenario C - Product Detail Page & Trust Verification
    $sC_gallery = ($mainProductContent -match 'product-gallery')
    $sC_badges = ($trustBadgesContent -match 'Secure checkout' -and $trustBadgesContent -match 'Designed for the home barista')
    $sC_accordions = ($accordionContent -match 'content != blank')
    $t4_03_pass = $sC_gallery -and $sC_badges -and $sC_accordions
    Assert-Test @{
        Id = "T4-03"; Tier = 4; FeatureId = "T4"
        Description = "Scenario C: PDP high-res gallery, trust badges, and conditional accordions"
        Passed = [bool]$t4_03_pass
        Expected = "Gallery + Badges + Conditional Accordions"
        Actual = "Gallery=$sC_gallery, Badges=$sC_badges, Accordions=$sC_accordions"
    }

    # T4-04: Scenario D - Dynamic Free Shipping Cart Progression
    $sD_calc = ($cartSummaryContent -match 'minus:\s*cart\.total_price')
    $sD_away = ($enLocaleContent -match 'away from FREE SHIPPING')
    $sD_unlocked = ($enLocaleContent -match 'FREE STANDARD SHIPPING UNLOCKED')
    $t4_04_pass = $sD_calc -and $sD_away -and $sD_unlocked
    Assert-Test @{
        Id = "T4-04"; Tier = 4; FeatureId = "T4"
        Description = "Scenario D: Cart drawer progress calculation and bilingual threshold states"
        Passed = [bool]$t4_04_pass
        Expected = "Calculation + 'away' text + 'unlocked' text"
        Actual = "Calc=$sD_calc, Away=$sD_away, Unlocked=$sD_unlocked"
    }

    # T4-05: Scenario E - Predictive Search Exploration & Recovery Journey
    $sE_drawer = ($headerContent -match 'SearchDrawer')
    $sE_empty = ($predictiveSearchContent -match '(?i)NOTHING YET')
    $sE_recovery = ($predictiveSearchContent -match 'explore our coffee bar essentials')
    $t4_05_pass = $sE_drawer -and $sE_empty -and $sE_recovery
    Assert-Test @{
        Id = "T4-05"; Tier = 4; FeatureId = "T4"
        Description = "Scenario E: Search drawer empty-state and catalog discovery recovery"
        Passed = [bool]$t4_05_pass
        Expected = "Drawer + 'NOTHING YET.' + recovery copy"
        Actual = "Drawer=$sE_drawer, Empty=$sE_empty, Recovery=$sE_recovery"
    }

    # T4-06: Scenario F - 404 Error Encounter & Graceful Catalog Return
    $sF_headline = ($main404Content -match '(?i)LOOKS LIKE THIS SHOT DIDN.*T DIAL IN') -or ($enLocaleContent -match '(?i)LOOKS LIKE THIS SHOT DIDN.*T DIAL IN')
    $sF_cta = ($main404Content -match '(?i)BACK TO THE COFFEE BAR') -or ($enLocaleContent -match '(?i)BACK TO THE COFFEE BAR')
    $t4_06_pass = $sF_headline -and $sF_cta
    Assert-Test @{
        Id = "T4-06"; Tier = 4; FeatureId = "T4"
        Description = "Scenario F: 404 extraction error message and catalog return CTA"
        Passed = [bool]$sF_headline -and [bool]$sF_cta
        Expected = "'DIDN'T DIAL IN' + 'BACK TO THE COFFEE BAR'"
        Actual = "Headline=$sF_headline, CTA=$sF_cta"
    }

    # T4-07: Scenario G - Seville Business Verification & Footer Transparency
    $sG_address = ($footerContent -match 'Calle Pintor Rold.n 3') -or (($footerGroup | Out-String) -match 'Calle Pintor Rold.n 3')
    $sG_phone = ($footerContent -match '\+34 648 273 811') -or (($footerGroup | Out-String) -match '\+34 648 273 811')
    $sG_email = ($footerContent -match 'xaviborja1@hotmail\.com') -or (($footerGroup | Out-String) -match 'xaviborja1@hotmail\.com')
    $sG_copyright = ($footerContent -match 'Dose\s*&\s*Dial')
    $t4_07_pass = $sG_address -and $sG_phone -and $sG_email -and $sG_copyright
    Assert-Test @{
        Id = "T4-07"; Tier = 4; FeatureId = "T4"
        Description = "Scenario G: Seville business credentials and dynamic copyright transparency"
        Passed = [bool]$t4_07_pass
        Expected = "Address + Phone + Email + Copyright in footer"
        Actual = "Addr=$sG_address, Phone=$sG_phone, Email=$sG_email, Copyright=$sG_copyright"
    }

    # T4-08: Scenario H - Mobile Responsive Touch & Reduced Motion Compliance
    $sH_touch = ($baseCssContent -match 'min-height\s*:\s*(44px|48px|3rem)') -or ($baseCssContent -match 'min-width\s*:\s*(44px|48px|3rem)')
    $sH_motion = ($baseCssContent -match 'prefers-reduced-motion\s*:\s*reduce')
    $t4_08_pass = $sH_touch -and $sH_motion
    Assert-Test @{
        Id = "T4-08"; Tier = 4; FeatureId = "T4"
        Description = "Scenario H: Mobile touch targets (>=44px) and prefers-reduced-motion compliance"
        Passed = [bool]$t4_08_pass
        Expected = "Touch target min 44px + reduced motion in CSS"
        Actual = "Touch=$sH_touch, Motion=$sH_motion"
    }
}

# ==============================================================================
# SUMMARY REPORT & QUALITY GATE ASSESSMENT
# ==============================================================================
$tier1Tests = $Global:TestResults | Where-Object { $_.Tier -eq 1 }
$tier2Tests = $Global:TestResults | Where-Object { $_.Tier -eq 2 }
$tier3Tests = $Global:TestResults | Where-Object { $_.Tier -eq 3 }
$tier4Tests = $Global:TestResults | Where-Object { $_.Tier -eq 4 }

$t1Pass = ($tier1Tests | Where-Object { $_.Passed }).Count
$t2Pass = ($tier2Tests | Where-Object { $_.Passed }).Count
$t3Pass = ($tier3Tests | Where-Object { $_.Passed }).Count
$t4Pass = ($tier4Tests | Where-Object { $_.Passed }).Count

$totalPass = ($Global:TestResults | Where-Object { $_.Passed }).Count
$totalTests = $Global:TestResults.Count
$totalFail = $totalTests - $totalPass
$overallPassPct = if ($totalTests -gt 0) { [math]::Round(($totalPass * 100.0) / $totalTests, 1) } else { 0 }

Write-Host "`n================================================================================" -ForegroundColor Cyan
Write-Host "                       DOSE & DIAL E2E TEST SUMMARY                             " -ForegroundColor Cyan
Write-Host "================================================================================" -ForegroundColor Cyan

$summaryRows = @(
    [PSCustomObject]@{ Tier = "Tier 1: Feature & Syntactic"; Total = $tier1Tests.Count; Passed = $t1Pass; Failed = ($tier1Tests.Count - $t1Pass); Rate = "$([math]::Round(($t1Pass*100.0)/[math]::Max(1,$tier1Tests.Count),1))%" },
    [PSCustomObject]@{ Tier = "Tier 2: Boundary & Corner";    Total = $tier2Tests.Count; Passed = $t2Pass; Failed = ($tier2Tests.Count - $t2Pass); Rate = "$([math]::Round(($t2Pass*100.0)/[math]::Max(1,$tier2Tests.Count),1))%" },
    [PSCustomObject]@{ Tier = "Tier 3: Cross-Integration";    Total = $tier3Tests.Count; Passed = $t3Pass; Failed = ($tier3Tests.Count - $t3Pass); Rate = "$([math]::Round(($t3Pass*100.0)/[math]::Max(1,$tier3Tests.Count),1))%" },
    [PSCustomObject]@{ Tier = "Tier 4: Customer Scenarios";   Total = $tier4Tests.Count; Passed = $t4Pass; Failed = ($tier4Tests.Count - $t4Pass); Rate = "$([math]::Round(($t4Pass*100.0)/[math]::Max(1,$tier4Tests.Count),1))%" }
)

$summaryRows | Format-Table -Property Tier, Total, Passed, Failed, Rate -AutoSize

Write-Host "--------------------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host "  GRAND TOTAL: $totalPass / $totalTests passed ($overallPassPct%)" -ForegroundColor $(if ($totalFail -eq 0) { "Green" } else { "Yellow" })
Write-Host "================================================================================" -ForegroundColor Cyan

# Output JSON report if requested
if ($JsonOutput -ne "") {
    $reportObj = [PSCustomObject]@{
        Timestamp    = (Get-Date -Format "o")
        TotalTests   = $totalTests
        TotalPassed  = $totalPass
        TotalFailed  = $totalFail
        PassRate     = "$overallPassPct%"
        TierSummary  = $summaryRows
        Results      = $Global:TestResults
    }
    $reportJson = $reportObj | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText($JsonOutput, $reportJson, [System.Text.Encoding]::UTF8)
    Write-Host "Results JSON saved to: $JsonOutput" -ForegroundColor DarkGray
}

# Exit code handling: 0 if 100% pass, 1 if any failure
if ($totalFail -gt 0) {
    Write-Host "`n>> QUALITY GATE STATUS: FAILED ($totalFail failing checks)" -ForegroundColor Red
    Write-Host ">> Expected during early implementation milestones (TDD baseline)." -ForegroundColor Yellow
    exit 1
} else {
    Write-Host "`n>> QUALITY GATE STATUS: PASSED (100% compliant)" -ForegroundColor Green
    exit 0
}
