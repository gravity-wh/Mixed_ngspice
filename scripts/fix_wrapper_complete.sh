#!/bin/bash
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits
PASS=0; FAIL=0

echo "=== Step 1: Create complete wrapper with ALL subcircuit variants ==="
WRAPPER="$C/hc/pmos_nmos_3p3_wrapper.spice"
cat > "$WRAPPER" << 'WEOF'
* Minimal compatibility wrapper for hybridCHIPS/MAGICAL circuits
* Maps old subcircuit names → standard BSIM4 models
.subckt pmos_3p3 D G S B w=1u l=0.15u
M1 D G S B pmos W={w} L={l}
.ends pmos_3p3

.subckt pmos_6p0 D G S B w=1u l=0.15u
M1 D G S B pmos W={w} L={l}
.ends pmos_6p0

.subckt nmos_3p3 D G S B w=1u l=0.15u
M1 D G S B nmos W={w} L={l}
.ends nmos_3p3
WEOF
echo "  Wrapper: $WRAPPER"
grep '^\.subckt' "$WRAPPER"

# Copy to OF directory too
cp "$WRAPPER" "$C/of/pmos_nmos_3p3_wrapper.spice"

echo ""
echo "=== Step 2: Ensure all HC magic circuits include the wrapper ==="
for f in "$C/hc"/HC_magic_*.spice; do
    [ -f "$f" ] || continue
    if ! grep -q 'pmos_nmos_3p3_wrapper' "$f" 2>/dev/null; then
        sed -i "1i .include pmos_nmos_3p3_wrapper.spice" "$f"
    fi
done

echo ""
echo "=== Step 3: Re-test ALL 25 previously-failing circuits ==="
t() {
    local l="$1"; local n="$2"
    echo -n "  $l ... "
    timeout 15 "$V12" --batch "$n" > "/tmp/wfix_${l}.log" 2>&1
    local nan=$(grep -c FP32-NAN "/tmp/wfix_${l}.log" 2>/dev/null) || nan=0
    local err=$(grep -c 'Error: Transient op failed\|Error: The operating point\|timestep too small\|incomplete\|could not find\|No such file\|unknown subckt' "/tmp/wfix_${l}.log" 2>/dev/null) || err=0
    if [ "$nan" -eq 0 ] && [ "$err" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1))
    else echo "FAIL(nan=$nan err=$err)"; FAIL=$((FAIL+1)); fi
}

# HC magic (14)
echo "--- HC magic_* (14) ---"
for f in "$C/hc"/HC_magic_*.spice; do
    [ -f "$f" ] && t "hc_$(basename $f .spice)" "$f"
done

# AB ideal_opamp (2)
echo "--- AB ideal_opamp (2) ---"
for f in "$C/ab"/AB_Ideal_opamp_*.spice; do
    [ -f "$f" ] && t "ab_$(basename $f .spice)" "$f"
done

# OF GF180 (1)
echo "--- OF GF180 (1) ---"
f="$C/of/OF_cdl_gf180mcu_osu_sc_9T_tb.spice"
[ -f "$f" ] && t "of_gf180" "$f"

# OF sim_* (8 — expect skip, but try anyway)
echo "--- OF sim_* (8) ---"
for f in "$C/of"/OF_[1-8]_sim_*.sp; do
    [ -f "$f" ] && t "of_$(basename $f .sp)" "$f"
done

echo ""
echo "============================================================"
echo "  $PASS PASS, $FAIL FAIL from 25 previously-failing circuits"
echo "============================================================"
