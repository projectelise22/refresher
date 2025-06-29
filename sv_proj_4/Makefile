TOP_MODULE = tb
VERILOG_SOURCES = tb.sv

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp $(VERILOG_SOURCES) --top-module tb


run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
