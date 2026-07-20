#!/usr/bin/env python3
"""Compare FP32 vs FP64 Ngspice simulation outputs.

Supports DC operating point analysis, AC measurements, and transient waveform comparison.
Outputs a Markdown-formatted accuracy report.

Usage:
    python compare_fp.py <fp32_log> <fp64_log>
    python compare_fp.py <fp32_log> <fp64_log> --ci
    python compare_fp.py <fp32_log> <fp64_log> --ci --json-summary
    python compare_fp.py --latest          # compare latest logs
    python compare_fp.py --list            # list available logs

CI mode (--ci):
    Exits with non-zero code on precision failures.
    exit 0: all metrics PASS or no comparable data
    exit 1: at least one metric FAIL (exceeds --fail-* threshold)
    exit 2: at least one metric WARN but no FAIL
"""

import sys
import os
import re
import json
import glob
from collections import OrderedDict

LOG_DIR = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs")
ABS_TOL = 1e-3   # floor for relative error denominator (1mV for voltages)

# Default thresholds: err < WARN => PASS, WARN <= err < FAIL => WARN, err >= FAIL => FAIL
THRESHOLD_WARN_DC = 0.001   # 0.1%
THRESHOLD_FAIL_DC = 0.01    # 1%
THRESHOLD_WARN_AC = 0.01    # 1% (dB values amplify small errors)
THRESHOLD_FAIL_AC = 0.05    # 5%
THRESHOLD_WARN_TRAN = 0.001 # 0.1%
THRESHOLD_FAIL_TRAN = 0.01  # 1%


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


def parse_control_print(text):
    """Extract values from .control block 'print' outputs like 'gm = 4.36e-05'."""
    values = OrderedDict()
    for line in text.split("\n"):
        m = re.match(r'^\s*([\w()\[\].@]+)\s*=\s*([-+]?\d+\.?\d*[eE]?[-+]?\d+)', line)
        if m:
            try: values[m.group(1).strip()] = float(m.group(2))
            except ValueError: pass
    return values


def parse_tran_waveforms(text):
    waves = OrderedDict()
    in_data = False
    columns = []
    for line in text.split("\n"):
        if re.match(r"Index\s+time\b", line):
            columns = line.split(); in_data = True
            for col in columns[2:]: waves[col] = []
            continue
        if in_data:
            if re.match(r"\s*$", line) or "---" in line: in_data = False; continue
            parts = line.split()
            if len(parts) >= 3:
                for i, col in enumerate(columns[2:]):
                    if i + 2 < len(parts):
                        try: waves[col].append(float(parts[i + 2]))
                        except ValueError: pass
    return waves


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


def compute_error(v32, v64):
    denom = max(abs(v64), ABS_TOL)
    return abs(v32 - v64) / denom


def status_label(err, warn_threshold=0.001, fail_threshold=0.01):
    if err < warn_threshold: return "PASS"
    elif err < fail_threshold: return "WARN"
    else: return "FAIL"


def compare_dicts(d32, d64, label="", fp32_label="fp32", fp64_label="fp64",
                  warn_threshold=0.001, fail_threshold=0.01):
    results = []
    all_keys = set(d64.keys()) & set(d32.keys())
    missing = set(d64.keys()) - set(d32.keys())
    for key in sorted(all_keys):
        err = compute_error(d32[key], d64[key])
        results.append((key, d64[key], d32[key], err,
                        status_label(err, warn_threshold, fail_threshold)))
    return results, missing


def compare_waveforms(w32, w64, warn_threshold=0.001, fail_threshold=0.01):
    results = {}
    for sig in w64:
        if sig not in w32: continue
        v32_arr, v64_arr = w32[sig], w64[sig]
        n = min(len(v32_arr), len(v64_arr))
        if n == 0: continue
        errors, max_err, max_idx = [], 0.0, 0
        for i in range(n):
            err = compute_error(v32_arr[i], v64_arr[i])
            errors.append(err)
            if err > max_err: max_err, max_idx = err, i
        rms = (sum(e * e for e in errors) / n) ** 0.5
        results[sig] = {"rms": rms, "max": max_err, "max_idx": max_idx, "n": n,
                        "status": status_label(max_err, warn_threshold, fail_threshold)}
    return results


def find_latest_logs():
    logs = sorted(glob.glob(os.path.join(LOG_DIR, "*.log")), key=os.path.getmtime, reverse=True)
    fp32_log, fp64_log = None, None
    for log in logs:
        base = os.path.basename(log)
        if fp32_log is None and "fp32" in base: fp32_log = log
        if fp64_log is None and "fp64" in base: fp64_log = log
        if fp32_log and fp64_log: break
    return fp32_log, fp64_log


def detect_type(text):
    if re.search(r"transient analysis|Index\s+time", text, re.IGNORECASE): return "tran"
    return "dc"


def generate_report(fp32_path_or_text, fp64_path_or_text, text_mode=False,
                    warn_dc=None, fail_dc=None, warn_ac=None, fail_ac=None,
                    warn_tran=None, fail_tran=None, ignore_missing=False):
    """Generate Markdown comparison report. Returns (report_md, summary_dict)."""
    if warn_dc is None: warn_dc = THRESHOLD_WARN_DC
    if fail_dc is None: fail_dc = THRESHOLD_FAIL_DC
    if warn_ac is None: warn_ac = THRESHOLD_WARN_AC
    if fail_ac is None: fail_ac = THRESHOLD_FAIL_AC
    if warn_tran is None: warn_tran = THRESHOLD_WARN_TRAN
    if fail_tran is None: fail_tran = THRESHOLD_FAIL_TRAN

    if text_mode:
        text32, text64 = fp32_path_or_text, fp64_path_or_text
        fp32_label, fp64_label = "FP32", "FP64"
    else:
        with open(fp32_path_or_text) as f: text32 = f.read()
        with open(fp64_path_or_text) as f: text64 = f.read()
        fp32_label = os.path.basename(fp32_path_or_text)
        fp64_label = os.path.basename(fp64_path_or_text)

    all_errors = []
    worst_overall = (0.0, "N/A", "N/A")
    nan_detected = False
    errors_detected = False

    for text, label in [(text32, "FP32"), (text64, "FP64")]:
        if "nan" in text.lower() or "NaN" in text: nan_detected = True
        if re.search(r"error|fatal|timestep too small|singular matrix|iteration limit",
                     text, re.IGNORECASE):
            if not re.search(r"(Node\s+Voltage|Index\s+time|gain_max|period|freq)", text):
                errors_detected = True

    lines = [f"# FP32 vs FP64 Accuracy Report", "",
             f"- **FP32**: `{fp32_label}`", f"- **FP64**: `{fp64_label}`", ""]
    sim_type = detect_type(text64)

    # --- DC Node Voltages ---
    volts32 = parse_op_voltages(text32)
    volts64 = parse_op_voltages(text64)
    worst_v = (0.0, "N/A")
    if volts64:
        lines.extend(["## DC Operating Point", "", "### Node Voltages", "",
                      "| Node | FP64 | FP32 | RelErr | Status |",
                      "|------|------|------|--------|--------|"])
        v_results, v_missing = compare_dicts(volts32, volts64, "V", "fp32", "fp64", warn_dc, fail_dc)
        for key, v64, v32, err, status in v_results:
            lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
            if err > worst_v[0]: worst_v = (err, key)
            all_errors.append((f"v({key})", err, "dc", status))
        if v_missing and not ignore_missing:
            lines.append(f"| *(missing)* | — | — | — | {', '.join(sorted(v_missing))} |")
        lines.append("")
    else:
        lines.extend(["## DC Operating Point", "", "*No node voltages found in output.*", ""])

    # --- Source Currents ---
    currs32 = parse_op_currents(text32)
    currs64 = parse_op_currents(text64)
    currs32_r = {k.replace("#branch", "_I"): v for k, v in currs32.items()}
    currs64_r = {k.replace("#branch", "_I"): v for k, v in currs64.items()}
    if currs64_r:
        lines.extend(["### Source Currents", "",
                      "| Source | FP64 | FP32 | RelErr | Status |",
                      "|--------|------|------|--------|--------|"])
        c_results, c_missing = compare_dicts(currs32_r, currs64_r, "I", "fp32", "fp64", warn_dc, fail_dc)
        for key, v64, v32, err, status in c_results:
            lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
            if err > worst_v[0]: worst_v = (err, key)
            all_errors.append((f"i({key})", err, "dc", status))
        lines.append("")

    # --- Device Parameters ---
    params32 = parse_device_params(text32)
    params64 = parse_device_params(text64)
    if params64:
        lines.extend(["## Device Operating Point Parameters", "",
                      "| Parameter | FP64 | FP32 | RelErr | Status |",
                      "|-----------|------|------|--------|--------|"])
        p_results, p_missing = compare_dicts(params32, params64, "P", "fp32", "fp64", warn_dc, fail_dc)
        for key, v64, v32, err, status in p_results:
            lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
            if err > worst_v[0]: worst_v = (err, key)
            all_errors.append((key, err, "dc", status))
        lines.append("")

    # --- .control Print Values ---
    ctrl32 = parse_control_print(text32)
    ctrl64 = parse_control_print(text64)
    if ctrl64:
        ac_keys = {'gain_max', 'ugbw', 'pm', 'phase_margin', 'bandwidth', 'gain'}
        dc_ctrl64 = {k: v for k, v in ctrl64.items() if k not in ac_keys}
        dc_ctrl32 = {k: v for k, v in ctrl32.items() if k not in ac_keys}
        ac_ctrl64 = {k: v for k, v in ctrl64.items() if k in ac_keys}
        ac_ctrl32 = {k: v for k, v in ctrl32.items() if k in ac_keys}

        if dc_ctrl64:
            lines.extend(["## DC Measured Values", "",
                          "| Metric | FP64 | FP32 | RelErr | Status |",
                          "|--------|------|------|--------|--------|"])
            dd_results, dd_missing = compare_dicts(dc_ctrl32, dc_ctrl64, "DC", "fp32", "fp64", warn_dc, fail_dc)
            for key, v64, v32, err, status in dd_results:
                lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
                if err > worst_v[0]: worst_v = (err, key)
                all_errors.append((key, err, "dc", status))
            lines.append("")

        if ac_ctrl64:
            lines.extend(["## AC Measured Values", "",
                          "| Metric | FP64 | FP32 | RelErr | Status |",
                          "|--------|------|------|--------|--------|"])
            aa_results, aa_missing = compare_dicts(ac_ctrl32, ac_ctrl64, "AC", "fp32", "fp64", warn_ac, fail_ac)
            for key, v64, v32, err, status in aa_results:
                lines.append(f"| `{key}` | {v64:.6e} | {v32:.6e} | {err:.2e} | {status} |")
                all_errors.append((key, err, "ac", status))
            lines.append("")

    # --- Transient Waveforms ---
    worst_t = (0.0, "")
    wave_results = {}
    if sim_type == "tran":
        waves32 = parse_tran_waveforms(text32)
        waves64 = parse_tran_waveforms(text64)
        if waves64:
            lines.extend(["## Transient Waveforms", "",
                          "| Signal | RMS Error | Max Error | Points | Status |",
                          "|--------|-----------|-----------|--------|--------|"])
            wave_results = compare_waveforms(waves32, waves64, warn_tran, fail_tran)
            for sig, r in sorted(wave_results.items()):
                lines.append(f"| `{sig}` | {r['rms']:.2e} | {r['max']:.2e} | {r['n']} | {r['status']} |")
                if r["max"] > worst_t[0]: worst_t = (r["max"], sig)
                all_errors.append((sig, r["max"], "tran", r["status"]))
            lines.append("")

    # --- Summary ---
    if all_errors: worst_overall = max(all_errors, key=lambda x: x[1])
    has_fail = any(s == "FAIL" for _, _, _, s in all_errors)
    has_warn = any(s == "WARN" for _, _, _, s in all_errors)

    if nan_detected and not all_errors: overall = "FAIL"
    elif has_fail: overall = "FAIL"
    elif has_warn: overall = "WARN"
    elif all_errors: overall = "PASS"
    elif errors_detected: overall = "FAIL"
    else: overall = "NODATA"

    n_pass = sum(1 for _, _, _, s in all_errors if s == "PASS")
    n_warn = sum(1 for _, _, _, s in all_errors if s == "WARN")
    n_fail = sum(1 for _, _, _, s in all_errors if s == "FAIL")

    lines.extend(["## Summary", "",
                  f"- **Metrics compared**: {len(all_errors)}",
                  f"- **PASS**: {n_pass} | **WARN**: {n_warn} | **FAIL**: {n_fail}"])
    if worst_overall[1] != "N/A":
        lines.append(f"- **Worst error**: {worst_overall[0]:.2e} on `{worst_overall[1]}` ({worst_overall[2]})")
    if nan_detected: lines.append("- :warning: **NaN detected** in output")
    if errors_detected: lines.append("- :warning: **Convergence errors** detected")
    lines.extend(["", f"**Overall Verdict: {overall}**", ""])

    summary = {
        "verdict": overall, "max_error": worst_overall[0],
        "worst_metric": worst_overall[1], "worst_category": worst_overall[2],
        "n_metrics": len(all_errors), "n_pass": n_pass, "n_warn": n_warn, "n_fail": n_fail,
        "nan_detected": nan_detected, "errors_detected": errors_detected,
        "dc_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "dc"],
        "ac_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "ac"],
        "tran_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "tran"],
    }
    return "\n".join(lines), summary


def verdict_to_exit_code(verdict):
    if verdict == "FAIL": return 1
    elif verdict == "WARN": return 2
    else: return 0


def list_logs():
    logs = sorted(glob.glob(os.path.join(LOG_DIR, "*.log")), key=os.path.getmtime, reverse=True)
    if not logs:
        print("No logs found in", LOG_DIR); return
    print(f"{'Date':<20} {'Size':>8}  File")
    print("-" * 60)
    import datetime
    for log in logs[:30]:
        mtime = os.path.getmtime(log); size = os.path.getsize(log)
        dt = datetime.datetime.fromtimestamp(mtime).strftime("%Y-%m-%d %H:%M:%S")
        print(f"{dt:<20} {size:>8}  {os.path.basename(log)}")


def parse_args():
    args = {"ci": False, "json_summary": False, "ignore_missing": False,
            "warn_dc": None, "fail_dc": None, "warn_ac": None, "fail_ac": None,
            "warn_tran": None, "fail_tran": None, "output": None}
    positional = []
    raw_args = sys.argv[1:]
    i = 0
    while i < len(raw_args):
        arg = raw_args[i]
        if arg == "--ci": args["ci"] = True
        elif arg == "--json-summary": args["json_summary"] = True
        elif arg == "--ignore-missing": args["ignore_missing"] = True
        elif arg in ("--warn-dc", "--fail-dc", "--warn-ac", "--fail-ac", "--warn-tran", "--fail-tran"):
            key = arg[2:].replace("-", "_")
            if i + 1 < len(raw_args): i += 1; args[key] = float(raw_args[i])
        elif arg in ("--threshold-dc", "--threshold-ac", "--threshold-tran"):
            if i + 1 < len(raw_args):
                i += 1
                val = float(raw_args[i])
                if arg == "--threshold-dc": args["warn_dc"] = val; args["fail_dc"] = val * 10
                elif arg == "--threshold-ac": args["warn_ac"] = val; args["fail_ac"] = val * 10
                elif arg == "--threshold-tran": args["warn_tran"] = val; args["fail_tran"] = val * 10
        elif arg in ("-o", "--output"):
            if i + 1 < len(raw_args): i += 1; args["output"] = raw_args[i]
        elif arg in ("--latest", "--list"): positional.append(arg)
        elif not arg.startswith("-"): positional.append(arg)
        i += 1
    return args, positional


if __name__ == "__main__":
    args, positional = parse_args()

    if "--list" in positional:
        list_logs(); sys.exit(0)

    if "--latest" in positional:
        fp32_log, fp64_log = find_latest_logs()
        if not fp32_log: print("ERROR: No fp32 log found"); sys.exit(3)
        if not fp64_log: print("ERROR: No fp64 log found"); sys.exit(3)
    elif len(positional) >= 2:
        fp32_log, fp64_log = positional[0], positional[1]
    else:
        print("Usage: compare_fp.py <fp32_log> <fp64_log> [options]")
        print("       compare_fp.py --latest [options]")
        print("       compare_fp.py --list")
        print("\nOptions:")
        print("  --ci                Exit with non-zero on precision failures")
        print("  --json-summary      Output machine-readable JSON summary")
        print("  --ignore-missing    Don't warn about absent keys")
        print("  --threshold-dc N    Set DC WARN threshold (FAIL = 10x)")
        print("  --threshold-ac N    Set AC WARN threshold")
        print("  --threshold-tran N  Set TRAN WARN threshold")
        print("  --warn-dc N         Set DC WARN threshold explicitly")
        print("  --fail-dc N         Set DC FAIL threshold explicitly")
        print("  -o, --output FILE   Write report to FILE")
        sys.exit(3)

    if not os.path.exists(fp32_log): print(f"ERROR: fp32 log not found: {fp32_log}"); sys.exit(3)
    if not os.path.exists(fp64_log): print(f"ERROR: fp64 log not found: {fp64_log}"); sys.exit(3)

    report_md, summary = generate_report(
        fp32_log, fp64_log,
        warn_dc=args["warn_dc"], fail_dc=args["fail_dc"],
        warn_ac=args["warn_ac"], fail_ac=args["fail_ac"],
        warn_tran=args["warn_tran"], fail_tran=args["fail_tran"],
        ignore_missing=args["ignore_missing"]
    )

    if args["output"]:
        with open(args["output"], "w") as f: f.write(report_md)
        print(f"Report written to {args['output']}")
    else:
        print(report_md)

    if args["json_summary"]:
        print("\n--- JSON SUMMARY ---")
        print(json.dumps(summary))

    if args["ci"]:
        sys.exit(verdict_to_exit_code(summary["verdict"]))
    else:
        sys.exit(0)  # backward compatible
