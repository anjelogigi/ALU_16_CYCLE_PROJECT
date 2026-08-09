class scoreboard extends uvm_scoreboard;
  `uvm_component_utils(scoreboard)

  uvm_tlm_analysis_fifo #(trans) inp_mon_fifo;
  uvm_tlm_analysis_fifo #(trans) out_mon_fifo;

  trans inp_mon_xn, out_mon_xn;

  bit [`DW-1:0] oprd1, oprd2;
  bit [`CW-1:0] cmd_reg;
  bit oprd1_valid, oprd2_valid, mode_reg, cin_reg;
  int wait_count, pass_count, fail_count;

  trans exp_queue[$], delay_q[$];
  int delay_cycles_q[$];

  localparam int BASE_LATENCY = 3;
  localparam int MUL_LATENCY  = 4;

  function new(string name="scoreboard", uvm_component parent);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    inp_mon_fifo = new("inp_mon_fifo", this);
    out_mon_fifo = new("out_mon_fifo", this);
    inp_mon_xn   = trans::type_id::create("inp_mon_xn");
    out_mon_xn   = trans::type_id::create("out_mon_xn");
  endfunction

  task run_phase(uvm_phase phase);
    fork
      process_input();
      process_output();
    join
  endtask

  task process_input();
    trans cur_exp;
    bit mode_dec_inc_a, mode_dec_inc_b, logic_single_a, logic_single_b;
    bit single_operand_ready, both_operand_ready;

    forever begin
      inp_mon_fifo.get(inp_mon_xn);

      if(inp_mon_xn.rst) begin
        oprd1 = 0; oprd2 = 0;
        oprd1_valid = 0; oprd2_valid = 0;
        mode_reg = 0; cmd_reg = 0; cin_reg = 0;
        wait_count = 0;
        continue;
      end

      if (inp_mon_xn.inp_valid != 2'b00) begin
        mode_reg = inp_mon_xn.mode;
        cmd_reg  = inp_mon_xn.cmd;
        cin_reg  = inp_mon_xn.cin;

        if (inp_mon_xn.inp_valid[0]) begin
          oprd1 = inp_mon_xn.OA;
          oprd1_valid = 1;
        end
        if (inp_mon_xn.inp_valid[1]) begin
          oprd2 = inp_mon_xn.OB;
          oprd2_valid = 1;
        end
        if (inp_mon_xn.inp_valid == 2'b11) wait_count = 0;
      end

      if(oprd1_valid ^ oprd2_valid) wait_count++;

      if(wait_count > 16) begin
        cur_exp = trans::type_id::create("cur_exp");
        cur_exp.err = 1'b1;
        
        delay_q.push_back(cur_exp);
        delay_cycles_q.push_back(BASE_LATENCY);
        
        oprd1_valid = 0; oprd2_valid = 0; wait_count = 0;
      end

      mode_dec_inc_a = mode_reg  && (cmd_reg inside {4'b0100, 4'b0101});
      mode_dec_inc_b = mode_reg  && (cmd_reg inside {4'b0110, 4'b0111});
      logic_single_a = !mode_reg && (cmd_reg inside {4'b0110, 4'b1000, 4'b1001});
      logic_single_b = !mode_reg && (cmd_reg inside {4'b0111, 4'b1010, 4'b1011});

      single_operand_ready = (mode_dec_inc_a && oprd1_valid) || (mode_dec_inc_b && oprd2_valid) ||
                           (logic_single_a && oprd1_valid) || (logic_single_b && oprd2_valid);
      both_operand_ready   = oprd1_valid && oprd2_valid;

      if(single_operand_ready || both_operand_ready) begin
        cur_exp      = trans::type_id::create("cur_exp");
        cur_exp.OA   = oprd1;
        cur_exp.OB   = oprd2;
        cur_exp.mode = mode_reg;
        cur_exp.cmd  = cmd_reg;
        cur_exp.cin  = cin_reg;
        
        ref_model(cur_exp);

        if (mode_reg && (cmd_reg inside {4'b1001, 4'b1010})) begin
          delay_q.push_back(cur_exp);
          delay_cycles_q.push_back(MUL_LATENCY);
        end else begin
          delay_q.push_back(cur_exp);
          delay_cycles_q.push_back(BASE_LATENCY);
        end

        oprd1_valid = 0; oprd2_valid = 0; wait_count = 0;
      end
    end
  endtask

  task process_output();
    trans chk_pkt;

    forever begin
      out_mon_fifo.get(out_mon_xn);

      if(out_mon_xn.rst) begin
        exp_queue.delete(); delay_q.delete(); delay_cycles_q.delete();
        continue;
      end

      foreach (delay_cycles_q[i]) delay_cycles_q[i]--;
      
      while (delay_q.size() > 0 && delay_cycles_q[0] <= 0) begin
        exp_queue.push_back(delay_q.pop_front());
        delay_cycles_q.pop_front();
      end

      if (exp_queue.size() == 0) continue;

      chk_pkt = exp_queue.pop_front();
      
      check_Data(chk_pkt, out_mon_xn);
    end
  endtask

  task ref_model(trans t);
    bit [`DW-1:0] a = t.OA;
    bit [`DW-1:0] b = t.OB;
    
    bit [(`DW*2)-1:0] a_ext   = a;
    bit [(`DW*2)-1:0] b_ext   = b;
    bit [(`DW*2)-1:0] cin_ext = t.cin;
    
    bit [(`DW*2)-1:0] AU_out_tmp1, AU_out_tmp2;
    int               rot_amt;

    t.res = 0; t.cout = 0; t.oflow = 0;
    t.G = 0; t.E = 0; t.L = 0; t.err = 0;

    if(t.mode) begin 
      case(t.cmd)
        4'b0000: begin t.res = a_ext + b_ext;            t.cout = t.res[`DW]; end
        4'b0001: begin t.res = a_ext - b_ext;            t.oflow = (a < b);   end
        4'b0010: begin t.res = a_ext + b_ext + cin_ext; t.cout = t.res[`DW]; end
        4'b0011: begin t.res = a_ext - b_ext - cin_ext; t.oflow = (a < (b + t.cin)); end
        4'b0100: t.res = a_ext + 1'b1;
        4'b0101: t.res = a_ext - 1'b1;
        4'b0110: t.res = b_ext + 1'b1;
        4'b0111: t.res = b_ext - 1'b1;
        4'b1000: begin t.E = (a == b); t.G = (a > b); t.L = (a < b); end
        4'b1001: begin 
                   AU_out_tmp1 = a_ext + 1'b1; 
                   AU_out_tmp2 = b_ext + 1'b1; 
                   t.res = AU_out_tmp1 * AU_out_tmp2; 
                 end
        4'b1010: begin 
                   AU_out_tmp1 = a_ext << 1; 
                   AU_out_tmp2 = b_ext; 
                   t.res = AU_out_tmp1 * AU_out_tmp2; 
                 end
      endcase
    end else begin 
      case(t.cmd)
        4'b0000: t.res = {1'b0, (a & b)};
        4'b0001: t.res = {1'b0, ~(a & b)};
        4'b0010: t.res = {1'b0, (a | b)};
        4'b0011: t.res = {1'b0, ~(a | b)};
        4'b0100: t.res = {1'b0, (a ^ b)};
        4'b0101: t.res = {1'b0, ~(a ^ b)};
        4'b0110: t.res = {1'b0, ~a};
        4'b0111: t.res = {1'b0, ~b};
        4'b1000: t.res = {1'b0, (a >> 1)};
        4'b1001: t.res = {1'b0, (a << 1)};
        4'b1010: t.res = {1'b0, (b >> 1)};
        4'b1011: t.res = {1'b0, (b << 1)};
        4'b1100: begin rot_amt = b[2:0]; t.res = {1'b0, ((a << rot_amt) | (a >> (`DW - rot_amt)))}; t.err = |b[`DW-1:4]; end
        4'b1101: begin rot_amt = b[2:0]; t.res = {1'b0, ((a >> rot_amt) | (a << (`DW - rot_amt)))}; t.err = |b[`DW-1:4]; end
      endcase
    end
  endtask

  function void check_Data(trans exp_pkt, trans act_pkt);
    bit match = 1'b1;

    if(exp_pkt.err) begin
      if(act_pkt.err !== exp_pkt.err) begin 
        match = 1'b0; 
        `uvm_error(get_type_name(), $sformatf("ERR MISMATCH : Exp=%0b Act=%0b", exp_pkt.err, act_pkt.err)) 
      end
    end else begin
      if(act_pkt.res !== exp_pkt.res)     begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("RES MISMATCH : Exp=%0h Act=%0h", exp_pkt.res, act_pkt.res)) end
      if(act_pkt.cout !== exp_pkt.cout)   begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("COUT MISMATCH : Exp=%0b Act=%0b", exp_pkt.cout, act_pkt.cout)) end
      if(act_pkt.oflow !== exp_pkt.oflow) begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("OFLOW MISMATCH : Exp=%0b Act=%0b", exp_pkt.oflow, act_pkt.oflow)) end
      if(act_pkt.G !== exp_pkt.G)         begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("G MISMATCH : Exp=%0b Act=%0b", exp_pkt.G, act_pkt.G)) end
      if(act_pkt.E !== exp_pkt.E)         begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("E MISMATCH : Exp=%0b Act=%0b", exp_pkt.E, act_pkt.E)) end
      if(act_pkt.L !== exp_pkt.L)         begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("L MISMATCH : Exp=%0b Act=%0b", exp_pkt.L, act_pkt.L)) end
      if(act_pkt.err !== exp_pkt.err)     begin match = 1'b0; `uvm_error(get_type_name(), $sformatf("ERR MISMATCH : Exp=%0b Act=%0b", exp_pkt.err, act_pkt.err)) end
    end

    if(match) begin
      pass_count++;
      `uvm_info(get_type_name(), $sformatf("\n*************** PASS ****************\nInputs   : Mode=%0b Cmd=%0h OA=%0h OB=%0h CIN=%0b\nExpected : RES=%0h COUT=%0b OFLOW=%0b G=%0b E=%0b L=%0b ERR=%0b\nActual   : RES=%0h COUT=%0b OFLOW=%0b G=%0b E=%0b L=%0b ERR=%0b\n*************************************", exp_pkt.mode, exp_pkt.cmd, exp_pkt.OA, exp_pkt.OB, exp_pkt.cin, exp_pkt.res, exp_pkt.cout, exp_pkt.oflow, exp_pkt.G, exp_pkt.E, exp_pkt.L, exp_pkt.err, act_pkt.res, act_pkt.cout, act_pkt.oflow, act_pkt.G, act_pkt.E, act_pkt.L, act_pkt.err), UVM_NONE)
    end else begin
      fail_count++;
      `uvm_error(get_type_name(), $sformatf("\n!!!!!!!!!!!!!!! FAIL !!!!!!!!!!!!!!!!\nInputs   : Mode=%0b Cmd=%0h OA=%0h OB=%0h CIN=%0b\nExpected : RES=%0h COUT=%0b OFLOW=%0b G=%0b E=%0b L=%0b ERR=%0b\nActual   : RES=%0h COUT=%0b OFLOW=%0b G=%0b E=%0b L=%0b ERR=%0b\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!", exp_pkt.mode, exp_pkt.cmd, exp_pkt.OA, exp_pkt.OB, exp_pkt.cin, exp_pkt.res, exp_pkt.cout, exp_pkt.oflow, exp_pkt.G, exp_pkt.E, exp_pkt.L, exp_pkt.err, act_pkt.res, act_pkt.cout, act_pkt.oflow, act_pkt.G, act_pkt.E, act_pkt.L, act_pkt.err))
    end
  endfunction

  function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    if(exp_queue.size() != 0 || delay_q.size() != 0) begin
      `uvm_error(get_type_name(), $sformatf("Simulation ended with %0d expected transactions left in queue! (DUT dropped outputs?)", exp_queue.size() + delay_q.size()))
    end
  endfunction

  function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info(get_type_name(), $sformatf("\n========================================\nFINAL SCOREBOARD SUMMARY\n========================================\nTOTAL CHECKS    = %0d\nMATCH (PASS)    = %0d\nMISMATCH (FAIL) = %0d\n========================================", pass_count + fail_count, pass_count, fail_count), UVM_NONE)
  endfunction

endclass
