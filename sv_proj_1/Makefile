TOP_MODULE = my_tb
VERILOG_SOURCES = my_tb.sv my_design.sv 

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp $(VERILOG_SOURCES)

run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
