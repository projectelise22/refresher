module top_tb;
    logic S, D0, D1, Y;
    mux dut (.S(S), .D0(D0), .D1(D1), .Y(Y));
    initial begin
        //Set all inputs to 0
        D0 = 0; D1 = 0; S = 0;

        //Set D0 and D1
        D0 = 1; D1 = 0; #10;
        D0 = 0; D1 = 1; #10;
        D0 = 1; D1 = 0; #10;
        D0 = 1; D1 = 1; #10;

        //Set S to 1
        S = 1; #10;
        D0 = 1; D1 = 0; #10;
        D0 = 0; D1 = 0; #10;
        D0 = 0; D1 = 1; #10;
        $finish;
    end
endmodule
