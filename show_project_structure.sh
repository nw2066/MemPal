#!/bin/bash

# This script generates a project summary including directory structure
# (excluding specified directories like 'node_modules', 'dist') and the
# content of specified files or all files within specified directories,
# formatted in Markdown for clarity, especially when used as context
# for Large Language Models (LLMs).
#
# REQUIREMENTS:
# - 'tree' command is recommended for a clear directory structure visualization.
#   If 'tree' is not available, the script falls back to using 'find'.
#   Install 'tree':
#     Ubuntu/Debian: sudo apt install tree
#     macOS (Homebrew): brew install tree
#
# PARAMETERS:
# 1. [Optional] target_dir: The directory to scan for structure (defaults to '.').
# 2. [Optional] --include-dir <dir_path>: Specify a directory. All files
#    directly within this directory will have their contents included.
#    Can be used multiple times. Paths relative to the current working
#    directory or absolute paths are recommended.
# 3. [Optional] file_patterns: A list of glob patterns (e.g., "*.json", "README.md")
#    for files whose contents should be included (searched recursively from target_dir).
#    Quote patterns containing wildcards.
#    Defaults to "README.md" and "package.json" if *neither* file_patterns
#    *nor* --include-dir are provided.
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
#
# 5. Scan current directory, include all files directly under 'src/config':
#    ./show_project_structure.sh . --include-dir src/config
#
# 6. Scan 'my_proj' dir, include 'README.md' and all files in 'my_proj/scripts':
#    ./show_project_structure.sh my_proj README.md --include-dir my_proj/scripts
#
# 7. Scan current directory, include *.py files and all files in 'conf.d':
#    ./show_project_structure.sh . --include-dir conf.d "*.py"

# --- Configuration ---

# Output file name
OUTPUT_FILE="project_structure.txt"

# Directories to exclude from structure view and recursive file pattern search
# NOTE: --include-dir overrides these exclusions *for that specific directory*.
EXCLUDE_DIRS=("node_modules" "dist" ".git" "venv" "build" "__pycache__" ".vscode" ".idea")

# --- Argument Parsing ---

TARGET_DIR="." # Default Target Directory for structure scan
FILE_PATTERNS=() # Array for file patterns
INCLUDE_CONTENT_DIRS=() # Array for directories whose contents should be fully included
POS_ARGS=() # Temporary array for positional arguments

# Parse arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --include-dir)
        if [ -z "$2" ] || [[ "$2" == -* ]]; then
             echo "Error: --include-dir requires a directory path argument." >&2
             exit 1
        fi
        # Check if the include directory exists
        if [ ! -d "$2" ]; then
            echo "Warning: Directory specified with --include-dir not found: '$2'. Skipping." >&2
            # Optionally exit: exit 1
        else
             INCLUDE_CONTENT_DIRS+=("$2")
        fi
        shift # past argument
        shift # past value
        ;;
        -*) # Unknown option
        echo "Error: Unknown option '$1'" >&2
        exit 1
        ;;
        *) # Positional argument
        POS_ARGS+=("$1") # save it in array
        shift # past argument
        ;;
    esac
done

# Process positional arguments
# First positional argument is TARGET_DIR, the rest are FILE_PATTERNS
if [ ${#POS_ARGS[@]} -gt 0 ]; then
    TARGET_DIR="${POS_ARGS[0]}"
    FILE_PATTERNS=("${POS_ARGS[@]:1}") # Slice array from the second element
fi

# Check if the target directory exists
if [ ! -d "$TARGET_DIR" ]; then
    echo "Error: Target directory '$TARGET_DIR' not found." >&2
    exit 1
fi


# Apply default patterns ONLY if no patterns AND no include dirs were specified
if [ ${#FILE_PATTERNS[@]} -eq 0 ] && [ ${#INCLUDE_CONTENT_DIRS[@]} -eq 0 ]; then
    FILE_PATTERNS=("README.md" "package.json")
fi


# --- Helper Functions ---

# Function to build the exclusion arguments for 'find' and 'tree' (for structure)
build_exclusions() {
    local type="$1" # 'find' or 'tree'
    local args=()
    local pruned_paths=() # For find's pruning

    if [ "$type" == "find" ]; then
        for dir in "${EXCLUDE_DIRS[@]}"; do
            # Use -name for simple directory names, adjust if paths needed
            # Need -o between each condition for find
            if [ ${#pruned_paths[@]} -gt 0 ]; then
                pruned_paths+=(-o)
            fi
             # Prune the directory itself if found by name anywhere
             pruned_paths+=(-name "$dir" -type d -prune)
             # Also prune if path matches exactly (less common but safer)
             # pruned_paths+=(-o -path "*/${dir}" -prune) # Can be too broad
        done
        echo "${pruned_paths[@]}"
    elif [ "$type" == "tree" ]; then
        local pattern
        pattern=$(IFS="|"; echo "${EXCLUDE_DIRS[*]}")
        # Escape potential special characters in names for the pattern
        pattern=$(sed 's/[].[^$*]/\\&/g' <<< "$pattern")
        echo "-I ${pattern}"
    fi
}

# Function to print the directory structure
print_structure() {
    echo "## Directory Structure (`$TARGET_DIR`)"
    echo ""
    echo '```'
    cd "$TARGET_DIR" || { echo "[Error: Could not change to target directory '$TARGET_DIR']"; echo '```'; echo ""; return 1; }
    if command -v tree &>/dev/null; then
        local tree_excludes
        tree_excludes=$(build_exclusions "tree")
        # Use . for current dir now that we cd'd
        # shellcheck disable=SC2086 # We want word splitting for excludes
        if ! tree . $tree_excludes; then
             echo "[Warning: 'tree' command failed, possibly due to permissions or deep recursion. Falling back to 'find'.]"
             # Fallback within the code block - find from .
             local find_excludes
             find_excludes=($(build_exclusions "find"))
             # Start find from ., print relative paths, apply pruning
             find . ${find_excludes[@]} -o -print | sed -e '1d' -e 's%/[^/]*$%/..%' -e 's%^./%|--%' -e 's%/[^/]*%|--%g'
        fi
    else
        echo "[Info: 'tree' command not found. Using 'find' for basic structure (less visual clarity).]"
        local find_excludes
        find_excludes=($(build_exclusions "find"))
        # Start find from ., print relative paths, apply pruning
        find . ${find_excludes[@]} -o -print | sed -e '1d' -e 's%/[^/]*$%/..%' -e 's%^./%|--%' -e 's%/[^/]*%|--%g'
    fi
    cd - > /dev/null # Go back to original directory silently
    echo '```'
    echo "" # Add newline after the code block
}


# Function to print the content of specified files
print_file_contents() {
    echo "## Contents of Specified Files"
    if [ ${#FILE_PATTERNS[@]} -gt 0 ]; then
        echo "**Patterns:** \`${FILE_PATTERNS[*]}\` (searched from \`$TARGET_DIR\`)"
    fi
     if [ ${#INCLUDE_CONTENT_DIRS[@]} -gt 0 ]; then
        echo "**Included Directories:**"
        for inc_dir in "${INCLUDE_CONTENT_DIRS[@]}"; do
            echo "- \`$inc_dir\` (all files directly within)"
        done
    fi
    echo ""

    local all_found_files=()

    # 1. Find files based on patterns (recursive, respects EXCLUDE_DIRS)
    if [ ${#FILE_PATTERNS[@]} -gt 0 ]; then
        local find_pattern_args=("$TARGET_DIR")
        local find_excludes
        find_excludes=($(build_exclusions "find"))
        # Add exclusions using -prune
        find_pattern_args+=(${find_excludes[@]})
        # Add the file pattern matches
        find_pattern_args+=(-o \( -type f) # Start OR group for patterns
        local first_pattern=true
        for pattern in "${FILE_PATTERNS[@]}"; do
            if [ "$first_pattern" = true ]; then
                find_pattern_args+=(-name "$pattern")
                first_pattern=false
            else
                find_pattern_args+=(-o -name "$pattern")
            fi
        done
        find_pattern_args+=(\) -print) # Close the pattern group and specify print action

        # Find files matching patterns and add to list
        local pattern_files=()
        while IFS= read -r line; do
            pattern_files+=("$line")
        done < <(find "${find_pattern_args[@]}" 2>/dev/null)
        all_found_files+=("${pattern_files[@]}")
    fi

    # 2. Find files directly within --include-dir directories
    if [ ${#INCLUDE_CONTENT_DIRS[@]} -gt 0 ]; then
        local included_dir_files=()
        for inc_dir in "${INCLUDE_CONTENT_DIRS[@]}"; do
             # Find files *only* directly inside the specified directory
             # -maxdepth 1 ensures we don't go recursive here
             # -mindepth 1 ensures we don't list the directory itself
             while IFS= read -r line; do
                 # Check if the found file itself is in an EXCLUDE_DIRS pattern
                 # This is a basic check, might need refinement for complex paths
                 local filename
                 filename=$(basename "$line")
                 local excluded=false
#                 for ex_dir in "${EXCLUDE_DIRS[@]}"; do
#                      if [[ "$filename" == "$ex_dir" ]]; then # Don't list if file *name* matches excluded dir name
#                          excluded=true
#                          break
#                      fi
#                 done
                 # A simpler check might be needed if inc_dir is inside TARGET_DIR and contains excluded items
                 # For now, assume --include-dir implies wanting the contents regardless of EXCLUDE_DIRS

                 if [[ "$excluded" == "false" ]]; then
                    included_dir_files+=("$line")
                 fi
             done < <(find "$inc_dir" -maxdepth 1 -mindepth 1 -type f -print 2>/dev/null)
        done
        all_found_files+=("${included_dir_files[@]}")
    fi


    if [ ${#all_found_files[@]} -eq 0 ]; then
        echo "No files found matching the specified patterns or within the specified include directories."
        if [ ${#FILE_PATTERNS[@]} -gt 0 ]; then echo "Patterns searched: ${FILE_PATTERNS[*]}"; fi
        if [ ${#INCLUDE_CONTENT_DIRS[@]} -gt 0 ]; then echo "Included directories searched: ${INCLUDE_CONTENT_DIRS[*]}"; fi
        echo "Excluded directory patterns (for pattern search): ${EXCLUDE_DIRS[*]}"
        return
    fi

    # Sort and unique the combined list of files
    local unique_files=()
    # mapfile requires Bash 4+
    if command mapfile -h &>/dev/null ; then
         mapfile -t unique_files < <(printf "%s\n" "${all_found_files[@]}" | sort -u)
    else
        # Fallback for older Bash versions
        while IFS= read -r line; do
            unique_files+=("$line")
        done < <(printf "%s\n" "${all_found_files[@]}" | sort -u)
    fi


    if [ ${#unique_files[@]} -eq 0 ]; then
         echo "No unique files found after combining results." # Should not happen if all_found_files was > 0
         return
    fi

    for file in "${unique_files[@]}"; do
        # Attempt to determine language for markdown code block, fallback to text
        local lang=""
        case "$file" in
            *.js) lang="javascript" ;;
            *.jsx) lang="javascript" ;;
            *.ts) lang="typescript" ;;
            *.tsx) lang="typescript" ;;
            *.json) lang="json" ;;
            *.py) lang="python" ;;
            *.sh) lang="bash" ;;
            *.md) lang="markdown" ;;
            *.yaml|*.yml) lang="yaml" ;;
            *.xml) lang="xml" ;;
            *.html) lang="html" ;;
            *.css) lang="css" ;;
            *.java) lang="java" ;;
            *.kt) lang="kotlin" ;;
            *.go) lang="go" ;;
            *.rs) lang="rust" ;;
            *.c) lang="c" ;;
            *.cpp) lang="cpp" ;;
            *.h) lang="c" ;; # often C or C++
            *.hpp) lang="cpp" ;;
            *.rb) lang="ruby" ;;
            *.php) lang="php" ;;
            *.pl) lang="perl" ;;
            *.sql) lang="sql" ;;
            Dockerfile) lang="dockerfile" ;;
            Makefile) lang="makefile" ;;
            *) lang="text" ;; # Default fallback
        esac

        # Try to create a relative path for cleaner output
        local display_path="$file"
        # If file path starts with TARGET_DIR/, make relative to TARGET_DIR
        if [[ "$file" == "$TARGET_DIR/"* ]]; then
            display_path="${file#$TARGET_DIR/}"
        fi
        # Remove leading ./ if TARGET_DIR was '.'
        display_path="${display_path#./}"
        # Check if path is still absolute (e.g., --include-dir used an absolute path outside TARGET_DIR)
        # No change needed if absolute, just display it.


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

# Clear the output file
> "$OUTPUT_FILE"

# Write header information
{
    echo "# Project Summary"
    echo ""
    echo "**Generated:** $(date)"
    echo "**Structure Scanned From:** \`$TARGET_DIR\`"
    if [ ${#FILE_PATTERNS[@]} -gt 0 ]; then
      echo "**Included File Patterns:** \`${FILE_PATTERNS[*]}\`"
    fi
     if [ ${#INCLUDE_CONTENT_DIRS[@]} -gt 0 ]; then
      echo "**Included Directory Contents:**"
      for inc_dir in "${INCLUDE_CONTENT_DIRS[@]}"; do
          echo "  - \`$inc_dir\`"
      done
    fi
    echo "**Excluded Directory Patterns (for structure & pattern search):** \`${EXCLUDE_DIRS[*]}\`"
    echo ""

    # --- You can add your custom project overview here ---
    # Example using Method 2 from previous discussion (check for summary file):
    SUMMARY_FILE_REL="PROJECT_SUMMARY.md" # Relative name
    SUMMARY_FILE_ABS="$TARGET_DIR/$SUMMARY_FILE_REL"
    if [ -f "$SUMMARY_FILE_ABS" ]; then
        echo "## Project Overview (from $SUMMARY_FILE_REL)"
        echo ""
        cat "$SUMMARY_FILE_ABS"
        echo ""
    elif [ -f "$SUMMARY_FILE_REL" ]; then # Check relative to cwd too
        echo "## Project Overview (from $SUMMARY_FILE_REL)"
        echo ""
        cat "$SUMMARY_FILE_REL"
        echo ""
    else
        # Or add a default inline summary:
        echo "## Project Overview"
        echo ""
        echo "This is an electron project using local neo4j and d3.js for hypergraph visualisation."
        echo "It consists of prototypes of the basic functionality"
        echo ""
    fi
    # --- End custom overview section ---

    echo "---"
    echo ""

} >> "$OUTPUT_FILE"


# Append directory structure
print_structure >> "$OUTPUT_FILE"

# Append file contents
print_file_contents >> "$OUTPUT_FILE"

# --- Completion ---
# Check if output file actually contains more than just the header
# Adjusted threshold slightly due to potentially more header lines
if [ "$(wc -l < "$OUTPUT_FILE")" -gt 15 ]; then
    echo "Project summary written to $OUTPUT_FILE"
else
     # Check if any files were *supposed* to be found
    combined_check_args=()
    # Minimal check: just see if *any* file would be found by either method

    # 1. Check patterns
    if [ ${#FILE_PATTERNS[@]} -gt 0 ]; then
        find_check_pattern_args=("$TARGET_DIR")
        find_check_excludes=($(build_exclusions "find"))
        find_check_pattern_args+=(${find_check_excludes[@]})
        find_check_pattern_args+=(-o \( -type f)
        first_pattern=true
        for pattern in "${FILE_PATTERNS[@]}"; do
            if [ "$first_pattern" = true ]; then find_check_pattern_args+=(-name "$pattern"); first_pattern=false; else find_check_pattern_args+=(-o -name "$pattern"); fi
        done
        find_check_pattern_args+=(\) -print -quit)
        combined_check_args+=("${find_check_pattern_args[@]}")
    fi

     # 2. Check include dirs (just check if the first dir has any files)
     files_found_in_include_dir=false
     if [ ${#INCLUDE_CONTENT_DIRS[@]} -gt 0 ]; then
         for inc_dir in "${INCLUDE_CONTENT_DIRS[@]}"; do
            if find "$inc_dir" -maxdepth 1 -mindepth 1 -type f -print -quit 2>/dev/null | read -r; then
                files_found_in_include_dir=true
                break
            fi
         done
     fi

     # If either pattern find OR include dir find would yield results...
     if { [ ${#combined_check_args[@]} -gt 0 ] && find "${combined_check_args[@]}" 2>/dev/null | read -r; } || \
        [[ "$files_found_in_include_dir" == "true" ]]; then
         echo "Output written to $OUTPUT_FILE, but it seems minimal. Check for errors during execution (like file read permissions) or if files were empty."
    else
        echo "No matching files found via patterns or include directories, or only directory structure was generated. Output written to $OUTPUT_FILE."
        echo "Verify patterns, --include-dir paths, target directory, and exclusions."
    fi
fi

exit 0