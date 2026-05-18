#!/bin/bash

# --- Configuration ---
START_DIR="$HOME"
KEYWORD=""
SEARCH_CASE_INSENSITIVE=true 
SEARCH_WHOLE_WORD=true      

# --- Help and Usage ---
display_help() {
    echo "Usage: $0 [directory_to_scan] [options]"
    echo "Scans .txt, .odt, .doc, and .docx files for a specific term using Extended Grep."
    echo ""
    echo "Options:"
    echo "  -h, --help       Display this help message."
    echo "  -k, --keyword    Specify keyword (skips the interactive prompt)."
    echo "  -c, --case       Perform case-sensitive search."
    echo "  -p, --partial    Allow partial word matches."
    echo ""
    echo "Example: $0 ~/Documents"
    exit 0
}

# --- Process Command Line Arguments ---
while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) display_help ;;
        -k|--keyword)
            if [ -n "$2" ]; then
                KEYWORD="$2"
                shift 
            else
                echo "Error: --keyword requires an argument." >&2
                exit 1
            fi
            ;;
        -c|--case) SEARCH_CASE_INSENSITIVE=false ;;
        -p|--partial) SEARCH_WHOLE_WORD=false ;;
        *)
            if [ -d "$1" ]; then
                START_DIR="$1"
            else
                echo "Error: Unknown option or invalid directory '$1'." >&2
                exit 1
            fi
            ;;
    esac
    shift 
done

# --- Interactive Keyword Prompt ---
if [ -z "$KEYWORD" ]; then
    echo -n "🔍 Enter the term you want to search for: "
    read KEYWORD
    if [ -z "$KEYWORD" ]; then
        echo "Error: No search term entered. Exiting."
        exit 1
    fi
fi

# --- Pre-requisite Checks ---
for cmd in find unzip grep antiword; do
    if ! command -v $cmd &> /dev/null; then
        echo "Error: '$cmd' command not found." >&2
        exit 1
    fi
done

# --- Construct Grep Options ---
GREP_OPTIONS="-E" # Upgraded to Extended Regular Expressions
if [ "$SEARCH_CASE_INSENSITIVE" = true ]; then
    GREP_OPTIONS+="i"
fi
if [ "$SEARCH_WHOLE_WORD" = true ]; then
    GREP_OPTIONS+="w"
fi
SEARCH_TERM="$KEYWORD"

echo "---------------------------------------------------"
echo "🔍 Searching for: '$KEYWORD'"
echo "📂 Scanning within: '$START_DIR'"
echo "⚙️  Mode: Grep Extended (-E)"
echo "---------------------------------------------------"

# --- Unified Search Logic ---
MATCHING_FILES_OUTPUT=$(
    find "$START_DIR" -type f \( -iname "*.odt" -o -iname "*.doc" -o -iname "*.docx" -o -iname "*.txt" \) -print0 2>/dev/null | while IFS= read -r -d $'\0' doc_file; do
        MATCH=false
        LOWER_EXT="${doc_file##*.}"
        LOWER_EXT="${LOWER_EXT,,}"

        case "$LOWER_EXT" in
            txt)
                if grep $GREP_OPTIONS "$SEARCH_TERM" "$doc_file" &> /dev/null; then
                    MATCH=true
                fi
                ;;
            odt)
                if unzip -p "$doc_file" content.xml 2>/dev/null | grep $GREP_OPTIONS "$SEARCH_TERM" &> /dev/null; then
                    MATCH=true
                fi
                ;;
            doc)
                if antiword "$doc_file" 2>/dev/null | grep $GREP_OPTIONS "$SEARCH_TERM" &> /dev/null; then
                    MATCH=true
                fi
                ;;
            docx)
                if unzip -p "$doc_file" word/document.xml 2>/dev/null | grep $GREP_OPTIONS "$SEARCH_TERM" &> /dev/null; then
                    MATCH=true
                fi
                ;;
        esac

        if [ "$MATCH" = true ]; then
            echo "MATCH: $doc_file"
        fi
    done
)

# --- Summary and Output ---
if [ -n "$MATCHING_FILES_OUTPUT" ]; then
    echo -e "$MATCHING_FILES_OUTPUT" | sed 's/MATCH: //'
    FOUND_COUNT=$(echo -e "$MATCHING_FILES_OUTPUT" | grep -c "MATCH:")
else
    FOUND_COUNT=0
fi

echo "---------------------------------------------------"
echo "Search complete. Found '$KEYWORD' in $FOUND_COUNT file(s)."

