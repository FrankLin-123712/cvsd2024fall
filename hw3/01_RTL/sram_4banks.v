// ##################################################
// # SRAM Banks                                     #
// # ---------------------------------------------- #
// # Four sram blocks consist of a SRAM including a #
// # controller for streaming out data with 3 stage #
// # pipeline                                       #
// ##################################################
// `include "./sram_bank_controller.v"

`define RESET_MODE  3'd0
`define LOAD_MODE   3'd1
`define DISP_MODE   3'd2
`define CONV_MODE   3'd3
`define SOBEL_MODE  3'd4
`define MEDIAN_MODE 3'd5


module sram_4banks(
    input i_clk,
    input i_rst_n,
    // sram control signals
    input [2:0] i_mode,
    input [3:0] i_ox,
    input [3:0] i_oy,
    input [1:0] i_depth,
    input i_inst_valid,
    output o_inst_ready,
    // sram input data
    input [7:0] i_in_data,
    input i_in_data_valid,
    output o_in_data_ready,
    // sram output data for display
    output [7:0] o_disp_data,
    output o_disp_valid,
    // sram output data
    output [7:0] o_out_data0,
    output [7:0] o_out_data1,
    output [7:0] o_out_data2,
    output [7:0] o_out_data3,
    output [7:0] o_out_data4,
    output [7:0] o_out_data5,
    output [7:0] o_out_data6,
    output [7:0] o_out_data7,
    output [7:0] o_out_data8,
    output [7:0] o_out_data9,
    output [7:0] o_out_data10,
    output [7:0] o_out_data11,
    output [7:0] o_out_data12,
    output [7:0] o_out_data13,
    output [7:0] o_out_data14,
    output [7:0] o_out_data15,
    output o_out_data_valid
);

// --------- wires and regs ---------
// inst registers
reg [2:0] mode_r, mode_w;
reg [3:0] ox_r, ox_w;
reg [3:0] oy_r, oy_w;
reg [1:0] depth_r, depth_w;

wire rst_inst_w;
wire wen_inst_w;
wire [5:0] depth_when_done_w;

// system counters
reg [11:0] addr_ctr_r, addr_ctr_w;      // for load data from outside the core
reg [5:0] channel_ctr_r, channel_ctr_w; // for load compute data or load display data
reg [1:0] row_ctr_r, row_ctr_w;         // for load compute data or load display data

wire rst_addr_ctr_w, rst_channel_ctr_w, rst_row_ctr_w;
wire incr_addr_ctr_w, incr_channel_ctr_w, incr_row_ctr_w;

wire addr_done_load_w;   // high when addr ctr equals to 2048 when loading data
wire row_done_disp_w;    // high when row equals to 1 when displaying
wire row_done_read_w;    // high when row equals to 3 when loading compute data
wire channel_done_w;     // high when channel equals to depth_r when displaying or loading compute data
reg [2:0] row_iter_num_w;     // the iteration number of row, would be passed down along pipelines.

// addr generator signals
wire addr_gen_mode; // 0 for display, 1 for load compute data
wire [10:0] gen0_addr, gen1_addr, gen2_addr, gen3_addr;
wire [3:0] oob_flag;

// addr router signals
wire [8:0] bank0_raddr, bank1_raddr, bank2_raddr, bank3_raddr;
wire [2:0] bank0_portnum, bank1_portnum, bank2_portnum, bank3_portnum;

// bank control signals
wire [3:0] cen, wen;
wire [8:0] b0_a, b1_a, b2_a, b3_a;
wire [7:0] b0_q, b1_q, b2_q, b3_q;

// data router signals
wire [7:0] port0_rdata, port1_rdata, port2_rdata, port3_rdata;

// pipeline registers
reg [2:0] s1_portnum_r[0:3]; 
reg [2:0] s1_portnum_w[0:3];
wire rst_portnum_r, wen_portnum_r;

reg [2:0] s1_csr_r, s1_csr_w;
wire wen_s1_csr;

reg [7:0] disp_buf_r, disp_buf_w;
wire wen_disp_buf, disp_sel;

reg [2:0] s2_csr_r, s2_csr_w;
wire s2_flush, s2_valid;
wire pipeline_done;

reg [7:0] s2_compute_data_r[0:15];
reg [7:0] s2_compute_data_w[0:15];
reg [15:0] compute_data_sel_mask;

// ------------------- controller -------------------------
sram_bank_controller controller(
    .i_clk(i_clk), .i_rst_n(i_rst_n), 
    .i_mode(i_mode), .i_inst_valid(i_inst_valid), .o_inst_ready(o_inst_ready),
    .i_in_data_valid(i_in_data_valid), .o_in_data_ready(o_in_data_ready), 
    .o_disp_valid(o_disp_valid),
    .i_load_data_bank(addr_ctr_r[1:0]), .i_addr_done_load(addr_done_load_w), 
    .i_row_done_disp(row_done_disp_w), .i_channel_done(channel_done_w), .i_start_bank(gen0_addr[1:0]), 
    .i_row_done_read(row_done_read_w), .i_oob_flag(oob_flag), .i_pipeline_done(pipeline_done),
    .o_rst_addr_ctr(rst_addr_ctr_w), .o_incr_addr_ctr(incr_addr_ctr_w), 
    .o_sram_cen(cen), .o_sram_wen(wen), 
    .o_rst_inst(rst_inst_w), .o_wen_inst(wen_inst_w), 
    .o_addr_gen_mode(addr_gen_mode), 
    .o_rst_channel_ctr(rst_channel_ctr_w), .o_incr_channel_ctr(incr_channel_ctr_w), 
    .o_rst_row_ctr(rst_row_ctr_w), .o_incr_row_ctr(incr_row_ctr_w), 
    .o_rst_portnum_r(rst_portnum_r), .o_wen_portnum_r(wen_portnum_r), 
    .o_wen_s1_csr(wen_s1_csr), 
    .o_wen_disp_buf(wen_disp_buf), .o_disp_sel(disp_sel)
);

// ------------------- data path -------------------------
// ############## inst registers ##############

// mode_r
always@(*) begin
    if(rst_inst_w)      mode_w = `RESET_MODE;
    else if(wen_inst_w) mode_w = i_mode;
    else                mode_w = mode_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        mode_r <= `RESET_MODE;
    end
    else begin
        mode_r <= mode_w;
    end
end

// ox_r
always@(*) begin
    if(rst_inst_w)      ox_w = 4'd0;
    else if(wen_inst_w) ox_w = i_ox;
    else                ox_w = ox_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        ox_r <= 4'd0;
    end
    else begin
        ox_r <= ox_w;
    end
end

// oy_r
always@(*) begin
    if(rst_inst_w)      oy_w = 4'd0;
    else if(wen_inst_w) oy_w = i_oy;
    else                oy_w = oy_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        oy_r <= 4'd0;
    end
    else begin
        oy_r <= oy_w;
    end
end

// depth_r
always@(*) begin
    if(rst_inst_w)      depth_w = 2'd0;
    else if(wen_inst_w) depth_w = i_depth;
    else                depth_w = depth_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        depth_r <= `RESET_MODE;
    end
    else begin
        depth_r <= depth_w;
    end
end

assign depth_when_done_w = (mode_r == `CONV_MODE || mode_r == `DISP_MODE) ? (6'd8 << depth_r) : ((mode_r == `MEDIAN_MODE || mode_r == `SOBEL_MODE) ? 6'd4 : 6'd0);

// ############## system coutner ##############
// addr_ctr_r
always@(*) begin
    if(rst_addr_ctr_w)       addr_ctr_w = 12'd0;
    else if(incr_addr_ctr_w) addr_ctr_w = addr_ctr_r + 12'd1;
    else                     addr_ctr_w = addr_ctr_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        addr_ctr_r <= 12'd0;
    end
    else begin
        addr_ctr_r <= addr_ctr_w;
    end
end

assign addr_done_load_w = (addr_ctr_r == 12'd2048);

// channel_ctr
always@(*) begin
    if(rst_channel_ctr_w)       channel_ctr_w = 6'd0;
    else if(incr_channel_ctr_w) channel_ctr_w = channel_ctr_r + 6'd1;
    else                        channel_ctr_w = channel_ctr_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        channel_ctr_r <= 6'd0;
    end
    else begin
        channel_ctr_r <= channel_ctr_w;
    end
end

assign channel_done_w = (channel_ctr_r == depth_when_done_w);

// row_ctr
always@(*) begin
    if(rst_row_ctr_w)       row_ctr_w = 2'd0;
    else if(incr_row_ctr_w) row_ctr_w = row_ctr_r + 2'd1;
    else                    row_ctr_w = row_ctr_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        row_ctr_r <= 2'd0;
    end
    else begin
        row_ctr_r <= row_ctr_w;
    end
end

assign row_done_disp_w = (row_ctr_r == 2'd1);
assign row_done_read_w = (row_ctr_r == 2'd3);

always@(*) begin
    row_iter_num_w = 3'd0;
    case(row_ctr_r)
        2'd0: row_iter_num_w = 3'd4;
        2'd1: row_iter_num_w = 3'd3;
        2'd2: row_iter_num_w = 3'd2;
        2'd3: row_iter_num_w = 3'd1;
    endcase
end

// ############## stage 0 ##############
// 4 addr generator
wire [1:0] addr_gen0_id_w = 2'd0;
wire [1:0] addr_gen1_id_w = 2'd1;
wire [1:0] addr_gen2_id_w = 2'd2;
wire [1:0] addr_gen3_id_w = 2'd3;

addr_gen addr_gen0(.i_mode(addr_gen_mode), .i_channel(channel_ctr_r), .i_row(row_ctr_r), 
                    .i_ox(ox_r), .i_oy(oy_r), .i_gen_id(addr_gen0_id_w),
                    .o_addr(gen0_addr), .o_oob_flag(oob_flag[0]));

addr_gen addr_gen1(.i_mode(addr_gen_mode), .i_channel(channel_ctr_r), .i_row(row_ctr_r), 
                    .i_ox(ox_r), .i_oy(oy_r), .i_gen_id(addr_gen1_id_w),
                    .o_addr(gen1_addr), .o_oob_flag(oob_flag[1]));

addr_gen addr_gen2(.i_mode(addr_gen_mode), .i_channel(channel_ctr_r), .i_row(row_ctr_r), 
                    .i_ox(ox_r), .i_oy(oy_r), .i_gen_id(addr_gen2_id_w),
                    .o_addr(gen2_addr), .o_oob_flag(oob_flag[2]));

addr_gen addr_gen3(.i_mode(addr_gen_mode), .i_channel(channel_ctr_r), .i_row(row_ctr_r), 
                    .i_ox(ox_r), .i_oy(oy_r), .i_gen_id(addr_gen3_id_w),
                    .o_addr(gen3_addr), .o_oob_flag(oob_flag[3]));

// address router
addr_router addr_router0(
    .gen0_addr(gen0_addr), .gen1_addr(gen1_addr), .gen2_addr(gen2_addr), .gen3_addr(gen3_addr), 
    .oob_flag(oob_flag), .bank0_addr(bank0_raddr), .bank1_addr(bank1_raddr), .bank2_addr(bank2_raddr), .bank3_addr(bank3_raddr), 
    .bank0_portnum(bank0_portnum), .bank1_portnum(bank1_portnum), .bank2_portnum(bank2_portnum), .bank3_portnum(bank3_portnum)
);

assign b0_a = (wen[0]) ? bank0_raddr : addr_ctr_r[10:2];
assign b1_a = (wen[1]) ? bank1_raddr : addr_ctr_r[10:2];
assign b2_a = (wen[2]) ? bank2_raddr : addr_ctr_r[10:2];
assign b3_a = (wen[3]) ? bank3_raddr : addr_ctr_r[10:2];



// ############## stage 1 ##############

// s1_csr
always@(*) begin
    if(wen_s1_csr) s1_csr_w = row_iter_num_w;
    else           s1_csr_w = 3'd0;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s1_csr_r <= 3'd0;
    else         s1_csr_r <= s1_csr_w;
end

assign s2_valid = (s1_csr_r > 3'd0);
assign s2_flush = (s1_csr_r == 3'd0) && (s2_csr_r == 3'd1);

// portnum_r
integer i;
always@(*) begin
    if(rst_portnum_r) begin
        for(i=0; i<4; i=i+1) begin
            s1_portnum_w[i] = 3'd0;
        end
    end
    else if(wen_portnum_r) begin
        s1_portnum_w[0] = bank0_portnum;
        s1_portnum_w[1] = bank1_portnum;
        s1_portnum_w[2] = bank2_portnum;
        s1_portnum_w[3] = bank3_portnum;
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s1_portnum_w[i] = s1_portnum_r[i];
        end
    end
end


always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<4; i=i+1) begin
            s1_portnum_r[i] <= 3'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s1_portnum_r[i] <= s1_portnum_w[i];
        end
    end
end


// SRAM banks
sram_512x8 sram_b0(.CLK(i_clk), .CEN(cen[0]), .WEN(wen[0]), .A(b0_a), .D(i_in_data), .Q(b0_q));
sram_512x8 sram_b1(.CLK(i_clk), .CEN(cen[1]), .WEN(wen[1]), .A(b1_a), .D(i_in_data), .Q(b1_q));
sram_512x8 sram_b2(.CLK(i_clk), .CEN(cen[2]), .WEN(wen[2]), .A(b2_a), .D(i_in_data), .Q(b2_q));
sram_512x8 sram_b3(.CLK(i_clk), .CEN(cen[3]), .WEN(wen[3]), .A(b3_a), .D(i_in_data), .Q(b3_q));


// data router
data_router data_router0(
    .bank0_portnum(s1_portnum_r[0]), .bank1_portnum(s1_portnum_r[1]), 
    .bank2_portnum(s1_portnum_r[2]), .bank3_portnum(s1_portnum_r[3]), 
    .bank0_rdata(b0_q), .bank1_rdata(b1_q), .bank2_rdata(b2_q), .bank3_rdata(b3_q), 
    .port0_rdata(port0_rdata), .port1_rdata(port1_rdata), .port2_rdata(port2_rdata), .port3_rdata(port3_rdata)
);

// data path - display
always@(*) begin
    disp_buf_w = (wen_disp_buf) ? port1_rdata : disp_buf_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) disp_buf_r <= 8'd0;
    else         disp_buf_r <= disp_buf_w; 
end

assign o_disp_data = (disp_sel) ? disp_buf_r : port0_rdata;

// ############## stage 2 ##############

// s2_csr_r
always@(*) begin
    if(s2_flush)      s2_csr_w = 3'd0;
    else if(s2_valid) s2_csr_w = s1_csr_r;
    else              s2_csr_w = s2_csr_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s2_csr_r <= 3'd0;
    else         s2_csr_r <= s2_csr_w;
end



// data array for computing
always@(*) begin
    compute_data_sel_mask = 16'h0000;
    case(s1_csr_r)
        3'd4: compute_data_sel_mask = 16'h000f;
        3'd3: compute_data_sel_mask = 16'h00f0;
        3'd2: compute_data_sel_mask = 16'h0f00;
        3'd1: compute_data_sel_mask = 16'hf000;
    endcase
end

always@(*) begin
    if(s2_valid) begin
        s2_compute_data_w[0]  = (compute_data_sel_mask[0])  ? port0_rdata : s2_compute_data_r[0];
        s2_compute_data_w[1]  = (compute_data_sel_mask[1])  ? port1_rdata : s2_compute_data_r[1];
        s2_compute_data_w[2]  = (compute_data_sel_mask[2])  ? port2_rdata : s2_compute_data_r[2];
        s2_compute_data_w[3]  = (compute_data_sel_mask[3])  ? port3_rdata : s2_compute_data_r[3];
        s2_compute_data_w[4]  = (compute_data_sel_mask[4])  ? port0_rdata : s2_compute_data_r[4];
        s2_compute_data_w[5]  = (compute_data_sel_mask[5])  ? port1_rdata : s2_compute_data_r[5];
        s2_compute_data_w[6]  = (compute_data_sel_mask[6])  ? port2_rdata : s2_compute_data_r[6];
        s2_compute_data_w[7]  = (compute_data_sel_mask[7])  ? port3_rdata : s2_compute_data_r[7];
        s2_compute_data_w[8]  = (compute_data_sel_mask[8])  ? port0_rdata : s2_compute_data_r[8];
        s2_compute_data_w[9]  = (compute_data_sel_mask[9])  ? port1_rdata : s2_compute_data_r[9];
        s2_compute_data_w[10] = (compute_data_sel_mask[10]) ? port2_rdata : s2_compute_data_r[10];
        s2_compute_data_w[11] = (compute_data_sel_mask[11]) ? port3_rdata : s2_compute_data_r[11];
        s2_compute_data_w[12] = (compute_data_sel_mask[12]) ? port0_rdata : s2_compute_data_r[12];
        s2_compute_data_w[13] = (compute_data_sel_mask[13]) ? port1_rdata : s2_compute_data_r[13];
        s2_compute_data_w[14] = (compute_data_sel_mask[14]) ? port2_rdata : s2_compute_data_r[14];
        s2_compute_data_w[15] = (compute_data_sel_mask[15]) ? port3_rdata : s2_compute_data_r[15];
    end
    else begin
        for(i=0; i<16; i=i+1) begin
            s2_compute_data_w[i] = s2_compute_data_r[i];
        end
    end


end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<16; i=i+1) begin
            s2_compute_data_r[i] <= 8'd0;
        end
    end
    else begin
        for(i=0; i<16; i=i+1) begin
            s2_compute_data_r[i] <= s2_compute_data_w[i];
        end
    end
end

assign pipeline_done = (s2_csr_r == 3'd0);
assign o_out_data_valid = (s2_csr_r == 3'd1);


assign o_out_data0 = s2_compute_data_r[0];
assign o_out_data1 = s2_compute_data_r[1];
assign o_out_data2 = s2_compute_data_r[2];
assign o_out_data3 = s2_compute_data_r[3];
assign o_out_data4 = s2_compute_data_r[4];
assign o_out_data5 = s2_compute_data_r[5];
assign o_out_data6 = s2_compute_data_r[6];
assign o_out_data7 = s2_compute_data_r[7];
assign o_out_data8 = s2_compute_data_r[8];
assign o_out_data9 = s2_compute_data_r[9];
assign o_out_data10 = s2_compute_data_r[10];
assign o_out_data11 = s2_compute_data_r[11];
assign o_out_data12 = s2_compute_data_r[12];
assign o_out_data13 = s2_compute_data_r[13];
assign o_out_data14 = s2_compute_data_r[14];
assign o_out_data15 = s2_compute_data_r[15];

endmodule


module addr_gen(
    input i_mode, // 0 for display, 1 for compute
    input [5:0] i_channel,
    input [1:0] i_row,
    input [3:0] i_ox,
    input [3:0] i_oy,
    input [1:0] i_gen_id, // the address generator id.
    output [10:0] o_addr,
    output o_oob_flag // out of bound flag
);

reg [10:0] addr_w;
reg signed [3:0] row_idx_w;
reg signed [3:0] col_idx_w;
reg oob_flag_w;

always@(*) begin
    if(i_mode) begin // load compute data
        row_idx_w  = i_ox - 4'd1 + {2'b00, i_row};
        col_idx_w  = i_oy - 4'd1 + {2'b00, i_gen_id};
        oob_flag_w = !(((row_idx_w <= $signed(4'd7)) && (row_idx_w >= $signed(4'd0))) && 
                       ((col_idx_w <= $signed(4'd7)) && (col_idx_w >= $signed(4'd0))));
        addr_w     = (oob_flag_w) ? 11'd0 : ({5'd0, i_channel} << 6) + ({7'd0, row_idx_w} << 3) + {7'd0, col_idx_w};
    end
    else begin     // load display data
        row_idx_w  = i_ox + {2'b00, i_row};
        col_idx_w  = i_oy + {2'b00, i_gen_id};
        oob_flag_w = 0;
        addr_w     = ({5'd0, i_channel} << 6) + ({7'd0, row_idx_w} << 3) + {7'd0, col_idx_w};
    end
end

assign o_oob_flag = oob_flag_w;
assign o_addr = addr_w;

endmodule

module addr_router(
    input [10:0] gen0_addr,
    input [10:0] gen1_addr,
    input [10:0] gen2_addr,
    input [10:0] gen3_addr,
    input [3:0] oob_flag,
    output [8:0] bank0_addr,
    output [8:0] bank1_addr,
    output [8:0] bank2_addr,
    output [8:0] bank3_addr,
    output [2:0] bank0_portnum,
    output [2:0] bank1_portnum,
    output [2:0] bank2_portnum,
    output [2:0] bank3_portnum
);

wire [2:0] gen0_bank_idx;
wire [2:0] gen1_bank_idx;
wire [2:0] gen2_bank_idx;
wire [2:0] gen3_bank_idx;

reg [8:0] addr_w[0:3];
reg [2:0] portnum_w[0:3];

assign gen0_bank_idx = (oob_flag[0]) ? 3'b111 : {1'b0, gen0_addr[1:0]};
assign gen1_bank_idx = (oob_flag[1]) ? 3'b111 : {1'b0, gen1_addr[1:0]};
assign gen2_bank_idx = (oob_flag[2]) ? 3'b111 : {1'b0, gen2_addr[1:0]};
assign gen3_bank_idx = (oob_flag[3]) ? 3'b111 : {1'b0, gen3_addr[1:0]};

// output bank 0
always@(*) begin
    addr_w[0]    = 9'd0;
    portnum_w[0] = 3'b111; // the address out of bound. assign 111 to indicate invalid.
    case(3'b000)
        gen0_bank_idx: begin // gen0 --> bank0
            addr_w[0]    = gen0_addr[10:2];
            portnum_w[0] = 3'd0;
        end
        gen1_bank_idx: begin // gen1 --> bank0
            addr_w[0]    = gen1_addr[10:2];
            portnum_w[0] = 3'd1;
        end
        gen2_bank_idx: begin // gen2 --> bank0
            addr_w[0]    = gen2_addr[10:2];
            portnum_w[0] = 3'd2;
        end
        gen3_bank_idx: begin // gen3 --> bank0
            addr_w[0]    = gen3_addr[10:2];
            portnum_w[0] = 3'd3;
        end
    endcase
end

// output bank 1
always@(*) begin
    addr_w[1]    = 9'd0;
    portnum_w[1] = 3'b111; // the address out of bound. assign 111 to indicate invalid.
    case(3'b001)
        gen0_bank_idx: begin // gen0 --> bank1
            addr_w[1]    = gen0_addr[10:2];
            portnum_w[1] = 3'd0;
        end
        gen1_bank_idx: begin // gen1 --> bank1
            addr_w[1]    = gen1_addr[10:2];
            portnum_w[1] = 3'd1;
        end
        gen2_bank_idx: begin // gen2 --> bank1
            addr_w[1]    = gen2_addr[10:2];
            portnum_w[1] = 3'd2;
        end
        gen3_bank_idx: begin // gen3 --> bank1
            addr_w[1]    = gen3_addr[10:2];
            portnum_w[1] = 3'd3;
        end
    endcase
end

// output bank 2
always@(*) begin
    addr_w[2]    = 9'd0;
    portnum_w[2] = 3'b111; // the address out of bound. assign 111 to indicate invalid.
    case(3'b010)
        gen0_bank_idx: begin // gen0 --> bank2
            addr_w[2]    = gen0_addr[10:2];
            portnum_w[2] = 3'd0;
        end
        gen1_bank_idx: begin // gen1 --> bank2
            addr_w[2]    = gen1_addr[10:2];
            portnum_w[2] = 3'd1;
        end
        gen2_bank_idx: begin // gen2 --> bank2
            addr_w[2]    = gen2_addr[10:2];
            portnum_w[2] = 3'd2;
        end
        gen3_bank_idx: begin // gen3 --> bank2
            addr_w[2]    = gen3_addr[10:2];
            portnum_w[2] = 3'd3;
        end
    endcase
end

// output bank 3
always@(*) begin
    addr_w[3]    = 9'd0;
    portnum_w[3] = 3'b111; // the address out of bound. assign 111 to indicate invalid.
    case(3'b011)
        gen0_bank_idx: begin // gen0 --> bank3
            addr_w[3]    = gen0_addr[10:2];
            portnum_w[3] = 3'd0;
        end
        gen1_bank_idx: begin // gen1 --> bank3
            addr_w[3]    = gen1_addr[10:2];
            portnum_w[3] = 3'd1;
        end
        gen2_bank_idx: begin // gen2 --> bank3
            addr_w[3]    = gen2_addr[10:2];
            portnum_w[3] = 3'd2;
        end
        gen3_bank_idx: begin // gen3 --> bank3
            addr_w[3]    = gen3_addr[10:2];
            portnum_w[3] = 3'd3;
        end
    endcase
end

assign bank0_addr = addr_w[0];
assign bank1_addr = addr_w[1];
assign bank2_addr = addr_w[2];
assign bank3_addr = addr_w[3];

assign bank0_portnum = portnum_w[0];
assign bank1_portnum = portnum_w[1];
assign bank2_portnum = portnum_w[2];
assign bank3_portnum = portnum_w[3];

endmodule

module data_router(
    input [2:0] bank0_portnum,
    input [2:0] bank1_portnum,
    input [2:0] bank2_portnum,
    input [2:0] bank3_portnum,
    input [7:0] bank0_rdata,
    input [7:0] bank1_rdata,
    input [7:0] bank2_rdata,
    input [7:0] bank3_rdata,
    output [7:0] port0_rdata,
    output [7:0] port1_rdata,
    output [7:0] port2_rdata,
    output [7:0] port3_rdata
);

reg [7:0] port_rdata_w[0:3];

// ouput port 0
always@(*) begin
    port_rdata_w[0] = 8'd0;
    case(3'd0)
        bank0_portnum: begin // bank0 --> port0
            port_rdata_w[0] = bank0_rdata;
        end
        bank1_portnum: begin // bank1 --> port0
            port_rdata_w[0] = bank1_rdata;
        end
        bank2_portnum: begin // bank2 --> port0
            port_rdata_w[0] = bank2_rdata;
        end
        bank3_portnum: begin // bank3 --> port0
            port_rdata_w[0] = bank3_rdata;
        end
    endcase
end

// ouput port 1
always@(*) begin
    port_rdata_w[1] = 8'd0;
    case(3'd1)
        bank0_portnum: begin // bank0 --> port1
            port_rdata_w[1] = bank0_rdata;
        end
        bank1_portnum: begin // bank1 --> port1
            port_rdata_w[1] = bank1_rdata;
        end
        bank2_portnum: begin // bank2 --> port1
            port_rdata_w[1] = bank2_rdata;
        end
        bank3_portnum: begin // bank3 --> port1
            port_rdata_w[1] = bank3_rdata;
        end
    endcase
end

// ouput port 2
always@(*) begin
    port_rdata_w[2] = 8'd0;
    case(3'd2)
        bank0_portnum: begin // bank0 --> port2
            port_rdata_w[2] = bank0_rdata;
        end
        bank1_portnum: begin // bank1 --> port2
            port_rdata_w[2] = bank1_rdata;
        end
        bank2_portnum: begin // bank2 --> port2
            port_rdata_w[2] = bank2_rdata;
        end
        bank3_portnum: begin // bank3 --> port2
            port_rdata_w[2] = bank3_rdata;
        end
    endcase
end

// ouput port 3
always@(*) begin
    port_rdata_w[3] = 8'd0;
    case(3'd3)
        bank0_portnum: begin // bank0 --> port3
            port_rdata_w[3] = bank0_rdata;
        end
        bank1_portnum: begin // bank1 --> port3
            port_rdata_w[3] = bank1_rdata;
        end
        bank2_portnum: begin // bank2 --> port3
            port_rdata_w[3] = bank2_rdata;
        end
        bank3_portnum: begin // bank3 --> port3
            port_rdata_w[3] = bank3_rdata;
        end
    endcase
end

assign port0_rdata = port_rdata_w[0];
assign port1_rdata = port_rdata_w[1];
assign port2_rdata = port_rdata_w[2];
assign port3_rdata = port_rdata_w[3];

endmodule