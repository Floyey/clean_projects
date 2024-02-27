#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_PATH="/d/projects"
TEMP_FILE="/d/projects/bash/clean_projects/temp_projects.txt"

echo -e "${YELLOW}Searching for projects with 'vendor', 'node_modules', '__pycache__'...${NC}"
DIRS=$(find "$BASE_PATH" -type d \( -name "vendor" -o -name "node_modules" -o -name "__pycache__" \) -print | grep -vE "/vendor/|/node_modules/|/__pycache__/" | sed 's|/[^/]*$||' | sort | uniq)

echo -e "${YELLOW}Searching for projects with '.pyc' files...${NC}"
PYC=$(find "$BASE_PATH" -type f -name "*.pyc" -print | grep -vE "/vendor/|/node_modules/|/__pycache__/" | sed 's|/[^/]*$||' | sort | uniq)

PROJECTS=$(echo -e "$DIRS\n$PYC" | sort | uniq)

PROJECTS_FILTERS=$(echo "$PROJECTS" | awk -F'/' '{OFS="/"; $NF=""; print $0}' | sort | uniq)

echo "$PROJECTS_FILTERS" > "$TEMP_FILE"

if [[ -z "$PROJECTS_FILTERS" ]]; then
    TOTAL=0
else
    TOTAL=$(echo "$PROJECTS_FILTERS" | wc -l | tr -d ' ')
    ((TOTAL--))
fi
CURRENT=0

echo -e "${GREEN}Total projects to check: $TOTAL${NC}"

exec 3< "$TEMP_FILE"

while IFS= read -r PROJECT_PATH <&3; do
    if [[ -z "$PROJECT_PATH" ]]; then
        continue
    fi

    ((CURRENT++))
    PROJECT_NAME=$(basename "$PROJECT_PATH")

    echo -e "[${YELLOW}$CURRENT/$TOTAL${NC}] Checking ${GREEN}$PROJECT_NAME${NC}"

    read -p "Do you want to clean the project $PROJECT_PATH? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${RED}Cleaning $PROJECT_NAME...${NC}"
        find "$PROJECT_PATH" \( -name "vendor" -o -name "node_modules" -o -name "__pycache__" \) -exec rm -rf {} +
        find "$PROJECT_PATH" -type f -name "*.pyc" -delete
    fi

    PERCENTAGE=$((CURRENT * 100 / TOTAL))
    echo -e "${GREEN}Progress: $PERCENTAGE%${NC}"
    if [[ "$PERCENTAGE" != 100 ]]; then
        echo ""
    fi
done
echo "-------------------------------------------------"

exec 3<&-

rm "$TEMP_FILE"

echo -e "${RED}Cleaning completed.${NC}"

echo -e "${YELLOW}Press any key to exit...${NC}"
read -n 1 -s -r -p ""
