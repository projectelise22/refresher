`timescale 1ns/1ps
/* verilator lint_off WIDTHTRUNC */

module tb_3();

// 🧩 Exercise 1: Basic Task
// Goal: Understand task definition and calling.
// Task:
// Create a task called print_sum that takes two int inputs and prints their sum.
// Call it with the values 10 and 20.
    task print_sum(input int a, b);
        int s;
        s = a + b;
        $display("Sum: %0d", s);
    endtask : print_sum 

    initial begin
        #10;
        $display("================================");
        print_sum(10, 20);
    end

// 🧩 Exercise 2: Task with Output Parameter
// Goal: Learn to return values via task outputs.
// Task:
// Write a task multiply_by_two that takes an input int and an output int.
// It should return the input multiplied by 2.
    task multiply_by_two (input int base, output int prod);
        prod = base * 2;
        $display("Base: %0d, Product: %0d", base, prod);
    endtask: multiply_by_two

    int product = 0;
    initial begin
        #20;
        $display("================================");
        multiply_by_two(123, product);
        $display("product: %0d", product);
    end

// 🧩 Exercise 3: Function to Return Square
// Goal: Practice writing simple return-value functions.
// Task:
// Write a function square that takes an int input and returns the square of it.
// Call and display square(6).
    function int square(input int base);
        int sq_base;
        sq_base = base ** 2;
        return sq_base;
    endfunction: square

    int sq_in = 6;
    int sq_res = 0;
    initial begin
        #30;
        $display("================================");
        sq_res = square(sq_in);
        $display("Square of %0d: %0d", sq_in, sq_res);
    end

// 🧩 Exercise 4: Task with ref Parameter
// Goal: Modify values by reference.
// Task:
// Write a task increment_by_ref that takes one int by ref and adds 1 to it.
// Show the variable value before and after the task call.
    task increment_by_ref (ref int inc_r);
        $display("inc_r value before task call: %0d", inc_r);
        inc_r++;
        $display("inc_r value after task call: %0d", inc_r);
    endtask: increment_by_ref

    int var_inc = 0;
    initial begin
        #40;
        $display("================================");
        for (int i=0; i<5; i++) begin
            var_inc = i*2;
            increment_by_ref(var_inc);
        end        
    end

// 🧩 Exercise 5: Function with const ref
// Goal: Efficiently pass large data using constant references.
// Task:
// Write a function sum_array that takes an array of integers using const ref and returns the sum of the elements.
    function automatic int sum_array (const ref int q_arr[$]);
        int sum_q = 0;
        foreach (q_arr[j])
            sum_q = sum_q + q_arr[j];
        return sum_q;
    endfunction: sum_array

    int sum_q_arr = 0;
    int q_arr[$] = {1234, 123, 1234, 567, 67, 678, 90, 567, 456};
    initial begin
        #50;
        $display("================================");
        sum_q_arr = sum_array(q_arr);
        $display("Sum of queue: %0d", sum_q_arr);
    end

// 🧩 Exercise 6: Automatic Task Inside a Loop
// Goal: Avoid sharing state between task invocations.
// Task:
// Write a task show_loop_index(int i) and declare it automatic.
// Call it from a loop (for i = 0 to 3) and display i.
    task automatic show_loop_index(int i);
        i = i*10;
        $display("From task: %0d", i);
    endtask

    initial begin
        #60;
        $display("================================");
        for (int i=0; i<4; i++) begin
            show_loop_index(i);
            $display("int i from loop: %0d", i);
        end
    end

// 🧩 Exercise 7: Task to Read from Array of Structs
// Goal: Combine struct and task usage.
// Task:
// Now write a task read_reg that accepts:
// An array of reg_t
// An address
// It should search and display the data of the matching register.
    typedef struct {
        logic [7:0] address;
        logic [31:0] data;
    } reg_t;

    task automatic read_reg(ref reg_t reg_arr[8], input logic [7:0] address);
        bit found = 0;
        logic [31:0] data = 32'd0;
        $timeformat(-9, 3, " ns", 10);

        //Find address from register array
        foreach (reg_arr[j]) begin
            if (address == reg_arr[j].address) begin
                found = 1;
                data = reg_arr[j].data;
            end
        end

        //Display data if found
        if (!found)
            $display("[%0t] READ REGISTER: Register not found, invalid address!", $realtime);
        else
            $display("[%0t] READ REGISTER: Address = 0x%0h, Data = 0x%0h", $realtime, address, data);
        #10;
    endtask: read_reg

    reg_t reg_array[8];
    initial begin
        #70;
        $display("================================");
        for (int i=0; i<8; i++) begin
            reg_array[i].address = i;
            reg_array[i].data = i+4;
        end

        $display("reg_array: %0p", reg_array);

        read_reg(reg_array, 8'h0);
        read_reg(reg_array, 8'h1);
        read_reg(reg_array, 8'h2);
        read_reg(reg_array, 8'h3);
        read_reg(reg_array, 8'h10);
    end



    initial begin
        #500;
        $finish;
    end
endmodule