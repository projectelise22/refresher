TOP_MODULE = tb_2
VERILOG_SOURCES = tb_2.sv dut_1.sv 

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp tb_2.sv dut_1.sv --top-module tb_2


run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
