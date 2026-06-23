`include "defs.vh"

module Computer(
    input reset, 
    input [7:0] ins_addr, 
    input [31:0] ins, 
    input clk, 
    input done_storing, 
    output reg done, 
    output [31:0] out_reg1, 
    output [31:0] out_reg2, 
    output [31:0] out_reg3, 
    output [31:0] out_reg4, 
    output [31:0] total_cycles, 
    output [31:0] proc_cycles
);

wire [7:0] pc; 
wire [31:0] ins_fetched; 
wire ins_mem_command; 
reg [31:0] counter_total; 
reg [31:0] counter_proc; 
wire halt; 

Memory mem(~reset & ~done_storing, clk, ins_mem_command, done_storing ? pc : ins_addr, ins, ins_fetched);

Processor3 proc(clk, halt, ~done_storing, pc, ins_fetched, out_reg1, out_reg2, out_reg3, out_reg4);

assign total_cycles = counter_total;
assign proc_cycles = counter_proc;
assign ins_mem_command = done_storing ? `READ_COMMAND : `WRITE_COMMAND;

always @(posedge clk) begin
    if (reset) begin
        counter_total <= 32'b0;
        counter_proc <= 32'b0;
        done <= 1'b0;
    end
    else begin
        done <= halt;
        counter_total <= counter_total + 1'b1;
        // Only increment processor cycles when it is actually executing (not storing, and not halted)
        if (done_storing && !halt) begin
            counter_proc <= counter_proc + 1'b1;
        end
    end
end

endmodule