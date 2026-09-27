Write-Host "======================================================================" -ForegroundColor Cyan
Write-Host "   DOSE & DIAL - COOKIE CONSENT & PRIVACY POPUP STYLING TEST         " -ForegroundColor Cyan
Write-Host "======================================================================" -ForegroundColor Cyan

$baseCss = Get-Content "assets/base.css" -Raw
$failures = 0

function Assert-Check($name, $passed, $info = "") {
    if ($passed) {
        Write-Host "  [PASS] $name" -ForegroundColor Green
    } else {
        Write-Host "  [FAIL] $name - $info" -ForegroundColor Red
        $script:failures++
    }
}

Assert-Check "base.css contains #shopify-pc__banner dialog selector" ($baseCss -match "#shopify-pc__banner\.shopify-pc__banner__dialog")
Assert-Check "base.css applies dark obsidian glassmorphism" ($baseCss -match "rgba\(19,\s*21,\s*26,\s*0\.95\)")
Assert-Check "base.css applies backdrop-filter blur" ($baseCss -match "backdrop-filter:\s*blur\(24px\)")
Assert-Check "base.css styles illuminated amber LED dot on title" ($baseCss -match "shopify-pc__banner__body-title::before")
Assert-Check "base.css styles amber policy link" ($baseCss -match "shopify-pc__banner__body-policy-link")
Assert-Check "base.css styles molten amber Accept button" ($baseCss -match "shopify-pc__banner__btn-accept[\s\S]*?linear-gradient\(135deg,\s*#F4C58E\s*0%,\s*#E5A968\s*100%\)")
Assert-Check "base.css styles frosted titanium Decline button" ($baseCss -match "shopify-pc__banner__btn-decline[\s\S]*?rgba\(255,\s*255,\s*255,\s*0\.05\)")
Assert-Check "base.css styles Manage Preferences button" ($baseCss -match "shopify-pc__banner__btn-manage-prefs")
Assert-Check "base.css includes responsive mobile media query" ($baseCss -match "@media screen and \(max-width:\s*749px\)[\s\S]*?shopify-pc__banner__btns[\s\S]*?flex-direction:\s*column-reverse")
Assert-Check "base.css styles Preferences modal #shopify-pc__prefs__dialog" ($baseCss -match "#shopify-pc__prefs__dialog")
Assert-Check "base.css styles Preferences overlay #shopify-pc__prefs__overlay" ($baseCss -match "#shopify-pc__prefs__overlay")

Write-Host ""
if ($failures -eq 0) {
    Write-Host "All Cookie Consent assertions PASSED (100%)" -ForegroundColor Green
    exit 0
} else {
    Write-Host "Failed assertions: $failures" -ForegroundColor Red
    exit 1
}
