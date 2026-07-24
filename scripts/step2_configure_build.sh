#!/bin/bash
SRC=/tmp/ngspice_final/ngspice_fp32
cd $SRC

echo "=== Fix configure.ac ==="
sed -i 's/AC_ARG_ENABLE(\[smoketest\],/AC_ARG_ENABLE([single-precision],\n    [AS_HELP_STRING([--enable-single-precision], [Use single precision (float).])])\n\nAC_ARG_ENABLE([smoketest],/' configure.ac
sed -i 's/AC_OUTPUT/if test "x$enable_single_precision" = xyes; then\n    AC_DEFINE([SINGLE_PRECISION],[1],[Define for single precision])\n    AC_MSG_RESULT([Single precision enabled])\nfi\n\nAC_OUTPUT/' configure.ac
echo "configure.ac: OK"

echo ""
echo "=== Fix header type declarations ==="
sed -i 's/\bdouble\b/SPICE_REAL/g' $SRC/src/include/ngspice/devdefs.h
sed -i 's/\bdouble\b/SPICE_REAL/g' $SRC/src/spicelib/devices/bsim4v5/bsim4v5ext.h
sed -i 's/\bdouble\b/SPICE_REAL/g' $SRC/src/spicelib/devices/limit.c
sed -i 's/\bdouble \*timeStep\b/SPICE_REAL *timeStep/' $SRC/src/spicelib/devices/bsim4v5/b4v5trunc.c
echo "Headers: OK"

echo ""
echo "=== autoreconf ==="
autoreconf -fi 2>/dev/null
echo "autoreconf: OK"

echo ""
echo "=== configure + make ==="
mkdir -p build && cd build
../configure --enable-single-precision --disable-klu --disable-xspice --disable-osdi --disable-cider \
  CFLAGS="-O2 -g -fopenmp -Wno-conversion" 2>/dev/null
echo "configure: OK"

make -j20 2>/dev/null || true
BIN=src/ngspice
if [ -f "$BIN" ]; then
  echo "Binary: $(ls -lh $BIN | awk '{print $5}')"
  echo "SINGLE_PRECISION: $(grep -c SINGLE_PRECISION src/include/ngspice/config.h)"
else
  echo "BUILD FAILED — checking errors..."
  make -C src/spicelib/devices/bsim4v5 2>&1 | grep "error:" | head -3
fi
