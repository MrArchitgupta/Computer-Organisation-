`include "defs.vh"
 

 
module Processor3(
 
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
 

 
reg [1:0] state;  
 

 
reg [5:0] opcode_reg;
 
reg [5:0] func_reg;
 
reg [31:0] src1_reg;
 
reg [31:0] src2_reg;
 
reg [31:0] alu_src2_reg;
 
reg [4:0] shift_amount_reg;
 
reg [4:0] dest_addr_reg;
 

 
reg [4:0] write_addr_reg;
 
reg [31:0] write_data_reg;
 
reg write_enable_reg;
 

 
assign io_reg1 = io_reg[0];
 
assign io_reg2 = io_reg[1];
 
assign io_reg3 = io_reg[2];
 
assign io_reg4 = io_reg[3];
 

 
assign opcode = ins[31:26];
 
assign src1_addr = ins[25:21];
 
assign src2_addr = ins[20:16];
 
assign dest_addr = (opcode == `OP_REG) ? ins[15:11] : ins[20:16];
 
assign shift_amount = ins[10:6];
 
assign func = ins[5:0];
 
assign imm = ins[15:0];
 

 
wire [31:0] ext_imm = (opcode == `OP_ANDI || opcode == `OP_ORI || opcode == `OP_XORI) ?  
 
                                           {16'b0, imm} : {{16{imm[15]}}, imm};
 

 
wire [31:0] alu_src2 = (opcode == `OP_REG) ? src2 : ext_imm;
 

 
RegisterFile rf (
 
       .read_addr1(src1_addr),  
 
       .read_addr2(src2_addr),  
 
       .read_data1(src1),  
 
       .read_data2(src2),  
 
       .write_addr(write_addr_reg),  
 
       .write_data(write_data_reg),  
 
       .write_enable(write_enable_reg),  
 
       .clk(clk)
 
);
 

 
ALU alu (
 
       .src1(src1_reg),  
 
       .src2(alu_src2_reg),  
 
       .shift_amount(shift_amount_reg),  
 
       .opcode(opcode_reg),  
 
       .func(func_reg),  
 
       .dest(dest_data),  
 
       .dest_valid(dest_data_valid)
 
);
 

 
assign next_pc = (fetched  &  ~halt) ? pc + 1'b1 : 8'b0;
 

 
always @(posedge clk) begin
 
       if (reset) begin
 
               pc  <= 8'b0;
 
               io_reg_index  <= 2'b0;
 
               fetched  <= 1'b0;
 
               state  <= 2'b00;
 
               write_addr_reg  <= 5'b0;
 
               write_data_reg  <= 32'b0;
 
               write_enable_reg  <= 1'b0;
 
               // Explicitly clear I/O registers so Vivado maps them correctly
 
               io_reg[0]  <= 32'b0;
 
               io_reg[1]  <= 32'b0;
 
               io_reg[2]  <= 32'b0;
 
               io_reg[3]  <= 32'b0;
 
       end
 
       else begin
 
               case (state)
 
                       2'b00: begin  
 
                               opcode_reg  <= opcode;
 
                               func_reg  <= func;
 
                               src1_reg  <= src1;
 
                               src2_reg  <= src2;
 
                               alu_src2_reg  <= alu_src2;
 
                               shift_amount_reg  <= shift_amount;
 
                               dest_addr_reg  <= dest_addr;
 
                               
 
                               fetched  <= 1'b1;
 
                               state  <= 2'b01;  
 
                               write_enable_reg  <= 1'b0;  
 
                       end  
 
                       
 
                       2'b01: begin  
 
                               write_addr_reg  <= dest_addr_reg;                    
 
                               write_data_reg  <= dest_data;                            
 
                               write_enable_reg  <= dest_data_valid;            
 
                               
 
                               // FIXED: Syscall safely shifted to posedge!
 
                               if ((opcode_reg == `OP_REG)  &&  (func_reg == `FUNC_SYSCALL)  &&  (src1_reg == `SYS_write)) begin
 
                                       io_reg[io_reg_index]  <= src2_reg;
 
                                       io_reg_index  <= io_reg_index + 1'b1;
 
                               end
 
                               
 
                               state  <= 2'b10;  
 
                       end
 
                       
 
                       2'b10: begin
 
                               pc  <= halt ? pc : next_pc;  
 
                               state  <= 2'b00;  
 
                               write_enable_reg  <= 1'b0;  
 
                       end
 
               endcase
 
       end
 
end
 

 
assign halt = (reset | ~fetched) ? 1'b0 :  
 
                           (((opcode_reg == `OP_REG)  &&  (func_reg == `FUNC_SYSCALL)  &&  (src1_reg == `SYS_exit)) ? 1'b1 : 1'b0);
 

 
endmodule