#!/usr/bin/env python3
"""Compare FP32 vs FP64 Ngspice simulation outputs.

Supports DC operating point analysis and transient waveform comparison.
Outputs a Markdown-formatted accuracy report.

Usage:
    python compare_fp.py <fp32_log> <fp64_log>
    python compare_fp.py --latest          # compare latest logs
    python compare_fp.py --list            # list available logs
"""

import sys
import os
import re
import glob
from collections import OrderedDict

LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs")
ABS_TOL = 1e-3   # floor for relative error denominator (1mV for voltages)


def parse_op_voltages(text):
    """Extract node voltages from .op output.

    Ngspice format:
        Node                                  Voltage
        ----                                  -------
        vdd                              1.800000e+00
        vb2                              1.492889e+00
    """
    volts = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Node\s+Voltage", line):
            in_table = True
            continue
        if in_table and re.match(r"\s*----", line):
            continue
        if in_table and re.match(r"\s*$", line):
            in_table = False
            continue
        if in_table:
            m = re.match(r"\s*([\w.]+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m:
                volts[m.group(1)] = float(m.group(2))
    return volts


def parse_op_currents(text):
    """Extract source currents from .op output."""
    currs = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Source\s+Current", line):
            in_table = True
            continue
        if in_table and re.match(r"\s*----", line):
            continue
        if in_table and re.match(r"\s*$", line):
            in_table = False
            continue
        if in_table:
            m = re.match(r"\s*([\w#.]+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m:
                currs[m.group(1)] = float(m.group(2))
    return currs


def parse_tran_waveforms(text):
    """Extract transient waveform data.

    Ngspice format for .print tran:
        Index   time            v(vout)
        0       0.000000e+00    0.000000e+00
        1       1.000000e-05    1.234567e-03
        ...
    """
    waves = OrderedDict()
    in_data = False
    columns = []
    for line in text.split("\n"):
        # Detect .print tran header
        if re.match(r"Index\s+time\b", line):
            columns = line.split()
            in_data = True
            for col in columns[2:]:
                waves[col] = []
            continue
        if in_data:
            if re.match(r"\s*$", line) or "---" in line:
                in_data = False
                continue
            parts = line.split()
            if len(parts) >= 3:
                for i, col in enumerate(columns[2:]):
                    if i + 2 < len(parts):
                        try:
                            waves[col].append(float(parts[i + 2]))
                        except ValueError:
                            pass
    return waves


def parse_device_params(text):
    """Extract BSIM4 device operating point parameters.

    Format:
        device                   mp1
           gm                2.59e-06
          gds                1.47e-08
          vth                0.4305
    """
    params = OrderedDict()
    current_dev = None
    for line in text.split("\n"):
        m = re.match(r"^\s*device\s+(\S+)", line)
        if m:
            current_dev = m.group(1)
            continue
        if current_dev:
            m = re.match(r"\s+(\w+)\s+([-+]?\d+\.?\d*[eE]?[-+]?\d*)", line)
            if m:
                key = f"{current_dev}_{m.group(1)}"
                try:
                    params[key] = float(m.group(2))
                except ValueError:
                    pass
    return params


def compute_error(v32, v64):
    """Compute relative error: |v32 - v64| / max(|v64|, abs_tol)."""
    denom = max(abs(v64), ABS_TOL)
    return abs(v32 - v64) / denom


def status_label(err):
    if err < 0.001:
        return "PASS"
    elif err < 0.01:
        return "WARN"
    else:
        return "FAIL"


def compare_dicts(d32, d64, label, fp32_label, fp64_label):
    """Compare two parameter dictionaries and return results."""
    results = []
    all_keys = set(d64.keys()) & set(d32.keys())
    missing = set(d64.keys()) - set(d32.keys())
    for key in sorted(all_keys):
        err = compute_error(d32[key], d64[key])
        results.append((key, d64[key], d32[key], err, status_label(err)))
    return results, missing


def compare_waveforms(w32, w64):
    """Compare transient waveforms. Returns (rms_error, max_error, max_time).

    w32 and w64 are dicts of {signal_name: [values]}.
    Uses the minimum length across both waveforms.
    """
    results = {}
    for sig in w64:
        if sig not in w32:
            continue
        v32_arr = w32[sig]
        v64_arr = w64[sig]
        n = min(len(v32_arr), len(v64_arr))
        if n == 0:
            continue
        errors = []
        max_err = 0.0
        max_idx = 0
        for i in range(n):
            err = compute_error(v32_arr[i], v64_arr[i])
            errors.append(err)
            if err > max_err:
                max_err = err
                max_idx = i
        rms = (sum(e * e for e in errors) / n) ** 0.5
        results[sig] = {"rms": rms, "max": max_err, "max_idx": max_idx, "n": n}
    return results


def find_latest_logs():
    """Find the latest fp32 and fp64 log files."""
    logs = sorted(glob.glob(os.path.join(LOG_DIR, "*.log")),
                  key=os.path.getmtime, reverse=True)
    fp32_log = None
    fp64_log = None
    for log in logs:
        base = os.path.basename(log)
        if fp32_log is None and "fp32" in base:
            fp32_log = log
        if fp64_log is None and "fp64" in base:
            fp64_log = log
        if fp32_log and fp64_log:
            break
    return fp32_log, fp64_log


def detect_type(text):
    """Detect if the log contains transient or just DC data."""
    if re.search(r"transient analysis|Index\s+time", text, re.IGNORECASE):
        return "tran"
    return "dc"


def generate_report(fp32_path, fp64_path):
    """Generate a complete Markdown comparison report."""
    with open(fp32_path) as f:
        text32 = f.read()
    with open(fp64_path) as f:
        text64 = f.read()

    lines = []
    lines.append("# FP32 vs FP64 Accuracy Report")
    lines.append("")
    lines.append(f"- **FP32**: `{fp32_path}`")
    lines.append(f"- **FP64**: `{fp64_path}`")
    lines.append("")

    sim_type = detect_type(text64)

    # --- DC Operating Point ---
    volts32 = parse_op_voltages(text32)
    volts64 = parse_op_voltages(text64)
    currs32 = parse_op_currents(text32)
    currs64 = parse_op_currents(text64)

    if volts64:
        lines.append("## DC Operating Point")
        lines.append("")
        lines.append("### Node Voltages")
        lines.append("")
        lines.append(f"| Node | FP64 | FP32 | RelErr | Status |")
        lines.append(f"|------|------|------|--------|--------|")
        v_results, v_missing = compare_dicts(volts32, volts64, "V", "fp32", "fp64")
        worst_v = (0.0, "N/A")
        for key, v64, v32, err, status in v_results:
            lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
            if err > worst_v[0]:
                worst_v = (err, key)
        if v_missing:
            lines.append(f"| *(missing)* | — | — | — | {', '.join(sorted(v_missing))} |")
        lines.append("")

        currs32_renamed = {k.replace("#branch", "_I"): v for k, v in currs32.items()}
        currs64_renamed = {k.replace("#branch", "_I"): v for k, v in currs64.items()}
        if currs64_renamed:
            lines.append("### Source Currents")
            lines.append("")
            lines.append(f"| Source | FP64 | FP32 | RelErr | Status |")
            lines.append(f"|--------|------|------|--------|--------|")
            c_results, c_missing = compare_dicts(currs32_renamed, currs64_renamed, "I", "fp32", "fp64")
            for key, v64, v32, err, status in c_results:
                lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
            lines.append("")
    else:
        lines.append("## DC Operating Point")
        lines.append("")
        lines.append("*No node voltages found in output.*")
        lines.append("")

    # --- Device Parameters ---
    params32 = parse_device_params(text32)
    params64 = parse_device_params(text64)
    if params64:
        lines.append("## Device Operating Point Parameters")
        lines.append("")
        lines.append(f"| Parameter | FP64 | FP32 | RelErr | Status |")
        lines.append(f"|-----------|------|------|--------|--------|")
        p_results, p_missing = compare_dicts(params32, params64, "P", "fp32", "fp64")
        for key, v64, v32, err, status in p_results:
            lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
        lines.append("")

    # --- Transient Waveforms ---
    if sim_type == "tran":
        waves32 = parse_tran_waveforms(text32)
        waves64 = parse_tran_waveforms(text64)
        if waves64:
            lines.append("## Transient Waveforms")
            lines.append("")
            wave_results = compare_waveforms(waves32, waves64)
            lines.append(f"| Signal | RMS Error | Max Error | Points | Status |")
            lines.append(f"|--------|-----------|-----------|--------|--------|")
            worst_t = (0.0, "")
            for sig, r in sorted(wave_results.items()):
                status = status_label(r["max"])
                lines.append(f"| `{sig}` | {r['rms']:.2e} | {r['max']:.2e} | {r['n']} | {status} |")
                if r["max"] > worst_t[0]:
                    worst_t = (r["max"], sig)
            lines.append("")

    # --- Summary ---
    lines.append("## Summary")
    lines.append("")
    if volts64:
        lines.append(f"- **Worst DC voltage error**: {worst_v[0]:.2e} on `{worst_v[1]}`")
    if sim_type == "tran" and waves64:
        lines.append(f"- **Worst transient error**: {worst_t[0]:.2e} on `{worst_t[1]}`")
        lines.append(f"- **Transient RMS error**: {wave_results.get(list(wave_results.keys())[0] if wave_results else '', {}).get('rms', 0):.2e}")
    lines.append("")

    overall = "PASS"
    if worst_v[0] > 0.001:
        overall = "WARN"
    if worst_v[0] > 0.01:
        overall = "FAIL"
    lines.append(f"**Overall Verdict: {overall}**")
    lines.append("")

    return "\n".join(lines)


def list_logs():
    """List available log files."""
    logs = sorted(glob.glob(os.path.join(LOG_DIR, "*.log")),
                  key=os.path.getmtime, reverse=True)
    if not logs:
        print("No logs found in", LOG_DIR)
        return
    print(f"{'Date':<20} {'Size':>8}  File")
    print("-" * 60)
    for log in logs[:30]:
        mtime = os.path.getmtime(log)
        size = os.path.getsize(log)
        import datetime
        dt = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
        print(f"{dt:<20} {size:>8}  {os.path.basename(log)}")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    if sys.argv[1] == "--list":
        list_logs()
        sys.exit(0)

    if sys.argv[1] == "--latest":
        fp32_log, fp64_log = find_latest_logs()
        if not fp32_log:
            print("ERROR: No fp32 log found")
            sys.exit(1)
        if not fp64_log:
            print("ERROR: No fp64 log found")
            sys.exit(1)
    elif len(sys.argv) >= 3:
        fp32_log = sys.argv[1]
        fp64_log = sys.argv[2]
    else:
        print("Usage: compare_fp.py <fp32_log> <fp64_log>")
        sys.exit(1)

    if not os.path.exists(fp32_log):
        print(f"ERROR: fp32 log not found: {fp32_log}")
        sys.exit(1)
    if not os.path.exists(fp64_log):
        print(f"ERROR: fp64 log not found: {fp64_log}")
        sys.exit(1)

    report = generate_report(fp32_log, fp64_log)
    print(report)
