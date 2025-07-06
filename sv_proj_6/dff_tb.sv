`timescale 1ns / 1ps

//Class Transaction
class txn;
    rand logic din;
    logic dout;
    
    function txn copy();
        copy = new();
        copy.din = this.din;
        copy.dout = this.dout;
    endfunction
    
    function void display(string tag="TXN");
        $timeformat(-9, 3, " ns", 10);
        $display("%0t: [%0s] DIN=%0b, DOUT=%0b", $realtime, tag, this.din, this.dout);
    endfunction;
endclass

//Class generator
class gen;
    txn tx;
    mailbox #(txn) gen2drv;
    mailbox #(txn) gen2scb;
    event scb_next;
    event done;
    int count; //stimulus count
    
    function new(mailbox #(txn) gen2drv, mailbox #(txn) gen2scb);
        this.gen2drv = gen2drv;
        this.gen2scb = gen2scb;
        tx = new();
    endfunction
    
    task run();
        repeat (count) begin
            tx.din = 1'bX;
            //assert(tx.randomize())
            //else $error("[GEN] Randomization failed");
            gen2drv.put(tx.copy());
            gen2scb.put(tx.copy());
            tx.display("GEN");
            @(scb_next);
        end
        -> done;
    endtask
endclass

//Class driver
class drv;
    txn tx;
    mailbox #(txn) gen2drv;
    virtual dff_if vif;
    
    function new(mailbox #(txn) gen2drv);
        this.gen2drv = gen2drv;
    endfunction
    
    task reset();
        vif.rst <= 1'b1;
        vif.din <= 1'b0;
        repeat (5) @(posedge vif.clk);
        vif.rst <= 1'b0;
        @(posedge vif.clk);
        $display("[DRV] Reset asserted for 5 cycles");
    endtask
    
    task run();
        forever begin
            gen2drv.get(tx);
            vif.din <= tx.din;
            @(posedge vif.clk);
            tx.display("DRV");
            vif.din <= 1'b0; //Clear din
            @(posedge vif.clk);
        end
    endtask
endclass

//Class monitor
class mon;
    txn tx;
    mailbox #(txn) mon2scb;
    virtual dff_if vif;
    
    function new(mailbox #(txn) mon2scb);
        this.mon2scb = mon2scb;
    endfunction
    
    task run();
        tx = new();
        forever begin
            repeat (2) @(posedge vif.clk);
            tx.dout = vif.dout;
            mon2scb.put(tx);
            tx.display("MON");
        end
    endtask
endclass

//Class scoreboard
class scb;
    txn tx_gen;
    txn tx_mon;
    mailbox #(txn) gen2scb;
    mailbox #(txn) mon2scb;
    event scb_next; 
    int count_tx = 0;
    int count_err = 0;
    
    function new(mailbox #(txn) gen2scb, mailbox #(txn) mon2scb);
        this.gen2scb = gen2scb;
        this.mon2scb = mon2scb;
    endfunction
    
    task run();
        forever begin
            gen2scb.get(tx_gen); //Reference
            mon2scb.get(tx_mon); //Actual
            tx_gen.display("REF");
            tx_mon.display("ACT");
            count_tx++;
            if (tx_gen.din == 1'bX && tx_mon.dout == 1'b0)
                $display("[SCB] Data expected! DIN is 1'bX");
            else if(tx_mon.dout == tx_gen.din)
                $display("[SCB] Data matched!");
            else begin
                $display("[SCB] Data mismatched!");
                count_err++;
            end
            $display("=============================");
            -> scb_next;
        end
    endtask
endclass

//CLass environment
class env;
    //Componwnta
    gen i_gen;
    drv i_drv;
    mon i_mon;
    scb i_scb;
    
    //Mailboxes
    mailbox #(txn) gen2drv;
    mailbox #(txn) gen2scb;
    mailbox #(txn) mon2scb;
    
    //Virtual IF
    virtual dff_if vif;
    event next;
    
    function new(virtual dff_if vif);
        //Create components
        gen2drv = new();
        gen2scb = new();
        mon2scb = new();
        
        i_gen = new(gen2drv, gen2scb);
        i_drv = new(gen2drv);
        i_mon = new(mon2scb);
        i_scb = new(gen2scb, mon2scb);
        
        //Connect virtual if
        this.vif = vif;
        i_drv.vif = vif;
        i_mon.vif = vif;
        
        //Connect events
        i_gen.scb_next = next;
        i_scb.scb_next = next;
    endfunction
    
    task pre_test();
        i_drv.reset();
    endtask
    
    task test();
        fork
            i_gen.run();
            i_drv.run();
            i_mon.run();
            i_scb.run();
        join_none
    endtask;
    
    task post_test();
        wait(i_gen.done.triggered);
        if (i_scb.count_err > 0 )
            $display("[TEST FAILED!] %0d mismatched data out of %0d", i_scb.count_err, i_gen.count);
        else
            $display("[TEST PASSED!] %0d matched data out of %0d", i_scb.count_tx, i_gen.count);
        $finish();
    endtask;
    
    task run();
        pre_test();
        test();
        post_test();
    endtask;
endclass

module dff_tb();
    dff_if vif();   // TB Interface
    dff i_dff(vif); // DUT Instance
    
    //Generate clock
    initial vif.clk <= 1'b0;
    always #10 vif.clk <= ~vif.clk;
    
    //Instantiate Environment
    env i_env;
    
    //Start test
    initial begin
        i_env = new(vif);
        i_env.i_gen.count = 10;
        i_env.run();
    end
    
endmodule
