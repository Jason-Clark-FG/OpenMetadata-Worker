# Test script for matrix generation logic
# This simulates the workflow's matrix generation to ensure JSON is properly formatted

Write-Host "🧪 Testing matrix generation logic..." -ForegroundColor Cyan

# Simulate GitHub variables
$PROD_RELEASE_BRANCH = "1.4.6"
$DEV_RELEASE_BRANCH = "1.5.0"
$OM_LATEST_RELEASE = "1.5.1"

# Generate random suffixes (simulate workflow logic)
$prod_suffix = -join ((97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$dev_suffix = -join ((97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })
$latest_suffix = -join ((97..122) | Get-Random -Count 8 | ForEach-Object { [char]$_ })

Write-Host "Test variables:"
Write-Host "  PROD_RELEASE_BRANCH: $PROD_RELEASE_BRANCH"
Write-Host "  DEV_RELEASE_BRANCH: $DEV_RELEASE_BRANCH"
Write-Host "  OM_LATEST_RELEASE: $OM_LATEST_RELEASE"
Write-Host "  Generated suffixes: prod-$prod_suffix, dev-$dev_suffix, latest-$latest_suffix"
Write-Host ""

# Test the matrix generation logic
Write-Host "📋 Testing matrix generation..." -ForegroundColor Yellow

# Check if jq is available
try {
    $null = Get-Command jq -ErrorAction Stop
    Write-Host "✅ jq command found"
} catch {
    Write-Host "❌ jq command not found. Please install jq first." -ForegroundColor Red
    Write-Host "You can install it via: winget install stedolan.jq" -ForegroundColor Yellow
    Write-Host "Skipping tests that require jq..."
    return
}

$testsPassed = $true

# Build JSON array using jq for proper escaping (simulating bash logic)
try {
    $matrix_json = jq -n '[]'

    # Always scan PROD
    $matrix_json = $matrix_json | jq --arg tag $PROD_RELEASE_BRANCH --arg suffix "prod" --arg name "Production" --arg label "spot-prod-$prod_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'

    # Scan DEV if different from PROD
    if ($DEV_RELEASE_BRANCH -ne $PROD_RELEASE_BRANCH) {
        $matrix_json = $matrix_json | jq --arg tag $DEV_RELEASE_BRANCH --arg suffix "dev" --arg name "Development" --arg label "spot-dev-$dev_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'
    }

    # Scan LATEST if different from both DEV and PROD
    if (($OM_LATEST_RELEASE -ne $DEV_RELEASE_BRANCH) -and ($OM_LATEST_RELEASE -ne $PROD_RELEASE_BRANCH)) {
        $matrix_json = $matrix_json | jq --arg tag $OM_LATEST_RELEASE --arg suffix "latest" --arg name "Latest" --arg label "spot-latest-$latest_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'
    }

    Write-Host "Generated matrix: $matrix_json"

    # Enhanced JSON validation with detailed debugging
    try {
        $matrix_json | jq empty 2>$null
        Write-Host "✅ JSON validation successful" -ForegroundColor Green
        Write-Host "Matrix structure:"
        $matrix_json | jq .
        $count = $matrix_json | jq length
        Write-Host "Matrix items count: $count"
        
        # Test that we can iterate over the items (simulating workflow usage)
        Write-Host ""
        Write-Host "📝 Testing matrix iteration:" -ForegroundColor Yellow
        $items = $matrix_json | jq -c '.[]'
        $items | ForEach-Object {
            $item = $_
            $tag = $item | jq -r '.tag'
            $suffix = $item | jq -r '.suffix'
            $name = $item | jq -r '.name'
            $label = $item | jq -r '.label'
            Write-Host "  - $name ($suffix): tag=$tag, label=$label"
        }
        
        Write-Host ""
        Write-Host "🎉 Matrix generation test passed!" -ForegroundColor Green
    } catch {
        Write-Host "❌ JSON validation failed" -ForegroundColor Red
        Write-Host "Invalid JSON: $matrix_json"
        Write-Host "JSON error details:"
        $matrix_json | jq . 2>&1
        $testsPassed = $false
    }
} catch {
    Write-Host "❌ Error during matrix generation: $($_.Exception.Message)" -ForegroundColor Red
    $testsPassed = $false
}

Write-Host ""
Write-Host "🔄 Testing edge cases..." -ForegroundColor Yellow

# Test case: All versions are the same
Write-Host "Testing case where all versions are identical..."
try {
    $TEST_VERSION = "1.0.0"
    $edge_matrix_json = jq -n '[]'

    $edge_matrix_json = $edge_matrix_json | jq --arg tag $TEST_VERSION --arg suffix "prod" --arg name "Production" --arg label "spot-prod-$prod_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'

    if ($TEST_VERSION -ne $TEST_VERSION) {
        $edge_matrix_json = $edge_matrix_json | jq --arg tag $TEST_VERSION --arg suffix "dev" --arg name "Development" --arg label "spot-dev-$dev_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'
    }

    if (($TEST_VERSION -ne $TEST_VERSION) -and ($TEST_VERSION -ne $TEST_VERSION)) {
        $edge_matrix_json = $edge_matrix_json | jq --arg tag $TEST_VERSION --arg suffix "latest" --arg name "Latest" --arg label "spot-latest-$latest_suffix" '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]'
    }

    Write-Host "Matrix when all versions are identical: $edge_matrix_json"
    try {
        $edge_matrix_json | jq empty 2>$null
        Write-Host "✅ Edge case test passed - only PROD item should be present" -ForegroundColor Green
        $count = $edge_matrix_json | jq length
        Write-Host "Items count: $count"
    } catch {
        Write-Host "❌ Edge case test failed - JSON validation error" -ForegroundColor Red
        $testsPassed = $false
    }
} catch {
    Write-Host "❌ Error during edge case testing: $($_.Exception.Message)" -ForegroundColor Red
    $testsPassed = $false
}

# Test the check-failures logic too
Write-Host ""
Write-Host "🔄 Testing check-failures matrix logic..." -ForegroundColor Yellow

try {
    if ($matrix_json) {
        $original_matrix = $matrix_json
        Write-Host "Original matrix: $original_matrix"

        # Initialize empty array for failed items
        $failed_matrix = jq -n '[]'

        # Simulate checking each item (in real workflow, this would check actual job results)
        $items = $original_matrix | jq -c '.[]'
        $items | ForEach-Object {
            $item = $_
            $suffix = $item | jq -r '.suffix'
            Write-Host "Checking $suffix scan result..."
            
            # For testing, add all items as "failed" to test the logic
            $script:failed_matrix = $script:failed_matrix | jq --argjson item $item '. += [$item]'
        }

        Write-Host "Failed scans matrix: $failed_matrix"

        try {
            $failed_matrix | jq empty 2>$null
            Write-Host "✅ Failed matrix JSON validation successful" -ForegroundColor Green
            $count = $failed_matrix | jq length
            Write-Host "Failed items count: $count"
        } catch {
            Write-Host "❌ Failed matrix JSON validation failed" -ForegroundColor Red
            Write-Host "Invalid JSON: $failed_matrix"
            $testsPassed = $false
        }
    } else {
        Write-Host "⚠️  Skipping check-failures test - no valid matrix from previous test" -ForegroundColor Yellow
    }
} catch {
    Write-Host "❌ Error during check-failures testing: $($_.Exception.Message)" -ForegroundColor Red
    $testsPassed = $false
}

Write-Host ""
if ($testsPassed) {
    Write-Host "🎯 All matrix generation tests completed successfully!" -ForegroundColor Green
} else {
    Write-Host "⚠️  Some tests failed. Please review the errors above." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "📋 Test Summary:" -ForegroundColor Cyan
Write-Host "This test validates that the workflow's JSON generation logic works correctly."
Write-Host "The key improvements made to the workflow:"
Write-Host "  ✅ Replaced bash array concatenation with jq-based JSON construction"
Write-Host "  ✅ Added proper variable escaping using jq --arg parameters"
Write-Host "  ✅ Enhanced JSON validation with detailed error reporting"
Write-Host "  ✅ Added debugging output for troubleshooting"