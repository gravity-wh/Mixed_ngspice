#!/bin/bash
set -euo pipefail
SRC=/mnt/e/MyResearch/Mixed_ngspice/ngspice-46
BUILD=/tmp/build_v12
rm -rf "$BUILD"; cp -r "$SRC" "$BUILD"; cd "$BUILD"

echo "=== Minimal v1.2 build ==="

# 1. Add SPICE_REAL typedef
cat > /tmp/spice_real.h << 'HEADEREOF'
#ifndef SPICE_REAL_DEFINED
#define SPICE_REAL_DEFINED
#ifdef SINGLE_PRECISION
typedef float SPICE_REAL;
#else
typedef double SPICE_REAL;
#endif
#endif
HEADEREOF
# Insert after ngspice include guard in typedefs.h
sed -i '/#define ngspice_TYPEDEFS_H/r /tmp/spice_real.h' src/include/ngspice/typedefs.h
grep 'SPICE_REAL' src/include/ngspice/typedefs.h | head -3

# 2. Add -DSINGLE_PRECISION to all compile commands via a simple wrapper
export CFLAGS="-O2 -fopenmp -Wno-conversion -DSINGLE_PRECISION"
export CPPFLAGS="-DSINGLE_PRECISION"

# 3. Configure (no --enable-single-precision needed — we inject via CFLAGS)
./configure --disable-xspice --disable-osdi --disable-cider 2>&1 | tail -3

# 4. Build
make -j4 2>&1 | tail -15

if [ -f src/ngspice ]; then
    echo ""
    echo "BUILD SUCCESS: $BUILD/src/ngspice"
    ls -la src/ngspice
else
    echo "BUILD FAILED"
    exit 1
fi
