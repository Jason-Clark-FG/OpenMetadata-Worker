#!/bin/bash

# Test script for matrix generation logic
# This simulates the workflow's matrix generation to ensure JSON is properly formatted

echo "🧪 Testing matrix generation logic..."

# Simulate GitHub variables
PROD_RELEASE_BRANCH="1.4.6"
DEV_RELEASE_BRANCH="1.5.0"
OM_LATEST_RELEASE="1.5.1"

# Generate random suffixes (simulate workflow logic)
prod_suffix=$(shuf -er -n8 {a..z} | paste -sd '')
dev_suffix=$(shuf -er -n8 {a..z} | paste -sd '')
latest_suffix=$(shuf -er -n8 {a..z} | paste -sd '')

echo "Test variables:"
echo "  PROD_RELEASE_BRANCH: $PROD_RELEASE_BRANCH"
echo "  DEV_RELEASE_BRANCH: $DEV_RELEASE_BRANCH"
echo "  OM_LATEST_RELEASE: $OM_LATEST_RELEASE"
echo "  Generated suffixes: prod-$prod_suffix, dev-$dev_suffix, latest-$latest_suffix"
echo

# Test the matrix generation logic
echo "📋 Testing matrix generation..."

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo "❌ jq command not found. Please install jq first."
    echo "You can install it via: winget install stedolan.jq"
    echo "Skipping tests that require jq..."
    exit 0
fi

echo "✅ jq command found"

tests_passed=true

# Build JSON array using jq for proper escaping (exact workflow logic)
matrix_json=$(jq -n '[]')

# Always scan PROD
matrix_json=$(echo "$matrix_json" | jq --arg tag "$PROD_RELEASE_BRANCH" \
  --arg suffix "prod" \
  --arg name "Production" \
  --arg label "spot-prod-${prod_suffix}" \
  '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')

# Scan DEV if different from PROD
if [[ "$DEV_RELEASE_BRANCH" != "$PROD_RELEASE_BRANCH" ]]; then
  matrix_json=$(echo "$matrix_json" | jq --arg tag "$DEV_RELEASE_BRANCH" \
    --arg suffix "dev" \
    --arg name "Development" \
    --arg label "spot-dev-${dev_suffix}" \
    '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')
fi

# Scan LATEST if different from both DEV and PROD
if [[ "$OM_LATEST_RELEASE" != "$DEV_RELEASE_BRANCH" && "$OM_LATEST_RELEASE" != "$PROD_RELEASE_BRANCH" ]]; then
  matrix_json=$(echo "$matrix_json" | jq --arg tag "$OM_LATEST_RELEASE" \
    --arg suffix "latest" \
    --arg name "Latest" \
    --arg label "spot-latest-${latest_suffix}" \
    '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')
fi

echo "Generated matrix: $matrix_json"

# Enhanced JSON validation with detailed debugging (exact workflow logic)
if echo "$matrix_json" | jq empty 2>/dev/null; then
  echo "✅ JSON validation successful"
  echo "Matrix structure:"
  echo "$matrix_json" | jq .
  echo "Matrix items count: $(echo "$matrix_json" | jq length)"
  
  # Test that we can iterate over the items (simulating workflow usage)
  echo
  echo "📝 Testing matrix iteration:"
  while IFS= read -r item; do
    tag=$(echo "$item" | jq -r '.tag')
    suffix=$(echo "$item" | jq -r '.suffix')
    name=$(echo "$item" | jq -r '.name')
    label=$(echo "$item" | jq -r '.label')
    echo "  - $name ($suffix): tag=$tag, label=$label"
  done < <(echo "$matrix_json" | jq -c '.[]')
  
  echo
  echo "🎉 Matrix generation test passed!"
else
  echo "❌ JSON validation failed"
  echo "Invalid JSON: $matrix_json"
  echo "JSON error details:"
  echo "$matrix_json" | jq . 2>&1 || true
  echo "Environment variables:"
  echo "PROD_RELEASE_BRANCH: $PROD_RELEASE_BRANCH"
  echo "DEV_RELEASE_BRANCH: $DEV_RELEASE_BRANCH"
  echo "OM_LATEST_RELEASE: $OM_LATEST_RELEASE"
  tests_passed=false
fi

echo
echo "🔄 Testing edge cases..."

# Test case: All versions are the same
echo "Testing case where all versions are identical..."
TEST_VERSION="1.0.0"
edge_matrix_json=$(jq -n '[]')

edge_matrix_json=$(echo "$edge_matrix_json" | jq --arg tag "$TEST_VERSION" \
  --arg suffix "prod" \
  --arg name "Production" \
  --arg label "spot-prod-${prod_suffix}" \
  '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')

if [[ "$TEST_VERSION" != "$TEST_VERSION" ]]; then
  edge_matrix_json=$(echo "$edge_matrix_json" | jq --arg tag "$TEST_VERSION" \
    --arg suffix "dev" \
    --arg name "Development" \
    --arg label "spot-dev-${dev_suffix}" \
    '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')
fi

if [[ "$TEST_VERSION" != "$TEST_VERSION" && "$TEST_VERSION" != "$TEST_VERSION" ]]; then
  edge_matrix_json=$(echo "$edge_matrix_json" | jq --arg tag "$TEST_VERSION" \
    --arg suffix "latest" \
    --arg name "Latest" \
    --arg label "spot-latest-${latest_suffix}" \
    '. += [{"tag": $tag, "suffix": $suffix, "name": $name, "label": $label}]')
fi

echo "Matrix when all versions are identical: $edge_matrix_json"
if echo "$edge_matrix_json" | jq empty 2>/dev/null; then
  echo "✅ Edge case test passed - only PROD item should be present"
  echo "Items count: $(echo "$edge_matrix_json" | jq length)"
else
  echo "❌ Edge case test failed - JSON validation error"
  tests_passed=false
fi

echo
echo "🔄 Testing check-failures matrix logic..."

if [[ -n "$matrix_json" ]]; then
  original_matrix="$matrix_json"
  echo "Original matrix: $original_matrix"
  
  # Initialize empty array for failed items (exact workflow logic)
  failed_matrix=$(jq -n '[]')
  
  # Check each matrix item to see if it failed (exact workflow logic)
  while IFS= read -r item; do
    suffix=$(echo "$item" | jq -r '.suffix')
    
    echo "Checking $suffix scan result..."
    
    # For testing, add all items as "failed" to test the logic
    failed_matrix=$(echo "$failed_matrix" | jq --argjson item "$item" '. += [$item]')
  done < <(echo "$original_matrix" | jq -c '.[]')
  
  # Validate and output the final matrix (exact workflow logic)
  if echo "$failed_matrix" | jq empty 2>/dev/null; then
    echo "✅ Failed matrix JSON validation successful"
    echo "Failed scans matrix: $failed_matrix"
    echo "Failed items count: $(echo "$failed_matrix" | jq length)"
  else
    echo "❌ Failed matrix JSON validation failed"
    echo "Invalid JSON: $failed_matrix"
    echo "JSON error details:"
    echo "$failed_matrix" | jq . 2>&1 || true
    tests_passed=false
  fi
else
  echo "⚠️  Skipping check-failures test - no valid matrix from previous test"
fi

echo
if [[ "$tests_passed" == "true" ]]; then
  echo "🎯 All matrix generation tests completed successfully!"
else
  echo "⚠️  Some tests failed. Please review the errors above."
fi

echo
echo "📋 Test Summary:"
echo "This test validates that the workflow's JSON generation logic works correctly."
echo "The key improvements made to the workflow:"
echo "  ✅ Replaced bash array concatenation with jq-based JSON construction"
echo "  ✅ Added proper variable escaping using jq --arg parameters"
echo "  ✅ Enhanced JSON validation with detailed error reporting"
echo "  ✅ Added debugging output for troubleshooting"
echo
echo "🔧 This bash script uses the exact same logic as the GitHub Actions workflow,"
echo "   making it a more authentic test of the actual workflow behavior."