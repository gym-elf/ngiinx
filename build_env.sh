#!/usr/bin/env bash
set -e

BUILD_TYPE="${MODE:-release}"
REVISION="${REVISION:-1}"

cd /src

BUILD_DIR="/src/build"
ARTIFACTS_DIR="/src/artifacts"
REPORTS_DIR="/src/reports"

mkdir -p "$BUILD_DIR" "$ARTIFACTS_DIR" "$REPORTS_DIR"

CFLAGS=""
LDFLAGS=""

# флаги сборки

case "$BUILD_TYPE" in
    release)
        CFLAGS="-O2"
        ;;
    debug)
        CFLAGS="-O0 -g"
        ;;
    coverage)
        CFLAGS="-O0 -g --coverage"
        LDFLAGS="--coverage"
        ;;
    *)
        echo "Unknown flag: $BUILD_TYPE"
        exit 1
        ;;
esac

make clean || true

./configure \
    --with-cc-opt="$CFLAGS" \
    --with-ld-opt="$LDFLAGS"

# компиляция

make -j"$(nproc)"

# для release strip

if [[ "$BUILD_TYPE" == "release" ]]; then
    strip objs/nginx || true
fi

# установка во временную директорию

DESTDIR="$BUILD_DIR/install"
make install DESTDIR="$DESTDIR"

# создание пакета

PKG_NAME="nginx_${REVISION}_${BUILD_TYPE}.deb"

sudo checkinstall -y \
 --pkgname=nginx \
 --pkgversion="$REVISION" \
 --backup=no \
 --deldoc=yes \
 --fstrans=no \
 --default \
 --install=no \
 --pakdir="$ARTIFACTS_DIR" \
 make install DESTDIR="$DESTDIR"

echo "deb package complited: $ARTIFACTS_DIR/$PKG_NAME"

# покрытие

if [[ "$BUILD_TYPE" == "coverage" ]]; then
    ./objs/nginx -v || true

    lcov --capture --directory . --output-file coverage.info
    genhtml coverage.info --output-directory "$REPORTS_DIR/coverage_html"
    # процент строк

    COVERAGE=$(lcov --summary coverage.info | grep lines | awk '{print $2}' | tr -d '%')
    echo "$COVERAGE" > "$REPORTS_DIR/coverage_current.txt"
    echo "Coverage: $COVERAGE %"
fi

