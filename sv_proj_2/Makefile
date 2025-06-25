TOP_MODULE = top_tb
VERILOG_SOURCES = top_tb.sv mux.sv 

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp $(VERILOG_SOURCES)

run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
