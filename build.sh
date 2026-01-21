#!/bin/bash
set -e

MODE=$1
IMAGE_NAME=nginx_builder:latest
DATE=$(date +%Y%m%d%H%M)
REPORT="build_report_${DATE}.txt"
RUN_NUMBER=$(ls build_report_*.txt 2>/dev/null | wc -l | awk '{print $1+1}')

mkdir -p artifacts reports

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

if [[ -f revision.txt ]]; then
    REVISION=$(cat revision.txt)
    REVISION=$((REVISION+1))
else
    REVISION=1
fi
echo "$REVISION" > revision.txt

# запись в файл истории

echo "Run: $RUN_NUMBER" > "$REPORT"
echo "Revision: $REVISION" >> "$REPORT"
echo "Build type: $MODE" >> "$REPORT"

# сборка контейнера

docker run --rm \
    -v "$(pwd)/artifacts:/src/artifacts" \
    -v "$(pwd)/reports:/src/reports" \
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

echo "Build complited."
echo "$REPORT"

