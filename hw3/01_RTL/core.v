// `include "./system_controller.v"
// `include "./sram_4banks.v"
// `include "./conv_engine.v"
// `include "./sobel_nms_engine.v"
// `include "./median_filter_engine.v"
// `include "./four2oneMux.v"

`define MV_RIGHT  3'd0
`define MV_LEFT   3'd1
`define MV_UP     3'd2
`define MV_DOWN   3'd3
`define REDUCE_CH 3'd4
`define INCRE_CH  3'd5

`define SEQ_CONV   2'd0
`define SEQ_MEDIAN 2'd1
`define SEQ_SOBEL  2'd2

module core (                       //Don't modify interface
	input         i_clk,
	input         i_rst_n,
	input         i_op_valid,
	input  [ 3:0] i_op_mode,
    output        o_op_ready,
	input         i_in_valid,
	input  [ 7:0] i_in_data,
	output        o_in_ready,
	output        o_out_valid,
	output [13:0] o_out_data
);

// tensor shape
wire [3:0] tensor_ox, tensor_oy;
wire [1:0] tensor_depth;

// system controller output
wire sys_ctrl_sram_inst_valid;
wire [2:0] sys_ctrl_sram_mode;

wire sys_ctrl_sram_in_data_valid;

wire sys_ctrl_tensor_in_valid;
wire [2:0] sys_ctrl_tensor_op;

wire sys_ctrl_conv_rst_eng, sys_ctrl_median_rst_eng, sys_ctrl_sobel_rst_eng;
wire sys_ctrl_conv_set_eng, sys_ctrl_median_set_eng, sys_ctrl_sobel_set_eng;
wire sys_ctrl_conv_in_valid, sys_ctrl_median_in_valid, sys_ctrl_sobel_in_valid;

wire sys_ctrl_sel_valid;
wire [1:0] sys_ctrl_sel_eng;
wire sys_ctrl_rst_eng_done, sys_ctrl_rst_seq_out;


// sram output
wire sram_inst_ready;
wire sram_in_data_ready;
wire [7:0] sram_disp_data;
wire sram_disp_valid;
wire [7:0] sram_comp_data0, sram_comp_data1, sram_comp_data2, sram_comp_data3, 
 		   sram_comp_data4, sram_comp_data5, sram_comp_data6, sram_comp_data7,
		   sram_comp_data8, sram_comp_data9, sram_comp_data10, sram_comp_data11,
		   sram_comp_data12, sram_comp_data13, sram_comp_data14, sram_comp_data15;
wire sram_comp_data_valid;

// seq_out block
wire seq_out_valid;
wire [13:0] seq_out_data;

// conv engine
wire [13:0] conv_odata0, conv_odata1, conv_odata2, conv_odata3;
wire conv_o_valid;

// median engine
wire [13:0] median_odata0, median_odata1, median_odata2, median_odata3;
wire median_o_valid, median_o_done;

// sobel engine
wire [13:0] sobel_odata0, sobel_odata1, sobel_odata2, sobel_odata3;
wire sobel_o_valid, sobel_o_done;

// engine done register
wire eng_done_done_w;

system_controller system_controller0(
	.i_clk(i_clk), .i_rst_n(i_rst_n),  
	// ----- system IO ------
	.i_op_valid(i_op_valid), .i_op_mode(i_op_mode), .o_op_ready(o_op_ready), //op
	.i_in_valid(i_in_valid), .o_in_ready(o_in_ready), // data in
	.o_out_valid(o_out_valid), .o_out_data(o_out_data), // data out
    // ------ compute engine ------
	.o_conv_rst_eng(sys_ctrl_conv_rst_eng), .o_sobel_rst_eng(sys_ctrl_sobel_rst_eng), .o_median_rst_eng(sys_ctrl_median_rst_eng),
	.o_sobel_set_eng(sys_ctrl_sobel_set_eng), .o_sobel_in_valid(sys_ctrl_sobel_in_valid), // sobel nms
	.o_conv_set_eng(sys_ctrl_conv_set_eng), .o_conv_in_valid(sys_ctrl_conv_in_valid), // conv
	.o_median_set_eng(sys_ctrl_median_set_eng), .o_median_in_valid(sys_ctrl_median_in_valid), // median
	.o_tensor_in_valid(sys_ctrl_tensor_in_valid), .o_tensor_op(sys_ctrl_tensor_op), // tensor shape
    // ------ sram controller ------
	.o_sram_mode(sys_ctrl_sram_mode), .o_sram_inst_valid(sys_ctrl_sram_inst_valid), .i_sram_inst_ready(sram_inst_ready), // inst
	.o_sram_in_data_valid(sys_ctrl_sram_in_data_valid), .i_sram_in_data_ready(sram_in_data_ready), // load data
	.i_sram_disp_data(sram_disp_data), .i_sram_disp_valid(sram_disp_valid), // display
	.i_sram_out_data_valid(sram_comp_data_valid), // stream out data to compute engine
    // --------- sequence out block ---------
	.o_rst_seq_out(sys_ctrl_rst_seq_out), .i_seq_out_valid(seq_out_valid), .i_seq_out_data(seq_out_data),
    // --------- engine done register ---------
	.o_rst_eng_done_r(sys_ctrl_rst_eng_done), .i_eng_done_r(eng_done_done_w),
    // ----------- sel signals for both --------
	.o_sel_valid(sys_ctrl_sel_valid), .o_sel_eng(sys_ctrl_sel_eng)
);

sram_4banks sram_bank_group(
    .i_clk(i_clk), .i_rst_n(i_rst_n),
    // sram control signals
    .i_mode(sys_ctrl_sram_mode), .i_ox(tensor_ox), .i_oy(tensor_oy), .i_depth(tensor_depth),
    .i_inst_valid(sys_ctrl_sram_inst_valid), .o_inst_ready(sram_inst_ready),
    // sram input data
    .i_in_data(i_in_data), .i_in_data_valid(sys_ctrl_sram_in_data_valid),
    .o_in_data_ready(sram_in_data_ready),
    // sram output data for display
	.o_disp_data(sram_disp_data), .o_disp_valid(sram_disp_valid),
    // sram output data
    .o_out_data0(sram_comp_data0),
    .o_out_data1(sram_comp_data1),
    .o_out_data2(sram_comp_data2),
    .o_out_data3(sram_comp_data3),
    .o_out_data4(sram_comp_data4),
    .o_out_data5(sram_comp_data5),
    .o_out_data6(sram_comp_data6),
    .o_out_data7(sram_comp_data7),
    .o_out_data8(sram_comp_data8),
    .o_out_data9(sram_comp_data9),
    .o_out_data10(sram_comp_data10),
    .o_out_data11(sram_comp_data11),
    .o_out_data12(sram_comp_data12),
    .o_out_data13(sram_comp_data13),
    .o_out_data14(sram_comp_data14),
    .o_out_data15(sram_comp_data15),
    .o_out_data_valid(sram_comp_data_valid)
);


seq_out_block seq_out_block0(
	.i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
	.i_rst_seq(sys_ctrl_rst_seq_out), .i_sel_valid(sys_ctrl_sel_valid), .i_sel_eng(sys_ctrl_sel_eng),
	// input from conv engine
	.i_data0_conv(conv_odata0), .i_data1_conv(conv_odata1), .i_data2_conv(conv_odata2), 
	.i_data3_conv(conv_odata3), .i_valid_conv(conv_o_valid),
    // input from median engine
	.i_data0_median(median_odata0), .i_data1_median(median_odata1), .i_data2_median(median_odata2), 
	.i_data3_median(median_odata3), .i_valid_median(median_o_valid),
	// input from sobel engine
	.i_data0_sobel(sobel_odata0), .i_data1_sobel(sobel_odata1), .i_data2_sobel(sobel_odata2), 
	.i_data3_sobel(sobel_odata3), .i_valid_sobel(sobel_o_valid),
	// output 
	.o_data(seq_out_data), .o_valid(seq_out_valid)
);

tensor_shape tensor_shape0(
	.i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
	.i_in_valid(sys_ctrl_tensor_in_valid), .i_op(sys_ctrl_tensor_op), 
	// output
	.o_ox(tensor_ox), .o_oy(tensor_oy), .o_depth(tensor_depth)
);

engine_done engine_done0(
	.i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
	.i_rst_done(sys_ctrl_rst_eng_done), .i_sel_valid(sys_ctrl_sel_valid), .i_sel_eng(sys_ctrl_sel_eng), 
	// engine dones
	.i_conv_done(conv_o_valid), .i_sobel_done(sobel_o_done), .i_median_done(median_o_done),
	// output
	.o_done(eng_done_done_w)
);

sobel_nms_engine sobel_nms_eng0(
    .i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
    .i_rst_eng(sys_ctrl_sobel_rst_eng), .i_set_eng(sys_ctrl_sobel_set_eng),
	// input data
    .i_data0(sram_comp_data0),
    .i_data1(sram_comp_data1),
    .i_data2(sram_comp_data2),
    .i_data3(sram_comp_data3),
    .i_data4(sram_comp_data4),
    .i_data5(sram_comp_data5),
    .i_data6(sram_comp_data6),
    .i_data7(sram_comp_data7),
    .i_data8(sram_comp_data8),
    .i_data9(sram_comp_data9),
    .i_data10(sram_comp_data10),
    .i_data11(sram_comp_data11),
    .i_data12(sram_comp_data12),
    .i_data13(sram_comp_data13),
    .i_data14(sram_comp_data14),
    .i_data15(sram_comp_data15),
    .i_in_valid(sys_ctrl_sobel_in_valid),
	// output data
    .o_data0(sobel_odata0),
    .o_data1(sobel_odata1),
    .o_data2(sobel_odata2),
    .o_data3(sobel_odata3),
    .o_out_valid(sobel_o_valid),
	// done signals
    .o_done(sobel_o_done)
);

median_filter_engine med_filter_eng0(
    .i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
    .i_rst_eng(sys_ctrl_median_rst_eng), .i_set_eng(sys_ctrl_median_set_eng),
	// input data
    .i_data0(sram_comp_data0),
    .i_data1(sram_comp_data1),
    .i_data2(sram_comp_data2),
    .i_data3(sram_comp_data3),
    .i_data4(sram_comp_data4),
    .i_data5(sram_comp_data5),
    .i_data6(sram_comp_data6),
    .i_data7(sram_comp_data7),
    .i_data8(sram_comp_data8),
    .i_data9(sram_comp_data9),
    .i_data10(sram_comp_data10),
    .i_data11(sram_comp_data11),
    .i_data12(sram_comp_data12),
    .i_data13(sram_comp_data13),
    .i_data14(sram_comp_data14),
    .i_data15(sram_comp_data15),
    .i_in_valid(sys_ctrl_median_in_valid),
	// output data
    .o_data0(median_odata0),
    .o_data1(median_odata1),
    .o_data2(median_odata2),
    .o_data3(median_odata3),
    .o_out_valid(median_o_valid),
	// done signals
    .o_done(median_o_done)
);

conv_engine conv_eng0(
    .i_clk(i_clk), .i_rst_n(i_rst_n),
	// control signals
    .i_rst_eng(sys_ctrl_conv_rst_eng), .i_conv_depth(tensor_depth), .i_set_eng(sys_ctrl_conv_set_eng),
	// input data
    .i_data0(sram_comp_data0),
    .i_data1(sram_comp_data1),
    .i_data2(sram_comp_data2),
    .i_data3(sram_comp_data3),
    .i_data4(sram_comp_data4),
    .i_data5(sram_comp_data5),
    .i_data6(sram_comp_data6),
    .i_data7(sram_comp_data7),
    .i_data8(sram_comp_data8),
    .i_data9(sram_comp_data9),
    .i_data10(sram_comp_data10),
    .i_data11(sram_comp_data11),
    .i_data12(sram_comp_data12),
    .i_data13(sram_comp_data13),
    .i_data14(sram_comp_data14),
    .i_data15(sram_comp_data15),
    .i_in_valid(sys_ctrl_conv_in_valid),
	// output data
    .o_data0(conv_odata0),
    .o_data1(conv_odata1),
    .o_data2(conv_odata2),
    .o_data3(conv_odata3),
    .o_out_valid(conv_o_valid)
);


endmodule

module seq_out_block(
	input i_clk,
	input i_rst_n,

	input i_rst_seq,
	input i_sel_valid,
	input [1:0] i_sel_eng,

	input [13:0] i_data0_conv,
	input [13:0] i_data1_conv,
	input [13:0] i_data2_conv,
	input [13:0] i_data3_conv,
	input i_valid_conv,
	input [13:0] i_data0_median,
	input [13:0] i_data1_median,
	input [13:0] i_data2_median,
	input [13:0] i_data3_median,
	input i_valid_median,
	input [13:0] i_data0_sobel,
	input [13:0] i_data1_sobel,
	input [13:0] i_data2_sobel,
	input [13:0] i_data3_sobel,
	input i_valid_sobel,

	output [13:0] o_data,
	output o_valid
);

parameter S0 = 2'd0, S1 = 2'd1, S2 = 2'd2, S3 = 2'd3;
// wires and regs
reg [13:0] data0_w;
reg [1:0] sel_eng_r, sel_eng_w;
reg[13:0] data_buf_r[0:2];
reg[13:0] data_buf_w[0:2];
reg[1:0] status_r, status_w;
reg wen_buf_w;
reg [13:0] o_data_w;
reg o_valid_w;

always@(*) begin
	data0_w = 14'd0;
	case(sel_eng_r)
		`SEQ_CONV: data0_w = i_data0_conv;
		`SEQ_MEDIAN: data0_w = i_data0_median;
		`SEQ_SOBEL: data0_w = i_data0_sobel;
	endcase
end



// sel engine register
always@(*) begin
	if(i_rst_seq)        sel_eng_w = 2'b11;
	else if(i_sel_valid) sel_eng_w = i_sel_eng;
	else                 sel_eng_w = sel_eng_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) sel_eng_r <= 2'd0;
	else         sel_eng_r <= sel_eng_w;
end


// buffer 

integer i;
always@(*) begin
	if(i_rst_seq) begin
		for(i=0; i<3; i=i+1) begin
			data_buf_w[i] = 14'd0;
		end
	end
	else if(wen_buf_w) begin
		case(sel_eng_r)
			`SEQ_CONV:   begin
				data_buf_w[0] = i_data1_conv;
				data_buf_w[1] = i_data2_conv;
				data_buf_w[2] = i_data3_conv;
			end
			`SEQ_MEDIAN: begin
				data_buf_w[0] = i_data1_median;
				data_buf_w[1] = i_data2_median;
				data_buf_w[2] = i_data3_median;
			end
			`SEQ_SOBEL:  begin
				data_buf_w[0] = i_data1_sobel;
				data_buf_w[1] = i_data2_sobel;
				data_buf_w[2] = i_data3_sobel;
			end
			default: begin
				data_buf_w[0] = 14'd0;
				data_buf_w[1] = 14'd0;
				data_buf_w[2] = 14'd0;
			end
		endcase
	end
	else begin
		for(i=0; i<3; i=i+1) begin
			data_buf_w[i] = data_buf_r[i];
		end
	end
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) begin
		for(i=0; i<3; i=i+1) begin
			data_buf_r[i] <= 14'd0;
		end
	end
	else begin
		for(i=0; i<3; i=i+1) begin
			data_buf_r[i] <= data_buf_w[i];
		end
	end
end



// CS
always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) status_r <= 2'd0;
	else         status_r <= status_w;
end

// NL
always@(*) begin
	status_w = S0;
	case(status_r)
		S0: begin
			if(((sel_eng_r == `SEQ_CONV) && i_valid_conv)||
			((sel_eng_r == `SEQ_MEDIAN) && i_valid_median)||
			((sel_eng_r == `SEQ_SOBEL) && i_valid_sobel)) begin
				status_w = S1;
			end
			else status_w = S0;
		end
		S1: status_w = S2;
		S2: status_w = S3;
		S3: status_w = S0;
	endcase
end

// OL
always@(*) begin
	o_valid_w = 1'b1;
	o_data_w  = 14'd0;
	wen_buf_w = 1'b0;
	case(status_r)
		S0: begin
			if(((sel_eng_r == `SEQ_CONV) && i_valid_conv)||
			((sel_eng_r == `SEQ_MEDIAN) && i_valid_median)||
			((sel_eng_r == `SEQ_SOBEL) && i_valid_sobel)) begin
				o_valid_w = 1'b1;
				o_data_w = data0_w;
				wen_buf_w = 1'b1;
			end
			else begin
				o_valid_w = 1'b0;
				o_data_w  = 14'd0;
				wen_buf_w = 1'b0;
			end
		end
		S1: begin
			o_valid_w = 1'b1;
			o_data_w  = data_buf_r[0];
		end
		S2: begin
			o_valid_w = 1'b1;
			o_data_w  = data_buf_r[1];
		end
		S3: begin
			o_valid_w = 1'b1;
			o_data_w  = data_buf_r[2];
		end
	endcase
end

assign o_data = o_data_w;
assign o_valid = o_valid_w;

endmodule

module tensor_shape(
	input i_clk,
	input i_rst_n,
	input i_in_valid,
	input [2:0] i_op,

	output [3:0] o_ox,
	output [3:0] o_oy,
	output [1:0] o_depth

);

reg [3:0] ox_r, ox_w; // default 0 (max: 6, min:0)
reg [3:0] oy_r, oy_w; // default 0 (max: 6, min:0)
reg [1:0] depth_r, depth_w; // default 32 (max: 32, min: 8)

always@(*) begin
	ox_w = ox_r;
	if(i_in_valid) begin
		case(i_op)
			`MV_DOWN: ox_w = (ox_r == 4'd6) ? ox_r : (ox_r + 4'd1);
			`MV_UP:  ox_w = (ox_r == 4'd0) ? ox_r : (ox_r - 4'd1);
		endcase
	end
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) ox_r <= 4'd0;
	else         ox_r <= ox_w;
end

always@(*) begin
	oy_w = oy_r;
	if(i_in_valid) begin
		case(i_op)
			`MV_LEFT:   oy_w = (oy_r == 4'd0) ? oy_r : (oy_r - 4'd1);
			`MV_RIGHT: oy_w = (oy_r == 4'd6) ? oy_r : (oy_r + 4'd1);
		endcase
	end
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) oy_r <= 4'd0;
	else         oy_r <= oy_w;
end

always@(*) begin
	depth_w = depth_r;
	if(i_in_valid) begin
		case(i_op)
			`REDUCE_CH: depth_w = (depth_r == 2'd0) ? depth_r : (depth_r - 2'd1);
			`INCRE_CH:  depth_w = (depth_r == 2'd2) ? depth_r : (depth_r + 2'd1);
		endcase
	end
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) depth_r <= 2'd2;
	else         depth_r <= depth_w;
end

assign o_ox = ox_r;
assign o_oy = oy_r;
assign o_depth = depth_r;

endmodule

module engine_done(
	input i_clk,
	input i_rst_n,

	input i_rst_done,
	input i_sel_valid,
	input [1:0] i_sel_eng, 

	input i_conv_done,
	input i_sobel_done,
	input i_median_done,

	output o_done

);

reg done_r, done_w;
reg [1:0] sel_eng_r, sel_eng_w;

always@(*) begin
	if(i_rst_done)       sel_eng_w = 2'b11;
	else if(i_sel_valid) sel_eng_w = i_sel_eng;
	else                 sel_eng_w = sel_eng_r;
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) sel_eng_r <= 2'd0;
	else         sel_eng_r <= sel_eng_w;
end

always@(*) begin
	if(i_rst_done) done_w = 1'b0;
	else begin
		done_w = 1'b0;
		case(sel_eng_r)
			`SEQ_CONV:   done_w = (i_conv_done) ? 1'b1 : done_r;
 			`SEQ_MEDIAN: done_w = (i_median_done) ? 1'b1 : done_r;
			`SEQ_SOBEL:  done_w = (i_sobel_done) ? 1'b1 : done_r;
		endcase
	end
end

always@(negedge i_rst_n or posedge i_clk) begin
	if(!i_rst_n) done_r <= 1'b0;
	else         done_r <= done_w;
end

assign o_done = done_r;



endmodule