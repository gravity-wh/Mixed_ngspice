# float_spice Makefile — Zero-Double Float-First SPICE Engine
CC       = gcc
CFLAGS   = -O1 -Wall -Wextra -DSPICE_REAL=float -UUSE_OMP -I. -Ibsim4v5
# Suppress warnings in external ngspice-derived code
BSIM4V5_CFLAGS = $(CFLAGS) -Wno-unused-but-set-variable -Wno-unused-variable
LDFLAGS  = -lm
TARGET   = float_spice.exe

# ngspice-derived BSIM4v5 evaluation code (FP32-patched, zero-double)
BSIM4V5_SRC = bsim4v5/b4v5ld.c bsim4v5/b4v5temp.c
BSIM4V5_OBJ = $(BSIM4V5_SRC:.c=.o)

SRC      = float_spice.c

.PHONY: all clean check test-nmos test-pmos test-inv

all: $(TARGET)

$(TARGET): $(SRC) $(BSIM4V5_OBJ)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)

bsim4v5/%.o: bsim4v5/%.c
	$(CC) $(BSIM4V5_CFLAGS) -c $< -o $@

clean:
	rm -f $(TARGET) $(BSIM4V5_OBJ)

# Verify zero warnings
check: $(TARGET)
	@W=$$($(CC) $(CFLAGS) -fsyntax-only $(SRC) 2>&1 | grep -c warning || true); \
	if [ "$$W" -eq 0 ]; then echo "CHECK: 0 warnings PASS"; else echo "CHECK: $$W warnings FAIL"; exit 1; fi

# Single-device DC tests
test-nmos: $(TARGET)
	./$(TARGET) tests/test_nmos_dc.sp

test-pmos: $(TARGET)
	./$(TARGET) tests/test_pmos_dc.sp

test-inv: $(TARGET)
	./$(TARGET) tests/test_inv2.sp

# Convenience: run all quick tests
test: test-nmos test-pmos test-inv
