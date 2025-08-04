#!/bin/bash
# Comprehensive script cleanup for xanadOS

echo "=== Comprehensive Script Cleanup ==="

# Phase 1: Move problematic scripts to archive
echo "1. Moving broken scripts to archive for manual review..."
mkdir -p archive/broken-scripts-$(date +%Y%m%d)

# Move scripts with syntax errors to archive
if [[ -f "scripts/setup/gaming-workflow-optimization.sh" ]]; then
    echo "Moving gaming-workflow-optimization.sh to archive (syntax errors)"
    mv "scripts/setup/gaming-workflow-optimization.sh" "archive/broken-scripts-$(date +%Y%m%d)/"
fi

if [[ -f "scripts/setup/hardware-optimization.sh" ]]; then
    echo "Moving hardware-optimization.sh to archive (syntax errors)"
    mv "scripts/setup/hardware-optimization.sh" "archive/broken-scripts-$(date +%Y%m%d)/"
fi

# Phase 2: Remove dangerous eval usage (in archives only, leave active scripts for manual review)
echo "2. Documenting eval usage for security review..."
echo "Scripts requiring security review:" > security-review-required.txt
grep -l "eval.*\$" scripts/**/*.sh 2>/dev/null | grep -v archive >> security-review-required.txt || true

# Phase 3: Clean up duplicate archive files
echo "3. Removing obvious duplicate archive files..."
# Remove duplicates in archive that conflict with current scripts
declare -a archive_duplicates=(
    "archive/backups/logging-migration-20250803/scripts/lib/common.sh"
    "archive/backups/logging-migration-20250803/scripts/lib/directories.sh" 
    "archive/backups/logging-migration-20250803/scripts/lib/gaming-env.sh"
    "archive/backups/logging-migration-20250803/scripts/lib/reports.sh"
    "archive/backups/logging-migration-20250803/scripts/lib/setup-common.sh"
    "archive/backups/logging-migration-20250803/scripts/lib/validation.sh"
)

for duplicate in "${archive_duplicates[@]}"; do
    if [[ -f "$duplicate" ]]; then
        echo "Removing archive duplicate: $duplicate"
        rm -f "$duplicate"
    fi
done

echo "4. Creating clean backup of current working libraries..."
mkdir -p archive/working-libraries-backup-$(date +%Y%m%d)
cp -r scripts/lib/ archive/working-libraries-backup-$(date +%Y%m%d)/

echo "5. Fixing remaining file permissions..."
# Ensure library files are NOT executable (correct behavior)
chmod -x scripts/lib/*.sh 2>/dev/null || true

echo "✅ Cleanup completed"
echo "📋 Next steps:"
echo "   - Review security-review-required.txt for eval usage"
echo "   - Check archive/broken-scripts-$(date +%Y%m%d)/ for manual fixes"
echo "   - Run validation again to verify improvements"
