#!/bin/bash
# build_version.sh — Multi-version build dispatcher
# Usage: bash scripts/build_version.sh [v1.2|v1.6|fp64|all] [-j N]
set -euo pipefail
cd "$(dirname "$0")/.."

JOBS=$(nproc 2>/dev/null || echo 4)
VERSION="${1:-all}"

# Shift version arg, parse -j
if [[ "$VERSION" != "all" ]]; then shift; fi
while [[ $# -gt 0 ]]; do
  case "$1" in -j) JOBS="$2"; shift 2 ;; *) echo "Unknown: $1"; exit 1 ;; esac
done

NGSPICE_DIR="ngspice-46"
BIN_DIR="bin"
mkdir -p "$BIN_DIR"

build_one() {
    local ver="$1"         # v1.2 | v1.6 | fp64
    local patch_dir="$2"   # patches/v1.2 | patches/pure_fp32 | ""
    local extra_conf="$3"  # --enable-single-precision | ""
    local build_dir="build/${ver}"

    echo "=== Building $ver → $build_dir ==="
    rm -rf "$build_dir"
    cp -r "$NGSPICE_DIR" "$build_dir"

    # Apply patches
    if [ -n "$patch_dir" ] && [ -d "$patch_dir" ]; then
        for p in "$patch_dir"/*.patch; do
            echo "  patch: $(basename $p)"
            patch -d "$build_dir" -p1 < "$p" || { echo "FAILED: $p"; exit 1; }
        done
    fi

    cd "$build_dir"
    ./configure $extra_conf --disable-xspice --disable-osdi --disable-cider \
        CFLAGS="-O2 -fopenmp -Wno-conversion" 2>&1 | tail -1
    make -j"$JOBS" 2>&1 | tail -1
    cd ..

    # Symlink
    ln -sf "../$build_dir/src/ngspice" "$BIN_DIR/ngspice-$ver"
    echo "  Binary: $BIN_DIR/ngspice-$ver"
}

case "$VERSION" in
    all)
        build_one "fp64" "patches" ""
        build_one "v1.2" "patches" "--enable-single-precision"
        build_one "v1.6" "patches/pure_fp32" "--enable-single-precision"
        ;;
    fp64)
        build_one "fp64" "patches" ""
        ;;
    v1.2)
        build_one "v1.2" "patches" "--enable-single-precision"
        ;;
    v1.6)
        build_one "v1.6" "patches/pure_fp32" "--enable-single-precision"
        ;;
    *)
        echo "Usage: $0 [v1.2|v1.6|fp64|all] [-j N]"
        exit 1
        ;;
esac

echo ""
echo "=== Build complete ==="
ls -la "$BIN_DIR/"
