//`include "ctrl_status_regs_4.v"

module regs
	#(
		parameter DWIDTH = 32
	)
	(
	input						clk,
	input						reset,
	input		[1:0]			addr,
	input						wr_en,
	input		[DWIDTH-1:0]	data_in,

	output		[DWIDTH-1:0]	data_out,
	
	// Control signals
	output					start,
	output					soft_reset,

	output 		[2:0]		kern_cols,
	output		[7:0]		cols,
	output		[2:0]		kerns,
	output		[7:0]		stride,
	output					kern_addr_mode,
	output		[7:0]		result_cols,
	output		[3:0]		shift,
	output					en_max_pool,
	output		[2:0]		mask,
	
	// Status signals
	input					done,
	input					accum_ovrflow
	
	);

	wire	[DWIDTH-1:0] regs[0:4];

	ctrl_status_regs_4
	#(
		.DWIDTH	(32)
	)
	ctrl_status_regs_4_inst
	(
	.clk		(clk		),
	.reset		(reset		),
	.addr		(addr		),
	.wr_en		(wr_en		),
	.data_in	(data_in	),
	.data_out	(data_out	),
		
	//data_in comes and gets stored in one of these
	.ctrl0		(regs[0]	),
	.ctrl1		(regs[1]	),
	.ctrl2		(regs[2]	),
	.ctrl3		(regs[3]	),

	//stored data gets out as data_out
	.status0	({regs[0][DWIDTH-1:2],accum_ovrflow,done}),
	.status1	(regs[1]	),
	.status2	(regs[2]	),
	.status3	(regs[3]	)
	);


	// Specific mappings to configurations
	assign start			= regs[0][2];
	assign soft_reset		= regs[0][3];
	assign kern_cols		= regs[1][2:0];
    assign cols				= regs[1][15:8];
    assign kerns			= regs[1][18:16];
    assign stride			= regs[1][31:24];
    assign result_cols		= regs[2][7:0];
    assign shift			= regs[2][11:8];
    assign kern_addr_mode	= regs[2][16];
    assign en_max_pool		= regs[2][17];
	assign mask				= regs[2][20:18];

endmodule