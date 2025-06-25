//2x1 Multiplexer
module mux(
    input logic D1, D0,
    input logic S,
    output logic Y
);
    //Function
    always_comb begin
        Y = (~S & D0) | (S & D1);
    end
endmodule