module tb;
 
       reg reset;
 
       reg clk;
 
       reg done_storing;
 
       reg [7:0] ins_addr;
 
       reg [31:0] ins;
 
       
 
       wire done;
 
       wire [31:0] out_reg1, out_reg2, out_reg3, out_reg4;
 
       wire [31:0] total_cycles, proc_cycles;
 

 
       // Instantiate Top Module
 
       Computer uut (
 
               .reset(reset),  
 
               .ins_addr(ins_addr),  
 
               .ins(ins),  
 
               .clk(clk),  
 
               .done_storing(done_storing),  
 
               .done(done),  
 
               .out_reg1(out_reg1),  
 
               .out_reg2(out_reg2),  
 
               .out_reg3(out_reg3),  
 
               .out_reg4(out_reg4),  
 
               .total_cycles(total_cycles),  
 
               .proc_cycles(proc_cycles)
 
       );
 

 
       // Generate a clock of period 10 (50% duty cycle)
 
       initial begin
 
               clk = 0;
 
               forever #5 clk = ~clk;
 
       end
 

 
       initial begin
 
               // Initially reset = 1, done_storing = 0
 
               reset = 1;
 
               done_storing = 0;
 
               ins_addr = 0;
 
               ins = 0;
 

 
               // At time = 7, make reset = 0
 
               #7 reset = 0;
 
               
 
               // Set the first instruction
 
               ins_addr = 0; ins = 32'h2001fff1; // addi $1, $0, -15
 
               
 
               // After 10 time units, set the second instruction, continue sequentially
 
               #10 ins_addr = 1; ins = 32'h20020014; // addi $2, $0, 20
 
               #10 ins_addr = 2; ins = 32'h00221820; // add $3, $1, $2
 
               #10 ins_addr = 3; ins = 32'h200403ec; // addi $4, $0, 1004
 
               #10 ins_addr = 4; ins = 32'h0083000c; // syscall $4, $3
 
               #10 ins_addr = 5; ins = 32'h200403e9; // addi $4, $0, 1001
 
               #10 ins_addr = 6; ins = 32'h0080000c; // syscall $4, $0
 

 
               // After 10 time units, set done_storing = 1
 
               #10 done_storing = 1;
 

 
               // Wait for processor to assert the 'done' signal
 
               wait(done);
 
               
 
               // Give it a brief moment before stopping to observe final registers
 
               #20;
 
               
 
               $display("-------------------------------------------------");
 
               $display("Program Output Result (out_reg1): %d", out_reg1);
 
               $display("Processor Cycles: %d", proc_cycles);
 
               $display("Total Cycles: %d", total_cycles);
 
               $display("-------------------------------------------------");
 
               
 
               $stop;
 
       end
 
endmodule
 

   

 
 