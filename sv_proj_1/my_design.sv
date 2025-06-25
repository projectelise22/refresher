// my_design.sv
module my_design(
    input logic clk,
    input logic rst_n,
    input logic [3:0] a,
    output logic [3:0] y
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) y <= 4'd0;
        else y <= a + 1;
    end
endmodule