module adaptive_mac_top #(
  parameter int DATA_W = adaptive_pkg::DATA_W,
  parameter int ACC_W  = adaptive_pkg::ACC_W,
  parameter int CNT_W  = adaptive_pkg::CNT_W
) (
  input  logic               clk,
  input  logic               rst_n,

  // MAC stream
  input  logic               in_valid,
  output logic               in_ready,
  input  logic [DATA_W-1:0]  in_a,
  input  logic [DATA_W-1:0]  in_b,
  input  logic               in_clear,
  output logic               out_valid,
  output logic [ACC_W-1:0]   out_result,

  // Config (future APB CSRs)
  input  logic [CNT_W-1:0]   cfg_err_thresh,
  input  logic [CNT_W-1:0]   cfg_window,
  input  logic               cfg_force_en,
  input  logic [2:0]         cfg_force_mode,

  // Status (future APB CSRs)
  output logic [2:0]         stat_mode,
  output logic [CNT_W-1:0]   stat_err_count,
  output logic [CNT_W-1:0]   stat_replay_count,

  // Extension hook (SRAM ECC / MBIST in Tier 2)
  input  logic               ext_err_in
);
  import adaptive_pkg::*;

  mode_e mode_q;

  mac_pipe #(.DATA_W(DATA_W), .ACC_W(ACC_W)) u_mac (
    .clk       (clk),
    .rst_n     (rst_n),
    .in_valid  (in_valid),
    .in_ready  (in_ready),
    .in_a      (in_a),
    .in_b      (in_b),
    .in_clear  (in_clear),
    .out_valid (out_valid),
    .out_result(out_result)
  );

  // Still stubs: controller arrives in Steps 3-4
  assign stat_err_count    = '0;
  assign stat_replay_count = '0;
  assign stat_mode         = mode_q;

  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) mode_q <= MODE_NORMAL;
    else        mode_q <= mode_q;
endmodule
