all:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper.v
	vvp ./wrap.vvp

wave:
	gtkwave ./wave.vcd ./sigs_wrapper.gtkw