`timescale 1ns/1ps
`include "defines.svh"

module top;

  import uvm_pkg::*;
  import test_pkg::*;

  bit clk;

  initial clk = 0;
  always #5 clk = ~clk;

  alu_if vif(clk);

  ALU_DESIGN #(
    .DW(`DW),
    .CW(`CW)
  ) DUT (
    .CLK(clk),
    .RST(vif.rst),
    .CE(vif.ce),
    .MODE(vif.mode),
    .CIN(vif.cin),
    .CMD(vif.cmd),
    .INP_VALID(vif.inp_valid),
    .OPA(vif.OA),
    .OPB(vif.OB),
    .RES(vif.res),
    .COUT(vif.cout),
    .OFLOW(vif.oflow),
    .G(vif.G),
    .E(vif.E),
    .L(vif.L),
    .ERR(vif.err)
  );

  initial begin
    vif.rst = 1;
    repeat (2) @(posedge clk);
    vif.rst = 0;
  end

  initial begin
    uvm_config_db#(virtual alu_if)::set(null, "*", "alu_if", vif);
    run_test("test1");
  end

endmodule
