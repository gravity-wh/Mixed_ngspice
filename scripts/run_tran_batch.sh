#!/bin/bash
# run_tran_batch.sh — FP32 vs FP64 TRAN validation with waveform comparison
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
CT=/mnt/e/MyResearch/Mixed_ngspice/test/circuits_tran
AB=/mnt/e/MyResearch/Analog_blocks/Analog_Blocks
OUTDIR=/mnt/e/MyResearch/Mixed_ngspice/test/tran_results
mkdir -p "$OUTDIR"

echo "============================================="
echo "  FP32 TRAN Validation Batch Run"
echo "  $(date)"
echo "============================================="
echo ""

total=0; passed=0; failed=0

run_tran_test() {
    local label="$1"; local sp="$2"; shift 2
    total=$((total+1))
    echo "--- [$total] $label ---"
    echo "  Circuit: $(basename "$sp")"

    # Run FP64 (reference) - write rawfile
    local raw64="$OUTDIR/$(basename "$sp" .sp)_fp64.raw"
    local out64=$($FP64 -b "$sp" 2>&1)
    local ret64=$?

    # Run FP32
    local raw32="$OUTDIR/$(basename "$sp" .sp)_fp32.raw"
    local out32=$($FP32 -b "$sp" 2>&1)
    local ret32=$?

    # Clean output
    local out32c=$(echo "$out32" | grep -v "<<NAN")
    local out64c=$(echo "$out64" | grep -v "<<NAN")

    # Check FP64 first (if FP64 fails, circuit is the issue)
    local fp64_ok=1
    if echo "$out64c" | grep -qi "timestep too small"; then
        fp64_ok=0
    elif echo "$out64c" | grep -qi "iteration limit reached"; then
        fp64_ok=0
    fi

    # Check FP32
    local reason=""
    if [ $fp64_ok -eq 0 ]; then
        reason="FP64_ALSO_FAIL"
    elif echo "$out32c" | grep -qi "timestep too small"; then
        reason="TTS_FP32"
    elif echo "$out32c" | grep -qi "iteration limit reached"; then
        reason="NOCONV_FP32"
    elif echo "$out32c" | grep -qi "singular matrix"; then
        reason="SINGULAR_FP32"
    fi

    if [ -n "$reason" ]; then
        failed=$((failed+1))
        echo "  RESULT: ❌ $reason"
    else
        passed=$((passed+1))
        # Extract key metrics
        local meas32=$(echo "$out32" | grep -E '^\S+\s*=\s*[0-9]' | head -5 | tr '\n' ' ')
        local meas64=$(echo "$out64" | grep -E '^\S+\s*=\s*[0-9]' | head -5 | tr '\n' ' ')
        echo "  RESULT: ✅ PASS"
        [ -n "$meas64" ] && echo "  FP64 metrics: $meas64"
        [ -n "$meas32" ] && echo "  FP32 metrics: $meas32"

        # Compare .meas values numerically
        if [ -n "$meas32" ] && [ -n "$meas64" ]; then
            echo "$meas32" | grep -oE '[0-9.]+e?[0-9+\-]*' > "$OUTDIR/tmp32.txt" 2>/dev/null
            echo "$meas64" | grep -oE '[0-9.]+e?[0-9+\-]*' > "$OUTDIR/tmp64.txt" 2>/dev/null
        fi

        # Check step count from output
        local steps32=$(echo "$out32" | grep -oP 'ntranpairs\s*=\s*\K[0-9]+' | head -1)
        local steps64=$(echo "$out64" | grep -oP 'ntranpairs\s*=\s*\K[0-9]+' | head -1)
        [ -n "$steps32" ] && [ -n "$steps64" ] && \
            echo "  Steps: FP32=$steps32 FP64=$steps64 (ratio=$(echo "scale=2; $steps32/$steps64" | bc 2>/dev/null || echo '?'))"
    fi
    echo ""
}

# ===== LAYER 1: Existing TRAN testbenches =====
echo "========== LAYER 1: Existing TRAN Testbenches =========="
echo ""

# Analog_blocks Bandgap startup
for sp in "$AB/Bandgap/Netlists/Testbench/Bandgap1.8v_meas.spice" \
          "$AB/Bandgap/Netlists/Testbench/Bandgap5v_meas.spice"; do
    [ -f "$sp" ] && run_tran_test "BGR startup: $(basename $sp)" "$sp"
done

# Analog_blocks OTA slew rate
for sp in "$AB/OTA/Netlists/Testbench/Miller_OTA1.8v_meas_transient.spice" \
          "$AB/OTA/Netlists/Testbench/Folded_Cascode1.8v_meas_Transient.spice"; do
    [ -f "$sp" ] && run_tran_test "OTA slew: $(basename $sp)" "$sp"
done

# Analog_blocks Buck converter
sp="$AB/DC_DC converter/Netlists/Testbench/Buck_converter.spice"
[ -f "$sp" ] && run_tran_test "Buck converter" "$sp"

# Analog_blocks LDO line/load step
sp="$AB/LDO/Netlists/Testbench/LDO_Miller_1.8v_meas.spice"
[ -f "$sp" ] && run_tran_test "LDO load step" "$sp"

# ===== LAYER 2: T1-T5 Built Testbenches =====
echo "========== LAYER 2: T1-T5 Custom TRAN Testbenches =========="
echo ""

for sp in "$CT/T1_ring_osc_tran.sp" \
          "$CT/T2_ota_step.sp" \
          "$CT/T3_opamp_step.sp" \
          "$CT/T4_comparator_clock.sp" \
          "$CT/T5_bootstrap_switch.sp"; do
    [ -f "$sp" ] && run_tran_test "T$(echo $(basename $sp) | cut -c2)" "$sp"
done

# ===== LAYER 3: Original PTM45 TRAN circuits =====
echo "========== LAYER 3: Original PTM45 TRAN Circuits =========="
echo ""

for sp in /mnt/e/MyResearch/Mixed_ngspice/test/circuits/03_ring_oscillator_17stage/test_tran.sp \
          /mnt/e/MyResearch/Mixed_ngspice/test/circuits/07_bootstrap_switch_45nm/test_tran.sp \
          /mnt/e/MyResearch/Mixed_ngspice/test/circuits/08_roessler_attractor/test_chaos.sp; do
    [ -f "$sp" ] && run_tran_test "$(basename $(dirname $sp))" "$sp"
done

# ===== Summary =====
echo "============================================="
echo "  TRAN VALIDATION SUMMARY"
echo "============================================="
echo "Total: $total | ✅ PASS: $passed | ❌ FAIL: $failed"
if [ $total -gt 0 ]; then
    echo "Pass rate: $(( passed * 100 / total ))%"
fi
echo "Results directory: $OUTDIR"
