module razor_reg #(
  parameter int W = 16
) (
  input  logic         clk,
  input  logic         rst_n,
  input  logic [W-1:0] d,         // the value the logic SHOULD deliver
  input  logic         inject,    // 1 = pretend the path was too slow this cycle
  output logic [W-1:0] q_main,    // the normal flop (can be fooled)
  output logic [W-1:0] q_shadow,  // the shadow flop (always right)
  output logic         err        // 1 when the two disagree
);
  // Main flop: when inject=1 it misses the new value and keeps its OLD one
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n)       q_main <= '0;
    else if (!inject) q_main <= d;

  // Shadow flop: always captures the correct value
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) q_shadow <= '0;
    else        q_shadow <= d;

  // Error flag: the two copies disagree
  assign err = (q_main != q_shadow);
endmodule
