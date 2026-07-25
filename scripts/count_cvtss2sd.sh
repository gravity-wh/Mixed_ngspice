#!/bin/bash
# Count cvtss2sd per object file
DIR=/mnt/e/MyResearch/Mixed_ngspice/build_fp64/src/spicelib/devices
for d in bsim4v5 bsim4 bsim4v6 bsim4v7 bsimsoi bjt dio mos1 mos2 mos3; do
    total=0
    for f in "$DIR/$d"/*.o; do
        [ -f "$f" ] || continue
        cnt=$(objdump -d "$f" 2>/dev/null | grep -c cvtss2sd || echo 0)
        total=$((total + cnt))
        if [ "$cnt" -gt 0 ]; then
            echo "  $cnt $d/$(basename $f)"
        fi
    done
    echo "$d TOTAL: $total"
done
echo ""
echo "=== Full binary ==="
objdump -d /mnt/e/MyResearch/Mixed_ngspice/build_fp64/src/ngspice 2>/dev/null | grep -c cvtss2sd
