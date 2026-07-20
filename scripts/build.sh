#!/bin/bash
# build.sh — One-shot build of Mixed_ngspice (FP32 + FP64 reference)
# Usage: bash scripts/build.sh [--fp32-only] [--fp64-only] [-j N]

set -euo pipefail
cd "$(dirname "$0")/.."

JOBS=$(nproc 2>/dev/null || echo 4)
MODE="both"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --fp32-only) MODE="fp32"; shift ;;
    --fp64-only) MODE="fp64"; shift ;;
    --pure-fp32) MODE="pure-fp32"; shift ;;
    -j) JOBS="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

NGSPICE_URL="https://sourceforge.net/projects/ngspice/files/ng-spice-rework/46/ngspice-46.tar.gz"
NGSPICE_TAR="ngspice-46.tar.gz"
NGSPICE_DIR="ngspice-46"
PATCH_DIR="patches"
PURE_FP32_PATCH_DIR="patches/pure_fp32"

# --- Download ngspice-46 if needed ---
if [[ ! -f "$NGSPICE_TAR" ]]; then
  echo "[1/5] Downloading ngspice-46..."
  if command -v wget &>/dev/null; then
    wget -q --show-progress "$NGSPICE_URL" -O "$NGSPICE_TAR"
  else
    curl -L -o "$NGSPICE_TAR" "$NGSPICE_URL"
  fi
fi

# --- Extract ---
if [[ ! -d "$NGSPICE_DIR" ]]; then
  echo "[2/5] Extracting ngspice-46..."
  tar xzf "$NGSPICE_TAR"
fi

apply_patches() {
  local target="$1"
  echo "  Applying patches to $target..."
  for patch in "$PATCH_DIR"/*.patch; do
    local name=$(basename "$patch")
    echo "    - $name"
    patch -d "$target" -p1 < "$patch" || {
      echo "ERROR: Patch $name failed to apply!"
      exit 1
    }
  done
}

# --- Build FP32 ---
if [[ "$MODE" == "both" || "$MODE" == "fp32" ]]; then
  echo "[3/5] Building FP32 (mixed-precision)..."
  FP32_BUILD="build_fp32"
  rm -rf "$FP32_BUILD"
  cp -r "$NGSPICE_DIR" "$FP32_BUILD"
  apply_patches "$FP32_BUILD"

  cd "$FP32_BUILD"
  ./configure --enable-single-precision --disable-klu --disable-xspice \
    --disable-osdi --disable-cider --prefix="$PWD/install-fp32" \
    CFLAGS="-O2 -fopenmp -Wno-conversion" 2>&1 | tail -5
  make -j"$JOBS" 2>&1 | tail -5
  make install 2>&1 | tail -3
  cd ..
  echo "  FP32 binary: $FP32_BUILD/src/ngspice"
fi

# --- Build FP64 ---
if [[ "$MODE" == "both" || "$MODE" == "fp64" ]]; then
  echo "[4/5] Building FP64 (reference)..."
  FP64_BUILD="build_fp64"
  rm -rf "$FP64_BUILD"
  cp -r "$NGSPICE_DIR" "$FP64_BUILD"
  apply_patches "$FP64_BUILD"

  cd "$FP64_BUILD"
  # FP64: patches are no-ops (SPICE_REAL = double without --enable-single-precision)
  ./configure --disable-klu --disable-xspice --disable-osdi --disable-cider \
    --prefix="$PWD/install-fp64" \
    CFLAGS="-O2 -fopenmp -Wno-conversion" 2>&1 | tail -5
  make -j"$JOBS" 2>&1 | tail -5
  make install 2>&1 | tail -3
  cd ..
  echo "  FP64 binary: $FP64_BUILD/src/ngspice"
fi

echo "[5/6] Build complete!"
echo "  FP32: build_fp32/src/ngspice"
echo "  FP64: build_fp64/src/ngspice"

# --- Build Pure FP32 (all float, no double-precision islands) ---
if [[ "$MODE" == "pure-fp32" ]]; then
  echo "[1/3] Building Pure FP32 (all-float, no double islands)..."
  PURE_FP32_BUILD="build_pure_fp32"
  rm -rf "$PURE_FP32_BUILD"
  cp -r "$NGSPICE_DIR" "$PURE_FP32_BUILD"

  if [[ -d "$PURE_FP32_PATCH_DIR" ]]; then
    echo "  Applying pure FP32 patches (no double-precision islands)..."
    for patch in "$PURE_FP32_PATCH_DIR"/*.patch; do
      pname=$(basename "$patch")
      echo "    - $pname"
      patch -d "$PURE_FP32_BUILD" -p1 < "$patch" || {
        echo "ERROR: Pure FP32 patch $pname failed to apply!"
        exit 1
      }
    done
  else
    echo "ERROR: Pure FP32 patch directory not found: $PURE_FP32_PATCH_DIR"
    echo "Run: python scripts/gen_pure_fp32_patches.py"
    exit 1
  fi

  cd "$PURE_FP32_BUILD"
  ./configure --enable-single-precision --disable-klu --disable-xspice \
    --disable-osdi --disable-cider --prefix="$PWD/install-pure-fp32" \
    CFLAGS="-O2 -fopenmp -Wno-conversion" 2>&1 | tail -5
  make -j"$JOBS" 2>&1 | tail -5
  make install 2>&1 | tail -3
  cd ..
  echo "  Pure FP32 binary: $PURE_FP32_BUILD/src/ngspice"
fi

echo "[Done] Build complete!"
