#!/bin/bash
# verify_cvtss2sd.sh — Count cvtss2sd instructions in SPICE binaries
# Usage: bash scripts/verify_cvtss2sd.sh [binary] [binary2] ...
#
# Without arguments, checks all known binaries:
#   - float_spice/float_spice       (POC v1, ~175 lines)
#   - float_spice/float_spice_v2    (v2.0, ~600 lines)
#   - build_fp32/src/ngspice        (retrofitted, mixed-precision)
#   - build_fp64/src/ngspice        (retrofitted, double-precision ref)

set -euo pipefail

RESET='\033[0m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'

count_cvtss2sd() {
    local bin="$1"
    if [[ ! -f "$bin" ]]; then
        printf "  %-50s ${RED}NOT FOUND${RESET}\n" "$bin"
        return
    fi
    if [[ ! -x "$bin" && "$bin" != *.o && "$bin" != *.a ]]; then
        printf "  %-50s ${YELLOW}NOT EXECUTABLE${RESET}\n" "$bin"
    fi
    local count
    count=$(objdump -d "$bin" 2>/dev/null | grep -c "cvtss2sd" || echo "0")
    # Trim whitespace
    count=$(echo "$count" | tr -d ' ')

    if [[ "$count" -le 3 ]]; then
        printf "  %-50s ${GREEN}%s cvtss2sd${RESET}" "$bin" "$count"
        if [[ "$count" -le 3 ]]; then
            printf " ${GREEN}(libm printf only)${RESET}"
        fi
    elif [[ "$count" -le 50 ]]; then
        printf "  %-50s ${YELLOW}%s cvtss2sd${RESET}" "$bin" "$count"
        printf " ${YELLOW}(output formatting)${RESET}"
    else
        printf "  %-50s ${RED}%s cvtss2sd${RESET}" "$bin" "$count"
        printf " ${RED}(math conversion overhead)${RESET}"
    fi
    printf "\n"

    # Show top functions with cvtss2sd
    if [[ "$count" -gt 0 && "$count" -le 100 ]]; then
        objdump -d "$bin" 2>/dev/null | grep -B1 "cvtss2sd" | grep "^[0-9a-f]" | \
            sed 's/.*<\(.*\)>:/\1/' | sort | uniq -c | sort -rn | head -5 | \
            while read -r n func; do
                printf "         %3d in %s\n" "$n" "$func"
            done
    fi
}

echo "=============================================="
echo " cvtss2sd Instruction Count Verification"
echo " Target: 0 in application code, ≤3 total"
echo "=============================================="
echo ""

if [[ $# -gt 0 ]]; then
    for bin in "$@"; do
        count_cvtss2sd "$bin"
    done
else
    echo "--- From-Scratch Engines ---"
    count_cvtss2sd "float_spice/float_spice"
    count_cvtss2sd "float_spice/float_spice_v2"

    echo ""
    echo "--- Retrofitted ngspice ---"
    count_cvtss2sd "build_fp32/src/ngspice"
    count_cvtss2sd "build_fp64/src/ngspice"
    count_cvtss2sd "bin/ngspice-v1.2"
fi

echo ""
echo "=============================================="
echo " Legend:"
echo "   0-3   → Pure float (only libm printf)"
echo "   4-50  → Output formatting conversions"
echo "   50+   → Math conversion overhead"
echo "=============================================="
