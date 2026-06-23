// Code your design here
`timescale 1ns / 1ps

`define OP_REG 6'h0
`define OP_BLTZ_BGEZ 6'h1
`define OP_J 6'h2
`define OP_JAL 6'h3
`define OP_BEQ 6'h4
`define OP_BNE 6'h5
`define OP_BLEZ 6'h6
`define OP_BGTZ 6'h7
`define OP_ADDI 6'h8
`define OP_SLTI 6'ha
`define OP_SLTIU 6'hb
`define OP_ANDI 6'hc
`define OP_ORI 6'hd
`define OP_XORI 6'he

`define FUNC_SLL 6'h0
`define FUNC_SRL 6'h2
`define FUNC_SRA 6'h3
`define FUNC_SLLV 6'h4
`define FUNC_SRLV 6'h6
`define FUNC_SRAV 6'h7
`define FUNC_JR 6'h8
`define FUNC_JALR 6'h9
`define FUNC_SYSCALL 6'hc
`define FUNC_ADD 6'h20
`define FUNC_SUB 6'h22
`define FUNC_AND 6'h24
`define FUNC_OR 6'h25
`define FUNC_XOR 6'h26
`define FUNC_NOR 6'h27
`define FUNC_SLT 6'h2a
`define FUNC_SLTU 6'h2b

`define READ_COMMAND 1'b0
`define WRITE_COMMAND 1'b1

`define SYS_exit 32'd1001
`define SYS_write 32'd1004




module ALU (
    input [31:0] src1, input [31:0] src2, input [4:0] shift_amount, 
    input [5:0] opcode, input [5:0] func, input [7:0] pc, 
    input [31:0] branch_offset, input [4:0] rt,
    output reg [31:0] dest, output reg dest_valid,
    output reg [31:0] branch_target, output reg branch_taken
);

    always @(*) begin
        dest_valid = 1'b0;
        dest = 32'b0;
        branch_taken = 1'b0;
        branch_target = 32'b0;
        
        case (opcode)
            `OP_REG: begin
                case (func)
                    `FUNC_SLL:  begin dest = src2 << shift_amount; dest_valid = 1'b1; end
                    `FUNC_SRL:  begin dest = src2 >> shift_amount; dest_valid = 1'b1; end
                    `FUNC_SRA:  begin dest = $signed(src2) >>> shift_amount; dest_valid = 1'b1; end
                    `FUNC_SLLV: begin dest = src2 << src1[4:0]; dest_valid = 1'b1; end
                    `FUNC_SRLV: begin dest = src2 >> src1[4:0]; dest_valid = 1'b1; end
                    `FUNC_SRAV: begin dest = $signed(src2) >>> src1[4:0]; dest_valid = 1'b1; end
                    `FUNC_ADD:  begin dest = src1 + src2; dest_valid = 1'b1; end
                    `FUNC_SUB:  begin dest = src1 - src2; dest_valid = 1'b1; end
                    `FUNC_AND:  begin dest = src1 & src2; dest_valid = 1'b1; end
                    `FUNC_OR:   begin dest = src1 | src2; dest_valid = 1'b1; end
                    `FUNC_XOR:  begin dest = src1 ^ src2; dest_valid = 1'b1; end
                    `FUNC_NOR:  begin dest = ~(src1 | src2); dest_valid = 1'b1; end
                    `FUNC_SLT:  begin dest = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0; dest_valid = 1'b1; end
                    `FUNC_SLTU: begin dest = (src1 < src2) ? 32'd1 : 32'd0; dest_valid = 1'b1; end
                    `FUNC_JR:   begin branch_taken = 1'b1; branch_target = src1; end
                    `FUNC_JALR: begin branch_taken = 1'b1; branch_target = src1; dest = pc + 1; dest_valid = 1'b1; end
                endcase
            end
            `OP_ADDI: begin dest = src1 + src2; dest_valid = 1'b1; end
            `OP_ANDI: begin dest = src1 & src2; dest_valid = 1'b1; end
            `OP_ORI:  begin dest = src1 | src2; dest_valid = 1'b1; end
            `OP_XORI: begin dest = src1 ^ src2; dest_valid = 1'b1; end
            `OP_SLTI: begin dest = ($signed(src1) < $signed(src2)) ? 32'd1 : 32'd0; dest_valid = 1'b1; end
            `OP_SLTIU:begin dest = (src1 < src2) ? 32'd1 : 32'd0; dest_valid = 1'b1; end
            `OP_J:    begin branch_taken = 1'b1; branch_target = branch_offset; end
            `OP_JAL:  begin branch_taken = 1'b1; branch_target = branch_offset; dest = pc + 1; dest_valid = 1'b1; end
            `OP_BEQ:  begin branch_taken = (src1 == src2); branch_target = pc + branch_offset; end
            `OP_BNE:  begin branch_taken = (src1 != src2); branch_target = pc + branch_offset; end
            `OP_BLEZ: begin branch_taken = ($signed(src1) <= 0); branch_target = pc + branch_offset; end
            `OP_BGTZ: begin branch_taken = ($signed(src1) > 0); branch_target = pc + branch_offset; end
            `OP_BLTZ_BGEZ: begin 
                branch_taken = (rt == 5'b00001) ? ($signed(src1) >= 0) : ($signed(src1) < 0); 
                branch_target = pc + branch_offset; 
            end
        endcase
    end
endmodule

module RegisterFile (
    input [4:0] read_addr1, 
    input [4:0] read_addr2, 
    output [31:0] read_data1, 
    output [31:0] read_data2, 
    input [4:0] write_addr, 
    input [31:0] write_data,
    input write_enable, 
    input clk
);

    reg [31:0] regfile [0:31];

    // MIPS Rule: Register 0 is ALWAYS hardwired to 0. 
    assign read_data1 = (read_addr1 == 5'b0) ? 32'b0 : regfile[read_addr1]; 
    assign read_data2 = (read_addr2 == 5'b0) ? 32'b0 : regfile[read_addr2]; 

    always @ (negedge clk) begin
        if (write_enable && (write_addr != 0)) begin
            regfile[write_addr] <= write_data;
        end
    end
endmodule



module Memory(
    input write_enable, 
    input clk, 
    input command, 
    input [7:0] address, 
    input [31:0] word_in, 
    output [31:0] word_out
);

    reg [31:0] Mem [0:255];

    assign word_out = (command == `READ_COMMAND) ? Mem[address] : 32'b0;

    always @ (posedge clk) begin
        if ((command == `WRITE_COMMAND) && (write_enable == 1'b1)) begin
            Mem[address] <= word_in;
        end
    end
endmodule







module Processor(
    input clk, output halt, input reset, output reg [7:0] pc, 
    input [31:0] ins, output [31:0] io_reg1, output [31:0] io_reg2,
    output [31:0] io_reg3, output [31:0] io_reg4,
    output reg io_stall, input copied_io_regs, output [31:0] out_io_regs_index
);
    wire [5:0] opcode = ins[31:26]; 
    wire [5:0] func = ins[5:0]; 
    wire [4:0] shift_amount = ins[10:6];
    wire [4:0] src1_addr = ins[25:21]; 
    wire [4:0] src2_addr = ins[20:16]; 
    wire [4:0] dest_addr = (opcode == `OP_JAL) ? 5'd31 : (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
    wire [15:0] imm = ins[15:0];
    wire [25:0] jump_target = ins[25:0];

    wire [31:0] src1, src2, dest_data, branch_target;
    wire dest_data_valid, branch_taken; 
    
    reg [31:0] io_reg [0:3]; 
    reg [31:0] io_reg_index; 
    reg fetched;

    reg [1:0] state; // 0: Fetch, 1: Execute, 2: Write-Back
    reg [31:0] inter_dest_data;
    reg [4:0] inter_dest_addr;
    reg inter_dest_valid;
    reg [7:0] inter_next_pc;

    assign io_reg1 = io_reg[0]; 
    assign io_reg2 = io_reg[1];
    assign io_reg3 = io_reg[2]; 
    assign io_reg4 = io_reg[3];
    assign out_io_regs_index = io_reg_index;

    wire [31:0] extended_imm = (opcode == `OP_ANDI || opcode == `OP_ORI || opcode == `OP_XORI) ? {16'b0, imm} : {{16{imm[15]}}, imm};
    wire [31:0] alu_in2 = (opcode == `OP_REG || opcode == `OP_BEQ || opcode == `OP_BNE) ? src2 : extended_imm;
    wire [31:0] branch_offset = (opcode == `OP_J || opcode == `OP_JAL) ? {6'b0, jump_target} : extended_imm;

    wire rf_we = (state == 2'd2) ? inter_dest_valid : 1'b0;
    
    RegisterFile rf (src1_addr, src2_addr, src1, src2, inter_dest_addr, inter_dest_data, rf_we & fetched, clk);
    
    ALU alu (src1, alu_in2, shift_amount, opcode, func, pc, branch_offset, src2_addr, dest_data, dest_data_valid, branch_target, branch_taken);

    always @(posedge clk) begin
        if (reset) begin
            pc <= 8'b0;
            io_reg_index <= 32'b0; 
            fetched <= 1'b0;
            state <= 2'd0; 
            io_stall <= 1'b0;
        end else if (!halt) begin
            fetched <= 1'b1;
            
            // Handshake Logic
            if (io_stall) begin
                if (copied_io_regs) begin
                    io_stall <= 1'b0;
                    io_reg_index <= 32'b0;
                end
            end else begin
                case (state)
                    2'd0: begin state <= 2'd1; end // Fetch
                    2'd1: begin // Execute
                        inter_dest_data <= dest_data;
                        inter_dest_addr <= dest_addr;
                        inter_dest_valid <= dest_data_valid;
                        inter_next_pc <= branch_taken ? branch_target[7:0] : pc + 1;
                        
                        // Fix: Freeze the state machine BEFORE advancing if we hit the 5th print
                        if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_write) && (io_reg_index == 4)) begin
                            io_stall <= 1'b1;
                        end else begin
                            if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_write)) begin
                                io_reg[io_reg_index] <= src2;
                                io_reg_index <= io_reg_index + 1; 
                            end
                            state <= 2'd2; // Safe to advance
                        end
                    end
                    2'd2: begin // Write-Back
                        pc <= inter_next_pc;
                        state <= 2'd0;
                    end
                endcase
            end
        end
    end

    assign halt = (reset | ~fetched) ? 1'b0 : (((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_exit)) ? 1'b1 : 1'b0);
endmodule



module Code(
    input reset, input [7:0] ins_addr, input [31:0] ins, 
    input clk, input done_storing, input copied_io_regs,
    output reg done, output flush_io_regs, output [31:0] out_io_regs_index,
    output [31:0] out_reg1, output [31:0] out_reg2, 
    output [31:0] out_reg3, output [31:0] out_reg4, 
    output [31:0] total_cycles, output [31:0] proc_cycles
);
    wire [7:0] pc;
    wire [31:0] ins_fetched;
    wire ins_mem_command;
    reg [31:0] counter_total;
    reg [31:0] counter_proc;
    wire halt;

    Memory mem(~reset & ~done_storing, clk, ins_mem_command, done_storing ? pc : ins_addr, ins, ins_fetched);
    
    Processor proc(clk, halt, ~done_storing, pc, ins_fetched, out_reg1, out_reg2, out_reg3, out_reg4, flush_io_regs, copied_io_regs, out_io_regs_index);

    assign total_cycles = counter_total;
    assign proc_cycles = counter_proc;
    assign ins_mem_command = done_storing ? `READ_COMMAND : `WRITE_COMMAND;

    always @(posedge clk) begin
        if (reset) begin
            counter_total <= 32'b0;
            counter_proc <= 32'b0;
            done <= 1'b0;
        end else begin
            done <= halt; 
            counter_total <= counter_total + 1;
            counter_proc <= (done_storing && !halt && !flush_io_regs) ? counter_proc + 1 : counter_proc;
        end
    end
endmodule