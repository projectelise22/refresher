// sim_main.cpp
// C++ test harness that Verilator uses to simulate the Verilog design
// and generate a VCD waveform
#include "Vtop_tb.h"
#include "verilated.h"
#include "verilated_vcd_c.h"

vluint64_t main_time = 0;

double sc_time_stamp() { return main_time; }

int main(int argc, char **argv) {
    Verilated::commandArgs(argc, argv);
    Vtop_tb *top = new Vtop_tb;
    VerilatedVcdC *tfp = new VerilatedVcdC;
    Verilated::traceEverOn(true);
    top->trace(tfp, 99);
    tfp->open("wave.vcd");

    while (!Verilated::gotFinish()) {
        top->eval();
        tfp->dump(main_time);
        main_time++;
    }

    tfp->close();
    delete top;
    return 0;
}
