`include "defines.svh"

class trans extends uvm_sequence_item;
  `uvm_object_utils(trans)

  rand bit [`DW-1:0] OA;
  rand bit [`DW-1:0] OB;
  rand bit [1:0] inp_valid;
  rand bit [`CW-1:0] cmd;
  rand bit mode;
  rand bit cin;
  rand bit ce;
  bit rst;
  logic [`DW*2-1:0] res;
  bit err;
  bit oflow;
  bit cout;
  logic G;
  logic E;
  logic L;

  constraint c_ce {
    ce dist {1 := 95, 0 := 5};
  }

  constraint c_oa {
    OA inside {[0:(2**`DW)-1]};
  }

  constraint c_ob {
    OB inside {[0:(2**`DW)-1]};
  }

  constraint c_inp_valid {
    inp_valid dist {
      2'b00 := 5,
      2'b01 := 20,
      2'b10 := 20,
      2'b11 := 55
    };
  }

  constraint c_mode {
    mode dist {1 := 50, 0 := 50};
  }

  constraint c_cmd {
    if (mode)
      cmd inside {[4'h0:4'hA]};
    else
      cmd inside {[4'h0:4'hD]};
  }

  constraint c_cin {
    cin dist {0 := 50, 1 := 50};
  }

  function new(string name = "trans");
    super.new(name);
  endfunction

endclass
