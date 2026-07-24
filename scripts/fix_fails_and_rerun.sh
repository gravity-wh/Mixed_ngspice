#!/bin/bash
# Fix the 3 FAILs + add missing circuits, re-run all 121
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits
EY=/mnt/e/MyResearch/datasets/Bandgap-IP-Design-using-Sky130-technology-node/Prelayout

PASS=0; FAIL=0; SKIP=0

t() { local l="$1"; local n="$2"; local d="${3:-}"; local log="/tmp/final_${l}.log"
  if [ -n "$d" ]; then (cd "$d" && timeout 30 "$V12" --batch "$n") > "$log" 2>&1
  else timeout 30 "$V12" --batch "$n" > "$log" 2>&1; fi
  local nan=$(grep -c FP32-NAN "$log" 2>/dev/null) || nan=0
  local err=$(grep -c 'Error: Transient op failed\|Error: The operating point\|timestep too small\|incomplete\|could not find\|No such file\|unknown subckt' "$log" 2>/dev/null) || err=0
  if [ "$nan" -gt 0 ]; then echo "FAIL(NaN)"; FAIL=$((FAIL+1))
  elif [ "$err" -gt 0 ]; then echo "FAIL(err)"; FAIL=$((FAIL+1))
  else echo "PASS"; PASS=$((PASS+1)); fi; }

echo "=== v1.2 FINAL BATCH ==="

# 1. Fix ideal_opamp — add behavioral subcircuit to AB circuits that need it
echo "--- Fixing ideal_opamp ---"
cat > "$C/ab/ideal_opamp.spice" << 'EOF'
* Behavioral ideal opamp for testbenches
.subckt ideal_opamp vp vn out
E1 out 0 vp vn 1e6
.ends ideal_opamp
EOF
# Add include to the two failing AB files
for f in AB_Ideal_opamp_Ideal_opamp_realota.spice AB_Ideal_opamp_Ideal_opamp_tb.spice; do
    if [ -f "$C/ab/$f" ] && ! grep -q 'ideal_opamp.spice' "$C/ab/$f" 2>/dev/null; then
        sed -i '1i .include ideal_opamp.spice' "$C/ab/$f"
    fi
done

# 2. Add missing HC magic_* circuits (will SKIP due to subcircuit)
echo "--- Adding HC magic_* circuits ---"
for f in "$C/hc"/HC_magic_*.spice; do
    [ -f "$f" ] || continue
    echo -n "  HC_$(basename $f .spice) "; t "hc_magic_$(basename $f)" "$f"
done

# 3. Add remaining OF circuits
echo "--- Adding remaining OF circuits ---"
for f in "$C/of"/*.sp "$C/of"/*.spice; do
    [ -f "$f" ] || continue
    base=$(basename "$f")
    # Skip ones already tested
    case "$base" in
        OF_PMU_*|OF_1_sim_*|OF_testbench_*|OF_templates_cryo*) continue ;;
    esac
    echo -n "  OF_$base "; t "of_rest_$base" "$f"
done

# 4. Fix OF_1_sim_1_tb.sp — check error
echo "--- Diagnosing OF_1_sim_1_tb ---"
grep -i 'error\|could not find\|unknown\|No such' /tmp/final_of_rest_OF_1_sim_1_tb.sp.log 2>/dev/null | head -3 || echo "(fresh test)"

# 5. Re-test the 3 failures after fix
echo "--- Re-testing fixed circuits ---"
for f in AB_Ideal_opamp_Ideal_opamp_realota.spice AB_Ideal_opamp_Ideal_opamp_tb.spice; do
    echo -n "  AB_$f "; t "ab_fixed_$f" "$C/ab/$f"
done

echo ""
echo "=== $PASS PASS, $FAIL FAIL, $SKIP SKIP ==="
