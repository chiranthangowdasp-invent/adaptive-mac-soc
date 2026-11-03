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

sim_mac:
> iverilog -g2012 -o sim_mac.out -s tb_mac_pipe $(RTL) tb/basic/tb_mac_pipe.sv
> vvp sim_mac.out

MSG ?= update
save:
> git add -A
> git commit -m "$(MSG)" || true
> git push

sim_demo:
> iverilog -g2012 -o sim_demo.out -s tb_mac_demo $(RTL) tb/basic/tb_mac_demo.sv
> vvp sim_demo.out

wave_demo:
> gtkwave dump_demo.vcd $(wildcard mac_demo.gtkw) &

sim_razor:
> iverilog -g2012 -o sim_razor.out -s tb_razor_demo $(RTL) tb/basic/tb_razor_demo.sv
> vvp sim_razor.out

sim_razor_mac:
> iverilog -g2012 -o sim_razor_mac.out -s tb_mac_razor_demo $(RTL) tb/basic/tb_mac_razor_demo.sv
> vvp sim_razor_mac.out

lint_razor:
> verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
>   --top-module mac_pipe_razor $(RTL)

sim_rc:
> iverilog -g2012 -o sim_rc.out -s tb_mac_rc_demo $(RTL) tb/basic/tb_mac_rc_demo.sv
> vvp sim_rc.out

lint_rc:
> verilator --lint-only -Wall -Wno-DECLFILENAME -Wno-UNUSEDSIGNAL \
>   --top-module mac_pipe_rc $(RTL)
