# cvtss2sd Verification Guide

## Overview

`cvtss2sd` (Convert Scalar Single-Precision to Scalar Double-Precision) is the x86-64 instruction that converts a `float` to a `double`. Our goal: **zero cvtss2sd in application code**.

## Quick Check

```bash
# Build the zero-double engine
cd float_spice && make

# Count cvtss2sd instructions
objdump -d float_spice | grep -c "cvtss2sd"
```

## Methodology

### Step 1: Build the binary

```bash
# float_spice (from-scratch zero-double engine)
cd float_spice
gcc -O2 -Wall -o float_spice float_spice.c -lm

# OR for the retrofitted ngspice approach:
cd ..
bash scripts/build.sh -j $(nproc)
```

### Step 2: Disassemble and count

```bash
# Full disassembly, filter for cvtss2sd
objdump -d float_spice | grep -c "cvtss2sd"

# Show which functions contain cvtss2sd
objdump -d float_spice | grep -B1 "cvtss2sd" | grep "^[0-9a-f]" | head -20

# Count by section
objdump -d float_spice | grep -c "cvtss2sd"
```

### Step 3: Expected results

| Binary | cvtss2sd count | Source |
|--------|:---:|--------|
| `float_spice` (POC v1) | **3** | libm printf internals only |
| `float_spice_v2` | **~20** | `(double)` casts in printf (output only) |
| Vanilla ngspice-46 | **~5000+** | All math is double |
| Mixed_ngspice v1.2 | **~2192** | Mixed FP32/FP64 |
| Mixed_ngspice v1.9 | **~632** | After `-fsingle-precision-constant` |

### Understanding cvtss2sd sources

1. **Application math** (eliminated): `(double)float_var`, implicit float→double in expressions
2. **libm printf internals** (unavoidable in standard C): `printf("%f", float_var)` promotes float to double per C variadic rules. Count = number of unique printf call sites with float args.
3. **libm math functions** (avoidable): `sin(float)` implicitly converts to `sin(double)`. Use `sinf()` instead.

### How to reduce cvtss2sd further

```c
// BAD: generates cvtss2sd
printf("value = %f\n", (double)float_val);

// BAD: also generates cvtss2sd (variadic promotion)
printf("value = %f\n", float_val);

// GOOD: use integer formatting to avoid float→double
void print_float(float v) {
    int ip = (int)v;
    int frac = (int)((v - ip) * 1000000.0f + 0.5f);
    printf("%d.%06d", ip, frac);  // No cvtss2sd! (int args)
}
```

### Verification in CI

Add to `.github/workflows/test.yml`:

```yaml
- name: Verify zero cvtss2sd
  run: |
    cd float_spice && make
    CVD=$(objdump -d float_spice | grep -c "cvtss2sd" || echo "0")
    echo "cvtss2sd count: $CVD"
    if [ "$CVD" -gt 10 ]; then
      echo "WARNING: cvtss2sd count ($CVD) exceeds target (<10)"
    fi
```

## float_spice Zero-Double Design Principles

1. **REAL=float**: All computation uses `float`, never `double`
2. **R() macro**: Float literals use `R(1.0)` → `1.0f`
3. **Math functions**: Always `float` variants: `sinf()`, `cosf()`, `expf()`, `logf()`, `sqrtf()`, `fabsf()`, `powf()`
4. **No implicit conversion**: Never assign float to double, never pass float to double parameter
5. **Output**: Use integer-based float formatting to avoid variadic printf promotion
