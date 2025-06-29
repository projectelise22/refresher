`timescale 1ns / 1ps

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
    
    initial begin
        intf.clk <= 0;
    end
    
    always #10 intf.clk <= ~intf.clk;

    initial begin
        intf.resetn = 0;
        #50;
        intf.resetn = 1;
    end
    
 fifo_gen generator;
 fifo_drv driver;
 mailbox gen2drv;
 
//Test Setup
initial begin
    //Construct components
    gen2drv = new();
    generator = new(5, gen2drv);
    driver = new(intf, gen2drv);

    //Run components
    fork 
        generator.run();
        driver.run();
    join
end

initial begin
    #500;
    $finish;
end
endmodule