#!/usr/bin/env python3
"""
convert_math_functions.py — Mechanical math function → SPICE_* macro conversion
====================================================================
Converts bare math function calls to SPICE_* macros across all .c/.h files:
  exp(x) → SPICE_EXP(x), log(x) → SPICE_LOG(x), sqrt(x) → SPICE_SQRT(x), etc.

Protects FP64 islands and excluded files (same exclusions as Phase 2).
"""

import re
import os
import sys
import glob

# ── Math Function Mapping ─────────────────────────────────────────────
MATH_MAP = [
    # (bare_function, SPICE_macro)
    # Order matters: longer names first to avoid partial matches
    ('atan2',   'SPICE_ATAN2'),
    ('asinh',   'SPICE_ASINH'),
    ('acosh',   'SPICE_ACOSH'),
    ('atanh',   'SPICE_ATANH'),
    ('log10',   'SPICE_LOG10'),
    ('hypot',   'SPICE_HYPOT'),
    ('nextafter', 'SPICE_NEXTAFTER'),
    ('lgamma',  'SPICE_LGAMMA'),
    ('cbrt',    'SPICE_CBRT'),
    ('fmod',    'SPICE_FMOD'),
    ('ceil',    'SPICE_CEIL'),
    ('fabs',    'SPICE_FABS'),
    ('sqrt',    'SPICE_SQRT'),
    ('tanh',    'SPICE_TANH'),
    ('sinh',    'SPICE_SINH'),
    ('cosh',    'SPICE_COSH'),
    ('asin',    'SPICE_ASIN'),
    ('acos',    'SPICE_ACOS'),
    ('atan',    'SPICE_ATAN'),
    ('erfc',    'SPICE_ERFC'),
    ('fmax',    'SPICE_FMAX'),
    ('fmin',    'SPICE_FMIN'),
    ('trunc',   'SPICE_TRUNC'),
    ('round',   'SPICE_ROUND'),
    ('erf',     'SPICE_ERF'),
    ('exp',     'SPICE_EXP'),
    ('log',     'SPICE_LOG'),
    ('pow',     'SPICE_POW'),
    ('sin',     'SPICE_SIN'),
    ('cos',     'SPICE_COS'),
    ('tan',     'SPICE_TAN'),
]

# Excluded files/directories (relative to SRC_ROOT)
EXCLUDED = {
    'maths/fft/fftlib.c',
    'maths/fft/fftext.c',
    'maths/KLU',
    'ciderlib',
    'xspice',
}

# ── Logic ──────────────────────────────────────────────────────────────

def is_excluded(filepath, src_root):
    rel = os.path.relpath(filepath, src_root).replace('\\', '/')
    for excl in EXCLUDED:
        if rel.startswith(excl) or excl in rel:
            return True
    return False

def convert_file(filepath, src_root):
    """Convert math functions in a single file. Returns number of changes."""
    if is_excluded(filepath, src_root):
        return 0

    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        try:
            lines = f.readlines()
        except:
            return 0

    in_fp64_island = False
    in_ifndef_sp = False
    changes = 0

    new_lines = []
    for line in lines:
        # Track FP64 island state
        if 'FP64-ISLAND-START' in line:
            in_fp64_island = True
        if 'FP64-ISLAND-END' in line:
            in_fp64_island = False
            new_lines.append(line)
            continue

        # Track #ifndef SINGLE_PRECISION blocks
        if re.match(r'^\s*#\s*ifndef\s+SINGLE_PRECISION', line):
            in_ifndef_sp = True
        elif re.match(r'^\s*#\s*ifdef\s+SINGLE_PRECISION', line):
            in_ifndef_sp = False
        elif re.match(r'^\s*#\s*else\b', line):
            if in_ifndef_sp:
                in_ifndef_sp = False  # entering FP32 #else branch
        elif re.match(r'^\s*#\s*endif\b', line):
            in_ifndef_sp = False

        if in_fp64_island or in_ifndef_sp:
            new_lines.append(line)
            continue

        # Skip preprocessor, comments, and lines with existing SPICE_ macros
        stripped = line.lstrip()
        if stripped.startswith('#') or stripped.startswith('//') or stripped.startswith('/*'):
            new_lines.append(line)
            continue

        # Apply replacements (regex negative lookbehind already prevents
        # matching already-converted SPICE_EXP(), expf(), etc.)
        new_line = line
        for bare, spice in MATH_MAP:
            # Pattern: bare_name( but NOT when:
            # - preceded by SPICE_, letter, or underscore (avoid fabsf, expf, SPICE_EXP, etc.)
            # - the bare name is a whole word
            pattern = r'(?<![a-zA-Z_])' + re.escape(bare) + r'\s*\('
            replacement = spice + '('
            # Only replace if the pattern matches (not part of another identifier)
            if re.search(pattern, new_line):
                new_line = re.sub(pattern, replacement, new_line)

        if new_line != line:
            changes += 1
        new_lines.append(new_line)

    if changes > 0:
        with open(filepath, 'w', encoding='utf-8', newline='') as f:
            f.writelines(new_lines)

    return changes

def convert_all(src_root, verbose=True):
    """Convert all .c and .h files under src_root."""
    c_files = sorted(glob.glob(os.path.join(src_root, '**/*.c'), recursive=True))
    h_files = sorted(glob.glob(os.path.join(src_root, '**/*.h'), recursive=True))

    total_changed = 0
    total_lines = 0

    if verbose:
        print(f"Converting math functions in {src_root}")
        print(f"  {len(h_files)} headers, {len(c_files)} source files")

    for f in h_files + c_files:
        lc = convert_file(f, src_root)
        if lc > 0:
            total_changed += 1
            total_lines += lc
            if verbose:
                rel = os.path.relpath(f, src_root)
                print(f"  {rel}: {lc} lines")

    if verbose:
        print(f"\nTotal: {total_changed} files, {total_lines} lines changed")

    return total_changed, total_lines

def verify(src_root):
    """Check for remaining bare math function calls."""
    issues = []
    for bare, spice in MATH_MAP:
        count = 0
        for f in glob.glob(os.path.join(src_root, '**/*.c'), recursive=True):
            if is_excluded(f, src_root):
                continue
            try:
                with open(f, 'r', encoding='utf-8', errors='replace') as fh:
                    content = fh.read()
                    # Count bare calls not inside SPICE_* and not *f() variants
                    pattern = r'(?<![a-zA-Z_])' + re.escape(bare) + r'\s*\('
                    matches = re.findall(pattern, content)
                    count += len(matches)
            except:
                pass
        if count > 0:
            issues.append((bare, count))

    if issues:
        print("Remaining bare math calls:")
        for bare, count in sorted(issues, key=lambda x: -x[1]):
            print(f"  {bare}(): {count}")
    else:
        print("No bare math calls remaining!")

    return len(issues) == 0

def main():
    import argparse
    parser = argparse.ArgumentParser(
        description='Convert bare math functions → SPICE_* macros'
    )
    parser.add_argument('src_root', nargs='?',
                        default='build_fp32/src',
                        help='Source root directory')
    parser.add_argument('--verify', '-v', action='store_true',
                        help='Verify no bare math calls remain')
    parser.add_argument('--quiet', '-q', action='store_true',
                        help='Less output')

    args = parser.parse_args()
    src_root = os.path.abspath(args.src_root)

    if args.verify:
        verify(src_root)
        return

    convert_all(src_root, verbose=not args.quiet)
    verify(src_root)

if __name__ == '__main__':
    main()
