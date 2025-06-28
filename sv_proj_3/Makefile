TOP_MODULE = tb_3
VERILOG_SOURCES = tb_3.sv dut_1.sv 

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp tb_3.sv dut_1.sv --top-module tb_3


run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
