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
        $timeformat(-9, 3, " ns", 10);
        $display("[time: 0%t]Transaction========================", $realtime);
        $display("[%0s] wr_en = 0x%0h, rd_en = 0x%0h, din = 0x%0h", tag, wr_en, rd_en, din);
        $display("[%0s] full = 0x%0h, empty = 0x%0h, dout = 0x%0h", tag, full, empty, dout);
    endfunction: print_trans

endclass: fifo_trans

typedef enum {WR_ONLY, RD_ONLY, BOTH, INV_WR, INV_RD} gen_mode_t;

//FIFO generator
class fifo_gen;
    mailbox gen2drv;
    int trans_count;
    fifo_trans t;
    gen_mode_t mode;

    //Constructor
    function new(int no_trans, mailbox gen2drv, gen_mode_t mode);
        this.gen2drv = gen2drv;
        this.trans_count = no_trans;
        this.mode = mode;
    endfunction

    task run();
        bit success = 1'b0;
        for(int i=0; i<this.trans_count; i++) begin
            t = new();
            case(this.mode)
                WR_ONLY: success = t.randomize() with {wr_en == 1; rd_en == 0; };
                RD_ONLY: success = t.randomize() with {wr_en == 0; rd_en == 1; };
                BOTH:    success = t.randomize() with {wr_en == 1; rd_en == 1; };
                default: success = t.randomize() with {wr_en == 1; rd_en == 0; };
            endcase
            
            assert(success) else
                $error("[GEN] Randomization failed for mode %0s", this.mode);
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
    
    task reset_signals();
        this.vif.wr_en = 1'b0;
        this.vif.rd_en = 1'b0;
        this.vif.din   = 0;
    endtask
    
    task run();
        //initialize inputs and start after resetn is not active
        reset_signals();
        wait(this.vif.resetn == 1);
        forever begin            
            //create transaction object
            this.gen2drv.get(t);
            
            //Check FIFO Full
            if(t.wr_en) begin
                if(t.full) begin
                    assert(t.full == 1) else $error("[ASSERT] Write attempted when FIFO_FULL");
                end
            end
            
            //Drive Signals from generator
            #10;
            $display("[DRV] Waiting for transaction at time %0d", $time);
            vif.wr_en <= t.wr_en;
            vif.rd_en <= t.rd_en;
            vif.din <= t.din;
            
            t.print_trans("DRV");
            #10;
        end
    endtask;
endclass: fifo_drv

//FIFO Monitor
class fifo_mon;
    virtual fifo_if vif;
    fifo_trans t;
    mailbox #(fifo_trans) mon2scb;

    function new(virtual fifo_if vif, mailbox #(fifo_trans) mon2scb);
        this.mon2scb = mon2scb;
        this.vif = vif;
    endfunction

    task run();
        t = new();
        forever begin
            @(posedge this.vif.clk)
                if(!vif.resetn) continue;
                //Input Signals
                t.wr_en = this.vif.wr_en;
                t.rd_en = this.vif.rd_en;
                t.din = this.vif.din;

                //Output Signals
                t.dout = this.vif.dout;
                t.full = this.vif.full;
                t.empty = this.vif.empty;

                //Put to mailbox
                this.mon2scb.put(t);
                t.print_trans("MON");
        end
    endtask
endclass: fifo_mon

//FIFO Scoreboard
class fifo_scb;
    fifo_trans t;
    mailbox #(fifo_trans) mon2scb;
    
    bit [31:0] ref_model_q [$];
    bit [7:0] expected = 0;

    function new(mailbox #(fifo_trans) mon2scb);
        this.mon2scb = mon2scb;
        ref_model_q = {};
    endfunction

    task run();
        forever begin
            mon2scb.get(t);
            
            //Get valid written din
            if(t.wr_en && !t.full) begin
                ref_model_q.push_back(t.din);
                t.print_trans("SCB");
            end
            
            //Get valid read dout and compare per dout
            if(t.rd_en && !t.empty) begin
                if($size(ref_model_q) == 0) begin
                    $error("[SCB] Read from empty queue, no written data");
                end else begin
                    expected = ref_model_q.pop_front();
                    if(expected == t.dout)
                        $display("[SCB] Compare OK expected = 0x%0h, actual = 0x%0h", expected, t.dout);
                    else
                        $error("[SCB] Compare OK expected = 0x%0h, actual = 0x%0h", expected, t.dout); 
                end
            end
            #20;
        end
    endtask
endclass: fifo_scb