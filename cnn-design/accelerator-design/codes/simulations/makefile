all:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper.v
	vvp ./wrap.vvp

all2:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper_big.v
	vvp ./wrap.vvp

all3:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper_2d.v
	vvp ./wrap.vvp

all4:
	iverilog -o ./wrap.vvp ../verilog/*.v tb_ren_conv_top_wrapper_unified.v
	vvp ./wrap.vvp

allriscv:
	iverilog -o ./wrap.vvp ../verilog/*.v ../../../../riscv-design/pipeline/*[^t][a-zA-Z0-9].v tb_ren_conv_top_wrapper_with_riscv.v
	vvp ./wrap.vvp

allriscv2d:
	iverilog -o ./wrap.vvp ../verilog/*.v ../../../../riscv-design/pipeline/*[^t][a-zA-Z0-9].v tb_ren_conv_top_wrapper_with_riscv_2dimg.v
	vvp ./wrap.vvp

allriscv2dpll:
	iverilog -o ./wrap.vvp ../verilog/*.v ../../../../riscv-design/pipeline/*[^t][a-zA-Z0-9].v tb_ren_conv_top_wrapper_with_riscv_2dimg_parallel.v
	vvp ./wrap.vvp

allv1:
	iverilog -o ./wrap.vvp ../verilog/*.v ../../../../riscv-design/pipeline/*[^t][a-zA-Z0-9].v tb_ren_conv_top_wrapper_with_riscv_2dimg_version1.v
	vvp ./wrap.vvp

allv2:
	iverilog -o ./wrap.vvp ../verilog/*.v ../../../../riscv-design/pipeline/*[^t][a-zA-Z0-9].v tb_ren_conv_top_wrapper_with_riscv_2dimg_version2.v
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
	