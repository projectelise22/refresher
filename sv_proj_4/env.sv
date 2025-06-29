//FIFO IF interface
interface fifo_if #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
);
    logic clk;
    logic resetn;
    logic wr_en;
    logic rd_en;
    logic [DATA_WIDTH-1:0] din;
    
    logic [DATA_WIDTH-1:0] dout;
    logic full;
    logic empty;

//For driver
    modport drv_mp (
        input clk, resetn, full, empty, dout,
        output wr_en, rd_en, din
    );
    
//For monitor
    modport mon_mp (
        input clk, resetn, wr_en, rd_en, din, dout, full, empty
    );
endinterface: fifo_if

//FIFO transaction
class fifo_trans;
    //Control signals
    rand bit wr_en;
    rand bit rd_en;

    //Data signals
    rand bit [7:0] din;

    //Output signals from DUT
    bit [7:0] dout;
    bit full;
    bit empty;

    //Print details
    function void print_trans(string tag="TRANS");
        $display("[%0s] wr_en = %0d, rd_en = %0d, din = %0d", tag, wr_en, rd_en, din);
        $display("[%0s] full = %0d, empty = %0d, dout = %0d", tag, full, empty, dout);
    endfunction: print_trans

endclass: fifo_trans

//FIFO generator
class fifo_gen;
    mailbox gen2drv;
    int trans_count;
    fifo_trans t;

    //Constructor
    function new(int no_trans, mailbox gen2drv);
        this.gen2drv = gen2drv;
        this.trans_count = no_trans;
    endfunction

    task run();
        for(int i=0; i<this.trans_count; i++) begin
            t = new();
            assert(t.randomize());

            this.gen2drv.put(t);
            t.print_trans("GEN");
            #10;
        end
    endtask: run 

endclass: fifo_gen

//FIFO driver
class fifo_drv;
    virtual fifo_if vif;
    mailbox gen2drv;
    fifo_trans t;
    
    function new(virtual fifo_if vif, mailbox gen2drv);
        this.vif = vif;
        this.gen2drv = gen2drv;
    endfunction
    
    task run();
        forever begin
            //do only while resetn is not active
             wait(vif.resetn == 1);
            //create transaction object
            this.gen2drv.get(t);
            
            //Drive Signals from generator
            #10;
            $display("[DRV] Waiting for transaction at time %0d", $time);
            vif.wr_en <= t.wr_en;
            vif.rd_en <= t.rd_en;
            vif.din <= t.din;
            
            //Wait for clock then get response
            @(posedge vif.clk)
            t.dout = vif.dout;
            t.full = vif.full;
            t.empty = vif.empty;
            
            t.print_trans("DRV");
            #10;
        end
    endtask;
endclass: fifo_drv