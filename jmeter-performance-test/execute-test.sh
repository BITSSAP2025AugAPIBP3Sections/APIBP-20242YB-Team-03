#!/bin/bash

# =============================================================================
# JMeter Performance Test Execution Script
# =============================================================================
# Usage: ./execute-test.sh
# 
# Results: Saved in timestamped folders with JTL data + HTML dashboard
# =============================================================================

set -e  # Exit on any error

# Configuration
JMETER_TEST_DIR=$(pwd)
CURRENT_DATETIME=$(date +"%Y-%m-%d_%H-%M-%S")
TEST_PLAN="performance-test.jmx"

# Create timestamped result directory
RESULTS_BASE_DIR="results"
RESULT_DIR="$RESULTS_BASE_DIR/test_${CURRENT_DATETIME}"
mkdir -p "$RESULT_DIR"

echo "🚀 JMeter Performance Test Runner"
echo "=================================="
echo "Timestamp: $CURRENT_DATETIME"
echo "Result Folder: $RESULT_DIR"
echo ""

# Step 1: Validate test files exist
echo "📋 Validating test configuration..."
if [ ! -f "$TEST_PLAN" ]; then
    echo "❌ ERROR: JMeter test plan '$TEST_PLAN' not found!"
    echo "Please ensure the test plan exists in the current directory."
    exit 1
fi

echo "✅ Test plan: $TEST_PLAN"
echo ""

# Step 2: Execute JMeter test
echo "🧪 Executing JMeter Performance Test"
echo "===================================="

RESULTS_JTL="$RESULT_DIR/results.jtl"
echo "📁 Results file: $RESULTS_JTL"
echo ""

# Run JMeter in non-GUI mode
echo "🏃 Running JMeter test..."
jmeter -n -t "$TEST_PLAN" \
    -l "$RESULTS_JTL" \
    -JcurrentDateTime="$CURRENT_DATETIME" \
    -e -o "$RESULT_DIR/temp_dashboard"

JMETER_EXIT_CODE=$?

# Check JMeter execution result
if [ $JMETER_EXIT_CODE -ne 0 ]; then
    echo "❌ JMeter test execution failed (Exit code: $JMETER_EXIT_CODE)"
    exit 1
fi

echo "✅ JMeter test completed successfully!"

# Step 3: Generate HTML dashboard
echo ""
echo "📊 Generating HTML Dashboard"
echo "============================"

DASHBOARD_DIR="$RESULT_DIR/dashboard"
echo "📁 Dashboard directory: $DASHBOARD_DIR"

# Create dashboard from results
mkdir -p "$DASHBOARD_DIR"

# Remove temporary dashboard and create final one
rm -rf "$RESULT_DIR/temp_dashboard" 2>/dev/null || true

echo "🎨 Generating dashboard from results..."
jmeter -g "$RESULTS_JTL" -o "$DASHBOARD_DIR"

DASHBOARD_EXIT_CODE=$?

if [ $DASHBOARD_EXIT_CODE -eq 0 ]; then
    echo "✅ Dashboard generated successfully!"
else
    echo "⚠️  Dashboard generation had issues (Exit code: $DASHBOARD_EXIT_CODE)"
    echo "   Results file is still available: $RESULTS_JTL"
fi

# Step 4: Display results summary
echo ""
echo "🎯 Test Results Summary"
echo "======================"
echo "Timestamp: $CURRENT_DATETIME"
echo "Result Folder: $RESULT_DIR"
echo ""
echo "📄 Raw Results: $RESULTS_JTL"
if [ -f "$DASHBOARD_DIR/index.html" ]; then
    echo "📊 Dashboard: $DASHBOARD_DIR/index.html"
    echo ""
    echo "🚀 Quick Actions:"
    echo "   View Dashboard: open $DASHBOARD_DIR/index.html"
    echo "   View Results:   cat $RESULTS_JTL"
else
    echo "⚠️  Dashboard not generated - check JMeter logs"
fi

echo ""
echo "🏁 Performance test complete!"
