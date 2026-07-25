#!/usr/bin/env python3
"""Analyze double-precision SSE2 instructions in ELF binaries.
Counts cvtss2sd, addsd, mulsd, divsd, etc. in .text section.
"""
import struct
import os
import sys

# Double-precision instruction patterns (SSE2)
# Format: (mnemonic, byte_pattern, description)
DOUBLE_PATTERNS = [
    ('cvtss2sd',   b'\xf3\x0f\x5a', 'float->double conversion'),
    ('cvtsd2ss',   b'\xf2\x0f\x5a', 'double->float conversion'),
    ('addsd',      b'\xf2\x0f\x58', 'double add'),
    ('subsd',      b'\xf2\x0f\x5c', 'double subtract'),
    ('mulsd',      b'\xf2\x0f\x59', 'double multiply'),
    ('divsd',      b'\xf2\x0f\x5e', 'double divide'),
    ('sqrtsd',     b'\xf2\x0f\x51', 'double sqrt'),
    ('maxsd',      b'\xf2\x0f\x5f', 'double max'),
    ('minsd',      b'\xf2\x0f\x5d', 'double min'),
    ('cmpsd',      b'\xf2\x0f\xc2', 'double compare'),
    ('movsd_load',  b'\xf2\x0f\x10', 'double move (load)'),
    ('movsd_store', b'\xf2\x0f\x11', 'double move (store)'),
    ('cvtsi2sd',   b'\xf2\x0f\x2a', 'int->double conversion'),
]


def analyze_elf(filepath):
    """Full analysis of double-precision instructions in ELF .text section."""
    if not os.path.exists(filepath):
        return None

    with open(filepath, 'rb') as f:
        data = f.read()

    if data[:4] != b'\x7fELF':
        return None

    is_64bit = (data[4] == 2)

    if is_64bit:
        e_shoff = struct.unpack_from('<Q', data, 40)[0]
        e_shentsize = struct.unpack_from('<H', data, 58)[0]
        e_shnum = struct.unpack_from('<H', data, 60)[0]
        e_shstrndx = struct.unpack_from('<H', data, 62)[0]
    else:
        e_shoff = struct.unpack_from('<I', data, 32)[0]
        e_shentsize = struct.unpack_from('<H', data, 46)[0]
        e_shnum = struct.unpack_from('<H', data, 48)[0]
        e_shstrndx = struct.unpack_from('<I', data, 50)[0]

    def get_shdr(off):
        if is_64bit:
            sh_name = struct.unpack_from('<I', data, off)[0]
            sh_flags = struct.unpack_from('<Q', data, off + 8)[0]
            sh_offset = struct.unpack_from('<Q', data, off + 24)[0]
            sh_size = struct.unpack_from('<Q', data, off + 32)[0]
            sh_addr = struct.unpack_from('<Q', data, off + 16)[0]
        else:
            sh_name = struct.unpack_from('<I', data, off)[0]
            sh_flags = struct.unpack_from('<I', data, off + 8)[0]
            sh_offset = struct.unpack_from('<I', data, off + 16)[0]
            sh_size = struct.unpack_from('<I', data, off + 20)[0]
            sh_addr = struct.unpack_from('<I', data, off + 12)[0]
        return sh_name, sh_flags, sh_offset, sh_size, sh_addr

    shstr_off = e_shoff + e_shstrndx * e_shentsize
    _, _, shstr_offset, shstr_size, _ = get_shdr(shstr_off)
    shstr = data[shstr_offset:shstr_offset + shstr_size]

    def section_name(off):
        end = shstr.find(b'\x00', off)
        return shstr[off:end].decode() if end > off else ''

    # Find .text section
    text_data = b''
    text_vaddr = 0
    for i in range(e_shnum):
        hdr_off = e_shoff + i * e_shentsize
        sh_name, sh_flags, sh_offset, sh_size, sh_addr = get_shdr(hdr_off)
        name = section_name(sh_name)
        if name == '.text' and sh_size > 0 and sh_offset > 0:
            text_data = data[sh_offset:sh_offset + sh_size]
            text_vaddr = sh_addr
            break

    if not text_data:
        return None

    text_size = len(text_data)

    # Count each double-precision pattern
    total_counts = {}
    for mnem, pattern, _desc in DOUBLE_PATTERNS:
        count = 0
        pos = 0
        while True:
            pos = text_data.find(pattern, pos)
            if pos == -1:
                break
            count += 1
            pos += 1
        total_counts[mnem] = count

    filesize = os.path.getsize(filepath)
    return total_counts, text_size, filesize, text_data, text_vaddr, data, e_shoff, e_shentsize, e_shnum, e_shstrndx, section_name, get_shdr, is_64bit


def per_function_breakdown(filepath):
    """Find which functions contain cvtss2sd instructions."""
    result = analyze_elf(filepath)
    if result is None:
        return None

    counts, text_size, fsize, text_data, text_vaddr, data, e_shoff, e_shentsize, e_shnum, e_shstrndx, section_name, get_shdr, is_64bit = result

    # Find .symtab and .strtab
    symtab_off = 0
    symtab_size = 0
    symtab_entsize = 0
    strtab_off = 0
    for i in range(e_shnum):
        hdr_off = e_shoff + i * e_shentsize
        sh_name, sh_flags, sh_offset, sh_size, sh_addr = get_shdr(hdr_off)
        name = section_name(sh_name)
        if name == '.symtab':
            symtab_off = sh_offset
            symtab_size = sh_size
            sh_entsize = struct.unpack_from('<Q', data, hdr_off + 56)[0] if is_64bit else struct.unpack_from('<I', data, hdr_off + 36)[0]
            symtab_entsize = sh_entsize
        if name == '.strtab':
            strtab_off = sh_offset
            strtab_size_val = sh_size

    # Parse symbols
    symbols = []
    if symtab_off and symtab_entsize and strtab_off:
        nsyms = symtab_size // symtab_entsize
        for i in range(nsyms):
            soff = symtab_off + i * symtab_entsize
            st_name = struct.unpack_from('<I', data, soff)[0]
            st_info = data[soff + 4]
            st_value = struct.unpack_from('<Q', data, soff + 8)[0] if is_64bit else struct.unpack_from('<I', data, soff + 4)[0]
            st_size = struct.unpack_from('<Q', data, soff + 16)[0] if is_64bit else struct.unpack_from('<I', data, soff + 8)[0]
            if st_size > 0 and (st_info & 0xf) == 2:  # STT_FUNC
                name_end = data.find(b'\x00', strtab_off + st_name)
                if name_end > 0:
                    name = data[strtab_off + st_name:name_end].decode()
                    symbols.append((name, st_value, st_size))

    symbols.sort(key=lambda x: x[1])

    # Find cvtss2sd positions and correlate
    func_counts = {}
    pos = 0
    while True:
        pos = text_data.find(b'\xf3\x0f\x5a', pos)
        if pos == -1:
            break
        inst_vaddr = text_vaddr + pos

        func_name = 'unknown'
        for sym_name, sym_val, sym_size in symbols:
            if sym_val <= inst_vaddr < sym_val + sym_size:
                func_name = sym_name
                break

        func_counts[func_name] = func_counts.get(func_name, 0) + 1
        pos += 1

    return func_counts, text_size, fsize


def main():
    bins = [
        ('float_spice/float_spice',     'POC v1 (~175 lines)'),
        ('float_spice/float_spice_v2',  'POC v2 (~600 lines)'),
        ('build_fp64/src/ngspice',      'Retrofitted ngspice (fp64 reference)'),
        ('bin/ngspice-v1.2',            'Mixed_ngspice v1.2'),
    ]

    print('=' * 72)
    print('  DOUBLE-PRECISION SSE2 INSTRUCTION ANALYSIS')
    print('=' * 72)

    for b, desc in bins:
        result = analyze_elf(b)
        if result is None:
            print(f'\n  {b}: ANALYSIS FAILED')
            continue

        counts, text_size, fsize, _td, _tv, _d, _e, _es, _en, _ei, _sn, _gs, _64 = result
        total_double_ops = sum(counts.values())
        math_ops = total_double_ops - counts.get('movsd_load', 0) - counts.get('movsd_store', 0)

        print(f'\n  --- {b} ---')
        print(f'  {desc}')
        print(f'  File: {fsize/1024:.1f} KB  |  .text: {text_size/1024:.1f} KB')
        print(f'  Double-precision instruction counts:')
        for mnem, pattern, desc2 in DOUBLE_PATTERNS:
            c = counts.get(mnem, 0)
            if c > 0:
                print(f'    {mnem:14s} = {c:6d}  ({desc2})')
        print(f'  {"─" * 50}')
        print(f'  TOTAL (all double ops):     {total_double_ops:6d}')
        print(f'  TOTAL (excl. movsd):       {math_ops:6d}')

        # Assessment
        cvt = counts.get('cvtss2sd', 0)
        if cvt <= 3:
            grade = 'PURE FLOAT'
        elif cvt <= 50:
            grade = 'LOW (output only)'
        elif cvt <= 500:
            grade = 'MODERATE'
        else:
            grade = 'HIGH'
        print(f'  Assessment: {grade}')

    # Per-function breakdown for build_fp64
    print('\n' + '=' * 72)
    print('  PER-FUNCTION BREAKDOWN: build_fp64/src/ngspice')
    print('  Where are the cvtss2sd instructions?')
    print('=' * 72)

    result = per_function_breakdown('build_fp64/src/ngspice')
    if result:
        func_counts, text_size, fsize = result
        print(f'\n  Total cvtss2sd across {len(func_counts)} functions:')
        for name, cnt in sorted(func_counts.items(), key=lambda x: -x[1])[:25]:
            print(f'    {cnt:4d}  {name}')
        if len(func_counts) > 25:
            remaining = sorted(func_counts.items(), key=lambda x: -x[1])[25:]
            rem_total = sum(c for _, c in remaining)
            print(f'    ... ({len(remaining)} more functions, {rem_total} total)')

    # Also for bin/ngspice-v1.2
    print('\n' + '=' * 72)
    print('  PER-FUNCTION BREAKDOWN: bin/ngspice-v1.2')
    print('  Where are the cvtss2sd instructions?')
    print('=' * 72)

    result2 = per_function_breakdown('bin/ngspice-v1.2')
    if result2:
        func_counts2, text_size2, fsize2 = result2
        print(f'\n  Total cvtss2sd across {len(func_counts2)} functions:')
        for name, cnt in sorted(func_counts2.items(), key=lambda x: -x[1])[:25]:
            print(f'    {cnt:4d}  {name}')


if __name__ == '__main__':
    os.chdir(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    main()
