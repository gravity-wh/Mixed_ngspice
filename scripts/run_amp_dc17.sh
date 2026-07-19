#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
AMP=/mnt/e/MyResearch/AnalogGym/AnalogGym/Amplifier
PDK=/mnt/e/MyResearch/AnalogGym/mosfet_model

echo "=== AnalogGym AMP: 17 topologies — Simple DC OP ==="
echo ""

passed=0; failed=0; total=0

for topo in "$AMP/spice_netlist"/*; do
    [ -f "$topo" ] || continue
    tname=$(basename "$topo")
    [ ! -f "$AMP/design_variables/$tname" ] && continue
    total=$((total+1))
    echo -n "[$total] $tname ... "

    # Infer subcircuit name (lowercase version of filename)
    scname=$(echo "$tname" | tr '[:upper:]' '[:lower:]')

    # Create minimal DC OP test
    cat > "/tmp/dc_$tname.cir" << SPICEEND
* Simple DC OP test for $scname
.include $PDK/sky130_pdk/libs.tech/ngspice/corners/tt.spice
.include $AMP/spice_netlist/$tname
.include $AMP/design_variables/$tname

VDD VDDA 0 DC 1.8
VSS GNDA 0 DC 0

* Instantiate the amplifier: ports = gnda vdda vinn vinp vout
XAMP GNDA VDDA vinn vinp vout $scname

* Input at VDD/4 differential (conservative bias point)
VINP vinp 0 DC 0.5
VINN vinn 0 DC 0.45

* Light cap load
CL vout 0 1p

.op
.options gmin=1e-12 reltol=1e-5
.end
SPICEEND

    out=$($FP32 -b "/tmp/dc_$tname.cir" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")

    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1)); echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1)); echo "FAIL_SING"
    elif echo "$outc" | grep -qi "iteration limit"; then
        failed=$((failed+1)); echo "FAIL_NOCONV"
    elif echo "$outc" | grep -qi "unknown subckt\|can't find\|no definition"; then
        failed=$((failed+1)); echo "FAIL_SUBCKT"
    else
        passed=$((passed+1)); echo "PASS"
    fi
    rm -f "/tmp/dc_$tname.cir"
done

echo ""
echo "=== AMP DC OP Summary: $passed/$total PASS ==="
