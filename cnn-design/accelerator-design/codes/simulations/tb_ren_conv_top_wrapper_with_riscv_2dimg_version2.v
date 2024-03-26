//`include "../verilog/ren_conv_top_wrapper.v"
//`include "store_image.v"
//`include "./config_wb.v"

//     sim accdeg cnn f
// `include "../../../../riscv-design/pipeline/riscv.v"
// `include "../../../../riscv-design/pipeline/alu.v"
// `include "../../../../riscv-design/pipeline/registerfilenew.v"
// `include "../../../../riscv-design/pipeline/instructionmemory.v"
// `include "../../../../riscv-design/pipeline/adder.v"
// `include "../../../../riscv-design/pipeline/datamemory.v"
// `include "../../../../riscv-design/pipeline/immediategen.v"
// `include "../../../../riscv-design/pipeline/mux2_1.v"
// `include "../../../../riscv-design/pipeline/pc.v"
// `include "../../../../riscv-design/pipeline/alucontrol.v"
// `include "../../../../riscv-design/pipeline/maincontrol.v"
// `include "../../../../riscv-design/pipeline/ifidreg.v"
// `include "../../../../riscv-design/pipeline/idexreg.v"
// `include "../../../../riscv-design/pipeline/exmemreg.v"
// `include "../../../../riscv-design/pipeline/memwbreg.v"
// `include "../../../../riscv-design/pipeline/forwardingunit.v"
// `include "../../../../riscv-design/pipeline/mux3_1.v"
// `include "../../../../riscv-design/pipeline/hazarddetectionunit.v"
// `include "../../../../riscv-design/pipeline/mux2_1b.v"

module tb_ren_conv_top_wrapper;
	parameter KERN_COL_WIDTH 	= 3;
	parameter COL_WIDTH 		= 8; // address width
	parameter KERN_CNT_WIDTH 	= 3;
	parameter IMG_ADDR_WIDTH 	= 8;
	parameter RSLT_ADDR_WIDTH 	= 8;
	parameter KERNEL_DEPTH      = 32;
	parameter RESULT_DEPTH      = LOADED_IMG_SIZE;
    parameter MEMORY_DEPTH      = 32; // for riscv

	//some parameters I set for mnist images
	parameter IMG_SIZE          = 760 * 3; // 3 for repeated values
	parameter LOADED_IMG_SIZE   = IMG_SIZE/3; // 760/3 = 2
	parameter IMG_ROW_SIZE      = 28;
    parameter IMG_COL_SIZE      = 28;
    parameter NO_OF_INSTS		= 1; // 4

    // Wishbone Slave ports (WB MI A)
    reg 			wb_clk_i;
    reg 			wb_rst_i;
    reg 			wbs_stb_i;
    reg 			wbs_cyc_i;
    reg 			wbs_we_i;
    reg 	[3:0] 	wbs_sel_i;
    reg 	[31:0] 	wbs_dat_i;
    reg 	[31:0] 	wbs_adr_i;
    wire 			wbs_ack_o;
    wire 	[31:0] 	wbs_dat_o;

    reg             clk_riscv; // later make same clocks?
	reg				clk;
	reg				reset;

	reg				start;
	reg		[2:0]	kern_cols;
	reg		[7:0]	cols;
	reg		[2:0]	kerns;
	reg		[7:0]	stride;
	reg				kern_addr_mode;
	reg		[3:0]	shift;
	reg				en_max_pool;
	reg		[2:0]	mask;
	reg		[7:0]	result_cols;

	reg		[23:0]	image[0:LOADED_IMG_SIZE];
	reg		[23:0]	kernels[0:KERNEL_DEPTH-1];
	reg		[19:0]	result_sim[0:IMG_ROW_SIZE*NO_OF_INSTS];
	//reg		[7:0]	result[0:31];
	reg		[19:0]	result[0:IMG_ROW_SIZE];

    reg     [7:0]   iteration_offset;
    
	//reg 	[7:0]	result_depth;

	//real image
	//store_image store_img0();
	//reg [95:0] loaded_img;
	reg [7:0] loaded_img [0:IMG_SIZE];

	reg [8*64 - 1: 0] loaded_img_string;
	integer i,iter,run_count,j;

	reg [8 * 6 - 1 : 0] img_names [1:0];
	reg [7:0] img_count;

	reg [23:0] value;

    //riscv instance
    reg rst_riscv;
    reg from_riscv;

    riscv core(clk_riscv, rst_riscv); // later use different clocks for riscv and ren_cnn

	ren_conv_top_wrapper
	#(
	.NO_OF_INSTS		(NO_OF_INSTS		),
	.KERN_COL_WIDTH 	(KERN_COL_WIDTH 	),
	.COL_WIDTH 			(COL_WIDTH 			),
	.KERN_CNT_WIDTH 	(KERN_CNT_WIDTH 	),
	.IMG_ADDR_WIDTH 	(IMG_ADDR_WIDTH 	),
	.RSLT_ADDR_WIDTH 	(RSLT_ADDR_WIDTH 	)
	)
	ren_conv_top_wrapper_inst
	(
    // Wishbone Slave ports (WB MI A)
    .wb_clk_i		(wb_clk_i	),
    .wb_rst_i		(wb_rst_i	),
    .wbs_stb_i		(wbs_stb_i	),
    .wbs_cyc_i		(wbs_cyc_i	),
    .wbs_we_i		(wbs_we_i	),
    .wbs_sel_i		(wbs_sel_i	),
    .wbs_dat_i		(wbs_dat_i	),
    .wbs_adr_i		(wbs_adr_i	),
    .wbs_ack_o		(wbs_ack_o	),
    .wbs_dat_o		(wbs_dat_o	)
	);

always@* wb_clk_i = clk;
always@* wb_rst_i = reset;

initial
begin
	clk = 0;
	forever #5 clk = ~clk;
end

// parameter REG_BASE_ADDR 	= 32'h3000_0000;
// //parameter IMG_BASE_ADDR 	= 32'h3000_0100;
// parameter IMG_BASE_ADDR 	= 32'h3000_0400;
// parameter KERN_BASE_ADDR 	= 32'h3000_0200;
// parameter RES_BASE_ADDR 	= 32'h3000_0300;
parameter REG_BASE_ADDR 	= 32'h3000_0000;
//parameter IMG_BASE_ADDR 	= 32'h3000_0100;
parameter IMG_BASE_ADDR 	= 32'h3004_0000;
parameter KERN_BASE_ADDR 	= 32'h3002_0000;
parameter RES_BASE_ADDR 	= 32'h3003_0000;
parameter VERBOSE			= 9;
//-----------------------------------------------------------------------------
// Main test bench
//-----------------------------------------------------------------------------

always #1 clk_riscv = ~clk_riscv;

initial
begin
	$dumpfile("wavev1.vcd");
	$dumpvars(5, tb_ren_conv_top_wrapper);

    wb_clk_i	= 0;
    wbs_stb_i	= 0;
    wbs_cyc_i	= 0;
    wbs_we_i	= 0;
    wbs_sel_i	= 0;
    wbs_dat_i	= 0;
    wbs_adr_i	= 0;
	reset		= 0;
    iteration_offset = 0;


    $readmemh("../../../../riscv-design/pipeline/set-instructions/corrected-test-22.hex", core.insmem.memfile);
    clk_riscv   = 0;
    rst_riscv   = 1;
    #3
    rst_riscv   = 0;

    //wait until riscv puts all the image names in its data memory
    #2000

    if (VERBOSE > 10)
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

	repeat(2) @(posedge clk);
	#1 reset		= 1;
	repeat(2) @(posedge clk);
	#1 reset		= 0;

	repeat(10) @(posedge clk);

	// Configurations
	//config_test(0);
	config_test(1);

	run_count  = 1;
    from_riscv = 1;

	//risc should put the image names in its data memory, from where CNN can extract them one by one (or 4 each time if 4 instances of top module!)

	//load_data;
	img_count = 0;
	

	repeat(run_count)
	begin
		repeat(2) @(posedge clk);
		//load_data(from_riscv, img_names[img_count]);
        load_data(from_riscv, img_count);
		img_count = img_count+1;
        write_kernel(0);
        iter = 0;
        repeat( 26 ) // IMG_COL_SIZE / NO_OF_INSTS - 1
        begin
            // for (i = 0; i < 12; i = i+1)
			// begin
			// 	$display("seer before img %3d -> %3d %3d %3d", i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][7:0]);
			// end
            reset  = 0;
            write_image(iter);

                       //        IMG_ROW_SIZE 1      1          0                       0        1        111
            config_hw(0,kern_cols-1,cols-1,kerns-1,stride,kern_addr_mode,result_cols-1,shift,en_max_pool,mask, 1);
            //repeat(1000) @(posedge clk);
            // for (i = 0; i < 12; i = i+1)
			// begin
			// 	$display("seer mid %3d -> %3d %3d %3d", i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][7:0]);
			// end

            poll_done(0);

            $display("-------- iteration %2d ----------", iter);
            calculate_results(0, iter);
            repeat(10) @(posedge clk);

            iteration_offset = (iter == 6) ? 2 : (iter == 14) ? 1 : 0;
            $display("offset is %2d", iteration_offset);
			readback_results(0);
            repeat(10) @(posedge clk);
            compare_results;

            // for (i = 0; i < 20; i = i+1)
			// begin
			// 	$display("seei %3d -> %3d %3d %3d", i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][7:0]);
			// end

            // for (i = 0; i < 20; i = i+1)
			// begin
			// 	$display("seek %3d -> %3d %3d %3d", i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][7:0]);
			// end

            // for (i = 0; i < 12; i = i+1)
			// begin
			// 	$display("seer after %3d -> %3d %3d %3d", i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.results_dffram.r[i][7:0]);
			// end

            config_hw(0,0,0,0,0,0,0,0,0,0,0);

            wb_write(REG_BASE_ADDR+ (0 << 24),2);	// Set soft reset
			wb_write(REG_BASE_ADDR+ (0 << 24),0);	// Clear Start
			//wb_write(REG_BASE_ADDR+ (3 << 24),2);	// Set soft reset
			
            for(i=0; i < result_cols; i=i+1)
            begin
                result_sim[i]	<= 0;
                result[i]		<= 0;
            end
            // $display("here");
            // $display("here22");
			wb_write(REG_BASE_ADDR+ (0 << 24),0);	// Clear soft reset
            //$display("here2");

            iter = iter + 1;
            
            #2 reset  = 1;
            repeat(10) @(posedge clk);
            //$display("-------- here ----------", iter);
            //ren_conv_top_wrapper_inst.ren_conv_top_inst_0.ren_conv_inst.done = 0;
            //ren_conv_top_wrapper_inst.ren_conv_top_inst_0.ren_conv_inst.done = 0;
        end
	end
	$display("------------------------STATUS: Simulation complete-------------------------");

	$finish;
end
//-----------------------------------------------------------------------------
task config_test;
input [31:0] test_no;
begin
	if(test_no==0)		// Experiment in this case
	begin
	kern_cols			= 2;
    //cols				= 8;
	cols				= IMG_ROW_SIZE;
    kerns				= 1; // 3
	//result_depth		= kerns * cols;
    stride				= 1;
    kern_addr_mode		= 0;
    shift				= 0; // 12
    en_max_pool			= 1;
	//en_max_pool			= 0;
    mask				= 3'b111;
    result_cols			= en_max_pool ? (cols*kerns)/2 : cols*kerns;
	//names of images
	img_names[0]		= "40099";
	img_names[1]		= "28457";

	$display("--------------------------------------------------------------------------");
	end
	else if(test_no==1)		// Typical case with even cols and max pool enabled
	begin
	kern_cols			= 3;
    cols				= IMG_ROW_SIZE;
    kerns				= 1;
    stride				= 1;
    kern_addr_mode		= 0;
    shift				= 0; // 12
    en_max_pool			= 1;
    mask				= 3'b111;
    result_cols			= en_max_pool ? (cols*kerns)/2 : cols*kerns;
	//names of images
	img_names[0]		= "40099";
	img_names[1]		= "28457";
	end
	else if(test_no==2)	// Maxpool disabled
	begin
	kern_cols			= 3;
    cols				= 8;
    kerns				= 3;
    stride				= 1;
    kern_addr_mode		= 0;
    shift				= 0; // 12
    en_max_pool			= 1;
    mask				= 3'b111;
    result_cols			= en_max_pool ? cols*kerns/2 : cols*kerns;
	end
	else if(test_no==3)	// overflow (with dummy data) in third kernel
	begin
	kern_cols			= 4;
    cols				= 8;
    kerns				= 3;
    stride				= 1;
    kern_addr_mode		= 0;
    shift				= 0; // 12
    en_max_pool			= 1;
    mask				= 3'b111;
    result_cols			= en_max_pool ? cols*kerns/2 : cols*kerns;
	end
	
	$display("-----------SIMLULATION PARAMS------------");
	$display("kern_cols        = %0d",kern_cols);
	$display("cols             = %0d",cols		);
	$display("kerns            = %0d",kerns	);
	$display("stride           = %0d",stride	);
	$display("kern_addr_mode   = %0d",kern_addr_mode);
	$display("shift            = %0d",shift	);
	$display("en_max_pool      = %0d",en_max_pool);
	$display("mask             = %0d",mask		);
	$display("result_cols      = %0d",result_cols);
	$display("-----------------------------------------");
end
endtask
//-----------------------------------------------------------------------------
task poll_done;
input [7:0] inst_no;
reg [31:0] data_;
integer cnt;
begin
	data_ = 0;
	cnt = 0;
	while(!data_[0])
	begin
		wb_read(REG_BASE_ADDR + (inst_no << 24), data_);
		
		cnt=cnt+1;
		//$display("wbs_dat_o = %3d",wbs_dat_o);
		if(cnt>100)
		begin
			$display("Stuck in polling for done... Finishing");
			$finish;
		end
		repeat(10) @(posedge clk);
	end
end
endtask
//-----------------------------------------------------------------------------
task compare_results;
integer error_cnt;
begin
	error_cnt = 0;
	for(i=0; i < result_cols; i=i+1)
	begin
		if(result[i] !== result_sim[i])
		begin
			error_cnt=error_cnt+1;
			$display("MISMATCH: Actual = %d != Simulated = %d at index %d, ERROR_CNT %d", result[i], result_sim[i],i,error_cnt);
            //$stop;
		end
		else
			if(VERBOSE>0)$display("   MATCH: Actual = %d == Simulated = %d at index %d", result[i], result_sim[i],i);

	end
	if(error_cnt==0)
		$display("STATUS: No errors found");
end
endtask
//-----------------------------------------------------------------------------
task readback_results;
input [7:0] inst_no;
begin
    if (iteration_offset == 2)
    begin
      for(i=0; i < result_cols - iteration_offset; i=i+1)
        begin
            wb_read(RES_BASE_ADDR+ (inst_no << 24)+i*4, result[i + iteration_offset]);
            //$display("addr = %4h ; result[%2d] --> %10d", RES_BASE_ADDR+ (inst_no << 24)+i*4, i, result[i]);
        end

      for(i=0; i < iteration_offset; i=i+1)
        begin
            wb_read(RES_BASE_ADDR+ (inst_no << 24)+i*4 + (result_cols-iteration_offset)*4, result[i]);

        end
    end
    else if (iteration_offset == 1)
    begin
      for(i=1; i < result_cols; i=i+1)
        begin
            wb_read(RES_BASE_ADDR+ (inst_no << 24)+i*4, result[i - iteration_offset]);
            //$display("addr = %4h ; result[%2d] --> %10d", RES_BASE_ADDR+ (inst_no << 24)+i*4, i, result[i]);
        end
            wb_read(RES_BASE_ADDR+ (inst_no << 24), result[result_cols]);
    end
    else
        begin
        for(i=0; i < result_cols; i=i+1)
        begin
            wb_read(RES_BASE_ADDR+ (inst_no << 24)+i*4, result[i]);
            //$display("addr = %4h ; result[%2d] --> %10d", RES_BASE_ADDR+ (inst_no << 24)+i*4, i, result[i]);
        end
        end

    for(i=0; i < result_cols; i=i+1)
    begin
        if (result[i] == 20'bx)
            result[i] = 0;
        //$display("addr = %4h ; result[%2d] --> %10d", RES_BASE_ADDR+ (inst_no << 24)+i*4, i, result[i]);
    end

end
endtask
//-----------------------------------------------------------------------------
task calculate_results;
input [7:0] inst_no;
input [7:0] next_iter; // 4
reg [20:0] conv_result [0: RESULT_DEPTH];
integer ks, c,kc;
begin
	// convolve
	for(ks=0; ks<kerns;ks=ks+1) // all kernels
	begin
		for(c=0; c<cols-kern_cols+1;c=c+1) // image rows, the whole first COL (3 components per row)
		begin
			conv_result[c+ks*cols] = 0; // 16 to 23
			for(kc=0;kc<kern_cols;kc=kc+1) // 0 to 2
			begin // 8 bit each
				conv_result[c+ks*cols] = conv_result[c+ks*cols] +
								 mask[0] * (image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][ 7:0 ]*kernels[ks*(4<<kern_addr_mode)+kc][ 7:0 ]) +
								 mask[1] * (image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][15:8 ]*kernels[ks*(4<<kern_addr_mode)+kc][15:8 ]) +
								 mask[2] * (image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][23:16]*kernels[ks*(4<<kern_addr_mode)+kc][23:16]);
				//$display("conv_result[%2d] = %10d", c+ks*cols, conv_result[c+ks*cols]);
                //$display("image--[%3d] = %3d %3d %3d", next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc, image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][ 23:16 ], image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][15:8 ], image[next_iter*IMG_ROW_SIZE + cols*inst_no*(ks+1)+c+kc][7:0]);
                //$display("next iter is %3d", next_iter);
			end
			//if(VERBOSE>5) $display("conv_result[%2d] = %10d", c+ks*cols, conv_result[c+ks*cols]);//$display("");
		end
	end
	// max pool
	if(en_max_pool)
		for(ks=0; ks<kerns;ks=ks+1)
		begin
			for(c=0; c<cols-kern_cols+1;c=c+2)
			begin
				result_sim[ks*cols/2 + c/2] =  (conv_result[ks*cols + c] > conv_result[ks*cols + c+1]) ? conv_result[ks*cols + c] : conv_result[ks*cols + c+1];
				//$display("conv_result[%2d] (%2d) > conv_result[%2d] (%2d)---> result_sim[%2d] = %5d\n", ks*cols + c, conv_result[ks*cols + c], ks*cols + c + 1, conv_result[ks*cols + c + 1], ks*cols/2 + c/2, result_sim[ks*cols/2 + c/2]);
				//$display("actual result aana chaiye: %10d\n", ( (conv_result[ks*cols + c] > conv_result[ks*cols + c+1]) ? conv_result[ks*cols + c] : conv_result[ks*cols + c+1]) );
				//$display("lt_sum[%2d] = %5d\n", ....);
				
				//if(VERBOSE>5)$display("result_sim[%0d] = %0d", ks*cols/2 + c/2, result_sim[ks*cols/2 + c/2]);
			end
		end
	else
		for(c=0; c<result_cols;c=c+1)
		begin
			result_sim[c] =  conv_result[c];
			//if(VERBOSE>5)$display("result_sim[%0d] = %0d",c,result_sim[c]);
		end

end
endtask
//-----------------------------------------------------------------------------
task load_data;
input input_from_riscv;
input [8 * 5 - 1:0] img_addr; // 5 decimal digits -> max is 99,999 = 17 bits
reg [8 * 5 - 1 : 0] img_full_name;
integer j;
begin
    //when image address is located in riscv data memory, then image name is in 5 locations, each is 1-byte
    if (input_from_riscv == 1)
    begin
        img_full_name = {core.datamem.memfile[img_addr+4], core.datamem.memfile[img_addr+3], core.datamem.memfile[img_addr+2], core.datamem.memfile[img_addr+1], core.datamem.memfile[img_addr]};
        // 5 characters are stored sequentially
        $display("img full name is %s",img_full_name);

    end
    else
    begin
      img_full_name = img_addr;
    end
    
	//                    sim cod in main file
	loaded_img_string = {"../../../mnist_bin/training/0/", img_full_name}; // 28457

	$readmemb(loaded_img_string, loaded_img);

	// for(i = 0; i < IMG_SIZE; i = i + 1)
	// begin
	// 	$display("loaded_img[%2d] = %10d", i, loaded_img[i]);
	// end

    if (VERBOSE>8)
    begin
        for(i = 0; i < IMG_ROW_SIZE; i = i + 1)
        begin
            for(j = 0; j < IMG_COL_SIZE; j = j + 1)
            begin
                $write("%4d", loaded_img[IMG_ROW_SIZE*i + j]);
            end
            $display("");
        end
    end


    for(iter = 0; iter < NO_OF_INSTS*(IMG_COL_SIZE / NO_OF_INSTS - 1); iter=iter+1)
    begin
        //$display("iter started with %2d", iter);
        for(i=0; i < IMG_ROW_SIZE; i=i+1)
        begin
            image[IMG_ROW_SIZE*iter + i] =  {loaded_img[IMG_ROW_SIZE*i + iter], loaded_img[IMG_ROW_SIZE*i + 1 + iter],loaded_img[IMG_ROW_SIZE*i + 2 + iter]};
            //$display("image[%3d] = %3d %3d %3d", IMG_ROW_SIZE*iter + i, image[IMG_ROW_SIZE*iter + i][23:16], image[IMG_ROW_SIZE*iter + i][15:8], image[IMG_ROW_SIZE*iter + i][7:0]);
            //$display("loaded = %3d %3d %3d", loaded_img[IMG_ROW_SIZE*i + iter], loaded_img[IMG_ROW_SIZE*i + 1 + iter],loaded_img[IMG_ROW_SIZE*i + 2 + iter]);
        end
    end
        
    iter = 0;

	// Dummy data for kernels
	for(i=0; i < KERNEL_DEPTH; i = i + 1)
	begin
		kernels[i] =  (1+i/4)*'h10000 + (1+i/4)*'h100 + (1+i/4);
	//  i=0 to 3	'h         1 0000      100           1        = 1 _ 0000 _ 1001
	//	i=4 to 7	'h         2 0000      200           1        = 2 _ 0000 _ 2002
		//       
		//$display("kernels[%2d] => [23:16]->%2d, [15:8]->%2d, [7:0]->%2d\n", i, kernels[i][23:16], kernels[i][15:8], kernels[i][7:0]);
	end

end
endtask
//-----------------------------------------------------------------------------
task write_image;
input [7:0] next_iter;
begin
	for(i=0; i < IMG_ROW_SIZE; i=i+1)
	begin
		wb_write(IMG_BASE_ADDR + (0 << 24)+i*4, {8'd0, image[IMG_ROW_SIZE*0 + i + next_iter*IMG_ROW_SIZE]});
	end

    // if (VERBOSE > 3)
    // begin
    //     $display("IMAGE DFFRAM -- %3d", next_iter);
    //     for(i=0; i < IMG_ROW_SIZE; i=i+1)
    //     begin
    //         $display("addr = %4h ; imgdff[%2d] =  %20d", IMG_BASE_ADDR + (0 << 24)+i*4, IMG_ROW_SIZE*0 + i + next_iter*IMG_ROW_SIZE, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i]);
    //         //$display("addr = %4h ; imgdff[%2d] =  %20d", IMG_BASE_ADDR + (0 << 24)+i*4, IMG_ROW_SIZE*0 + i + next_iter*IMG_ROW_SIZE, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.img_dffram.r[i][7:0]);
    //     end
    // end
end
endtask
//-----------------------------------------------------------------------------
task write_kernel;
input [7:0] inst_no;
begin
	for(i=0; i < KERNEL_DEPTH; i=i+1)
    begin
		wb_write(KERN_BASE_ADDR+ (0 << 24)+i*4, {8'd0,kernels[i]});
        //wb_write(KERN_BASE_ADDR+ (1 << 24)+i*4, {8'd0,kernels[i]});
        //wb_write(KERN_BASE_ADDR+ (2 << 24)+i*4, {8'd0,kernels[i]});
        //wb_write(KERN_BASE_ADDR+ (3 << 24)+i*4, {8'd0,kernels[i]});
    end

    if (VERBOSE > 5)
    begin
        // $display("instance 0");
        // for(i=0; i < KERNEL_DEPTH; i=i+1)
        // begin
        //     $display("addr = %4h ; kernel[%2d] =  %10d %10d %10d", KERN_BASE_ADDR+ (0 << 24)+i*4, i, ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_0.kerns_dffram.r[i][7:0]);
        // end
        // $display("instance 1");
        // for(i=0; i < KERNEL_DEPTH; i=i+1)
        // begin
        //     $display("addr = %4h ; kernel[%2d] =  %10d %10d %10d", KERN_BASE_ADDR+ (1 << 24)+i*4, i, ren_conv_top_wrapper_inst.ren_conv_top_inst_1.kerns_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_1.kerns_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_1.kerns_dffram.r[i][7:0]);
        // end
        // $display("instance 2");
        // for(i=0; i < KERNEL_DEPTH; i=i+1)
        // begin
        //     $display("addr = %4h ; kernel[%2d] =  %10d %10d %10d", KERN_BASE_ADDR+ (2 << 24)+i*4, i, ren_conv_top_wrapper_inst.ren_conv_top_inst_2.kerns_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_2.kerns_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_2.kerns_dffram.r[i][7:0]);
        // end
        // $display("instance 3");
        // for(i=0; i < KERNEL_DEPTH; i=i+1)
        // begin
        //     $display("addr = %4h ; kernel[%2d] =  %10d %10d %10d", KERN_BASE_ADDR+ (3 << 24)+i*4, i, ren_conv_top_wrapper_inst.ren_conv_top_inst_3.kerns_dffram.r[i][23:16], ren_conv_top_wrapper_inst.ren_conv_top_inst_3.kerns_dffram.r[i][15:8], ren_conv_top_wrapper_inst.ren_conv_top_inst_3.kerns_dffram.r[i][7:0]);
        // end
    end
end
endtask
//-----------------------------------------------------------------------------
task config_hw;
input   [7:0]   inst_no;
input	[2:0]	kern_cols_in;
input	[7:0]	cols_in;
input	[2:0]	kerns_in;
input	[7:0]	stride_in;
input			kern_addr_mode_in;
input	[7:0]	result_cols_in;
input	[3:0]	shift_in;
input			en_max_pool_in;
input	[2:0]	mask_in;
input           start_signal;
begin
	// start			= regs[0][2];
	// kern_cols		= regs[1][2:0];
	// cols				= regs[1][15:8];
	// kerns			= regs[1][18:16];
	// stride			= regs[1][31:24];
	// kern_addr_mode	= regs[2][16];
	// shift			= regs[2][11:8];
	// en_max_pool		= regs[2][17];
	// mask				= regs[2][20:18];
	// result_cols		= regs[2][7:0];
	//cleaning
	// for(i = 0; i < 100; i = i + 1)
	// 	wb_write(REG_BASE_ADDR+ (inst_no << 24) + i*4, 0);

	//         address                            data
	wb_write(REG_BASE_ADDR+ (inst_no << 24)+4, 	
								kern_cols_in 		  +
								(cols_in  	<< 8	) +
								(kerns_in 	<< 16	) +
								(stride_in 	<< 24	));

	wb_write(REG_BASE_ADDR+ (inst_no << 24)+8, 	
								result_cols_in 			   +
								(shift_in 			<< 8)  +
								(kern_addr_mode_in 	<< 16) +
								(en_max_pool_in 	<< 17) +
								(mask_in 			<< 18));


	wb_write(REG_BASE_ADDR+ (inst_no << 24),start_signal*4);	// Start

end
endtask
//-----------------------------------------------------------------------------
task wb_write;
	input [31:0] addr;
	input [31:0] data;
	begin
		@(posedge clk);
		#1;
		wbs_stb_i	= 1;
		wbs_cyc_i	= 1;
		wbs_we_i	= 1;
		wbs_sel_i	= 4'hf; // 4'b1111
		wbs_dat_i	= data;
		wbs_adr_i	= addr;

		@(posedge clk);

		while(~wbs_ack_o)	@(posedge clk);
		//$display("WISHBONE WRITE: Address=0x%h, Data= %15d",addr,data);
		//$display("WISHBONE WRITE: Address=0x%h, Data= %3d %3d %3d",addr,data[23:16],data[15:8], data[7:0]);
		#1;
		wbs_stb_i	= 1'bx;
		wbs_cyc_i	= 0;
		wbs_we_i	= 1'hx;
		wbs_sel_i	= 4'hx;
		wbs_dat_i	= 32'hxxxx_xxxx;
		wbs_adr_i	= 32'hxxxx_xxxx;
	end
endtask
//-----------------------------------------------------------------------------
task wb_read;
	input 	[31:0] addr;
	output 	[31:0] data;
	begin

		@(posedge clk);
		#1;
		wbs_stb_i	= 1;
		wbs_cyc_i	= 1;
		wbs_we_i	= 0;
		wbs_sel_i	= 4'hf;
		wbs_adr_i	= addr;

		@(posedge clk);

		while(~wbs_ack_o)	@(posedge clk);

		// negate wishbone signals
		#1;
		wbs_stb_i	= 1'bx;
		wbs_cyc_i	= 0;
		wbs_we_i	= 1'hx;
		wbs_sel_i	= 4'hx;
		wbs_adr_i	= 32'hxxxx_xxxx;
		data		= wbs_dat_o;
		//$display("WISHBONE READ: Address=0x%h, Data= %3d, wbs_dat_o= %3d",addr,data,wbs_dat_o);

	end
endtask
//-----------------------------------------------------------------------------

endmodule