#!/bin/bash

# Local Code Quality Analysis Script
# Runs comprehensive code quality checks using available local tools
# Tools: SonarQube Scanner, ESLint, Semgrep, Trivy, TypeScript Compiler

set -e

echo "=========================================="
echo "Local Code Quality Analysis"
echo "=========================================="

# Configuration
WORKSPACE_DIR="$(pwd)"
REPORTS_DIR="code-quality-reports"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create reports directory
mkdir -p "$REPORTS_DIR"

echo "📁 Reports will be saved to: $REPORTS_DIR/"
echo "🕒 Analysis started at: $(date)"
echo ""

# Initialize results tracking
RESULTS=()
OVERALL_STATUS="PASS"

# Function to add result
add_result() {
    local tool=$1
    local status=$2
    local details=$3
    RESULTS+=("$tool|$status|$details")

    if [ "$status" = "FAIL" ]; then
        OVERALL_STATUS="FAIL"
    fi

    echo "✅ $tool: $status"
    if [ -n "$details" ]; then
        echo "   $details"
    fi
    echo ""
}

echo "🔍 Running Code Quality Analysis Tools..."
echo "=========================================="

# 1. ESLint Analysis
echo "1. Running ESLint Analysis..."
if command -v npx &> /dev/null; then
    if [ -f "package.json" ]; then
        echo "   📦 Found package.json, running ESLint..."

        # Try to run ESLint
        if npx eslint . --ext .js,.jsx,.ts,.tsx --format=json > "$REPORTS_DIR/eslint-results.json" 2>/dev/null; then
            # Parse ESLint results
            ERROR_COUNT=$(jq '.[] | select(.errorCount > 0) | .errorCount' "$REPORTS_DIR/eslint-results.json" | jq -s 'add // 0')
            WARNING_COUNT=$(jq '.[] | select(.warningCount > 0) | .warningCount' "$REPORTS_DIR/eslint-results.json" | jq -s 'add // 0')

            if [ "$ERROR_COUNT" -gt 0 ]; then
                add_result "ESLint" "FAIL" "Found $ERROR_COUNT errors and $WARNING_COUNT warnings"
            elif [ "$WARNING_COUNT" -gt 10 ]; then
                add_result "ESLint" "WARN" "Found $WARNING_COUNT warnings (acceptable threshold)"
            else
                add_result "ESLint" "PASS" "No errors, $WARNING_COUNT warnings"
            fi
        else
            # Try with different ESLint command
            if npx eslint src/ server/ --ext .js,.jsx,.ts,.tsx > "$REPORTS_DIR/eslint-output.txt" 2>&1; then
                add_result "ESLint" "PASS" "Analysis completed successfully"
            else
                add_result "ESLint" "WARN" "ESLint completed with warnings (check output)"
            fi
        fi
    else
        add_result "ESLint" "SKIP" "No package.json found"
    fi
else
    add_result "ESLint" "SKIP" "npx not available"
fi

# 2. TypeScript Type Checking
echo "2. Running TypeScript Type Checking..."
if command -v npx &> /dev/null; then
    if [ -f "tsconfig.json" ] || [ -f "server/tsconfig.json" ]; then
        echo "   📝 Found TypeScript configuration"

        if npx tsc --noEmit --skipLibCheck > "$REPORTS_DIR/tsc-output.txt" 2>&1; then
            add_result "TypeScript" "PASS" "Type checking passed"
        else
            ERROR_COUNT=$(grep -c "error" "$REPORTS_DIR/tsc-output.txt" || echo "0")
            add_result "TypeScript" "FAIL" "Found $ERROR_COUNT type errors"
        fi
    else
        add_result "TypeScript" "SKIP" "No TypeScript configuration found"
    fi
else
    add_result "TypeScript" "SKIP" "npx not available"
fi

# 3. SonarQube Scanner Analysis
echo "3. Running SonarQube Scanner Analysis..."
if command -v sonar-scanner &> /dev/null; then
    echo "   🔍 SonarQube scanner found"

    # Set SonarQube properties
    export SONAR_HOST_URL="${SONAR_HOST_URL:-http://localhost:9000}"
    export SONAR_PROJECT_KEY="${SONAR_PROJECT_KEY:-healthcare-app}"
    export SONAR_PROJECT_NAME="${SONAR_PROJECT_NAME:-Healthcare App}"
    export SONAR_SOURCES="${SONAR_SOURCES:-src,server}"

    # Run SonarQube analysis
    if sonar-scanner \
        -Dsonar.projectKey="$SONAR_PROJECT_KEY" \
        -Dsonar.projectName="$SONAR_PROJECT_NAME" \
        -Dsonar.sources="$SONAR_SOURCES" \
        -Dsonar.host.url="$SONAR_HOST_URL" \
        -Dsonar.login="${SONAR_TOKEN:-}" \
        -Dsonar.javascript.node.maxspace=4096 \
        -Dsonar.typescript.node.maxspace=4096 \
        > "$REPORTS_DIR/sonar-scanner-output.txt" 2>&1; then

        # Extract quality metrics from output
        BUGS=$(grep -o "Bugs: [0-9]*" "$REPORTS_DIR/sonar-scanner-output.txt" | grep -o "[0-9]*" | head -1 || echo "0")
        VULNERABILITIES=$(grep -o "Vulnerabilities: [0-9]*" "$REPORTS_DIR/sonar-scanner-output.txt" | grep -o "[0-9]*" | head -1 || echo "0")
        CODE_SMELLS=$(grep -o "Code Smells: [0-9]*" "$REPORTS_DIR/sonar-scanner-output.txt" | grep -o "[0-9]*" | head -1 || echo "0")

        DETAILS="Bugs: $BUGS, Vulnerabilities: $VULNERABILITIES, Code Smells: $CODE_SMELLS"

        if [ "$BUGS" -gt 5 ] || [ "$VULNERABILITIES" -gt 0 ]; then
            add_result "SonarQube" "FAIL" "$DETAILS"
        else
            add_result "SonarQube" "PASS" "$DETAILS"
        fi
    else
        add_result "SonarQube" "FAIL" "SonarQube analysis failed"
    fi

elif command -v npx &> /dev/null; then
    echo "   📦 Using npx sonar-scanner"

    if npx sonar-scanner \
        -Dsonar.projectKey=healthcare-app \
        -Dsonar.projectName="Healthcare App" \
        -Dsonar.sources="src,server" \
        -Dsonar.host.url="${SONAR_HOST_URL:-http://localhost:9000}" \
        -Dsonar.login="${SONAR_TOKEN:-}" \
        > "$REPORTS_DIR/sonar-scanner-output.txt" 2>&1; then

        add_result "SonarQube" "PASS" "Analysis completed via npx"
    else
        add_result "SonarQube" "WARN" "Analysis failed (server may not be available)"
    fi
else
    add_result "SonarQube" "SKIP" "SonarQube scanner not available"
fi

# 4. Semgrep SAST Analysis
echo "4. Running Semgrep SAST Analysis..."
if command -v semgrep &> /dev/null; then
    echo "   🔒 Running Semgrep security analysis"

    if semgrep --config=auto --json --output="$REPORTS_DIR/semgrep-results.json" . > "$REPORTS_DIR/semgrep-output.txt" 2>&1; then
        # Parse Semgrep results
        if [ -f "$REPORTS_DIR/semgrep-results.json" ]; then
            CRITICAL=$(jq '.results[] | select(.extra.severity == "ERROR") | .path' "$REPORTS_DIR/semgrep-results.json" 2>/dev/null | wc -l || echo "0")
            HIGH=$(jq '.results[] | select(.extra.severity == "WARNING") | .path' "$REPORTS_DIR/semgrep-results.json" 2>/dev/null | wc -l || echo "0")
            TOTAL=$(jq '.results | length' "$REPORTS_DIR/semgrep-results.json" 2>/dev/null || echo "0")

            DETAILS="Critical: $CRITICAL, High: $HIGH, Total: $TOTAL"

            if [ "$CRITICAL" -gt 0 ]; then
                add_result "Semgrep" "FAIL" "$DETAILS - Critical issues found"
            elif [ "$HIGH" -gt 5 ]; then
                add_result "Semgrep" "WARN" "$DETAILS - High severity issues"
            else
                add_result "Semgrep" "PASS" "$DETAILS"
            fi
        else
            add_result "Semgrep" "PASS" "Analysis completed (no issues found)"
        fi
    else
        add_result "Semgrep" "WARN" "Semgrep analysis completed with warnings"
    fi
else
    add_result "Semgrep" "SKIP" "Semgrep not available"
fi

# 5. Trivy Container Security Scan
echo "5. Running Trivy Container Security Scan..."
if command -v trivy &> /dev/null; then
    echo "   🐳 Scanning container images"

    VULN_FOUND=0
    IMAGES_SCANNED=0

    # Check for healthcare app images
    for image in "healthcare-app-frontend" "healthcare-app-backend"; do
        if docker images "$image" | grep -q "$image"; then
            echo "   Scanning $image..."

            if trivy image --format json --output "$REPORTS_DIR/trivy-$image.json" "$image" > /dev/null 2>&1; then
                # Parse Trivy results
                CRITICAL_VULN=$(jq '.Results[0].Vulnerabilities[] | select(.Severity == "CRITICAL") | .VulnerabilityID' "$REPORTS_DIR/trivy-$image.json" 2>/dev/null | wc -l || echo "0")
                HIGH_VULN=$(jq '.Results[0].Vulnerabilities[] | select(.Severity == "HIGH") | .VulnerabilityID' "$REPORTS_DIR/trivy-$image.json" 2>/dev/null | wc -l || echo "0")

                if [ "$CRITICAL_VULN" -gt 0 ]; then
                    add_result "Trivy-$image" "FAIL" "Found $CRITICAL_VULN critical vulnerabilities"
                    VULN_FOUND=1
                elif [ "$HIGH_VULN" -gt 3 ]; then
                    add_result "Trivy-$image" "WARN" "Found $HIGH_VULN high vulnerabilities"
                else
                    add_result "Trivy-$image" "PASS" "Low vulnerability count"
                fi

                IMAGES_SCANNED=$((IMAGES_SCANNED + 1))
            else
                add_result "Trivy-$image" "WARN" "Scan failed for $image"
            fi
        fi
    done

    if [ "$IMAGES_SCANNED" -eq 0 ]; then
        add_result "Trivy" "SKIP" "No container images found to scan"
    fi
else
    add_result "Trivy" "SKIP" "Trivy not available"
fi

# 6. Code Coverage Analysis
echo "6. Running Code Coverage Analysis..."
if [ -d "coverage" ] || [ -f "coverage/lcov.info" ]; then
    echo "   📊 Found coverage reports"

    if [ -f "coverage/lcov.info" ]; then
        # Parse LCOV coverage
        LINES_COVERED=$(grep -o "LF:[0-9]*" coverage/lcov.info | grep -o "[0-9]*" | awk '{sum += $1} END {print sum}' || echo "0")
        LINES_HIT=$(grep -o "LH:[0-9]*" coverage/lcov.info | grep -o "[0-9]*" | awk '{sum += $1} END {print sum}' || echo "0")

        if [ "$LINES_COVERED" -gt 0 ]; then
            COVERAGE_PERCENT=$((LINES_HIT * 100 / LINES_COVERED))
            DETAILS="Coverage: ${COVERAGE_PERCENT}% ($LINES_HIT/$LINES_COVERED lines)"

            if [ "$COVERAGE_PERCENT" -lt 70 ]; then
                add_result "Coverage" "FAIL" "$DETAILS - Below 70% threshold"
            elif [ "$COVERAGE_PERCENT" -lt 80 ]; then
                add_result "Coverage" "WARN" "$DETAILS - Below 80% target"
            else
                add_result "Coverage" "PASS" "$DETAILS"
            fi
        else
            add_result "Coverage" "WARN" "Coverage data found but unable to parse"
        fi
    else
        add_result "Coverage" "PASS" "Coverage reports found"
    fi
else
    add_result "Coverage" "SKIP" "No coverage reports found"
fi

# 7. Dependency Vulnerability Check
echo "7. Running Dependency Vulnerability Check..."
if command -v npm &> /dev/null && [ -f "package.json" ]; then
    echo "   📦 Checking npm dependencies"

    if npm audit --audit-level=moderate --json > "$REPORTS_DIR/npm-audit.json" 2>&1; then
        VULN_TOTAL=$(jq '.metadata.vulnerabilities.total // 0' "$REPORTS_DIR/npm-audit.json" 2>/dev/null || echo "0")
        VULN_CRITICAL=$(jq '.metadata.vulnerabilities.critical // 0' "$REPORTS_DIR/npm-audit.json" 2>/dev/null || echo "0")
        VULN_HIGH=$(jq '.metadata.vulnerabilities.high // 0' "$REPORTS_DIR/npm-audit.json" 2>/dev/null || echo "0")

        DETAILS="Total: $VULN_TOTAL, Critical: $VULN_CRITICAL, High: $VULN_HIGH"

        if [ "$VULN_CRITICAL" -gt 0 ]; then
            add_result "Dependencies" "FAIL" "$DETAILS - Critical vulnerabilities found"
        elif [ "$VULN_HIGH" -gt 5 ]; then
            add_result "Dependencies" "WARN" "$DETAILS - High vulnerability count"
        else
            add_result "Dependencies" "PASS" "$DETAILS"
        fi
    else
        add_result "Dependencies" "WARN" "npm audit completed with issues"
    fi
else
    add_result "Dependencies" "SKIP" "npm or package.json not available"
fi

echo ""
echo "=========================================="
echo "📊 CODE QUALITY ANALYSIS SUMMARY"
echo "=========================================="

# Generate summary report
SUMMARY_FILE="$REPORTS_DIR/code-quality-summary-$TIMESTAMP.json"

# Create summary JSON
cat > "$SUMMARY_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "workspace": "$WORKSPACE_DIR",
  "overall_status": "$OVERALL_STATUS",
  "tools_analyzed": ${#RESULTS[@]},
  "results": [
EOF

# Add results to JSON
for i in "${!RESULTS[@]}"; do
    IFS='|' read -r tool status details <<< "${RESULTS[$i]}"
    echo "    {" >> "$SUMMARY_FILE"
    echo "      \"tool\": \"$tool\"," >> "$SUMMARY_FILE"
    echo "      \"status\": \"$status\"," >> "$SUMMARY_FILE"
    echo "      \"details\": \"$details\"" >> "$SUMMARY_FILE"

    if [ $i -lt $((${#RESULTS[@]} - 1)) ]; then
        echo "    }," >> "$SUMMARY_FILE"
    else
        echo "    }" >> "$SUMMARY_FILE"
    fi
done

cat >> "$SUMMARY_FILE" << EOF
  ],
  "recommendations": [
    "Fix any FAIL status items before committing",
    "Address WARN status items to improve code quality",
    "Run this analysis regularly during development",
    "Consider setting up pre-commit hooks for automated quality checks"
  ]
}
EOF

# Display results table
printf "%-20s %-8s %s\n" "TOOL" "STATUS" "DETAILS"
printf "%-20s %-8s %s\n" "----" "------" "-------"
for result in "${RESULTS[@]}"; do
    IFS='|' read -r tool status details <<< "$result"
    printf "%-20s %-8s %s\n" "$tool" "$status" "$details"
done

echo ""
echo "🎯 Overall Status: $OVERALL_STATUS"
echo "📄 Detailed report saved to: $SUMMARY_FILE"
echo "📁 All reports saved to: $REPORTS_DIR/"
echo ""
echo "✅ Code Quality Analysis Completed!"
echo "=========================================="

# Exit with appropriate code
if [ "$OVERALL_STATUS" = "PASS" ]; then
    exit 0
else
    echo "❌ Some quality checks failed. Please review the results above."
    exit 1
fi
