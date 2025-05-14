// opcode mapping
`define OP_INT     7'b0110011 // add, sub, slt, sll, srl
`define OP_INT_IMM 7'b0010011 // addi
`define OP_FP      7'b1010011 // fadd, fsub, fclass, flt
`define LOAD       7'b0000011 // lw
`define STORE      7'b0100011 // sw
`define FLOAD      7'b0000111 // flw
`define FSTORE     7'b0100111 // fsw
`define BRANCH     7'b1100011 // beq, blt
`define EOF        7'b1110011 // eof

// operation of ALU
`define ADD    4'b0000
`define SUB    4'b0001
`define SLL    4'b0010
`define SRL    4'b0011
`define INT_EQ 4'b0100
`define INT_LT 4'b0101
`define FADD   4'b0110
`define FSUB   4'b0111
`define FCLASS 4'b1000
`define FP_LT  4'b1001

// selection of alu src A
`define RS1 2'b00
`define FS1 2'b01
`define PC  2'b10

// selection of alu src B
`define RS2 2'b00
`define FS2 2'b01
`define IMM 2'b10

// selection of regfile write back data
`define ALU_OUT   1'b0
`define MEM_RDATA 1'b1

// selection of mem addr
`define INST_ADDR 1'b0
`define DATA_ADDR 1'b1

// selection of mem write data
`define INT_DATA 1'b0
`define FP_DATA  1'b1

// selection of pc update value
`define PC_PLUS_4   1'b0
`define PC_PLUS_IMM 1'b1