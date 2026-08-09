class alu_base_seq extends uvm_sequence #(trans);
  `uvm_object_utils(alu_base_seq)

  int num_txns = 500;

  function new(string name = "alu_base_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize())
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

//--------------------------------------------------------------------------------------------------------------------------------------------------------
class alu_master_comprehensive_seq extends alu_base_seq;
  `uvm_object_utils(alu_master_comprehensive_seq)

  int num_standard_txns = 5000;
  int num_delay_txns    = 5000;

  function new(string name = "alu_master_comprehensive_seq");
    super.new(name);
  endfunction

  virtual task body();
    
    `uvm_info(get_type_name(), $sformatf("Starting Phase 1: %0d standard transactions...", num_standard_txns), UVM_LOW)
    
    repeat(num_standard_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        if (mode == 1'b1) {
          cmd inside {[4'h0 : 4'h8]};
        } else {
          cmd inside {[4'h0 : 4'hD]};
        }
      })
        `uvm_error(get_type_name(), "Standard op randomization failed")
      finish_item(req);
    end

    `uvm_info(get_type_name(), $sformatf("Starting Phase 2: %0d dynamic edge-case & staggered transactions...", num_delay_txns), UVM_LOW)

    repeat(num_delay_txns) begin
      bit [3:0] rand_cmd;
      int scenario_type;

      rand_cmd      = $urandom_range(0, 13);
      scenario_type = $urandom_range(1, 4);

      case (scenario_type)
        
        1: begin
          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b01;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OA        inside {[0 : 255]};
          })
            `uvm_error(get_type_name(), "Staggered Op A failed")
          finish_item(req);

          #($urandom_range(1, 10) * 10ns);

          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b10;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OB        inside {[0 : 255]};
          })
            `uvm_error(get_type_name(), "Staggered Op B failed")
          finish_item(req);
        end

        2: begin
          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b01;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OA        inside {[0 : 255]};
          })
            `uvm_error(get_type_name(), "Timeout Op A failed")
          finish_item(req);

          repeat(18) begin
            req = trans::type_id::create("req");
            start_item(req);
            if (!req.randomize() with {
              ce        == 1'b1;
              inp_valid == 2'b00;
            })
              `uvm_error(get_type_name(), "Timeout idle cycle failed")
            finish_item(req);
          end
        end

        3: begin
          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b01;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OA        == 8'h0A;
          })
            `uvm_error(get_type_name(), "Initial OA failed")
          finish_item(req);

          #40ns;

          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b01;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OA        == 8'h50;
          })
            `uvm_error(get_type_name(), "Updated OA failed")
          finish_item(req);

          #20ns;

          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b10;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OB        == 8'h05;
          })
            `uvm_error(get_type_name(), "OB completion failed")
          finish_item(req);
        end

        4: begin
          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b01;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OA        inside {[0 : 255]};
          })
            `uvm_error(get_type_name(), "Late Op A failed")
          finish_item(req);

          #180ns;

          req = trans::type_id::create("req");
          start_item(req);
          if (!req.randomize() with {
            ce        == 1'b1;
            inp_valid == 2'b10;
            mode      == (rand_cmd inside {[8:13]} ? 1'b0 : 1'b1);
            cmd       == rand_cmd;
            OB        inside {[0 : 255]};
          })
            `uvm_error(get_type_name(), "Late Op B failed")
          finish_item(req);
        end

      endcase
    end
  endtask
endclass

class latest_operand_a_seq extends alu_base_seq;
  `uvm_object_utils(latest_operand_a_seq)

  function new(string name = "latest_operand_a_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        == 8'h0A;
      })
        `uvm_error(get_type_name(), "Initial Operand A randomization failed")
      finish_item(req);

      #80ns;

      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        == 8'h32;
      })
        `uvm_error(get_type_name(), "Updated Operand A randomization failed")
      finish_item(req);

      #20ns;

      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b10;
        mode      == 1'b1;
        cmd       == 4'h9;
        OB        == 8'h05;
      })
        `uvm_error(get_type_name(), "Operand B randomization failed")
      finish_item(req);
    end
  endtask
endclass

class late_operand_b_seq extends alu_base_seq;
  `uvm_object_utils(late_operand_b_seq)

  function new(string name = "late_operand_b_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        inside {[0 : 255]};
      })
        `uvm_error(get_type_name(), "Operand A randomization failed")
      finish_item(req);

      #180ns;

      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b10;
        mode      == 1'b1;
        cmd       == 4'h9;
        OB        inside {[0 : 255]};
      })
        `uvm_error(get_type_name(), "Operand B randomization failed")
      finish_item(req);
    end
  endtask
endclass

class timeout_error_seq extends alu_base_seq;
  `uvm_object_utils(timeout_error_seq)

  function new(string name = "timeout_error_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        inside {[0 : 255]};
      })
        `uvm_error(get_type_name(), "Operand A randomization failed")
      finish_item(req);

      repeat(18) begin
        req = trans::type_id::create("req");
        start_item(req);
        if (!req.randomize() with {
          ce        == 1'b1;
          inp_valid == 2'b00;
        })
          `uvm_error(get_type_name(), "Idle transaction randomization failed")
        finish_item(req);
      end
    end
  endtask
endclass

class mul_9_wait_seq extends alu_base_seq;
  `uvm_object_utils(mul_9_wait_seq)

  function new(string name = "mul_9_wait_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        inside {[0 : 15]};
      })
        `uvm_error(get_type_name(), "Operand A randomization failed")
      finish_item(req);

      #($urandom_range(1, 8) * 10ns);

      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b10;
        mode      == 1'b1;
        cmd       == 4'h9;
        OB        inside {[0 : 15]};
      })
        `uvm_error(get_type_name(), "Operand B randomization failed")
      finish_item(req);
    end
  endtask
endclass

class add_wait_seq extends alu_base_seq;
  `uvm_object_utils(add_wait_seq)

  function new(string name = "add_wait_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b01;
        mode      == 1'b0;
        cmd       == 4'h0;
        OA        inside {[0 : 255]};
      })
        `uvm_error(get_type_name(), "Operand A randomization failed")
      finish_item(req);

      #($urandom_range(1, 10) * 10ns);

      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b10;
        mode      == 1'b0;
        cmd       == 4'h0;
        OB        inside {[0 : 255]};
      })
        `uvm_error(get_type_name(), "Operand B randomization failed")
      finish_item(req);
    end
  endtask
endclass

class shr1_a_seq extends alu_base_seq;
  `uvm_object_utils(shr1_a_seq)
  function new(string name = "shr1_a_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h8; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class shl1_a_seq extends alu_base_seq;
  `uvm_object_utils(shl1_a_seq)
  function new(string name = "shl1_a_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h9; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class shr1_b_seq extends alu_base_seq;
  `uvm_object_utils(shr1_b_seq)
  function new(string name = "shr1_b_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'hA; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class shl1_b_seq extends alu_base_seq;
  `uvm_object_utils(shl1_b_seq)
  function new(string name = "shl1_b_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'hB; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class rol_seq extends alu_base_seq;
  `uvm_object_utils(rol_seq)
  function new(string name = "rol_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'hC; OB inside {[0:255]}; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class ror_seq extends alu_base_seq;
  `uvm_object_utils(ror_seq)
  function new(string name = "ror_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'hD; OB inside {[0:255]}; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class and_seq extends alu_base_seq;
  `uvm_object_utils(and_seq)
  function new(string name = "and_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h0; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class nand_seq extends alu_base_seq;
  `uvm_object_utils(nand_seq)
  function new(string name = "nand_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h1; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class or_seq extends alu_base_seq;
  `uvm_object_utils(or_seq)
  function new(string name = "or_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h2; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class nor_seq extends alu_base_seq;
  `uvm_object_utils(nor_seq)
  function new(string name = "nor_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h3; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class xor_seq extends alu_base_seq;
  `uvm_object_utils(xor_seq)
  function new(string name = "xor_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h4; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class xnor_seq extends alu_base_seq;
  `uvm_object_utils(xnor_seq)
  function new(string name = "xnor_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h5; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class not_a_seq extends alu_base_seq;
  `uvm_object_utils(not_a_seq)
  function new(string name = "not_a_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h6; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class not_b_seq extends alu_base_seq;
  `uvm_object_utils(not_b_seq)
  function new(string name = "not_b_seq"); super.new(name); endfunction
  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);
      if (!req.randomize() with { ce == 1'b1; inp_valid == 2'b11; mode == 1'b0; cmd == 4'h7; })
        `uvm_error(get_type_name(), "Randomization failed")
      finish_item(req);
    end
  endtask
endclass

class mul_shl_seq extends alu_base_seq;
  `uvm_object_utils(mul_shl_seq)

  function new(string name = "mul_shl_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'hA;
        OA        inside {[0 : 20]};
        OB        inside {[0 : 20]};
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class mul_inc_seq extends alu_base_seq;
  `uvm_object_utils(mul_inc_seq)

  function new(string name = "mul_inc_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h9;
        OA        inside {[0 : 5]};
        OB        inside {[0 : 5]};
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class cmp_seq extends alu_base_seq;
  `uvm_object_utils(cmp_seq)

  function new(string name = "cmp_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h8;
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class inc_dec_seq extends alu_base_seq;
  `uvm_object_utils(inc_dec_seq)

  function new(string name = "inc_dec_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       inside {[4'h4:4'h7]};
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class sub_cin_seq extends alu_base_seq;
  `uvm_object_utils(sub_cin_seq)

  function new(string name = "sub_cin_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h3;
        cin       == 1'b1;
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class add_cin_seq extends alu_base_seq;
  `uvm_object_utils(add_cin_seq)

  function new(string name = "add_cin_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h2;
        cin       == 1'b1;
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class alu_simple_seq extends alu_base_seq;
  `uvm_object_utils(alu_simple_seq)

  function new(string name = "alu_simple_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        
        if (mode == 1'b1) {
          cmd inside {[4'h0 : 4'h8]};
        } else {
          cmd inside {[4'h0 : 4'hD]};
        }
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class add_seq extends alu_base_seq;
  `uvm_object_utils(add_seq)

  function new(string name = "add_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h0;
        cin       == 1'b0;
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass

class sub_seq extends alu_base_seq;
  `uvm_object_utils(sub_seq)

  function new(string name = "sub_seq");
    super.new(name);
  endfunction

  virtual task body();
    repeat(num_txns) begin
      req = trans::type_id::create("req");
      start_item(req);

      if (!req.randomize() with {
        ce        == 1'b1;
        inp_valid == 2'b11;
        mode      == 1'b1;
        cmd       == 4'h1;
        cin       == 1'b0;
      })
        `uvm_error(get_type_name(), "Transaction randomization failed")

      finish_item(req);
    end
  endtask
endclass
