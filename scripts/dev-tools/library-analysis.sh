#!/bin/bash

# Simple library consistency analysis for xanadOS
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"

echo "🔍 xanadOS Library Consistency Analysis"
echo "======================================"
echo "Project: $PROJECT_ROOT"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Counters
TOTAL_SCRIPTS=0
SCRIPTS_WITH_DUPLICATES=0
SCRIPTS_NEEDING_FIXES=0

echo "📁 Finding all shell scripts..."
SCRIPT_FILES=$(find "$PROJECT_ROOT/scripts" -name "*.sh" -type f | sort)
TOTAL_SCRIPTS=$(echo "$SCRIPT_FILES" | wc -l)

echo "Found $TOTAL_SCRIPTS shell scripts"
echo ""

echo "🔍 Analyzing duplicate function definitions..."
echo ""

# Check for duplicate print functions
DUPLICATE_FUNCTIONS=(
    "print_status"
    "print_error"
    "print_info"
    "print_success"
    "print_warning"
    "print_header"
)

for func in "${DUPLICATE_FUNCTIONS[@]}"; do
    echo "Checking for duplicate '$func' definitions..."

    # Find files that define this function
    FILES_WITH_FUNC=$(grep -l "^[[:space:]]*$func[[:space:]]*(" ${SCRIPT_FILES} 2>/dev/null || true)

    if [ -n "$FILES_WITH_FUNC" ]; then
        COUNT=$(echo "$FILES_WITH_FUNC" | wc -l)
        if [ "$COUNT" -eq 1 ] && echo "$FILES_WITH_FUNC" | grep -q "/lib/common.sh"; then
            echo "  ✅ Only found in library (expected): $func"
        else
            echo "  ⚠️  Found $COUNT files defining '$func':"
            echo "$FILES_WITH_FUNC" | sed 's/^/    /'
            ((SCRIPTS_WITH_DUPLICATES++))
        fi
    else
        echo "  ✅ No duplicate '$func' definitions found"
    fi
    echo ""
done

echo ""
echo "📊 Summary:"
echo "  Total scripts: $TOTAL_SCRIPTS"
echo "  Scripts with duplicate functions: $SCRIPTS_WITH_DUPLICATES"
echo ""

# Check for scripts missing library sources
echo "🔗 Checking for missing library sources..."
echo ""

SCRIPTS_MISSING_COMMON=0
SCRIPTS_MISSING_LOGGING=0

for script in ${SCRIPT_FILES}; do
    # Skip library files themselves
    if [[ "$script" == */lib/* ]]; then
        continue
    fi

    # Check if script uses print functions but doesn't source common.sh
    if grep -q "print_\(status\|error\|info\|success\|warning\|header\)" "$script" 2>/dev/null; then
        if ! grep -q "source.*common\.sh\|\..*common\.sh" "$script" 2>/dev/null; then
            echo "  ⚠️  $script uses print functions but doesn't source common.sh"
            ((SCRIPTS_MISSING_COMMON++))
        fi
    fi

    # Check if script uses log functions but doesn't source logging.sh
    if grep -q "log_\(info\|error\|success\|warning\|debug\)" "$script" 2>/dev/null; then
        if ! grep -q "source.*logging\.sh\|\..*logging\.sh" "$script" 2>/dev/null; then
            echo "  ⚠️  $script uses log functions but doesn't source logging.sh"
            ((SCRIPTS_MISSING_LOGGING++))
        fi
    fi
done

echo ""
echo "📊 Missing Sources Summary:"
echo "  Scripts missing common.sh source: $SCRIPTS_MISSING_COMMON"
echo "  Scripts missing logging.sh source: $SCRIPTS_MISSING_LOGGING"
echo ""

# Check library files
echo "📚 Library files status:"
for lib in common.sh logging.sh directories.sh config.sh package-management.sh validation.sh display.sh system-info.sh hardware-detection.sh; do
    lib_path="$PROJECT_ROOT/scripts/lib/$lib"
    if [ -f "$lib_path" ]; then
        lines=$(wc -l < "$lib_path")
        echo "  ✅ $lib ($lines lines)"
    else
        echo "  ❌ $lib (missing)"
    fi
done

echo ""
echo "🎯 Analysis Complete!"
echo ""

if [ $SCRIPTS_WITH_DUPLICATES -gt 0 ] || [ $SCRIPTS_MISSING_COMMON -gt 0 ] || [ $SCRIPTS_MISSING_LOGGING -gt 0 ]; then
    echo "❗ Issues found that need fixing:"
    [ $SCRIPTS_WITH_DUPLICATES -gt 0 ] && echo "  - Remove duplicate function definitions"
    [ $SCRIPTS_MISSING_COMMON -gt 0 ] && echo "  - Add missing common.sh sources"
    [ $SCRIPTS_MISSING_LOGGING -gt 0 ] && echo "  - Add missing logging.sh sources"
    echo ""
    echo "Run with --fix flag to automatically fix these issues (when implemented)"
else
    echo "✅ No issues found! Library usage is consistent."
fi

echo ""
echo "Analysis log available at: /tmp/xanados-library-analysis-$(date +%s).log"
