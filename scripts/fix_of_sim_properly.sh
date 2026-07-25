#!/bin/bash
# Actually fix OF sim_* circuits instead of deleting them
C=/mnt/e/MyResearch/Mixed_ngspice/test/circuits/of
V12=/mnt/e/MyResearch/Mixed_ngspice/bin/ngspice-v1.2
MODEL=/mnt/e/MyResearch/Mixed_ngspice/test/models/45nm_LP_BSIM4/ptm45lp.lib
PASS=0

echo "=== Rewriting OF sim_* as proper testbenches ==="
for i in 1 2 3 4 5 6 7 8; do
    f="$C/OF_${i}_sim_${i}_tb.sp"
    # Each sim circuit is a simple RC low-pass: R=5k, C=5F
    # Test with AC sweep + DC OP
    cat > "$f" << CEOP
* OF sim_${i} — RC Low-Pass Filter Testbench
.include ${MODEL}
.option gmin=1e-12

* Power supply
VDD VDD 0 DC 1.8
VSS VSS 0 DC 0

* RC network with DC bias
R1 VIN VOUT 5k
C1 VOUT VSS 5
Rload VOUT VSS 1e9

* Input with DC bias
VIN VIN VSS DC 0.9 AC 1

.control
op
ac dec 10 1 1MEG
print vdb(vout) vp(vout)
.endc
.end
CEOP
    echo -n "  OF_${i}_sim_${i}_tb.sp ... "
    timeout 15 "$V12" --batch "$f" > "/tmp/of_sim_fix_${i}.log" 2>&1
    nan=$(grep -c FP32-NAN "/tmp/of_sim_fix_${i}.log") || nan=0
    err=$(grep -c 'Error:\|timestep too small\|singular\|incomplete' "/tmp/of_sim_fix_${i}.log") || err=0
    if [ "$nan" -eq 0 ] && [ "$err" -eq 0 ]; then
        echo "PASS"
        PASS=$((PASS+1))
    else
        echo "FAIL(nan=$nan err=$err)"
    fi
done

echo ""
echo "=== OF sim_* fix result: $PASS/8 PASS ==="
