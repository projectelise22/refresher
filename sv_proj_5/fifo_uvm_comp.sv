`include "uvm_macros.svh"
import uvm_pkg::*;

class fifo_txn extends uvm_sequence_item;

  // Define the fields of the transaction
  rand bit        wr_en;
  rand bit        rd_en;
  rand bit [7:0]  data;

  // Factory registration macro
  `uvm_object_utils(fifo_txn)

  // Constructor
  function new(string name = "fifo_txn");
    super.new(name);
  endfunction

  // Optional: Print function for debug
  function void do_print(uvm_printer printer);
    super.do_print(printer);
    printer.print_field_int("wr_en", wr_en, 1);
    printer.print_field_int("rd_en", rd_en, 1);
    printer.print_field_int("data", data, 8);
  endfunction

endclass

class fifo_sequencer extends uvm_sequencer #(fifo_txn);
  `uvm_component_utils(fifo_sequencer)

  // Add virtual interface handle here
  virtual fifo_if vif;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction
endclass

class fifo_sequence extends uvm_sequence #(fifo_txn);
  `uvm_object_utils(fifo_sequence)

  function new(string name = "fifo_sequence");
    super.new(name);
  endfunction

  task body();
    fifo_txn txn;

    repeat (10) begin
      txn = fifo_txn::type_id::create("txn");
      txn.wr_en = 1;
      txn.rd_en = 0;
      txn.data  = $urandom_range(0, 255);

      start_item(txn);
      finish_item(txn);

      // Wait some clocks between transactions
      #10;
      //repeat (5) @(posedge p_sequencer.vif.clk);
    end
  endtask
endclass

class fifo_driver extends uvm_driver #(fifo_txn);
  `uvm_component_utils(fifo_driver)

  virtual fifo_if vif; // Virtual interface handle

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    if (!uvm_config_db#(virtual fifo_if)::get(this, "", "vif", vif))
      `uvm_fatal("NOVIF", "Virtual interface must be set for fifo_driver")
  endfunction

  task run_phase(uvm_phase phase);
    fifo_txn txn;

    forever begin
      seq_item_port.get_next_item(txn); // Get transaction from sequencer

      // Drive interface signals based on transaction data
      vif.wr_en <= txn.wr_en;
      vif.rd_en <= txn.rd_en;
      vif.din   <= txn.data;

      @(posedge vif.clk);  // Wait for clock edge to apply signals

      seq_item_port.item_done();  // Notify sequence item done
    end
  endtask
endclass
  
  class fifo_env extends uvm_env;
  `uvm_component_utils(fifo_env)

  fifo_driver    driver;
  fifo_sequencer sequencer;
  // fifo_monitor monitor; // Add later if you want

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    driver    = fifo_driver::type_id::create("driver", this);
    sequencer = fifo_sequencer::type_id::create("sequencer", this);
    // monitor   = fifo_monitor::type_id::create("monitor", this);

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    driver.seq_item_port.connect(sequencer.seq_item_export);
  endfunction
endclass

class fifo_test extends uvm_test;
  `uvm_component_utils(fifo_test)

  fifo_env env;

  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    env = fifo_env::type_id::create("env", this);
  endfunction

  task run_phase(uvm_phase phase);
    fifo_txn txn;

    // Create and start a sequence here
    fifo_sequence seq;

    phase.raise_objection(this);

    seq = fifo_sequence::type_id::create("seq");
    seq.start(env.sequencer);

    // wait some time for sequence to finish
    #1000;

    phase.drop_objection(this);
  endtask
endclass
