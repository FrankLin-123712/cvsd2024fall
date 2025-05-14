design_name = core

root_dir := $(PWD)
bld_dir := ./build

tb_dir := ../00_TB


$(bld_dir):
	mkdir -p $(bld_dir); \

nWave:
	nWave $(design_name).fsdb &


verdi: | $(bld_dir)
	verdi -ssf $(design_name).fsdb &


tb: | clean
	@if [ -z "$(filter p%, $(MAKECMDGOALS))" ]; then \
		echo "Error: Please specify a valid argument starting with 'p' (e.g., 'make tb p0')"; \
		exit 1; \
	fi
	vcs -full64 -R -f rtl.f +v2k -sverilog -debug_access+all \
	+pattern_num=$(filter p%, $(MAKECMDGOALS)) | tee sim.log \


tb_all: | clean
	vcs -full64 -R -f rtl.f +v2k -sverilog -debug_access+all +define+ALL | tee sim.log \


lint:
	spyglass -tcl  Spyglass.tcl &


clean:
	rm -rf *.history *.log *.fsdb; \
	rm -rf simv* novas*; \
	rm -rf csrc ucli.key vc_hdrs.h BSSLib.lib++; \
	rm -rf nWaveLog verdiLog; \
	rm -rf spyglass-1 build; \

