all:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper.v
	vvp ./wrap.vvp

wave:
	gtkwave ./wave.vcd ./sigs_wrapper.gtkw

#tbshift: tb_shifter.v
#	iverilog -o ./tb_shifter.vvp tb_shifter.v
#	vvp ./tb_shifter.vvp

gtk:
	gtkwave ./wave.vcd ./new_sigs.gtkw

tbmax: tb_maxpool.v
	iverilog -o ./tb_maxpool.vvp tb_maxpool.v
	vvp ./tb_maxpool.vvp
	