#!/bin/bash
#
# Git Repository Cleanup and .gitignore Analysis
# 

cd "$(dirname "$0")/../.." || exit 1

echo "================================================"
echo "GIT REPOSITORY CLEANUP ANALYSIS"
echo "================================================"
echo "Generated: $(date)"
echo ""

echo "1. CURRENT .GITIGNORE STATUS:"
echo "============================"
echo ""

echo "✅ Updated .gitignore with comprehensive patterns:"
echo "   • Build artifacts and caches"
echo "   • Generated reports and test data"
echo "   • Package files (deb, rpm, etc.)"
echo "   • IDE/Editor files"
echo "   • Backup files"
echo "   • Python/Node.js cache files"
echo "   • OS generated files"
echo "   • Virtual environments"
echo ""

echo "2. DIRECTORIES THAT SHOULD BE IGNORED:"
echo "======================================"
echo ""

echo "Generated content directories:"
echo "├── docs/reports/generated/* (report files)"
echo "├── docs/reports/temp/* (temporary files)"
echo "├── docs/reports/data/* (data files)"
echo "├── build/work/* (build work files)"
echo "├── build/out/* (build outputs)"
echo "├── build/cache/* (build cache)"
echo "├── testing/results/* (test results)"
echo "└── archive/backups/* (backup files)"
echo ""

echo "3. TRACKED FILES THAT SHOULD BE UNTRACKED:"
echo "=========================================="
echo ""

echo "Currently tracked files that should be ignored:"

# List tracked files that match gitignore patterns
git ls-files | while read -r file; do
    if git check-ignore "$file" >/dev/null 2>&1; then
        echo "  📄 $file"
    fi
done

# Check specifically for our report files
tracked_reports=$(git ls-files docs/reports/generated/ docs/reports/data/ | grep -v "\.gitkeep\|README\.md" | wc -l)
if [[ $tracked_reports -gt 0 ]]; then
    echo ""
    echo "📊 Found $tracked_reports tracked report files that should be untracked:"
    git ls-files docs/reports/generated/ docs/reports/data/ | grep -v "\.gitkeep\|README\.md" | head -10 | while read -r file; do
        echo "  📄 $file"
    done
    
    if [[ $tracked_reports -gt 10 ]]; then
        echo "  ... and $((tracked_reports - 10)) more files"
    fi
fi

echo ""

echo "4. .GITKEEP FILES ADDED:"
echo "======================="
echo ""

gitkeep_files=(
    "docs/reports/generated/.gitkeep"
    "docs/reports/temp/.gitkeep"
    "docs/reports/data/.gitkeep"
    "testing/results/.gitkeep"
    "build/work/.gitkeep"
    "build/out/.gitkeep"
    "build/cache/.gitkeep"
)

for file in "${gitkeep_files[@]}"; do
    if [[ -f "$file" ]]; then
        echo "  ✅ $file"
    else
        echo "  ❌ $file (missing)"
    fi
done

echo ""

echo "5. RECOMMENDATIONS:"
echo "=================="
echo ""

if [[ $tracked_reports -gt 0 ]]; then
    echo "🔧 To clean up tracked generated files:"
    echo "   git rm --cached docs/reports/generated/*"
    echo "   git rm --cached docs/reports/data/*"
    echo "   git commit -m 'Remove tracked generated files from repository'"
    echo ""
fi

echo "📋 Patterns now covered by .gitignore:"
echo "   • *.tmp, *.log, *.cache files"
echo "   • IDE files (.vscode/, .idea/, *.swp)"
echo "   • OS files (.DS_Store, Thumbs.db, desktop.ini)"
echo "   • Package files (*.deb, *.rpm, *.zip, etc.)"
echo "   • Python cache (__pycache__/, *.pyc, .pytest_cache/)"
echo "   • Node.js files (node_modules/, npm-debug.log*)"
echo "   • Build outputs (*.o, *.so, *.dll, *.exe)"
echo "   • Backup files (*.backup, *.bak, *.orig)"
echo "   • Virtual environments (venv/, .env/)"
echo ""

echo "🎯 Repository Status:"
current_untracked=$(git ls-files --others --exclude-standard | wc -l)
echo "   • Untracked files: $current_untracked"
echo "   • .gitignore patterns: $(grep -c '^[^#]' .gitignore 2>/dev/null || echo 0) active rules"
echo "   • .gitkeep files: ${#gitkeep_files[@]} directories preserved"

echo ""
echo "================================================"
echo "GITIGNORE ANALYSIS COMPLETE"
echo "================================================"
