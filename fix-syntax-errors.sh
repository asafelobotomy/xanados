#!/bin/bash
# Fix syntax errors in problematic scripts

echo "Fixing gaming-workflow-optimization.sh..."
# Remove the extra closing brace around line 149
sed -i '149d' scripts/setup/gaming-workflow-optimization.sh

echo "Checking hardware-optimization.sh for unmatched braces..."
# This requires manual inspection, marking for review
echo "scripts/setup/hardware-optimization.sh needs manual review for missing closing brace"

echo "Syntax fixes applied"
