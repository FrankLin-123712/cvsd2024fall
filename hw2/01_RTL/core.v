`include "../00_TB/define.v"
`include "./cpu_components/macro_define.v"
`include "./cpu_components/controller.v"

`include "./cpu_components/datapath_components/alu.v"
`include "./cpu_components/datapath_components/immgen.v"
`include "./cpu_components/datapath_components/pc.v"
`include "./cpu_components/datapath_components/regfile.v"

`include "./cpu_components/multicycle_registers/alu_out_reg.v"
`include "./cpu_components/multicycle_registers/alu_src_reg.v"
`include "./cpu_components/multicycle_registers/inst_reg.v"
`include "./cpu_components/multicycle_registers/mem_reg.v"

module core #( // DO NOT MODIFY INTERFACE!!!
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
) ( 
    input i_clk,
    input i_rst_n,

    // Testbench IOs
    output [2:0] o_status, 
    output       o_status_valid,

    // Memory IOs
    output [ADDR_WIDTH-1:0] o_addr,
    output [DATA_WIDTH-1:0] o_wdata,
    output                  o_we,
    input  [DATA_WIDTH-1:0] i_rdata
);

// ---------- wires and regs -----------
// signals for passing data
wire [31:0] pc_inst_addr_w;
wire [31:0] inst_w;
wire [31:0] rf_rs1_w, rf_rs2_w, fd_fs1_w, fd_fs2_w, imm_w;
wire [31:0] src_rs1_w, src_rs2_w, src_fs1_w, src_fs2_w, src_imm_w;
wire [31:0] alu_src_a_w, alu_src_b_w;
wire [31:0] alu_out_w, alu_reg_out_w;
wire [3:0] alu_flag_w, alu_reg_flag_w;
wire [31:0] mem_reg_out_w;
wire [31:0] rf_wdata_w;
wire [31:0] pc_next_w;

// multicycle regsiter write enable
wire wen_reg_pc;
wire wen_reg_inst;
wire wen_reg_src;
wire wen_reg_alu;
wire wen_reg_mem;

// data selection signals
wire sel_pc_next;
wire sel_instr_memls;
wire sel_mem_wdata;
wire [1:0] sel_alu_a;
wire [1:0] sel_alu_b;
wire sel_regfile_wdata;

// data path control signals
wire wen_regfile_rd;
wire wen_regfile_fd;
wire wen_mem;
wire [3:0] op_alu;
wire [6:0] op_code;


// ---------- data path mux connection ----------
assign pc_next_w = (sel_pc_next == `PC_PLUS_IMM) ? alu_reg_out_w : (pc_inst_addr_w + 32'd4);
assign o_addr = (sel_instr_memls == `DATA_ADDR) ? alu_reg_out_w : pc_inst_addr_w;
assign alu_src_a_w = (sel_alu_a == `RS1) ? (src_rs1_w) : 
                        ((sel_alu_a == `FS1) ? (src_fs1_w) : 
                        ((sel_alu_a == `PC) ? pc_inst_addr_w : 32'd0));
assign alu_src_b_w = (sel_alu_b == `RS2) ? (src_rs2_w) : 
                        ((sel_alu_b == `FS2) ? (src_fs2_w) : 
                        ((sel_alu_b == `IMM) ? src_imm_w : 32'd0));
assign rf_wdata_w = (sel_regfile_wdata == `MEM_RDATA) ? mem_reg_out_w : alu_reg_out_w;
assign o_we = wen_mem;
assign o_wdata = (sel_mem_wdata == `FP_DATA) ? src_fs2_w : src_rs2_w;


// ---------- multicycle registers ----------
inst_reg inst_r(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_wen(wen_reg_inst), .i_inst(i_rdata), 
                .o_inst(inst_w));

alu_src_reg alu_src_r(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_wen(wen_reg_src), 
                      .i_rs1(rf_rs1_w), .i_rs2(rf_rs2_w), .i_fs1(fd_fs1_w), .i_fs2(fd_fs2_w), .i_imm(imm_w),
                      .o_rs1(src_rs1_w), .o_rs2(src_rs2_w), .o_fs1(src_fs1_w), .o_fs2(src_fs2_w), .o_imm(src_imm_w));

alu_out_reg alu_out_r(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_wen(wen_reg_alu), 
                      .i_alu_out(alu_out_w), .i_alu_flag(alu_flag_w),
                      .o_alu_out(alu_reg_out_w), .o_alu_flag(alu_reg_flag_w));

mem_reg mem_r(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_wen(wen_reg_mem), .i_mem_rdata(i_rdata), 
              .o_mem_rdata(mem_reg_out_w));

// ---------- controller -----------
controller ctrl(.i_clk(i_clk), .i_rst_n(i_rst_n), 
                // ---- status signals from data path ----
                .i_inst(inst_w), .i_alu_flag(alu_reg_flag_w), .i_alu_out(alu_out_w),
                // ---- control signals to data path ---- 
                // pipeline register write enable signal
                .wen_reg_pc(wen_reg_pc), .wen_reg_inst(wen_reg_inst), .wen_reg_src(wen_reg_src), 
                .wen_reg_alu(wen_reg_alu), .wen_reg_mem(wen_reg_mem),
                // data selection signals
                .sel_pc_next(sel_pc_next), .sel_instr_memls(sel_instr_memls), .sel_mem_wdata(sel_mem_wdata), 
                .sel_alu_a(sel_alu_a), .sel_alu_b(sel_alu_b), .sel_regfile_wdata(sel_regfile_wdata),
                // data path components control signals
                .wen_regfile_rd(wen_regfile_rd), .wen_regfile_fd(wen_regfile_fd), .wen_mem(wen_mem),
                .op_alu(op_alu), .op_code(op_code),
                // system status output signals
                .o_status(o_status), .o_status_valid(o_status_valid));

// ---------- data path components -----------
pc pc_0(.i_clk(i_clk), .i_rst_n(i_rst_n), .i_wen_pc(wen_reg_pc), 
        .i_pc_next(pc_next_w), .o_pc(pc_inst_addr_w));

immgen ig_0(.i_inst(inst_w), .o_imm(imm_w));

regfile rf_int_0(.i_clk(i_clk), .i_rst_n(i_rst_n), 
                 .i_src1_idx(inst_w[19:15]), .i_src2_idx(inst_w[24:20]), .i_dest_idx(inst_w[11:7]),
                 .i_wen(wen_regfile_rd), .i_wdata(rf_wdata_w),
                 .o_src1(rf_rs1_w), .o_src2(rf_rs2_w));

regfile rf_fp_0(.i_clk(i_clk), .i_rst_n(i_rst_n), 
                .i_src1_idx(inst_w[19:15]), .i_src2_idx(inst_w[24:20]), .i_dest_idx(inst_w[11:7]),
                .i_wen(wen_regfile_fd), .i_wdata(rf_wdata_w),
                .o_src1(fd_fs1_w), .o_src2(fd_fs2_w));

alu alu_0(.i_op_code(op_code), .i_op_alu(op_alu), 
          .i_src_a(alu_src_a_w), .i_src_b(alu_src_b_w), 
          .o_alu_out(alu_out_w), .o_alu_flag(alu_flag_w));



endmodule