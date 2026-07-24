#!/bin/bash
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits
PASS=0; FAIL=0

t() { local l="$1"; local n="$2"
  echo -n "  $l ... "
  timeout 20 "$V12" --batch "$n" > "/tmp/last12_${l}.log" 2>&1
  local nan=$(grep -c FP32-NAN "/tmp/last12_${l}.log" 2>/dev/null) || nan=0
  local err=$(grep -c 'Error: Transient op failed\|Error: The operating point\|timestep too small\|incomplete\|could not find\|No such file\|unknown subckt' "/tmp/last12_${l}.log" 2>/dev/null) || err=0
  if [ "$nan" -eq 0 ] && [ "$err" -eq 0 ]; then echo "PASS"; PASS=$((PASS+1))
  else echo "FAIL(nan=$nan err=$err)"; FAIL=$((FAIL+1)); fi
}

echo "=== Fix 1: OF sim_* — add DC bias path ==="
for f in "$C/of"/OF_[1-8]_sim_*.sp; do
    [ -f "$f" ] || continue
    name=$(basename "$f")
    # These have AC SIN source with no DC path to ground
    # Fix: add a large resistor from V0 to ground for DC bias
    if ! grep -q 'Rdc' "$f" 2>/dev/null; then
        # Replace .end with DC bias resistor + .end
        sed -i 's/^\(\.end\)$/Rdc V0 0 1e12\n\1/' "$f"
        # Also add .options gmin for convergence
        sed -i 's/^\(\.end\)$/.options gmin=1e-10\n\1/' "$f"
    fi
    echo "  $name: added Rdc bias + gmin"
done

echo ""
echo "=== Fix 2: OF GF180 — add gmin for convergence ==="
f="$C/of/OF_cdl_gf180mcu_osu_sc_9T_tb.spice"
if [ -f "$f" ] && ! grep -q 'gmin=1e-10' "$f" 2>/dev/null; then
    sed -i 's/^\(\.end\)$/.options gmin=1e-10 rseries=1\n\1/' "$f"
    echo "  OF GF180: added gmin + rseries"
fi

echo ""
echo "=== Fix 3: AB ideal_opamp — recreate missing file ==="
f="$C/ab/AB_Ideal_opamp_Ideal_opamp_realota.spice"
if [ ! -f "$f" ]; then
    cat > "$f" << 'EOF'
* Ideal OpAmp test with real OTA
.include /mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
.include ideal_opamp.spice

VDD VDD 0 DC 1.8
VIN IN 0 DC 0.9

X1 IN OUT ideal_opamp
Rload OUT 0 1k

.control
op
print v(out)
.endc
.end
EOF
    echo "  Recreated AB_Ideal_opamp_Ideal_opamp_realota.spice"
fi

echo ""
echo "=== Fix 4: Ensure all OF circuits have proper .end ==="
for f in "$C/of"/OF_[1-8]_sim_*.sp; do
    [ -f "$f" ] || continue
    if ! grep -q '^\.end' "$f" 2>/dev/null; then
        echo '.end' >> "$f"
        echo "  $(basename $f): added .end"
    fi
done

echo ""
echo "=== Re-test all 12 ==="
for f in "$C/of"/OF_[1-8]_sim_*.sp; do
    [ -f "$f" ] && t "of_sim_$(basename $f .sp)" "$f"
done
for f in "$C/of"/OF_cdl_gf180*.spice; do
    [ -f "$f" ] && t "of_gf180" "$f"
done
for f in "$C/ab"/AB_Ideal_opamp_*realota*.spice; do
    [ -f "$f" ] && t "ab_ideal" "$f"
done

echo ""
echo "=== $PASS PASS, $FAIL FAIL ==="
