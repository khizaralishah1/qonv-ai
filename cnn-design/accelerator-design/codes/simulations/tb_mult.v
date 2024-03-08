`include "../verilog/mult.v"

module tb_mult;

	parameter WIDTH_A = 8;
	parameter WIDTH_B = 8;
    
	(
	input	signed		[WIDTH_A-1:0] 			a,
	input	signed		[WIDTH_B-1:0] 			b,
	//output	reg	signed	[WIDTH_A+WIDTH_B-1:0]	out
	output	reg	[WIDTH_A+WIDTH_B-1:0]	out
    );

	always@* out = 	a*b;

endmodule
	
	mult
	#(
		.DWIDTH 	(20 		)
	)
	max_pool_inst
	(
	.clk			(clk		),
	.reset			(reset		),
	.en_maxpool		(en_maxpool	),
	.data_in		(data_in	),
	.valid_in		(valid_in	),
	.data_out		(data_out	),
	.valid_out		(valid_out	)
	);
	
	initial
	begin
		clk = 0;
		forever #5 clk = ~clk;
	end

	initial
	begin
		$dumpfile("wave_mp.vcd");
		$dumpvars(0, tb_maxpool);
		
		reset		= 0;
		en_maxpool	= 0;
		data_in		= 0;
		valid_in	= 0;

		repeat(2) @(posedge clk);
		#1 reset		= 1;

		repeat(2) @(posedge clk);
		#1 reset		= 0;
		
		repeat(10) @(posedge clk);
		
		#1 valid_in = 1;

		@(posedge clk);
		$display("\ninitial in = %10d\nou = %10d\n", data_in, data_out);


		for(i = 1; i < 5; i = i + 1)
		begin
			@(posedge clk);
			#1 data_in = i;
			@(posedge clk);
			@(posedge clk);
			$display("\nin = %10d\nou = %10d\n", data_in, data_out);
		end
		#1 valid_in = 0;
					
		repeat(10) @(posedge clk);
		#1 valid_in = 1;
		data_in		= 0;
		en_maxpool	= 1;
		for(i=1; i <20; i=i+1)
		begin
			@(posedge clk);
			#1 data_in = i;
		end
		
		$finish;
	end

endmodule