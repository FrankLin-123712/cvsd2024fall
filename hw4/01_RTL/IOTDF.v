`timescale 1ns/10ps

// include files for spyglass checking
// `include "./SystemController.v"
// `include "./DataLoader.v"
// `include "./EnDecryptCrcgen.v"
// `include "./Comparator.v"

module IOTDF( clk, rst, in_en, iot_in, fn_sel, busy, valid, iot_out);
input          clk;
input          rst;
input          in_en;
input  [7:0]   iot_in;
input  [2:0]   fn_sel;
output         busy;
output         valid;
output [127:0] iot_out;


// ----------- wires and regs --------------
// data path signals 
wire dl_dready;          // control signals to data loader
wire dl_dvalid;          // status signals from data loader
wire [127:0] dl_iot_in;  // data out

wire cr_en;              // control signals to encrypter / decrypter / crc_generator
wire [1:0] cr_sel_fn;    // control signals to encrypter / decrypter / crc_generator
wire cr_done;            // status signals from encrypter/ decrypter / crc_generator
reg [127:0] cr_iot_in;   // data in
wire [127:0] cr_iot_out; // data out

wire comp_set_mode, comp_sel_fn, comp_en; // control signals to comparator
wire comp_setted, comp_ready, comp_done;  // status signals from comparator
reg [127:0] comp_iot_in;                  // data in
wire [127:0] comp_iot_out;                // data out

wire sel_iot_eng; // control signals for selecting iot_in to and iot_out from
reg [127:0] iot_out_w;

// ---------- system controller ----------
SystemController system_controller(
    // ------- io -------
    .i_clk(clk), .i_rst(rst),
    .i_en(in_en), .i_sel_fn(fn_sel),
    .o_valid(valid),
    
    // select engine
    .o_sel_iot_eng(sel_iot_eng),

    // data loader
    .o_dl_dready(dl_dready),
    .i_dl_dvalid(dl_dvalid),

    // encrypter / decrypter / crc_generator
    .o_cr_en(cr_en),
    .o_cr_sel_fn(cr_sel_fn),
    .i_cr_done(cr_done),
    
    // comparator
    .o_comp_set_mode(comp_set_mode),
    .o_comp_sel_fn(comp_sel_fn),
    .i_comp_setted(comp_setted),
    .o_comp_en(comp_en),
    .i_comp_ready(comp_ready),
    .i_comp_done(comp_done)
);

// ---------- data loader ------------
DataLoader data_loader(
    .i_clk(clk), .i_rst(rst),
    .i_en(in_en), .i_iot_in(iot_in),
    .o_busy(busy),

    .i_dready(dl_dready),
    .o_iot_out(dl_iot_in),
    .o_dvalid(dl_dvalid)
);

// ---------- select iot_in to which engine -----------
always@(*) begin
    // default assignment
    cr_iot_in   = 128'd0;
    comp_iot_in = 128'd0;

    case(sel_iot_eng)
        1'd0: cr_iot_in   = dl_iot_in;
        1'd1: comp_iot_in = dl_iot_in;
    endcase
end

// ---------- encrypter -----------
EnDecryptCrcgen crypt_crc(
    .i_clk(clk), .i_rst(rst),
    .i_en(cr_en), .i_sel_fn(cr_sel_fn),
    .i_iot_in(cr_iot_in),
    .o_done(cr_done),
    .o_iot_out(cr_iot_out)
);

// ---------- comparator ----------
Comparator comparator0(
    .i_clk(clk),
    .i_rst(rst),
    .i_set_mode(comp_set_mode),
    .i_sel_fn(comp_sel_fn),
    .o_setted(comp_setted),
    .i_en(comp_en),
    .i_iot_in(comp_iot_in),
    .o_ready(comp_ready),
    .o_done(comp_done),
    .o_iot_out(comp_iot_out)
);


// ---------- select iot out from 3 engine ----------
always@(*) begin
    iot_out_w = 128'd0;
    case(sel_iot_eng)
        1'd0: iot_out_w = cr_iot_out;
        1'd1: iot_out_w = comp_iot_out;
    endcase
end
assign iot_out = iot_out_w;

endmodule
