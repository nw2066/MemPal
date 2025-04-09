#!/bin/bash

# This script generates a project summary including directory structure
# (excluding specified directories like 'node_modules', 'dist') and the
# content of specified files, formatted in Markdown for clarity,
# especially when used as context for Large Language Models (LLMs).
#
# REQUIREMENTS:
# - 'tree' command is recommended for a clear directory structure visualization.
#   If 'tree' is not available, the script falls back to using 'find'.
#   Install 'tree':
#     Ubuntu/Debian: sudo apt install tree
#     macOS (Homebrew): brew install tree
#
# PARAMETERS:
# 1. [Optional] target_dir: The directory to scan (defaults to current directory '.').
# 2. [Optional] file_patterns: A list of glob patterns (e.g., "*.json", "README.md")
#    for files whose contents should be included. Quote patterns containing wildcards.
#    Defaults to "README.md" and "package.json" if none are provided.
#
# EXAMPLES:
# 1. Scan current directory, include default files (README.md, package.json):
#    ./show_project_structure.sh
#
# 2. Scan specific directory, include default files:
#    ./show_project_structure.sh /path/to/project
#
# 3. Scan specific directory with custom file patterns:
#    ./show_project_structure.sh /path/to/project "*.json" "*.md" "Dockerfile"
#
# 4. Scan current directory with custom file patterns:
#    ./show_project_structure.sh . "*.config.js" "LICENSE"

# --- Configuration ---

# Output file name
OUTPUT_FILE="project_structure.txt"

# Directories to exclude from both structure and file content search
# Add more patterns here if needed (e.g., 'venv', '.git', 'build')
EXCLUDE_DIRS=("node_modules" "dist" ".git" "venv" "build" "__pycache__")

# --- Argument Parsing ---

TARGET_DIR="${1:-.}"

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' not found." >&2
    exit 1
fi

# Shift the first argument (target_dir) if it was provided
if [ $# -gt 0 ]; then
    shift
fi

# Define patterns for files whose content should be included
# Use remaining arguments as patterns, or default if none provided
FILE_PATTERNS=("$@")
if [ ${#FILE_PATTERNS[@]} -eq 0 ]; then
    FILE_PATTERNS=("README.md" "package.json")
fi

# --- Helper Functions ---

# Function to build the exclusion arguments for 'find' and 'tree'
build_exclusions() {
    local type="$1" # 'find' or 'tree'
    local args=()
    if [ "$type" == "find" ]; then
        for dir in "${EXCLUDE_DIRS[@]}"; do
            # -o -path '*/<dir>' -prune
            args+=(-o -path "*/${dir}" -prune)
        done
        # Remove the first '-o'
        echo "${args[@]:1}"
    elif [ "$type" == "tree" ]; then
        local pattern
        pattern=$(IFS="|"; echo "${EXCLUDE_DIRS[*]}")
        echo "-I ${pattern}"
    fi
}

# Function to print the directory structure
print_structure() {
    echo "## Directory Structure"
    echo ""
    echo '```'
    if command -v tree &>/dev/null; then
        local tree_excludes
        tree_excludes=$(build_exclusions "tree")
        # shellcheck disable=SC2086 # We want word splitting for excludes
        if ! tree "$TARGET_DIR" $tree_excludes; then
             echo "[Warning: 'tree' command failed, possibly due to permissions or deep recursion. Falling back to 'find'.]"
             # Fallback within the code block
             find "$TARGET_DIR" \( $(build_exclusions "find") \) -o -print | sed -e '1d' -e 's%/[^/]*$%/..%' -e 's%/[^/]*%|--%g'
        fi
    else
        echo "[Info: 'tree' command not found. Using 'find' for basic structure (less visual clarity).]"
        # Use find with pruning for exclusions
        # The find command structure:
        # find <target> \( <exclusion_path1> -prune -o <exclusion_path2> -prune ... \) -o -print
        # This finds everything, *unless* it encounters an excluded path (then it prunes/doesn't descend),
        # OR it prints the path if it wasn't pruned.
        find "$TARGET_DIR" \( $(build_exclusions "find") \) -o -print | sed -e '1d' -e 's%/[^/]*$%/..%' -e 's%/[^/]*%|--%g'
    fi
    echo '```'
    echo "" # Add newline after the code block
}


# Function to print the content of specified files
print_file_contents() {
    echo "## Contents of Specified Files"
    echo ""

    local find_args=("$TARGET_DIR")
    # Add exclusions using -prune
    find_args+=(\( $(build_exclusions "find") \))
    # Add the file pattern matches
    find_args+=(-o \( -type f)
    local first_pattern=true
    for pattern in "${FILE_PATTERNS[@]}"; do
        if [ "$first_pattern" = true ]; then
            find_args+=(-name "$pattern")
            first_pattern=false
        else
            find_args+=(-o -name "$pattern")
        fi
    done
    find_args+=(\) -print) # Close the pattern group and specify print action

    # Use process substitution to avoid issues with subshells in 'while read' loops
    # Use 'mapfile' (bash 4+) or a temporary array for older bash
    local found_files=()
    while IFS= read -r line; do
        found_files+=("$line")
    done < <(find "${find_args[@]}" 2>/dev/null)


    if [ ${#found_files[@]} -eq 0 ]; then
        echo "No files found matching the specified patterns: ${FILE_PATTERNS[*]}"
        echo "Excluded directories: ${EXCLUDE_DIRS[*]}"
        return
    fi

    # Sort files for consistent output order
    IFS=$'\n' found_files=($(sort <<<"${found_files[*]}"))
    unset IFS

    for file in "${found_files[@]}"; do
        # Attempt to determine language for markdown code block, fallback to text
        local lang=""
        case "$file" in
            *.js) lang="javascript" ;;
            *.json) lang="json" ;;
            *.py) lang="python" ;;
            *.sh) lang="bash" ;;
            *.md) lang="markdown" ;;
            *.yaml|*.yml) lang="yaml" ;;
            *.xml) lang="xml" ;;
            *.html) lang="html" ;;
            *.css) lang="css" ;;
            Dockerfile) lang="dockerfile" ;;
            *) lang="text" ;; # Default fallback
        esac

        # Use relative path for cleaner output if possible
        local display_path="${file#./}" # Remove leading ./ if present
        # Check if file path starts with target dir, make relative if so
        if [[ "$display_path" == "$TARGET_DIR"* ]]; then
             display_path="${display_path#$TARGET_DIR/}"
             # Handle case where target_dir is '.' and file is in '.'
             display_path="${display_path#./}"
        fi


        echo "### File: \`$display_path\`"
        echo ""
        echo "\`\`\`$lang"
        # Use cat and handle potential read errors
        if ! cat "$file"; then
            echo "[Error: Could not read file '$file']"
        fi
        echo "\`\`\`"
        echo "" # Add newline after the code block
    done
}

# --- Main Execution ---

# Ensure pipefail is enabled if using pipelines where errors matter
# set -o pipefail # Uncomment if needed, but might mask specific file read errors if used broadly

# Clear the output file
> "$OUTPUT_FILE"

# Write header information
{
    echo "# Project Summary: $TARGET_DIR"
    echo ""
    echo "**Generated:** $(date)"
    echo "**Target Directory:** \`$TARGET_DIR\`"
    echo "**Included File Patterns:** \`${FILE_PATTERNS[*]}\`"
    echo "**Excluded Directories:** \`${EXCLUDE_DIRS[*]}\`"
    echo ""
    echo "## Project Overview" # Optional Section Title
    echo "

This project is for prototyping the basic functionality of a hypergraph visualisation app.
It uses a a local hosted neo4j database with d3.js in electron.

    "
    echo ""
    echo "---"
    echo ""


} >> "$OUTPUT_FILE"


# Append directory structure
print_structure >> "$OUTPUT_FILE"

# Append file contents
print_file_contents >> "$OUTPUT_FILE"

# --- Completion ---
# Check if output file actually contains more than the header
# Crude check: count lines > 10 (adjust if header becomes larger/smaller)
if [ "$(wc -l < "$OUTPUT_FILE")" -gt 10 ]; then
    echo "Project summary written to $OUTPUT_FILE"
else
     # If only header is present or minimal content, check if files were found
     # Re-run find minimally just to check existence without printing content
    find_check_args=("$TARGET_DIR")
    find_check_args+=(\( $(build_exclusions "find") \))
    find_check_args+=(-o \( -type f)
    first_pattern=true
    for pattern in "${FILE_PATTERNS[@]}"; do
        if [ "$first_pattern" = true ]; then
            find_check_args+=(-name "$pattern")
            first_pattern=false
        else
            find_check_args+=(-o -name "$pattern")
        fi
    done
    find_check_args+=(\) -print -quit) # Quit after finding the first match

    if find "${find_check_args[@]}" 2>/dev/null | read -r; then
         # Files matching patterns exist, but maybe tree failed AND cat failed?
         echo "Output written to $OUTPUT_FILE, but it seems minimal. Check for errors during execution or file permissions."
    else
        echo "No matching files found or only directory structure was generated. Output written to $OUTPUT_FILE."
        echo "Verify patterns, target directory, and exclusions."
         # Optionally remove the file if truly empty/useless
         # if [ ! -s "$OUTPUT_FILE" ]; then rm "$OUTPUT_FILE"; fi
    fi
fi

exit 0