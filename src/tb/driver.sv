`include "defines.svh"

class input_driver extends uvm_driver #(trans);

  `uvm_component_utils(input_driver)

  virtual alu_if.INP_DRV vif;
  alu_config m_cfg;

  function new(string name = "input_driver", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    if (!uvm_config_db#(alu_config)::get(this, "", "alu_config", m_cfg))
      `uvm_fatal(get_type_name(), "Failed to get alu_config")

  endfunction

  function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);

    vif = m_cfg.vif;

  endfunction

  task run_phase(uvm_phase phase);

    vif.inp_dr_cb.ce        <= 0;
    vif.inp_dr_cb.mode      <= 0;
    vif.inp_dr_cb.cin       <= 0;
    vif.inp_dr_cb.cmd       <= '0;
    vif.inp_dr_cb.inp_valid <= '0;
    vif.inp_dr_cb.OA        <= '0;
    vif.inp_dr_cb.OB        <= '0;

    forever begin

      seq_item_port.get_next_item(req);

      drive(req);

      seq_item_port.item_done();

    end

  endtask

  task drive(trans data2duv);

    `uvm_info("INPUT_DRIVER",
              $sformatf("Driving Transaction\n%s", data2duv.sprint()),
              UVM_LOW)

    @(vif.inp_dr_cb);

    vif.inp_dr_cb.ce        <= data2duv.ce;
    vif.inp_dr_cb.mode      <= data2duv.mode;
    vif.inp_dr_cb.cin       <= data2duv.cin;
    vif.inp_dr_cb.cmd       <= data2duv.cmd;
    vif.inp_dr_cb.inp_valid <= data2duv.inp_valid;
    vif.inp_dr_cb.OA        <= data2duv.OA;
    vif.inp_dr_cb.OB        <= data2duv.OB;

  endtask

endclass
