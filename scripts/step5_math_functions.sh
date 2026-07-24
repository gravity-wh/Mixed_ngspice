#!/bin/bash
# Step 5: Replace ALL double-only math functions with float versions
BSIM4=/tmp/ngspice_final/ngspice_fp32/src/spicelib/devices/bsim4v5

echo "=== Replacing double math functions with float versions ==="
for f in $BSIM4/*.c; do
  name=$(basename $f)
  before=$(grep -c "fmax\|fmin\|fmod\|fabs\|hypot\|pow " $f 2>/dev/null || echo 0)

  # Only replace standalone function calls (not in comments or macros)
  sed -i 's/\bfmax(/fmaxf(/g' "$f"
  sed -i 's/\bfmin(/fminf(/g' "$f"
  sed -i 's/\bfmod(/fmodf(/g' "$f"
  sed -i 's/\bfabs(/fabsf(/g' "$f"
  sed -i 's/\bhypot(/hypotf(/g' "$f"
  sed -i 's/\bpow(/powf(/g' "$f"

  after=$(grep -c "fmaxf\|fminf\|fmodf\|fabsf\|hypotf\|powf" $f 2>/dev/null || echo 0)
  [ "$after" -gt 0 ] && echo "  $name: $after float math calls"
done

echo ""
echo "=== Clean rebuild ==="
cd /tmp/ngspice_final/ngspice_fp32/build
make -C src/spicelib/devices/bsim4v5 clean 2>/dev/null
make -C src/spicelib/devices/bsim4v5 2>&1 | grep -c "error:" || echo "0 errors"

echo ""
echo "=== L4: Final per-file cvtss2sd ==="
total=0
for o in src/spicelib/devices/bsim4v5/*.o; do
  [ -f "$o" ] || continue
  cvt=$(objdump -d $o 2>/dev/null | grep -c "cvtss2sd")
  [ "$cvt" -gt 0 ] && echo "  $(basename $o): $cvt"
  total=$((total + cvt))
done
echo "TOTAL: $total"
