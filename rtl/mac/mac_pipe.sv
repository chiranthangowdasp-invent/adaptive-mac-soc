module mac_pipe #(
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
  output logic [ACC_W-1:0]   out_result
);
  localparam int PROD_W = 2 * DATA_W;

  // Stage 1: operand registers
  logic              s1_valid, s1_clr;
  logic [DATA_W-1:0] s1_a, s1_b;

  // Stage 2: product register
  logic              s2_valid, s2_clr;
  logic [PROD_W-1:0] s2_prod;

  // Stage 3: accumulator
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
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      s2_valid <= 1'b0;
      s2_clr   <= 1'b0;
      s2_prod  <= '0;
    end else begin
      s2_valid <= s1_valid;
      s2_clr   <= s1_clr;
      if (s1_valid) s2_prod <= s1_a * s1_b;
    end
  end

  // Stage 3: add with one extra carry bit, then saturate
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
