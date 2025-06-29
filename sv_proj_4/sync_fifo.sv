module sync_fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16,
    parameter ADDR_WIDTH = $clog2(DEPTH)
)(
    input  logic                  clk,
    input  logic                  rst_n,

    input  logic                  wr_en,
    input  logic                  rd_en,
    input  logic [DATA_WIDTH-1:0] din,

    output logic [DATA_WIDTH-1:0] dout,
    output logic                  full,
    output logic                  empty
);

    // Internal memory
    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    // Write and Read pointers
    logic [ADDR_WIDTH-1:0] wr_ptr, rd_ptr;

    // Counter to track number of elements
    logic [ADDR_WIDTH:0]   fifo_count;

    // Write operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr <= 0;
        end else if (wr_en && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr <= wr_ptr + 1;
        end
    end

    // Read operation
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rd_ptr <= 0;
        end else if (rd_en && !empty) begin
            rd_ptr <= rd_ptr + 1;
        end
    end

    // Output data
    assign dout = mem[rd_ptr];

    // FIFO count logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            fifo_count <= 0;
        end else begin
            case ({wr_en && !full, rd_en && !empty})
                2'b10: fifo_count <= fifo_count + 1; // write only
                2'b01: fifo_count <= fifo_count - 1; // read only
                default: fifo_count <= fifo_count;   // no change or simultaneous read/write
            endcase
        end
    end

    // Status flags
    assign full  = (fifo_count == DEPTH);
    assign empty = (fifo_count == 0);

endmodule
