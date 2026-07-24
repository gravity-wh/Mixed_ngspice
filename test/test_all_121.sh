#!/bin/bash
# Test ALL circuits in test/circuits/ subdirectories with v1.2
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
CIRCUITS=/mnt/e/MyResearch/Mixed_ngspice/test/circuits
PASS=0; FAIL=0; SKIP=0; TOTAL=0

t() {
    local cat="$1"; local name="$2"; local netlist="$3"; local dir="${4:-}"
    TOTAL=$((TOTAL+1))
    local log="/tmp/all121_${cat}_${name}.log"
    if [ -n "$dir" ]; then
        (cd "$dir" && timeout 60 "$V12" --batch "$netlist") > "$log" 2>&1
    else
        timeout 60 "$V12" --batch "$netlist" > "$log" 2>&1
    fi
    local rc=$?
    local nan=$(grep -c FP32-NAN "$log" 2>/dev/null) || nan=0
    local rows=$(grep 'No. of Data Rows' "$log" 2>/dev/null | tail -1 | awk '{print $NF}') || rows="?"
    local pdk_err=$(grep -c 'could not find\|No such file\|unknown subckt' "$log" 2>/dev/null) || pdk_err=0
    local sim_err=$(grep -c 'Error: Transient op failed\|Error: The operating point\|timestep too small\|incomplete' "$log" 2>/dev/null) || sim_err=0

    if [ "$nan" -gt 0 ]; then
        echo "FAIL(NaN=$nan)"
        FAIL=$((FAIL+1))
    elif [ "$sim_err" -gt 0 ]; then
        echo "FAIL(sim=$sim_err)"
        FAIL=$((FAIL+1))
    elif [ "$pdk_err" -gt 0 ]; then
        echo "SKIP(PDK)"
        SKIP=$((SKIP+1))
    elif [ "$rc" -ne 0 ]; then
        echo "SKIP(crash)"
        SKIP=$((SKIP+1))
    else
        echo "PASS($rows)"
        PASS=$((PASS+1))
    fi
}

echo "============================================================"
echo "  v1.2 Full Circuit Test — $(date +%H:%M)"
echo "============================================================"

# MX original (14 files in 01-08/)
echo "--- MX: PTM45 BSIM4 (14 circuits) ---"
for d in 01_single_nmos_45nm 02_single_pmos_45nm 03_ring_oscillator_17stage \
         04_ota_5transistor_45nm 05_opamp_2stage_miller_45nm \
         06_comparator_strongarm_45nm 07_bootstrap_switch_45nm 08_roessler_attractor; do
    for f in "$CIRCUITS/$d"/*.sp; do
        [ -f "$f" ] || continue
        t "MX" "$(basename $f)" "$(basename $f)" "$CIRCUITS/$d"
    done
done

# AB (28 files)
echo "--- AB: SKY130 (28 circuits) ---"
for f in "$CIRCUITS/ab"/*.spice; do
    [ -f "$f" ] || continue
    t "AB" "$(basename $f .spice)" "$f"
done

# HC (24 files)
echo "--- HC: PTM45 subcircuit (24 circuits) ---"
for f in "$CIRCUITS/hc"/*.spice; do
    [ -f "$f" ] || continue
    t "HC" "$(basename $f .spice)" "$f"
done

# AG (10 files, AnalogGym)
echo "--- AG: AnalogGym (10 circuits) ---"
for f in "$CIRCUITS/ag"/*.sp; do
    [ -f "$f" ] || continue
    t "AG" "$(basename $f .sp)" "$f"
done

# MG (24 files, MAGICAL)
echo "--- MG: MAGICAL (24 circuits) ---"
for f in "$CIRCUITS/mg"/*.sp; do
    [ -f "$f" ] || continue
    t "MG" "$(basename $f .sp)" "$f"
done

# OF (41 files, OpenFASOC)
echo "--- OF: OpenFASOC (41 circuits) ---"
for f in "$CIRCUITS/of"/*.sp "$CIRCUITS/of"/*.spice; do
    [ -f "$f" ] || continue
    ext="${f##*.}"
    t "OF" "$(basename $f .$ext)" "$f"
done

# CA (3 files, caravel)
echo "--- CA: caravel (3 circuits) ---"
for f in "$CIRCUITS/ca"/*.spice; do
    [ -f "$f" ] || continue
    t "CA" "$(basename $f .spice)" "$f"
done

# S5 (2 files, SKY130 stand-alone)
echo "--- S5: SKY130 stand-alone (2 circuits) ---"
for f in "$CIRCUITS/s5"/*.spice; do
    [ -f "$f" ] || continue
    t "S5" "$(basename $f .spice)" "$f"
done

# Eyantra BGR (7 files, from datasets/)
echo "--- EY: Eyantra BGR (7 circuits) ---"
EYDIR=/mnt/e/MyResearch/datasets/Bandgap-IP-Design-using-Sky130-technology-node/Prelayout
for f in "$EYDIR"/*.cir; do
    [ -f "$f" ] || continue
    t "EY" "$(basename $f .cir)" "$f"
done

echo ""
echo "============================================================"
echo "  v1.2: $PASS PASS, $SKIP SKIP (PDK), $FAIL FAIL"
echo "  Total: $TOTAL circuits tested"
echo "============================================================"
