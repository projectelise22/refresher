`timescale 1ns / 1ps

interface fifo_if;
    logic clk, rst;
    logic wr, rd;
    logic full, empty;
    logic [7:0] din;
    logic [7:0] dout;
endinterface

module fifo(fifo_if vif);

    //Pointers, memory has depth of 16
    logic [3:0] wptr = 0, rptr = 0;
    //Counter for tracking number of elements in FIFO
    logic [4:0] cnt = 0;
    //Memory array
    logic [7:0] mem [15:0];

    //Behavior of FIFO    
    always @(posedge vif.clk) begin
        if (vif.rst) begin
            wptr <= 0;
            rptr <= 0;
            cnt <= 0;
        end else if (vif.wr && !vif.full) begin
            mem[wptr] <= vif.din;
            wptr <= wptr + 1;
            cnt <= cnt + 1;
        end else if (vif.rd && !vif.empty) begin
            vif.dout <= mem[rptr];
            rptr <= rptr + 1;
            cnt <= cnt - 1;
        end
    end
    
    assign vif.empty = (cnt == 0)? 1'b1 : 1'b0;
    assign vif.full = (cnt == 16)? 1'b1 : 1'b0;
        
endmodule