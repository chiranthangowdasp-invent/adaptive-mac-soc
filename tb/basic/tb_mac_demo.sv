module tb_mac_demo;
  logic        clk = 0, rst_n = 0;
  logic        in_valid = 0, in_clear = 0, in_ready, out_valid;
  logic [7:0]  in_a = 0, in_b = 0;
  logic [23:0] out_result;

  mac_pipe dut (.*);

  always #5 clk = ~clk;          // rising edges at t = 5, 15, 25, 35 ...

  // after every rising edge, wait 1 unit so registers have updated, then print
  always @(posedge clk) begin
    #1;
    $display("t=%0d | in: v=%b a=%0d b=%0d clr=%b | s1: v=%b a=%0d b=%0d | s2: v=%b prod=%0d | acc=%0d out_valid=%b",
             $time, in_valid, in_a, in_b, in_clear,
             dut.s1_valid, dut.s1_a, dut.s1_b,
             dut.s2_valid, dut.s2_prod,
             out_result, out_valid);
  end

  initial begin
    $dumpfile("dump_demo.vcd");
    $dumpvars(0, tb_mac_demo);

    repeat (2) @(negedge clk);
    rst_n = 1;                                   // release reset at t=20

    @(negedge clk);                              // t=30: operation 1 (3 x 4, start fresh)
    in_valid = 1; in_a = 3;  in_b = 4;  in_clear = 1;

    @(negedge clk);                              // t=40: operation 2 (10 x 10, add on)
    in_a = 10; in_b = 10; in_clear = 0;

    @(negedge clk);                              // t=50: stop sending
    in_valid = 0;

    repeat (6) @(negedge clk);
    $finish;
  end
endmodule
