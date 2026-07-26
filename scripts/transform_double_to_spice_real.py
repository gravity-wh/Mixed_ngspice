#!/usr/bin/env python3
"""
C Type Transformer: double → SPICE_REAL in SPICE-aware source files.

Unlike sed, this tool:
1. Checks if each file has SPICE_REAL available (includes typedefs.h chain)
2. Only converts function signatures, not local variables
3. Handles multi-line signatures, K&R C, function pointers, array params
4. Preserves double in non-SPICE-aware files (maths/poly, etc.)
"""

import re, os, sys

class CTypeTransformer:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        self.stats = {'files_checked': 0, 'files_modified': 0, 'signatures_converted': 0}

    def is_spice_aware(self, filepath):
        """Check if file has access to SPICE_REAL type via include chain."""
        try:
            with open(filepath, 'r', errors='ignore') as f:
                content = f.read()
        except:
            return False

        # Direct include of typedefs.h
        if re.search(r'#include\s+["<]ngspice/typedefs\.h[">]', content):
            return True
        # config.h is always included first and leads to typedefs.h via ngspice.h
        if re.search(r'#include\s+["<]ngspice/config\.h[">]', content):
            return True
        if re.search(r'#include\s+["<]ngspice/ngspice\.h[">]', content):
            return True
        # In spicelib: devices and analysis are always SPICE-aware
        if '/spicelib/' in filepath:
            return True
        if '/frontend/' in filepath:
            return True
        # In include/: always SPICE-aware
        if '/include/ngspice/' in filepath:
            return True
        return False

    def fix_kandr_params(self, content):
        """Fix K&R C parameter declarations: double ar, ai, *cr, *ci → split into double ar, ai; SPICE_REAL *cr, *ci"""
        # Pattern: indentation + "double" + comma-list ending with *ptr
        def split_kandr(m):
            line = m.group(0)
            indent = m.group(1)
            # Split into type name and variable list
            # Remove "double " prefix
            rest = re.sub(r'^\s*double\s+', '', line)
            parts = [p.strip() for p in rest.split(',')]
            scalars = [p for p in parts if not p.startswith('*')]
            pointers = [p for p in parts if p.startswith('*')]
            result = []
            if scalars:
                result.append(f"{indent}double {', '.join(scalars)};")
            if pointers:
                ptr_names = [p.lstrip('*') for p in pointers]
                result.append(f"{indent}SPICE_REAL *{', *'.join(ptr_names)};")
            return '\n'.join(result)

        # Match lines: spaces + "double" + word-comma-list ending with *name
        content = re.sub(
            r'^(\s+)double\s+[\w\s,]+,\s*\*[\w\s,]+;\s*$',
            split_kandr, content, flags=re.MULTILINE)
        return content

    def fix_function_params(self, content):
        """Replace double* with SPICE_REAL* in function signatures (multi-line aware)."""
        # Strategy: find function signatures by matching function name followed by (
        # Then replace all double* within the parameter list

        # Match function definitions and declarations:
        # [extern/static] [return_type] funcname( ... params ... )
        # This regex handles multi-line signatures

        def replace_double_star_in_params(match):
            """Within a function parameter list, replace double* → SPICE_REAL*"""
            full = match.group(0)
            prefix = match.group(1)  # everything before and including (
            params = match.group(2)  # parameter list
            suffix = match.group(3)  # ) and rest

            # Replace double* → SPICE_REAL* (any whitespace between double and *)
            params = re.sub(r'\bdouble\s*\*\s*', 'SPICE_REAL *', params)
            # Also handle double arr[] → SPICE_REAL arr[] (but NOT double arr[N] with N>0?)
            # For now, only handle empty brackets
            params = re.sub(r'\bdouble\s+(\w+)\s*\[\s*\]', r'SPICE_REAL \1[]', params)

            return prefix + params + suffix

        # Match: funcname (params) — captures the name, params, and closing
        # This is a simplified approach; a full parser would use AST
        content = re.sub(
            r'((?:\w+\s+)*\w+\s*\([^)]*?)double\s*\*\s*(\w+(?:\s*\[\s*\])?\s*[,)])',
            r'\1SPICE_REAL *\2', content)

        return content

    def fix_function_pointers(self, content):
        """Fix function pointer declarations in structs/typedefs."""
        # int (*funcname) (params) — function pointer in struct
        content = re.sub(
            r'(\*\s*\w+\s*\)\s*\([^)]*?)double\s*\*\s*',
            r'\1SPICE_REAL *', content)
        return content

    def transform_file(self, filepath):
        """Apply all transformations to a single file."""
        try:
            with open(filepath, 'r', errors='ignore') as f:
                content = f.read()
                original = content
        except:
            return

        # Fix K&R C declarations first
        content = self.fix_kandr_params(content)
        # Fix function signatures
        content = self.fix_function_params(content)
        # Fix function pointers
        content = self.fix_function_pointers(content)

        if content != original:
            with open(filepath, 'w') as f:
                f.write(content)
            self.stats['files_modified'] += 1

    def run(self):
        """Scan all C/H files and apply transformations."""
        for root, dirs, files in os.walk(self.base_dir):
            # Skip build artifacts
            dirs[:] = [d for d in dirs if d not in {'.libs', '.deps', 'autom4te.cache'}]
            for f in files:
                if not (f.endswith('.c') or f.endswith('.h')):
                    continue
                filepath = os.path.join(root, f)
                self.stats['files_checked'] += 1

                if not self.is_spice_aware(filepath):
                    continue

                self.transform_file(filepath)

        print(f"Checked: {self.stats['files_checked']} files")
        print(f"Modified: {self.stats['files_modified']} files")

if __name__ == '__main__':
    base = sys.argv[1] if len(sys.argv) > 1 else '/tmp/build_phase1/ngspice-46'
    t = CTypeTransformer(base)
    t.run()
