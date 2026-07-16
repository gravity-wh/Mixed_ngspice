#!/usr/bin/env python3
"""Generate FP32 corner model files from TT baseline and HSPICE corner deltas.

Reads the HSPICE library's corner delta parameters and the original .mdl file.
For each corner produces p18_{corner}_fp32.mdl and n18_{corner}_fp32.mdl with
all HSPICE expressions pre-evaluated (base + delta).

Usage:
    python gen_corners.py          # generates all 5 corners
    python gen_corners.py --list   # list available corners
"""

import sys
import os
import re

LIB_FILE = "/mnt/e/xwechat_files/wxid_orm3owzcoz8x22_1c85/msg/file/2026-07/netlist_lib/hspice/bc018_v1p14_rev2.lib"
MDL_FILE = "/mnt/e/xwechat_files/wxid_orm3owzcoz8x22_1c85/msg/file/2026-07/netlist_lib/hspice/bc018_v1p14_rev2.mdl"
OUT_DIR = "/mnt/e/Myresearch/AnalogSizing/models"

# Model ranges in .mdl file (line numbers)
MODEL_RANGES = {
    "n18": (43, 180),
    "p18": (181, 318),
}

# corners to generate
CORNERS = ["tt", "ff", "ss", "fnsp", "snfp"]


def parse_corner_deltas(lib_path, corner):
    """Extract delta values for a specific corner from the .lib file.

    Returns dict like {'dvth_p18': 0.054, 'dxl_p18': -5e-9, ...}
    """
    deltas = {}
    in_corner = False
    with open(lib_path, errors="replace") as f:
        for line in f:
            line = line.strip()
            if re.match(rf"^\.lib\s+{corner}\s*$", line, re.IGNORECASE):
                in_corner = True
                continue
            if in_corner and re.match(r"^\.endl", line):
                break
            if in_corner and line.startswith("+"):
                # Remove leading + and split by whitespace
                content = line[1:].strip()
                # Parse key=value pairs (some values are quoted expressions)
                for match in re.finditer(
                    r"(\w+)\s*=\s*('[^']*'|[-+]?\d+\.?\d*(?:[eE][-+]?\d+)?)", content
                ):
                    key = match.group(1)
                    val_str = match.group(2)
                    if val_str.startswith("'"):
                        # Quoted expression — extract just the number part for d*=0
                        # For corners other than tt, we use the computed value
                        inner = val_str.strip("'")
                        # Try to evaluate simple expressions like '-5e-9*b'
                        # The 'b' parameter is a binning flag (0 or 1)
                        try:
                            val = float(eval(inner.replace("b", "1")))
                        except Exception:
                            val = 0.0
                    else:
                        try:
                            val = float(val_str)
                        except ValueError:
                            continue
                    deltas[key] = val
    return deltas


def apply_deltas_to_model(mdl_path, model_name, deltas):
    """Apply corner deltas to a model definition from .mdl file.

    Reads the raw .mdl with HSPICE expressions like '4.27e-9+dtox_p18'.
    Replaces each expression with pre-evaluated value: base + delta.
    """
    start, end = MODEL_RANGES[model_name]
    lines_out = []
    lines_out.append(f".model {model_name} {'nmos' if model_name.startswith('n') else 'pmos'} level=54 version=4.5")

    with open(mdl_path, errors="replace") as f:
        all_lines = f.readlines()

    expr_re = re.compile(r"'([^']+)'")

    for line in all_lines[start - 1 : end]:
        line = line.rstrip("\r\n")
        # Skip the original .model line (we already added our own)
        if line.startswith(".model"):
            continue
        if not line.startswith("+"):
            continue

        def replace_expr(match):
            expr = match.group(1)
            # Pattern: base_number+delta_param or base_number-delta_param
            # Must handle scientific notation like 4.27e-009 or -1.3e-008
            m = re.match(r"([-+]?\d+\.?\d*(?:[eE][-+]?\d+)?)\s*([+-])\s*(\w+)", expr)
            if m:
                base_str = m.group(1)
                op = m.group(2)
                dparam = m.group(3)
                try:
                    base = float(base_str)
                except ValueError:
                    return match.group(0)
                delta = deltas.get(dparam, 0.0)
                if op == "+":
                    result = base + delta
                else:
                    result = base - delta
                if abs(result) < 1e-12 and abs(result) > 0:
                    return f"{result:.6e}"
                elif abs(result) >= 1e4 or (abs(result) < 1e-12 and result != 0):
                    return f"{result:.6e}"
                else:
                    return f"{result:.10g}"
            return match.group(0)

        line = expr_re.sub(replace_expr, line)
        lines_out.append(line)

    return "\n".join(lines_out)


def generate_corner(corner):
    """Generate p18 and n18 model files for a corner."""
    deltas = parse_corner_deltas(LIB_FILE, corner)
    print(f"  {corner}: {len(deltas)} delta parameters loaded")

    # Generate in order: p18 first, then n18 (avoids memory corruption)
    p18_content = apply_deltas_to_model(MDL_FILE, "p18", deltas)
    n18_content = apply_deltas_to_model(MDL_FILE, "n18", deltas)

    p18_path = os.path.join(OUT_DIR, f"p18_{corner}_fp32.mdl")
    n18_path = os.path.join(OUT_DIR, f"n18_{corner}_fp32.mdl")

    with open(p18_path, "w") as f:
        f.write(p18_content + "\n")
    with open(n18_path, "w") as f:
        f.write(n18_content + "\n")

    return p18_path, n18_path


def main():
    if len(sys.argv) > 1 and sys.argv[1] == "--list":
        print("Available corners:", ", ".join(CORNERS))
        return

    os.makedirs(OUT_DIR, exist_ok=True)

    print("=== Generating FP32 Corner Model Files ===")
    print(f"Output: {OUT_DIR}/")
    print()

    for corner in CORNERS:
        p18_path, n18_path = generate_corner(corner)
        p18_size = os.path.getsize(p18_path)
        n18_size = os.path.getsize(n18_path)
        print(f"    p18_{corner}_fp32.mdl  ({p18_size} bytes)")
        print(f"    n18_{corner}_fp32.mdl  ({n18_size} bytes)")
        print()

    print("Done.")


if __name__ == "__main__":
    main()
