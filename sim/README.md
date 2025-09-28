# HDL Simulation Environment

This repository contains a **general HDL simulation Makefile** that can compile and run SystemVerilog testbenches using Icarus Verilog.  

It is designed to:  

- Compile **only the source files needed** for each testbench.  
- Support **parameters** for each design.  
- List available testbenches.  
- Run all testbenches in a sweep.  
- Check for missing RTL files and warn before compiling.  

---

## Directory Structure

```
sim/
├─ clk_divider_tb.sv          # Example testbench
├─ clk_divider_tb.files       # List of RTL sources used by testbench
├─ uart_tb.sv                 # Another testbench
├─ uart_tb.files              # List of RTL sources used by testbench
├─ Makefile                   # The general simulation Makefile
```

Each `<testbench>.files` should contain a **list of RTL source files** required for that testbench (one per line or space-separated).  

### Example: `clk_divider_tb.files`

```bash
../rtl/common/basic/clk_divider.sv
```

> Make sure the paths are relative to the `sim/` directory.

---

## Makefile Targets

### 1. List available testbenches

```bash
make list
```

Prints all `*_tb.sv` testbenches available to run.

---

### 2. Compile and run a single testbench

```bash
make run TB=<testbench> PARAMS="PARAM1=VALUE1 PARAM2=VALUE2" DEFINES="MACRO1 MACRO2=VALUE"
```

Examples:

``` bash
make run TB=clk_divider_tb PARAMS="DIV=7"
make run TB=debounce_tb DEFINES="DIV=4 DEBUG"
```

- Compiles only the RTL files listed in `clk_divider_tb.files`.  
- Passes parameters to the testbench (if it has parametrizable modules).  
- Produces a simulation output file: `clk_divider_tb_sim.vvp`.  
- Expects your testbench to generate a waveform file with the same name as the testbench, e.g., `clk_divider_tb.vcd`.

---

### 3. View waveforms

```bash
make waves TB=<testbench>
```

- Runs the simulation (if not already run) and opens GTKWave with the VCD file that **your testbench generated**, e.g., `clk_divider_tb.vcd`.

---

### 4. Run all testbenches (sweep)

```bash
make sweep
```

- Runs all `*_tb.sv` testbenches sequentially.  
- Uses the same parameter overrides for each testbench.

---

### 5. Clean outputs

```bash
make clean
```

- Removes all simulation output files (`*_sim.vvp`, `*.vcd`).

---

## RTL File Check

Before compiling, the Makefile checks that all RTL files listed in `<testbench>.files` exist.  

- If any file is missing, the Makefile prints a warning and aborts compilation.  
- This helps catch typos or missing RTL sources early.

---

## Adding a New Testbench

To add a new testbench:

1. Create a SystemVerilog testbench file, e.g.:

```
sim/new_tb.sv
```

2. Create a corresponding `.files` list:

```
sim/new_tb.files
```

Example `new_tb.files`:

```
../rtl/common/basic/ff.sv
../rtl/projects/sample_project/src/other_module.sv
```

3. Make sure your testbench writes its VCD file using:

```systemverilog
$dumpfile("new_tb.vcd");
```

4. Run your new testbench:

```bash
make run TB=new_tb PARAMS="PARAM1=VALUE"
```

You do **not** need to edit the Makefile — it automatically detects all `*_tb.sv` files.

---

## Example Testbench Snippet

`clk_divider_tb.sv` example:

```verilog
`timescale 1ns/1ps

module clk_divider_tb;

parameter DIV = 5;

logic clk;
logic rst;
logic clk_out;

// Instantiate DUT
clk_divider #(.DIV(DIV)) dut (
    .rst(rst),
    .clk_in(clk),
    .clk_out(clk_out)
);

initial begin
    clk = 0;
    forever #5 clk = ~clk;
end

initial begin
    rst = 1;
    #20 rst = 0;
end

initial begin
    $dumpfile("clk_divider_tb.vcd");  // must match testbench name
    $dumpvars(0, clk_divider_tb);
    #200 $finish;
end

endmodule
```

---

## Notes

- All paths in `.files` lists must be correct and relative to `sim/`.  
- The Makefile is **general-purpose**: add any testbench by creating its `.sv` and `.files`.  
- Supports passing arbitrary parameters via `PARAMS`.  
- Only the files listed in the `.files` list are compiled, so unrelated RTL is ignored.  
- VCD file name **must match the testbench name**, e.g., `clk_divider_tb.vcd`.

---

This README ensures your workflow is simple: the Makefile handles compilation, running, and GTKWave viewing, while the testbench controls the VCD filename.
