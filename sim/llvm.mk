rtl_src_dir := $(root_dir)/src/
rtl_core_files ?= core.files
rtl_top_files ?= ahb_top.files
rtl_tb_files ?= ahb_tb.files
rtl_inc_dir ?= $(root_dir)/src/includes
rtl_inc_tb_dir ?= $(root_dir)/src/tb
top_module ?= top_exp_ahb

rtl_core_list := $(addprefix $(rtl_src_dir),$(shell cat $(rtl_src_dir)$(rtl_core_files)))
rtl_top_list := $(addprefix $(rtl_src_dir),$(shell cat $(rtl_src_dir)$(rtl_top_files)))
rtl_tb_list := $(addprefix $(rtl_src_dir),$(shell cat $(rtl_src_dir)$(rtl_tb_files)))
sv_list := $(rtl_core_list) $(rtl_top_list) $(rtl_tb_list)

build_verilator:
	mkdir -p build; \
	cd build; \
	verilator \
	-cc \
	-sv \
	+1800-2017ext+sv \
	-Wno-fatal \
	--top-module $(top_module) \
	-DSCR1_TRGT_SIMULATION \
	-CFLAGS -DVCD_TRACE -CFLAGS -DTRACE_LVLV=20 \
	-CFLAGS -DVCD_FNAME=simx.vcd \
	--clk clk \
	--exe /home/ocelaiwo/Workspace/sail-riscv-regular/c_emulator/riscv_exp.c \
	--trace \
	--trace-params \
    --trace-structs \
	--no-threads    \
    --no-timing     \
	--fno-merge-const-pool -x-assign fast -x-initial fast --noassert \
    --trace-underscore \
	--Mdir . \
	-I$(rtl_inc_dir) \
	-I$(rtl_inc_tb_dir) \
	-I/home/ocelaiwo/.opam/default/share/sail/lib/ \
	$(SIM_BUILD_OPTS) \
	$(sv_list); \
