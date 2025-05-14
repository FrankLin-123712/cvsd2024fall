module DataIn (
    input i_clk,
    input i_rst,
    // --- IO ---
    input i_in_valid,
    input [63:0] i_in_data,
    output o_in_ready,
    // --- PointAdder ---
    input i_ptadd_ready,
    output [254:0] o_ptadd_m,
    output [254:0] o_ptadd_xp,
    output [254:0] o_ptadd_yp,
    output o_ptadd_valid
    
);


// ---- wires and regs ----
// controller
localparam S_RESET  = 3'd0,
           S_RECV_M = 3'd1,
           S_RECV_X = 3'd2,
           S_RECV_Y = 3'd3,
           S_DONE   = 3'd4;
reg [2:0] status_r, status_w;

// input signals for controller
wire io_fire, ptadd_fire, ctr_eq_3;
// output signals for controller
reg incr_ctr;
reg update_M, update_X, update_Y;
reg o_in_ready_w, o_ptadd_valid_w;

// data path
wire [7:0] base_addr; // base address for reg to update
reg [1:0] counter_r, counter_w; // counter
reg [255:0] regM_r, regM_w; // reg_M
reg [255:0] regX_r, regX_w; // reg_X
reg [255:0] regY_r, regY_w; // reg_Y

// ---- data path -----
assign io_fire = o_in_ready_w && i_in_valid;
assign ptadd_fire = o_ptadd_valid_w && i_ptadd_ready;
assign ctr_eq_3 = (counter_r == 2'd3);

// counter
always@(*) begin
    counter_w = (incr_ctr) ? (counter_r + 2'd1) : counter_r;
end

always@(posedge i_clk) begin
    if(i_rst) counter_r <= 2'd0;
    else      counter_r <= counter_w;
end

assign base_addr = 8'd255 - {counter_r, 6'd0};
// regM
always@(*) begin
    // default assignment
    regM_w = regM_r;
    
    // partial update
    regM_w[base_addr -: 64] = (update_M) ? i_in_data : regM_r[base_addr -: 64];
end

always@(posedge i_clk) begin
    if(i_rst) regM_r <= 256'd0;
    else      regM_r <= regM_w;
end

// regX
always@(*) begin
    // default assignment
    regX_w = regX_r;
    
    // partial update
    regX_w[base_addr -: 64] = (update_X) ? i_in_data : regX_r[base_addr -: 64];
end

always@(posedge i_clk) begin
    if(i_rst) regX_r <= 256'd0;
    else      regX_r <= regX_w;
end

// regY
always@(*) begin
    // default assignment
    regY_w = regY_r;
    
    // partial update
    regY_w[base_addr -: 64] = (update_Y) ? i_in_data : regY_r[base_addr -: 64];
end

always@(posedge i_clk) begin
    if(i_rst) regY_r <= 256'd0;
    else      regY_r <= regY_w;
end

// ---- controller -----
// CS
always@(posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS
always@(*) begin
    // default assignment
    status_w = status_r;

    case(status_r)
        S_RESET:  status_w = S_RECV_M;
        S_RECV_M: status_w = (ctr_eq_3 && io_fire) ? S_RECV_X : status_r;
        S_RECV_X: status_w = (ctr_eq_3 && io_fire) ? S_RECV_Y : status_r;
        S_RECV_Y: status_w = (ctr_eq_3 && io_fire) ? S_DONE : status_r;
        S_DONE:   status_w = (ptadd_fire) ? S_RECV_M : status_r;
    endcase
end

// OL
always@(*) begin
    // default assignment
    o_in_ready_w    = 1'b0;
    o_ptadd_valid_w = 1'b0;
    incr_ctr        = 1'b0;
    update_M        = 1'b0;
    update_X        = 1'b0;
    update_Y        = 1'b0;

    case(status_r) 
        S_RECV_M: begin
            o_in_ready_w = 1'b1;
            update_M     = io_fire;
            incr_ctr     = io_fire;
        end
        S_RECV_X: begin
            o_in_ready_w = 1'b1;
            update_X     = io_fire;
            incr_ctr     = io_fire;
        end
        S_RECV_Y: begin
            o_in_ready_w = 1'b1;
            update_Y     = io_fire;
            incr_ctr     = io_fire;
        end
        S_DONE: begin
            o_ptadd_valid_w = 1'b1;
        end
    endcase
end


// -------- io -------- 
assign o_ptadd_m     = regM_r[254:0];
assign o_ptadd_xp    = regX_r[254:0];
assign o_ptadd_yp    = regY_r[254:0];
assign o_in_ready    = o_in_ready_w;
assign o_ptadd_valid = o_ptadd_valid_w;
endmodule