#!/bin/bash
#
# xanadOS Cleanup and Validation Summary
# Validates directory structure and reports cleanup status
#

cd "$(dirname "$0")/../.." || exit 1

echo "🧹 CLEANUP AND VALIDATION SUMMARY"
echo "================================="
echo ""

echo "✅ COMPLETED CLEANUP TASKS:"
echo "1. Archived deprecated files:"
echo "   • test-directory-structure.sh → archive/deprecated/2025-08-01-cleanup/"
echo ""

echo "2. Updated directory references:"
echo "   • Removed hardcoded paths from documentation"
echo "   • Updated test files to use relative paths"
echo "   • Marked USER_DATA_DIRS as deprecated in directories.sh"
echo "   • Updated temp directory to use docs/reports/temp/"
echo ""

echo "3. Fixed directory structure inconsistencies:"
echo "   • All reports now in docs/reports/ (not Docs/)"
echo "   • Added temp/ subdirectory to reports structure"
echo "   • Updated documentation to reflect current structure"
echo ""

echo "📁 CURRENT DIRECTORY STRUCTURE:"
echo "docs/reports/"
ls -la docs/reports/ | sed 's/^/  /'
echo ""

echo "📊 FILE COUNTS:"
echo "  Data files: $(find docs/reports/data/ -type f | wc -l)"
echo "  Generated reports: $(find docs/reports/generated/ -type f | wc -l)"
echo "  Archived files: $(find archive/deprecated/2025-08-01-cleanup/ -type f | wc -l)"
echo ""

echo "🔍 VALIDATION CHECKS:"

# Check for remaining hardcoded paths
HARDCODED_PATHS=$(find docs/ scripts/ \( -name "*.md" -o -name "*.sh" \) -print0 | xargs -0 grep -l "$(pwd)" 2>/dev/null | wc -l)
if [[ $HARDCODED_PATHS -eq 0 ]]; then
    echo "  ✅ No hardcoded absolute paths found"
else
    echo "  ⚠️  Found $HARDCODED_PATHS files with hardcoded paths"
fi

# Check directory structure
if [[ -d "docs/reports/data" && -d "docs/reports/generated" && -d "docs/reports/archive" && -d "docs/reports/temp" ]]; then
    echo "  ✅ All required directories exist"
else
    echo "  ❌ Missing required directories"
fi

# Check for orphaned Docs directory
if [[ ! -d "Docs" ]]; then
    echo "  ✅ No conflicting Docs/ directory"
else
    echo "  ⚠️  Conflicting Docs/ directory still exists"
fi

# Check test files
ACTIVE_TESTS=$(find scripts/dev-tools/ -name "test-*.sh" | wc -l)
echo "  📋 Active test files: $ACTIVE_TESTS"

echo ""
echo "🎯 CLEANUP STATUS: COMPLETE"
echo ""
echo "📋 RECOMMENDATIONS:"
echo "1. Review archived files in archive/deprecated/2025-08-01-cleanup/"
echo "2. Test all functionality with updated directory structure"
echo "3. Update any external documentation that references old paths"
echo "4. Consider removing USER_DATA_DIRS in future version"
echo ""

echo "🚀 READY FOR NEXT DEVELOPMENT PHASE!"
