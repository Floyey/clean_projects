#!/bin/bash

# Initialize variables
BASE_PATH=""
declare -a DIRS_TO_DELETE
declare -a FILES_TO_DELETE
RM_ALL=false
TEMP_FILE="clean_projects.tmp"

# ANSI color codes for colorful output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show usage
usage() {
    echo "Usage: $0 -b BASE_PATH [-d DIR_TO_DELETE]... [-f FILE_TO_DELETE]... -y"
    echo "  -b    Base path for projects (required)"
    echo "  -d    Directory to delete (optional, can be used multiple times)"
    echo "  -f    File pattern to delete (optional, can be used multiple times)"
    echo "  -y    Clean all projects automatically (optional)"
    echo "  -h, --help  Show this help message and exit"
    echo "Note: At least one of -d or -f must be provided unless in help mode."
    exit 1
}

# Extended getopt command to include long options
TEMP=`getopt -o b:d:f:yh --long help -- "$@"`
eval set -- "$TEMP"

# Parse command line options
while true; do
    case "$1" in
        -b )
            BASE_PATH=$2; shift 2
            ;;
        -d )
            DIRS_TO_DELETE+=("$2"); shift 2
            ;;
        -f )
            FILES_TO_DELETE+=("$2"); shift 2
            ;;
        -y )
            RM_ALL=true; shift
            ;;
        -h | --help )
            usage; exit 1
            ;;
        -- )
            shift; break
            ;;
        * )
            break
            ;;
    esac
done

# Check for missing arguments
if [ -z "$BASE_PATH" ] || { [ ${#DIRS_TO_DELETE[@]} -eq 0 ] && [ ${#FILES_TO_DELETE[@]} -eq 0 ]; }; then
    echo -e "${RED}Error: Missing required arguments. BASE_PATH is required and at least one of DIR_TO_DELETE or FILE_TO_DELETE.${NC}"
    usage
fi

# Display directories and files to be cleaned
echo -e "${YELLOW}Searching for directories and files to clean:${NC}"
for DIR in "${DIRS_TO_DELETE[@]}"; do
    echo -e "${GREEN}Directory: $DIR${NC}"
done
for FILE in "${FILES_TO_DELETE[@]}"; do
    echo -e "${GREEN}File: $FILE${NC}"
done

echo -e "${YELLOW}\nStarting project cleanup...${NC}\n"

# Generating exclude pattern for find command
EXCLUDE_PATTERN=$(printf "|/%s/" "${DIRS_TO_DELETE[@]}")
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:1}"

# Construct find command arguments for directories and files to delete
FIND_ARGS=""
for DIR in "${DIRS_TO_DELETE[@]}"; do
    FIND_ARGS+=" -type d -name $DIR -o"
done
for FILE in "${FILES_TO_DELETE[@]}"; do
    FIND_ARGS+=" -type f -name $FILE -o"
done
# Remove trailing '-o'
FIND_ARGS=${FIND_ARGS::-2}

# Collect projects to clean
while IFS= read -r line; do
    PROJECT_PATH=$(echo "$line" | grep -oE "^$BASE_PATH/[^/]+/[^/]+")
    PROJECTS+="$PROJECT_PATH\n"
done < <(find "$BASE_PATH" \( $FIND_ARGS \) | grep -vE "$EXCLUDE_PATTERN")
PROJECTS_FILTERED=$(echo -e "$PROJECTS" | sort | uniq | awk NF)

# Save filtered projects to a temporary file
echo "$PROJECTS_FILTERED" > "$TEMP_FILE"

# Determine the total number of projects to check
if [[ -z "$PROJECTS_FILTERED" ]]; then
    TOTAL=0
else
    TOTAL=$(echo "$PROJECTS_FILTERED" | wc -l | tr -d ' ')
fi

echo -e "${GREEN}Total projects to check: $TOTAL${NC}"

# Read from temporary file
exec 3< "$TEMP_FILE"

CURRENT=0
# Main loop to process each project
while IFS= read -r PROJECT_PATH <&3; do
    if [[ -z "$PROJECT_PATH" ]]; then
        continue
    fi
    BUG_CATCHED=false

    ((CURRENT++))
    PROJECT_NAME=$(basename "$PROJECT_PATH")

    # Display current project being processed
    echo -e "[${YELLOW}$CURRENT/$TOTAL${NC}] Checking ${GREEN}$PROJECT_NAME${NC}"

    if [[ $RM_ALL == "true" ]]; then
        # Cleaning each project automatically
        if ! find "$PROJECT_PATH" \( $FIND_ARGS \) -exec rm -rf {} + 2>/dev/null; then
            BUG_CATCHED=true
        fi
    else
        # Confirm before cleaning each project
        while true; do
            echo -ne "${YELLOW}Do you want to clean the project $PROJECT_PATH? [y/N] ${NC}"
            read response
            case $response in
                [yY][eE][sS]|[Yy]* )
                    # Attempt to delete specified directories and files
                    if ! find "$PROJECT_PATH" \( $FIND_ARGS \) -exec rm -rf {} + 2>/dev/null; then
                        BUG_CATCHED=true
                    fi
                    break;;
                [nN][oO]|[Nn]* | "" )
                    echo -e "${RED}Skipping $PROJECT_NAME${NC}"
                    break;;
                * )
                    echo -e "${RED}Please answer yes (y) or no (n).${NC}";;
            esac
        done
    fi

    if [[ $BUG_CATCHED == "true" ]]; then
        echo -e "${RED}Failed to clean $PROJECT_NAME. Check permissions or existence.${NC}"
        echo -e "${RED}\nError: Permission denied while deleting file $PROJECT_PATH${NC}\n"
    fi

    # Calculate and display progress
    PERCENTAGE=$((CURRENT * 100 / TOTAL))
    echo -e "${GREEN}Progress: $PERCENTAGE%${NC}"
    if [[ "$PERCENTAGE" != 100 ]]; then
        echo ""
    fi
done
echo "-------------------------------------------------"

# Clean up
exec 3<&-
rm "$TEMP_FILE"

# Final message
echo -e "${RED}Cleaning completed.${NC}"
echo -e "${YELLOW}Press any key to exit...${NC}"
read -n 1 -s -r -p ""
