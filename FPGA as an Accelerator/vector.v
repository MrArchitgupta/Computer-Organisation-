`timescale 1ns / 1ps

module vector (
    input wire clk,
    input wire [8:0] index,
    input wire [31:0] value,
    input wire vector_id,
    input wire input_done,
    input wire start_arm,
    input wire stop_arm,
    output reg [31:0] reduction_result,
    output reg done,
    output reg [31:0] arm_cycles
);

    reg [31:0] v0 [0:511];
    reg [31:0] v1 [0:511];
    reg [31:0] v2 [0:511];
    
    reg [3:0] state = 0;

    initial begin
        done = 0;
        arm_cycles = 0;
    end

    // FSM Transitions and Cycle Counting
    always @(posedge clk) begin
        if (state == 0) begin
            if (input_done) state <= 1;
        end 
        else if (state >= 1 && state <= 9) begin
            state <= state + 1;
        end 
        else if (state == 10) begin
            done <= 1; 
            if (start_arm) state <= 11;
        end 
        else if (state == 11) begin
            if (!stop_arm) arm_cycles <= arm_cycles + 1;
        end
    end

    // State 0: Input storing logic
    always @(posedge clk) begin
        if (state == 0 && !input_done) begin
            if (vector_id == 0) v0[index] <= value;
            else v1[index] <= value;
        end
    end

    // Massive Parallelization (Consolidated to fix MDRV-1 Error)
    genvar i;
    generate
        for (i = 0; i < 512; i = i + 1) begin: process_loop
            always @(posedge clk) begin
                if (state == 1) begin
                    v2[i] <= v0[i] + v1[i]; 
                end 
                else if (state == 2 && i < 256) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 3 && i < 128) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 4 && i < 64) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 5 && i < 32) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 6 && i < 16) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 7 && i < 8) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 8 && i < 4) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end 
                else if (state == 9 && i < 2) begin
                    v2[i] <= v2[2*i] + v2[2*i+1]; 
                end
            end
        end
    endgenerate

    // State 10: Final sum to output register
    always @(posedge clk) begin
        if (state == 10) reduction_result <= v2[0] + v2[1]; 
    end

endmodule
