#!/usr/bin/env python3
"""Compare FP32 vs FP64 ngspice rawfile outputs and report relative errors."""

import sys
import struct
import math
from pathlib import Path


def parse_rawfile(path):
    """Parse ngspice binary rawfile. Returns (title, date, plotname, flags,
    num_vars, num_points, var_names, data_matrix).

    data_matrix: list of lists, one per variable, each with num_points floats.
    """
    with open(path, "rb") as f:
        raw = f.read()

    def read_str():
        nonlocal pos
        end = raw.index(b"\0", pos)
        s = raw[pos:end].decode("latin-1")
        pos = end + 1
        return s

    pos = 0

    # Header magic
    magic = raw[pos : pos + 8]
    pos += 8
    if magic[:5] != b"Title":
        # Newer format: skip initial bytes until "Title:" found
        idx = raw.find(b"Title:")
        if idx >= 0:
            pos = idx
        else:
            raise ValueError(f"Not a valid ngspice rawfile: {path}")

    title_line = read_str()
    title = title_line.split(":", 1)[1].strip() if ":" in title_line else title_line
    date = read_str()
    plotname = read_str()
    flags = read_str()
    header_line = read_str()  # "No. Variables: ..."
    num_vars = int(header_line.split(":")[1].strip().split()[0])
    header_line2 = read_str()  # "No. Points: ..." or "No. Points: ...\tVariables: ..."
    if "Variables:" in header_line2:
        pts_part = header_line2.split("\t")[0]
        num_points = int(pts_part.split(":")[1].strip().split()[0])
    else:
        num_points_part = header_line2.strip()
        num_points = int(num_points_part.split(":")[1].strip().split()[0])

    # Read variable names
    var_names = []
    for _ in range(num_vars):
        header_line3 = read_str()
        # Get the variable name (last tab-separated field)
        parts = header_line3.split("\t")
        var_name = parts[-1].strip() if parts else "?"
        var_names.append(var_name)

    # Skip "Binary:\n"
    if raw[pos : pos + 7] == b"Binary:":
        pos += 7
        if raw[pos] == 0x0A:  # newline
            pos += 1

    # Read data: num_points rows, each with num_vars doubles (FP64)
    data = [[] for _ in range(num_vars)]
    for _ in range(num_points):
        for v in range(num_vars):
            if pos + 8 > len(raw):
                break
            val = struct.unpack(">d", raw[pos : pos + 8])[0]
            pos += 8
            data[v].append(val)

    return title, date, plotname, flags, num_vars, num_points, var_names, data


def compare(fp32_path, fp64_path, threshold=0.001):
    """Compare two rawfiles, report variables exceeding threshold."""
    _, _, _, _, nv32, np32, names32, data32 = parse_rawfile(fp32_path)
    _, _, _, _, nv64, np64, names64, data64 = parse_rawfile(fp64_path)

    if nv32 != nv64 or np32 != np64:
        print(f"WARNING: Mismatched dimensions: FP32({nv32}v x {np32}p) vs FP64({nv64}v x {np64}p)")

    nvars = min(nv32, nv64)
    npts = min(np32, np64)

    max_err = 0.0
    max_var = ""
    max_idx = 0
    violations = []

    for v in range(nvars):
        name = names32[v] if v < len(names32) else f"var{v}"
        for p in range(npts):
            v32 = data32[v][p]
            v64 = data64[v][p]

            denom = abs(v64)
            if denom < 1e-30:
                if abs(v32) > 1e-30:
                    rel_err = 1.0  # zero vs non-zero
                else:
                    continue
            else:
                rel_err = abs(v32 - v64) / denom

            if math.isnan(rel_err):
                violations.append((name, p, v32, v64, float("nan")))
                continue

            if rel_err > max_err:
                max_err = rel_err
                max_var = name
                max_idx = p

            if rel_err > threshold:
                violations.append((name, p, v32, v64, rel_err))

    print(f"Comparison: {nvars} variables, {npts} points")
    print(f"Max relative error: {max_err:.6%} ({max_var}[{max_idx}]: FP32={data32[names32.index(max_var)][max_idx]:.6g} FP64={data64[names64.index(max_var)][max_idx]:.6g})")
    print(f"Violations > {threshold:.1%}: {len(violations)}")

    if violations:
        print("\nTop 20 violations:")
        violations.sort(key=lambda x: -x[4] if not math.isnan(x[4]) else float("inf"))
        for name, idx, v32, v64, err in violations[:20]:
            if math.isnan(err):
                print(f"  {name}[{idx}]: FP32={v32:.6g} FP64={v64:.6g} rel_err=NAN")
            else:
                print(f"  {name}[{idx}]: FP32={v32:.6g} FP64={v64:.6g} rel_err={err:.4%}")

    return max_err, len(violations)


if __name__ == "__main__":
    if len(sys.argv) < 3:
        print(f"Usage: {sys.argv[0]} <fp32.raw> <fp64.raw> [threshold]")
        print("  threshold: max acceptable relative error (default 0.001 = 0.1%)")
        sys.exit(1)

    fp32_file = sys.argv[1]
    fp64_file = sys.argv[2]
    thresh = float(sys.argv[3]) if len(sys.argv) > 3 else 0.001

    if not Path(fp32_file).exists():
        print(f"ERROR: {fp32_file} not found")
        sys.exit(1)
    if not Path(fp64_file).exists():
        print(f"ERROR: {fp64_file} not found")
        sys.exit(1)

    max_err, n_violations = compare(fp32_file, fp64_file, thresh)
    if n_violations > 0:
        sys.exit(1)
