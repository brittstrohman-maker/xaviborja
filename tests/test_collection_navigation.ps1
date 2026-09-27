Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - COLLECTION NAVIGATION VERIFICATION                   " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$root = $PSScriptRoot + "\.."
$header = Get-Content -Raw "$root\sections\header.liquid"
$footer = Get-Content -Raw "$root\sections\footer.liquid"
$index = Get-Content -Raw "$root\templates\index.json"

function Assert-Test($condition, $name) {
    if ($condition) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $name" -ForegroundColor Red
        throw "Assertion failed: $name"
    }
}

# 1. Header checks
Assert-Test ($header -match '/collections/espresso-tools') "Header links to /collections/espresso-tools"
Assert-Test ($header -match '/collections/coffee-station') "Header links to /collections/coffee-station"
Assert-Test ($header -match '/collections/brewing') "Header links to /collections/brewing"
Assert-Test ($header -match '/collections/cups-glassware') "Header links to /collections/cups-glassware"
Assert-Test ($header -match 'show_collection_links') "Header schema exposes show_collection_links"
Assert-Test ($header -match 'nav__dropdown') "Header includes desktop dropdown menu"
Assert-Test ($header -match 'menu-drawer__sublist') "Header includes mobile drawer collection sublist"

# 2. Index template checks
Assert-Test ($index -match '"link": "/collections/espresso-tools"') "Index hero/card-1 links to /collections/espresso-tools"
Assert-Test ($index -match '"link": "/collections/coffee-station"') "Index card-2 links to /collections/coffee-station"
Assert-Test ($index -match '"link": "/collections/brewing"') "Index card-3 links to /collections/brewing"
Assert-Test ($index -match '"link": "/collections/cups-glassware"') "Index card-4 links to /collections/cups-glassware"

# 3. Footer checks
Assert-Test ($footer -match '/collections/espresso-tools') "Footer links to /collections/espresso-tools"
Assert-Test ($footer -match '/collections/cups-glassware') "Footer links to /collections/cups-glassware"

# 4. JSON validity check
$jsonFiles = Get-ChildItem -Path $root -Recurse -Filter *.json
foreach ($f in $jsonFiles) {
    try {
        $c = Get-Content -Raw -Encoding UTF8 $f.FullName
        $null = ConvertFrom-Json $c
        Write-Host "  [PASS] Valid JSON: $($f.Name)" -ForegroundColor Green
    } catch {
        Write-Host "  [FAIL] Invalid JSON: $($f.FullName) - $($_.Exception.Message)" -ForegroundColor Red
        throw "JSON error in $($f.FullName)"
    }
}

Write-Host "`nAll Collection Navigation and Template assertions PASSED (100%)" -ForegroundColor Green
