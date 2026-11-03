.RECIPEPREFIX := >

PKG  := rtl/common/adaptive_pkg.sv
RTL  := $(PKG) $(filter-out $(PKG),$(wildcard rtl/*/*.sv))
TB   ?= tb/basic/tb_top_smoke.sv
TOPM ?= tb_top_smoke

lint:
> verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
>   --top-module adaptive_mac_top $(RTL)

sim:
> iverilog -g2012 -o sim.out -s $(TOPM) $(RTL) $(TB)
> vvp sim.out

wave:
> gtkwave dump.vcd &

clean:
> rm -f sim.out dump.vcd
