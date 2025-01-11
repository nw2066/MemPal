#!/bin/bash


# This script generates a directory structure (excluding 'node_modules' and 'dist' directories)
# and extracts the content of specified files into an output file named 'project_structure.txt'.
#
# REQUIREMENTS:
# - The 'tree' command should be installed for directory structure generation.
#   If 'tree' is not available, the script will fallback to using 'find' to list directories.
#   To install 'tree' on Ubuntu/Debian: sudo apt install tree
#   On macOS (via Homebrew): brew install tree
#
# PARAMETERS:
# 1. [Optional] The target directory to scan (defaults to the current directory if not provided).
# 2. [Optional] A list of file patterns (e.g., "*.json", "README.md") whose contents should be included in the output.
#    - If no file patterns are provided, it defaults to "README.md" and "package.json".
#
# EXAMPLES:
# 1. To scan the current directory and include default file patterns:
#    ./show_project_structure.sh
#
# 2. To scan a specific directory with custom file patterns:
#    ./show_project_structure.sh /path/to/project "*.json" "*.md"
#
# 3. To scan the current directory with custom file patterns:
#    ./show_project_structure.sh . "*.config.js"
# Define the directory to scan (current directory by default)

TARGET_DIR="${1:-.}"

# Shift the first argument to allow remaining arguments to be file patterns
shift

# Define patterns for files whose content should be included (default to README.md and package.json if none provided)
FILE_PATTERNS=("$@")
if [ ${#FILE_PATTERNS[@]} -eq 0 ]; then
    FILE_PATTERNS=("README.md" "package.json")
fi

# Define the output file
OUTPUT_FILE="project_structure.txt"

# Clear the output file if it exists
> "$OUTPUT_FILE"

# Append directory structure to the file
echo "Directory Structure:" >> "$OUTPUT_FILE"
if command -v tree &>/dev/null; then
    tree "$TARGET_DIR" -I 'node_modules|dist' >> "$OUTPUT_FILE" 2>/dev/null
else
    echo "'tree' command not found. Using 'find' as a fallback." >> "$OUTPUT_FILE"
    find "$TARGET_DIR" -print | sed -e "s|[^/]*/|  |g" -e "s|/| |g" >> "$OUTPUT_FILE"
fi

echo "" >> "$OUTPUT_FILE"

# Find and append content of matching files to the output file
echo "Contents of Specified Files:" >> "$OUTPUT_FILE"
for pattern in "${FILE_PATTERNS[@]}"; do
    # Find files matching the pattern, excluding node_modules and dist
    find "$TARGET_DIR" -type f -name "$pattern" ! -path "*/node_modules/*" ! -path "*/dist/*" 2>/dev/null | while read -r file; do
        echo "File: $file" >> "$OUTPUT_FILE"
        echo "---------------------------" >> "$OUTPUT_FILE"
        cat "$file" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    done
done

# Notify the user of the output file location
if [ -s "$OUTPUT_FILE" ]; then
    echo "Output written to $OUTPUT_FILE"
else
    echo "No output was generated. Verify directory contents and exclusions."
fi