`include "defs.vh"

module Processor(
    input clk, 
    output halt, 
    input reset, 
    output reg [7:0] pc, 
    input [31:0] ins, 
    output [31:0] io_reg1, 
    output [31:0] io_reg2, 
    output [31:0] io_reg3, 
    output [31:0] io_reg4
);

wire [5:0] opcode; 
wire [5:0] func; 
wire [4:0] shift_amount; 
wire [4:0] src1_addr; 
wire [4:0] src2_addr; 
wire [31:0] src1; 
wire [31:0] src2; 
wire [4:0] dest_addr; 
wire [31:0] dest_data; 
wire dest_data_valid; 
wire [7:0] next_pc; 
wire [15:0] imm; 

reg [31:0] io_reg [0:3]; 
reg [1:0] io_reg_index; 
reg fetched; 

assign io_reg1 = io_reg[0];
assign io_reg2 = io_reg[1];
assign io_reg3 = io_reg[2];
assign io_reg4 = io_reg[3];

// Decode instruction logic
assign opcode = ins [31:26];
assign src1_addr = ins [25:21]; // rs
assign src2_addr = ins [20:16]; // rt
assign dest_addr = (opcode == `OP_REG) ? ins [15:11] : ins [20:16]; // rd for R-type, rt for I-type
assign shift_amount = ins [10:6];
assign func = ins [5:0];
assign imm = ins [15:0];

// Immediate extension: Zero-extend for logical, Sign-extend for arithmetic
wire [31:0] ext_imm = (opcode == `OP_ANDI || opcode == `OP_ORI || opcode == `OP_XORI) ? 
                      {16'b0, imm} : {{16{imm[15]}}, imm};

// ALU operand mux: R-type uses src2 (register), I-type uses extended immediate
wire [31:0] alu_src2 = (opcode == `OP_REG) ? src2 : ext_imm;

RegisterFile rf (src1_addr, src2_addr, src1, src2, dest_addr, dest_data, dest_data_valid & fetched, clk);

ALU alu (src1, alu_src2, shift_amount, opcode, func, dest_data, dest_data_valid);

assign next_pc = (fetched & ~halt) ? pc + 1'b1 : 8'b0;

always @(posedge clk) begin
    if (reset) begin
        pc <= 8'b0;
        io_reg_index <= 2'b0;
        fetched <= 1'b0;
    end
    else begin
        pc <= halt ? pc : next_pc;
        fetched <= 1'b1;
    end
end

always @(negedge clk) begin
    if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_write)) begin
        io_reg_index <= io_reg_index + 1'b1;
        io_reg[io_reg_index] <= src2;
    end
end

assign halt = (reset | ~fetched) ? 1'b0 : 
              (((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_exit)) ? 1'b1 : 1'b0);

endmodule



