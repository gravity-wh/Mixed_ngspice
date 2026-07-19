#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
AMP=/mnt/e/MyResearch/AnalogGym/AnalogGym/Amplifier/amp_spice_testbench
SP=/mnt/e/MyResearch/AnalogGym/AnalogGym/Amplifier/spice_netlist
DV=/mnt/e/MyResearch/AnalogGym/AnalogGym/Amplifier/design_variables

echo "=== AnalogGym AMP: 17 topologies FP32 ==="
echo ""

passed=0; failed=0; skipped=0; total=0

for topo in "$SP"/*; do
    [ -f "$topo" ] || continue
    tname=$(basename "$topo")
    total=$((total+1))

    # Check if design_variables exists
    if [ ! -f "$DV/$tname" ]; then
        skipped=$((skipped+1))
        echo "[$total] $tname ... SKIP (no design_variables)"
        continue
    fi

    echo -n "[$total] $tname ... "

    # Create testbench with this topology
    sed "s|\.include \.\./spice_netlist/.*|.include ../spice_netlist/$tname|" "$AMP/TB_Amplifier_ACDC.cir" | \
    sed "s|\.include \.\./design_variables/.*|.include ../design_variables/$tname|" > "/tmp/amp_${tname}.cir"

    out=$($FP32 -b "/tmp/amp_${tname}.cir" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")

    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1))
        echo "FAIL_TTS"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1))
        echo "FAIL_SING"
    elif echo "$outc" | grep -qi "iteration limit reached"; then
        failed=$((failed+1))
        echo "FAIL_NOCONV"
    else
        passed=$((passed+1))
        gain=$(echo "$out" | grep -oP 'gain\s*=\s*\S+' | head -1)
        echo "PASS ($gain)"
    fi

    # Clean up
    rm -f "/tmp/amp_${tname}.cir"
done

echo ""
echo "=== AMP Summary ==="
echo "Total: $total | PASS: $passed | FAIL: $failed | SKIP: $skipped"
echo "Pass rate: $(( passed * 100 / (passed + failed) ))%"
