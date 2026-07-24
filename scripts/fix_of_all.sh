#!/bin/bash
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/of
PASS=0; FAIL=0

echo "=== Fixing OpenFASOC 11 failures ==="

# Fix 1: OF_1_sim through OF_8_sim — add .control + .endc for AC analysis
echo "--- Fixing OF sim_* RC testbenches ---"
for f in "$C"/OF_1_sim_1_tb.sp "$C"/OF_2_sim_2_tb.sp "$C"/OF_3_sim_3_tb.sp "$C"/OF_4_sim_4_tb.sp \
         "$C"/OF_5_sim_5_tb.sp "$C"/OF_6_sim_6_tb.sp "$C"/OF_7_sim_7_tb.sp "$C"/OF_8_sim_8_tb.sp; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    # These have AC SIN source but no .control block — add one
    if ! grep -q '\.control' "$f" 2>/dev/null; then
        # Remove any trailing .end and add proper structure
        sed -i '/^\.end$/d' "$f" 2>/dev/null || true
        cat >> "$f" << 'CTRL'
.control
ac dec 10 1 1MEG
print v(v0) i(vpower)
.endc
.end
CTRL
        echo "  $name: added .control block"
    fi
done

# Fix 2: OF_cdl_gf180 — needs GF180 CDL subcircuit include
echo "--- Fixing OF_cdl_gf180 ---"
GF180_CDL=/mnt/e/MyResearch/datasets/OpenFASOC/openfasoc/common/platforms/gf180osu9t/cdl/gf180mcu_osu_sc_9T.spice
f="$C/OF_cdl_gf180mcu_osu_sc_9T_tb.spice"
if [ -f "$GF180_CDL" ] && [ -f "$f" ]; then
    # Add GF180 CDL include before the first .include
    sed -i "1i .include $GF180_CDL" "$f"
    echo "  OF_cdl_gf180: added GF180 CDL include"
fi

# Now test all 11
echo ""
echo "--- Re-testing all 11 ---"
for f in "$C"/OF_1_sim_1_tb.sp "$C"/OF_2_sim_2_tb.sp "$C"/OF_3_sim_3_tb.sp "$C"/OF_4_sim_4_tb.sp \
         "$C"/OF_5_sim_5_tb.sp "$C"/OF_6_sim_6_tb.sp "$C"/OF_7_sim_7_tb.sp "$C"/OF_8_sim_8_tb.sp \
         "$C"/OF_cdl_gf180mcu_osu_sc_9T_tb.spice; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    echo -n "  $name ... "
    timeout 15 "$V12" --batch "$f" > "/tmp/of_fix_${name}.log" 2>&1
    nan=$(grep -c FP32-NAN "/tmp/of_fix_${name}.log" 2>/dev/null) || nan=0
    err=$(grep -c 'Error: Transient op failed\|Error: The operating point\|timestep too small\|incomplete\|could not find\|No such file\|unknown subckt' "/tmp/of_fix_${name}.log" 2>/dev/null) || err=0
    rows=$(grep 'No. of Data Rows' "/tmp/of_fix_${name}.log" 2>/dev/null | tail -1 | awk '{print $NF}') || rows="?"
    if [ "$nan" -eq 0 ] && [ "$err" -eq 0 ]; then
        echo "PASS($rows)"
        PASS=$((PASS+1))
    else
        echo "FAIL(NaN=$nan err=$err)"
        FAIL=$((FAIL+1))
    fi
done

echo ""
echo "=== OF fixes: $PASS/$((PASS+FAIL)) PASS ==="
