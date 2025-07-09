`timescale 1ns / 1ps

//class transaction
class txn;
    rand logic newd;
    rand logic [11:0] din;
    logic cs, mosi;
    
    function txn copy();
        copy = new();
        copy.newd = this.newd;
        copy.din  = this.din;
        copy.cs   = this.cs;
        copy.mosi = this.mosi;
    endfunction
    
    function void display(input string tag="TXN");
        $display("[%0t %0s] DATA_NEW: %0b | DIN: %0d | CS: %0b | MOSI: %0b",
                 $time, tag, newd, din, cs, mosi);
    endfunction
endclass

//Class generator
class gen;
    txn tx;
    mailbox #(txn) mbx;
    event done; 
    int count = 0;
    event drv_next, scb_next;
    
    function new(mailbox #(txn) mbx);
        this.mbx = mbx;
        tx = new();
    endfunction;
    
    task run();
        repeat (count) begin
            assert(tx.randomize()) else $error("Generation failed!");
            mbx.put(tx.copy);
            tx.display("GEN");
            @(drv_next);
            @(scb_next);
        end
        -> done;
    endtask
endclass

//Class driver
class drv;
    txn tx;
    mailbox #(txn) mbx;
    mailbox #(bit [11:0]) mbx_ds;
    event drv_next;
    virtual spi_if vif;
    
    function new(mailbox #(bit [11:0]) mbx_ds, mailbox #(txn) mbx);
        this.mbx = mbx;
        this.mbx_ds = mbx_ds;
    endfunction 
    
    task reset();
        vif.rst  <= 1'b1;
        vif.cs   <= 1'b1;
        vif.newd <= 1'b0;
        vif.din  <= 12'h000;
        vif.mosi <= 1'b0;
        repeat (10) @(posedge vif.clk);
        vif.rst <= 1'b0;
        repeat (5) @(posedge vif.clk);
        $display("[%0t DRV] Reset asserted, initialized inputs", $time);
    endtask
    
    task run();
        forever begin
            mbx.get(tx);
            @(posedge vif.sclk);
            tx.newd = 1'b1;
            vif.newd <= tx.newd;
            vif.din  <= tx.din;
            mbx_ds.put(tx.din);
            @(posedge vif.sclk);
            vif.newd <= 1'b0;
            wait(vif.cs == 1'b1);
            tx.display("DRV");
            -> drv_next;
        end
    endtask
endclass

//Class monitor
class mon;
    txn tx;
    mailbox #(bit [11:0]) mbx_dr;
    bit [11:0] srx;
    virtual spi_if vif;
    
    function new(mailbox #(bit [11:0]) mbx_dr);
        this.mbx_dr =  mbx_dr;
    endfunction
    
    task run();
        forever begin
            @(posedge vif.sclk);
            wait(vif.cs == 1'b0); //Start of transaction
            @(posedge vif.sclk);
            
            for (int i=0; i<=11; i++) begin
                @(posedge vif.sclk);
                srx[i] = vif.mosi;
            end
            
            wait(vif.cs == 1'b0); //End of transaction
            
            $display("[%0t MON] DATA SENT = %0d", $time, srx);
            mbx_dr.put(srx);
        end 
    endtask
endclass

//class scoreboard
class scb;
    mailbox #(bit [11:0]) mbx_ds;
    mailbox #(bit [11:0]) mbx_dr;
    bit [11:0] ds, dr;
    event scb_next;
    
    function new(mailbox #(bit [11:0]) mbx_ds, mailbox #(bit [11:0]) mbx_dr);
        this.mbx_ds = mbx_ds;
        this.mbx_dr = mbx_dr;
    endfunction
    
    task run();
        forever begin
            mbx_ds.get(ds);
            mbx_dr.get(dr);
            if (dr == ds)
                $display("[%0t SCB] Received serial data: %0d MATCHED sent DIN: %0d", $time, dr, ds);
            else
                $error("[%0t SCB] Received serial data: %0d DID NOT MATCHED sent DIN: %0d", $time, dr, ds);
        -> scb_next;
        end
    endtask
endclass

//Class Environment
class env;
    //Class handles
    gen i_gen;
    drv i_drv;
    mon i_mon;
    scb i_scb;
    
    //Events
    event drv_next, scb_next;
    
    //Mailboxes
    mailbox #(txn) gen2drv;
    mailbox #(bit [11:0]) drv2scb;
    mailbox #(bit [11:0]) mon2scb;
    
    //Interfaces
    virtual spi_if vif;
    
    //Connect classes
    function new(virtual spi_if vif);
        gen2drv = new();
        drv2scb = new();
        mon2scb = new();
        
        i_gen = new(gen2drv);
        i_drv = new(drv2scb, gen2drv);
        i_mon = new(mon2scb);
        i_scb = new(drv2scb, mon2scb);
        
        this.vif  = vif;
        i_drv.vif = this.vif;
        i_mon.vif = this.vif;
        
        i_gen.drv_next = drv_next;
        i_drv.drv_next = drv_next;
        
        i_gen.scb_next = scb_next;
        i_scb.scb_next = scb_next;
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
        join
    endtask
    
    task post_test();
        wait(i_gen.done.triggered);
        $display("All data sent");
        $finish();
    endtask
    
    task run();
        pre_test();
        test();
        post_test();
    endtask
endclass

module spi_tb();
    //Interface
    spi_if vif();
    //DUT Instance
    spi_m i_spi_m(.clk(vif.clk),
                  .rst(vif.rst),
                  .newd(vif.newd),
                  .din(vif.din),
                  .sclk(vif.sclk),
                  .cs(vif.cs),
                  .mosi(vif.mosi));
                  
    //Generate clock
    initial vif.clk <= 1'b0;
    always #10 vif.clk <= ~vif.clk;
    
    //Run test
    env i_env;
    initial begin
        i_env = new(vif);
        i_env.i_gen.count = 10;
        i_env.run();
    end
endmodule
