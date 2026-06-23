`timescale 1ns / 1ps

module matrix_tb;
    reg clk;
    reg [3:0] row_id, col_id;
    reg [31:0] input_val;
    reg vector_id;
    reg input_done, start_arm, stop_arm;
    reg [3:0] index;
    
    wire [31:0] y_out;
    wire done;
    wire [31:0] arm_cycles;

    matrix uut (
        .clk(clk), .row_id(row_id), .col_id(col_id), .input_val(input_val),
        .vector_id(vector_id), .input_done(input_done), .index(index),
        .start_arm(start_arm), .stop_arm(stop_arm),
        .y_out(y_out), .done(done), .arm_cycles(arm_cycles)
    );

    always #5 clk = ~clk;

    integer r, c;

initial begin
        clk = 0; input_done = 0; start_arm = 0; stop_arm = 0;
        vector_id = 0; row_id = 0; col_id = 0; input_val = 0; index = 0;

        #20;

        // Load Matrix M with (row - col)
        // This generates positive, negative, and zero values.
        vector_id = 0;
        for (r = 0; r < 16; r = r + 1) begin
            for (c = 0; c < 16; c = c + 1) begin
                row_id = r; 
                col_id = c; 
                input_val = r - c; // Will inherently create 32-bit 2's complement negatives
                @(posedge clk); #1;
            end
        end

        // Load Vector x with alternating 1 and -1
        vector_id = 1;
        for (r = 0; r < 16; r = r + 1) begin
            row_id = r; 
            if (r % 2 == 0) input_val = 1;
            else input_val = -1; // -1 in 32-bit 2's complement is 32'hFFFFFFFF
            @(posedge clk); #1;
        end

        // Start FPGA computation
        @(posedge clk); #1;
        input_done = 1;

        // Wait for computation
        wait (done == 1);
        
        // Read out y values
        $display("FPGA Matrix-Vector Results (Difficult Inputs):");
        for (r = 0; r < 16; r = r + 1) begin
            index = r;
            @(posedge clk); #1;
            // Using %0d treats the binary as a signed integer for the printout
            $display("y[%0d] = %0d (Expected: 8)", r, $signed(y_out));
        end

        // Emulate ARM
        @(posedge clk); #1;
        start_arm = 1;
        #1500; 
        @(posedge clk); #1;
        stop_arm = 1;
        
        #20;
        $display("Simulated ARM Cycles: %d", arm_cycles);
        $finish;
    end
endmodule