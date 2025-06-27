`timescale 1ns/1ps
/* verilator lint_off WIDTHTRUNC */
module tb_2;

// Exercise 1: Create a struct called 'reg_t' with the following fields:
// - address: 8-bit logic
// - data: 32-bit logic
// Task: Declare a variable of type reg_t and assign values to it.
struct {
    logic [7:0] address;
    logic [31:0] data;
} reg_t1; 

initial begin
    #10;
    $display("========================================================");
    reg_t1.address = 8'h22;
    reg_t1.data = 32'hBABA_FAFA;
    $display("Struct reg_t1: address = 0x%0h, data = 0x%0h", reg_t1.address, reg_t1.data);
end

initial begin
    #200;
    $finish;
end

// Exercise 2: Create an array of 4 reg_t variables
// Task: Assign unique address/data values to each and print them using a loop
typedef struct {
    logic [7:0] address;
    logic [31:0] data;
} reg_t;

reg_t arr_reg_t [4];
logic [7:0] temp_address = 8'h00;
logic [31:0] temp_data = 32'h0000_0001;

initial begin
    #20;
    $display("========================================================");
    foreach (arr_reg_t[j]) begin
        arr_reg_t[j].address = temp_address;
        arr_reg_t[j].data = temp_data;
        temp_address++;
        temp_data = temp_data * 2;
    end

    $display("arr_reg_t: %0p", arr_reg_t);
end

// 🧩 Exercise 3: Array of Structs
// Goal: Work with multiple structured records.
// 📝 Task:
// Create an array reg_file of 4 reg_t elements.
// Set each register's address to i*4 and data to i.
reg_t reg_file [4];

initial begin
    #30;
    $display("========================================================");
    for(int i=0; i<$size(reg_file); i++) begin
        reg_file[i].address = i*4;
        reg_file[i].data = i;
    end

    $display("reg_file: %0p", reg_file);
end

// 🧩 Exercise 4: Struct with Enum
// Goal: Use enum inside a struct.
// 📝 Task:
// Create a typedef enum named access_t with values READ, WRITE, RW.
// Add access_t permission; to reg_t.
// Assign permission = RW to one of the registers.
typedef enum {READ, WRITE, RW} access_t;
struct {
    logic [7:0] address;
    logic [31:0] data;
    access_t permission;
} reg_t2;

initial begin
    #40;
    $display("========================================================");
    reg_t2.address = $random();
    reg_t2.data = $random();
    reg_t2.permission = RW;

    $display("rg_t2: address=0x%0h, data=0x%0h, permission=%0s ", reg_t2.address, reg_t2.data, reg_t2.permission.name);
end

// 🧩 Exercise 5: Queue of Structs
// Goal: Use dynamic structures with typedef.
// 📝 Task:
// Declare a queue of reg_t called reg_queue.
// Push three different registers into it.
// Use a loop to display their contents.
reg_t q_reg [$];
reg_t register_1;
reg_t register_2;
reg_t register_3;

initial begin
    #50;
    $display("========================================================");
    register_1.address = $random();
    register_2.address = $random();
    register_3.address = $random();
    register_1.data = $random();
    register_2.data = $random();
    register_3.data = $random();
    q_reg.push_front(register_1);
    q_reg.push_front(register_2);
    q_reg.insert(1, register_3);

    $display("q_reg: %0p", q_reg);
end

// 🧩 Exercise 6: Create Access Functions
// Goal: Build reusable logic using structs.
// 📝 Task:
// Write a task write_register(input logic [7:0] addr, input logic [31:0] data) that updates the matching address in reg_file.
// Write another task read_register(input logic [7:0] addr) that prints out the data.
task write_register(input logic [7:0] address, input logic [31:0] data);
    foreach (reg_file[j]) begin
        if (address == reg_file[j].address) reg_file[j].data = data; 
    end
endtask

task read_register(input logic [7:0] address);
    foreach (reg_file[j]) begin
        if (address == reg_file[j].address)
            $display("Register[%0d]: address = 0x%0h, data = 0x%0h", j, reg_file[j].address, reg_file[j].data);
    end
endtask

task read_all_registers();
    $display("Reading all registers...");
    foreach (reg_file[j])
        $display("Register[%0d]: address = 0x%0h, data = 0x%0h", j, reg_file[j].address, reg_file[j].data);
endtask

initial begin
    #60;
    $display("========================================================");
    $display("Before doing any tasks...");
    read_all_registers();
    $display("Write and Read Register[1]");
    write_register(8'h4, 32'hFFFF_0000);
    read_register(8'h4);
end

// 🧩 Exercise 7: Nested Struct
// Goal: Build hierarchical data models.
// 📝 Task:
// Create a typedef struct called packet_t that contains:
// A 4-bit id
// A reg_t payload
// Initialize a variable pkt1 with some sample values.
typedef struct {
    bit [3:0] id;
    reg_t payload;
} packet_t;

packet_t pkt1;

initial begin
    #70;
    $display("========================================================");
    pkt1.id = $random();
    pkt1.payload.address = 8'h30;
    pkt1.payload.data = 32'hAAAA_0000;

    $display("packet 1: %0p", pkt1);
end

endmodule