#!/bin/bash
FP64=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build64/src/ngspice
FP32=/mnt/e/MyResearch/Ngspice/ngspice-46_mixed/build/src/ngspice
TB=/mnt/e/MyResearch/Mixed_ngspice/test/bsim4/testbenches

echo "=== OTA DC (BSIM4) ==="
$FP64 -b $TB/ota_dc_bsim4.cir 2>&1 | grep -E 'v\(|Warning|Error|failed|singular|TEMP'

echo ""
echo "=== OPAMP DC (BSIM4) ==="
$FP64 -b $TB/opamp_dc_bsim4.cir 2>&1 | grep -E 'v\(|Warning|Error|failed|singular|TEMP'

echo ""
echo "=== LDO DC (BSIM4) ==="
$FP64 -b $TB/ldo_dc_bsim4.cir 2>&1 | grep -E 'v\(|vout|Warning|Error|failed|singular|TEMP'
