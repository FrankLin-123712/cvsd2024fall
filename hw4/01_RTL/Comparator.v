module Comparator(
    input i_clk,
    input i_rst,
    input i_set_mode,
    input i_sel_fn,
    output o_setted,
    input i_en,
    input [127:0] i_iot_in,
    output o_ready,
    output o_done,
    output [127:0] o_iot_out
);

// --------- wires and regs -----------
// ### io ###
reg o_ready_w, o_done_w;
reg [127:0] o_iot_out_w;

// ### data path ###
// extreme value register
reg [127:0] extr_r[0:1];
reg [127:0] extr_w[0:1];
reg rst_extr_max, rst_extr_min, update_extr;

// status signals for extreme value
wire replace_idx;
wire [1:0] comp_flag; // compare iot_in with extr_r[1] and extr_r[0].

// counter
reg [3:0] ctr_r, ctr_w;
reg rst_ctr, incr_ctr;

// mode
reg [1:0] mode_r, mode_w;  // [1] for set flag, [0] for mode
reg wen_mode;

// controller
reg [2:0] status_r, status_w;
localparam S_RESET    = 3'd0,
           S_IDLE     = 3'd1,
           S_COMPARE  = 3'd2,
           S_OUTPUT1  = 3'd3,
           S_OUTPUT2  = 3'd4,
           S_SET_MODE = 3'd5;

// ------------ data path -------------
// status signals
/* Top2 Mode  : 1 imply extr_r[1] is smaller, so we should replace extr_r[1].
 * Last2 Mode : 1 imply extr_r[1] is smaller, so we should replace extr_r[0]. 
*/
assign replace_idx = (mode_r[0] ^ (extr_r[0] > extr_r[1]));

/* Top2 Mode  : the inital value should be the minimum (0)
 * Last2 Mode : the inital value should be the maximum (2^128 - 1)
*/
assign comp_flag   = {mode_r[0] ^ (i_iot_in > extr_r[1]), mode_r[0] ^ (i_iot_in > extr_r[0])};

// mode register
always@(*) begin
    mode_w = mode_r;

    if(wen_mode) begin
        mode_w = {1'b1, i_sel_fn};
    end
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) mode_r <= 2'b00;
    else      mode_r <= mode_w;
end

assign o_setted = mode_r[1];

// extreme value register
integer i;
always@(*) begin

    // default assignment
    for(i=0; i<2; i=i+1) begin
        extr_w[i] = extr_r[i];
    end

    if(rst_extr_max) begin
        for(i=0; i<2; i=i+1) begin
            extr_w[i] = ~128'd0; // initial vlaues are setted to 2^128-1.
        end
    end
    else if(rst_extr_min) begin
        for(i=0; i<2; i=i+1) begin
            extr_w[i] = 128'd0; // initial value are setted to 0.
        end
    end
    else if(update_extr) begin
        extr_w[replace_idx]  = i_iot_in;
        extr_w[!replace_idx] = extr_r[!replace_idx];
    end
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) begin
        for(i=0; i<2; i=i+1) begin
            extr_r[i] <= 128'd0;
        end
    end
    else begin
        for(i=0; i<2; i=i+1) begin
            extr_r[i] <= extr_w[i];
        end
    end
end

// counter
always@(*) begin
    if(rst_ctr)       ctr_w = 4'd0;
    else if(incr_ctr) ctr_w = ctr_r + 4'd1;
    else              ctr_w = ctr_r;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) ctr_r <= 4'd0;
    else      ctr_r <= ctr_w;
end

// ----------- controller ----------------
// CS
always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS
always@(*) begin
    status_w = S_IDLE;
    case(status_r)
        S_RESET:   status_w = S_IDLE;
        S_IDLE:    status_w = (i_en) ? S_COMPARE : ((i_set_mode) ? S_SET_MODE : S_IDLE);
        S_COMPARE: status_w = (ctr_r < 4'd8) ? S_COMPARE : S_OUTPUT1;
        S_OUTPUT1: status_w = S_OUTPUT2;
        S_OUTPUT2: status_w = S_IDLE;
    endcase
end

// OL
always@(*) begin
    // ------ default assignment -------
    // io
    o_ready_w   = 1'b0;
    o_done_w    = 1'b0;
    o_iot_out_w = 128'd0;

    // data path control signals
    rst_extr_max = 1'b0;
    rst_extr_min = 1'b0;
    update_extr  = 1'b0;
    rst_ctr      = 1'b0;
    incr_ctr     = 1'b0;
    wen_mode     = 1'b0;
    
    case(status_r)
        // S_RESET : all output set to 0 
        S_IDLE: begin
            // when iot_data ready
            o_ready_w   = 1'b1;
            incr_ctr    = i_en;
            update_extr = (i_en && ((|comp_flag) == 1'b1));
            // when setting the mode
            wen_mode = i_set_mode;
        end
        S_SET_MODE: begin
            {rst_extr_min, rst_extr_max} = (mode_r[0]) ? 2'b01 : 2'b10;
        end
        S_COMPARE: begin
            if(ctr_r < 4'd8) begin
                o_ready_w   = 1'b1;
                incr_ctr    = i_en;
                update_extr = (i_en && ((|comp_flag) == 1'b1));
            end
        end
        S_OUTPUT1: begin
            o_done_w    = 1'b1;
            o_iot_out_w = extr_r[!replace_idx];
        end
        S_OUTPUT2: begin
            o_done_w    = 1'b1;
            o_iot_out_w = extr_r[replace_idx];
            {rst_extr_min, rst_extr_max} = (mode_r[0]) ? 2'b01 : 2'b10;
            rst_ctr     = 1'b1;
        end
    endcase
end

assign o_ready   = o_ready_w;
assign o_done    = o_done_w;
assign o_iot_out = o_iot_out_w;





endmodule