`timescale 1ns/1ps

module tb_1;
    bit arr_1 [8] = '{8{1'b0}};
    bit arr_2 [] = '{0, 1, 1, 0};
    int arr_3 [8] = '{default:8};

    //For checking how to declare and print values of an array
    bit temp = 1'b0;
    int k = 0;
    initial begin
        #20;
        $display("=======================");
        $display("Size of arr_1 = %0d", $size(arr_1));
        $display("Size of arr_2 = %0d", $size(arr_2));
        $display("=======================");
        foreach(arr_2[j])
            $display("arr_2[%0d] = %0d", j, arr_2[j]);
        
        #20;
        $display("=======================");
        for(int i=0; i<$size(arr_1); i++) begin
            arr_1[i] = temp;
            $display("arr_1[%0d] = %0d", i, arr_1[i]);
            temp = ~temp;
        end

        #20;
       $display("======================="); 
       for(int i=0; i<$size(arr_3); i++)
            $display("arr_3[%0d] = %0d", i, arr_3[i]);

        #20;
       $display("=======================");
       repeat(10) begin
            arr_3[k] = k;
            k++;
       end
       $display("arr_3 = %0p", arr_3);

        #100; 
        $finish; 
    end

    //Dynamic Arrays
    bit [7:0] dyn_arr1[];
    bit [7:0] temp_dyn = 8'h00;
    initial begin
        dyn_arr1 = new[4];
        foreach (dyn_arr1[j]) begin
            dyn_arr1[j] = temp_dyn;
            temp_dyn = temp_dyn + 2;
        end
        $display("=======================");
        $display("dyn_arr1 = %0p", dyn_arr1);

        // Create new 20 dynamic array, copying previous values from 1st index
        dyn_arr1 = new[20](dyn_arr1);
        $display("=======================");
        $display("dyn_arr1 = %0p", dyn_arr1); 
    end

    //Array reduction methods
    int arr_1_sum = 0;
    initial begin
        arr_1 = '{0, 1, 1, 1, 0, 0, 1, 1};
        // arr_1_sum = arr_1.sum // Not supported currently in verilator
        $display("=======================");
        $display("The sum of all elements in arr_1 is %0d", arr_1_sum);
    end
endmodule