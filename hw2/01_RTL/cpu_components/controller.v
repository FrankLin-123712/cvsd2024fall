`define INST_op      i_inst[6:0]
`define INST_funct7  i_inst[31:25]
`define INST_funct3  i_inst[14:12]

`define ALU_fp_inf   i_alu_flag[3]
`define ALU_fp_nan   i_alu_flag[2]
`define ALU_addr_oob i_alu_flag[1]
`define ALU_overflow i_alu_flag[0]

module controller(
    input i_clk,
    input i_rst_n,
    
    // ------- status signals from data path -------
    input [31:0] i_inst,
    input [3:0]  i_alu_flag,
    input [31:0] i_alu_out,  // the alu_out from alu directly

    // ------- control signals to data path -------
    // pipeline register write enable signal
    output wen_reg_pc,
    output wen_reg_inst,
    output wen_reg_src,
    output wen_reg_alu,
    output wen_reg_mem,

    // data selection signals
    output sel_pc_next,
    output sel_instr_memls,
    output sel_mem_wdata,
    output [1:0] sel_alu_a,
    output [1:0] sel_alu_b,
    output sel_regfile_wdata,

    // data path components control signals
    output wen_regfile_rd,
    output wen_regfile_fd,
    output wen_mem,
    output [3:0] op_alu,
    output [6:0] op_code,

    // system status output signals
    output [2:0] o_status,
    output o_status_valid
);


// ------ Status encoding ------
parameter S_IDLE       = 4'd0, 
          S_IF_RM      = 4'd1,
          S_IF_IR      = 4'd2,
          S_ID         = 4'd3,
          S_EX         = 4'd4,
          S_MEM        = 4'd5,
          S_CAL_PC     = 4'd6,
          S_MEM_READ   = 4'd7,
          S_WB_NEXT_PC = 4'd8,
          S_INV_INT_AR = 4'd9,
          S_INV_FP_AR  = 4'd10,
          S_INV_ADDR   = 4'd11,
          S_HALT       = 4'd12,
          S_STOP       = 4'd13;

// ------ Wires and Regs ------ 
// controller state reg
reg [3:0] state;
reg [3:0] state_next;
// control signals for set and clear branch taken flag
reg reset_reg_bt_flag;
reg wen_reg_bt_flag;
// branch taken flag reg
reg bt_flag_reg;

// ------ output signals ------
// wen signals
reg wen_reg_pc_w;
reg wen_reg_inst_w;
reg wen_reg_src_w;
reg wen_reg_alu_w;
reg wen_reg_mem_w;

// selection signals
reg sel_pc_next_w;
reg sel_instr_memls_w;
reg sel_mem_wdata_w;
reg [1:0] sel_alu_a_w;
reg [1:0] sel_alu_b_w;
reg sel_regfile_wdata_w;

// data path control signals
reg wen_regfile_rd_w;
reg wen_regfile_fd_w;
reg wen_mem_w;
reg [3:0] op_alu_w;
reg [6:0] op_code_w;

// system signals
reg [2:0] o_status_w;
reg o_status_valid_w;

// invalid flag
wire inv_int_ar_flag;
wire inv_fp_ar_flag;
wire inv_instaddr_oob_flag;





assign inv_int_ar_flag = (({`INST_op, `INST_funct7} == {`OP_INT, `FUNCT7_ADD}) ||
                          ({`INST_op, `INST_funct7} == {`OP_INT, `FUNCT7_SUB}) ||
                          (`INST_op == `OP_INT_IMM)) && `ALU_overflow;
assign inv_fp_ar_flag = (({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FADD}) ||
                         ({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FSUB}) ||
                         ({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FLT})
                        ) && (`ALU_fp_inf || `ALU_fp_nan);
assign inv_instaddr_oob_flag = (`INST_op == `BRANCH) && (`ALU_addr_oob || `ALU_overflow);
// -------------------------------
// Status reg for branch taken
// -------------------------------
always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        bt_flag_reg <= 1'b0;
    end
    else begin
        if(reset_reg_bt_flag) begin
            bt_flag_reg <= 1'b0;
        end
        else begin
            bt_flag_reg <= (wen_reg_bt_flag) ? (i_alu_out == 32'd1) : bt_flag_reg;
        end
    end
end

// ---------------------------------------------------------------------------
// Controller
// ---------------------------------------------------------------------------

// ----------- CS ----------
always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
       state <= S_IDLE;
    end   
    else begin
        state <= state_next;
    end
end

// ----------- NL ----------
always @(*)
begin
    // default assignment
    state_next = S_IDLE;
    
    case(state)
        S_IDLE: begin
            state_next = S_IF_RM;
        end
        S_IF_RM: begin
            state_next = S_IF_IR;
        end
        S_IF_IR: begin
            state_next = S_ID;
        end
        S_ID: begin
            if(`INST_op == `EOF) begin
                state_next = S_HALT;
            end
            else begin
                state_next = S_EX;
            end
        end
        S_EX: begin
            case(`INST_op)
                // R type instruction - integer arithmetic op
                `OP_INT:     state_next = S_WB_NEXT_PC;
                // R type instruction - floating-point arithmetic op
                `OP_FP:      state_next = S_WB_NEXT_PC;
                // I type instruction - add with intermediate value op
                `OP_INT_IMM: state_next = S_WB_NEXT_PC;
                // LOAD instruction 
                `LOAD:       state_next = S_MEM;
                `FLOAD:      state_next = S_MEM;
                // S type instruction
                `STORE:      state_next = S_MEM;
                `FSTORE:     state_next = S_MEM;
                // BRANCH
                `BRANCH:     state_next = S_CAL_PC;
            endcase
        end
        S_MEM: begin
            case(`INST_op)
                // LOAD instruction
                `LOAD:   state_next = (`ALU_overflow || `ALU_addr_oob) ? S_INV_ADDR : S_MEM_READ;
                `FLOAD:  state_next = (`ALU_overflow || `ALU_addr_oob) ? S_INV_ADDR : S_MEM_READ;
                // STORE instruction
                `STORE:  state_next = (`ALU_overflow || `ALU_addr_oob) ? S_INV_ADDR : S_WB_NEXT_PC;
                `FSTORE: state_next = (`ALU_overflow || `ALU_addr_oob) ? S_INV_ADDR : S_WB_NEXT_PC;
            endcase
        end
        S_CAL_PC: begin
            state_next = S_WB_NEXT_PC;
        end
        S_MEM_READ: begin
            state_next = S_WB_NEXT_PC;
        end
        S_WB_NEXT_PC: begin
            if( (({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FADD}) ||
                 ({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FSUB}) ||
                 ({`INST_op, `INST_funct7} == {`OP_FP, `FUNCT7_FLT})) && 
                 (`ALU_fp_inf || `ALU_fp_nan)
              ) begin
                // encounter the invalid operation @fadd, fsub, flt
                // operand or result is infinite or nan number
                state_next = S_INV_FP_AR;
            end
            else if((({`INST_op, `INST_funct7} == {`OP_INT, `FUNCT7_ADD}) ||
                     ({`INST_op, `INST_funct7} == {`OP_INT, `FUNCT7_SUB}) ||
                     ({`INST_op, `INST_funct3} == {`OP_INT_IMM, `FUNCT3_ADDI})) && 
                     `ALU_overflow) begin
                // encounter the invalid operation @add, sub, addi
                // result is overflow
                state_next = S_INV_INT_AR;
            end
            else if((`INST_op == `BRANCH) &&
                    (`ALU_addr_oob || `ALU_overflow) &&
                    (bt_flag_reg)) begin
                // encounter the invalid operation @beq, blt
                // addr is overflow or out of inst mem space
                // only triggered when the branch is taken
                state_next = S_INV_ADDR;
            end
            else begin
                state_next = S_IF_RM;
            end
        end
        S_INV_INT_AR: state_next = S_STOP;
        S_INV_FP_AR : state_next = S_STOP;
        S_INV_ADDR  : state_next = S_STOP;
        S_HALT      : state_next = S_STOP;
        S_STOP      : state_next = S_STOP;
    endcase
end



// ----------- OL ----------
// wen signals
assign wen_reg_pc = wen_reg_pc_w;
assign wen_reg_inst = wen_reg_inst_w;
assign wen_reg_src = wen_reg_src_w;
assign wen_reg_alu = wen_reg_alu_w;
assign wen_reg_mem = wen_reg_mem_w;

// selection signals
assign sel_pc_next = sel_pc_next_w;
assign sel_instr_memls = sel_instr_memls_w;
assign sel_mem_wdata = sel_mem_wdata_w;
assign sel_alu_a = sel_alu_a_w;
assign sel_alu_b = sel_alu_b_w;
assign sel_regfile_wdata = sel_regfile_wdata_w;

// data path control signals
assign wen_regfile_rd = wen_regfile_rd_w;
assign wen_regfile_fd = wen_regfile_fd_w;
assign wen_mem = wen_mem_w;
assign op_alu = op_alu_w;
assign op_code = op_code_w;

// system signals
assign o_status = o_status_w;
assign o_status_valid = o_status_valid_w;

always @(*)
begin
    // default assignment
    wen_reg_pc_w   = 1'b0;
    wen_reg_inst_w = 1'b0;
    wen_reg_src_w  = 1'b0;
    wen_reg_alu_w  = 1'b0;
    wen_reg_mem_w  = 1'b0;

    sel_pc_next_w       = 1'b0;
    sel_instr_memls_w   = 1'b0;
    sel_mem_wdata_w     = 1'b0;
    sel_alu_a_w         = 2'b00;
    sel_alu_b_w         = 2'b00;
    sel_regfile_wdata_w = 2'b00;

    wen_regfile_rd_w   = 1'b0;
    wen_regfile_fd_w   = 1'b0;
    wen_mem_w          = 1'b0;
    op_alu_w           = 4'b0000;
    op_code_w          = 7'b111_1111;

    o_status_w         = 3'b000;
    o_status_valid_w   = 1'b0;

    reset_reg_bt_flag  = 1'b0;
    wen_reg_bt_flag    = 1'b0;

    case(state)
        // States that output 0
        // S_IDLE
        // S_HALT
        // S_INV_INT_AR
        // S_INV_FP_AR
        // S_INV_ADDR

        S_IF_RM      : begin
            sel_instr_memls_w = `INST_ADDR;
            wen_mem_w         = 1'b0;
            wen_reg_inst_w    = 1'b0;
        end
        S_IF_IR      : begin
            wen_reg_inst_w    = 1'b1;
        end
        S_ID         : begin
            if(`INST_op == `EOF) begin
                o_status_w       = `EOF_TYPE;
                o_status_valid_w = 1'b1;
            end
            else begin
                wen_reg_src_w = 1'b1;
            end
        end
        S_EX         : begin
            wen_reg_alu_w    = 1'b1;
            case(`INST_op)
                // R type instruction - integer arithmetic op  (add, sub, slt, sll, srl)
                `OP_INT: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `RS2;
                    case({`INST_funct7, `INST_funct3})
                        {`FUNCT7_ADD, `FUNCT3_ADD} : op_alu_w = `ADD;
                        {`FUNCT7_SUB, `FUNCT3_SUB} : op_alu_w = `SUB;
                        {`FUNCT7_SLT, `FUNCT3_SLT} : op_alu_w = `INT_LT;
                        {`FUNCT7_SLL, `FUNCT3_SLL} : op_alu_w = `SLL;
                        {`FUNCT7_SRL, `FUNCT3_SRL} : op_alu_w = `SRL;
                    endcase
                    op_code_w = `INST_op;
                end
                // R type instruction - floating-point arithmetic op
                `OP_FP: begin
                    sel_alu_a_w = `FS1;
                    sel_alu_b_w = `FS2;
                    case({`INST_funct7, `INST_funct3})
                        {`FUNCT7_FADD, `FUNCT3_FADD} :     op_alu_w = `FADD;
                        {`FUNCT7_FSUB, `FUNCT3_FSUB} :     op_alu_w = `FSUB;
                        {`FUNCT7_FCLASS, `FUNCT3_FCLASS} : op_alu_w = `FCLASS;
                        {`FUNCT7_FLT, `FUNCT3_FLT} :       op_alu_w = `FP_LT;
                    endcase
                    op_code_w = `INST_op;
                end
                // I type instruction - add with intermediate value op
                `OP_INT_IMM: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `IMM;
                    op_alu_w    = `ADD;
                    op_code_w   = `INST_op;
                end
                // LOAD instruction 
                `LOAD: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `IMM;
                    op_alu_w    = `ADD;
                    op_code_w   = `INST_op;
                end
                `FLOAD: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `IMM;
                    op_alu_w    = `ADD;
                    op_code_w   = `INST_op;
                end
                // S type instruction
                `STORE: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `IMM;
                    op_alu_w    = `ADD;
                    op_code_w   = `INST_op;
                end
                `FSTORE: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `IMM;
                    op_alu_w    = `ADD;
                    op_code_w   = `INST_op;
                end
                // BRANCH
                `BRANCH: begin
                    sel_alu_a_w = `RS1;
                    sel_alu_b_w = `RS2;
                    case(`INST_funct3)
                        `FUNCT3_BEQ: op_alu_w = `INT_EQ;
                        `FUNCT3_BLT: op_alu_w = `INT_LT;
                    endcase
                    wen_reg_bt_flag = 1'b1;
                end
            endcase
        end
        S_MEM        : begin
            if ((`ALU_overflow || `ALU_addr_oob)) begin
                // mem address out of bound
                o_status_w = `INVALID_TYPE;
                o_status_valid_w = 1'b1;
            end
            else begin
                if ((`INST_op == `LOAD) || (`INST_op == `FLOAD)) begin
                    sel_instr_memls_w = `DATA_ADDR;
                    wen_mem_w         = 1'b0;
                    wen_reg_mem_w     = 1'b0;
                end
                else if(`INST_op == `STORE) begin
                    sel_instr_memls_w = `DATA_ADDR;
                    sel_mem_wdata_w   = `INT_DATA;
                    wen_mem_w         = 1'b1;
                end 
                else if(`INST_op == `FSTORE) begin
                    sel_instr_memls_w = `DATA_ADDR;
                    sel_mem_wdata_w   = `FP_DATA;
                    wen_mem_w         = 1'b1;
                end
            end
        end
        S_CAL_PC     : begin
            sel_alu_a_w    = `PC;
            sel_alu_b_w    = `IMM;
            op_alu_w       = `ADD;
            wen_reg_alu_w  = 1'b1;
            op_code_w      = `INST_op;
        end
        S_MEM_READ   : begin
            sel_instr_memls_w = `DATA_ADDR;
            wen_mem_w         = 1'b0;
            wen_reg_mem_w     = 1'b1;
        end
        S_WB_NEXT_PC : begin
            if(inv_fp_ar_flag) begin
                // fp invalid operation
                o_status_w = `INVALID_TYPE;
                o_status_valid_w = 1'b1;
            end 
            else if(inv_int_ar_flag) begin
                // int invalid operation
                o_status_w = `INVALID_TYPE;
                o_status_valid_w = 1'b1;
            end
            else if(inv_instaddr_oob_flag) begin
                // branch invalid operation
                o_status_w = `INVALID_TYPE;
                o_status_valid_w = 1'b1;
            end
            else begin
                o_status_valid_w = 1'b1;
                wen_reg_pc_w     = 1'b1;
                // ------ reset status reg in controller ------
                reset_reg_bt_flag  = 1'b1;
                case(`INST_op)
                    `OP_INT: begin // add, sub, slt, sll, srl
                        // ------ o_status ------
                        o_status_w = `R_TYPE; 
                        // ------ update regfiles ------
                        sel_regfile_wdata_w = `ALU_OUT;
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b10;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `OP_INT_IMM: begin // addi
                        // ------ o_status ------
                        o_status_w = `I_TYPE;
                        // ------ update regfiles ------
                        sel_regfile_wdata_w = `ALU_OUT;
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b10;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `OP_FP: begin // fadd, fsub, fclass, flt
                        // ------ o_status ------
                        o_status_w = `R_TYPE;
                        // ------ update regfiles ------
                        sel_regfile_wdata_w = `ALU_OUT;
                        {wen_regfile_rd_w, wen_regfile_fd_w} = ((`INST_funct7 == `FUNCT7_FCLASS) || (`INST_funct7 == `FUNCT7_FLT)) ? 2'b10 : 2'b01;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `LOAD: begin // lw
                        // ------ o_status ------
                        o_status_w = `I_TYPE;
                        // ------ update regfiles ------
                        sel_regfile_wdata_w = `MEM_RDATA;
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b10;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `FLOAD: begin // flw
                        // ------ o_status ------
                        o_status_w = `I_TYPE;
                        // ------ update regfiles ------
                        sel_regfile_wdata_w = `MEM_RDATA;
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b01;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `STORE: begin // sw
                        // ------ o_status ------
                        o_status_w = `S_TYPE;
                        // ------ update regfiles ------
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b00;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `FSTORE: begin // fsw
                        // ------ o_status ------
                        o_status_w = `S_TYPE;
                        // ------ update regfiles ------
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b00;
                        // ------ update program counter ------
                        sel_pc_next_w = `PC_PLUS_4;
                    end
                    `BRANCH: begin // beq, blt
                        // ------ o_status ------
                        o_status_w = `B_TYPE;
                        // ------ update regfiles ------
                        {wen_regfile_rd_w, wen_regfile_fd_w} = 2'b00;
                        // ------ update program counter ------
                        sel_pc_next_w = (bt_flag_reg) ? `PC_PLUS_IMM : `PC_PLUS_4;
                    end
                endcase
            end
        end
    endcase
end


endmodule