`timescale 1ns / 1ps

typedef enum {WRITE, READ} FIFO_OP;
//Class transaction
class txn;
    rand FIFO_OP op;
    rand logic wr, rd;
    rand logic [7:0] din;
    logic full, empty;
    logic [7:0] dout;
    
    //Constraints
    //constraint op_dist {
    //op dist { WRITE := 8, READ := 2 };
    //}
    
    constraint wr_rd {
        (op == WRITE) -> wr == 1 && rd == 0;
        (op == READ)  -> rd == 1 && wr == 0;
    }

    function txn copy();
        copy = new();
        copy.op = this.op;
        copy.wr = this.wr;
        copy.rd = this.rd;
        copy.full = this.full;
        copy.empty = this.empty;
        copy.din = this.din;
        copy.dout = this.dout;
    endfunction 

    function void display (string tag="TXN");
        if (op == WRITE)
            $display("[%0t %0s] FIFO WRITE: wr= %0b, din=%0d, full=%0b", $time, tag, wr, din, full);
        else if (op == READ)
            $display("[%0t %0s] FIFO READ: rd= %0b, dout=%0d, empty=%0b", $time, tag, rd, dout, empty);
    endfunction
endclass

//Class generator
class gen;
    txn tx;
    mailbox #(txn) gen2drv;
    mailbox #(txn) gen2scb;
    int count = 0;
    event done;
    
    function new(mailbox #(txn) gen2drv, mailbox #(txn) gen2scb);
        this.gen2drv = gen2drv;
        this.gen2scb = gen2scb;
    endfunction
    
    function void set_gen(int count);
        this.count = count;
    endfunction
    
    task wr_fifo();
        tx = new();
        assert(tx.randomize() with {tx.op == WRITE;})
            else $display("Write generation failed!");
        gen2drv.put(tx.copy());
        gen2scb.put(tx.copy());
        tx.display("GEN");
    endtask
    
    task rd_fifo();
        tx = new();
        assert(tx.randomize() with {tx.op == READ;})
            else $display("Write generation failed!");
        gen2drv.put(tx.copy());
        gen2scb.put(tx.copy());
        tx.display("GEN");
    endtask
    
    task run();
        repeat (count) begin
            wr_fifo();
        end 
        repeat (count) begin
            rd_fifo();
        end 
    endtask
endclass

//Class driver
class drv;
    txn tx;
    mailbox #(txn) gen2drv;
    virtual fifo_if vif;
    
    function new(mailbox #(txn) gen2drv);
        this.gen2drv = gen2drv;
    endfunction
    
    task init();
        @(posedge vif.clk);
        vif.rst <= 1'b1;
        vif.wr  <= 1'b0;
        vif.rd  <= 1'b0;
        vif.din <= 0;
        repeat (5) @(posedge vif.clk);
        vif.rst <= 1'b0;
        $display("Reset asserted for 5 cycles, initialize inputs...");
        @(posedge vif.clk);
    endtask
    
    task run();
        forever begin
            gen2drv.get(tx);
            @(posedge vif.clk);
            if (tx.op == WRITE) begin
                vif.wr <= tx.wr;
                vif.rd <= tx.rd;
                vif.din <= tx.din;
                tx.display("DRV");
            end else if (tx.op == READ) begin
                vif.wr <= tx.wr;
                vif.rd <= tx.rd;
                tx.display("DRV");
            end
        end
    endtask
endclass

//Class monitor
class mon;
    txn tx;
    mailbox #(txn) mon2scb;
    virtual fifo_if vif;
    
    function new(mailbox #(txn) mon2scb);
        this.mon2scb = mon2scb;
    endfunction
    
    task run();
        logic prev_rd = 1'b0;
        logic prev_empty = 1'b0;
        forever begin
            wait(!vif.rst);
            @(posedge vif.clk);
            if (vif.wr && !vif.full) begin
                tx = new();
                tx.op   = WRITE;
                tx.wr   = vif.wr;
                tx.din  = vif.din;
                tx.full = vif.full;
                mon2scb.put(tx.copy);
                tx.display("MON");
            end else if (prev_rd && !prev_empty) begin
                tx = new();
                tx.op    = READ;
                tx.rd    = vif.rd;
                tx.dout  = vif.dout;
                tx.empty = vif.empty;
                mon2scb.put(tx);
                tx.display("MON");
            end
            prev_rd = vif.rd; 
            prev_empty = vif.empty;         
        end
    endtask
endclass

//Class scoreboard
class scb;
    txn tx_ref, tx_act;
    logic [7:0] ref_q [$];
    logic [7:0] act_q [$];
    mailbox #(txn) gen2scb;
    mailbox #(txn) mon2scb;
    
    function new(mailbox #(txn) gen2scb, mailbox #(txn) mon2scb);
        this.gen2scb = gen2scb;
        this.mon2scb = mon2scb;
    endfunction
    
    function compare();
        int count_err = 0;
        foreach(ref_q[i]) begin
            if (act_q[i] != ref_q[i])
                count_err++;
        end
        if (count_err > 0)
            $display("FAIL: Data mismatched!");
        else
            $display("PASS: All data matched!");
        $display("Written data: %0p", ref_q);
        $display("Read data: %0p", act_q);
    endfunction
    
    task run();
        forever begin
            gen2scb.get(tx_ref);
            mon2scb.get(tx_act);
            if (tx_ref.op == WRITE) begin
                ref_q.push_front(tx_ref.din);
                tx_ref.display("SCB");
            end
            if (tx_act.op == READ) begin
                act_q.push_front(tx_act.dout);
                tx_act.display("SCB");
            end
            $display("act_q size = %0d",  $size(act_q));
            if ($size(act_q) == 5) compare();
        end  
    endtask
    
endclass

module fifo_tb();
    fifo_if vif();
    fifo i_fifo(vif);
    
    mailbox #(txn) gen2drv;
    mailbox #(txn) gen2scb;
    mailbox #(txn) mon2scb;
    gen i_gen;
    drv i_drv;
    mon i_mon;
    scb i_scb;
    
    //Generate clock
    initial vif.clk <= 1'b0;
    always #5 vif.clk <= ~vif.clk;
    
    //Start test
    initial begin
        gen2drv = new();
        gen2scb = new();
        mon2scb = new();
        i_gen = new(gen2drv, gen2scb);
        i_drv = new(gen2drv);
        i_mon = new(mon2scb);
        i_scb = new(gen2scb, mon2scb);
        
        i_drv.vif = vif;
        i_mon.vif = vif;
        
        // Start driver reset & run task first
        i_drv.init();
        i_gen.set_gen(5);
        fork
            i_gen.run();
            i_drv.run();
            i_mon.run();
            i_scb.run();
        join
    end
    
endmodule