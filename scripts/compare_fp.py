#!/usr/bin/env python3
"""Compare FP32 vs FP64 simulation outputs — ngspice and float_spice.

Supports DC operating point analysis, AC measurements, transient waveform comparison,
and cross-format float_spice vs ngspice reference comparison (P4.3).
Outputs a Markdown-formatted accuracy report.

Usage:
    python compare_fp.py <fp32_log> <fp64_log>
    python compare_fp.py <fp32_log> <fp64_log> --ci
    python compare_fp.py <fp32_log> <fp64_log> --ci --json-summary
    python compare_fp.py --latest          # compare latest logs
    python compare_fp.py --list            # list available logs
    python compare_fp.py float_spice.log ngspice_ref.log  # auto-detected

CI mode (--ci):
    Exits with non-zero code on precision failures.
    exit 0: all metrics PASS or no comparable data
    exit 1: at least one metric FAIL (exceeds --fail-* threshold)
    exit 2: at least one metric WARN but no FAIL

float_spice mode:
    When one input is float_spice output (detected by "=== float_spice" header),
    cross-format comparison is used automatically.  Node voltages, source currents,
    device parameters, .control print values, DC sweeps, and TRAN waveforms are
    extracted from both formats and compared by normalized metric name.
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


# ===== Float-Spice Output Parsers (P4.3) =====

def parse_fs_header(text):
    """Detect float_spice output and extract version info."""
    m = re.search(r'=== float_spice (v\S+)', text)
    if m: return m.group(1)
    return None

def parse_fs_op_voltages(text):
    """Parse float_spice 'Node Voltages' section.
    Format:
      Node Voltages:
      Node         Voltage
      ----         -------
      0            0.000000
      VDD          1.100000
    """
    volts = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Node\s+Voltage", line): in_table = True; continue
        if in_table and re.match(r"\s*----", line): continue
        if in_table:
            if re.match(r"\s*$", line) or "Source Currents" in line or "Device Param" in line or "---" in line or "[Done]" in line:
                in_table = False; continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    volts[parts[0]] = float(parts[1])
                except ValueError: pass
    return volts

def parse_fs_op_currents(text):
    """Parse float_spice 'Source Currents' section.
    Format:
      Source Currents:
      Source       Current
      ------       -------
      VDD          -1.234e-05
    """
    currs = OrderedDict()
    in_table = False
    for line in text.split("\n"):
        if re.match(r"\s*Source\s+Current", line): in_table = True; continue
        if in_table and re.match(r"\s*----", line): continue
        if in_table:
            if re.match(r"\s*$", line) or "Device Param" in line or "---" in line or "[Done]" in line:
                in_table = False; continue
            parts = line.split()
            if len(parts) >= 2:
                try:
                    currs[parts[0]] = float(parts[1])
                except ValueError: pass
    return currs

def parse_fs_device_params(text):
    """Parse float_spice 'Device Parameters' section.
    Format:
      device M1               Ids=1.234e-05  gm=1.234e-04  gds=1.234e-06  vth=0.523456  vdsat=0.234567
    """
    params = OrderedDict()
    for line in text.split("\n"):
        m = re.match(r"^\s*device\s+(\S+)", line)
        if m:
            dev = m.group(1)
            # Parse key=value pairs on this line
            for kv in re.finditer(r'(\w+)=([-+]?\d+\.?\d*[eE]?[-+]?\d*)', line):
                try:
                    params[f"{dev}_{kv.group(1)}"] = float(kv.group(2))
                except ValueError: pass
    return params

def parse_fs_control_print(text):
    """Parse float_spice '.control print' output section.
    Format:
      --- Requested output (.control print) ---
      v(d) = 0.523456
      i(vd) = -1.234e-05
    """
    values = OrderedDict()
    in_section = False
    for line in text.split("\n"):
        if "Requested output" in line and "control print" in line:
            in_section = True; continue
        if in_section:
            if re.match(r"\s*$", line) or "Node Voltages" in line or "[Done]" in line:
                in_section = False; continue
            m = re.match(r'^\s*([vi])\((\S+)\)\s*=\s*([-+]?\d+\.?\d*[eE]?[-+]?\d*)', line)
            if m:
                try:
                    values[f"{m.group(1)}({m.group(2)})"] = float(m.group(3))
                except ValueError: pass
    return values

def parse_fs_dc_sweep(text):
    """Parse float_spice 'DC Sweep' output.
    Format:
      DC Sweep: VD from 0.0000 to 1.1000 step 0.0100
      Sweep     V(D)        ...
      0.0000    0.000000    ...  # 15 iters
    Returns: {column_name: [values], ...} with 'sweep' as the sweep variable values.
    """
    sweep = OrderedDict()
    columns = []
    in_header = False
    for line in text.split("\n"):
        if "DC Sweep:" in line or "Nested DC Sweep:" in line:
            in_header = True; continue
        if in_header and re.match(r"Sweep\s", line):
            columns = line.split()
            # Remove trailing comment tokens like '#', '15', 'iters'
            while columns and (columns[-1].startswith('#') or columns[-1].isdigit() or columns[-1] == 'iters'):
                columns.pop()
            for col in columns: sweep[col] = []
            in_header = False
            continue
        if columns:
            parts = line.split()
            # Remove trailing '#', 'N', 'iters' tokens
            while parts and (parts[-1].startswith('#') or parts[-1].isdigit() or parts[-1] == 'iters'):
                parts.pop()
            if len(parts) >= len(columns):
                for i, col in enumerate(columns):
                    if i < len(parts):
                        try: sweep[col].append(float(parts[i]))
                        except ValueError: pass
            elif re.match(r"\s*$", line) or "[Done]" in line or "DC Operating Point" in line:
                columns = []  # end of sweep data
    return sweep

def parse_fs_tran(text):
    """Parse float_spice TRAN output.
    Format:
      Index   time       V(D)        ...
      1       1.000e-09  0.523456    ...  # 15 iters
    """
    waves = OrderedDict()
    columns = []
    for line in text.split("\n"):
        if re.match(r"Index\s+time\b", line):
            columns = line.split()
            # Remove trailing comment tokens
            while columns and (columns[-1].startswith('#') or columns[-1].isdigit() or columns[-1] == 'iters'):
                columns.pop()
            for col in columns[2:]: waves[col] = []
            continue
        if columns:
            parts = line.split()
            while parts and (parts[-1].startswith('#') or parts[-1].isdigit() or parts[-1] == 'iters'):
                parts.pop()
            if len(parts) >= 2:
                for i, col in enumerate(columns[2:]):
                    if i + 2 < len(parts):
                        try: waves[col].append(float(parts[i + 2]))
                        except ValueError: pass
            elif re.match(r"\s*$", line) or "[Done]" in line:
                columns = []
    return waves

def parse_fs_convergence(text):
    """Extract DC convergence iteration count from float_spice output."""
    m = re.search(r'DC convergence:\s*(\d+)\s*iterations', text)
    if m: return int(m.group(1))
    m = re.search(r'DC OP:\s*(\d+)\s*iterations', text)
    if m: return int(m.group(1))
    return None

def detect_fs_format(text):
    """Detect if text is float_spice output format."""
    return bool(re.search(r'=== float_spice\b', text))

def normalize_node_name(name):
    """Normalize node/source names for cross-format comparison.
    - Case-insensitive
    - Strip trailing/leading whitespace
    - Handle ngspice '#branch' suffix for source currents
    """
    name = name.strip()
    name = re.sub(r'#branch$', '', name, flags=re.IGNORECASE)
    return name.lower()

def match_dict_keys(d_fs, d_ref, normalizer=normalize_node_name):
    """Build a mapping from float_spice keys to reference keys.
    Returns list of (fs_key, ref_key) pairs that match.
    """
    ref_map = {normalizer(k): k for k in d_ref.keys()}
    pairs = []
    for fs_key in d_fs.keys():
        nkey = normalizer(fs_key)
        if nkey in ref_map:
            pairs.append((fs_key, ref_map[nkey]))
    return pairs


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


def _compare_section_fs(d_fs, d_ref, section_label, category, warn_th, fail_th,
                         all_errors, worst_v, lines, fs_label="float_spice", ref_label="ref"):
    """Compare a float_spice dict against a reference dict using normalized key matching.
    Appends rows to `lines` and updates `all_errors` and `worst_v` in-place."""
    pairs = match_dict_keys(d_fs, d_ref)
    if not pairs: return
    lines.extend([f"### {section_label}", "",
                  f"| Metric | {ref_label} | {fs_label} | RelErr | Status |",
                  "|--------|------|------|--------|--------|"])
    matched_ref = set()
    for fs_key, ref_key in pairs:
        v_fs, v_ref = d_fs[fs_key], d_ref[ref_key]
        err = compute_error(v_fs, v_ref)
        status = status_label(err, warn_th, fail_th)
        lines.append(f"| `{fs_key}` | {v_ref:.6e} | {v_fs:.6e} | {err:.2e} | {status} |")
        if err > worst_v[0]: worst_v[:] = (err, fs_key)
        all_errors.append((fs_key, err, category, status))
        matched_ref.add(ref_key)
    missing = set(d_ref.keys()) - matched_ref
    if missing:
        lines.append(f"| *(missing)* | — | — | — | {', '.join(sorted(missing))} |")
    lines.append("")


def generate_fs_report(text_fs, text_ref, fs_label="float_spice", ref_label="reference",
                       warn_dc=None, fail_dc=None, warn_ac=None, fail_ac=None,
                       warn_tran=None, fail_tran=None):
    """Generate Markdown report comparing float_spice output against ngspice reference.
    Returns (report_md, summary_dict)."""
    if warn_dc is None: warn_dc = THRESHOLD_WARN_DC
    if fail_dc is None: fail_dc = THRESHOLD_FAIL_DC
    if warn_ac is None: warn_ac = THRESHOLD_WARN_AC
    if fail_ac is None: fail_ac = THRESHOLD_FAIL_AC
    if warn_tran is None: warn_tran = THRESHOLD_WARN_TRAN
    if fail_tran is None: fail_tran = THRESHOLD_FAIL_TRAN

    fs_ver = parse_fs_header(text_fs)
    all_errors = []
    worst_v = [0.0, "N/A"]
    nan_detected = False
    errors_detected = False

    # NaN / error detection
    for text, label in [(text_fs, fs_label), (text_ref, ref_label)]:
        text_clean = re.sub(r'<<NAN[^\n]*\n?', '', text)
        if "nan" in text_clean.lower() or "NaN" in text_clean:
            nan_detected = True
        if re.search(r"error|fatal|timestep too small|singular matrix|iteration limit",
                     text_clean, re.IGNORECASE):
            if not re.search(r"(Node\s+Voltage|Index\s+time|gain_max|period|freq)", text_clean):
                errors_detected = True

    lines = [f"# float_spice vs Reference Accuracy Report", "",
             f"- **float_spice**: `{fs_label}` (v{fs_ver or '?'})",
             f"- **Reference**: `{ref_label}`", ""]

    # --- Convergence ---
    fs_iters = parse_fs_convergence(text_fs)
    if fs_iters is not None:
        lines.extend([f"- **DC iterations**: {fs_iters}", ""])

    # --- DC Node Voltages ---
    fs_volts = parse_fs_op_voltages(text_fs)
    ref_volts = parse_op_voltages(text_ref)
    if not ref_volts:
        # Try control print format as fallback
        ref_ctrl = parse_control_print(text_ref)
        ref_volts = {k: v for k, v in ref_ctrl.items() if k.startswith('v(')}
        ref_volts = {k[2:-1]: v for k, v in ref_volts.items()}  # v(D) → D

    if fs_volts and ref_volts:
        lines.extend(["## DC Operating Point", ""])
        _compare_section_fs(fs_volts, ref_volts, "Node Voltages", "dc",
                            warn_dc, fail_dc, all_errors, worst_v, lines,
                            fs_label, ref_label)

    # --- Source Currents ---
    fs_currs = parse_fs_op_currents(text_fs)
    ref_currs = parse_op_currents(text_ref)
    ref_currs = {re.sub(r'#branch$', '', k, flags=re.IGNORECASE): v
                 for k, v in ref_currs.items()}
    # Also try control print
    ref_ctrl2 = parse_control_print(text_ref)
    ref_currs_i = {k[2:-1]: v for k, v in ref_ctrl2.items() if k.startswith('i(')}
    ref_currs.update(ref_currs_i)

    if fs_currs and ref_currs:
        _compare_section_fs(fs_currs, ref_currs, "Source Currents", "dc",
                            warn_dc, fail_dc, all_errors, worst_v, lines,
                            fs_label, ref_label)

    # --- Device Parameters ---
    fs_params = parse_fs_device_params(text_fs)
    ref_params = parse_device_params(text_ref)
    if fs_params and ref_params:
        _compare_section_fs(fs_params, ref_params, "Device Operating Point Parameters", "dc",
                            warn_dc, fail_dc, all_errors, worst_v, lines,
                            fs_label, ref_label)

    # --- .control Print Values ---
    fs_ctrl = parse_fs_control_print(text_fs)
    ref_ctrl3 = parse_control_print(text_ref)
    if fs_ctrl and ref_ctrl3:
        _compare_section_fs(fs_ctrl, ref_ctrl3, "Measured Values (.control print)", "dc",
                            warn_dc, fail_dc, all_errors, worst_v, lines,
                            fs_label, ref_label)

    # --- DC Sweep ---
    fs_sweep = parse_fs_dc_sweep(text_fs)
    if fs_sweep:
        lines.extend(["## DC Sweep", "",
                      f"| Column | Points | Min | Max |",
                      f"|--------|--------|-----|-----|"])
        for col, vals in fs_sweep.items():
            if vals:
                lines.append(f"| `{col}` | {len(vals)} | {min(vals):.4e} | {max(vals):.4e} |")
        lines.append("")

    # --- TRAN ---
    fs_tran = parse_fs_tran(text_fs)
    ref_tran = parse_tran_waveforms(text_ref) if detect_type(text_ref) == "tran" else {}
    if fs_tran and ref_tran:
        lines.extend(["## Transient Waveforms", "",
                      "| Signal | RMS Error | Max Error | Points | Status |",
                      "|--------|-----------|-----------|--------|--------|"])
        wave_results = compare_waveforms(fs_tran, ref_tran, warn_tran, fail_tran)
        worst_t = [0.0, ""]
        for sig, r in sorted(wave_results.items()):
            lines.append(f"| `{sig}` | {r['rms']:.2e} | {r['max']:.2e} | {r['n']} | {r['status']} |")
            if r["max"] > worst_t[0]: worst_t = [r["max"], sig]
            all_errors.append((sig, r["max"], "tran", r["status"]))
        if worst_t[0] > worst_v[0]: worst_v[:] = worst_t
        lines.append("")
    elif fs_tran:
        lines.extend(["## Transient Waveforms", "",
                      f"| Signal | Points | Min | Max |",
                      f"|--------|--------|-----|-----|"])
        for col, vals in fs_tran.items():
            if vals:
                lines.append(f"| `{col}` | {len(vals)} | {min(vals):.4e} | {max(vals):.4e} |")
        lines.append("")

    # --- Summary ---
    worst_overall = max(all_errors, key=lambda x: x[1]) if all_errors else ("N/A", 0.0, "N/A")
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
    if worst_overall[0] != "N/A":
        lines.append(f"- **Worst error**: {worst_overall[1]:.2e} on `{worst_overall[0]}` ({worst_overall[2]})")
    if nan_detected: lines.append("- :warning: **NaN detected** in output")
    if errors_detected: lines.append("- :warning: **Convergence errors** detected")
    lines.extend(["", f"**Overall Verdict: {overall}**", ""])

    summary = {
        "verdict": overall, "max_error": worst_overall[1],
        "worst_metric": worst_overall[0], "worst_category": worst_overall[2],
        "n_metrics": len(all_errors), "n_pass": n_pass, "n_warn": n_warn, "n_fail": n_fail,
        "nan_detected": nan_detected, "errors_detected": errors_detected,
        "dc_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "dc"],
        "ac_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "ac"],
        "tran_errors": [{"metric": m, "error": e, "status": s} for m, e, c, s in all_errors if c == "tran"],
        "float_spice_version": fs_ver,
    }
    return "\n".join(lines), summary


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
        with open(fp32_path_or_text, encoding='utf-8', errors='replace') as f: text32 = f.read()
        with open(fp64_path_or_text, encoding='utf-8', errors='replace') as f: text64 = f.read()
        fp32_label = os.path.basename(fp32_path_or_text)
        fp64_label = os.path.basename(fp64_path_or_text)

    # P4.3: Auto-detect float_spice format → cross-format comparison
    fs32 = detect_fs_format(text32)
    fs64 = detect_fs_format(text64)
    if fs32 and not fs64:
        return generate_fs_report(text32, text64, fp32_label, fp64_label,
                                  warn_dc, fail_dc, warn_ac, fail_ac, warn_tran, fail_tran)
    elif fs64 and not fs32:
        return generate_fs_report(text64, text32, fp64_label, fp32_label,
                                  warn_dc, fail_dc, warn_ac, fail_ac, warn_tran, fail_tran)
    elif fs32 and fs64:
        # Both float_spice — compare directly using float_spice parsers
        pass  # fall through to standard comparison (both are float_spice format)

    all_errors = []
    worst_overall = ("N/A", 0.0, "N/A")  # (metric_name, error_value, category)
    nan_detected = False
    errors_detected = False

    for text, label in [(text32, "FP32"), (text64, "FP64")]:
        # Filter out model parameter listings that contain <<NAN for unused params
        text_clean = re.sub(r'<<NAN[^\n]*\n?', '', text)
        if "nan" in text_clean.lower() or "NaN" in text_clean: nan_detected = True
        if re.search(r"error|fatal|timestep too small|singular matrix|iteration limit",
                     text_clean, re.IGNORECASE):
            if not re.search(r"(Node\s+Voltage|Index\s+time|gain_max|period|freq)", text_clean):
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
    if worst_overall[0] != "N/A":
        lines.append(f"- **Worst error**: {worst_overall[1]:.2e} on `{worst_overall[0]}` ({worst_overall[2]})")
    if nan_detected: lines.append("- :warning: **NaN detected** in output")
    if errors_detected: lines.append("- :warning: **Convergence errors** detected")
    lines.extend(["", f"**Overall Verdict: {overall}**", ""])

    summary = {
        "verdict": overall, "max_error": worst_overall[1],
        "worst_metric": worst_overall[0], "worst_category": worst_overall[2],
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
            "float_spice": False,
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
        elif arg == "--float-spice": args["float_spice"] = True
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
        print("       compare_fp.py float_spice.log ngspice_ref.log  # auto-detected")
        print("\nOptions:")
        print("  --ci                Exit with non-zero on precision failures")
        print("  --json-summary      Output machine-readable JSON summary")
        print("  --ignore-missing    Don't warn about absent keys")
        print("  --float-spice       Force first argument as float_spice output")
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
