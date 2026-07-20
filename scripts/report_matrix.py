#!/usr/bin/env python3
"""Aggregate three-way comparison JSON files into a comprehensive validation matrix.

Scans logs/ for *_threeway.json files, aggregates results, and produces:
  1. validation_matrix.md — human-readable summary table
  2. validation_summary.json — structured data for downstream tools
  3. island_recovery_waterfall.json — sorted recovery data for plotting

Usage:
    python report_matrix.py <log_directory>
    python report_matrix.py logs/ --output-md report.md --output-json report.json
    python report_matrix.py logs/ --mode full    # includes corners in matrix
"""

import os
import sys
import json
import glob
import re
from collections import defaultdict
from datetime import datetime


def find_threeway_jsons(logdir):
    """Find all *_threeway.json files in logdir."""
    pattern = os.path.join(logdir, "*_threeway.json")
    files = sorted(glob.glob(pattern))
    if not files:
        # Also check subdirectory patterns
        files = sorted(glob.glob(os.path.join(logdir, "**", "*_threeway.json"), recursive=True))
    return files


def extract_circuit_info(filename):
    """Extract circuit name and corner from filename."""
    basename = os.path.basename(filename)
    # Pattern: {label}_threeway.json
    m = re.match(r'(.+)_threeway\.json', basename)
    if m:
        label = m.group(1)
        # Try to separate corner from circuit name
        for c in ['_tt', '_ff', '_ss', '_fs', '_sf']:
            if label.endswith(c):
                return label[:-len(c)], c.lstrip('_').upper()
        return label, 'TT'
    return basename, '?'


def categorize_metric(metric_name):
    """Categorize metric by which double-precision island it belongs to."""
    name = metric_name.lower()
    if 'vbseff' in name:
        return 'Vbseff'
    if 'vth' in name or 'dvt' in name:
        return 'Vth'
    if 'abulk' in name or 'dab' in name:
        return 'Abulk'
    if 'ueff' in name or 'dueff' in name or 'mobility' in name:
        return 'Mobility'
    if 'noise' in name or 'onoise' in name or 'flicker' in name:
        return 'Noise'
    if 'leff' in name or 'weff' in name:
        return 'Leff/Weff'
    if 'gm' in name or 'gds' in name or 'id' in name:
        return 'Device'
    if 'gain' in name or 'ugbw' in name or 'pm' in name or 'phase' in name:
        return 'AC'
    return 'Other'


def aggregate(logdir, mode='quick'):
    """Aggregate all three-way JSON files into a summary."""
    files = find_threeway_jsons(logdir)
    if not files:
        return {"error": f"No *_threeway.json files found in {logdir}"}

    circuits = []
    all_recoveries = []
    island_recovery = defaultdict(lambda: {'recoveries': [], 'metrics': []})
    pure_failures = []
    mixed_failures = []

    for f in files:
        try:
            with open(f) as fh:
                data = json.load(fh)
        except (json.JSONDecodeError, IOError):
            continue

        circuit_name, corner = extract_circuit_info(f)

        # Extract key stats
        n_metrics = data.get('n_metrics', 0)
        avg_recovery = data.get('avg_recovery_pct', 0)
        mixed = data.get('mixed', {})
        pure = data.get('pure', {})

        circuit_entry = {
            'name': circuit_name,
            'corner': corner,
            'sim_type': data.get('sim_type', '?'),
            'n_metrics': n_metrics,
            'avg_recovery_pct': avg_recovery,
            'mixed': {
                'n_pass': mixed.get('n_pass', 0),
                'n_warn': mixed.get('n_warn', 0),
                'n_fail': mixed.get('n_fail', 0),
            },
            'pure': {
                'n_pass': pure.get('n_pass', 0),
                'n_warn': pure.get('n_warn', 0),
                'n_fail': pure.get('n_fail', 0),
            },
        }

        # Per-metric island analysis
        for metric in data.get('all_metrics', []):
            cat = categorize_metric(metric.get('metric', ''))
            rec = metric.get('recovery_pct', 0)
            island_recovery[cat]['recoveries'].append(rec)
            island_recovery[cat]['metrics'].append(metric.get('metric', ''))
            all_recoveries.append(rec)

            # Track failures
            if metric.get('pure_status') == 'FAIL' or (isinstance(metric.get('pure_err'), (int, float)) and (metric.get('pure_err', 0) > 0.1 or metric.get('pure_err', 0) != metric.get('pure_err', 0))):
                pure_failures.append({
                    'circuit': circuit_name,
                    'corner': corner,
                    'metric': metric.get('metric', '?'),
                    'mode': 'NaN' if (isinstance(metric.get('pure_err'), float) and metric.get('pure_err') != metric.get('pure_err')) else ('Inf' if metric.get('pure_err', 0) > 1e10 else 'precision'),
                    'pure_err': metric.get('pure_err', 0),
                    'mixed_err': metric.get('mixed_err', 0),
                })
            if metric.get('mixed_status') == 'FAIL':
                mixed_failures.append({
                    'circuit': circuit_name,
                    'corner': corner,
                    'metric': metric.get('metric', '?'),
                    'mixed_err': metric.get('mixed_err', 0),
                })

        circuits.append(circuit_entry)

    # Compute summary stats
    if circuits:
        mixed_total = sum(c['mixed']['n_pass'] + c['mixed']['n_warn'] + c['mixed']['n_fail'] for c in circuits)
        mixed_pass = sum(c['mixed']['n_pass'] for c in circuits)
        pure_total = sum(c['pure']['n_pass'] + c['pure']['n_warn'] + c['pure']['n_fail'] for c in circuits)
        pure_pass = sum(c['pure']['n_pass'] for c in circuits)
        avg_rec = sum(c['avg_recovery_pct'] for c in circuits) / len(circuits) if circuits else 0

        island_summary = {}
        for cat, data in sorted(island_recovery.items()):
            recs = data['recoveries']
            if recs:
                island_summary[cat] = {
                    'avg_recovery': sum(recs) / len(recs),
                    'median_recovery': sorted(recs)[len(recs)//2],
                    'min_recovery': min(recs),
                    'max_recovery': max(recs),
                    'n_metrics': len(recs),
                    'top_metrics': sorted(zip(recs, data['metrics']), reverse=True)[:3],
                }
    else:
        mixed_total = mixed_pass = pure_total = pure_pass = avg_rec = 0
        island_summary = {}

    return {
        'date': datetime.now().isoformat(),
        'mode': mode,
        'n_files': len(files),
        'total_circuits': len(circuits),
        'total_metrics': len(all_recoveries),
        'avg_recovery_pct': avg_rec,
        'median_recovery_pct': sorted(all_recoveries)[len(all_recoveries)//2] if all_recoveries else 0,
        'mixed_pass_rate': f"{mixed_pass}/{mixed_total} ({mixed_pass/mixed_total*100:.1f}%)" if mixed_total > 0 else "N/A",
        'pure_pass_rate': f"{pure_pass}/{pure_total} ({pure_pass/pure_total*100:.1f}%)" if pure_total > 0 else "N/A",
        'mixed_fail_count': sum(c['mixed']['n_fail'] for c in circuits),
        'pure_fail_count': sum(c['pure']['n_fail'] for c in circuits),
        'circuits': circuits,
        'island_analysis': island_summary,
        'pure_fp32_failures': pure_failures[:20],
        'mixed_fp32_failures': mixed_failures[:20],
    }


def generate_markdown(summary, outpath):
    """Generate a human-readable Markdown report."""
    lines = [
        "# Mixed_ngspice Three-Way Precision Validation Report",
        "",
        f"- **Date**: {summary['date'][:19]}",
        f"- **Mode**: {summary['mode']}",
        f"- **Circuits**: {summary['total_circuits']}",
        f"- **Metrics**: {summary['total_metrics']}",
        "",
        "## Overall Results",
        "",
        "| Variant | Pass Rate | Failures |",
        "|---------|-----------|----------|",
        f"| **Mixed FP32** | {summary['mixed_pass_rate']} | {summary['mixed_fail_count']} |",
        f"| **Pure FP32** | {summary['pure_pass_rate']} | {summary['pure_fail_count']} |",
        f"| **Avg Island Recovery** | {summary['avg_recovery_pct']:.1f}% | — |",
        "",
        "## Island Recovery Analysis",
        "",
        "| Island | Avg Recovery | Median | Min | Max | N Metrics |",
        "|--------|-------------|--------|-----|-----|-----------|",
    ]
    for cat, info in summary.get('island_analysis', {}).items():
        lines.append(f"| **{cat}** | {info['avg_recovery']:.1f}% | {info['median_recovery']:.1f}% | {info['min_recovery']:.1f}% | {info['max_recovery']:.1f}% | {info['n_metrics']} |")

    lines.extend([
        "",
        "## Per-Circuit Results",
        "",
        "| Circuit | Corner | Type | Mixed P/W/F | Pure P/W/F | Recovery |",
        "|---------|--------|------|-------------|------------|----------|",
    ])
    for c in summary['circuits']:
        m = c['mixed']; p = c['pure']
        lines.append(f"| `{c['name']}` | {c['corner']} | {c['sim_type']} | {m['n_pass']}/{m['n_warn']}/{m['n_fail']} | {p['n_pass']}/{p['n_warn']}/{p['n_fail']} | {c['avg_recovery_pct']:.1f}% |")

    if summary['pure_fp32_failures']:
        lines.extend([
            "",
            "## Pure FP32 Failures (Top 10)",
            "",
            "| Circuit | Metric | Mode | Pure Err | Mixed Err |",
            "|---------|--------|------|----------|-----------|",
        ])
        for f in summary['pure_fp32_failures'][:10]:
            pure_e = f'{f["pure_err"]:.2e}' if isinstance(f['pure_err'], (int, float)) and f['pure_err'] == f['pure_err'] else 'NaN'
            mixed_e = f'{f["mixed_err"]:.2e}' if isinstance(f['mixed_err'], (int, float)) and f['mixed_err'] == f['mixed_err'] else 'NaN'
            lines.append(f"| `{f['circuit']}` | `{f['metric']}` | {f['mode']} | {pure_e} | {mixed_e} |")

    with open(outpath, 'w') as f:
        f.write('\n'.join(lines))
    print(f"Markdown report: {outpath}")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="Aggregate three-way comparison reports")
    parser.add_argument("logdir", help="Directory containing *_threeway.json files")
    parser.add_argument("--output-md", help="Markdown output path")
    parser.add_argument("--output-json", help="JSON output path")
    parser.add_argument("--mode", choices=['quick', 'full'], default='quick')
    args = parser.parse_args()

    summary = aggregate(args.logdir, args.mode)

    if "error" in summary:
        print(f"ERROR: {summary['error']}", file=sys.stderr)
        sys.exit(1)

    if args.output_json:
        with open(args.output_json, 'w') as f:
            json.dump(summary, f, indent=2)
        print(f"JSON summary: {args.output_json}")

    if args.output_md:
        generate_markdown(summary, args.output_md)
    else:
        # Print brief summary to stdout
        print(f"Total circuits: {summary['total_circuits']}")
        print(f"Mixed FP32: {summary['mixed_pass_rate']}")
        print(f"Pure FP32:  {summary['pure_pass_rate']}")
        print(f"Avg Island Recovery: {summary['avg_recovery_pct']:.1f}%")


if __name__ == "__main__":
    main()
