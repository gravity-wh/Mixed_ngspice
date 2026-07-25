#!/bin/bash
# Phase 1 build script for fp32 ngspice
set -e
cd /tmp
rm -rf build_fp32_test
cp -r /mnt/e/MyResearch/Mixed_ngspice/ngspice-46 build_fp32_test
cd build_fp32_test

echo "=== Applying patches ==="
for p in /mnt/e/MyResearch/Mixed_ngspice/patches/clean/*.patch; do
    patch -p1 -N < "$p"
done

echo "=== Copying fp32_math.h ==="
cp /mnt/e/MyResearch/Mixed_ngspice/ngspice-46/src/include/ngspice/fp32_math.h src/include/ngspice/

echo "=== Configuring with SINGLE_PRECISION ==="
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix=/tmp/build_fp32_test/install 2>&1 | tail -5

echo "=== Building (this will take a while) ==="
make -j$(nproc) 2>&1 | tail -20

echo "=== Build complete ==="
ls -la src/ngspice
