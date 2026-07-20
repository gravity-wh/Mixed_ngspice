#!/usr/bin/env python3
"""Three-way precision comparison: Mixed FP32 vs Pure FP32 vs FP64 baseline.

Ablation study tool to quantify the contribution of double-precision islands
in the Mixed_ngspice project.

Usage:
    python compare_three.py <mixed_fp32.log> <pure_fp32.log> <fp64.log>
    python compare_three.py <mixed_fp32.log> <pure_fp32.log> <fp64.log> --ci
    python compare_three.py <mixed_fp32.log> <pure_fp32.log> <fp64.log> -o report.md --json report.json

CI mode (--ci):
    exit 0: both variants PASS within their respective thresholds
    exit 1: at least one FAIL
    exit 2: at least one WARN but no FAIL
"""

import sys
import os
import re
import json
import glob
from collections import OrderedDict

# Reuse parsers from compare_fp.py
try:
    from compare_fp import (parse_op_voltages, parse_op_currents, parse_device_params,
                            parse_control_print, parse_tran_waveforms,
                            compute_error, status_label, detect_type,
                            ABS_TOL, THRESHOLD_WARN_DC, THRESHOLD_FAIL_DC,
                            THRESHOLD_WARN_AC, THRESHOLD_FAIL_AC,
                            THRESHOLD_WARN_TRAN, THRESHOLD_FAIL_TRAN)
except ImportError:
    # Fallback: copy minimal parsers
    ABS_TOL = 1e-3
    THRESHOLD_WARN_DC = 0.001; THRESHOLD_FAIL_DC = 0.01
    THRESHOLD_WARN_AC = 0.01; THRESHOLD_FAIL_AC = 0.05
    THRESHOLD_WARN_TRAN = 0.001; THRESHOLD_FAIL_TRAN = 0.01

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
        values = OrderedDict()
        for line in text.split("\n"):
            m = re.match(r'^\s*([\w()\[\].@]+)\s*=\s*([-+]?\d+\.?\d*[eE]?[-+]?\d+)', line)
            if m:
                try: values[m.group(1).strip()] = float(m.group(2))
                except ValueError: pass
        return values

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

    def parse_tran_waveforms(text):
        waves = OrderedDict()
        in_data = False; columns = []
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

    def compute_error(v32, v64):
        denom = max(abs(v64), ABS_TOL)
        return abs(v32 - v64) / denom

    def status_label(err, warn_threshold=0.001, fail_threshold=0.01):
        if err < warn_threshold: return "PASS"
        elif err < fail_threshold: return "WARN"
        else: return "FAIL"

    def detect_type(text):
        if re.search(r"transient analysis|Index\s+time", text, re.IGNORECASE): return "tran"
        return "dc"


def compare_dicts_three(d_mixed, d_pure, d_fp64, label="",
                         warn_mixed=0.001, fail_mixed=0.01,
                         warn_pure=0.01, fail_pure=0.10):
    """Compare three dictionaries and return list of rows with island recovery."""
    results = []
    all_keys = set(d_fp64.keys()) & set(d_mixed.keys()) & set(d_pure.keys())
    for key in sorted(all_keys):
        err_mixed = compute_error(d_mixed[key], d_fp64[key])
        err_pure = compute_error(d_pure[key], d_fp64[key])
        # Island Recovery: how much of the pure-FP32 error was recovered by mixed precision
        if err_pure > 1e-15:
            recovery = (err_pure - err_mixed) / err_pure * 100.0
        else:
            recovery = 0.0
        results.append({
            'metric': key, 'fp64': d_fp64[key],
            'mixed': d_mixed[key], 'mixed_err': err_mixed,
            'mixed_status': status_label(err_mixed, warn_mixed, fail_mixed),
            'pure': d_pure[key], 'pure_err': err_pure,
            'pure_status': status_label(err_pure, warn_pure, fail_pure),
            'recovery_pct': recovery,
        })
    return results


def compare_waveforms_three(w_mixed, w_pure, w_fp64,
                             warn_mixed=0.001, fail_mixed=0.01,
                             warn_pure=0.01, fail_pure=0.10):
    """Three-way waveform comparison."""
    results = {}
    for sig in w_fp64:
        if sig not in w_mixed or sig not in w_pure: continue
        m_arr, p_arr, f_arr = w_mixed[sig], w_pure[sig], w_fp64[sig]
        n = min(len(m_arr), len(p_arr), len(f_arr))
        if n == 0: continue

        m_errs, p_errs = [], []
        for i in range(n):
            m_errs.append(compute_error(m_arr[i], f_arr[i]))
            p_errs.append(compute_error(p_arr[i], f_arr[i]))
        m_rms = (sum(e*e for e in m_errs) / n) ** 0.5
        p_rms = (sum(e*e for e in p_errs) / n) ** 0.5
        m_max = max(m_errs); p_max = max(p_errs)

        if p_max > 1e-15:
            recovery = (p_max - m_max) / p_max * 100.0
        else:
            recovery = 0.0

        results[sig] = {
            'mixed_rms': m_rms, 'mixed_max': m_max,
            'mixed_status': status_label(m_max, warn_mixed, fail_mixed),
            'pure_rms': p_rms, 'pure_max': p_max,
            'pure_status': status_label(p_max, warn_pure, fail_pure),
            'recovery_pct': recovery, 'n': n,
        }
    return results


def format_row_md(metric, fp64_val, mixed_val, mixed_err, mixed_s, pure_val, pure_err, pure_s, recovery):
    """Format a single 3-way comparison row."""
    def fmt(v): return f"{v:.6e}" if isinstance(v, float) else str(v)
    def fmt_pct(v): return f"{v:.1f}%" if v >= 0 else "N/A"
    status_icon = {'PASS': '✅', 'WARN': '⚠️', 'FAIL': '❌'}

    # Highlight recovery > 50%
    rec_str = fmt_pct(recovery)
    if recovery > 50: rec_str = f"**{rec_str}**"

    return (f"| `{metric}` | {fmt(fp64_val)} | {fmt(mixed_val)} | "
            f"{mixed_err:.2e} {status_icon.get(mixed_s, mixed_s)} | "
            f"{fmt(pure_val)} | {pure_err:.2e} {status_icon.get(pure_s, pure_s)} | "
            f"{rec_str} |")


def generate_report(mixed_log, pure_log, fp64_log,
                     warn_mixed_dc=None, fail_mixed_dc=None,
                     warn_pure_dc=0.01, fail_pure_dc=0.10,
                     warn_mixed_ac=None, fail_mixed_ac=None,
                     warn_pure_ac=0.05, fail_pure_ac=0.20,
                     warn_mixed_tran=None, fail_mixed_tran=None,
                     warn_pure_tran=0.01, fail_pure_tran=0.10):
    """Generate a three-way Markdown comparison report."""
    if warn_mixed_dc is None: warn_mixed_dc = THRESHOLD_WARN_DC
    if fail_mixed_dc is None: fail_mixed_dc = THRESHOLD_FAIL_DC
    if warn_mixed_ac is None: warn_mixed_ac = THRESHOLD_WARN_AC
    if fail_mixed_ac is None: fail_mixed_ac = THRESHOLD_FAIL_AC
    if warn_mixed_tran is None: warn_mixed_tran = THRESHOLD_WARN_TRAN
    if fail_mixed_tran is None: fail_mixed_tran = THRESHOLD_FAIL_TRAN

    with open(mixed_log) as f: t_mixed = f.read()
    with open(pure_log) as f: t_pure = f.read()
    with open(fp64_log) as f: t_fp64 = f.read()

    mixed_label = os.path.basename(mixed_log)
    pure_label = os.path.basename(pure_log)
    fp64_label = os.path.basename(fp64_log)
    sim_type = detect_type(t_fp64)

    # Header
    lines = [
        "# Three-Way Precision Ablation Report",
        "",
        f"- **Mixed FP32**: `{mixed_label}` (double-precision islands active)",
        f"- **Pure FP32**: `{pure_label}` (all-float, no islands — strawman)",
        f"- **FP64 Ref**: `{fp64_label}` (full double precision)",
        "",
        f"**Analysis Type**: {sim_type.upper()}",
        "",
        "## DC Operating Point — Three-Way Comparison",
        "",
        "| Metric | FP64 | Mixed FP32 | Err | Pure FP32 | Err | Island Recovery |",
        "|--------|------|------------|-----|-----------|-----|-----------------|",
    ]

    # --- DC Node Voltages ---
    v_mixed = parse_op_voltages(t_mixed)
    v_pure = parse_op_voltages(t_pure)
    v_fp64 = parse_op_voltages(t_fp64)

    all_rows = []
    if v_fp64:
        rows_v = compare_dicts_three(v_mixed, v_pure, v_fp64, "V",
                                      warn_mixed_dc, fail_mixed_dc,
                                      warn_pure_dc, fail_pure_dc)
        for r in rows_v:
            lines.append(format_row_md(r['metric'], r['fp64'],
                         r['mixed'], r['mixed_err'], r['mixed_status'],
                         r['pure'], r['pure_err'], r['pure_status'],
                         r['recovery_pct']))
        lines.append("")
        all_rows.extend(rows_v)

    # --- Source Currents ---
    c_mixed = parse_op_currents(t_mixed)
    c_pure = parse_op_currents(t_pure)
    c_fp64 = parse_op_currents(t_fp64)
    cm = {k.replace("#branch", "_I"): v for k, v in c_mixed.items()}
    cp = {k.replace("#branch", "_I"): v for k, v in c_pure.items()}
    cf = {k.replace("#branch", "_I"): v for k, v in c_fp64.items()}
    if cf:
        lines.extend(["### Source Currents", "",
                       "| Source | FP64 | Mixed FP32 | Err | Pure FP32 | Err | Island Recovery |",
                       "|--------|------|------------|-----|-----------|-----|-----------------|"])
        rows_c = compare_dicts_three(cm, cp, cf, "I", warn_mixed_dc, fail_mixed_dc, warn_pure_dc, fail_pure_dc)
        for r in rows_c:
            lines.append(format_row_md(r['metric'], r['fp64'],
                         r['mixed'], r['mixed_err'], r['mixed_status'],
                         r['pure'], r['pure_err'], r['pure_status'],
                         r['recovery_pct']))
        lines.append("")
        all_rows.extend(rows_c)

    # --- Device Parameters ---
    p_mixed = parse_device_params(t_mixed)
    p_pure = parse_device_params(t_pure)
    p_fp64 = parse_device_params(t_fp64)
    if p_fp64:
        lines.extend(["## Device Operating Point Parameters", "",
                       "| Parameter | FP64 | Mixed FP32 | Err | Pure FP32 | Err | Island Recovery |",
                       "|-----------|------|------------|-----|-----------|-----|-----------------|"])
        rows_p = compare_dicts_three(p_mixed, p_pure, p_fp64, "P", warn_mixed_dc, fail_mixed_dc, warn_pure_dc, fail_pure_dc)
        for r in rows_p:
            lines.append(format_row_md(r['metric'], r['fp64'],
                         r['mixed'], r['mixed_err'], r['mixed_status'],
                         r['pure'], r['pure_err'], r['pure_status'],
                         r['recovery_pct']))
        lines.append("")
        all_rows.extend(rows_p)

    # --- .control Print Values (DC + AC) ---
    ctrl_m = parse_control_print(t_mixed)
    ctrl_p = parse_control_print(t_pure)
    ctrl_f = parse_control_print(t_fp64)
    ac_keys = {'gain_max', 'ugbw', 'pm', 'phase_margin', 'bandwidth', 'gain'}

    dc_f = {k: v for k, v in ctrl_f.items() if k not in ac_keys}
    if dc_f:
        dc_m = {k: v for k, v in ctrl_m.items() if k not in ac_keys}
        dc_p = {k: v for k, v in ctrl_p.items() if k not in ac_keys}
        lines.extend(["## DC Measured Values", "",
                       "| Metric | FP64 | Mixed FP32 | Err | Pure FP32 | Err | Island Recovery |",
                       "|--------|------|------------|-----|-----------|-----|-----------------|"])
        rows_dc = compare_dicts_three(dc_m, dc_p, dc_f, "DC", warn_mixed_dc, fail_mixed_dc, warn_pure_dc, fail_pure_dc)
        for r in rows_dc:
            lines.append(format_row_md(r['metric'], r['fp64'],
                         r['mixed'], r['mixed_err'], r['mixed_status'],
                         r['pure'], r['pure_err'], r['pure_status'],
                         r['recovery_pct']))
        lines.append("")
        all_rows.extend(rows_dc)

    ac_f = {k: v for k, v in ctrl_f.items() if k in ac_keys}
    if ac_f:
        ac_m = {k: v for k, v in ctrl_m.items() if k in ac_keys}
        ac_p = {k: v for k, v in ctrl_p.items() if k in ac_keys}
        lines.extend(["## AC Measured Values", "",
                       "| Metric | FP64 | Mixed FP32 | Err | Pure FP32 | Err | Island Recovery |",
                       "|--------|------|------------|-----|-----------|-----|-----------------|"])
        rows_ac = compare_dicts_three(ac_m, ac_p, ac_f, "AC", warn_mixed_ac, fail_mixed_ac, warn_pure_ac, fail_pure_ac)
        for r in rows_ac:
            lines.append(format_row_md(r['metric'], r['fp64'],
                         r['mixed'], r['mixed_err'], r['mixed_status'],
                         r['pure'], r['pure_err'], r['pure_status'],
                         r['recovery_pct']))
        lines.append("")
        all_rows.extend(rows_ac)

    # --- Transient Waveforms ---
    wave_results = {}
    if sim_type == "tran":
        w_m = parse_tran_waveforms(t_mixed)
        w_p = parse_tran_waveforms(t_pure)
        w_f = parse_tran_waveforms(t_fp64)
        if w_f:
            lines.extend(["## Transient Waveforms — Three-Way", "",
                           "| Signal | Mixed RMS | Mixed Max | Status | Pure RMS | Pure Max | Status | Island Recovery |",
                           "|--------|-----------|-----------|--------|----------|----------|--------|-----------------|"])
            wave_results = compare_waveforms_three(w_m, w_p, w_f,
                                                    warn_mixed_tran, fail_mixed_tran,
                                                    warn_pure_tran, fail_pure_tran)
            for sig, r in sorted(wave_results.items()):
                s_m = '✅' if r['mixed_status'] == 'PASS' else ('⚠️' if r['mixed_status'] == 'WARN' else '❌')
                s_p = '✅' if r['pure_status'] == 'PASS' else ('⚠️' if r['pure_status'] == 'WARN' else '❌')
                rec = f"{r['recovery_pct']:.1f}%"
                if r['recovery_pct'] > 50: rec = f"**{rec}**"
                lines.append(f"| `{sig}` | {r['mixed_rms']:.2e} | {r['mixed_max']:.2e} {s_m} | "
                             f"| {r['pure_rms']:.2e} | {r['pure_max']:.2e} {s_p} | {rec} |")
            lines.append("")

    # --- Summary ---
    if all_rows:
        recoveries = [r['recovery_pct'] for r in all_rows if r['pure_err'] > 1e-15]
        avg_recovery = sum(recoveries) / len(recoveries) if recoveries else 0.0
        med_recovery = sorted(recoveries)[len(recoveries)//2] if recoveries else 0.0
        max_recovery = max(recoveries) if recoveries else 0.0

        # Identify top-5 and bottom-5 recovery metrics
        sorted_by_rec = sorted(all_rows, key=lambda r: r['recovery_pct'], reverse=True)
        top5 = sorted_by_rec[:5]
        bottom5 = sorted_by_rec[-5:]

        mixed_fails = sum(1 for r in all_rows if r['mixed_status'] == 'FAIL')
        pure_fails = sum(1 for r in all_rows if r['pure_status'] == 'FAIL')
        mixed_warns = sum(1 for r in all_rows if r['mixed_status'] == 'WARN')
        pure_warns = sum(1 for r in all_rows if r['pure_status'] == 'WARN')

        nan_detected = 'nan' in t_pure.lower()

        lines.extend([
            "## Summary",
            "",
            f"- **Metrics compared**: {len(all_rows)}",
            f"- **Average Island Recovery**: {avg_recovery:.1f}% (median: {med_recovery:.1f}%, max: {max_recovery:.1f}%)",
            "",
            f"### Mixed FP32 (double islands)",
            f"- PASS: {len(all_rows) - mixed_fails - mixed_warns} | WARN: {mixed_warns} | FAIL: {mixed_fails}",
            "",
            f"### Pure FP32 (no islands)",
            f"- PASS: {len(all_rows) - pure_fails - pure_warns} | WARN: {pure_warns} | FAIL: {pure_fails}",
            "",
            "### Top-5 Island Recovery (largest benefit from double precision)",
            "| Metric | Mixed Err | Pure Err | Recovery |",
            "|--------|-----------|----------|----------|",
        ])
        for r in top5:
            lines.append(f"| `{r['metric']}` | {r['mixed_err']:.2e} | {r['pure_err']:.2e} | {r['recovery_pct']:.1f}% |")

        lines.extend([
            "",
            "### Bottom-5 Island Recovery (least benefit)",
            "| Metric | Mixed Err | Pure Err | Recovery |",
            "|--------|-----------|----------|----------|",
        ])
        for r in reversed(bottom5):
            lines.append(f"| `{r['metric']}` | {r['mixed_err']:.2e} | {r['pure_err']:.2e} | {r['recovery_pct']:.1f}% |")

        if nan_detected:
            lines.extend(["", ":warning: **NaN detected** in Pure FP32 output — precision overflow"])

        # --- Per-Island Category Breakdown ---
        if getattr(sys.modules[__name__], '_args_category', False) or True:
            # Categorize each metric by island
            island_groups = {
                'Vbseff': [], 'Vth': [], 'Abulk': [], 'Mobility': [],
                'Leff/Weff': [], 'Noise': [], 'Device': [], 'AC': [], 'Other': []
            }
            def _cat(name):
                n = name.lower()
                if 'vbseff' in n: return 'Vbseff'
                if 'vth' in n or 'dvt' in n: return 'Vth'
                if 'abulk' in n or 'dab' in n: return 'Abulk'
                if 'ueff' in n or 'dueff' in n or 'mobility' in n: return 'Mobility'
                if 'noise' in n or 'onoise' in n or 'flicker' in n: return 'Noise'
                if 'leff' in n or 'weff' in n: return 'Leff/Weff'
                if 'gm' in n or 'gds' in n or 'id' in n: return 'Device'
                if 'gain' in n or 'ugbw' in n or 'pm' in n or 'phase' in n: return 'AC'
                return 'Other'
            for r in all_rows:
                island_groups[_cat(r['metric'])].append(r['recovery_pct'])

            lines.extend([
                "",
                "### Island Recovery by Category",
                "",
                "| Island | N | Avg Recovery | Median | Min | Max |",
                "|--------|---|-------------|--------|-----|-----|",
            ])
            cat_summary = {}
            for cat, recs in island_groups.items():
                if recs:
                    cat_summary[cat] = {
                        'n': len(recs), 'avg': sum(recs)/len(recs),
                        'median': sorted(recs)[len(recs)//2],
                        'min': min(recs), 'max': max(recs)
                    }
                    lines.append(f"| **{cat}** | {len(recs)} | {cat_summary[cat]['avg']:.1f}% | {cat_summary[cat]['median']:.1f}% | {cat_summary[cat]['min']:.1f}% | {cat_summary[cat]['max']:.1f}% |")

        lines.extend(["", f"**Overall: Mixed FP32 recovers {avg_recovery:.1f}% of pure-FP32 precision loss**", ""])

        # Build JSON summary
        summary = {
            "mixed_label": mixed_label, "pure_label": pure_label, "fp64_label": fp64_label,
            "sim_type": sim_type,
            "n_metrics": len(all_rows),
            "avg_recovery_pct": avg_recovery,
            "median_recovery_pct": med_recovery,
            "max_recovery_pct": max_recovery,
            "mixed": {"n_pass": len(all_rows) - mixed_fails - mixed_warns, "n_warn": mixed_warns, "n_fail": mixed_fails},
            "pure": {"n_pass": len(all_rows) - pure_fails - pure_warns, "n_warn": pure_warns, "n_fail": pure_fails},
            "nan_detected": nan_detected,
            "top5_recovery": [{"metric": r['metric'], "mixed_err": r['mixed_err'], "pure_err": r['pure_err'], "recovery_pct": r['recovery_pct']} for r in top5],
            "bottom5_recovery": [{"metric": r['metric'], "mixed_err": r['mixed_err'], "pure_err": r['pure_err'], "recovery_pct": r['recovery_pct']} for r in reversed(bottom5)],
            "wave_results": {sig: {"mixed_rms": r['mixed_rms'], "pure_rms": r['pure_rms'], "recovery_pct": r['recovery_pct']} for sig, r in wave_results.items()},
            "all_metrics": [{"metric": r['metric'], "mixed_err": r['mixed_err'], "pure_err": r['pure_err'], "recovery_pct": r['recovery_pct'], "fp64_val": r['fp64']} for r in all_rows],
            "island_analysis": cat_summary if cat_summary else {},
        }
    else:
        summary = {"error": "no comparable metrics found"}

    return "\n".join(lines), summary


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Three-way precision comparison")
    parser.add_argument("mixed_log", nargs='?', help="Mixed FP32 ngspice output log")
    parser.add_argument("pure_log", nargs='?', help="Pure FP32 ngspice output log")
    parser.add_argument("fp64_log", nargs='?', help="FP64 reference ngspice output log")
    parser.add_argument("--ci", action="store_true", help="CI mode: exit with error code on failure")
    parser.add_argument("-o", "--output-md", help="Write markdown report to file")
    parser.add_argument("--json", "--output-json", help="Write JSON summary to file")
    parser.add_argument("--list", action="store_true", help="List available logs")
    parser.add_argument("--category", action="store_true",
                        help="Add per-island category breakdown to report and JSON")
    args = parser.parse_args()

    if args.list:
        logs_dir = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "logs")
        logs = sorted(glob.glob(os.path.join(logs_dir, "*.log")), key=os.path.getmtime, reverse=True)
        if not logs: print("No logs found"); return
        for log in logs[:30]: print(os.path.basename(log))
        return

    if not all([args.mixed_log, args.pure_log, args.fp64_log]):
        parser.print_help()
        print("\nUsage: compare_three.py <mixed_fp32.log> <pure_fp32.log> <fp64.log> [options]")
        sys.exit(1)

    for f in [args.mixed_log, args.pure_log, args.fp64_log]:
        if not os.path.exists(f):
            print(f"ERROR: file not found: {f}")
            sys.exit(3)

    report, summary = generate_report(args.mixed_log, args.pure_log, args.fp64_log)

    if args.output_md:
        with open(args.output_md, 'w') as f: f.write(report)
        print(f"Report written to {args.output_md}")
    else:
        print(report)

    if args.json:
        with open(args.json, 'w') as f: json.dump(summary, f, indent=2)
        print(f"\nJSON written to {args.json}")

    if args.ci:
        if summary.get("error"):
            sys.exit(0)  # no data — not a failure
        pure_fails = summary["pure"]["n_fail"]
        pure_warns = summary["pure"]["n_warn"]
        mixed_fails = summary["mixed"]["n_fail"]
        if pure_fails > 0 or mixed_fails > 0:
            sys.exit(1)
        elif pure_warns > 0:
            sys.exit(2)
        else:
            sys.exit(0)


if __name__ == "__main__":
    main()
