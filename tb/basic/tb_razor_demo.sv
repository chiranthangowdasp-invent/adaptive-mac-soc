module tb_razor_demo;
  logic       clk = 0, rst_n = 0;
  logic [7:0] d = 0;
  logic       inject = 0;
  logic [7:0] q_main, q_shadow;
  logic       err;

  razor_reg #(.W(8)) dut (.*);

  always #5 clk = ~clk;

  always @(posedge clk) begin
    #1;
    $display("t=%0d | d=%0d inject=%b | main=%0d shadow=%0d | err=%b",
             $time, d, inject, q_main, q_shadow, err);
  end

  task automatic apply(input logic [7:0] dv, input logic inj);
    @(negedge clk);
    d = dv; inject = inj;
  endtask

  initial begin
    $dumpfile("dump_razor.vcd");
    $dumpvars(0, tb_razor_demo);
    repeat (2) @(negedge clk);
    rst_n = 1;
    apply(5,  0);   // t=30
    apply(9,  1);   // t=40
    apply(9,  0);   // t=50
    apply(9,  1);   // t=60
    apply(20, 1);   // t=70
    apply(20, 0);   // t=80
    repeat (3) @(negedge clk);
    $finish;
  end
endmodule
