// my_tb.sv
module my_tb;
    logic clk;
    logic rst_n;
    logic [3:0] a;
    logic [3:0] y;

    my_design i_my_design(
        .clk(clk), 
        .rst_n(rst_n), 
        .a(a), 
        .y(y)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        $dumpfile("wave.vcd");
        $dumpvars(0, my_tb);

        rst_n = 0; a = 0;
        repeat(2) @(posedge clk); rst_n = 1;

        a = 4'd5;  repeat(2) @(posedge clk);
        a = 4'd10; repeat(2) @(posedge clk);
        a = 4'd15; repeat(2) @(posedge clk);

        $finish;
    end
endmodule
