module tb_top_smoke;
  import adaptive_pkg::*;

  logic clk = 0, rst_n = 0;
  logic in_valid = 0, in_clear = 0, ext_err_in = 0;
  logic [7:0] in_a = 0, in_b = 0;
  logic in_ready, out_valid;
  logic [23:0] out_result;
  logic [15:0] cfg_err_thresh = 16'd4, cfg_window = 16'd256;
  logic cfg_force_en = 0;
  logic [2:0] cfg_force_mode = 0, stat_mode;
  logic [15:0] stat_err_count, stat_replay_count;

  adaptive_mac_top dut (.*);

  always #5 clk = ~clk;

  initial begin
    $dumpfile("dump.vcd");
    $dumpvars(0, tb_top_smoke);
    #22 rst_n = 1;
    repeat (3) @(posedge clk);
    if (stat_mode === MODE_NORMAL) $display("PASS: top skeleton resets to NORMAL");
    else                           $error("FAIL: stat_mode=%0d", stat_mode);
    $finish;
  end
endmodule
