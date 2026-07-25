#!/usr/bin/env python3
"""Fix double→SPICE_REAL in ngspice function signatures for SINGLE_PRECISION.
Handles the edge cases that sed scripts miss."""

import re, sys, os, glob

def fix_file(filepath):
    with open(filepath, 'r') as f:
        content = f.read()
    original = content

    # 1. Fix noise function declarations: extern int XXXnoise(... double*)
    content = re.sub(
        r'(extern\s+int\s+\w+noise\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content)

    # 2. Fix truncation function declarations
    content = re.sub(
        r'(extern\s+int\s+\w+trunc\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content)

    # 3. Fix disto function declarations
    content = re.sub(
        r'(extern\s+int\s+\w+disto\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content)

    # 4. Fix noise/trunc/disto function DEFINITIONS (across multiple lines)
    content = re.sub(
        r'(^\w+noise\s*\([^)]*?)\bdouble\s*\*\s*OnDens',
        r'\1SPICE_REAL *OnDens', content, flags=re.MULTILINE)
    content = re.sub(
        r'(^\w+trunc\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content, flags=re.MULTILINE)
    content = re.sub(
        r'(^\w+disto\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content, flags=re.MULTILINE)

    # 5. Fix eval functions (B1evaluate, B2evaluate, etc.)
    content = re.sub(
        r'(^\w*evaluate\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content, flags=re.MULTILINE)
    content = re.sub(
        r'(^\w*Evaluate\s*\([^)]*?)\bdouble\s*\*',
        r'\1SPICE_REAL *', content, flags=re.MULTILINE)

    # 6. Fix leftover double* → SPICE_REAL * in all extern declarations
    content = re.sub(
        r'(extern\s+\w+\s+\w+\s*\([^)]*?)\bdouble\s*\*(?=\s*[,)])',
        r'\1SPICE_REAL *', content)

    if content != original:
        with open(filepath, 'w') as f:
            f.write(content)
        return True
    return False

def main():
    base_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    fixed = 0
    for root, dirs, files in os.walk(base_dir):
        for f in files:
            if f.endswith('.c') or f.endswith('.h'):
                path = os.path.join(root, f)
                if fix_file(path):
                    fixed += 1
    print(f"Fixed {fixed} files")

if __name__ == '__main__':
    main()
