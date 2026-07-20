#!/usr/bin/env python3
"""
gen_baseline.py — Generate FP64 golden reference JSON for Mixed_ngspice.

Runs each test circuit through the FP64 ngspice binary, extracts all measurable
values, and writes a complete golden reference file.

Usage:
    python3 scripts/gen_baseline.py --fp64 build_fp64/src/ngspice \
        --circuits test/circuits/ --output test/expected/fp64_baseline_ptm45nm.json

    python3 scripts/gen_baseline.py --fp64 build_fp64/src/ngspice \
        --circuits test/circuits/ --output test/expected/fp64_baseline_ptm45nm.json \
        --include-tran  # Also generate entries for test/circuits_tran/
"""

import sys
import os
import re
import json
import subprocess
import argparse
from collections import OrderedDict
from pathlib import Path
from datetime import datetime


# =============================================================================
# Value extraction parsers (self-contained, no external dependencies)
# =============================================================================

def parse_op_voltages(text):
    volts = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Node\s+Voltage", line): in_table = True; continue
        if in_table and re.match(r"\s*----", line): continue
        if in_table and re.match(r"\s*$", line): in_table = False; continue
        if in_table:
            m = re.match(r"\s*([\w.]+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m: volts[m.group(1)] = float(m.group(2))
    return volts


def parse_op_currents(text):
    currs = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Source\s+Current", line): in_table = True; continue
        if in_table and re.match(r"\s*----", line): continue
        if in_table and re.match(r"\s*$", line): in_table = False; continue
        if in_table:
            m = re.match(r"\s*([\w#.]+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m: currs[m.group(1)] = float(m.group(2))
    return currs


def parse_device_params(text):
    params = OrderedDict()
    current_dev = None
    for line in text.split("\n"):
        m = re.match(r"^\s*device\s+(\S+)", line)
        if m: current_dev = m.group(1); continue
        if current_dev:
            m = re.match(r"\s+(\w+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m:
                try: params[f"{current_dev}_{m.group(1)}"] = float(m.group(2))
                except ValueError: pass
    return params


def parse_control_print(text):
    values = OrderedDict()
    for line in text.split("\n"):
        m = re.match(r'^\s*([\w()\[\].@]+)\s*=\s*([-+]?\d+\.?\d*[eE]?[-+]?\d+)', line)
        if m:
            try: values[m.group(1).strip()] = float(m.group(2))
            except ValueError: pass
    return values


# =============================================================================
# Tolerance defaults
# =============================================================================
DEFAULT_TOLERANCES = {
    "voltage":    {"rel": 0.001, "abs_floor": 0.001},
    "current":    {"rel": 0.001, "abs_floor": 1e-9},
    "gm":         {"rel": 0.01,  "abs_floor": 1e-9},
    "gds":        {"rel": 0.02,  "abs_floor": 1e-9},
    "vth":        {"rel": 0.005, "abs_floor": 0.001},
    "ac_gain_db": {"rel": 0.02,  "abs_floor": 0.1},
    "ac_freq_hz": {"rel": 0.05,  "abs_floor": 1e3},
    "ac_phase":   {"abs": 3.0},
    "osc_freq":   {"rel": 0.005},
    "osc_period": {"rel": 0.005},
    "tran_rms":   {"rel": 0.02},
    "tran_max":   {"rel": 0.05},
    "chaos_stats": {"rel": 0.15},
}


# =============================================================================
# Test circuit manifest
# =============================================================================
CIRCUITS = [
    {
        "id": "01_single_nmos_dc", "spice_file": "test/circuits/01_single_nmos_45nm/test_dc.sp",
        "analysis": "DC OP", "model": "45nm_LP",
        "metric_types": {"v(d)": "voltage", "v(g)": "voltage", "gm": "gm", "gds": "gds", "vth": "vth", "id": "current"}
    },
    {
        "id": "01_single_nmos_sweep", "spice_file": "test/circuits/01_single_nmos_45nm/test_dc_sweep.sp",
        "analysis": "DC Sweep", "model": "45nm_LP", "metric_types": {"vth0": "vth"}
    },
    {
        "id": "02_single_pmos_dc", "spice_file": "test/circuits/02_single_pmos_45nm/test_dc.sp",
        "analysis": "DC OP", "model": "45nm_LP",
        "metric_types": {"v(d)": "voltage", "v(g)": "voltage", "gm": "gm", "gds": "gds", "vth": "vth", "id": "current"}
    },
    {
        "id": "02_single_pmos_sweep", "spice_file": "test/circuits/02_single_pmos_45nm/test_dc_sweep.sp",
        "analysis": "DC Sweep", "model": "45nm_LP", "metric_types": {"vth0": "vth"}
    },
    {
        "id": "03_ring_oscillator_dc", "spice_file": "test/circuits/03_ring_oscillator_17stage/test_tran.sp",
        "analysis": "DC OP (single inverter)", "model": "45nm_LP",
        "metric_types": {"v(out)": "voltage", "gm_p": "gm", "gm_n": "gm", "id_p": "current"}
    },
    {
        "id": "04_ota_5transistor_dc", "spice_file": "test/circuits/04_ota_5transistor_45nm/test_dc.sp",
        "analysis": "DC OP", "model": "45nm_LP",
        "metric_types": {"v(out)": "voltage", "v(netd)": "voltage", "v(tail)": "voltage",
                         "gm_in": "gm", "gm_load": "gm", "gds_out": "gds", "id_tail": "current", "vth_in": "vth"}
    },
    {
        "id": "04_ota_ac", "spice_file": "test/circuits/04_ota_5transistor_45nm/test_ac.sp",
        "analysis": "AC", "model": "45nm_LP",
        "metric_types": {"gain_max": "ac_gain_db", "ugbw": "ac_freq_hz"}
    },
    {
        "id": "05_opamp_2stage_dc", "spice_file": "test/circuits/05_opamp_2stage_miller_45nm/test_dc.sp",
        "analysis": "DC OP", "model": "45nm_LP",
        "metric_types": {"v(out)": "voltage", "v(a)": "voltage", "v(b)": "voltage", "v(tail)": "voltage",
                         "gm1": "gm", "gm7": "gm", "gds7": "gds", "id5": "current"}
    },
    {
        "id": "05_opamp_ac", "spice_file": "test/circuits/05_opamp_2stage_miller_45nm/test_ac.sp",
        "analysis": "AC", "model": "45nm_LP",
        "metric_types": {"gain_max": "ac_gain_db", "ugbw": "ac_freq_hz", "pm": "ac_phase"}
    },
    {
        "id": "06_comparator_strongarm", "spice_file": "test/circuits/06_comparator_strongarm_45nm/test_tran.sp",
        "analysis": "DC OP (static, CLK=1)", "model": "45nm_HP",
        "metric_types": {"v(vxp)": "voltage", "v(vxn)": "voltage", "v(vlp)": "voltage", "v(vln)": "voltage",
                         "v(vs)": "voltage", "gm_in": "gm", "id_tail": "current"}
    },
    {
        "id": "07_bootstrap_switch", "spice_file": "test/circuits/07_bootstrap_switch_45nm/test_tran.sp",
        "analysis": "TRAN", "model": "45nm_HP", "metric_types": {},
        "known_failure": "FP64 also fails (TTS) — ngspice branch stiffness"
    },
    {
        "id": "08_roessler_attractor", "spice_file": "test/circuits/08_roessler_attractor/test_chaos.sp",
        "analysis": "TRAN Chaos", "model": "behavioral", "comparison_method": "relaxed_final_value",
        "metric_types": {"v(x)": "chaos_stats", "v(y)": "chaos_stats", "v(z)": "chaos_stats"},
        "note": "Chaotic system — compare final values with wide tolerances (15%)"
    },
]

TRAN_CIRCUITS = [
    {
        "id": "T1_ring_osc_tran", "spice_file": "test/circuits_tran/T1_ring_osc_tran.sp",
        "analysis": "TRAN", "model": "45nm_LP",
        "metric_types": {"period": "osc_period", "freq": "osc_freq"}
    },
    {
        "id": "T2_ota_step", "spice_file": "test/circuits_tran/T2_ota_step.sp",
        "analysis": "TRAN", "model": "45nm_LP",
        "metric_types": {"vout_final": "voltage", "overshoot": "voltage"}
    },
    {
        "id": "T3_opamp_step", "spice_file": "test/circuits_tran/T3_opamp_step.sp",
        "analysis": "TRAN", "model": "45nm_LP",
        "metric_types": {"vout_final": "voltage", "overshoot": "voltage"}
    },
    {
        "id": "T4_comparator_clock", "spice_file": "test/circuits_tran/T4_comparator_clock.sp",
        "analysis": "TRAN", "model": "45nm_HP",
        "metric_types": {"vdd_current": "current"}
    },
    {
        "id": "T5_bootstrap_switch", "spice_file": "test/circuits_tran/T5_bootstrap_switch.sp",
        "analysis": "TRAN", "model": "45nm_HP",
        "metric_types": {"vsampled_mean": "voltage", "vsampled_pp": "voltage"}
    },
]


def run_ngspice(ngspice_path, circuit_path, timeout=120):
    """Run ngspice in batch mode and capture output."""
    try:
        result = subprocess.run(
            [ngspice_path, "--batch", circuit_path],
            capture_output=True, text=True, timeout=timeout,
            cwd=str(Path(circuit_path).parent)
        )
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return None
    except Exception as e:
        print(f"    ERROR: {e}", file=sys.stderr)
        return None


def extract_all_values(text):
    """Extract all measurable values using all parsers."""
    values = OrderedDict()
    for k, v in parse_op_voltages(text).items(): values[k] = v
    for k, v in parse_op_currents(text).items(): values[f"i({k.replace('#branch', '_I')})"] = v
    for k, v in parse_device_params(text).items(): values[k] = v
    for k, v in parse_control_print(text).items(): values[k] = v
    return values


def generate_baseline(fp64_bin, circuits, output_path, timeout=120):
    """Run all circuits through FP64 and generate golden reference JSON."""
    results = {}
    for circ in circuits:
        circ_id = circ["id"]
        spice_file = circ["spice_file"]
        print(f"  [{circ_id}] {spice_file} ... ", end="", flush=True)

        if not os.path.exists(spice_file):
            print("SKIP (file not found)")
            continue

        text = run_ngspice(fp64_bin, spice_file, timeout)
        if text is None:
            print("TIMEOUT/ERROR")
            circ["fp64_status"] = "error"; circ["outputs"] = {}
            results[circ_id] = circ; continue

        has_errors = bool(re.search(r"timestep too small|singular matrix|iteration limit reached",
                                     text, re.IGNORECASE))
        values = extract_all_values(text)

        if not values and has_errors:
            print("FAIL (convergence error, no data)")
            circ["fp64_status"] = "known_failure"; circ["outputs"] = {}
            results[circ_id] = circ; continue

        outputs = {}
        metric_types = circ.get("metric_types", {})
        for key, val in values.items():
            mtype = metric_types.get(key, "voltage")
            entry = {"value": round(val, 10), "type": mtype}
            tol = DEFAULT_TOLERANCES.get(mtype, DEFAULT_TOLERANCES["voltage"])
            if "rel" in tol: entry["tolerance_rel"] = tol["rel"]
            if "abs" in tol: entry["tolerance_abs"] = tol["abs"]
            if "abs_floor" in tol: entry["abs_floor"] = tol["abs_floor"]
            outputs[key] = entry

        circ["outputs"] = outputs; circ["fp64_status"] = "pass"
        results[circ_id] = circ
        print(f"OK ({len(outputs)} metrics)")

    baseline = {
        "version": "2.0",
        "description": f"FP64 reference baseline for PTM 45nm LP/HP circuits. Generated by gen_baseline.py.",
        "date_generated": datetime.now().isoformat(),
        "ngspice_version": "ngspice-46 (patched, double-precision mode, patches 001-015)",
        "defaults": {"tolerances": DEFAULT_TOLERANCES, "abs_floor_voltage": 0.001, "abs_floor_current": 1e-9},
        "circuits": results,
    }
    with open(output_path, "w") as f:
        json.dump(baseline, f, indent=2, default=str)
    print(f"\nBaseline written to {output_path} ({len(results)} circuits, {sum(len(c.get('outputs', {})) for c in results.values())} metrics)")


def main():
    parser = argparse.ArgumentParser(description="Generate FP64 golden reference for Mixed_ngspice")
    parser.add_argument("--fp64", required=True, help="Path to FP64 ngspice binary")
    parser.add_argument("--circuits", default="test/circuits/", help="Directory containing test circuits")
    parser.add_argument("--output", default="test/expected/fp64_baseline_ptm45nm.json", help="Output JSON path")
    parser.add_argument("--include-tran", action="store_true", help="Also generate entries for test/circuits_tran/")
    parser.add_argument("--timeout", type=int, default=120, help="Per-circuit timeout in seconds")
    args = parser.parse_args()

    if not os.path.exists(args.fp64):
        print(f"ERROR: FP64 binary not found: {args.fp64}"); sys.exit(1)

    print(f"Generating baseline using FP64: {args.fp64}")
    circuits = list(CIRCUITS)
    if args.include_tran: circuits.extend(TRAN_CIRCUITS)
    generate_baseline(args.fp64, circuits, args.output, args.timeout)


if __name__ == "__main__":
    main()
