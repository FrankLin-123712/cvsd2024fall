// `include "./DataIn.v"
// `include "./PointAdder.v"
// `include "./Reducer.v"
// `include "./DataOut.v"
// `include "./utils.v"


module ed25519 (
        input i_clk,
        input i_rst ,
        input i_in_valid,
        output o_in_ready,
        input [63:0] i_in_data,
        output o_out_valid,
        input  i_out_ready,
        output [63:0]o_out_data
);



// wire ptadd_ready, ptadd_valid;
wire reduce_valid, reduce_ready;
wire dataout_valid, dataout_ready;
// wire [254:0] ptadd_xp, ptadd_yp, ptadd_m; 
wire [254:0] reduce_xmp, reduce_ymp, reduce_zmp;
wire [254:0] dataout_bits;

// DataIn datain (
//     .i_clk(i_clk),
//     .i_rst(i_rst),
//     // --- IO ---
//     .i_in_valid(i_in_valid),
//     .i_in_data(i_in_data),
//     .o_in_ready(o_in_ready),
//     // --- PointAdder ---
//     .i_ptadd_ready(ptadd_ready),
//     .o_ptadd_m(ptadd_m),
//     .o_ptadd_xp(ptadd_xp),
//     .o_ptadd_yp(ptadd_yp),
//     .o_ptadd_valid(ptadd_valid)
    
// );

PointAdder ptadd (
    .i_clk(i_clk),
    .i_rst(i_rst),
    // --- io ---
    .i_in_valid(i_in_valid),
    .i_in_data(i_in_data),
    .o_in_ready(o_in_ready),
    // --- Reducer ---
    .i_reduce_ready(reduce_ready),
    .o_reduce_xmp(reduce_xmp),
    .o_reduce_ymp(reduce_ymp),
    .o_reduce_zmp(reduce_zmp),
    .o_reduce_valid(reduce_valid)
);

Reducer reducer(
    .i_clk(i_clk),
    .i_rst(i_rst),
    // --- PointAdder ---
    .i_ptadd_valid(reduce_valid),
    .i_ptadd_xmp(reduce_xmp),
    .i_ptadd_ymp(reduce_ymp),
    .i_ptadd_zmp(reduce_zmp),
    .o_ptadd_ready(reduce_ready),
    // --- DataOut ---
    .i_out_ready(i_out_ready),
    .o_out_valid(o_out_valid),
    .o_out_data(o_out_data)
);

// module Reducer(
//     input i_clk,
//     input i_rst,
//     // --- PointAdder ---
//     input i_ptadd_valid,
//     input [254:0] i_ptadd_xmp,
//     input [254:0] i_ptadd_ymp,
//     input [254:0] i_ptadd_zmp,
//     output o_ptadd_ready,
//     // --- io ---
//     input i_out_ready,
//     output [63:0] o_out_data,
//     output o_out_valid

// );

// DataOut dataout(
//     .i_clk(i_clk),
//     .i_rst(i_rst),
//     // --- IO ---
//     .i_out_ready(i_out_ready),
//     .o_out_data(o_out_data),
//     .o_out_valid(o_out_valid),
//     // --- Reducer ---
//     .i_reducer_valid(dataout_valid),
//     .i_reducer_data(dataout_bits),
//     .o_reducer_ready(dataout_ready)
// );

endmodule
