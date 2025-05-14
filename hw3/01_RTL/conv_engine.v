// ##################################################
// # Convolution Engine                             #
// # ---------------------------------------------- #
// # A 3 stages pipelined convolution engine        #
// # contains only valid control bit for simplicity #
// # assume 4 cycle recieve one batch of data       #
// ##################################################
// `include "./four2oneMux.v"

module conv_engine (
    input i_clk,
    input i_rst_n,
    input i_rst_eng,          // reset all status reg after finish conv
    input [1:0] i_conv_depth, // set depth of conv
    input i_set_eng,          // high for valid control signals, also set enable reg to high
    input [7:0] i_data0,
    input [7:0] i_data1,
    input [7:0] i_data2,
    input [7:0] i_data3,
    input [7:0] i_data4,
    input [7:0] i_data5,
    input [7:0] i_data6,
    input [7:0] i_data7,
    input [7:0] i_data8,
    input [7:0] i_data9,
    input [7:0] i_data10,
    input [7:0] i_data11,
    input [7:0] i_data12,
    input [7:0] i_data13,
    input [7:0] i_data14,
    input [7:0] i_data15,
    input i_in_valid,
    output signed [13:0] o_data0,
    output signed [13:0] o_data1,
    output signed [13:0] o_data2,
    output signed [13:0] o_data3,
    output o_out_valid
);


// stage 0 pipeline regs & wires
reg [7:0] s0_data_r[0:15];
reg [7:0] s0_data_w[0:15];
reg [2:0] s0_status_r, s0_status_w;
wire s0_decre_status_w;

reg [1:0] s0_sel_data_w;
wire [7:0] conv_i0_w, conv_i1_w, conv_i2_w,
           conv_i3_w, conv_i4_w, conv_i5_w,
           conv_i6_w, conv_i7_w, conv_i8_w;

wire [11:0] conv_o0_w, conv_o1_w, conv_o2_w, 
            conv_o3_w, conv_o4_w, conv_o5_w,
            conv_o6_w, conv_o7_w, conv_o8_w;

wire [11:0] sum_01_w, sum_23_w, sum_45_w, sum_67_w;

// stage 1 pipeline regs & wires
wire s1_in_valid;
wire s1_flush;
reg [11:0] s1_data_r[0:4];
reg [11:0] s1_data_w[0:4];
reg [2:0] s1_status_r, s1_status_w;

wire [11:0] sum_0123_w, sum_4567_w, sum_01234567_w, sum_all_w;

// stage 2 pipeline regs & wires
wire s2_in_valid;
wire s2_flush;
reg [11:0] s2_data_r;
reg [11:0] s2_data_w;
reg [2:0] s2_status_r, s2_status_w;

reg [1:0] sel_demux_w;
wire [17:0] acc_data0_w, acc_data1_w, acc_data2_w, acc_data3_w;

// stage 3 pipeline regs & wires
wire s3_in_valid;

reg [17:0] s3_data_r[0:3];
reg [17:0] s3_data_w[0:3];

// system control register
wire comp_one_channel_w;
reg [5:0] conv_depth_r;
reg [5:0] conv_depth_w;
wire conv_done_w; // set when conv_depth_r == 0
reg en_r;  // set by system controller, reset by conv engine
reg en_w;
reg [5:0] depth_w; // decode from i_conv_depth


// ------------------------ stage 0 pipeline ------------------------

// create signals for next pipeline stage
assign s1_in_valid = (s0_status_r > 3'd0);
assign s1_flush    = (s0_status_r == 3'd0) && (s1_status_r == 3'd1);

// update pipeline status regs
assign s0_decre_status_w = (s0_status_r > 3'd0);
always@(*) begin
    if(i_in_valid)             s0_status_w = 3'd4;               // set s0_status_r to 4 when valid data getting in
    else if(s0_decre_status_w) s0_status_w = s0_status_r - 3'd1; // keep decrease status_r when it is larger than 0
    else                       s0_status_w = s0_status_r;        // default : keep the register value
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s0_status_r <= 3'b000;
    else         s0_status_r <= s0_status_w;
end

// update pipeline data regs 
always@(*) begin
    s0_data_w[0] = (i_in_valid) ? i_data0 : s0_data_r[0];
    s0_data_w[1] = (i_in_valid) ? i_data1 : s0_data_r[1];
    s0_data_w[2] = (i_in_valid) ? i_data2 : s0_data_r[2];
    s0_data_w[3] = (i_in_valid) ? i_data3 : s0_data_r[3];
    s0_data_w[4] = (i_in_valid) ? i_data4 : s0_data_r[4];
    s0_data_w[5] = (i_in_valid) ? i_data5 : s0_data_r[5];
    s0_data_w[6] = (i_in_valid) ? i_data6 : s0_data_r[6];
    s0_data_w[7] = (i_in_valid) ? i_data7 : s0_data_r[7];
    s0_data_w[8] = (i_in_valid) ? i_data8 : s0_data_r[8];
    s0_data_w[9] = (i_in_valid) ? i_data9 : s0_data_r[9];
    s0_data_w[10] = (i_in_valid) ? i_data10 : s0_data_r[10];
    s0_data_w[11] = (i_in_valid) ? i_data11 : s0_data_r[11];
    s0_data_w[12] = (i_in_valid) ? i_data12 : s0_data_r[12];
    s0_data_w[13] = (i_in_valid) ? i_data13 : s0_data_r[13];
    s0_data_w[14] = (i_in_valid) ? i_data14 : s0_data_r[14];
    s0_data_w[15] = (i_in_valid) ? i_data15 : s0_data_r[15];
end

integer i;
always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<16; i=i+1) begin
            s0_data_r[i] <= 8'b0;
        end
    end
    else begin
        for(i=0; i<16; i=i+1) begin
            s0_data_r[i] <= s0_data_w[i];
        end
    end
end

// perform dot product
always@(*) begin
    s0_sel_data_w = 2'b00;
    case(s0_status_r)
        3'd4: s0_sel_data_w = 2'b00;
        3'd3: s0_sel_data_w = 2'b01;
        3'd2: s0_sel_data_w = 2'b10;
        3'd1: s0_sel_data_w = 2'b11;
    endcase
end



four2oneMux #(.data_width(8)) mux0(.o_out(conv_i0_w), .i_in0(s0_data_r[0]), .i_in1(s0_data_r[1]), .i_in2(s0_data_r[4]), .i_in3(s0_data_r[5]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux1(.o_out(conv_i1_w), .i_in0(s0_data_r[1]), .i_in1(s0_data_r[2]), .i_in2(s0_data_r[5]), .i_in3(s0_data_r[6]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux2(.o_out(conv_i2_w), .i_in0(s0_data_r[2]), .i_in1(s0_data_r[3]), .i_in2(s0_data_r[6]), .i_in3(s0_data_r[7]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux3(.o_out(conv_i3_w), .i_in0(s0_data_r[4]), .i_in1(s0_data_r[5]), .i_in2(s0_data_r[8]), .i_in3(s0_data_r[9]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux4(.o_out(conv_i4_w), .i_in0(s0_data_r[5]), .i_in1(s0_data_r[6]), .i_in2(s0_data_r[9]), .i_in3(s0_data_r[10]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux5(.o_out(conv_i5_w), .i_in0(s0_data_r[6]), .i_in1(s0_data_r[7]), .i_in2(s0_data_r[10]), .i_in3(s0_data_r[11]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux6(.o_out(conv_i6_w), .i_in0(s0_data_r[8]), .i_in1(s0_data_r[9]), .i_in2(s0_data_r[12]), .i_in3(s0_data_r[13]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux7(.o_out(conv_i7_w), .i_in0(s0_data_r[9]), .i_in1(s0_data_r[10]), .i_in2(s0_data_r[13]), .i_in3(s0_data_r[14]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux8(.o_out(conv_i8_w), .i_in0(s0_data_r[10]), .i_in1(s0_data_r[11]), .i_in2(s0_data_r[14]), .i_in3(s0_data_r[15]), .i_sel(s0_sel_data_w));

conv_shifter conv(.i_data0(conv_i0_w), .i_data1(conv_i1_w), .i_data2(conv_i2_w), 
                  .i_data3(conv_i3_w), .i_data4(conv_i4_w), .i_data5(conv_i5_w), 
                  .i_data6(conv_i6_w), .i_data7(conv_i7_w), .i_data8(conv_i8_w),
                  .o_data0(conv_o0_w), .o_data1(conv_o1_w), .o_data2(conv_o2_w),
                  .o_data3(conv_o3_w), .o_data4(conv_o4_w), .o_data5(conv_o5_w),
                  .o_data6(conv_o6_w), .o_data7(conv_o7_w), .o_data8(conv_o8_w)
                 );

// add the dot product
assign sum_01_w = conv_o0_w + conv_o1_w;
assign sum_23_w = conv_o2_w + conv_o3_w;
assign sum_45_w = conv_o4_w + conv_o5_w;
assign sum_67_w = conv_o6_w + conv_o7_w;

// ------------------------ stage 1 pipeline ------------------------

// create signals for next pipeline stage
assign s2_in_valid = (s1_status_r > 3'd0);
assign s2_flush    = (s1_status_r == 3'd0) && (s2_status_r == 3'd1);

// update pipeline status regs
always@(*) begin
    if(s1_in_valid)   s1_status_w = s0_status_r; // set s1_status_r to s0_status_r when s1_in_valid high
    else if(s1_flush) s1_status_w = 3'd0;
    else              s1_status_w = s1_status_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s1_status_r <= 3'd0;
    else         s1_status_r <= s1_status_w;
end

// update pipeline data regs
always@(*) begin
    s1_data_w[0] = (s1_in_valid) ? sum_01_w  : s1_data_r[0];
    s1_data_w[1] = (s1_in_valid) ? sum_23_w  : s1_data_r[1];
    s1_data_w[2] = (s1_in_valid) ? sum_45_w  : s1_data_r[2];
    s1_data_w[3] = (s1_in_valid) ? sum_67_w  : s1_data_r[3];
    s1_data_w[4] = (s1_in_valid) ? conv_o8_w : s1_data_r[4];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<5; i=i+1) begin
            s1_data_r[i] <= 12'd0;
        end
    end
    else begin
        for(i=0; i<5; i=i+1) begin
            s1_data_r[i] <= s1_data_w[i];
        end
    end
end

// perform add to dot product
assign sum_0123_w = s1_data_r[0] + s1_data_r[1];
assign sum_4567_w = s1_data_r[2] + s1_data_r[3];
assign sum_01234567_w = sum_0123_w + sum_4567_w;
assign sum_all_w = sum_01234567_w + s1_data_r[4];

// ------------------------ stage 2 pipeline ------------------------
// create signals for next pipeline stage
assign s3_in_valid = (s2_status_r > 3'd0);
assign comp_one_channel_w = (s2_status_r == 3'd1); 

// update pipeline status regs
always@(*) begin
    if(s2_in_valid)   s2_status_w = s1_status_r;
    else if(s2_flush) s2_status_w = 3'd0;
    else              s2_status_w = s2_status_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s2_status_r <= 3'd0;
    else         s2_status_r <= s2_status_w;
end

// update pipeline data regs
always@(*) begin
    s2_data_w = (s2_in_valid) ? sum_all_w : s2_data_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s2_data_r <= 12'd0;
    else         s2_data_r <= s2_data_w;
end

// perform accumulation with previous dot product sum results
always@(*) begin
    sel_demux_w = 2'b00;
    case(s2_status_r)
        3'd4: sel_demux_w = 2'b00;
        3'd3: sel_demux_w = 2'b01;
        3'd2: sel_demux_w = 2'b10;
        3'd1: sel_demux_w = 2'b11;
    endcase
end

// perform accumulation to previous channel
assign acc_data0_w = s3_data_r[0] + {6'd0, s2_data_r};
assign acc_data1_w = s3_data_r[1] + {6'd0, s2_data_r};
assign acc_data2_w = s3_data_r[2] + {6'd0, s2_data_r};
assign acc_data3_w = s3_data_r[3] + {6'd0, s2_data_r};

// ------------------------ stage 3 pipeline ------------------------

// update pipeline data regs
always@(*) begin
    s3_data_w[0] = (s3_in_valid && (sel_demux_w == 2'd0)) ? acc_data0_w : ((i_rst_eng) ? 18'd0 : s3_data_r[0]);
    s3_data_w[1] = (s3_in_valid && (sel_demux_w == 2'd1)) ? acc_data1_w : ((i_rst_eng) ? 18'd0 : s3_data_r[1]);
    s3_data_w[2] = (s3_in_valid && (sel_demux_w == 2'd2)) ? acc_data2_w : ((i_rst_eng) ? 18'd0 : s3_data_r[2]);
    s3_data_w[3] = (s3_in_valid && (sel_demux_w == 2'd3)) ? acc_data3_w : ((i_rst_eng) ? 18'd0 : s3_data_r[3]);
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<4; i=i+1) begin
            s3_data_r[i] <= 18'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s3_data_r[i] <= s3_data_w[i];
        end
    end
end


// ------------------------- system status register ----------------------------
assign conv_done_w = (conv_depth_r == 6'd0);
assign o_out_valid = conv_done_w && en_r;

always@(*) begin
    depth_w = 6'd32;
    case(i_conv_depth)
        2'b00: depth_w = 6'd8;
        2'b01: depth_w = 6'd16;
        2'b10: depth_w = 6'd32;
    endcase
end

// update depth register
always@(*) begin
    if(i_rst_eng)          conv_depth_w = 6'd0;
    else if(i_set_eng)        conv_depth_w = depth_w;
    else if(comp_one_channel_w) conv_depth_w = (conv_depth_r - 6'd1);
    else                        conv_depth_w = conv_depth_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) conv_depth_r <= 6'd0;
    else         conv_depth_r <= conv_depth_w;
end

// update enable register
always@(*) begin
    if(i_set_eng)        en_w = 1'b1;
    else if(conv_done_w) en_w = 1'b0;
    else                 en_w = en_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) en_r <= 1'b0;
    else         en_r <= en_w;
end

// ------------------- data output --------------------
assign o_data0 = (s3_data_r[0][3] == 1'b1) ? (s3_data_r[0][17:4] + 14'd1) : s3_data_r[0][17:4];
assign o_data1 = (s3_data_r[1][3] == 1'b1) ? (s3_data_r[1][17:4] + 14'd1) : s3_data_r[1][17:4];
assign o_data2 = (s3_data_r[2][3] == 1'b1) ? (s3_data_r[2][17:4] + 14'd1) : s3_data_r[2][17:4];
assign o_data3 = (s3_data_r[3][3] == 1'b1) ? (s3_data_r[3][17:4] + 14'd1) : s3_data_r[3][17:4];


endmodule


module conv_shifter (
    input [7:0] i_data0,
    input [7:0] i_data1,
    input [7:0] i_data2,
    input [7:0] i_data3,
    input [7:0] i_data4,
    input [7:0] i_data5,
    input [7:0] i_data6,
    input [7:0] i_data7,
    input [7:0] i_data8,
    output [11:0] o_data0,
    output [11:0] o_data1,
    output [11:0] o_data2,
    output [11:0] o_data3,
    output [11:0] o_data4,
    output [11:0] o_data5,
    output [11:0] o_data6,
    output [11:0] o_data7,
    output [11:0] o_data8
);

assign o_data0 = {i_data0, 4'b0000} >> 4; // x(1/16)
assign o_data1 = {i_data1, 4'b0000} >> 3; // x(1/8)
assign o_data2 = {i_data2, 4'b0000} >> 4; // x(1/16)
assign o_data3 = {i_data3, 4'b0000} >> 3; // x(1/8)
assign o_data4 = {i_data4, 4'b0000} >> 2; // x(1/4)
assign o_data5 = {i_data5, 4'b0000} >> 3; // x(1/8)
assign o_data6 = {i_data6, 4'b0000} >> 4; // x(1/16)
assign o_data7 = {i_data7, 4'b0000} >> 3; // x(1/8)
assign o_data8 = {i_data8, 4'b0000} >> 4; // x(1/16)

endmodule