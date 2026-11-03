module mac_pipe_razor #(
  parameter int DATA_W = adaptive_pkg::DATA_W,
  parameter int ACC_W  = adaptive_pkg::ACC_W
) (
  input  logic               clk,
  input  logic               rst_n,

  input  logic               in_valid,
  output logic               in_ready,
  input  logic [DATA_W-1:0]  in_a,
  input  logic [DATA_W-1:0]  in_b,
  input  logic               in_clear,

  output logic               out_valid,
  output logic [ACC_W-1:0]   out_result,

  input  logic               inject_fault,   // simulation hook: "multiplier too slow now"
  output logic               timing_err      // Razor flag for a valid operation
);
  localparam int PROD_W = 2 * DATA_W;

  // Stage 1: unchanged
  logic              s1_valid, s1_clr;
  logic [DATA_W-1:0] s1_a, s1_b;

  // Stage 2: product register is now a Razor register
  logic              s2_valid, s2_clr;
  logic [PROD_W-1:0] prod_d;             // multiplier output (before the register)
  logic [PROD_W-1:0] s2_prod;            // main flop (can be fooled)
  logic [PROD_W-1:0] s2_prod_shadow;     // shadow flop (always right)
  logic              s2_err_raw;

  // Stage 3: unchanged
  logic [ACC_W-1:0]  acc_q, acc_base;
  logic [ACC_W:0]    sum;

  assign in_ready = 1'b1;

  // Stage 1
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1_valid <= 1'b0;
      s1_clr   <= 1'b0;
      s1_a     <= '0;
      s1_b     <= '0;
    end else begin
      s1_valid <= in_valid;
      s1_clr   <= in_valid & in_clear;
      if (in_valid) begin
        s1_a <= in_a;
        s1_b <= in_b;
      end
    end
  end

  // Stage 2
  assign prod_d = s1_a * s1_b;

  razor_reg #(.W(PROD_W)) u_razor_prod (
    .clk      (clk),
    .rst_n    (rst_n),
    .d        (prod_d),
    .inject   (inject_fault & s1_valid),   // a late path only matters for real data
    .q_main   (s2_prod),
    .q_shadow (s2_prod_shadow),
    .err      (s2_err_raw)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s2_valid <= 1'b0;
      s2_clr   <= 1'b0;
    end else begin
      s2_valid <= s1_valid;
      s2_clr   <= s1_clr;
    end
  end

  assign timing_err = s2_err_raw & s2_valid;

  // Stage 3: unchanged
  always_comb begin
    acc_base = s2_clr ? '0 : acc_q;
    sum      = {1'b0, acc_base} + {{(ACC_W+1-PROD_W){1'b0}}, s2_prod};
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_q     <= '0;
      out_valid <= 1'b0;
    end else begin
      out_valid <= s2_valid;
      if (s2_valid)
        acc_q <= sum[ACC_W] ? {ACC_W{1'b1}} : sum[ACC_W-1:0];
    end
  end

  assign out_result = acc_q;
endmodule
