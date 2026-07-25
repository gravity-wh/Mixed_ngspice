#!/usr/bin/env python3
"""Phase 2: Apply fp32 math transformations to all BSIM family evaluation files.

Reads the transformation patterns from the bsim4v5 patches (already applied
in patches/clean/003-b4v5ld.patch etc.) and applies them to BSIM4, BSIM4v6,
BSIM4v7, BSIMSOI evaluation files.
"""

import re, sys, os, glob

# Key transformations from the bsim4v5 patches:
# 1. Add fp32_math.h include after typedefs.h include
# 2. Add SPICE_EXP/SPICE_SQRT/SPICE_LOG macros if not present
# 3. Replace exp((double)(x)) -> SPICE_EXP(x)
# 4. Replace sqrt((double)(x)) -> SPICE_SQRT(x)
# 5. Replace log((double)(x)) -> SPICE_LOG(x)
# 6. The DEXP macro uses exp((double)(A)) -> use expf((float)(A))
# 7. Add CHECK_NAN macro

def add_fp32_includes(content):
    """Add fp32_math.h include after typedefs.h or at reasonable location."""
    if 'fp32_math.h' in content:
        return content
    # Add after SPICE includes
    if '#include "ngspice/typedefs.h"' in content:
        content = content.replace(
            '#include "ngspice/typedefs.h"',
            '#include "ngspice/typedefs.h"\n#include "ngspice/fp32_math.h"')
    else:
        # Add at the top after first #include block
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('#include') and i > 0:
                lines.insert(i+1, '#include "ngspice/fp32_math.h"')
                break
        content = '\n'.join(lines)
    return content

def add_spice_math_macros(content):
    """Add SPICE_EXP/SQRT/LOG macros if not already present."""
    if 'SPICE_EXP(x)' in content:
        return content

    macros = '''
/* FP32 math wrappers — delegates to fp32_math.h safe functions */
#ifndef SPICE_EXP
#define SPICE_EXP(x)  fp32_safe_exp((SPICE_REAL)(x))
#endif
#ifndef SPICE_SQRT
#define SPICE_SQRT(x) fp32_safe_sqrt((SPICE_REAL)(x))
#endif
#ifndef SPICE_LOG
#define SPICE_LOG(x)  fp32_safe_log((SPICE_REAL)(x))
#endif
'''
    # Insert after first #define block or before first function
    lines = content.split('\n')
    insert_at = 0
    for i, line in enumerate(lines):
        if line.startswith('#define') and i > insert_at:
            insert_at = i + 1
    if insert_at > 0:
        lines.insert(insert_at, macros)
        content = '\n'.join(lines)
    return content

def convert_exp_to_spice(content):
    """Replace exp((double)(x)) patterns with SPICE_EXP.
    Also handle exp() without double cast."""
    # Pattern 1: exp((double)(variable))
    content = re.sub(
        r'exp\(\(double\)\((\w+)\)\)',
        r'SPICE_EXP(\1)',
        content)
    # Pattern 2: exp((double)(expression)) — more complex
    # Leave these for manual review
    return content

def convert_sqrt_to_spice(content):
    """Replace sqrt((double)(x)) with SPICE_SQRT."""
    content = re.sub(
        r'sqrt\(\(double\)\(([^)]+)\)\)',
        r'SPICE_SQRT(\1)',
        content)
    return content

def convert_log_to_spice(content):
    """Replace log((double)(x)) with SPICE_LOG."""
    content = re.sub(
        r'log\(\(double\)\(([^)]+)\)\)',
        r'SPICE_LOG(\1)',
        content)
    return content

def fix_dexp_macro(content):
    """Update DEXP macro to use SPICE_EXP or expf."""
    # The existing DEXP in bsim4 series:
    # B = (SPICE_REAL)exp((double)(A));
    content = content.replace(
        'B = (SPICE_REAL)exp((double)(A));',
        'B = (SPICE_REAL)SPICE_EXP(A);')
    return content

def add_nan_check_macro(content):
    """Add CHECK_NAN macro if not present."""
    if 'CHECK_NAN(var)' in content:
        return content

    nan_macro = '''
/* FP32 NaN tracking */
#define CHECK_NAN(var) \\
    if (FP32_IS_NAN(var)) { \\
        var = 0.0; \\
    }
'''
    # Insert before first function definition
    lines = content.split('\n')
    for i, line in enumerate(lines):
        if line.strip().startswith('int ') or line.strip().startswith('void '):
            lines.insert(i, nan_macro)
            break
    return '\n'.join(lines)

def process_file(filepath):
    """Apply all fp32 transformations to a single C file."""
    with open(filepath, 'r', encoding='utf-8', errors='replace') as f:
        content = f.read()

    original = content
    content = add_fp32_includes(content)
    content = add_spice_math_macros(content)
    content = convert_exp_to_spice(content)
    content = convert_sqrt_to_spice(content)
    content = convert_log_to_spice(content)
    content = fix_dexp_macro(content)
    # Don't add CHECK_NAN by default — only for eval files

    if content != original:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        return True
    return False

# ===== Main =====
if __name__ == '__main__':
    target_dirs = sys.argv[1:] if len(sys.argv) > 1 else []

    if not target_dirs:
        print("Usage: phase2_convert_bsim.py <device_dirs...>")
        print("Example: phase2_convert_bsim.py bsim4 bsim4v6 bsim4v7 bsimsoi")
        sys.exit(1)

    for d in target_dirs:
        # Find the main evaluation files
        c_files = glob.glob(f'{d}/*ld.c') + glob.glob(f'{d}/*temp.c') + \
                  glob.glob(f'{d}/*set.c') + glob.glob(f'{d}/*noi.c') + \
                  glob.glob(f'{d}/*geo.c')
        for f in sorted(c_files):
            if process_file(f):
                print(f'  MODIFIED: {f}')
            else:
                print(f'  UNCHANGED: {f}')
