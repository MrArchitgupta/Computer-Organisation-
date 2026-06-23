// Code your testbench here
// or browse Examples
`timescale 1ns / 1ps

module tb;

    // Inputs to Computer
    reg reset;
    reg [7:0] ins_addr;
    reg [31:0] ins;
    reg clk;
    reg done_storing;
    reg copied_io_regs;

    // Outputs from Computer
    wire done;
    wire flush_io_regs;
    wire [31:0] out_io_regs_index;
    wire [31:0] out_reg1, out_reg2, out_reg3, out_reg4;
    wire [31:0] total_cycles, proc_cycles;

    // Instantiate the Unit Under Test (UUT)
    Code uut (
        .reset(reset), 
        .ins_addr(ins_addr), 
        .ins(ins), 
        .clk(clk), 
        .done_storing(done_storing), 
        .copied_io_regs(copied_io_regs),
        .done(done), 
        .flush_io_regs(flush_io_regs), 
        .out_io_regs_index(out_io_regs_index),
        .out_reg1(out_reg1), 
        .out_reg2(out_reg2), 
        .out_reg3(out_reg3), 
        .out_reg4(out_reg4), 
        .total_cycles(total_cycles), 
        .proc_cycles(proc_cycles)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    // Program Memory Array (Currently holding Assignment 1 code)
    reg [31:0] mips_instructions [0:17];
    integer i;

  
    initial begin
      $dumpfile("dump.vcd");
        $dumpvars(0, tb);
        // Initialize Assignment 1 Instructions
        mips_instructions[0] = 32'h2001FFF6; mips_instructions[1] = 32'h20210001;
        mips_instructions[2] = 32'h201E03EC; mips_instructions[3] = 32'h03C1000C;
        mips_instructions[4] = 32'h00010A80; mips_instructions[5] = 32'h03C1000C;
        mips_instructions[6] = 32'h000108C3; mips_instructions[7] = 32'h03C1000C;
        mips_instructions[8] = 32'h2021FFFF; mips_instructions[9] = 32'h03C1000C;
        mips_instructions[10] = 32'h2022FFFF; mips_instructions[11] = 32'h00220824;
        mips_instructions[12] = 32'h03C1000C; mips_instructions[13] = 32'h20220001;
        mips_instructions[14] = 32'h00220825; mips_instructions[15] = 32'h03C1000C;
        mips_instructions[16] = 32'h201E03E9; mips_instructions[17] = 32'h03C0000C;

        // Initialize Inputs
        clk = 0;
        reset = 1;
        ins_addr = 0;
        ins = 0;
        done_storing = 0;
        copied_io_regs = 0;

        // 1. Reset the system
        #20;
        reset = 0;
        #10;

        // 2. Load instructions into Computer memory
        for (i = 0; i < 18; i = i + 1) begin
            ins_addr = i;
            ins = mips_instructions[i];
            #10; // Wait one clock cycle per write
        end

        // 3. Start execution
        done_storing = 1;

        // 4. Fall into a polling loop just like the C program
        // We will wait until the processor asserts 'done'
        wait(done == 1'b1);
        
        $display("========================================");
        $display("Execution Finished!");
        $display("Total Cycles: %d", total_cycles);
        $display("Proc Cycles: %d", proc_cycles);
        $display("Final Residual IO Regs Index: %d", out_io_regs_index);
        $display("========================================");
        $finish;
    end

    // 5. Asynchronous Handshake Monitor (Simulates the C code reading full registers)
// 5. Synchronous Handshake Monitor (Simulates the C code reading full registers)
    always @(posedge clk) begin
        if (flush_io_regs && !copied_io_regs) begin
            $display("--- STALL DETECTED: Flushing IO Registers ---");
            $display("out1: %d, out2: %d, out3: %d, out4: %d", 
                     $signed(out_reg1), $signed(out_reg2), $signed(out_reg3), $signed(out_reg4));
            
            // Assert copied signal on the next clock edge
            copied_io_regs <= 1'b1;
            
        end else if (copied_io_regs && !flush_io_regs) begin
            // De-assert the signal once the processor lowers the stall flag
            copied_io_regs <= 1'b0;
        end
    end

endmodule