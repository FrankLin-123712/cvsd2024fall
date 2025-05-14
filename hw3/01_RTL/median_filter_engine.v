// ##################################################
// # Median Filter Engine                           #
// # ---------------------------------------------- #
// # A 3 stages pipelined median filter engine      #
// # contains only valid control bit for simplicity #
// # assume 4 cycle recieve one batch of data       #
// ##################################################
// `include "./four2oneMux"

module median_filter_engine(
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
wire [7:0] sorter0_i0_w, sorter0_i1_w, sorter0_i2_w,
           sorter1_i0_w, sorter1_i1_w, sorter1_i2_w,
           sorter2_i0_w, sorter2_i1_w, sorter2_i2_w;

wire [7:0] sorter0_omin_w, sorter0_omed_w, sorter0_omax_w, 
           sorter1_omin_w, sorter1_omed_w, sorter1_omax_w, 
           sorter2_omin_w, sorter2_omed_w, sorter2_omax_w;

// stage 1 pipeline regs & wires
wire s1_in_valid;
wire s1_flush;
reg [7:0] s1_data_r [0:8];
reg [7:0] s1_data_w [0:8];
reg [2:0] s1_status_r, s1_status_w;

wire [7:0] s1_max_w, s1_med_w, s1_min_w;

// stage 2 pipeline regs & wires
wire s2_in_valid;
wire s2_flush;
reg [7:0] s2_data_r [0:2];
reg [7:0] s2_data_w [0:2];
reg [2:0] s2_status_r, s2_status_w;

wire [7:0] s2_med_in_seq_w;
reg [1:0] s2_sel_demux_w;
wire [7:0] s2_med0_w, s2_med1_w, s2_med2_w, s2_med3_w; 

// stage 3 pipeline regs & wires
wire s3_in_valid;
reg [7:0] s3_data_r[0:3];
reg [7:0] s3_data_w[0:3];

// system control register
wire comp_one_channel_w;
wire comp_all_channel_w;
reg [2:0] med_flt_depth_r;
reg [2:0] med_flt_depth_w;
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
            s0_data_r[i] <= 8'b0;
        end
    end
    else begin
        for(i=0; i<16; i=i+1) begin
            s0_data_r[i] <= s0_data_w[i];
        end
    end
end

// perform triple sorting
always@(*) begin
    s0_sel_data_w = 2'b00;
    case(s0_status_r)
        3'd4: s0_sel_data_w = 2'b00;
        3'd3: s0_sel_data_w = 2'b01;
        3'd2: s0_sel_data_w = 2'b10;
        3'd1: s0_sel_data_w = 2'b11;
    endcase
end

four2oneMux #(.data_width(8)) mux0(.o_out(sorter0_i0_w), .i_in0(s0_data_r[0]), .i_in1(s0_data_r[1]), .i_in2(s0_data_r[4]), .i_in3(s0_data_r[5]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux1(.o_out(sorter0_i1_w), .i_in0(s0_data_r[1]), .i_in1(s0_data_r[2]), .i_in2(s0_data_r[5]), .i_in3(s0_data_r[6]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux2(.o_out(sorter0_i2_w), .i_in0(s0_data_r[2]), .i_in1(s0_data_r[3]), .i_in2(s0_data_r[6]), .i_in3(s0_data_r[7]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux3(.o_out(sorter1_i0_w), .i_in0(s0_data_r[4]), .i_in1(s0_data_r[5]), .i_in2(s0_data_r[8]), .i_in3(s0_data_r[9]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux4(.o_out(sorter1_i1_w), .i_in0(s0_data_r[5]), .i_in1(s0_data_r[6]), .i_in2(s0_data_r[9]), .i_in3(s0_data_r[10]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux5(.o_out(sorter1_i2_w), .i_in0(s0_data_r[6]), .i_in1(s0_data_r[7]), .i_in2(s0_data_r[10]), .i_in3(s0_data_r[11]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux6(.o_out(sorter2_i0_w), .i_in0(s0_data_r[8]), .i_in1(s0_data_r[9]), .i_in2(s0_data_r[12]), .i_in3(s0_data_r[13]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux7(.o_out(sorter2_i1_w), .i_in0(s0_data_r[9]), .i_in1(s0_data_r[10]), .i_in2(s0_data_r[13]), .i_in3(s0_data_r[14]), .i_sel(s0_sel_data_w));
four2oneMux #(.data_width(8)) mux8(.o_out(sorter2_i2_w), .i_in0(s0_data_r[10]), .i_in1(s0_data_r[11]), .i_in2(s0_data_r[14]), .i_in3(s0_data_r[15]), .i_sel(s0_sel_data_w));

triple_sorter t0(.i_in0(sorter0_i0_w), .i_in1(sorter0_i1_w), .i_in2(sorter0_i2_w), 
                 .o_min(sorter0_omin_w), .o_med(sorter0_omed_w), .o_max(sorter0_omax_w));
triple_sorter t1(.i_in0(sorter1_i0_w), .i_in1(sorter1_i1_w), .i_in2(sorter1_i2_w), 
                 .o_min(sorter1_omin_w), .o_med(sorter1_omed_w), .o_max(sorter1_omax_w));
triple_sorter t2(.i_in0(sorter2_i0_w), .i_in1(sorter2_i1_w), .i_in2(sorter2_i2_w), 
                 .o_min(sorter2_omin_w), .o_med(sorter2_omed_w), .o_max(sorter2_omax_w));

// ------------------------ stage 1 pipeline ------------------------
// create control signals for next stage pipeline
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
    s1_data_w[0] = (s1_in_valid) ? sorter0_omin_w : s1_data_r[0];
    s1_data_w[1] = (s1_in_valid) ? sorter0_omed_w : s1_data_r[1];
    s1_data_w[2] = (s1_in_valid) ? sorter0_omax_w : s1_data_r[2];
    s1_data_w[3] = (s1_in_valid) ? sorter1_omin_w : s1_data_r[3];
    s1_data_w[4] = (s1_in_valid) ? sorter1_omed_w : s1_data_r[4];
    s1_data_w[5] = (s1_in_valid) ? sorter1_omax_w : s1_data_r[5];
    s1_data_w[6] = (s1_in_valid) ? sorter2_omin_w : s1_data_r[6];
    s1_data_w[7] = (s1_in_valid) ? sorter2_omed_w : s1_data_r[7];
    s1_data_w[8] = (s1_in_valid) ? sorter2_omax_w : s1_data_r[8];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<9; i=i+1) begin
            s1_data_r[i] <= 8'd0;
        end
    end
    else begin
        for(i=0; i<9; i=i+1) begin
            s1_data_r[i] <= s1_data_w[i];
        end
    end
end

// finding max in min_s of 3 groups
max_finder s1_find_max(.i_in0(s1_data_r[0]), .i_in1(s1_data_r[3]), .i_in2(s1_data_r[6]), .o_max(s1_max_w));
// finding med in med_s of 3 groups
med_finder s1_find_med(.i_in0(s1_data_r[1]), .i_in1(s1_data_r[4]), .i_in2(s1_data_r[7]), .o_med(s1_med_w));
// finding min in max_s of 3 groups
min_finder s1_find_min(.i_in0(s1_data_r[2]), .i_in1(s1_data_r[5]), .i_in2(s1_data_r[8]), .o_min(s1_min_w));

// ------------------------ stage 2 pipeline ------------------------
// create control signals for next stage pipeline
assign s3_in_valid        = (s2_status_r > 3'd0);
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
    s2_data_w[0] = (s2_in_valid) ? s1_max_w : s2_data_r[0];
    s2_data_w[1] = (s2_in_valid) ? s1_med_w : s2_data_r[1];
    s2_data_w[2] = (s2_in_valid) ? s1_min_w : s2_data_r[2];
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<3; i=i+1) begin
            s2_data_r[i] <= 3'd0;
        end
    end
    else begin
        for(i=0; i<3; i=i+1) begin
            s2_data_r[i] <= s2_data_w[i];
        end
    end
end

// finding median in these three numbers
med_finder s2_find_med(.i_in0(s2_data_r[0]), .i_in1(s2_data_r[1]), .i_in2(s2_data_r[2]), 
                       .o_med(s2_med_in_seq_w));

// store to corresponding registers
always@(*) begin
    s2_sel_demux_w = 2'b00;
    case(s2_status_r)
        3'd4: s2_sel_demux_w = 2'b00;
        3'd3: s2_sel_demux_w = 2'b01;
        3'd2: s2_sel_demux_w = 2'b10;
        3'd1: s2_sel_demux_w = 2'b11;
    endcase
end

// ------------------------ stage 3 pipeline ------------------------

// udpate pipeline data regs
always@(*) begin
    s3_data_w[0] = (s3_in_valid && (s2_sel_demux_w == 2'd0)) ? s2_med_in_seq_w : s3_data_r[0];
    s3_data_w[1] = (s3_in_valid && (s2_sel_demux_w == 2'd1)) ? s2_med_in_seq_w : s3_data_r[1];
    s3_data_w[2] = (s3_in_valid && (s2_sel_demux_w == 2'd2)) ? s2_med_in_seq_w : s3_data_r[2];
    s3_data_w[3] = (s3_in_valid && (s2_sel_demux_w == 2'd3)) ? s2_med_in_seq_w : s3_data_r[3];
end


always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) begin
        for(i=0; i<4; i=i+1) begin
            s3_data_r[i] <= 8'd0;
        end
    end
    else begin
        for(i=0; i<4; i=i+1) begin
            s3_data_r[i] <= s3_data_w[i];
        end
    end
end

// ------------------------ system status registers ------------------------

// update median filter depth counter
always@(*) begin
    if(i_rst_eng) med_flt_depth_w = 3'd0;
    else if(i_set_eng)          med_flt_depth_w = 3'd4;
    else if(comp_one_channel_w) med_flt_depth_w = med_flt_depth_r - 3'd1;
    else                        med_flt_depth_w = med_flt_depth_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) med_flt_depth_r <= 3'd0;
    else         med_flt_depth_r <= med_flt_depth_w;
end

// update the out_valid register
always@(*) begin
    out_valid_w = (comp_one_channel_w) ? 1'b1 : 1'b0;
end

always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) out_valid_r <= 1'b0;
    else         out_valid_r <= out_valid_w;
end

assign comp_all_channel_w = (med_flt_depth_r == 3'd0);



// ------------------------ system output ---------------------------
assign o_data0     = {6'b00_0000, s3_data_r[0]};
assign o_data1     = {6'b00_0000, s3_data_r[1]};
assign o_data2     = {6'b00_0000, s3_data_r[2]};
assign o_data3     = {6'b00_0000, s3_data_r[3]};
assign o_out_valid = out_valid_r;
assign o_done      = (out_valid_r && comp_all_channel_w);

endmodule

module triple_sorter(
    input [7:0] i_in0,
    input [7:0] i_in1,
    input [7:0] i_in2,
    output [7:0] o_min,
    output [7:0] o_med,
    output [7:0] o_max
);

wire comp_01_flag;
wire comp_02_flag;
wire comp_12_flag;

reg [7:0] o_min_w;
reg [7:0] o_med_w;
reg [7:0] o_max_w;

assign comp_01_flag = (i_in0 > i_in1);
assign comp_02_flag = (i_in0 > i_in2);
assign comp_12_flag = (i_in1 > i_in2);

always@(*) begin
    {o_max_w, o_med_w, o_min_w} = {i_in0, i_in1, i_in2};
    case({comp_01_flag, comp_02_flag, comp_12_flag})
        // impossible case : 3'b101, 3'b010
        3'b111: {o_max_w, o_med_w, o_min_w} = {i_in0, i_in1, i_in2};
        3'b110: {o_max_w, o_med_w, o_min_w} = {i_in0, i_in2, i_in1};
        3'b100: {o_max_w, o_med_w, o_min_w} = {i_in2, i_in0, i_in1};
        3'b011: {o_max_w, o_med_w, o_min_w} = {i_in1, i_in0, i_in2};
        3'b001: {o_max_w, o_med_w, o_min_w} = {i_in1, i_in2, i_in0};
        3'b000: {o_max_w, o_med_w, o_min_w} = {i_in2, i_in1, i_in0};
    endcase
end

assign o_min = o_min_w;
assign o_med = o_med_w;
assign o_max = o_max_w;


endmodule

module max_finder(
    input [7:0] i_in0,
    input [7:0] i_in1,
    input [7:0] i_in2,
    output [7:0] o_max
);

wire [7:0] max_w, med_w, min_w;

triple_sorter sorter3(.i_in0(i_in0), .i_in1(i_in1), .i_in2(i_in2), .o_min(min_w), .o_med(med_w), .o_max(max_w));
assign o_max = max_w;

endmodule

module med_finder(
    input [7:0] i_in0,
    input [7:0] i_in1,
    input [7:0] i_in2,
    output [7:0] o_med
);

wire [7:0] max_w, med_w, min_w;

triple_sorter sorter3(.i_in0(i_in0), .i_in1(i_in1), .i_in2(i_in2), .o_min(min_w), .o_med(med_w), .o_max(max_w));
assign o_med = med_w;

endmodule

module min_finder(
    input [7:0] i_in0,
    input [7:0] i_in1,
    input [7:0] i_in2,
    output [7:0] o_min
);

wire [7:0] max_w, med_w, min_w;

triple_sorter sorter3(.i_in0(i_in0), .i_in1(i_in1), .i_in2(i_in2), .o_min(min_w), .o_med(med_w), .o_max(max_w));
assign o_min = min_w;

endmodule
