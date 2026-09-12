# asic-flow-lab — AES-128 open-source ASIC flow
IVERILOG ?= iverilog
VVP      ?= vvp

RTL = rtl/aes_core.v rtl/aes_mmio.v rtl/cryptocore_top.v rtl/aes_asic_top.v
OPENLANE_TOP ?= aes_asic_top

.PHONY: test lint sim wave clean

test: sim/tb_aes.vvp
	cd sim && $(VVP) tb_aes.vvp

sim/tb_aes.vvp: rtl/aes_core.v rtl/aes_mmio.v rtl/cryptocore_top.v tb/tb_aes.v
	@mkdir -p sim 2>/dev/null || mkdir sim 2>NUL || exit 0
	$(IVERILOG) -g2001 -o sim/tb_aes.vvp rtl/aes_core.v rtl/aes_mmio.v rtl/cryptocore_top.v tb/tb_aes.v

lint:
	verilator --lint-only -Wall --top-module $(OPENLANE_TOP) $(RTL) || true

sim: test

wave: test
	@echo "GTKWave: gtkwave sim/tb_aes.vcd"

clean:
	rm -rf sim/*.vvp sim/*.vcd 2>/dev/null || powershell -NoProfile -Command "Remove-Item -Force sim\*.vvp,sim\*.vcd -ErrorAction SilentlyContinue"
