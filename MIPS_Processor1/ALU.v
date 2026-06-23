`include "defs.vh"

module ALU (
    input [31:0] src1, 
    input [31:0] src2, 
    input [4:0] shift_amount, 
    input [5:0] opcode, 
    input [5:0] func, 
    output [31:0] dest, 
    output dest_valid
);

reg [31:0] result;
reg result_valid;

assign dest = result; 
assign dest_valid = result_valid; 

always @(*) begin
    result = 32'b0;
    result_valid = 1'b0;
    
    case (opcode)
       `OP_REG: begin
            case (func)
                // --- FIXED: Shift src2 by shift_amount ---
                `FUNC_SLL:  begin result = src2 << shift_amount; result_valid = 1'b1; end
                `FUNC_SRL:  begin result = src2 >> shift_amount; result_valid = 1'b1; end
                `FUNC_SRA:  begin result = $signed(src2) >>> shift_amount; result_valid = 1'b1; end
                
                // --- FIXED: Shift src2 by the value inside src1 ---
                `FUNC_SLLV: begin result = src2 << src1[4:0]; result_valid = 1'b1; end
                `FUNC_SRLV: begin result = src2 >> src1[4:0]; result_valid = 1'b1; end
                `FUNC_SRAV: begin result = $signed(src2) >>> src1[4:0]; result_valid = 1'b1; end
                
                // --- Arithmetic and Logic (Unchanged) ---
                `FUNC_ADD:  begin result = src1 + src2; result_valid = 1'b1; end
                `FUNC_SUB:  begin result = src1 - src2; result_valid = 1'b1; end
                `FUNC_AND:  begin result = src1 & src2; result_valid = 1'b1; end
                `FUNC_OR:   begin result = src1 | src2; result_valid = 1'b1; end
                `FUNC_XOR:  begin result = src1 ^ src2; result_valid = 1'b1; end
                `FUNC_NOR:  begin result = ~(src1 | src2); result_valid = 1'b1; end
                `FUNC_SYSCALL: begin result_valid = 1'b0; end
            endcase
        end

//Ye change kr na alu mai
        `OP_ADDI: begin result = src1 + src2; result_valid = 1'b1; end
        `OP_ANDI: begin result = src1 & src2; result_valid = 1'b1; end
        `OP_ORI:  begin result = src1 | src2; result_valid = 1'b1; end
        `OP_XORI: begin result = src1 ^ src2; result_valid = 1'b1; end
    endcase
end

endmodule