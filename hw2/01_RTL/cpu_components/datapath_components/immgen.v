`define INST_op i_inst[6:0]
`define INST_funct3 i_inst[14:12]

`define I_TYPE_IMM i_inst[31:20]
`define S_TYPE_IMM {i_inst[31:25], i_inst[11:7]}
`define B_TYPE_IMM {i_inst[31], i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}

module immgen(
    input [31:0] i_inst,
    output [31:0] o_imm
);

reg [31:0] o_imm_w;

assign o_imm = o_imm_w;

always @(*)
begin
    o_imm_w = 32'd0;
    case({`INST_op, `INST_funct3})
        {`OP_INT_IMM, `FUNCT3_ADDI}: o_imm_w = $signed(`I_TYPE_IMM);
        {      `LOAD,   `FUNCT3_LW}: o_imm_w = $signed(`I_TYPE_IMM);
        {     `FLOAD,  `FUNCT3_FLW}: o_imm_w = $signed(`I_TYPE_IMM);
        {     `STORE,   `FUNCT3_SW}: o_imm_w = $signed(`S_TYPE_IMM);
        {    `FSTORE,  `FUNCT3_FSW}: o_imm_w = $signed(`S_TYPE_IMM);
        {    `BRANCH,  `FUNCT3_BEQ}: o_imm_w = $signed(`B_TYPE_IMM);
        {    `BRANCH,  `FUNCT3_BLT}: o_imm_w = $signed(`B_TYPE_IMM);
    endcase
end

endmodule