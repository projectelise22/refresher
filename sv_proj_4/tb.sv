`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.06.2025 16:55:25
// Design Name: 
// Module Name: tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb();
    //Interface
    fifo_if intf();
    
    //Instantiate DUT
    sync_fifo i_fifo(
        .clk    (intf.clk),
        .rst_n  (intf.resetn),
        .wr_en  (intf.wr_en),
        .rd_en  (intf.rd_en),
        .din    (intf.din),
        .dout   (intf.dout),
        .full   (intf.full),
        .empty  (intf.empty)
    );

// Initialize and generate clock    
    initial begin
        intf.clk <= 0;
    end
    
    always #10 intf.clk <= ~intf.clk;

// Initialize and run reset
    initial begin
        intf.resetn = 0;
        #50;
        intf.resetn = 1;
    end

 // Instantiate tb components   
 fifo_gen generator;
 fifo_drv driver;
 mailbox gen2drv;
 fifo_mon monitor;
 fifo_scb scoreboard;
 mailbox #(fifo_trans) mon2scb;
 
//Test Setup
initial begin
    //Construct components
    gen2drv = new();
    generator = new(5, gen2drv, BOTH);
    driver = new(intf, gen2drv);
    
    mon2scb = new();
    monitor = new(intf, mon2scb);
    scoreboard = new(mon2scb);
   
    //Run components
    fork 
        generator.run();
        driver.run();
        monitor.run();
        scoreboard.run();
    join
end

initial begin
    #500;
    $finish;
end
endmodule
