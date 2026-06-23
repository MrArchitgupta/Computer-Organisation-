`timescale 1ns / 1ps
`include "defs.vh"

module tb_Computer();

    // Inputs to Computer
    reg reset;
    reg [7:0] ins_addr;
    reg [31:0] ins;
    reg clk;
    reg done_storing;
    reg copied_io_regs;

    // Outputs from Computer
    wire done;
    wire [31:0] total_cycles;
    wire [31:0] proc_cycles;
    wire [31:0] out_reg1;
    wire [31:0] out_reg2;
    wire [31:0] out_reg3;
    wire [31:0] out_reg4;
    wire flush_io_regs;
    wire [2:0] io_reg_index;

    // Internal testbench variables
    integer i;
    reg [31:0] program [0:22]; // 23 instructions from our translated C program

    // Instantiate the Computer module
    Computer uut (
        .reset(reset),
        .ins_addr(ins_addr),
        .ins(ins),
        .clk(clk),
        .done_storing(done_storing),
        .done(done),
        .total_cycles(total_cycles),
        .proc_cycles(proc_cycles),
        .out_reg1(out_reg1),
        .out_reg2(out_reg2),
        .out_reg3(out_reg3),
        .out_reg4(out_reg4),
        .flush_io_regs(flush_io_regs),     // Connected to io_stall
        .copied_io_regs(copied_io_regs),   // Handshake input
        .io_reg_index(io_reg_index)
    );

    // 1. Clock Generation: Period of 10 (50% duty cycle) [cite: 643]
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // 2. Load the Program and Start Execution
    initial begin
        // Initialize the translated Assignment 1 MIPS program
        program[0]  = 32'h2001FFF6; // addi $1, $0, -10
        program[1]  = 32'h20210001; // addi $1, $1, 1
        program[2]  = 32'h200403EC; // addi $4, $0, 1004
        program[3]  = 32'h0081000C; // syscall $4, $1 (print)
        program[4]  = 32'h00010A80; // sll $1, $1, 10
        program[5]  = 32'h200403EC; // addi $4, $0, 1004
        program[6]  = 32'h0081000C; // syscall $4, $1 (print)
        program[7]  = 32'h000108C3; // sra $1, $1, 3
        program[8]  = 32'h200403EC; // addi $4, $0, 1004
        program[9]  = 32'h0081000C; // syscall $4, $1 (print)
        program[10] = 32'h2021FFFF; // addi $1, $1, -1
        program[11] = 32'h200403EC; // addi $4, $0, 1004
        program[12] = 32'h0081000C; // syscall $4, $1 (print)
        program[13] = 32'h2022FFFF; // addi $2, $1, -1
        program[14] = 32'h00220824; // and $1, $1, $2
        program[15] = 32'h200403EC; // addi $4, $0, 1004
        program[16] = 32'h0081000C; // syscall $4, $1 (print)
        program[17] = 32'h20220001; // addi $2, $1, 1
        program[18] = 32'h00220825; // or $1, $1, $2
        program[19] = 32'h200403EC; // addi $4, $0, 1004
        program[20] = 32'h0081000C; // syscall $4, $1 (print)
        program[21] = 32'h200403E9; // addi $4, $0, 1001
        program[22] = 32'h0080000C; // syscall $4, $0 (exit)

        // Initial state [cite: 644]
        reset = 1;
        done_storing = 0;
        copied_io_regs = 0;
        ins_addr = 0;
        ins = 0;

        // At time = 7, make reset = 0 and set first instruction [cite: 645]
        #7; 
        reset = 0;

        // Input all instructions sequentially, waiting 10 time units each [cite: 646-647]
        for (i = 0; i < 23; i = i + 1) begin
            ins_addr = i;
            ins = program[i];
            #10;
        end

        // After all instructions are input, wait 10 time units and set done_storing = 1 [cite: 648]
        #10;
        done_storing = 1;
    end

    // 3. Simulate the Vitis C Program Handshake (Environment)
    // This block constantly watches for the io_stall signal
    always @(posedge clk) begin
        if (flush_io_regs && !copied_io_regs) begin
            $display("[%0t] IO STALL DETECTED! Flushing registers...", $time);
            $display("Flushed Data -> Reg1: %d, Reg2: %d, Reg3: %d, Reg4: %d", 
                      $signed(out_reg1), $signed(out_reg2), $signed(out_reg3), $signed(out_reg4));
            
            // Assert the handshake signal to tell the processor we copied the data
            copied_io_regs <= 1'b1;
        end 
        else if (copied_io_regs) begin
            // De-assert it on the next clock cycle to complete the handshake
            copied_io_regs <= 1'b0;
        end
    end

    // 4. Handle Program Completion
    initial begin
        // Wait until the processor asserts the done signal
        wait(done == 1'b1);
        
        $display("[%0t] PROGRAM COMPLETE (SYS_EXIT).", $time);
        
        // Print residual registers based on io_reg_index
        if (io_reg_index > 0) $display("Residual Data -> Reg1: %d", $signed(out_reg1));
        if (io_reg_index > 1) $display("Residual Data -> Reg2: %d", $signed(out_reg2));
        if (io_reg_index > 2) $display("Residual Data -> Reg3: %d", $signed(out_reg3));
        
        $display("Total Cycles: %d, Proc Cycles: %d", total_cycles, proc_cycles);
        
        // End simulation
        #20 $finish;
    end

endmodule