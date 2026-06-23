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
    output [31:0] io_reg4,
    
    output reg io_stall,
    output reg [2:0] io_reg_index, 
    input copied_io_regs
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
    reg fetched;
    
    
    reg [2:0] current_print_count; 
    reg [1:0] state; 
    reg program_done;
    
    reg [31:0] dest_data_reg;
    reg dest_data_valid_reg;
    reg [4:0] dest_addr_reg;

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

    RegisterFile rf (
        src1_addr, src2_addr, src1, src2, 
        dest_addr_reg, dest_data_reg, 
        (state == 2) ? dest_data_valid_reg : 1'b0, 
        clk
    );

    ALU alu (
        src1, (opcode == `OP_REG) ? src2 : {{16{imm[15]}}, imm}, 
        shift_amount, opcode, func, dest_data, dest_data_valid
    );

    assign halt = (program_done) ? 1'b1 : 1'b0;
    
    assign next_pc = pc + 1;

    always @(posedge clk) begin
        if (reset) begin
            pc <= 8'b0;
            current_print_count <= 0;
            io_reg_index <= 0;
            fetched <= 1'b0;
            io_stall <= 1'b0;
            state <= 0;
            program_done <= 1'b0;

            io_reg[0] <= 32'b0; io_reg[1] <= 32'b0; 
            io_reg[2] <= 32'b0; io_reg[3] <= 32'b0;
        end else begin
            
         
            if (copied_io_regs && io_stall) begin
                io_stall <= 1'b0;         
                current_print_count <= 0; 
               
            end 
            else if (!io_stall && !halt) begin
                fetched <= 1'b1;
                
                case(state)
                    2'd0: begin 
                        state <= 1;
                    end
                    
                    2'd1: begin 
                        
                        if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_exit)) begin
                            program_done <= 1'b1;
                            io_reg_index <= current_print_count; 
                            state <= 0;
                        end
                       
                        else if ((opcode == `OP_REG) && (func == `FUNC_SYSCALL) && (src1 == `SYS_write)) begin
                            if (current_print_count == 4) begin
                               
                                io_stall <= 1'b1;
                             
                            end else begin
                               
                                io_reg[current_print_count] <= src2;
                                current_print_count <= current_print_count + 1;
                               
                                dest_data_valid_reg <= 1'b0; 
                                state <= 2;
                            end
                        end
                 
                        else begin
                            dest_data_reg <= dest_data;
                            dest_data_valid_reg <= dest_data_valid;
                            dest_addr_reg <= dest_addr;
                            state <= 2;
                        end
                    end
                    
                    2'd2: begin 
                        pc <= next_pc; 
                        state <= 0;
                    end
                endcase
            end
        end
    end
endmodule