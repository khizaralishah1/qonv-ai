`include "../verilog/shifter.v"

module tb_shifter;
	
	parameter IN_WIDTH		= 20;
	parameter SHFT_WIDTH	= 4;
	parameter OUT_WIDTH		= 20;

	reg	 [IN_WIDTH-1:0] in;
	reg	 [SHFT_WIDTH-1:0] shift;
	wire [OUT_WIDTH-1:0] out;

	integer i;

	shifter
	# (
		.IN_WIDTH (20),
		.SHFT_WIDTH (4),
		.OUT_WIDTH (20)
	)
	shifter_inst
	(
		.in (in),
		.shift (shift),
		.out (out)
	);
	
	initial
	begin
		$dumpfile("shifter.vcd");
		$dumpvars(1, tb_shifter);
		
		in		= 0;
		shift	= 0;
		i       = 0;

		#1
		for ( i = 0; i < 5; i = i + 1)
			begin
			#2
			in = 20'b0000_0000_0000_0000_0000 + i;
			$display("in = %20b", shifter_inst.in);
			#2
			$display("ou = %20b\nshift was %4b\n", out, shift);  
			end
		
		$finish;
	end

endmodule