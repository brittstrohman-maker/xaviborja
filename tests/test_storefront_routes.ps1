$urls = @(
    "https://doseydial.myshopify.com/",
    "https://doseydial.myshopify.com/collections/all",
    "https://doseydial.myshopify.com/cart",
    "https://doseydial.myshopify.com/search"
)

$allPassed = $true
foreach ($url in $urls) {
    try {
        $res = Invoke-WebRequest -Uri $url -Method Get -UseBasicParsing -MaximumRedirection 5
        Write-Host "$url -> StatusCode: $($res.StatusCode)" -ForegroundColor Green
        if ($res.StatusCode -ne 200) {
            $allPassed = $false
        }
    } catch {
        Write-Host "$url -> Error: $($_.Exception.Message)" -ForegroundColor Red
        if ($_.Exception.Response) {
            Write-Host "Response StatusCode: $($_.Exception.Response.StatusCode.value__)" -ForegroundColor Yellow
        }
        $allPassed = $false
    }
}

if ($allPassed) {
    Write-Host "All storefront routes returned HTTP 200 OK!" -ForegroundColor Green
} else {
    Write-Host "Some storefront routes failed." -ForegroundColor Red
}
