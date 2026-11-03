module tb_mac_pipe;
  localparam int DATA_W = 8;
  localparam int ACC_W  = 24;

  logic              clk = 0, rst_n = 0;
  logic              in_valid = 0, in_clear = 0, in_ready, out_valid;
  logic [DATA_W-1:0] in_a = 0, in_b = 0;
  logic [ACC_W-1:0]  out_result;

  mac_pipe #(.DATA_W(DATA_W), .ACC_W(ACC_W)) dut (.*);

  always #5 clk = ~clk;

  // ---------------- golden model ----------------
  logic [ACC_W-1:0] gold_acc = 0;
  logic [ACC_W-1:0] exp_q [$];
  logic [ACC_W-1:0] exp_val;
  int errors = 0, checked = 0, sent = 0;

  function automatic logic [ACC_W-1:0] gold_step(
      input logic [ACC_W-1:0]  acc,
      input logic [DATA_W-1:0] a,
      input logic [DATA_W-1:0] b,
      input logic              clr);
    logic [ACC_W:0] s;
    s = {1'b0, (clr ? {ACC_W{1'b0}} : acc)} + (a * b);
    return s[ACC_W] ? {ACC_W{1'b1}} : s[ACC_W-1:0];
  endfunction

  // ---------------- stimulus helpers ----------------
  task automatic drive(input logic [DATA_W-1:0] a,
                       input logic [DATA_W-1:0] b,
                       input logic              clr);
    @(negedge clk);
    in_valid = 1; in_a = a; in_b = b; in_clear = clr;
    gold_acc = gold_step(gold_acc, a, b, clr);
    exp_q.push_back(gold_acc);
    sent++;
  endtask

  task automatic idle(input int n);
    repeat (n) begin
      @(negedge clk);
      in_valid = 0; in_clear = 0;
    end
  endtask

  // ---------------- checker ----------------
  always @(negedge clk) begin
    if (rst_n && out_valid) begin
      if (exp_q.size() == 0) begin
        $error("out_valid with nothing expected");
        errors++;
      end else begin
        exp_val = exp_q.pop_front();
        checked++;
        if (out_result !== exp_val) begin
          $error("MISMATCH got=%0d exp=%0d @%0t", out_result, exp_val, $time);
          errors++;
        end
      end
    end
  end

  // ---------------- test sequence ----------------
  initial begin
    $dumpfile("dump_mac.vcd");
    $dumpvars(0, tb_mac_pipe);

    repeat (3) @(negedge clk);
    rst_n = 1;

    // directed
    drive(8'd3,   8'd4,   1'b1);   // clear -> 12
    drive(8'd10,  8'd10,  1'b0);   // 112
    drive(8'd255, 8'd255, 1'b0);   // 65137
    idle(2);
    drive(8'd0,   8'd200, 1'b0);   // unchanged value, still accumulated
    drive(8'd1,   8'd1,   1'b1);   // clear -> 1
    idle(3);

    // saturation: 300 * 65025 > 2^24
    repeat (300) drive(8'd255, 8'd255, 1'b0);
    idle(4);
    $display("after saturation phase, gold_acc = %h (expect ffffff)", gold_acc);

    // constrained random with occasional clears and gaps
    repeat (2000) begin
      drive($urandom_range(0,255), $urandom_range(0,255),
            ($urandom_range(0,15) == 0));
      if ($urandom_range(0,3) == 0) idle($urandom_range(1,3));
    end
    idle(6);

    if (errors == 0 && checked == sent && exp_q.size() == 0)
      $display("PASS: %0d operations checked, 0 errors", checked);
    else
      $display("FAIL: errors=%0d checked=%0d sent=%0d pending=%0d",
               errors, checked, sent, exp_q.size());
    $finish;
  end
endmodule
