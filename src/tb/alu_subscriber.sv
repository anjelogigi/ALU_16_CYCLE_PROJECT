class alu_subscriber extends uvm_subscriber #(trans);
  `uvm_component_utils(alu_subscriber)

  trans t;

  covergroup alu_cg;
    option.per_instance = 1;

    cp_mode: coverpoint t.mode {
      bins arithmetic      = {1'b1};
      bins logical_shift   = {1'b0};
    }

    cp_cmd: coverpoint t.cmd {
      bins basic_ops[]     = {[4'h0 : 4'h3]}; 
      bins inc_dec[]       = {[4'h4 : 4'h7]}; 
      bins cmp_shift[]     = {[4'h8 : 4'hB]}; 
      bins rotate[]        = {[4'hC : 4'hD]}; 
      ignore_bins reserved = {[4'hE : 4'hF]};
    }

    cp_inp_valid: coverpoint t.inp_valid {
      bins idle            = {2'b00};
      bins only_a          = {2'b01};
      bins only_b          = {2'b10};
      bins both_ab         = {2'b11};
    }

    cp_cin: coverpoint t.cin {
      bins low  = {1'b0};
      bins high = {1'b1};
    }

    cp_ce: coverpoint t.ce {
      bins enabled         = {1'b1};
      ignore_bins disabled = {1'b0};
    }

    cross_mode_cmd: cross cp_mode, cp_cmd {
      ignore_bins invalid_arith_rotates = binsof(cp_mode.arithmetic) && 
                                          (binsof(cp_cmd.rotate) || binsof(cp_cmd.cmp_shift));
    }

    cross_handshake_cmd: cross cp_inp_valid, cp_cmd {
      ignore_bins ignore_idle = binsof(cp_inp_valid.idle);
    }

  endgroup

  function new(string name = "alu_subscriber", uvm_component parent);
    super.new(name, parent);
    alu_cg = new();
  endfunction

  virtual function void write(trans t);
    this.t = t;
    alu_cg.sample(); 
  endfunction

  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("Functional Coverage = %0.2f%%", alu_cg.get_inst_coverage()), UVM_LOW)
  endfunction

endclass
