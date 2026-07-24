# float_spice Makefile — Zero-Double Float-First SPICE Engine
CC       = gcc
CFLAGS   = -O2 -Wall -Wextra
LDFLAGS  = -lm
TARGET   = float_spice
SRC      = float_spice.c

.PHONY: all clean verify test

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $@ $< $(LDFLAGS)

clean:
	rm -f $(TARGET)

# Verify ≤5 cvtss2sd in application code (P4.6: CI enforcement)
verify: $(TARGET)
	@echo "=== cvtss2sd instruction count ==="
	@COUNT=$$(objdump -d $(TARGET) | grep -c "cvtss2sd" || echo "0"); \
	echo "$$COUNT"; \
	if [ "$$COUNT" -le 5 ]; then \
		echo "✅ PASS: cvtss2sd count ($$COUNT) ≤ 5 — zero-double in application code"; \
	else \
		echo "❌ FAIL: cvtss2sd count ($$COUNT) > 5 — double promotion detected in application code"; \
		exit 1; \
	fi

# Quick test on NMOS DC
test: $(TARGET)
	./$(TARGET) ../test/circuits/mx/mx_nmos_dc.sp
