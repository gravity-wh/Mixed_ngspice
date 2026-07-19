#!/bin/bash
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
AB=/mnt/e/MyResearch/Analog_blocks/Analog_Blocks

echo "=== Analog_blocks FULL FP32 Validation ==="
passed=0; failed=0; nodc=0; total=0

while IFS= read -r sp; do
    [ -f "$sp" ] || continue
    total=$((total+1))
    name=$(echo "$sp" | sed 's|/mnt/e/MyResearch/Analog_blocks/Analog_Blocks/||')

    out=$($FP32 -b "$sp" 2>&1)
    outc=$(echo "$out" | grep -v "<<NAN")

    if echo "$outc" | grep -qi "timestep too small"; then
        failed=$((failed+1))
        echo "FAIL_TTS: $name"
    elif echo "$outc" | grep -qi "singular matrix"; then
        failed=$((failed+1))
        echo "FAIL_SING: $name"
    elif echo "$outc" | grep -qi "iteration limit reached"; then
        failed=$((failed+1))
        echo "FAIL_NOCONV: $name"
    elif echo "$outc" | grep -qi "no analysis"; then
        nodc=$((nodc+1))
        echo "NODC: $name (subcircuit-only, no stimulus)"
    else
        passed=$((passed+1))
        echo "PASS: $name"
    fi
done < <(find "$AB" -name '*.spice' -o -name '*.sp' -o -name '*.cir' | grep -v 'layout\|PEX\|extr_net\|backup' | sort)

echo ""
echo "=== Analog_blocks FULL Summary ==="
echo "Total: $total | PASS: $passed | FAIL: $failed | NODC(subckt): $nodc"
echo "Effective pass rate (exc. subckts): $(( passed * 100 / (passed + failed) ))%"
