$url = "https://doseydial.myshopify.com/"
try {
    $res = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -MaximumRedirection 5
    $html = $res.Content
    Write-Host "HTTP Status: $($res.StatusCode)" -ForegroundColor Green
    
    $hasLogo = $html -match "dose-dial-logo\.svg"
    $hasFavicon = $html -match "favicon\.svg"
    $hasAppleTouch = $html -match "apple-touch-icon\.png"
    
    Write-Host "  Live HTML contains dose-dial-logo.svg: $hasLogo" -ForegroundColor $(if ($hasLogo) { "Green" } else { "Yellow" })
    Write-Host "  Live HTML contains favicon.svg: $hasFavicon" -ForegroundColor $(if ($hasFavicon) { "Green" } else { "Yellow" })
    Write-Host "  Live HTML contains apple-touch-icon.png: $hasAppleTouch" -ForegroundColor $(if ($hasAppleTouch) { "Green" } else { "Yellow" })
} catch {
    Write-Host "Error fetching live URL: $($_.Exception.Message)" -ForegroundColor Red
}
