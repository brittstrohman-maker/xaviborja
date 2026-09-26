$locales = Get-Content "locales/en.default.schema.json" -Raw | ConvertFrom-Json

# 1. Check config/settings_schema.json
$schemaRaw = Get-Content "config/settings_schema.json" -Raw
$matches = [regex]::Matches($schemaRaw, '"(t:[^"]+)"')
Write-Host "Total translation references in settings_schema.json: $($matches.Count)"
$missingCount = 0
$seen = @{}

foreach ($m in $matches) {
    $k = $m.Groups[1].Value
    if ($seen.ContainsKey($k)) { continue }
    $seen[$k] = $true

    $parts = $k.Substring(2).Split('.')
    $curr = $locales
    $missing = $false
    foreach ($p in $parts) {
        if ($curr -and $curr.PSObject.Properties[$p]) {
            $curr = $curr.$p
        } else {
            $missing = $true
            break
        }
    }
    if ($missing) {
        Write-Host "  MISSING in settings_schema.json: $k" -ForegroundColor Red
        $missingCount++
    }
}

# 2. Check all sections/*.liquid schemas
$sectionFiles = Get-ChildItem "sections/*.liquid"
$sectionMissingCount = 0
foreach ($sf in $sectionFiles) {
    $content = Get-Content $sf.FullName -Raw
    if ($content -match '\{%\s*schema\s*%\}([\s\S]*?)\{%\s*endschema\s*%\}') {
        $sectionSchemaJson = $matches[1]
        $secMatches = [regex]::Matches($sectionSchemaJson, '"(t:[^"]+)"')
        foreach ($sm in $secMatches) {
            $k = $sm.Groups[1].Value
            $parts = $k.Substring(2).Split('.')
            $curr = $locales
            $missing = $false
            foreach ($p in $parts) {
                if ($curr -and $curr.PSObject.Properties[$p]) {
                    $curr = $curr.$p
                } else {
                    $missing = $true
                    break
                }
            }
            if ($missing) {
                Write-Host "  MISSING in $($sf.Name): $k" -ForegroundColor Red
                $sectionMissingCount++
            }
        }
    }
}

Write-Host "Section schema missing translations: $sectionMissingCount"
if ($missingCount -eq 0 -and $sectionMissingCount -eq 0) {
    Write-Host "All translation keys exist in locales/en.default.schema.json! (0 missing)" -ForegroundColor Green
} else {
    Write-Host "Total missing translation keys: $($missingCount + $sectionMissingCount)" -ForegroundColor Red
    exit 1
}
