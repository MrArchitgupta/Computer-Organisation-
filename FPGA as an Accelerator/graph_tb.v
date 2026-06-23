`timescale 1ns / 1ps

module graph_tb;
    reg clk;
    reg [4:0] edge_source, edge_dest;
    reg adjacency_val;
    reg [4:0] path_length;
    reg input_done, start_arm, stop_arm;
    reg [4:0] start_vertex, end_vertex;
    
    wire is_there_path;
    wire done;
    wire [31:0] arm_cycles;

    graph uut (
        .clk(clk), .edge_source(edge_source), .edge_dest(edge_dest),
        .adjacency_val(adjacency_val), .path_length(path_length),
        .input_done(input_done), .start_vertex(start_vertex),
        .end_vertex(end_vertex), .start_arm(start_arm),
        .stop_arm(stop_arm), .is_there_path(is_there_path),
        .done(done), .arm_cycles(arm_cycles)
    );

    always #5 clk = ~clk;

    integer i, j;

    initial begin
        clk = 0; input_done = 0; start_arm = 0; stop_arm = 0;
        edge_source = 0; edge_dest = 0; adjacency_val = 0;
        path_length = 31; start_vertex = 0; end_vertex = 31; // Testing path 0 -> 31

        #20;

        // Load Directed Ring Graph (0->1, 1->2, ... 31->0)
        for (i = 0; i < 32; i = i + 1) begin
            for (j = 0; j < 32; j = j + 1) begin
                edge_source = i;
                edge_dest = j;
                if (j == ((i + 1) % 32)) adjacency_val = 1;
                else adjacency_val = 0;
                @(posedge clk); #1;
            end
        end

        // Trigger Computation
        @(posedge clk); #1;
        input_done = 1;

        wait (done == 1);
        $display("FPGA finished computing graph paths.");
        
        // Check Result
        @(posedge clk); #1;
        if (is_there_path) $display("SUCCESS: Path of length 31 found between 0 and 31!");
        else $display("FAIL: Path not found.");

        // Emulate ARM Processing
        @(posedge clk); #1;
        start_arm = 1;
        #25000; // ARM will take much longer for this!
        @(posedge clk); #1;
        stop_arm = 1;
        
        #20;
        $display("Simulated ARM Cycles: %d", arm_cycles);
        $finish;
    end
endmodule