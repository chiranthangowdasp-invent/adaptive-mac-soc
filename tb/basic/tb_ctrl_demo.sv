module tb_ctrl_demo;
  import adaptive_pkg::*;

  logic        clk = 0, rst_n = 0;
  logic        err_event = 0, activity = 0;
  logic [15:0] cfg_err_thresh = 16'd3, cfg_window = 16'd8;
  logic        cfg_force_en = 0;
  logic [2:0]  cfg_force_mode = 0, stat_mode;
  logic [15:0] stat_err_count, stat_replay_count;
  logic        throttle_en, clk_en;

  adaptive_ctrl dut (.*);

  always #5 clk = ~clk;

  logic [2:0] prev = 3'bxxx;
  logic [4:0] seen = 5'b0;

  // print only when the mode changes
  always @(posedge clk) begin
    #1;
    if (stat_mode !== prev) begin
      $display("t=%0d mode=%0d | err_cnt=%0d win=%0d | throttle=%b clk_en=%b | total_err=%0d replays=%0d",
               $time, stat_mode, dut.err_cnt, dut.win_cnt,
               throttle_en, clk_en, stat_err_count, stat_replay_count);
      prev = stat_mode;
    end
    if (stat_mode < 5) seen[stat_mode] = 1'b1;
  end

  task automatic cyc(input int n);
    repeat (n) @(negedge clk);
  endtask

  task automatic err_pulse();
    @(negedge clk) err_event = 1;
    @(negedge clk) err_event = 0;
  endtask

  initial begin
    $dumpfile("dump_ctrl.vcd");
    $dumpvars(0, tb_ctrl_demo);

    repeat (2) @(negedge clk);
    rst_n = 1; activity = 1;
    cyc(5);                                   // busy, no errors: stay NORMAL

    $display("--- one isolated error ---");
    err_pulse();
    cyc(12);

    $display("--- burst of 3 errors ---");
    err_pulse(); err_pulse(); err_pulse();
    cyc(30);

    $display("--- no work arrives ---");
    activity = 0;
    cyc(25);

    $display("--- work returns ---");
    activity = 1;
    cyc(4);

    if (seen == 5'b11111 && stat_mode == MODE_NORMAL &&
        stat_err_count == 4 && stat_replay_count == 4)
      $display("PASS: all 5 modes visited, 4 errors, 4 replays, back in NORMAL");
    else
      $display("FAIL: seen=%b mode=%0d err=%0d replays=%0d",
               seen, stat_mode, stat_err_count, stat_replay_count);
    $finish;
  end
endmodule
