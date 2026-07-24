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

# Verify 0 cvtss2sd in application code
verify: $(TARGET)
	@echo "=== cvtss2sd instruction count ==="
	@objdump -d $(TARGET) | grep -c "cvtss2sd" || echo "0"
	@echo "(Expected: 0 in application code; libm printf internals excluded)"

# Quick test on NMOS DC
test: $(TARGET)
	./$(TARGET) ../test/circuits/mx/mx_nmos_dc.sp
