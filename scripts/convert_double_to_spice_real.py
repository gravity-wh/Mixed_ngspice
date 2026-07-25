#!/usr/bin/env python3
"""
convert_double_to_spice_real.py — Mechanical double → SPICE_REAL conversion
====================================================================
Converts double to SPICE_REAL across all .c/.h files in the ngspice
source tree, while protecting FP64 islands and excluded files.

Strategy:
  1. Process .h files FIRST (struct definitions), then .c files
  2. Skip files on the exclusion list
  3. Skip lines inside FP64 island markers or #ifndef SINGLE_PRECISION blocks
  4. Apply regex rules for locals, params, casts, return types, struct fields
"""

import re
import os
import sys
import glob

# ── Configuration ──────────────────────────────────────────────────────
SRC_ROOT = None  # set from command line or auto-detected

# Files excluded entirely from conversion (relative to SRC_ROOT)
EXCLUDED_FILES = {
    'maths/fft/fftlib.c',
    'maths/fft/fftext.c',
    'maths/KLU',
    'ciderlib',
    'xspice',
}

# ── Regex Rules ────────────────────────────────────────────────────────

# Cast: (double) → (SPICE_REAL)
RE_CAST = re.compile(r'\(double\)')

# Struct field / local variable declaration:
#   leading whitespace + double + space + identifiers + ;
# Matches: "    double fieldname;" or "    double x, y, z;"
# Does NOT match: function return types (no leading ws in most cases)
RE_STRUCT_FIELD = re.compile(
    r'^(\s*)(double)\s+'
    r'('
        r'(?:\*?\s*\w+(?:\s*\[[^\]]*\])?)'  # first identifier (maybe ptr, maybe array)
        r'(?:\s*,\s*\*?\s*\w+(?:\s*\[[^\]]*\])?)*'  # additional identifiers
    r')\s*;',
    re.MULTILINE
)

# Function return type: "static double func_name(" or just "double func_name("
# But NOT "long double" — need to check for "long" prefix
RE_RETURN_TYPE = re.compile(
    r'(?<!\blong\s)(?<!\bSPICE_)\bdouble\s+(\*?\s*\w+\s*\()',
)

# Function parameter: (double param_name) or (double *param_name)
# Match "double" preceded by '(' or ',' and followed by identifier
RE_PARAM = re.compile(r'([(,]\s*)double(\s+\*?\s*\w+)')

# General "double" in declarations (catch-all for complex patterns)
# "double *ptr", "double **ptr", "double arr[]"
RE_POINTER_DECL = re.compile(
    r'(?<!\blong\s)(?<!\bSPICE_)\bdouble\s+(\*+\s*\w+)'
)

# "long double" — must NOT be converted
# This is already handled by the negative lookbehind in patterns above

# Static/const/extern/volatile declarations
# "static double x", "const double x", "extern double x"
RE_QUALIFIED = re.compile(
    r'(static\s+|const\s+|extern\s+|volatile\s+|register\s+)'
    r'(?<!\blong\s)double\b'
)

# ── Prototypes that use "double" as a type in typedef — rare, skip ─────

def is_excluded(filepath):
    """Check if file should be excluded from conversion."""
    rel = os.path.relpath(filepath, SRC_ROOT).replace('\\', '/')
    for excl in EXCLUDED_FILES:
        if rel.startswith(excl) or excl in rel:
            return True
    return False

def has_fp64_markers(content):
    """Check if file contains FP64 island markers."""
    return 'FP64-ISLAND' in content

def convert_line(line, in_fp64_island, in_ifndef_sp):
    """Apply double→SPICE_REAL conversions to a single line.
    Returns (converted_line, in_fp64_island, in_ifndef_sp)."""

    # Track FP64 island state
    if 'FP64-ISLAND-START' in line:
        return line, True, in_ifndef_sp
    if 'FP64-ISLAND-END' in line:
        return line, False, in_ifndef_sp

    # Track #ifndef SINGLE_PRECISION blocks
    if re.match(r'^\s*#\s*ifndef\s+SINGLE_PRECISION', line):
        return line, in_fp64_island, True
    if re.match(r'^\s*#\s*ifdef\s+SINGLE_PRECISION', line):
        return line, in_fp64_island, False  # entering SINGLE_PRECISION block
    if re.match(r'^\s*#\s*else\b', line):
        if in_ifndef_sp:
            return line, in_fp64_island, False  # #else of #ifndef SINGLE_PRECISION = FP32 path
        return line, in_fp64_island, in_ifndef_sp
    if re.match(r'^\s*#\s*endif\b', line):
        return line, in_fp64_island, False

    # Skip if in protected region
    if in_fp64_island or in_ifndef_sp:
        return line, in_fp64_island, in_ifndef_sp

    # Skip preprocessor directives and comments
    stripped = line.lstrip()
    if stripped.startswith('#') or stripped.startswith('//') or stripped.startswith('/*'):
        return line, in_fp64_island, in_ifndef_sp

    # Skip lines that are entirely inside a block comment
    if '/*' in line and '*/' not in line:
        return line, in_fp64_island, in_ifndef_sp

    # Skip "long double"
    if 'long double' in line:
        return line, in_fp64_island, in_ifndef_sp

    # Skip if already has SPICE_REAL
    if 'SPICE_REAL' in line:
        return line, in_fp64_island, in_ifndef_sp

    # Skip typedef lines that define double types (rare)
    if re.match(r'^\s*typedef\s+double\b', line):
        return line, in_fp64_island, in_ifndef_sp

    # Skip #define lines using double
    if re.match(r'^\s*#\s*define\s+.*\bdouble\b', line):
        return line, in_fp64_island, in_ifndef_sp

    # Apply conversions
    original = line

    # 1. Cast: (double) → (SPICE_REAL)
    line = RE_CAST.sub('(SPICE_REAL)', line)

    # 2. Function parameters: (..., double param, ...) → (..., SPICE_REAL param, ...)
    line = RE_PARAM.sub(r'\1SPICE_REAL\2', line)

    # 3. Pointer declarations: double *ptr, double **ptr
    line = RE_POINTER_DECL.sub(r'SPICE_REAL \1', line)

    # 4. Qualified declarations: static double, const double, extern double
    line = RE_QUALIFIED.sub(r'\1SPICE_REAL', line)

    # 5. Struct field / local var: "    double fieldname;"
    line = RE_STRUCT_FIELD.sub(r'\1SPICE_REAL \3;', line)

    # 6. Return type: double func_name(
    line = RE_RETURN_TYPE.sub(r'SPICE_REAL \1', line)

    # Final catch-all: any remaining bare "double " that's not part of another word
    # Only apply if simpler patterns haven't caught it
    # This handles cases like "double x = ..." (assignment with initialization)
    line = re.sub(
        r'(?<!\w)(?<!\blong\s)double\s+(?!\w*\s*\()([a-zA-Z_]\w*)',
        r'SPICE_REAL \1',
        line
    )

    return line, in_fp64_island, in_ifndef_sp

def convert_file(filepath, dry_run=False):
    """Convert a single file. Returns (changed, line_count)."""
    if is_excluded(filepath):
        return False, 0

    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        try:
            lines = f.readlines()
        except Exception as e:
            print(f"  SKIP {filepath}: {e}")
            return False, 0

    in_fp64_island = False
    in_ifndef_sp = False
    changed = 0

    new_lines = []
    for i, line in enumerate(lines):
        new_line, in_fp64_island, in_ifndef_sp = convert_line(
            line, in_fp64_island, in_ifndef_sp
        )
        if new_line != line:
            changed += 1
        new_lines.append(new_line)

    if changed > 0 and not dry_run:
        with open(filepath, 'w', encoding='utf-8', newline='') as f:
            f.writelines(new_lines)

    return changed > 0, changed

def convert_all(src_root, dry_run=False, verbose=True):
    """Convert all .c and .h files under src_root."""
    global SRC_ROOT
    SRC_ROOT = src_root

    # Process headers first, then source files
    h_files = sorted(glob.glob(os.path.join(src_root, '**/*.h'), recursive=True))
    c_files = sorted(glob.glob(os.path.join(src_root, '**/*.c'), recursive=True))

    total_changed = 0
    total_lines_changed = 0

    if verbose:
        print(f"Processing {len(h_files)} headers...")

    for f in h_files:
        changed, lc = convert_file(f, dry_run=dry_run)
        if changed:
            total_changed += 1
            total_lines_changed += lc
            if verbose:
                rel = os.path.relpath(f, src_root)
                print(f"  H {rel}: {lc} lines")

    if verbose:
        print(f"Processing {len(c_files)} source files...")

    for f in c_files:
        changed, lc = convert_file(f, dry_run=dry_run)
        if changed:
            total_changed += 1
            total_lines_changed += lc
            if verbose:
                rel = os.path.relpath(f, src_root)
                print(f"  C {rel}: {lc} lines")

    if verbose:
        print(f"\nTotal: {total_changed} files, {total_lines_changed} lines changed")

    return total_changed, total_lines_changed

def count_remaining_double(src_root):
    """Count remaining 'double' occurrences for verification."""
    count = 0
    for pattern in ['**/*.c', '**/*.h']:
        for f in glob.glob(os.path.join(src_root, pattern), recursive=True):
            rel = os.path.relpath(f, src_root).replace('\\', '/')
            if is_excluded(f):
                continue
            try:
                with open(f, 'r', encoding='utf-8', errors='replace') as fh:
                    for line in fh:
                        # Count non-comment, non-string "double"
                        stripped = line.strip()
                        if stripped.startswith('//') or stripped.startswith('/*') or stripped.startswith('*'):
                            continue
                        if re.search(r'(?<!\w)double(?!\w)', line):
                            count += 1
            except:
                pass
    return count

def main():
    import argparse
    parser = argparse.ArgumentParser(
        description='Convert double → SPICE_REAL across ngspice source tree'
    )
    parser.add_argument('src_root', nargs='?',
                        default='build_fp32/src',
                        help='Source root directory (default: build_fp32/src)')
    parser.add_argument('--dry-run', '-n', action='store_true',
                        help='Show what would be changed without writing')
    parser.add_argument('--quiet', '-q', action='store_true',
                        help='Less output')
    parser.add_argument('--count', '-c', action='store_true',
                        help='Count remaining double occurrences only')
    parser.add_argument('--file', '-f', type=str,
                        help='Convert a single file only')

    args = parser.parse_args()
    src_root = os.path.abspath(args.src_root)

    if args.count:
        remaining = count_remaining_double(src_root)
        print(f"Remaining 'double' occurrences: {remaining}")
        return

    if args.file:
        filepath = os.path.abspath(args.file)
        changed, lc = convert_file(filepath, dry_run=args.dry_run)
        if changed:
            print(f"Changed {filepath}: {lc} lines")
        else:
            print(f"No changes in {filepath}")
        return

    print(f"Converting double → SPICE_REAL in {src_root}")
    print(f"Dry run: {args.dry_run}")
    print()

    convert_all(src_root, dry_run=args.dry_run, verbose=not args.quiet)

    remaining = count_remaining_double(src_root)
    print(f"\nRemaining 'double' occurrences (approximate): {remaining}")

if __name__ == '__main__':
    main()
