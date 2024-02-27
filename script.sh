#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BASE_PATH="/d/projects"
TECH_DIRS=("bash" "docker" "html" "node" "php" "python")

DIRS_TO_DELETE=("vendor" "node_modules" "__pycache__")
FILES_TO_DELETE=("*.pyc")

TEMP_FILE="temp_projects.txt"

echo -e "${YELLOW}Searching for directories and files to clean:${NC}"
for DIR in "${DIRS_TO_DELETE[@]}"; do
    echo -e "${GREEN}Directory: $DIR${NC}"
done
for FILE in "${FILES_TO_DELETE[@]}"; do
    echo -e "${GREEN}File: $FILE${NC}"
done
echo -e "${YELLOW}\nStarting project cleanup...${NC}\n"

EXCLUDE_PATTERN=$(printf "|/%s/" "${DIRS_TO_DELETE[@]}")
EXCLUDE_PATTERN="${EXCLUDE_PATTERN:1}"

FIND_ARGS=""
for DIR in "${DIRS_TO_DELETE[@]}"; do
    FIND_ARGS+=" -type d -name $DIR -o"
done
for FILE in "${FILES_TO_DELETE[@]}"; do
    FIND_ARGS+=" -type f -name $FILE -o"
done
FIND_ARGS=${FIND_ARGS::-2}

PROJECTS=""
for TECH_DIR in "${TECH_DIRS[@]}"; do
    while IFS= read -r line; do
        PROJECT_PATH=$(echo "$line" | grep -oE "^$BASE_PATH/[^/]+/[^/]+")
        PROJECTS+="$PROJECT_PATH\n"
    done < <(find "$BASE_PATH/$TECH_DIR" \( $FIND_ARGS \) | grep -vE "$EXCLUDE_PATTERN")
done
PROJECTS_FILTERS=$(echo -e "$PROJECTS" | sort | uniq | awk NF)

echo "$PROJECTS_FILTERS" > "$TEMP_FILE"

if [[ -z "$PROJECTS_FILTERS" ]]; then
    TOTAL=0
else
    TOTAL=$(echo "$PROJECTS_FILTERS" | wc -l | tr -d ' ')
fi

echo -e "${GREEN}Total projects to check: $TOTAL${NC}"

exec 3< "$TEMP_FILE"

CURRENT=0
while IFS= read -r PROJECT_PATH <&3; do
    if [[ -z "$PROJECT_PATH" ]]; then
        continue
    fi

    ((CURRENT++))
    PROJECT_NAME=$(basename "$PROJECT_PATH")

    echo -e "[${YELLOW}$CURRENT/$TOTAL${NC}] Checking ${GREEN}$PROJECT_NAME${NC}"

    while true; do
        echo -ne "${YELLOW}Do you want to clean the project $PROJECT_PATH? [y/N] ${NC}"
        read response
        case $response in
            [yY][eE][sS]|[Yy]* )
                if ! find "$PROJECT_PATH" \( $FIND_ARGS \) -delete 2>/dev/null; then
                    echo -e "${RED}Failed to clean $PROJECT_NAME. Check permissions or existence.${NC}"
                fi
                break;;
            [nN][oO]|[Nn]* | "" )
                echo -e "${RED}Skipping $PROJECT_NAME${NC}"
                break;;
            * )
                echo -e "${RED}Please answer yes (y) or no (n).${NC}";;
        esac
    done

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
