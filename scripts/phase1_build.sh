#!/bin/bash
set -euo pipefail
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_fp32_phase1

echo "=== Phase 1.4: Reproduce build_fp64 (baseline) ==="
rm -rf "$BUILD"
mkdir -p "$BUILD"

echo "--- Extracting pristine ngspice-46 ---"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
cd "$BUILD/ngspice-46"

echo "--- Applying 11 patches ---"
for p in "$REPO/patches/clean"/0*.patch; do
    patch -p1 -N -s < "$p" 2>/dev/null && echo "  OK: $(basename $p)" || echo "  SKIP: $(basename $p)"
done

echo "--- Copying fp32_math.h ---"
cp "$REPO/ngspice-46/src/include/ngspice/fp32_math.h" src/include/ngspice/

echo "--- Configure (matching build_fp64 flags) ---"
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/config_fp32.log 2>&1
echo "  configure: $(tail -1 /tmp/config_fp32.log)"

echo "--- make -j (this takes ~3 min) ---"
if make -j$(nproc) > /tmp/build_fp32.log 2>&1; then
    echo "  BUILD OK"
else
    echo "BUILD FAILED — last 40 lines:"
    tail -40 /tmp/build_fp32.log
    exit 1
fi

echo "--- Binary built ---"
ls -la src/ngspice

echo ""
echo "=== cvtss2sd count ==="
CVD=$(objdump -d src/ngspice 2>/dev/null | grep -c "cvtss2sd" || echo "0")
echo "cvtss2sd: $CVD (build_fp64 ref: 164)"
echo ""
echo "=== Phase 1.4 COMPLETE ==="
