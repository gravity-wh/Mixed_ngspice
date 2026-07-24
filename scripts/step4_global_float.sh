#!/bin/bash
BSIM4=/tmp/ngspice_final/ngspice_fp32/src/spicelib/devices/bsim4v5

echo "=== Adding FP32 math + eliminating (double) in all BSIM4v5 .c files ==="
for f in $BSIM4/*.c; do
  name=$(basename $f)
  # Skip files that already have the math block
  if grep -q "B4V5_FP32_MATH" "$f" 2>/dev/null; then
    # Already has it — just eliminate casts
    sed -i 's/exp((double)(x))/expf((float)(x))/g' "$f"
    sed -i 's/log((double)(x))/logf((float)(x))/g' "$f"
    sed -i 's/sqrt((double)(x))/sqrtf((float)(x))/g' "$f"
    sed -i 's/pow((double)(x),(double)(y))/powf((float)(x),(float)(y))/g' "$f"
    echo "  $name: updated"
  else
    # Add math block after #include "bsim4v5def.h"
    sed -i 's|#include "bsim4v5def.h"|#include "bsim4v5def.h"\n#define B4V5_FP32_MATH\n#ifdef B4V5_FP32_MATH\n#undef SPICE_EXP\n#undef SPICE_LOG\n#undef SPICE_SQRT\n#undef SPICE_POW\n#define SPICE_EXP(x)  expf((float)(x))\n#define SPICE_LOG(x)  logf((float)(x))\n#define SPICE_SQRT(x) sqrtf((float)(x))\n#define SPICE_POW(x,y) powf((float)(x),(float)(y))\n#endif|' "$f"
    sed -i 's/exp((double)(x))/expf((float)(x))/g' "$f"
    sed -i 's/log((double)(x))/logf((float)(x))/g' "$f"
    sed -i 's/sqrt((double)(x))/sqrtf((float)(x))/g' "$f"
    sed -i 's/pow((double)(x),(double)(y))/powf((float)(x),(float)(y))/g' "$f"
    echo "  $name: math block added + casts fixed"
  fi
done

echo ""
echo "=== Rebuild all BSIM4v5 ==="
cd /tmp/ngspice_final/ngspice_fp32/build
make -C src/spicelib/devices/bsim4v5 2>&1 | grep -c "error:" || echo "0 errors"

echo ""
echo "=== L4: Final cvtss2sd per file ==="
for o in src/spicelib/devices/bsim4v5/*.o; do
  [ -f "$o" ] || continue
  cvt=$(objdump -d $o 2>/dev/null | grep -c "cvtss2sd")
  [ "$cvt" -gt 0 ] && echo "  $(basename $o): $cvt"
done
echo "TOTAL: $(objdump -d src/spicelib/devices/bsim4v5/*.o 2>/dev/null | grep -c cvtss2sd)"
