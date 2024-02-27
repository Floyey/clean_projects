#!/bin/bash

BASE_PATH="/d/projects"
TEMP_FILE="/d/projects/bash/clean_projects/temp_projects.txt"

echo "Searching for projects with 'vendor', 'node_modules', '__pycache__'..."
DIRS=$(find "$BASE_PATH" -type d \( -name "vendor" -o -name "node_modules" -o -name "__pycache__" \) -print | grep -vE "/vendor/|/node_modules/|/__pycache__/" | sed 's|/[^/]*$||' | sort | uniq)

echo "Searching for projects with '.pyc' files..."
PYC=$(find "$BASE_PATH" -type f -name "*.pyc" -print | grep -vE "/vendor/|/node_modules/|/__pycache__/" | sed 's|/[^/]*$||' | sort | uniq)

PROJECTS=$(echo "$DIRS\n$PYC" | sort | uniq)

PROJECTS_FILTERS=$(echo "$PROJECTS" | awk -F'/' '{OFS="/"; $NF=""; print $0}' | sort | uniq)

echo "$PROJECTS_FILTERS" > "$TEMP_FILE"

if [[ -z "$PROJECTS_FILTERS" ]]; then
    TOTAL=0
else
    TOTAL=$(echo "$PROJECTS_FILTERS" | wc -l | tr -d ' ')
    ((TOTAL--))
fi
CURRENT=0

echo "Total projects to check: $TOTAL"

exec 3< "$TEMP_FILE"

while IFS= read -r PROJECT_PATH <&3; do
    if [[ -z "$PROJECT_PATH" ]]; then
        continue
    fi

    ((CURRENT++))
    PROJECT_NAME=$(basename "$PROJECT_PATH")

    echo "[$CURRENT/$TOTAL] Checking $PROJECT_NAME"

    read -p "Do you want to clean the project $PROJECT_PATH? [y/N] " response
    if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo "Cleaning $PROJECT_NAME..."
        find "$PROJECT_PATH" \( -name "vendor" -o -name "node_modules" -o -name "__pycache__" \) -exec rm -rf {} +
        find "$PROJECT_PATH" -type f -name "*.pyc" -delete
    fi

    PERCENTAGE=$((CURRENT * 100 / TOTAL))
    echo "Progress: $PERCENTAGE%"
    if [[ "$PERCENTAGE" != 100 ]]; then
        echo ""
    fi
done
echo "-------------------------------------------------"

exec 3<&-

rm "$TEMP_FILE"

echo "Cleaning completed."

echo "Press any key to exit..."
read -n 1 -s -r -p ""
