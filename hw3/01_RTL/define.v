// ---------------- SRAM macro ----------------
`define RESET_MODE  3'd0
`define LOAD_MODE   3'd1
`define DISP_MODE   3'd2
`define CONV_MODE   3'd3
`define SOBEL_MODE  3'd4
`define MEDIAN_MODE 3'd5

// ----------------- inst macro -------------------
`define LOAD_IF  4'b0000
`define ORI_RS   4'b0001
`define ORI_LS   4'b0010
`define ORI_US   4'b0011
`define ORI_DS   4'b0100
`define RDU_CH   4'b0101
`define INC_CH   4'b0110
`define OUTPUT   4'b0111
`define CONV     4'b1000
`define MED_FLT  4'b1001
`define SOBELNMS 4'b1010

// ------------- tensor op macro ---------------
`define MV_RIGHT  3'd0
`define MV_LEFT   3'd1
`define MV_UP     3'd2
`define MV_DOWN   3'd3
`define REDUCE_CH 3'd4
`define INCRE_CH  3'd5

// -------- options for selecting output data from which engine ------------
`define SEQ_CONV   2'd0
`define SEQ_MEDIAN 2'd1
`define SEQ_SOBEL  2'd2