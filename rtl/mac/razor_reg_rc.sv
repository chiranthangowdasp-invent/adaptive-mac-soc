module razor_reg_rc #(
  parameter int W = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [W-1:0] d,
  input  logic         inject,    // simulation hook: new value arrives too late
  input  logic         restore,   // 1 = replay cycle
  output logic [W-1:0] q_main,
  output logic [W-1:0] q_shadow,
  output logic         err
);
  // Main flop: restore has priority, then the (fakeable) normal capture
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)       q_main <= '0;
    else if (restore) q_main <= q_shadow;   // copy the correct value back
    else if (!inject) q_main <= d;

  // Shadow flop: normally always captures; HOLDS during restore
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)        q_shadow <= '0;
    else if (!restore) q_shadow <= d;

  assign err = (q_main != q_shadow);
endmodule
