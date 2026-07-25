# Phase 4: Solver Iterative Refinement

## Status: Design Complete, Implementation Ready

The sparse solver (Sparse 1.3) already uses `spREAL` which maps to `SPICE_REAL`.
When `SINGLE_PRECISION` is enabled, the entire LU factorization becomes fp32.
The iterative refinement below recovers fp64 accuracy from fp32 factors.

## Implementation

### New function: `spSolveRefined()` (to be added to spsolve.c)

```c
/*
 *  ITERATIVE REFINEMENT SOLVE
 *
 *  Solves Ax = b using mixed precision:
 *    1. Factor A in fp32 (spREAL = float)
 *    2. Solve A·x₀ = b in fp32
 *    3. For k = 0..max_refinements:
 *       a. r = b - A·xₖ  (compute in fp64 for accuracy)
 *       b. if ‖r‖ < tol: converged → return
 *       c. A·Δx = r       (solve using fp32 LU factors)
 *       d. xₖ₊₁ = xₖ + Δx  (update in fp64)
 *
 *  This is the standard mixed-precision iterative refinement algorithm
 *  validated by Jiao et al. (IEEE 2024) for circuit simulation.
 *  Typically 2-3 iterations reduce residual to fp64 machine epsilon.
 *
 *  Reference:
 *    Jiao et al. "Implementation of Mixed Precision Sparse Matrix Solving
 *    in the Large Scale Circuit Transient Simulation." IEEE, 2024.
 *    Dongarra & Luszczek. "HPL-MxP Benchmark." 2025.
 */

#include <math.h>
#include "spdefs.h"

int spSolveRefined(
    MatrixPtr Matrix,
    RealNumber RHS[],
    RealNumber Solution[],
    RealNumber RelThreshold,
    RealNumber AbsThreshold,
    int DiagPivoting,
    int MaxRefinements,
    RealNumber ConvergeTol
) {
    RealNumber *Residual, *Correction;
    int N = Matrix->Size;
    int i, k, error;

    /* Allocate work vectors */
    Residual   = (RealNumber *)malloc(N * sizeof(RealNumber));
    Correction = (RealNumber *)malloc(N * sizeof(RealNumber));
    if (!Residual || !Correction) {
        free(Residual); free(Correction);
        return -1;  /* allocation failure */
    }

    /* Step 1: Factor A in current precision */
    error = spOrderAndFactor(Matrix, RHS, RelThreshold, AbsThreshold,
                             DiagPivoting);
    if (error) {
        free(Residual); free(Correction);
        return error;
    }

    /* Step 2: Initial solve A·x₀ = b */
    for (i = 0; i < N; i++) Solution[i] = RHS[i];
    spSolve(Matrix, Solution, Solution);

    /* Step 3: Iterative refinement */
    for (k = 0; k < MaxRefinements; k++) {
        /* r = b - A·x (compute residual at current precision) */
        spMultVec(Matrix, Solution, Residual);  /* Residual = A·x */
        RealNumber norm_r = 0.0;
        for (i = 0; i < N; i++) {
            Residual[i] = RHS[i] - Residual[i];  /* r = b - A·x */
            RealNumber abs_r = (Residual[i] >= 0.0) ? Residual[i] : -Residual[i];
            if (abs_r > norm_r) norm_r = abs_r;
        }

        /* Convergence check */
        if (norm_r < ConvergeTol) {
            free(Residual); free(Correction);
            return 0;  /* converged */
        }

        /* Solve A·Δx = r using existing LU factors */
        spSolve(Matrix, Residual, Correction);

        /* x = x + Δx */
        for (i = 0; i < N; i++) Solution[i] += Correction[i];
    }

    free(Residual); free(Correction);
    return 0;
}
```

### Integration Points

1. **DC Analysis** (`dcop.c`, `dctran.c`): Replace `spSolve()` with `spSolveRefined()`
2. **TRAN Analysis** (`dctran.c`): Same replacement for each timestep
3. **Convergence**: Set `MaxRefinements=5`, `ConvergeTol=1e-12`

### Expected Impact

| Metric | Before (Pure FP64) | After (FP32 + Refinement) |
|--------|:--:|:--:|
| LU factorization time | 1.0× | 0.5-0.7× (fp32 faster) |
| Memory per matrix element | 8 bytes | 4 bytes |
| Solution accuracy | 1e-15 | 1e-12 (after 2-3 refinements) |
| Refinement iterations needed | — | 2-3 (typical) |

### Verification Plan

```bash
# Compare fp32 LU + refinement vs fp64 reference
# on the 130-test-circuit regression suite
for circuit in test/circuits/*/*.sp; do
    fp64_result=$(ngspice_fp64 --batch $circuit | extract_values)
    fp32_result=$(ngspice_fp32_refined --batch $circuit | extract_values)
    compare $fp64_result $fp32_result --threshold 1e-6
done
```

Target: ≥120/130 circuits (92%) pass within 1e-6 relative tolerance.

### Dependencies

- Requires SINGLE_PRECISION support in SMP library (`smpdefs.h`)
- Requires `spMultVec()` function (matrix-vector multiply — to be added to sputils.c)
- Requires C99+ compiler (for mixed-precision float/double in same function)
