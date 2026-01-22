#!/bin/bash
set -e

MODE=$1
IMAGE_NAME=nginx_builder:latest
DATE=$(date +%Y-%m-%d)
REPORT="build_report_${DATE}_${MODE}.txt"
RUN_NUMBER=$(ls build_report_*.txt 2>/dev/null | wc -l | awk '{print $1+1}')
REV_FILE="build/revision.txt"

mkdir -p build/artifacts build/install reports

if [[ -z "$MODE" ]]; then
    echo "Usage: $0 {release|debug|coverage}"
    exit 1
fi

# проверка наличия docker-образа

if docker image inspect $IMAGE_NAME >/dev/null 2>&1; then
    echo "Image: $IMAGE_NAME"
else
    echo "Image does not exist. Building..."
    docker build -t $IMAGE_NAME .
fi

# номер ревизии

if [[ -f "$REV_FILE" ]]; then
    REVISION=$(cat "$REV_FILE")
    REVISION=$((REVISION+1))
else
    REVISION=1
fi
echo "$REVISION" > "$REV_FILE"

# запись в файл истории

echo "Run: $RUN_NUMBER" > "$REPORT"
echo "Revision: $REVISION" >> "$REPORT"
echo "Build type: $MODE" >> "$REPORT"

# сборка контейнера

docker run --rm \
    -v "$(pwd)/src:/src" \
    -v "$(pwd)/build:/build" \
    -v "$(pwd)/reports:/reports" \
    -e MODE="$MODE" \
    -e REVISION="$REVISION" \
    $IMAGE_NAME \
    /usr/local/bin/build_env.sh

# сравнение покрытия

if [[ "$MODE" == "coverage" ]]; then
    CURRENT_COVERAGE=$(cat reports/coverage_current.txt)

    echo "Coverage: $CURRENT_COVERAGE" >> "$REPORT"

    if [[ -f coverage_history.txt ]]; then
        PREV_COVERAGE=$(cat coverage_history.txt)
    else
        PREV_COVERAGE=0
    fi

    echo "Previous coverage: $PREV_COVERAGE"
    echo "Current coverage: $CURRENT_COVERAGE"

    if (( $(echo "$CURRENT_COVERAGE < $PREV_COVERAGE" | bc -l) )); then
        echo "Current coverage decreased"
        exit 1
    else
        echo "Current coverage increased"
        echo "$CURRENT_COVERAGE" > coverage_history.txt
    fi
fi

echo "Build complited: $REPORT"

