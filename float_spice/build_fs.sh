#!/bin/bash
# build_fs.sh — Build float_spice with conda-cached GCC toolchain
# =====================================================================
# Sets up GCC 15.2 from cached conda packages and builds float_spice.
# Usage: bash float_spice/build_fs.sh [clean]
# =====================================================================
set -e

GCC_PKGS="/e/ANACONDA/pkgs"
GCC_BASE="$GCC_PKGS/gcc_impl_win-64-15.2.0-hf3019ae_20/Library"
BIN_BASE="$GCC_PKGS/binutils_impl_win-64-2.46.1-bootstrap_h173839c_2/Library"
LD_BASE="$GCC_PKGS/ld_impl_win-64-2.46.1-bootstrap_h8c62646_2/Library"
LIBGCC="$GCC_PKGS/libgcc-15.2.0-h8ee18e1_20/Library"
LIBGCC_DEV="$GCC_PKGS/libgcc-devel_win-64-15.2.0-hbb59886_120/Library"
HEADERS="$GCC_PKGS/mingw-w64-ucrt-x86_64-headers-git-12.0.0.r4.gg4f2fc60ca-hd8ed1ab_10/Library/x86_64-w64-mingw32/sysroot/usr"
CRT="$GCC_PKGS/mingw-w64-ucrt-x86_64-crt-git-12.0.0.r4.gg4f2fc60ca-hd8ed1ab_10/Library/x86_64-w64-mingw32/sysroot/usr"
MANIFEST="$GCC_PKGS/mingw-w64-ucrt-x86_64-windows-default-manifest-6.4-he206cdd_7/Library/x86_64-w64-mingw32/sysroot/usr"

export PATH="$GCC_BASE/bin:$BIN_BASE/bin:$LD_BASE/bin:$LIBGCC/bin:$PATH"
export C_INCLUDE_PATH="$HEADERS/include"
export LIBRARY_PATH="$CRT/lib:$LIBGCC_DEV/lib/gcc/x86_64-w64-mingw32/15.2.0:$MANIFEST/lib:$LIBGCC/lib"
export PATH="$LIBGCC/bin:$PATH"  # runtime DLLs

TOOLCHAIN="x86_64-w64-mingw32-gcc"
CFLAGS="-O2 -Wall -Wextra -std=gnu11"

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FS_DIR="$ROOT/float_spice"

if [ "$1" = "clean" ]; then
    rm -f "$FS_DIR/float_spice.exe"
    echo "Cleaned."
    exit 0
fi

echo "=== Building float_spice ==="
echo "Compiler: $($TOOLCHAIN --version | head -1)"
cd "$FS_DIR"
$TOOLCHAIN $CFLAGS -o float_spice float_spice.c -lm
echo "Build: OK ($(wc -c < float_spice.exe) bytes)"
echo ""
echo "Run: float_spice/float_spice.exe <circuit.sp>"
echo "Verify: objdump -d float_spice.exe | grep -c cvtss2sd"
