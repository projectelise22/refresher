`timescale 1ns / 1ps

module spi_m(
    input clk, rst, newd,
    input [11:0] din,
    output logic sclk, cs, mosi 
);
    
    // States
    typedef enum bit[1:0] {
        idle   = 2'b00,
        enable = 2'b01,
        send   = 2'b10,
        comp   = 2'b11
    } state_type;
    state_type state = idle;
    
    // Count for clock and behavior
    int countc = 0, count = 0;
    
    // sclk generation
    always @(posedge clk) begin
        if (rst == 1'b1) begin
            countc <= 0;
            sclk   <= 1'b0;
        end else begin
            if (countc < 5) 
                countc <= countc + 1;
            else begin
                countc <= 0;
                sclk <= ~sclk;
            end
        end
    end
    
    // fsm
    reg [11:0] temp;
    always @(posedge sclk) begin
        if (rst == 1'b1) begin
            cs   <= 1'b1;
            mosi <= 1'b0;
            state <= idle;
            count <= 0;
        end else begin
            case (state)
                idle: begin
                    if (newd == 1'b1) begin
                        state <= send;
                        temp  <= din;
                        cs    <= 1'b0;
                        count <= 0;
                    end
                end
                send: begin
                    if (count <= 11) begin
                        mosi  <= temp[count];
                        count <= count + 1;
                    end else begin
                        count <= 0;
                        state <= idle;
                        cs    <= 1'b1;
                        mosi  <= 1'b0;
                    end
                end
                default: state <= idle;
            endcase
        end
    end
    
endmodule

interface spi_if;
    logic clk, rst, newd;
    logic [11:0] din;
    logic sclk, cs, mosi;
endinterface
