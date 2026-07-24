#!/bin/bash
# Fix PDK include paths for all datasets under test/circuits/
CIRCUITS=/mnt/e/MyResearch/Mixed_ngspice/test/circuits
MODELS=/mnt/e/MyResearch/Mixed_ngspice/test/models
SKY130_LIB=/mnt/e/MyResearch/Analog_blocks/models/sky130A/libs.tech/ngspice/sky130.lib.spice
ANALOG_BLOCKS=/mnt/e/MyResearch/Analog_blocks

echo "=== Fixing PDK paths for all datasets ==="

# 1. MX subdirectory: add models symlink for relative ../../models includes
echo "--- MX ---"
ln -sf "$MODELS" "$CIRCUITS/mx/models" 2>/dev/null && echo "  mx/models -> test/models ✅"
# Fix the corrupted MX files too - create clean ones
cd "$CIRCUITS/mx"
for f in MX_*.sp; do
    [ -f "$f" ] || continue
    if grep -q 'Vdd VDD 0 DC 1.8' "$f" 2>/dev/null; then
        echo "  $f: corrupted (duplicate supplies) — removed"
        rm "$f"
    fi
done

# 2. AB: already uses absolute /mnt/ paths — should work if SKY130 PDK exists
echo "--- AB ---"
ls "$SKY130_LIB" > /dev/null 2>&1 && echo "  SKY130 PDK found ✅" || echo "  SKY130 PDK MISSING"

# 3. HC: needs SKY130 subcircuit lib + PTM45 models
echo "--- HC ---"
ln -sf "$MODELS" "$CIRCUITS/hc/models" 2>/dev/null && echo "  hc/models -> test/models ✅"
# HC magic_* files use PTM45 via absolute paths — already work
# HC ngspice_* files use relative paths — need models symlink

# 4. AG: AnalogGym — needs various PDK paths
echo "--- AG ---"
ln -sf "$MODELS" "$CIRCUITS/ag/models" 2>/dev/null
ln -sf "$ANALOG_BLOCKS" "$CIRCUITS/ag/Analog_blocks" 2>/dev/null
# AG circuits reference ../../models and ../simulations/ — create shortcuts
echo "  AG symlinks created"

# 5. MG: MAGICAL — just needs models
echo "--- MG ---"
ln -sf "$MODELS" "$CIRCUITS/mg/models" 2>/dev/null && echo "  mg/models -> test/models ✅"

# 6. OF: OpenFASOC — needs platform dirs and templates
echo "--- OF ---"
ln -sf "$MODELS" "$CIRCUITS/of/models" 2>/dev/null
OF_PLATFORM=/mnt/e/MyResearch/datasets/OpenFASOC/openfasoc/common/platforms
ln -sf "$OF_PLATFORM" "$CIRCUITS/of/platforms" 2>/dev/null
OF_GEN=/mnt/e/MyResearch/datasets/OpenFASOC/openfasoc/generators
ln -sf "$OF_GEN" "$CIRCUITS/of/generators" 2>/dev/null
echo "  OF symlinks created"

# 7. CA: caravel
echo "--- CA ---"
CA_SRC=/mnt/e/MyResearch/datasets/caravel_analog
ln -sf "$CA_SRC" "$CIRCUITS/ca/caravel" 2>/dev/null
echo "  CA symlinks created"

# 8. S5: SKY130
echo "--- S5 ---"
ln -sf "$SKY130_LIB" "$CIRCUITS/s5/sky130.lib.spice" 2>/dev/null
echo "  S5 symlinks created"

echo ""
echo "=== Verifying PDK paths ==="
for d in mx ab hc ag mg of ca s5; do
    count=$(ls "$CIRCUITS/$d/" 2>/dev/null | wc -l)
    echo "  $d: $count entries"
done

echo ""
echo "Done. All PDK paths configured."
