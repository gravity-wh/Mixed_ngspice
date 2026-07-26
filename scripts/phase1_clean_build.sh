#!/bin/bash
set -e
REPO=/mnt/e/MyResearch/Mixed_ngspice
BUILD=/tmp/build_phase1
rm -rf "$BUILD" && mkdir -p "$BUILD"
tar xzf "$REPO/ngspice-46.tar.gz" -C "$BUILD"
cd "$BUILD/ngspice-46"

# Step 1: patch 001
patch -p1 -N -s < "$REPO/patches/clean/001-typedefs.patch" 2>/dev/null || true

# Step 2: spmatrix.h
sed -i 's|^#define  spREAL double|#ifdef SINGLE_PRECISION\n#define  spREAL float\n#else\n#define  spREAL double\n#endif|' src/include/ngspice/spmatrix.h

# Step 3: spdefs.h
sed -i 's|^#define spREAL  double|#ifndef spREAL\n#define spREAL  SPICE_REAL\n#endif|' src/maths/sparse/spdefs.h

# Step 4: spsolve.c
sed -i '1s/^/#include <stdlib.h>\n/' src/maths/sparse/spsolve.c

# Step 5: configure
./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    CFLAGS="-O2 -fopenmp -DSINGLE_PRECISION -Wno-conversion" \
    --prefix="$BUILD/install" > /tmp/cfg_p1.log 2>&1

# Step 6: build
if make -j$(nproc) > /tmp/build_p1.log 2>&1; then
    echo "BUILD SUCCESS"
    ls -la src/ngspice
else
    echo "Errors: $(grep -c 'error:' /tmp/build_p1.log)"
    grep 'error:' /tmp/build_p1.log | head -10
fi
