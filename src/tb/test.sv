class test extends uvm_test;
  `uvm_component_utils(test)

  env env_h;
  alu_config m_cfg;

  function new(string name = "test", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);

    m_cfg = alu_config::type_id::create("m_cfg");

    if (!uvm_config_db#(virtual alu_if)::get(this, "", "alu_if", m_cfg.vif))
      `uvm_fatal(get_type_name(), "Can't get the interface")

    m_cfg.input_agent_is_active  = UVM_ACTIVE;
    m_cfg.output_agent_is_active = UVM_PASSIVE;

    uvm_config_db#(alu_config)::set(this, "*", "alu_config", m_cfg);

    env_h = env::type_id::create("env_h", this);
  endfunction

  function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction

endclass

class test1 extends test;
  `uvm_component_utils(test1)

  alu_simple_seq simple_s; 
  add_seq add_s;
  sub_seq sub_s;
  add_cin_seq add_cin_s;
  sub_cin_seq sub_cin_s;
  inc_dec_seq inc_dec_s;
  cmp_seq cmp_s;
  mul_inc_seq mul_inc_s;
  mul_shl_seq mul_shl_s;
  and_seq and_s;
  nand_seq nand_s;
  or_seq or_s;
  nor_seq nor_s;
  xor_seq xor_s;
  xnor_seq xnor_s;
  not_a_seq not_a_s;
  not_b_seq not_b_s;
  shr1_a_seq shr1_a_s;
  shl1_a_seq shl1_a_s;
  shr1_b_seq shr1_b_s;
  shl1_b_seq shl1_b_s;
  rol_seq rol_s;
  ror_seq ror_s;

  add_wait_seq add_wait_s;

  mul_9_wait_seq mul_9_wait_s;

  timeout_error_seq timeout_error_s;

  late_operand_b_seq late_operand_b_s;
  latest_operand_a_seq latest_operand_a_s;

  alu_master_comprehensive_seq master_seq;

  function new(string name = "test1", uvm_component parent);
    super.new(name, parent);
  endfunction

  task run_phase(uvm_phase phase);
    phase.raise_objection(this);

    master_seq = alu_master_comprehensive_seq::type_id::create("master_seq");
    `uvm_info(get_type_name(), "Starting ALU Master Comprehensive Sequence (Phase 1 & Phase 2)...", UVM_LOW)
    master_seq.start(env_h.inp_agt_h.seqr_h);


    /*latest_operand_a_s = latest_operand_a_seq::type_id::create("latest_operand_a_s");
    latest_operand_a_s.num_txns = 10; 
    `uvm_info(get_type_name(), "Starting Latest Operand A Priority Sequence...", UVM_LOW)
    latest_operand_a_s.start(env_h.inp_agt_h.seqr_h);*/

    /*late_operand_b_s = late_operand_b_seq::type_id::create("late_operand_b_s");
    late_operand_b_s.num_txns = 10; 
    `uvm_info(get_type_name(), "Starting Late Operand B Sequence (>16 cycles gap)...", UVM_LOW)
    late_operand_b_s.start(env_h.inp_agt_h.seqr_h);*/

    /*timeout_error_s = timeout_error_seq::type_id::create("timeout_error_s");
    timeout_error_s.num_txns = 10; 
    `uvm_info(get_type_name(), "Starting Timeout Error Sequence (Operand B missing)...", UVM_LOW)
    timeout_error_s.start(env_h.inp_agt_h.seqr_h);*/

    /*mul_9_wait_s = mul_9_wait_seq::type_id::create("mul_9_wait_s");
    mul_9_wait_s.num_txns = 25; 
    `uvm_info(get_type_name(), "Starting Multiplication CMD 9 Staggered Wait Sequence...", UVM_LOW)
    mul_9_wait_s.start(env_h.inp_agt_h.seqr_h);*/

    /*add_wait_s = add_wait_seq::type_id::create("add_wait_s");
    add_wait_s.num_txns = 20; 
    `uvm_info(get_type_name(), "Starting Staggered ADD Wait Sequence...", UVM_LOW)
    add_wait_s.start(env_h.inp_agt_h.seqr_h);*/

    /*shr1_a_s = shr1_a_seq::type_id::create("shr1_a_s");
    shr1_a_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting SHR1_A Sequence (CMD = 4'h8)...", UVM_LOW)
    shr1_a_s.start(env_h.inp_agt_h.seqr_h);*/

    /*shl1_a_s = shl1_a_seq::type_id::create("shl1_a_s");
    shl1_a_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting SHL1_A Sequence (CMD = 4'h9)...", UVM_LOW)
    shl1_a_s.start(env_h.inp_agt_h.seqr_h);*/

    /*shr1_b_s = shr1_b_seq::type_id::create("shr1_b_s");
    shr1_b_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting SHR1_B Sequence (CMD = 4'hA)...", UVM_LOW)
    shr1_b_s.start(env_h.inp_agt_h.seqr_h);*/

    /*shl1_b_s = shl1_b_seq::type_id::create("shl1_b_s");
    shl1_b_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting SHL1_B Sequence (CMD = 4'hB)...", UVM_LOW)
    shl1_b_s.start(env_h.inp_agt_h.seqr_h);*/

    /*rol_s = rol_seq::type_id::create("rol_s");
    rol_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting ROL_A_B Sequence (CMD = 4'hC)...", UVM_LOW)
    rol_s.start(env_h.inp_agt_h.seqr_h);*/

    /*ror_s = ror_seq::type_id::create("ror_s");
    ror_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting ROR_A_B Sequence (CMD = 4'hD)...", UVM_LOW)
    ror_s.start(env_h.inp_agt_h.seqr_h);*/

    /*and_s = and_seq::type_id::create("and_s");
    and_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting AND Sequence (CMD = 4'h0)...", UVM_LOW)
    and_s.start(env_h.inp_agt_h.seqr_h);*/

    /*nand_s = nand_seq::type_id::create("nand_s");
    nand_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting NAND Sequence (CMD = 4'h1)...", UVM_LOW)
    nand_s.start(env_h.inp_agt_h.seqr_h);*/

    /*or_s = or_seq::type_id::create("or_s");
    or_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting OR Sequence (CMD = 4'h2)...", UVM_LOW)
    or_s.start(env_h.inp_agt_h.seqr_h);*/

    /*nor_s = nor_seq::type_id::create("nor_s");
    nor_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting NOR Sequence (CMD = 4'h3)...", UVM_LOW)
    nor_s.start(env_h.inp_agt_h.seqr_h);*/

    /*xor_s = xor_seq::type_id::create("xor_s");
    xor_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting XOR Sequence (CMD = 4'h4)...", UVM_LOW)
    xor_s.start(env_h.inp_agt_h.seqr_h);*/

    /*xnor_s = xnor_seq::type_id::create("xnor_s");
    xnor_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting XNOR Sequence (CMD = 4'h5)...", UVM_LOW)
    xnor_s.start(env_h.inp_agt_h.seqr_h);*/

    /*not_a_s = not_a_seq::type_id::create("not_a_s");
    not_a_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting NOT_A Sequence (CMD = 4'h6)...", UVM_LOW)
    not_a_s.start(env_h.inp_agt_h.seqr_h);*/

    /*not_b_s = not_b_seq::type_id::create("not_b_s");
    not_b_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting NOT_B Sequence (CMD = 4'h7)...", UVM_LOW)
    not_b_s.start(env_h.inp_agt_h.seqr_h);*/

    /*mul_shl_s = mul_shl_seq::type_id::create("mul_shl_s");
    mul_shl_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting MUL_SHL Sequence (CMD = 4'hA)...", UVM_LOW)
    mul_shl_s.start(env_h.inp_agt_h.seqr_h);*/

    /*mul_inc_s = mul_inc_seq::type_id::create("mul_inc_s");
    mul_inc_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting MUL_INC Sequence (CMD = 4'h9)...", UVM_LOW)
    mul_inc_s.start(env_h.inp_agt_h.seqr_h);*/

    /*cmp_s = cmp_seq::type_id::create("cmp_s");
    cmp_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting CMP Sequence (CMD = 4'h8)...", UVM_LOW)
    cmp_s.start(env_h.inp_agt_h.seqr_h);*/

    /*inc_dec_s = inc_dec_seq::type_id::create("inc_dec_s");
    inc_dec_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting Inc/Dec Sequence (CMD = 4'h4 to 4'h7)...", UVM_LOW)
    inc_dec_s.start(env_h.inp_agt_h.seqr_h);*/

    /*sub_cin_s = sub_cin_seq::type_id::create("sub_cin_s");
    sub_cin_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting SUB with CIN Sequence (CMD = 4'h3)...", UVM_LOW)
    sub_cin_s.start(env_h.inp_agt_h.seqr_h);*/

    /*simple_s = alu_simple_seq::type_id::create("simple_s");
    simple_s.num_txns = 100;  
    simple_s.start(env_h.inp_agt_h.seqr_h);*/

    /*add_s = add_seq::type_id::create("add_s");
    add_s.num_txns = 50;   
    add_s.start(env_h.inp_agt_h.seqr_h);*/

    /*sub_s = sub_seq::type_id::create("sub_s");
    sub_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting Subtraction Sequence (CMD = 4'h1)...", UVM_LOW)
    sub_s.start(env_h.inp_agt_h.seqr_h);*/

    /*add_cin_s = add_cin_seq::type_id::create("add_cin_s");
    add_cin_s.num_txns = 50; 
    `uvm_info(get_type_name(), "Starting ADD with CIN Sequence (CMD = 4'h2)...", UVM_LOW)
    add_cin_s.start(env_h.inp_agt_h.seqr_h);*/

    #50000; 

    phase.drop_objection(this);
  endtask

endclass
