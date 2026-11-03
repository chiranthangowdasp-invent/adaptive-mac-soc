module mac_pipe_rc #(
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

  input  logic               inject_fault,
  output logic               timing_err
);
  localparam int PROD_W = 2 * DATA_W;

  logic              s1_valid, s1_clr;
  logic [DATA_W-1:0] s1_a, s1_b;

  logic              s2_valid, s2_clr;
  logic [PROD_W-1:0] prod_d, s2_prod, s2_prod_shadow;
  logic              s2_err_raw;

  logic [ACC_W-1:0]  acc_q, acc_base;
  logic [ACC_W:0]    sum;

  logic stall;                                  // 1 = replay cycle
  assign stall      = s2_err_raw & s2_valid;
  assign timing_err = stall;
  assign in_ready   = ~stall;

  // Stage 1: holds during a stall
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s1_valid <= 1'b0;  s1_clr <= 1'b0;
      s1_a     <= '0;    s1_b   <= '0;
    end else if (!stall) begin
      s1_valid <= in_valid;
      s1_clr   <= in_valid & in_clear;
      if (in_valid) begin
        s1_a <= in_a;
        s1_b <= in_b;
      end
    end
  end

  // Stage 2: multiplier + Razor register, flags hold during a stall
  assign prod_d = s1_a * s1_b;

  razor_reg_rc #(.W(PROD_W)) u_razor_prod (
    .clk      (clk),
    .rst_n    (rst_n),
    .d        (prod_d),
    .inject   (inject_fault & s1_valid),
    .restore  (stall),
    .q_main   (s2_prod),
    .q_shadow (s2_prod_shadow),
    .err      (s2_err_raw)
  );

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s2_valid <= 1'b0;
      s2_clr   <= 1'b0;
    end else if (!stall) begin
      s2_valid <= s1_valid;
      s2_clr   <= s1_clr;
    end
  end

  // Stage 3: no accumulate and no output during a stall
  always_comb begin
    acc_base = s2_clr ? '0 : acc_q;
    sum      = {1'b0, acc_base} + {{(ACC_W+1-PROD_W){1'b0}}, s2_prod};
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      acc_q     <= '0;
      out_valid <= 1'b0;
    end else begin
      out_valid <= s2_valid & ~stall;
      if (s2_valid & ~stall)
        acc_q <= sum[ACC_W] ? {ACC_W{1'b1}} : sum[ACC_W-1:0];
    end
  end

  assign out_result = acc_q;
endmodule
