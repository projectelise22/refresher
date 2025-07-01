`include "uvm_macros.svh"
import uvm_pkg::*;

module fifo_tb;

  // Instantiate the interface
  fifo_if fifo_if_inst();

  // DUT instantiation
  sync_fifo #(.DATA_WIDTH(8), .DEPTH(16)) dut (
    .clk    (fifo_if_inst.clk),
    .rst_n  (fifo_if_inst.rst_n),
    .wr_en  (fifo_if_inst.wr_en),
    .rd_en  (fifo_if_inst.rd_en),
    .din    (fifo_if_inst.din),
    .dout   (fifo_if_inst.dout),
    .full   (fifo_if_inst.full),
    .empty  (fifo_if_inst.empty)
  );
  
  initial begin
    // Connect interface to UVM via config_db
    uvm_config_db#(virtual fifo_if)::set(null, "*", "vif", fifo_if_inst);
    run_test("fifo_test");
  end
  
  initial begin
    fifo_if_inst.rst_n = 0;
    #10 fifo_if_inst.rst_n = 1;
  end

  // Clock generation
  initial begin
    fifo_if_inst.clk = 0;
    forever #5 fifo_if_inst.clk = ~fifo_if_inst.clk;
  end

endmodule