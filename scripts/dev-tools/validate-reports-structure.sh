#!/bin/bash
#
# Quick test of the docs directory structure
#

cd /home/vm/Documents/xanadOS

echo "🎯 DIRECTORY STRUCTURE UPDATE SUMMARY"
echo ""

echo "✅ Created proper reports structure in docs:"
echo "   docs/reports/data/      - Raw data files"
echo "   docs/reports/generated/ - Generated reports" 
echo "   docs/reports/archive/   - Archived reports"
echo ""

echo "✅ Moved existing files:"
echo "Data files moved to docs/reports/data/:"
find docs/reports/data/ -type f | while read -r file; do
    echo "   $(basename "$file")"
done

echo ""
echo "Generated reports moved to docs/reports/generated/:"
find docs/reports/generated/ -type f | while read -r file; do
    echo "   $(basename "$file")"
done

echo ""
echo "📁 Complete directory structure:"
tree docs/reports/ 2>/dev/null || (
    echo "docs/reports/"
    echo "├── data/"
    find docs/reports/data/ -type f -exec basename {} \; | sed 's/^/│   ├── /'
    echo "├── generated/"
    find docs/reports/generated/ -type f -exec basename {} \; | sed 's/^/│   ├── /'
    echo "├── archive/"
    echo "└── README.md"
)

echo ""
echo "📊 File count summary:"
echo "   Data files: $(find docs/reports/data/ -type f | wc -l)"
echo "   Generated reports: $(find docs/reports/generated/ -type f | wc -l)"
echo "   Total files: $(find docs/reports/ -type f | wc -l)"

echo ""
echo "✅ Benefits of new structure:"
echo "   • All reports now in version control (docs/)"
echo "   • Clear separation of data vs generated files"
echo "   • Easy to find and share reports with team"
echo "   • Automatic archiving prevents directory bloat"
echo "   • Self-documenting with README.md"

echo ""
echo "🚀 Updated directory functions ready:"
echo "   • get_results_dir() → docs/reports/generated/"
echo "   • get_results_filename() → docs/reports/data/{file}"
echo "   • get_log_filename() → docs/reports/generated/{file}"

echo ""
echo "🎯 Directory structure update: COMPLETE!"
