module tb_mac_rc_demo;
  logic        clk = 0, rst_n = 0;
  logic        in_valid = 0, in_clear = 0, in_ready, out_valid;
  logic [7:0]  in_a = 0, in_b = 0;
  logic [23:0] out_result;
  logic        inject_fault = 0, timing_err;

  mac_pipe_rc dut (.*);

  always #5 clk = ~clk;

  always @(posedge clk) begin
    #1;
    $display("t=%0d | inj=%b rdy=%b | main=%0d shadow=%0d err=%b | acc=%0d out_valid=%b",
             $time, inject_fault, in_ready,
             dut.s2_prod, dut.s2_prod_shadow, timing_err,
             out_result, out_valid);
  end

  initial begin
    $dumpfile("dump_mac_rc.vcd");
    $dumpvars(0, tb_mac_rc_demo);

    repeat (2) @(negedge clk);
    rst_n = 1;                                   // t=20

    @(negedge clk);                              // t=30: operation 1 (3 x 4, clear)
    in_valid = 1; in_a = 3;  in_b = 4;  in_clear = 1;

    @(negedge clk);                              // t=40: operation 2 (10 x 10)
    in_a = 10; in_b = 10; in_clear = 0;

    @(negedge clk);                              // t=50: stop sending, fake a late multiply
    in_valid = 0;
    inject_fault = 1;

    @(negedge clk);                              // t=60: back to normal
    inject_fault = 0;

    repeat (6) @(negedge clk);

    if (out_result === 24'd112) $display("PASS: replay restored the correct result (112)");
    else                        $display("FAIL: result=%0d, expected 112", out_result);
    $finish;
  end
endmodule
