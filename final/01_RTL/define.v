// modmul : operand a
`define MUL_A_REG0    4'd0
`define MUL_A_REG1    4'd1
`define MUL_A_REG2    4'd2
`define MUL_A_REG3    4'd3
`define MUL_A_REG4    4'd4
`define MUL_A_REG5    4'd5
`define MUL_A_REG6    4'd6
`define MUL_A_REG7    4'd7
`define MUL_A_CONST_D 4'd8

// modmul : operand b
`define MUL_B_REG0 3'd0
`define MUL_B_REG1 3'd1
`define MUL_B_REG2 3'd2
`define MUL_B_REG3 3'd3
`define MUL_B_REG4 3'd4
`define MUL_B_REG5 3'd5
`define MUL_B_REG6 3'd6
`define MUL_B_REG7 3'd7

// modadd : operand a
`define ADD_A_REG0 3'd0
`define ADD_A_REG1 3'd1
`define ADD_A_REG2 3'd2
`define ADD_A_REG3 3'd3
`define ADD_A_REG4 3'd4
`define ADD_A_REG5 3'd5
`define ADD_A_REG6 3'd6
`define ADD_A_REG7 3'd7

// modadd : operand b
`define ADD_B_REG0 3'd0
`define ADD_B_REG1 3'd1
`define ADD_B_REG2 3'd2
`define ADD_B_REG3 3'd3
`define ADD_B_REG4 3'd4
`define ADD_B_REG5 3'd5
`define ADD_B_REG6 3'd6
`define ADD_B_REG7 3'd7

// modsub : operand a
`define SUB_A_REG0    4'd0
`define SUB_A_REG1    4'd1
`define SUB_A_REG2    4'd2
`define SUB_A_REG3    4'd3
`define SUB_A_REG4    4'd4
`define SUB_A_REG5    4'd5
`define SUB_A_REG6    4'd6
`define SUB_A_REG7    4'd7
`define SUB_A_CONST_Q 4'd8

// modsub : operand b
`define SUB_B_REG0 3'd0
`define SUB_B_REG1 3'd1
`define SUB_B_REG2 3'd2
`define SUB_B_REG3 3'd3
`define SUB_B_REG4 3'd4
`define SUB_B_REG5 3'd5
`define SUB_B_REG6 3'd6
`define SUB_B_REG7 3'd7

// regfile : wdata
`define REGF_WD_MUL    2'd0
`define REGF_WD_ADD    2'd1
`define REGF_WD_SUB    2'd2
`define REGF_WD_INDATA 2'd3