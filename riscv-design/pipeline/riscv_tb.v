`include "riscv.v"

module riscv_tb;

    parameter MEMORY_DEPTH = 6'b10_0000; // 32 in decimal

    reg clk, rst;

    integer i;
    integer verbose;

    riscv core(clk, rst);

    always #1 clk = ~clk;

    initial
        begin
            $dumpfile("../vcd/riscv_pipeline.vcd");
            $dumpvars(4, riscv_tb);

            //$readmemh({"./set-instructions/test-", test_case_number, ".hex"}, core.insmem.memfile);
            $readmemh("./set-instructions/corrected-test-22.hex", core.insmem.memfile);

            verbose = 1;

            clk = 0;

            #1
            rst = 1;

            #2
            rst = 0;

            #2000 
            
            if (verbose > 0)
            begin
                
                for(i=0; i < MEMORY_DEPTH; i=i+1)
                begin
                    $display("INSTRUCTION MEMORY[%2d] = %8b", i, core.insmem.memfile[i]);
                end

                for(i=0; i < MEMORY_DEPTH; i=i+1)
                begin
                    $display("DATA MEMORY[%2d] = %8b", i, core.datamem.memfile[i]);
                end
            end

            #5
            $finish;
        end
endmodule