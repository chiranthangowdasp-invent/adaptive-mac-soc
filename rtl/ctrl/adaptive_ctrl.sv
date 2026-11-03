module adaptive_ctrl #(
  parameter int               CNT_W      = adaptive_pkg::CNT_W,
  parameter logic [CNT_W-1:0] IDLE_LIMIT = 16
) (
  input  logic             clk,
  input  logic             rst_n,

  input  logic             err_event,       // an error was seen this cycle
  input  logic             activity,        // work is arriving

  input  logic [CNT_W-1:0] cfg_err_thresh,
  input  logic [CNT_W-1:0] cfg_window,
  input  logic             cfg_force_en,
  input  logic [2:0]       cfg_force_mode,

  output logic [2:0]       stat_mode,
  output logic [CNT_W-1:0] stat_err_count,
  output logic [CNT_W-1:0] stat_replay_count,

  output logic             throttle_en,     // 1 = run at half rate
  output logic             clk_en           // 0 = clock gated
);
  import adaptive_pkg::*;

  mode_e            mode_q, mode_d;
  logic [CNT_W-1:0] win_cnt, err_cnt, idle_cnt;
  logic [CNT_W:0]   win_next;
  logic             window_end;
  logic [2:0]       eff_mode;

  // Window: ends after cfg_window cycles
  assign win_next   = {1'b0, win_cnt} + 1;
  assign window_end = (win_next >= {1'b0, cfg_window});

  // ---- Next-state logic (pure combinational) ----
  always_comb begin
    mode_d = mode_q;
    case (mode_q)
      MODE_NORMAL: begin
        if (err_event)                 mode_d = MODE_RECOVER;
        else if (idle_cnt >= IDLE_LIMIT) mode_d = MODE_LOW_POWER;
      end
      MODE_RECOVER: mode_d = MODE_MONITOR;
      MODE_MONITOR: begin
        if (err_cnt >= cfg_err_thresh) mode_d = MODE_THROTTLE;
        else if (err_event)            mode_d = MODE_RECOVER;
        else if (window_end)           mode_d = MODE_NORMAL;
      end
      MODE_THROTTLE: begin
        if (window_end && err_cnt == 0) mode_d = MODE_MONITOR;
      end
      MODE_LOW_POWER: begin
        if (activity) mode_d = MODE_NORMAL;
      end
      default: mode_d = MODE_NORMAL;
    endcase
  end

  // ---- State register ----
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) mode_q <= MODE_NORMAL;
    else        mode_q <= mode_d;

  // ---- Counters ----
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      win_cnt           <= '0;
      err_cnt           <= '0;
      idle_cnt          <= '0;
      stat_err_count    <= '0;
      stat_replay_count <= '0;
    end else begin
      // idle counter (saturating)
      if (activity)                        idle_cnt <= '0;
      else if (idle_cnt != {CNT_W{1'b1}})  idle_cnt <= idle_cnt + 1;

      // lifetime statistics (saturating)
      if (err_event && stat_err_count != {CNT_W{1'b1}})
        stat_err_count <= stat_err_count + 1;
      if (mode_d == MODE_RECOVER && mode_q != MODE_RECOVER &&
          stat_replay_count != {CNT_W{1'b1}})
        stat_replay_count <= stat_replay_count + 1;

      // window counters
      if (mode_q == MODE_NORMAL || mode_q == MODE_LOW_POWER) begin
        win_cnt <= '0;                                   // the first error opens a window
        err_cnt <= {{(CNT_W-1){1'b0}}, err_event};
      end else if (mode_d == MODE_THROTTLE && mode_q != MODE_THROTTLE) begin
        win_cnt <= '0;                                   // fresh window on entering throttle
        err_cnt <= '0;
      end else if (window_end) begin
        win_cnt <= '0;                                   // window finished: start the next
        err_cnt <= {{(CNT_W-1){1'b0}}, err_event};
      end else begin
        win_cnt <= win_next[CNT_W-1:0];
        if (err_event && err_cnt != {CNT_W{1'b1}})
          err_cnt <= err_cnt + 1;
      end
    end
  end

  // ---- Outputs (manual override wins over the FSM) ----
  assign eff_mode    = cfg_force_en ? cfg_force_mode : mode_q;
  assign stat_mode   = eff_mode;
  assign throttle_en = (eff_mode == MODE_THROTTLE);
  assign clk_en      = (eff_mode != MODE_LOW_POWER);
endmodule
