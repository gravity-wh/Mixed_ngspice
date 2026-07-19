#!/usr/bin/env python3
"""
SCS (Spectre) → SPICE (ngspice/hspice) Netlist Converter
=========================================================

Converts Cadence Spectre .scs netlists to SPICE .sp format.
Supports ngspice and hspice simulators.

Usage:
    python scs2sp.py input.scs                  # → input.sp (ngspice)
    python scs2sp.py input.scs output.sp        # → output.sp (ngspice)
    python scs2sp.py input.scs --hspice         # hspice format
    python scs2sp.py input.scs --stdout         # print to stdout
    python scs2sp.py input.scs --hspice --stdout
"""

import re
import sys
import os


# ─── Main Converter ─────────────────────────────────────────────────────────

class Scs2Spice:
    """Converts Spectre SCS netlist text to SPICE format."""

    def __init__(self, mode='ngspice'):
        self.mode = mode
        self.collecting_sweep_data = False
        self.collecting_params = False
        self.param_names = []
        self.sweep_data_rows = []

    # ── Helpers ──────────────────────────────────────────────────────────

    @staticmethod
    def fix_node(n):
        """Clean up a Spectre node name for SPICE."""
        n = n.strip()
        if n in ('0', 'gnd!', 'GND!'):
            return '0'
        if n == '__root_VSS__':
            return '0'
        if n == '__root_VDD__':
            return 'vdd'
        # Remove escaped angle brackets: n9_\<5\>_ → n9_5
        n = re.sub(r'_\\?<(\d+)\\?>_', r'_\1', n)
        n = re.sub(r'_<(\d+)>_', r'_\1', n)
        n = n.replace('\\', '')
        if n == '_vss_':
            return '0'
        if n == '_vdd_':
            return 'vdd'
        return n

    @staticmethod
    def fix_nodes(nodes):
        """Fix a space-separated node list."""
        return ' '.join(Scs2Spice.fix_node(p) for p in nodes.split())

    @staticmethod
    def get_param(params, key, default=None):
        """Extract a Spectre parameter: key=value (value may contain nested parens)."""
        pattern = r'(?:\b|^)' + re.escape(key) + r'\s*=\s*'
        rest = re.split(pattern, params, maxsplit=1)
        if len(rest) < 2:
            return default
        val = rest[1].lstrip()
        depth = 0
        end = 0
        for i, ch in enumerate(val):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif depth == 0 and ch in (' ', '\t', ',', '/'):
                break
            end = i + 1
        v = val[:end].rstrip(',')
        return v if v else default

    @staticmethod
    def clean_param_value(val):
        """Remove Spectre int() wrapper, keep the argument."""
        if val is None:
            return None
        m = re.match(r'int\((.+)\)', val.strip())
        return m.group(1).strip() if m else val.strip()

    # ── Entry ────────────────────────────────────────────────────────────

    def convert(self, line):
        raw = line.rstrip('\n')
        s = raw.strip()
        if not s:
            return ''

        # ── Comment ──
        if s.startswith('//'):
            return '* ' + s[2:].strip()

        # ── Split off inline comment ──
        code, comment = self._split_comment(s)
        result = ''

        # ── Top-level statement dispatch ──
        if code:
            result = self._statement(code, raw_stripped=s)

        # ── Attach comment if any ──
        if comment and result:
            result = result + '   $ ' + comment[2:].strip()
        elif comment and not result:
            result = '$ ' + comment[2:].strip()

        return result

    # ── Statement dispatch ───────────────────────────────────────────────

    def _statement(self, code, raw_stripped=''):
        # ── parameters ──
        m = re.match(r'parameters\s+(\S+)\s*=\s*(.+)', code)
        if m:
            return f'.param {m.group(1)}={m.group(2)}'

        # ── model ──
        m = re.match(r'model\s+(\S+)\s+(\S+)\s+(.*)', code)
        if m:
            mname, mtype, mparams = m.group(1), m.group(2), m.group(3).strip().rstrip('/').strip()
            sp_type = {'vswitch': 'sw', 'resistor': 'res', 'capacitor': 'cap',
                       'isource': 'isrc', 'vsource': 'vsrc', 'iprobe': 'isense'}.get(mtype, mtype)
            return f'.model {mname} {sp_type} {mparams}'

        # ── include ──
        m = re.match(r'include\s+"(.+?)"(?:\s+section\s*=\s*(\S+))?', code)
        if m:
            path, section = m.group(1), m.group(2)
            if self.mode == 'hspice' and section:
                return f'.lib "{path}" {section}'
            return f'.include "{path}"'

        # ── global ──
        m = re.match(r'global\s+(.+)$', code)
        if m:
            return '.global ' + self.fix_nodes(m.group(1))

        # ── subckt  /  ends ──
        m = re.match(r'subckt\s+(\S+)\s+(.+)$', code)
        if m:
            return '.subckt ' + m.group(1) + ' ' + self.fix_nodes(m.group(2))

        if re.match(r'ends\s*', code):
            tail = code[4:].strip()
            return f'.ends {tail}' if tail else '.ends'

        # ── simulatorOptions options ... ──
        m = re.match(r'simulatorOptions\s+options\s+(.*)$', code)
        if m:
            return '.options ' + self._convert_options(m.group(1))

        # ── save / saveOptions ──
        if re.match(r'save\s+all', code):
            return '.options post=1' if self.mode == 'hspice' else '.save all'
        if re.match(r'saveOptions\s+', code):
            return ''

        # ── TRAN analysis ──
        m = re.match(r'tran\s+tran\s+(.*)$', code)
        if m:
            return f'.tran {self.get_param(m.group(1), "step", "1e-09")} {self.get_param(m.group(1), "stop", "1e-06")}'

        # ── AC analysis ──
        m = re.match(r'ac\s+ac\s+(.*)$', code)
        if m:
            p = m.group(1)
            return f'.ac dec 10 {self.get_param(p, "start", "1")} {self.get_param(p, "stop", "1e9")}'

        # ── STB → AC ──
        m = re.match(r'stb\s+stb\s+(.*)$', code)
        if m:
            p = m.group(1)
            return f'.ac dec 10 {self.get_param(p, "start", "1")} {self.get_param(p, "stop", "1e9")}   $ STB→AC'

        # ── sweep / data block ──
        if re.match(r'swp\s+sweep\s+paramset\s*=\s*(\S+)', code):
            return ''

        # paramset block header  (e.g. "sweepdata paramset {")
        m = re.match(r'(\w+)\s+paramset\s*\{?\s*$', code)
        if m:
            self.collecting_params = True
            self.param_names = []
            self.sweep_data_rows = []
            return ''

        # Data column header row
        if self.collecting_params and re.match(r'^[a-z_]\S*\s+[a-z_]', code):
            self.param_names = code.split()
            self.collecting_params = False
            self.collecting_sweep_data = True
            return ''

        # Sweep data rows
        if self.collecting_sweep_data and re.match(r'^[\d.eE+\-]', code):
            self.sweep_data_rows.append(code.split())
            return ''

        # Closing brace ends sweep
        if raw_stripped == '}' and self.collecting_sweep_data:
            self.collecting_sweep_data = False
            return self._emit_sweep_data()
        if raw_stripped == '}':
            return ''

        # ── Element instance ──
        result = self._element(code)
        if result is not None:
            return result

        # ── Fallback (pass through, but fix nodes) ──
        # Skip lines where instance name starts with '_' (invalid SPICE prefix)
        first_tok = code.split()[0] if code.split() else ''
        if first_tok.startswith('_'):
            return ''
        # Fix known node names even in fallback
        fixed = self._fix_fallback(code)
        return fixed

    # ── Element conversion ───────────────────────────────────────────────

    def _element(self, code):
        """Try to convert an element line.  Returns SPICE string or None."""
        # ---- Pattern: with parentheses ----
        # INST_NAME (N1 N2 ...) TYPE PARAMS
        m = re.match(r'(\S+)\s+\(([^)]*)\)\s+(.*)', code)
        if m:
            iname = m.group(1)
            ports_raw = m.group(2).strip()
            rest = m.group(3).strip()
            rest_parts = rest.split(None, 1)
            model_type = rest_parts[0] if rest_parts else ''
            params = rest_parts[1] if len(rest_parts) > 1 else ''
            ports = self.fix_nodes(ports_raw)

            r = self._match_instance(iname, ports, model_type, params, code.lower())
            if r is not None:
                return r

        # ---- Pattern: without parentheses (nonstandard Spectre) ----
        # _v1_ n1 n2 resistor r=0
        # INST_NAME  N1 N2 ... TYPE PARAMS
        m2 = re.match(r'(\S+)\s+(\S+(?:\s+\S+)*)\s+(\S+)\s+(.*)', code)
        if m2:
            iname = m2.group(1)
            ports_raw = m2.group(2)
            model_type = m2.group(3)
            params = m2.group(4).strip()
            ports = self.fix_nodes(ports_raw)

            r = self._match_instance(iname, ports, model_type, params, code.lower())
            if r is not None:
                return r

        return None

    def _match_instance(self, iname, ports, model_type, params, code_lower):
        """Match an instance against known Spectre element types."""
        fc = iname[0].lower()

        # ── Resistor ──
        if fc == 'r' and ('resistor' in code_lower or model_type == 'resistor'):
            rval = self.get_param(params, 'r', '1k')
            return f'{iname} {ports} {rval}'

        # ── Capacitor ──
        if fc == 'c' and ('capacitor' in code_lower or model_type == 'capacitor'):
            cval = self.get_param(params, 'c', '1p')
            return f'{iname} {ports} {cval}'

        # ── Current source ──
        if fc == 'i' and ('isource' in code_lower or model_type == 'isource'):
            return self._isource(iname, ports, params)

        # ── Voltage source ──
        if fc == 'v' and ('vsource' in code_lower or model_type == 'vsource'):
            return self._vsource(iname, ports, params)

        # ── iprobe → V-source 0V ──
        if model_type == 'iprobe':
            return f'V{iname} {ports} DC 0'

        # ── vcvs / pcccs ──
        if model_type == 'vcvs':
            return f'E{iname} {ports} {self.get_param(params, "gain", "1")}'
        if model_type == 'pcccs':
            return f'F{iname} {ports} {self.get_param(params, "gain", "1")}'

        # ── MOSFET ──
        if re.match(r'mmosfet_\d+', iname):
            return self._mosfet(iname, ports, params, model_type)
        if re.match(r'(Nmosfetfromvirtuoso|Pmosfetfromvirtuoso)_\d+', iname):
            return self._mosfet(iname, ports, params, model_type)

        # ── Model-based resistors (xrhrpo, xrpposab, etc.) ──
        if iname.startswith('xr') and model_type and model_type[0].islower():
            rval = self.get_param(params, 'r', '1k')
            return f'r_{iname[1:]} {ports} {rval}   $ model={model_type}'

        # ── Subcircuit X-call ──
        if iname[0].lower() == 'x' or (model_type and model_type[0].isupper()):
            return f'{iname} {ports} {model_type}'

        return None

    # ── Element builders ─────────────────────────────────────────────────

    def _vsource(self, iname, ports, params):
        dc_val = self.get_param(params, 'dc')
        ac_val = self.get_param(params, 'ac')
        ptype = self.get_param(params, 'type', '')
        mag = self.get_param(params, 'mag')

        vname = iname if iname[0].upper() == 'V' else 'V' + iname

        # PULSE
        if ptype == 'pulse':
            v0  = self.get_param(params, 'val0', '0')
            v1  = self.get_param(params, 'val1', '1')
            td  = self.get_param(params, 'delay', '0')
            tr  = self.get_param(params, 'rise', '1e-9')
            tf  = self.get_param(params, 'fall', '1e-9')
            pw  = self.get_param(params, 'width', '1e-6')
            per = self.get_param(params, 'period', '2e-6')
            return f'{vname} {ports} PULSE({v0} {v1} {td} {tr} {tf} {pw} {per})'

        # SINE
        if ptype == 'sine':
            return f'{vname} {ports} SIN({dc_val or 0} {mag or 1} 1k)'

        # DC
        if dc_val is not None:
            if ac_val is not None and ac_val not in ('None', '0'):
                return f'{vname} {ports} DC {dc_val} AC {ac_val}'
            if mag is not None:
                return f'{vname} {ports} DC {dc_val} AC {mag}'
            return f'{vname} {ports} DC {dc_val}'

        return f'{vname} {ports} 0'

    def _isource(self, iname, ports, params):
        dc_val = self.get_param(params, 'dc', '0')
        ac_val = self.get_param(params, 'ac')
        iname2 = iname if iname[0].upper() == 'I' else 'I' + iname

        if ac_val is not None and ac_val not in ('None', '0'):
            return f'{iname2} {ports} DC {dc_val} AC {ac_val}'
        return f'{iname2} {ports} DC {dc_val}'

    def _mosfet(self, iname, ports, params, model):
        nodes = ports.split()
        while len(nodes) < 4:
            nodes.append('0')
        d, g, s, b = nodes[0], nodes[1], nodes[2], nodes[3]

        lval = self.clean_param_value(self.get_param(params, 'l', '1e-6'))
        wval = self.clean_param_value(self.get_param(params, 'w', '1e-6'))
        mval = self.clean_param_value(self.get_param(params, 'm', '1'))

        sp = f'L={lval} W={wval} M={mval}'

        for key in ('nf',):
            v = self.get_param(params, key)
            if v is not None:
                sp += f' {key}={self.clean_param_value(v)}'

        return f'{iname} {d} {g} {s} {b} {model} {sp}'

    # ── Options / sweep ──────────────────────────────────────────────────

    @staticmethod
    def _convert_options(opts):
        keep = {'temp', 'tnom', 'reltol', 'vabstol', 'iabstol', 'gmin'}
        return ' '.join(t for t in opts.split() if t.split('=')[0] in keep)

    def _emit_sweep_data(self):
        lines = []
        if self.mode == 'hspice':
            lines.append('.data sweepdata')
            lines.append(' '.join(self.param_names))
            for row in self.sweep_data_rows:
                lines.append(' '.join(row))
            lines.append('.enddata')
            lines.append('.dc data=sweepdata')
        else:
            for n, row in enumerate(self.sweep_data_rows):
                pairs = ', '.join(f'{p}={v}' for p, v in zip(self.param_names, row))
                lines.append(f'* Sweep point {n}: {pairs}')
            lines.append('* ^^^^ ngspice: use .step param or .data for sweep')
        return '\n'.join(lines)

    # ── Fallback ─────────────────────────────────────────────────────────

    @staticmethod
    def _fix_fallback(code):
        """Fix node names in a fallback line that wasn't parsed as an element."""
        # Fix known node references
        code = code.replace('__root_VSS__', '0')
        code = code.replace('__root_VDD__', 'vdd')
        code = code.replace('_vss_', '0')
        code = code.replace('_vdd_', 'vdd')
        return code

    # ── Comment splitter ─────────────────────────────────────────────────

    @staticmethod
    def _split_comment(line):
        depth = 0
        for i, ch in enumerate(line):
            if ch == '(':
                depth += 1
            elif ch == ')':
                depth -= 1
            elif depth == 0 and ch == '/' and i + 1 < len(line) and line[i + 1] == '/':
                return line[:i].strip(), line[i:]
        return line.strip(), ''

    # ── Run ──────────────────────────────────────────────────────────────

    def __call__(self, text):
        out = [f'* SPICE netlist — converted from Spectre SCS ({self.mode})', '']
        for line in text.splitlines():
            r = self.convert(line)
            if r is not None and r != '':
                out.append(r)
        out.extend(['', '.end'])
        return '\n'.join(out)


# ─── CLI ────────────────────────────────────────────────────────────────────

def main():
    argv = sys.argv[1:]
    if not argv:
        print(__doc__)
        return

    mode = 'ngspice'
    infile = outfile = None
    to_stdout = False

    for a in argv:
        if a == '--hspice':
            mode = 'hspice'
        elif a == '--ngspice':
            mode = 'ngspice'
        elif a == '--stdout':
            to_stdout = True
        elif a.startswith('-'):
            print(f'Unknown option: {a}')
            sys.exit(1)
        elif infile is None:
            infile = a
        else:
            outfile = a

    if not infile:
        print('Error: no input file')
        sys.exit(1)

    with open(infile) as f:
        text = f.read()

    result = Scs2Spice(mode=mode)(text)

    if to_stdout:
        print(result)
    else:
        if not outfile:
            outfile = os.path.splitext(infile)[0] + '.sp'
        with open(outfile, 'w') as f:
            f.write(result)
        print(f'OK: {infile} → {outfile}  ({mode})')


if __name__ == '__main__':
    main()
