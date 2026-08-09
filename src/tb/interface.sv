`timescale 1ns/1ps

interface alu_if(input bit clk);

  logic rst;
  logic [7:0] OA;
  logic [7:0] OB;
  logic [1:0] inp_valid;
  logic [3:0] cmd;
  logic [15:0] res;
  logic mode;
  logic ce;
  logic cin;
  logic err;
  logic oflow;
  logic cout;
  logic G;
  logic E;
  logic L;

  clocking inp_dr_cb @(posedge clk);
    default input #1 output #1;
    output OA;
    output OB;
    output inp_valid;
    output cmd;
    output mode;
    output ce;
    output cin;
  endclocking

  clocking inp_mon_cb @(posedge clk);
    default input #1 output #1;
    input rst;
    input OA;
    input OB;
    input inp_valid;
    input cmd;
    input mode;
    input ce;
    input cin;
  endclocking

  clocking out_mon_cb @(posedge clk);
    default input #1 output #1;
    input rst;
    input OA;
    input OB;
    input inp_valid;
    input cmd;
    input mode;
    input ce;
    input cin;
    input res;
    input err;
    input oflow;
    input cout;
    input G;
    input E;
    input L;
  endclocking

  modport INP_DRV (clocking inp_dr_cb);
  modport INP_MON (clocking inp_mon_cb);
  modport OUT_MON (clocking out_mon_cb);

endinterface
