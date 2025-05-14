module DataOut(
    input i_clk,
    input i_rst,
    // --- IO ---
    input i_out_ready,
    output [63:0] o_out_data,
    output o_out_valid,
    // --- Reducer ---
    input i_reducer_valid,
    input [254:0] i_reducer_data,
    output o_reducer_ready
    
);

// ----- wires and regs -----
// counter
reg [1:0] counter_r, counter_w;
reg incr_counter;

// xg
reg [254:0] xg_r, xg_w;
reg wen_xg;

// yg
reg [254:0] yg_r, yg_w;
reg wen_yg;

// fsm
localparam S_RESET   = 3'd0,
           S_RECV_X  = 3'd1,
           S_RECV_Y  = 3'd2,
           S_TRANS_X = 3'd3,
           S_TRANS_Y = 3'd4;
reg [2:0] status_r, status_w;
wire io_fire, reduce_fire, trans_done;
reg o_reduce_ready_w, o_out_valid_w;
reg sel_data; // select for which data to output

// output data
wire [255:0] o_data;
wire [7:0] base_addr;

// ----- data path ----- 
// xg
always@(*) begin
    xg_w = (wen_xg) ? i_reducer_data : xg_r;
end
always@(posedge i_clk) begin
    if(i_rst) xg_r <= 255'd0;
    else      xg_r <= xg_w;
end
// yg
always@(*) begin
    yg_w = (wen_yg) ? i_reducer_data : yg_r;
end
always@(posedge i_clk) begin
    if(i_rst) yg_r <= 255'd0;
    else      yg_r <= yg_w;
end
// counter
always@(*) begin
    counter_w = (incr_counter) ? (counter_r + 2'd1) : counter_r;
end
always@(posedge i_clk) begin
    if(i_rst) counter_r <= 2'd0;
    else      counter_r <= counter_w;
end

// partial selection
assign o_data    = (sel_data) ? {1'b0, yg_r} : {1'b0, xg_r};
assign base_addr = 8'd255 - {counter_r, 6'd0};

// ----- controller ------
// inputs
assign io_fire     = o_out_valid_w && i_out_ready;
assign reduce_fire = o_reduce_ready_w && i_reducer_valid;
assign trans_done  = (counter_r == 2'd3);

// CS
always @(posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS
always@(*) begin
    status_w = status_r;

    case(status_r)
        S_RESET:   status_w = S_RECV_X;
        S_RECV_X:  status_w = (reduce_fire          ) ? S_RECV_Y  : status_r;
        S_RECV_Y:  status_w = (reduce_fire          ) ? S_TRANS_X : status_r;
        S_TRANS_X: status_w = (trans_done && io_fire) ? S_TRANS_Y : status_r;
        S_TRANS_Y: status_w = (trans_done && io_fire) ? S_RECV_X  : status_r;
    endcase
end

// OL
always@(*) begin
    // ------- default assignment --------
    // io
    o_out_valid_w    = 1'b0;
    o_reduce_ready_w = 1'b0;
    // data path
    wen_xg       = 1'b0;
    wen_yg       = 1'b0;
    incr_counter = 1'b0;
    sel_data     = 1'b0;

    case(status_r)
        S_RECV_X: begin
            o_reduce_ready_w = 1'b1;
            wen_xg = reduce_fire;
        end
        S_RECV_Y: begin
            o_reduce_ready_w = 1'b1;
            wen_yg = reduce_fire;
        end
        S_TRANS_X: begin
            o_out_valid_w = 1'b1;
            incr_counter  = io_fire;
            sel_data      = 1'b0;
        end
        S_TRANS_Y: begin
            o_out_valid_w = 1'b1;
            incr_counter  = io_fire;
            sel_data      = 1'b1;
        end
    endcase
end

// --------- io ----------
assign o_out_valid     = o_out_valid_w;
assign o_reducer_ready = o_reduce_ready_w;
assign o_out_data      = o_data[base_addr -: 64];

endmodule