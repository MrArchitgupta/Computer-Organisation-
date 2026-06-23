`timescale 1ns / 1ps

module graph (
    input wire clk,
    input wire [4:0] edge_source,
    input wire [4:0] edge_dest,
    input wire adjacency_val,
    input wire [4:0] path_length,
    input wire input_done,
    input wire [4:0] start_vertex,
    input wire [4:0] end_vertex,
    input wire start_arm,
    input wire stop_arm,
    output wire is_there_path,
    output reg done,
    output reg [31:0] arm_cycles
);

    reg [31:0] A [0:31];
    reg [31:0] B [0:31];
    reg [31:0] C [0:31];
    reg [31:0] A_transposed [0:31];
    
    reg [3:0] state = 0;
    reg [4:0] current_k = 1;

    initial begin
        done = 0;
        arm_cycles = 0;
    end

    assign is_there_path = B[start_vertex][end_vertex];

    // FSM Transitions
    always @(posedge clk) begin
        if (state == 0) begin
            if (input_done) state <= 1;
        end
        else if (state == 1) begin
            if (path_length <= 1) state <= 7; 
            else state <= 2;
        end
        else if (state >= 2 && state <= 4) begin
            state <= state + 1;
        end
        else if (state == 5) begin
            state <= 6;
        end
        else if (state == 6) begin
            if (current_k == path_length - 1) begin
                state <= 7; 
            end else begin
                current_k <= current_k + 1;
                state <= 2; 
            end
        end
        else if (state == 7) begin 
            done <= 1;
            if (start_arm) state <= 8;
        end
        else if (state == 8) begin 
            if (!stop_arm) arm_cycles <= arm_cycles + 1;
        end
    end

    // State 0: Accept Adjacency Matrix
    always @(posedge clk) begin
        if (state == 0 && !input_done) begin
            if (adjacency_val) begin
                A[edge_source][edge_dest] <= 1'b1;
                A_transposed[edge_dest][edge_source] <= 1'b1;
            end else begin
                A[edge_source][edge_dest] <= 1'b0;
                A_transposed[edge_dest][edge_source] <= 1'b0;
            end
        end
    end

    genvar r, c;
    generate
        for (r = 0; r < 32; r = r + 1) begin: process_rows
            // Safe single driver for B
            always @(posedge clk) begin
                if (state == 1) B[r] <= A[r];
                else if (state == 6) B[r] <= C[r];
            end

            // Safe single driver for C
            for (c = 0; c < 32; c = c + 1) begin: process_cols
                always @(posedge clk) begin
                    if (state == 2 && r < 8)
                        C[r][c] <= |(B[r] & A_transposed[c]);
                    else if (state == 3 && r >= 8 && r < 16)
                        C[r][c] <= |(B[r] & A_transposed[c]);
                    else if (state == 4 && r >= 16 && r < 24)
                        C[r][c] <= |(B[r] & A_transposed[c]);
                    else if (state == 5 && r >= 24 && r < 32)
                        C[r][c] <= |(B[r] & A_transposed[c]);
                end
            end
        end
    endgenerate

endmodule