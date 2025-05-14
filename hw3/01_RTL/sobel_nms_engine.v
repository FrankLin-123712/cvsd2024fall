// ##################################################
// # Sobel NMS Engine                               #
// # ---------------------------------------------- #
// # A 4 stages pipelined sobel NMS engine          #
// # contains only valid control bit for simplicity #
// # assume 4 cycle recieve one batch of data       #
// ##################################################
// `include "./four2oneMux"

module sobel_nms_engine(
    input i_clk,
    input i_rst_n,
    input i_rst_eng,   // reset reset depth to 0
    input i_set_eng,   // set depth to 4
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
    output o_out_valid,
    output o_done
);

// stage 0 pipeline regs & wires
reg [7:0] s0_data_r[0:15];
reg [7:0] s0_data_w[0:15];
reg [2:0] s0_status_r, s0_status_w;
wire s0_decre_status_w;

reg [1:0] s0_sel_data_w;
wire [7:0] sobel_i0_w, sobel_i1_w, sobel_i2_w,
           sobel_i3_w, sobel_i4_w, sobel_i5_w,
           sobel_i6_w, sobel_i7_w, sobel_i8_w;
wire [10:0] sobelx_o0_w, sobelx_o2_w,
           sobelx_o3_w, sobelx_o5_w,
           sobelx_o6_w, sobelx_o8_w;
wire [10:0] sobely_o0_w, sobely_o1_w, sobely_o2_w,
           sobely_o6_w, sobely_o7_w, sobely_o8_w;
wire [10:0] sumx_02_w, sumx_35_w, sumx_68_w;
wire [10:0] sumy_01_w, sumy_26_w, sumy_78_w;


// stage 1 pipeline regs & wires
wire s1_in_valid;
wire s1_flush;
reg [10:0] s1_data_r[0:5];
reg [10:0] s1_data_w[0:5];
reg [2:0] s1_status_r, s1_status_w;

wire [10:0] sumx_0235_w;
wire [10:0] sumx_all_w;
wire [10:0] sumy_0126_w;
wire [10:0] sumy_all_w;

// stage 2 pipeline regs & wires
wire s2_in_valid;
wire s2_flush;
reg [10:0] s2_data_r[0:1];
reg [10:0] s2_data_w[0:1];
reg [2:0] s2_status_r, s2_status_w;

wire [11:0] gxy_w;
wire [1:0] gdir_w;

// stage 3 pipeline regs & wires
wire s3_in_valid;
wire s3_flush;
reg [11:0] s3_gxy_r[0:3];
reg [11:0] s3_gxy_w[0:3];
reg [1:0] s3_gdir_r[0:3];
reg [1:0] s3_gdir_w[0:3];
reg [2:0] s3_status_r, s3_status_w;

reg [1:0] s3_sel_demux_w;
wire [11:0] gnms0_w, gnms1_w, gnms2_w, gnms3_w;

// stage 4 pipeline regs & wires
wire s4_in_valid;
reg [11:0] s4_data_r [0:3];
reg [11:0] s4_data_w [0:3];

// system control registers
wire comp_one_channel_w;
wire comp_all_channel_w;
reg [2:0] sobel_depth_r;
reg [2:0] sobel_depth_w;
reg out_valid_r;
reg out_valid_w;





// ------------------------ stage 0 pipeline ------------------------
// create signals for next stage pipeline
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
            s0_data_r[i] <= 8'd0;
        end
    end
    else begin
        for(i=0; i<16; i=i+1) begin
            s0_data_r[i] <= s0_data_w[i];
        end
    end
end

// perform sobel gradient calculation
always@(*) begin
    s0_sel_data_w = 2'b00;
    case(s0_status_r)
        3'd4: s0_sel_data_w = 2'b00;
        3'd3: s0_sel_data_w = 2'b01;
        3'd2: s0_sel_data_w = 2'b10;
        3'd1: s0_sel_data_w = 2'b11;
    endcase
end

four2oneMux #(.data_width(8)) mux0(.o_out(sobel_i0_w), .i_in0(s0_data_r[0]), .i_in1(s0_data_r[1]), .i_in2(s0_data_r[4]), .i_in3(s0_data_r[5]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux1(.o_out(sobel_i1_w), .i_in0(s0_data_r[1]), .i_in1(s0_data_r[2]), .i_in2(s0_data_r[5]), .i_in3(s0_data_r[6]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux2(.o_out(sobel_i2_w), .i_in0(s0_data_r[2]), .i_in1(s0_data_r[3]), .i_in2(s0_data_r[6]), .i_in3(s0_data_r[7]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux3(.o_out(sobel_i3_w), .i_in0(s0_data_r[4]), .i_in1(s0_data_r[5]), .i_in2(s0_data_r[8]), .i_in3(s0_data_r[9]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux4(.o_out(sobel_i4_w), .i_in0(s0_data_r[5]), .i_in1(s0_data_r[6]), .i_in2(s0_data_r[9]), .i_in3(s0_data_r[10]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux5(.o_out(sobel_i5_w), .i_in0(s0_data_r[6]), .i_in1(s0_data_r[7]), .i_in2(s0_data_r[10]), .i_in3(s0_data_r[11]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux6(.o_out(sobel_i6_w), .i_in0(s0_data_r[8]), .i_in1(s0_data_r[9]), .i_in2(s0_data_r[12]), .i_in3(s0_data_r[13]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux7(.o_out(sobel_i7_w), .i_in0(s0_data_r[9]), .i_in1(s0_data_r[10]), .i_in2(s0_data_r[13]), .i_in3(s0_data_r[14]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux8(.o_out(sobel_i8_w), .i_in0(s0_data_r[10]), .i_in1(s0_data_r[11]), .i_in2(s0_data_r[14]), .i_in3(s0_data_r[15]), .i_sel(s0_sel_data_w));

filter_x gx(.i_data0(sobel_i0_w), .i_data2(sobel_i2_w), .i_data3(sobel_i3_w), .i_data5(sobel_i5_w), .i_data6(sobel_i6_w), .i_data8(sobel_i8_w),
            .o_data0(sobelx_o0_w), .o_data2(sobelx_o2_w), .o_data3(sobelx_o3_w), .o_data5(sobelx_o5_w), .o_data6(sobelx_o6_w), .o_data8(sobelx_o8_w));

filter_y gy(.i_data0(sobel_i0_w), .i_data1(sobel_i1_w), .i_data2(sobel_i2_w), .i_data6(sobel_i6_w), .i_data7(sobel_i7_w), .i_data8(sobel_i8_w),
            .o_data0(sobely_o0_w), .o_data1(sobely_o1_w), .o_data2(sobely_o2_w), .o_data6(sobely_o6_w), .o_data7(sobely_o7_w), .o_data8(sobely_o8_w));

assign sumx_02_w = sobelx_o0_w + sobelx_o2_w;
assign sumx_35_w = sobelx_o3_w + sobelx_o5_w;
assign sumx_68_w = sobelx_o6_w + sobelx_o8_w;
assign sumy_01_w = sobely_o0_w + sobely_o1_w;
assign sumy_26_w = sobely_o2_w + sobely_o6_w;
assign sumy_78_w = sobely_o7_w + sobely_o8_w;

// ------------------------ stage 1 pipeline ------------------------
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
    s1_data_w[0] = (s1_in_valid) ? sumx_02_w : s1_data_r[0];
    s1_data_w[1] = (s1_in_valid) ? sumx_35_w : s1_data_r[1];
    s1_data_w[2] = (s1_in_valid) ? sumx_68_w : s1_data_r[2];
    s1_data_w[3] = (s1_in_valid) ? sumy_01_w : s1_data_r[3];
    s1_data_w[4] = (s1_in_valid) ? sumy_26_w : s1_data_r[4];
    s1_data_w[5] = (s1_in_valid) ? sumy_78_w : s1_data_r[5];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<6; i=i+1) begin
            s1_data_r[i] <= 11'd0;
        end
    end
    else begin
        for(i=0; i<6; i=i+1) begin
            s1_data_r[i] <= s1_data_w[i];
        end
    end
end

// perform sum
assign sumx_0235_w = s1_data_r[0] + s1_data_r[1];
assign sumx_all_w  = sumx_0235_w + s1_data_r[2];
assign sumy_0126_w = s1_data_r[3] + s1_data_r[4];
assign sumy_all_w  = sumy_0126_w + s1_data_r[5];


// ------------------------ stage 2 pipeline ------------------------
assign s3_in_valid = (s2_status_r > 3'd0);
assign s3_flush    = (s2_status_r == 3'd0) && (s3_status_r == 3'd1);

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
    s2_data_w[0] = (s2_in_valid) ? sumx_all_w : s2_data_r[0];
    s2_data_w[1] = (s2_in_valid) ? sumy_all_w : s2_data_r[1];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        s2_data_r[0] <= 11'd0;
        s2_data_r[1] <= 11'd0;
    end
    else begin
        s2_data_r[0] <= s2_data_w[0];
        s2_data_r[1] <= s2_data_w[1];
    end
end

// perform gxy_compute 
gxy_compute gxy(.i_gx(s2_data_r[0]), .i_gy(s2_data_r[1]), .o_gxy(gxy_w));

// perform gdir_compute
gdir_compute gdir(.i_gx(s2_data_r[0]), .i_gy(s2_data_r[1]), .o_gdir(gdir_w));

// ------------------------ stage 3 pipeline ------------------------
assign comp_one_channel_w = (s3_status_r == 3'd1);

// update pipeline status register
always@(*) begin
    if(s3_in_valid)   s3_status_w = s2_status_r;
    else if(s3_flush) s3_status_w = 3'd0;
    else              s3_status_w = s3_status_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) s3_status_r <= 3'd0;
    else         s3_status_r <= s3_status_w;
end

// update pipeline data registers
always@(*) begin
    s3_sel_demux_w = 2'b00;
    case(s2_status_r)
        3'd4: s3_sel_demux_w = 2'b00;
        3'd3: s3_sel_demux_w = 2'b01;
        3'd2: s3_sel_demux_w = 2'b10;
        3'd1: s3_sel_demux_w = 2'b11;
    endcase
end

always@(*) begin
    s3_gxy_w[0] = (s3_in_valid && (s3_sel_demux_w == 2'b00)) ? gxy_w : s3_gxy_r[0];
    s3_gxy_w[1] = (s3_in_valid && (s3_sel_demux_w == 2'b01)) ? gxy_w : s3_gxy_r[1];
    s3_gxy_w[2] = (s3_in_valid && (s3_sel_demux_w == 2'b10)) ? gxy_w : s3_gxy_r[2];
    s3_gxy_w[3] = (s3_in_valid && (s3_sel_demux_w == 2'b11)) ? gxy_w : s3_gxy_r[3];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin 
        for(i=0; i<4; i=i+1) begin
            s3_gxy_r[i] <= 12'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s3_gxy_r[i] <= s3_gxy_w[i];
        end
    end
end

always@(*) begin
    s3_gdir_w[0] = (s3_in_valid && (s3_sel_demux_w == 2'b00)) ? gdir_w : s3_gdir_r[0];
    s3_gdir_w[1] = (s3_in_valid && (s3_sel_demux_w == 2'b01)) ? gdir_w : s3_gdir_r[1];
    s3_gdir_w[2] = (s3_in_valid && (s3_sel_demux_w == 2'b10)) ? gdir_w : s3_gdir_r[2];
    s3_gdir_w[3] = (s3_in_valid && (s3_sel_demux_w == 2'b11)) ? gdir_w : s3_gdir_r[3];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin 
        for(i=0; i<4; i=i+1) begin
            s3_gdir_r[i] <= 2'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s3_gdir_r[i] <= s3_gdir_w[i];
        end
    end
end

// perform Gnms
nms_comp gnms(.i_gxy0(s3_gxy_r[0]), .i_gxy1(s3_gxy_r[1]), .i_gxy2(s3_gxy_r[2]), .i_gxy3(s3_gxy_r[3]), 
              .i_gdir0(s3_gdir_r[0]), .i_gdir1(s3_gdir_r[1]), .i_gdir2(s3_gdir_r[2]), .i_gdir3(s3_gdir_r[3]), 
              .o_gnms0(gnms0_w), .o_gnms1(gnms1_w), .o_gnms2(gnms2_w), .o_gnms3(gnms3_w));


// ------------------------ stage 4 pipeline ------------------------

// update pipeline data registers
always@(*) begin
    s4_data_w[0] = (comp_one_channel_w) ? gnms0_w : s4_data_r[0];
    s4_data_w[1] = (comp_one_channel_w) ? gnms1_w : s4_data_r[1];
    s4_data_w[2] = (comp_one_channel_w) ? gnms2_w : s4_data_r[2];
    s4_data_w[3] = (comp_one_channel_w) ? gnms3_w : s4_data_r[3];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin 
        for(i=0; i<4; i=i+1) begin
            s4_data_r[i] <= 12'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s4_data_r[i] <= s4_data_w[i];
        end
    end
end

// ------------------------ system status register ------------------------
assign comp_all_channel_w = sobel_depth_r == 3'd0;

// update sobel nms depth counter
always@(*) begin
    if(i_rst_eng)               sobel_depth_w = 3'd0;
    else if(i_set_eng)          sobel_depth_w = 3'd4;
    else if(comp_one_channel_w) sobel_depth_w = sobel_depth_r - 3'd1;
    else                        sobel_depth_w = sobel_depth_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) sobel_depth_r <= 3'd0;
    else         sobel_depth_r <= sobel_depth_w;
end

// update the out_valid register
always@(*) begin
    out_valid_w = (comp_one_channel_w) ? 1'b1 : 1'b0;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) out_valid_r <= 1'b0;
    else         out_valid_r <= out_valid_w;
end

// ------------------------ system output ------------------------
assign o_data0     = {2'b00, s4_data_r[0]};
assign o_data1     = {2'b00, s4_data_r[1]};
assign o_data2     = {2'b00, s4_data_r[2]};
assign o_data3     = {2'b00, s4_data_r[3]};
assign o_out_valid = out_valid_r;
assign o_done      = (out_valid_r && comp_all_channel_w);

endmodule


module filter_x(
    input [7:0] i_data0,
    input [7:0] i_data2,
    input [7:0] i_data3,
    input [7:0] i_data5,
    input [7:0] i_data6,
    input [7:0] i_data8,
    output [10:0] o_data0,
    output [10:0] o_data2,
    output [10:0] o_data3,
    output [10:0] o_data5,
    output [10:0] o_data6,
    output [10:0] o_data8
);

assign o_data0 =  ~{3'b000, i_data0} + 11'd1;        // x(-1)
assign o_data2 =   {3'b000, i_data2};                // x( 1)
assign o_data3 = (~{3'b000, i_data3} + 11'd1) <<< 1; // x(-2)
assign o_data5 =   {3'b000, i_data5} <<< 1;          // x( 2)
assign o_data6 =  ~{3'b000, i_data6} + 11'd1;        // x(-1)
assign o_data8 =   {3'b000, i_data8};                // x( 1)

endmodule

module filter_y(
    input [7:0] i_data0,
    input [7:0] i_data1,
    input [7:0] i_data2,
    input [7:0] i_data6,
    input [7:0] i_data7,
    input [7:0] i_data8,
    output [10:0] o_data0,
    output [10:0] o_data1,
    output [10:0] o_data2,
    output [10:0] o_data6,
    output [10:0] o_data7,
    output [10:0] o_data8
);

assign o_data0 =  ~{3'b000, i_data0} + 11'd1;        // x(-1)
assign o_data1 = (~{3'b000, i_data1} + 11'd1) <<< 1; // x(-2)
assign o_data2 =  ~{3'b000, i_data2} + 11'd1;        // x(-1)
assign o_data6 =   {3'b000, i_data6};                // x( 1)
assign o_data7 =   {3'b000, i_data7} <<< 1;          // x( 2)
assign o_data8 =   {3'b000, i_data8};                // x( 1)

endmodule

module gxy_compute(
    input [10:0] i_gx,
    input [10:0] i_gy,
    output [11:0] o_gxy
);

wire [11:0] abs_gx;
wire [11:0] abs_gy;

assign abs_gx = (i_gx[10]) ? (~{i_gx[10], i_gx} + 11'd1) : {i_gx[10], i_gx};
assign abs_gy = (i_gy[10]) ? (~{i_gy[10], i_gy} + 11'd1) : {i_gy[10], i_gy};

assign o_gxy = abs_gx + abs_gy;

endmodule

module gdir_compute(
    input [10:0] i_gx, 
    input [10:0] i_gy,
    output [1:0] o_gdir
);

// indicate i_gx positive or not
wire pos_flag;

// intermediate value (7 bits fraction digits + 14 bits integer digits)
wire signed [20:0] gx_inter;
wire signed [20:0] gy_inter;

wire signed [20:0] gx_multiply_2_414_inter;
wire signed [20:0] gx_multiply_0_414_inter;
wire signed [20:0] gx_multiply_neg_0_414_inter;
wire signed [20:0] gx_multiply_neg_2_414_inter;

// |x|y|z|w| x-> 1 for y>2.414*x 
// |x|y|z|w| y-> 1 for y>0.414*x 
// |x|y|z|w| z-> 1 for y>-0.414*x
// |x|y|z|w| w-> 1 for y>-2.414*x
wire [3:0] comp_flag;
wire y_large_than_2_414x, y_large_than_0_414x, 
     y_large_than_neg_0_414x, y_large_than_neg_2_414x;

reg [1:0] gdir_w;

assign pos_flag = !i_gx[10];

assign gx_inter = {{3{i_gx[10]}}, i_gx, 7'b000_0000};
assign gy_inter = {{3{i_gy[10]}}, i_gy, 7'b000_0000};

// x * 2.41406
assign gx_multiply_2_414_inter = ((gx_inter <<< 1) + (gx_inter >>> 2)) + ((gx_inter >>> 3) + (gx_inter >>> 5)) + (gx_inter >>> 7); 
// x * 0.41406
assign gx_multiply_0_414_inter = ((gx_inter >>> 2) + (gx_inter >>> 3)) + ((gx_inter >>> 5) + (gx_inter >>> 7));
// x * -0.41406
assign gx_multiply_neg_0_414_inter = -$signed(((gx_inter >>> 2) + (gx_inter >>> 3)) + ((gx_inter >>> 5) + (gx_inter >>> 7)));
// x * -2.41406
assign gx_multiply_neg_2_414_inter = -$signed(((gx_inter <<< 1) + (gx_inter >>> 2)) + ((gx_inter >>> 3) + (gx_inter >>> 5)) + (gx_inter >>> 7));

// perform y/x > coeff
assign y_large_than_2_414x     = (pos_flag) ? (gy_inter > gx_multiply_2_414_inter) : (gy_inter < gx_multiply_2_414_inter);
assign y_large_than_0_414x     = (pos_flag) ? (gy_inter > gx_multiply_0_414_inter) : (gy_inter < gx_multiply_0_414_inter);
assign y_large_than_neg_0_414x = (pos_flag) ? (gy_inter > gx_multiply_neg_0_414_inter) : (gy_inter < gx_multiply_neg_0_414_inter);
assign y_large_than_neg_2_414x = (pos_flag) ? (gy_inter > gx_multiply_neg_2_414_inter) : (gy_inter < gx_multiply_neg_2_414_inter);

assign comp_flag = {y_large_than_2_414x, y_large_than_0_414x, y_large_than_neg_0_414x, y_large_than_neg_2_414x};

// decide the theta located at which region
// y/x > 2.41406 --> region 0
// 2.41406 > y/x > 0.41406 --> region 1
// 0.41406 > y/x > -0.41406 --> region 2
// -0.41406 > y/x > -2.41406 --> region 3
// -2.41406 > y/x --> region 0
always@(*)begin
    gdir_w = 2'b00;
    case(comp_flag)
        4'b1111: gdir_w = 2'd0;
        4'b0111: gdir_w = 2'd1;
        4'b0011: gdir_w = 2'd2;
        4'b0001: gdir_w = 2'd3;
        4'b0000: gdir_w = 2'd0;
    endcase
end

assign o_gdir = gdir_w;

endmodule


module nms_comp(
    input [11:0] i_gxy0,
    input [11:0] i_gxy1,
    input [11:0] i_gxy2,
    input [11:0] i_gxy3,
    input [1:0] i_gdir0,
    input [1:0] i_gdir1,
    input [1:0] i_gdir2,
    input [1:0] i_gdir3,
    output [11:0] o_gnms0,
    output [11:0] o_gnms1,
    output [11:0] o_gnms2,
    output [11:0] o_gnms3
);

reg [1:0] comp_flag0, comp_flag1, comp_flag2, comp_flag3;

// ---------------
// | gxy0 | gxy1 |
// ---------------
// | gxy2 | gxy3 |
// ---------------
// gxy0
always@(*) begin
    comp_flag0 = 2'b00;
    case(i_gdir0)
        2'd0: comp_flag0 = {i_gxy0 >= i_gxy2, i_gxy0 >= 12'd0};
        2'd1: comp_flag0 = {i_gxy0 >= i_gxy3, i_gxy0 >= 12'd0};
        2'd2: comp_flag0 = {i_gxy0 >= i_gxy1, i_gxy0 >= 12'd0};
        2'd3: comp_flag0 = {i_gxy0 >=  12'd0, i_gxy0 >= 12'd0};
    endcase
end

// gxy1
always@(*) begin
    comp_flag1 = 2'b00;
    case(i_gdir1)
        2'd0: comp_flag1 = {i_gxy1 >= i_gxy3, i_gxy1 >= 12'd0};
        2'd1: comp_flag1 = {i_gxy1 >=  12'd0, i_gxy1 >= 12'd0};
        2'd2: comp_flag1 = {i_gxy1 >= i_gxy0, i_gxy1 >= 12'd0};
        2'd3: comp_flag1 = {i_gxy1 >= i_gxy2, i_gxy1 >= 12'd0};
    endcase
end

// gxy2
always@(*) begin
    comp_flag2 = 2'b00;
    case(i_gdir2)
        2'd0: comp_flag2 = {i_gxy2 >= i_gxy0, i_gxy2 >= 12'd0};
        2'd1: comp_flag2 = {i_gxy2 >=  12'd0, i_gxy2 >= 12'd0};
        2'd2: comp_flag2 = {i_gxy2 >= i_gxy3, i_gxy2 >= 12'd0};
        2'd3: comp_flag2 = {i_gxy2 >= i_gxy1, i_gxy2 >= 12'd0};
    endcase
end

// gxy3
always@(*) begin
    comp_flag3 = 2'b00;
    case(i_gdir3)
        2'd0: comp_flag3 = {i_gxy3 >= i_gxy1, i_gxy3 >= 12'd0};
        2'd1: comp_flag3 = {i_gxy3 >= i_gxy0, i_gxy3 >= 12'd0};
        2'd2: comp_flag3 = {i_gxy3 >= i_gxy2, i_gxy3 >= 12'd0};
        2'd3: comp_flag3 = {i_gxy3 >=  12'd0, i_gxy3 >= 12'd0};
    endcase
end

assign o_gnms0 = (&comp_flag0) ? i_gxy0 : 12'd0;
assign o_gnms1 = (&comp_flag1) ? i_gxy1 : 12'd0;
assign o_gnms2 = (&comp_flag2) ? i_gxy2 : 12'd0;
assign o_gnms3 = (&comp_flag3) ? i_gxy3 : 12'd0;

endmodule