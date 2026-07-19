#!/usr/bin/env python3
"""
batch_validate.py — Automated FP32 vs FP64 validation runner for Mixed_ngspice.
Runs every SPICE circuit through both FP32 and FP64 ngspice,
extracts DC operating point values, and reports relative errors.
"""
import subprocess, re, json, sys, os, glob, argparse
from pathlib import Path

NGSPICE_FP32 = os.environ.get("NGSPICE_FP32", "")
NGSPICE_FP64 = os.environ.get("NGSPICE_FP64", "")
TOLERANCE_DC = float(os.environ.get("TOL_DC", "0.01"))  # 1% default
TOLERANCE_AC = float(os.environ.get("TOL_AC", "0.05"))  # 5% default

def run_ngspice(ngspice_path, circuit_path, timeout=120):
    """Run ngspice in batch mode and capture output."""
    try:
        result = subprocess.run(
            [ngspice_path, "-b", circuit_path],
            capture_output=True, text=True, timeout=timeout,
            cwd=str(Path(circuit_path).parent)
        )
        return result.stdout + result.stderr
    except subprocess.TimeoutExpired:
        return "TIMEOUT"
    except Exception as e:
        return f"ERROR: {e}"

def extract_op_values(output):
    """Extract DC operating point values from ngspice output."""
    values = {}
    # Match patterns like: v(d) = 1.100000e+00 or id = 1.481894e-05
    for line in output.split('\n'):
        # Voltage: v(xxx) = value
        m = re.match(r'^\s*v\((\S+)\)\s*=\s*([\d.eE+\-]+)', line)
        if m:
            values[f"v({m.group(1)})"] = float(m.group(2))
        # Current: id = value or i(xxx) = value
        m = re.match(r'^\s*id\s*=\s*([\d.eE+\-]+)', line)
        if m:
            values["id"] = float(m.group(1))
        m = re.match(r'^\s*i\((\S+)\)\s*=\s*([\d.eE+\-]+)', line)
        if m:
            values[f"i({m.group(1)})"] = float(m.group(2))
        # Transconductance: gm = value
        m = re.match(r'^\s*gm\s*=\s*([\d.eE+\-]+)', line)
        if m:
            values["gm"] = float(m.group(1))
        # Error detection
        if "Error" in line and "singular" not in line.lower():
            if "nan" not in line.lower():
                pass  # non-fatal errors
    return values

def extract_ac_values(output):
    """Extract AC analysis results from ngspice output."""
    values = {}
    # Look for gain/db/phase values
    for line in output.split('\n'):
        m = re.match(r'^\s*db\((\S+)\)\s*=\s*([\d.eE+\-]+)', line)
        if m:
            values[f"db({m.group(1)})"] = float(m.group(2))
    return values

def rel_error(v32, v64):
    """Compute relative error |v32 - v64| / max(|v64|, 1e-30)"""
    denom = max(abs(v64), 1e-30)
    return abs(v32 - v64) / denom

def compare_results(fp32_out, fp64_out, circuit_name):
    """Compare FP32 vs FP64 outputs and return report dict."""
    report = {
        "circuit": circuit_name,
        "fp32_converged": "Error" not in fp32_out or "TIMEOUT" in fp32_out,
        "fp64_converged": "Error" not in fp64_out or "TIMEOUT" in fp64_out,
        "nodes": {},
        "verdict": "PENDING",
        "max_error": 0.0,
        "nan_detected": False,
    }

    if fp32_out == "TIMEOUT":
        report["verdict"] = "TIMEOUT_FP32"
        return report
    if fp64_out == "TIMEOUT":
        report["verdict"] = "TIMEOUT_FP64"
        return report

    # Check for NaN
    if "nan" in fp32_out.lower() or "NaN" in fp32_out:
        report["nan_detected"] = True
        report["verdict"] = "NaN_FP32"
        return report
    if "nan" in fp64_out.lower() or "NaN" in fp64_out:
        report["verdict"] = "NaN_FP64"
        return report

    # Check for convergence failure
    if "doAnalyses: iteration limit reached" in fp32_out or "failed to converge" in fp32_out.lower():
        report["verdict"] = "NOCONV_FP32"
        return report
    if "doAnalyses: iteration limit reached" in fp64_out or "failed to converge" in fp64_out.lower():
        report["verdict"] = "NOCONV_FP64"
        return report

    # Extract values
    vals32 = extract_op_values(fp32_out)
    vals64 = extract_op_values(fp64_out)

    if not vals64:
        report["verdict"] = "NO_DATA_FP64"
        return report
    if not vals32:
        report["verdict"] = "NO_DATA_FP32"
        return report

    # Compare all common nodes
    max_err = 0.0
    for key in vals64:
        if key in vals32:
            err = rel_error(vals32[key], vals64[key])
            report["nodes"][key] = {
                "fp32": vals32[key],
                "fp64": vals64[key],
                "rel_error_pct": err * 100
            }
            max_err = max(max_err, err)

    report["max_error"] = max_err * 100  # as percentage

    # Verdict
    if max_err < TOLERANCE_DC * 100:
        report["verdict"] = "PASS"
    elif max_err < TOLERANCE_DC * 500:
        report["verdict"] = "WARN"
    else:
        report["verdict"] = "FAIL"

    return report

def find_spice_files(base_dir):
    """Find all .sp, .cir, .spice files in a directory tree."""
    patterns = ["**/*.sp", "**/*.cir", "**/*.spice"]
    files = []
    for p in patterns:
        files.extend(glob.glob(os.path.join(base_dir, p), recursive=True))
    return sorted(set(files))

def main():
    parser = argparse.ArgumentParser(description="Batch FP32 vs FP64 validation")
    parser.add_argument("--fp32", default=NGSPICE_FP32, help="Path to FP32 ngspice binary")
    parser.add_argument("--fp64", default=NGSPICE_FP64, help="Path to FP64 ngspice binary")
    parser.add_argument("--dir", default=".", help="Directory containing SPICE files")
    parser.add_argument("--output", default="validation_results.json", help="Output JSON file")
    parser.add_argument("--timeout", type=int, default=120, help="Timeout per circuit (seconds)")
    args = parser.parse_args()

    if not args.fp32 or not args.fp64:
        print("ERROR: Must specify --fp32 and --fp64 paths, or set NGSPICE_FP32/NGSPICE_FP64 env vars")
        sys.exit(1)

    if not os.path.exists(args.fp32):
        print(f"ERROR: FP32 binary not found: {args.fp32}")
        sys.exit(1)
    if not os.path.exists(args.fp64):
        print(f"ERROR: FP64 binary not found: {args.fp64}")
        sys.exit(1)

    spice_files = find_spice_files(args.dir)
    print(f"Found {len(spice_files)} SPICE files in {args.dir}")

    results = []
    passed = warned = failed = 0

    for i, sp in enumerate(spice_files):
        name = os.path.relpath(sp, args.dir)
        print(f"[{i+1}/{len(spice_files)}] {name} ... ", end="", flush=True)

        out64 = run_ngspice(args.fp64, sp, timeout=args.timeout)
        out32 = run_ngspice(args.fp32, sp, timeout=args.timeout)

        report = compare_results(out32, out64, name)
        results.append(report)

        verdict = report["verdict"]
        if verdict == "PASS":
            passed += 1
            print(f"✅ PASS (max err {report['max_error']:.4f}%)")
        elif verdict == "WARN":
            warned += 1
            print(f"⚠️  WARN (max err {report['max_error']:.4f}%)")
        else:
            failed += 1
            print(f"❌ {verdict}")

    # Summary
    total = len(spice_files)
    print(f"\n{'='*60}")
    print(f"SUMMARY: {total} circuits | ✅ {passed} PASS | ⚠️ {warned} WARN | ❌ {failed} FAIL")

    # Write JSON
    summary = {
        "total": total, "passed": passed, "warned": warned, "failed": failed,
        "pass_rate": f"{passed/total*100:.1f}%" if total > 0 else "N/A",
        "results": results
    }
    with open(args.output, "w") as f:
        json.dump(summary, f, indent=2)
    print(f"Results written to {args.output}")

if __name__ == "__main__":
    main()
