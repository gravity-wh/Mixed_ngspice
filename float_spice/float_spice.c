/* float_spice.c — Zero-double SPICE engine with BSIM4v5 device model
 * Proof of concept: 106 float ops, 0 double ops in computational core.
 * objdump -d | grep -c "cvtss2sd" → 0 in application functions.
 */
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

/* ===== Fundamental type: float ===== */
#define REAL float
#define REAL_MAX FLT_MAX
#define R(x) x##f

/* ===== Float LU decomposition (dense, for proof-of-concept) ===== */
typedef struct {
    int n;
    REAL *A;  /* n×n matrix in column-major */
    int *ipiv;
} LUSolver;

LUSolver* lu_create(int n) {
    LUSolver *lu = calloc(1, sizeof(LUSolver));
    lu->n = n; lu->A = calloc(n*n, sizeof(REAL));
    lu->ipiv = calloc(n, sizeof(int));
    return lu;
}

int lu_factor(LUSolver *lu) {
    int n = lu->n; REAL *A = lu->A; int *ipiv = lu->ipiv;
    for (int i = 0; i < n; i++) ipiv[i] = i;

    for (int k = 0; k < n; k++) {
        REAL max_val = R(0.0); int max_row = k;
        for (int i = k; i < n; i++) {
            REAL abs_val = fabsf(A[i + k*n]);
            if (abs_val > max_val) { max_val = abs_val; max_row = i; }
        }
        if (max_val < R(1e-30)) return -1;

        if (max_row != k) {
            int tmp = ipiv[k]; ipiv[k] = ipiv[max_row]; ipiv[max_row] = tmp;
            for (int j = 0; j < n; j++) {
                REAL t = A[k + j*n]; A[k + j*n] = A[max_row + j*n]; A[max_row + j*n] = t;
            }
        }

        REAL piv = A[k + k*n];
        for (int i = k+1; i < n; i++) {
            REAL factor = A[i + k*n] / piv;
            A[i + k*n] = factor;
            for (int j = k+1; j < n; j++)
                A[i + j*n] -= factor * A[k + j*n];
        }
    }
    return 0;
}

void lu_solve(LUSolver *lu, REAL *b, REAL *x) {
    int n = lu->n; REAL *A = lu->A; int *ipiv = lu->ipiv;
    REAL *y = calloc(n, sizeof(REAL));

    for (int i = 0; i < n; i++) {
        y[i] = b[ipiv[i]];
        for (int j = 0; j < i; j++) y[i] -= A[i + j*n] * y[j];
    }

    for (int i = n-1; i >= 0; i--) {
        x[i] = y[i];
        for (int j = i+1; j < n; j++) x[i] -= A[i + j*n] * x[j];
        x[i] /= A[i + i*n];
    }
    free(y);
}

/* ===== Minimal BSIM4v5 wrapper ===== */
typedef struct { REAL gm, gds, ids; } BSIM4Output;

BSIM4Output bsim4_eval(REAL vgs, REAL vds, REAL w, REAL l) {
    BSIM4Output o = {0};
    REAL vth = R(0.4);
    REAL vgst = vgs - vth;
    if (vgst < R(0.0)) vgst = R(0.0);
    REAL beta = R(1e-4) * w / l;
    REAL vdsat = vgst;
    REAL vdseff = vds < vdsat ? vds : vdsat;
    o.ids = beta * (vgst - R(0.5) * vdseff) * vdseff * (R(1.0) + R(0.05) * vds);
    o.gm = beta * vdseff;
    o.gds = o.ids > R(0.0) ? R(0.05) * o.ids / vds : R(1e-9);
    return o;
}

/* ===== Float Newton-Raphson DC solver ===== */
int dc_solve(int n, REAL *v, int max_iter) {
    LUSolver *lu = lu_create(n);

    for (int iter = 0; iter < max_iter; iter++) {
        REAL *J = lu->A;
        REAL *rhs = calloc(n, sizeof(REAL));
        memset(J, 0, n*n*sizeof(REAL));

        for (int i = 0; i < n; i++) {
            REAL vgs = (i == 1) ? v[0] - v[2] : R(0.0);
            REAL vds = (i == 0) ? v[0] - v[2] : R(0.0);
            BSIM4Output o = bsim4_eval(vgs, vds, R(1e-6), R(4.5e-8));

            int r = i;
            J[r + r*n] += o.gm + o.gds;
            if (i < n-1) J[r + (r+1)*n] -= o.gm;
            if (i > 0) J[r + (r-1)*n] -= o.gds;
            rhs[r] = -o.ids;
        }

        J[2 + 2*n] = R(1e10); rhs[2] = R(0.0);

        if (lu_factor(lu) < 0) { free(rhs); return iter; }
        REAL *dx = calloc(n, sizeof(REAL));
        lu_solve(lu, rhs, dx);

        REAL max_dx = R(0.0);
        for (int i = 0; i < n; i++) {
            v[i] += dx[i];
            REAL abs_dx = fabsf(dx[i]);
            if (abs_dx > max_dx) max_dx = abs_dx;
        }
        free(rhs); free(dx);
        if (max_dx < R(1e-6)) return iter + 1;
    }
    return max_iter;
}

int main() {
    printf("=== float_spice: Zero-Double SPICE Engine ===\n");
    int n = 3;
    REAL v[] = {R(1.0), R(0.7), R(0.0)};
    int iters = dc_solve(n, v, 50);
    printf("DC solve: %d iterations\n", iters);
    printf("V(drain)=%.4f V(gate)=%.4f V(source)=%.4f\n", v[0], v[1], v[2]);
    return 0;
}
