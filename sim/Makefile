# =============================
# HDL Test Makefile (per-testbench filelist)
# =============================

# Tools
IVERILOG := iverilog
VVP      := vvp
GTKWAVE  := gtkwave

# Default parameters
TB       ?=
PARAMS   ?=

# Detect all testbenches
TESTBENCHES := $(wildcard *_tb.sv)
TB_MODULES  := $(patsubst %.sv,%,$(TESTBENCHES))

# Output files
OUT      := $(TB)_sim.vvp
VCD_FILE := $(TB).vcd

# -----------------------------
# PHONY targets
# -----------------------------
.PHONY: all run clean list sweep waves help precheck

# Default target
all: run

# -----------------------------
# Help
# -----------------------------
help:
	@echo "Usage: make <target> TB=<testbench> [PARAMS=\"PARAM1=VALUE1 PARAM2=VALUE2\"]"
	@echo ""
	@echo "Targets:"
	@echo "  all       - Default: run selected testbench (requires TB)"
	@echo "  run       - Compile and run simulation for TB"
	@echo "  waves     - Open waveform in GTKWave after running"
	@echo "  list      - List all available testbenches"
	@echo "  sweep     - Run all testbenches found"
	@echo "  clean     - Remove generated .vvp and .vcd files"
	@echo "  help      - Show this help message"

# -----------------------------
# List testbenches
# -----------------------------
list:
	@echo "Available testbenches:"
	@for tb in $(TB_MODULES); do \
		echo "  $$tb"; \
	done

# -----------------------------
# Pre-check TB and filelist
# -----------------------------
precheck:
	@if [ -z "$(TB)" ]; then \
		echo "Error: No testbench specified. Use 'make run TB=<testbench>'"; \
		exit 1; \
	fi
	@if [ ! -f "$(TB).files" ]; then \
		echo "Error: Filelist $(TB).files not found. Create a .files file listing RTL sources for $(TB)"; \
		exit 1; \
	fi
	@echo "Checking RTL files in $(TB).files..."
	@missing=0; \
	for f in $$(cat $(TB).files); do \
	  if [ ! -f "$$f" ]; then \
	    echo "WARNING: RTL file $$f not found!"; \
	    missing=1; \
	  fi; \
	done; \
	if [ $$missing -eq 1 ]; then \
	  echo "One or more RTL files are missing, aborting compile."; \
	  exit 1; \
	fi

# -----------------------------
# Convert PARAMS string into Icarus arguments
# -----------------------------
PARAM_FLAGS := $(foreach p,$(PARAMS),-P$(TB).$(p))

# -----------------------------
# Compile target
# -----------------------------
$(OUT): precheck
	@echo "Compiling testbench $(TB) with parameters: $(PARAMS)"
	$(IVERILOG) -g2012 -o $(OUT) \
	  $(PARAM_FLAGS) \
	  $(shell cat $(TB).files) \
	  $(TB).sv

# -----------------------------
# Run simulation
# -----------------------------
run: $(OUT)
	@echo "Running simulation for $(TB)..."
	$(VVP) $(OUT)
	@if [ -f $(VCD_FILE) ]; then \
		echo "VCD file found: $(VCD_FILE)"; \
	else \
		echo "Warning: VCD file $(VCD_FILE) not found!"; \
	fi

# -----------------------------
# View waveform
# -----------------------------
waves: run
	$(GTKWAVE) $(VCD_FILE)

# -----------------------------
# Sweep: run all testbenches
# -----------------------------
sweep:
	@for tb in $(TB_MODULES); do \
		echo "=== Running $$tb ==="; \
		make run TB=$$tb PARAMS="$(PARAMS)"; \
	done

# -----------------------------
# Clean
# -----------------------------
clean:
	rm -f *_sim.vvp *.vcd
