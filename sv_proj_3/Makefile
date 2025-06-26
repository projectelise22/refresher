TOP_MODULE = tb_1
VERILOG_SOURCES = tb_1.sv dut_1.sv 

all:
	verilator --cc --timing --exe --trace --build sim_main.cpp tb_1.sv dut_1.sv --top-module tb_1


run: all
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir wave.vcd
