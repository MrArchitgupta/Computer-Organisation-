`timescale 1ns / 1ps

module matrix(
    input wire clk,
    input wire [3:0] row_id,
    input wire [3:0] col_id,
    input wire [31:0] input_val, 
    input wire vector_id,
    input wire input_done,
    input wire [3:0] index,
    input wire start_arm,
    input wire stop_arm,
    output wire [31:0] y_out,
    output reg done,
    output reg [31:0] arm_cycles
);

    reg [31:0] M [0:15][0:15];
    reg [31:0] x [0:15];
    reg [31:0] y [0:15];
    reg [31:0] v [0:15];
    reg [31:0] w [0:15];
    
    reg [3:0] state = 0;
    reg [3:0] current_row = 0;

    initial begin
        done = 0;
        arm_cycles = 0;
    end
    
    assign y_out = y[index];

    // FSM Transitions and Cycle Counting
    always @(posedge clk) begin
        if (state == 0) begin
            if (input_done) state <= 1;
        end
        else if (state >= 1 && state <= 6) begin
            state <= state + 1; 
        end
        else if (state == 7) begin
            if (current_row == 15) begin
                done <= 1; 
                if (start_arm) state <= 8; 
            end else begin
                current_row <= current_row + 1;
                state <= 1; 
            end
        end
        else if (state == 8) begin
            if (!stop_arm) arm_cycles <= arm_cycles + 1;
        end
    end

    // State 0: Accept Inputs
    always @(posedge clk) begin
        if (state == 0 && !input_done) begin
            if (vector_id == 0) M[row_id][col_id] <= input_val;
            else x[row_id] <= input_val; 
        end
    end

    // State 7: Save result
    always @(posedge clk) begin
        if (state == 7) y[current_row] <= w[0]; 
    end

    // Single Consolidated Generate Block
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin: process_loop
            always @(posedge clk) begin
                if (state == 1) begin
                    v[i] <= M[current_row][i];
                end
                else if (state == 2) begin
                    w[i] <= v[i] * x[i];
                end
                else if (state == 3 && i < 8) begin
                    w[i] <= w[2*i] + w[2*i+1];
                end
                else if (state == 4 && i < 4) begin
                    w[i] <= w[2*i] + w[2*i+1];
                end
                else if (state == 5 && i < 2) begin
                    w[i] <= w[2*i] + w[2*i+1];
                end
                else if (state == 6 && i < 1) begin
                    w[0] <= w[0] + w[1];
                end
            end
        end
    endgenerate

endmodule