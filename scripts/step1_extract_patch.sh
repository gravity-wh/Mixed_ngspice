#!/bin/bash
# Step 1: Extract pristine + apply all patches
PROJ=/mnt/e/MyResearch/Mixed_ngspice
P=$PROJ/patches

rm -rf /tmp/ngspice_final 2>/dev/null
mkdir -p /tmp/ngspice_final
tar -xzf $PROJ/ngspice-46.tar.gz -C /tmp/ngspice_final/
mv /tmp/ngspice_final/ngspice-46 /tmp/ngspice_final/ngspice_fp32
SRC=/tmp/ngspice_final/ngspice_fp32
cd $SRC

echo "Applying patches 001-011 (absolute paths, need -p6)..."
for f in $P/001-typedefs-spice-macros.patch $P/002-bsim4v5def-struct-fp32.patch \
         $P/004-b4v5temp-double-island.patch $P/005-b4v5set-spice-real.patch \
         $P/006-b4v5noi-fp32.patch $P/007-b4v5pzld-fp32.patch \
         $P/008-b4v5acld-fp32.patch $P/009-b4v5geo-fp32.patch \
         $P/010-devsup-spice-real.patch $P/011-spconfig-include.patch; do
  patch -p6 < $f 2>/dev/null || true
done

echo "Applying patch 003 (absolute paths, -p6)..."
patch -p6 -F 3 < $P/003-b4v5ld-hotpath-fp32.patch 2>/dev/null || true

echo "Applying patch 013 (relative a/b paths, -p1 from bsim4v5 dir)..."
cd $SRC/src/spicelib/devices/bsim4v5
patch -p1 -F 5 < $P/013-multi-t-nan-fix.patch 2>/dev/null || true
cd $SRC

BSIM4=$SRC/src/spicelib/devices/bsim4v5
echo ""
echo "=== Patch Results ==="
echo "SPICE_REAL in typedefs.h:  $(grep -c SPICE_REAL $SRC/src/include/ngspice/typedefs.h)"
echo "SPICE_REAL in bsim4v5def.h: $(grep -c SPICE_REAL $BSIM4/bsim4v5def.h)"
echo "CHECK_NAN in b4v5ld.c:     $(grep -c CHECK_NAN $BSIM4/b4v5ld.c)"
echo "double Vbseff island:      $(grep -c 'DOUBLE PRECISION ISLAND.*Vbseff' $BSIM4/b4v5ld.c)"
echo "double in b4v5ld.c:        $(grep -c '\bdouble\b' $BSIM4/b4v5ld.c)"
echo "double in b4v5temp.c:      $(grep -c '\bdouble\b' $BSIM4/b4v5temp.c)"
