#!/usr/bin/env python3
"""Final cleanup: catch remaining double patterns missed by Phase 2."""

import re
import os
import sys
import glob

EXCLUDED = {'ciderlib', 'xspice', 'KLU', 'fft/fftlib.c', 'fft/fftext.c'}

def is_excluded(path):
    for e in EXCLUDED:
        if e in path.replace('\\', '/'):
            return True
    return False

def cleanup_file(f):
    if is_excluded(f):
        return 0
    try:
        with open(f, 'r', encoding='utf-8', errors='replace') as fh:
            content = fh.read()
    except:
        return 0

    original = content
    lines = content.split('\n')
    new_lines = []

    for line in lines:
        # Skip lines with SPICE_REAL or long double or typedef double
        if 'SPICE_REAL' in line or 'long double' in line or 'typedef double' in line:
            new_lines.append(line)
            continue

        # Skip preprocessor and comments
        s = line.lstrip()
        if s.startswith('#') or s.startswith('//') or s.startswith('/*') or s.startswith('*'):
            new_lines.append(line)
            continue

        # Replace remaining bare "double" (not part of other words)
        # Patterns: unnamed params: (double) (double,) (double *)
        #           named params: double param,
        #           return types: double func(
        new_line = re.sub(r'(?<!\w)double\s+(?=\*?\s*[a-zA-Z_])', 'SPICE_REAL ', line)
        # Unnamed parameter: (double) or (double, or , double) or , double,
        new_line = re.sub(r'\(\s*double\s*\)', '(SPICE_REAL)', new_line)
        new_line = re.sub(r'\(\s*double\s*,', '(SPICE_REAL,', new_line)
        new_line = re.sub(r',\s*double\s*\)', ', SPICE_REAL)', new_line)
        new_line = re.sub(r',\s*double\s*,', ', SPICE_REAL,', new_line)

        new_lines.append(new_line)

    new_content = '\n'.join(new_lines)
    if new_content != original:
        with open(f, 'w', encoding='utf-8', newline='') as fh:
            fh.write(new_content)
        return 1
    return 0

def main():
    src_root = sys.argv[1] if len(sys.argv) > 1 else 'build_fp32/src'
    src_root = os.path.abspath(src_root)

    total = 0
    for f in glob.glob(os.path.join(src_root, '**/*.c'), recursive=True):
        total += cleanup_file(f)
    for f in glob.glob(os.path.join(src_root, '**/*.h'), recursive=True):
        total += cleanup_file(f)

    print(f"Final cleanup: {total} files changed")

if __name__ == '__main__':
    main()
