module DataLoader(
    input i_clk,
    input i_rst,
    input i_en,
    input [7:0] i_iot_in,
    output o_busy,

    input i_dready,
    output [127:0] o_iot_out,
    output o_dvalid
);

// ------- wires and regs --------
// buffer for storing partial iot_data
reg [127:0] iot_data_r, iot_data_w;
reg rst_iot_data, wen_iot_data;
wire [6:0] base_addr_update;

// data counter for checking data buffer is ful and deciding which part of buffer to update
reg [4:0] data_ctr_r, data_ctr_w;
reg rst_data_ctr, incr_data_ctr;

// controller
localparam S_RESET     = 2'd0,
           S_IDLE      = 2'd1,
           S_LOAD_DATA = 2'd2;

reg [1:0] status_r, status_w;
reg o_busy_w, o_dvalid_w;


// -------- data path ---------
// data counter
always@(*) begin
    // default assignment
    data_ctr_w = data_ctr_r;

    if(rst_data_ctr)       data_ctr_w = 5'd0;
    else if(incr_data_ctr) data_ctr_w = data_ctr_r + 5'd1;             
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) data_ctr_r <= 5'd0;
    else      data_ctr_r <= data_ctr_w;
end


// iot_data buffer
assign base_addr_update = ({3'b000, data_ctr_r[3:0]} << 3) + 7'd7;
always@(*) begin
    // default assignment 
    iot_data_w = iot_data_r;

    if(rst_iot_data)      iot_data_w = 128'd0;
    else if(wen_iot_data) iot_data_w[base_addr_update -: 8] = i_iot_in;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) iot_data_r <= 128'd0;
    else      iot_data_r <= iot_data_w;
end

assign o_iot_out = iot_data_r;

// ---------- controller ---------
// CS 
always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS 
always@(*) begin
    // default assignment
    status_w = S_IDLE;

    case(status_r)
        S_RESET:     status_w = S_IDLE;
        S_IDLE:      status_w = (i_en) ? S_LOAD_DATA : S_IDLE;
        S_LOAD_DATA: status_w = ((data_ctr_r == 5'd16) && i_dready) ? S_IDLE : S_LOAD_DATA;
    endcase
end

// OL
always@(*) begin
    // ------ default assignment ------
    // io
    o_busy_w   = 1'b1;
    o_dvalid_w = 1'b0;
    // data path control signals
    rst_iot_data  = 1'b0;
    wen_iot_data  = 1'b0;
    rst_data_ctr  = 1'b0;
    incr_data_ctr = 1'b0;

    case(status_r)
        // S_RESET
        S_IDLE: begin
            o_busy_w      = 1'b0;
            wen_iot_data  = i_en;
            incr_data_ctr = i_en;
        end
        S_LOAD_DATA: begin
            o_busy_w      = (data_ctr_r >= 5'd15);
            wen_iot_data  = i_en;
            incr_data_ctr = i_en;
            o_dvalid_w    = (data_ctr_r == 5'd16);
            rst_iot_data  = ((data_ctr_r == 5'd16) && i_dready);
            rst_data_ctr  = ((data_ctr_r == 5'd16) && i_dready);
        end
    endcase
end

assign o_busy   = o_busy_w;
assign o_dvalid = o_dvalid_w;

endmodule