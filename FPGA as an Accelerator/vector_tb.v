`timescale 1ns / 1ps

module vector_tb;
    reg clk;
    reg [8:0] index;
    reg [31:0] value;
    reg vector_id;
    reg input_done;
    reg start_arm;
    reg stop_arm;
    
    wire [31:0] reduction_result;
    wire done;
    wire [31:0] arm_cycles;

    vector uut (
        .clk(clk),
        .index(index),
        .value(value),
        .vector_id(vector_id),
        .input_done(input_done),
        .start_arm(start_arm),
        .stop_arm(stop_arm),
        .reduction_result(reduction_result),
        .done(done),
        .arm_cycles(arm_cycles)
    );

    always #5 clk = ~clk; 

    integer i;

    initial begin
        clk = 0; index = 0; value = 0; vector_id = 0; 
        input_done = 0; start_arm = 0; stop_arm = 0;

        #20;
        
        // Load v0 with 1s
        vector_id = 0;
        for (i = 0; i < 512; i = i + 1) begin
            index = i; 
            value = 1; 
            @(posedge clk); 
            #1; // <-- MAGIC DELAY: Wait 1ns after clock edge to prevent race condition
        end
        
        // Load v1 with 2s
        vector_id = 1;
        for (i = 0; i < 512; i = i + 1) begin
            index = i; 
            value = 2; 
            @(posedge clk); 
            #1; // <-- MAGIC DELAY
        end

        // Trigger FPGA computation
        @(posedge clk);
        #1;
        input_done = 1;
        
        // Wait for reduction result
        wait (done == 1);
        $display("FPGA finished. Result: %d", reduction_result); // Will now be 1536!
        
        // Emulate ARM Processing
        @(posedge clk);
        #1;
        start_arm = 1;
        
        #1500; // Simulated delay for ARM loop
        
        @(posedge clk);
        #1;
        stop_arm = 1;
        
        #20;
        $display("ARM cycles counted by FPGA: %d", arm_cycles);
        $finish;
    end
endmodule