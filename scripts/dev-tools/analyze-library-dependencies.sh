#!/bin/bash
#
# Library Dependency Map and Analysis
# Creates a detailed map of library dependencies and references
#

cd "$(dirname "$0")/../.." || exit 1

echo "================================================"
echo "LIBRARY DEPENDENCY ANALYSIS"
echo "================================================"
echo ""

# Function to extract actual dependencies
get_dependencies() {
    local lib="$1"
    echo "📁 $(basename "$lib")"
    echo "   Path: $lib"
    
    if [[ ! -f "$lib" ]]; then
        echo "   ❌ File not found"
        return 1
    fi
    
    # Get source statements
    local sources
    sources=$(grep '^[[:space:]]*source[[:space:]]' "$lib" 2>/dev/null | grep -v '^[[:space:]]*#')
    
    if [[ -n "$sources" ]]; then
        echo "   Dependencies:"
        echo "$sources" | while IFS= read -r line; do
            echo "     → $line"
        done
        
        # Check dependency paths
        echo "   Dependency validation:"
        local script_dir
        script_dir="$(dirname "$lib")"
        
        # Extract and validate each dependency
        echo "$sources" | grep -o '"[^"]*"' | tr -d '"' | while IFS= read -r dep_path; do
            # Handle $(dirname "${BASH_SOURCE[0]}") pattern
            if [[ "$dep_path" =~ ^\$\(dirname.*\)/.* ]]; then
                # Extract the filename after the dirname expansion
                local filename
                filename=$(echo "$dep_path" | sed 's|.*)/||')
                local full_path="$script_dir/$filename"
                
                if [[ -f "$full_path" ]]; then
                    echo "     ✅ $filename (resolves to: $full_path)"
                else
                    echo "     ❌ $filename (would resolve to: $full_path)"
                fi
            else
                # Direct path
                if [[ -f "$dep_path" ]]; then
                    echo "     ✅ $dep_path"
                else
                    echo "     ❌ $dep_path (not found)"
                fi
            fi
        done
    else
        echo "   ℹ️  No dependencies"
    fi
    
    # Check functions exported
    echo "   Exported functions:"
    local functions
    functions=$(grep '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*()[[:space:]]*{' "$lib" | sed 's/()[[:space:]]*{.*/()/' | head -10)
    if [[ -n "$functions" ]]; then
        echo "$functions" | while IFS= read -r func; do
            echo "     🔧 $func"
        done
    else
        echo "     ℹ️  No functions found"
    fi
    
    echo ""
}

# Analyze each library
echo "1. Individual Library Analysis:"
echo "==============================="
echo ""

LIBRARIES=(
    "scripts/lib/common.sh"
    "scripts/lib/directories.sh"
    "scripts/lib/gaming-env.sh"
    "scripts/lib/logging.sh"
    "scripts/lib/reports.sh"
    "scripts/lib/validation.sh"
)

for lib in "${LIBRARIES[@]}"; do
    get_dependencies "$lib"
done

# Create dependency graph
echo "2. Dependency Graph:"
echo "==================="
echo ""
echo "Dependency relationships:"
echo ""

for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        lib_name=$(basename "$lib" .sh)
        deps=$(grep '^[[:space:]]*source[[:space:]]' "$lib" 2>/dev/null | grep -o '/[^/]*\.sh' | sed 's|/||' | sed 's|\.sh||' | tr '\n' ' ')
        
        if [[ -n "$deps" ]]; then
            echo "$lib_name depends on: $deps"
        else
            echo "$lib_name: no dependencies"
        fi
    fi
done

echo ""

# Check for issues
echo "3. Potential Issues Analysis:"
echo "============================="
echo ""

# Check for circular dependencies
echo "Circular dependency check:"
found_circular=false

for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        lib_name=$(basename "$lib" .sh)
        
        # Get dependencies of this library
        deps=$(grep '^[[:space:]]*source[[:space:]]' "$lib" 2>/dev/null | grep -o '/[^/]*\.sh' | sed 's|/||' | sed 's|\.sh||')
        
        # Check if any dependency also depends on this library
        for dep in $deps; do
            dep_file="scripts/lib/${dep}.sh"
            if [[ -f "$dep_file" ]]; then
                if grep -q "${lib_name}.sh" "$dep_file" 2>/dev/null; then
                    echo "  ⚠️  Circular: $lib_name ↔ $dep"
                    found_circular=true
                fi
            fi
        done
    fi
done

if [[ "$found_circular" == "false" ]]; then
    echo "  ✅ No circular dependencies found"
fi

echo ""

# Check load order
echo "Recommended load order:"
echo "1. common.sh (no dependencies)"
echo "2. directories.sh (depends on common.sh)"
echo "3. logging.sh (depends on common.sh)"
echo "4. validation.sh (depends on common.sh)"
echo "5. gaming-env.sh (depends on common.sh, validation.sh)"
echo "6. reports.sh (depends on common.sh, directories.sh)"

echo ""

# Function overlap check
echo "4. Function Overlap Analysis:"
echo "============================="
echo ""

# Get all function names from all libraries
temp_file=$(mktemp)
for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        lib_name=$(basename "$lib" .sh)
        grep '^[[:space:]]*[a-zA-Z_][a-zA-Z0-9_]*()[[:space:]]*{' "$lib" | sed 's/()[[:space:]]*{.*//' | sed 's/^[[:space:]]*//' | while read -r func; do
            echo "$func:$lib_name" >> "$temp_file"
        done
    fi
done

# Check for duplicate function names
duplicates=$(sort "$temp_file" | cut -d: -f1 | uniq -d)
if [[ -n "$duplicates" ]]; then
    echo "Functions defined in multiple libraries:"
    for func in $duplicates; do
        echo "  🔄 $func defined in:"
        grep "^$func:" "$temp_file" | cut -d: -f2 | while read -r lib; do
            echo "    - $lib.sh"
        done
    done
else
    echo "✅ No function name conflicts found"
fi

rm -f "$temp_file"

echo ""
echo "5. External Dependencies:"
echo "========================"
echo ""

# Check for external command dependencies
echo "External commands used in libraries:"
for lib in "${LIBRARIES[@]}"; do
    if [[ -f "$lib" ]]; then
        lib_name=$(basename "$lib" .sh)
        
        # Look for common external commands
        external_cmds=$(grep -oE '\b(curl|wget|git|docker|systemctl|service|apt|yum|dnf|pacman|grep|sed|awk|find|xargs|hostname|whoami|id|uname)\b' "$lib" 2>/dev/null | sort -u | tr '\n' ' ')
        
        if [[ -n "$external_cmds" ]]; then
            echo "  📦 $lib_name: $external_cmds"
        fi
    fi
done

echo ""
echo "================================================"
echo "ANALYSIS COMPLETE"
echo "================================================"
