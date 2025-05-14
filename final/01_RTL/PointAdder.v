`define CONST_D 255'h52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3
// `include "./utils.v"
module PointAdder(
    input i_clk,
    input i_rst,
    // --- IO ---
    input i_in_valid,
    input [63:0] i_in_data,
    output o_in_ready,
    // --- Reducer ---
    input i_reduce_ready,
    output [254:0] o_reduce_xmp,
    output [254:0] o_reduce_ymp,
    output [254:0] o_reduce_zmp,
    output o_reduce_valid
);

// -------- wires and regs ---------
// point r
reg [254:0] Xr_r, Xr_w, Yr_r, Yr_w, Zr_r, Zr_w;
reg rst_pointR, wen_pointR;

// M
reg [255:0] M_r, M_w;
reg wen_M;
// Xp
reg [255:0] Xp_r, Xp_w;
reg wen_Xp;
// Yp
reg [255:0] Yp_r, Yp_w;
reg wen_Yp;


// counter
reg [7:0] counter_r, counter_w;
reg rst_counter, incr_counter;
wire [7:0] M_bit_idx;
wire [7:0] base_addr;

// check_flag
reg check_flag_r, check_flag_w;
reg set_check_flag, rst_check_flag;

// Controller
localparam S_RESET   = 4'd0,
           S_RECV_M  = 4'd1,
           S_RECV_X  = 4'd2,
           S_RECV_Y  = 4'd3,
           S_PTADD1  = 4'd4,
           S_PTADD2  = 4'd5,
           S_PTADD3  = 4'd6,
           S_PTADD4  = 4'd7,
           S_CHECK_M = 4'd8,
           S_DONE_Z  = 4'd9,
           S_DONE_X  = 4'd10,
           S_DONE_Y  = 4'd11;

reg [3:0] status_r, status_w;
wire io_fire, load_done, ptadd_done, reduce_fire;  // input signals
reg o_in_ready_w, o_reduce_valid_w;                // output signals
reg sel_point;                                     // sel r(0) or p(1)

// point adder data path
reg [254:0] tmp_r [0:4];
reg [254:0] tmp_w [0:4];

// valid_bit flag for only set one cycle valid signals
reg valid_mm1_flag_r, valid_mm1_flag_w;
reg valid_mm2_flag_r, valid_mm2_flag_w;
reg valid_mm3_flag_r, valid_mm3_flag_w;
// reg valid_add1_flag_r, valid_add1_flag_w;
// reg valid_add2_flag_r, valid_add2_flag_w;

reg [254:0] mm1_a, mm1_b; // mm1 input data
wire [254:0] mm1_o;       // mm1 output data
reg sela_mm1;             // mm1 control signals
reg [1:0] selb_mm1;
reg valid_mm1;
wire valid_mm1_o;         // mm1 status signals

reg [254:0] mm2_a, mm2_b;       // mm2 input data
wire [254:0] mm2_o;             // mm2 output data
reg [1:0] sela_mm2, selb_mm2;   // mm2 control signals
reg valid_mm2;
wire valid_mm2_o;               // mm2 status signals

reg [254:0] mm3_a, mm3_b;       // mm3 input data
wire [254:0] mm3_o;             // mm3 output data
reg [1:0] sela_mm3, selb_mm3;   // mm3 control signals
reg valid_mm3;
wire valid_mm3_o;               // mm3 status signals

reg [254:0] add1_a, add1_b;     // add1 input data
wire [254:0] add1_o;            // add1 output data
reg [1:0] sela_add1, selb_add1; // add1 control signals
reg op_add1, valid_add1;
wire valid_add1_o;              // add1 status signals

reg [254:0] add2_a, add2_b;     // add2 input data
wire [254:0] add2_o;            // add2 output data
reg [1:0] sela_add2, selb_add2; // add2 control signals
reg op_add2, valid_add2;
wire valid_add2_o;              // add2 status signals

wire [254:0] mm4_o;             // mm4 output data
wire valid_mm4;                 // mm4 control signals
wire valid_mm4_o;               // mm4 status signals

wire [254:0] add3_o;            // add3 output signals
reg op_add3;                    // add3 control signals
wire valid_add3_o;              // add3 status signals

reg wbsel_reg1, wbsel_reg2, wbsel_reg3; // registers write signals
reg [1:0] wbsel_reg4;
reg wen_reg1, wen_reg2, wen_reg3, wen_reg4, wen_reg5;

wire [254:0] X2, Y2, Z2;
wire [254:0] ptadd_x3, ptadd_y3, ptadd_z3;
reg [254:0] reg1_wdata, reg2_wdata, reg3_wdata, reg4_wdata;

wire stage1_done, stage2_done, stage3_done, stage4_done;


// -------- data path -------- 
// point r 
always@(*) begin
    Xr_w = Xr_r;

    if(rst_pointR) Xr_w = 255'd0;
    else if(wen_pointR) Xr_w = ptadd_x3; 
end
always@(posedge i_clk) begin
    if(i_rst) Xr_r <= 255'd0;
    else      Xr_r <= Xr_w;
end

always@(*) begin
    Yr_w = Yr_r;

    if(rst_pointR) Yr_w = 255'd1;
    else if(wen_pointR) Yr_w = ptadd_y3;
end
always@(posedge i_clk) begin
    if(i_rst) Yr_r <= 255'd1;
    else      Yr_r <= Yr_w;
end

always@(*) begin
    Zr_w = Zr_r;

    if(rst_pointR) Zr_w = 255'd1;
    else if(wen_pointR) Zr_w = ptadd_z3;
end
always@(posedge i_clk) begin
    if(i_rst) Zr_r <= 255'd1;
    else      Zr_r <= Zr_w;
end

// point p
always@(*) begin
    // default assignment
    Xp_w = Xp_r;

    Xp_w[base_addr -: 64] = (wen_Xp) ? i_in_data : Xp_r[base_addr -: 64];
end
always@(posedge i_clk) begin
    if(i_rst) Xp_r <= 255'd0;
    else      Xp_r <= Xp_w;
end

always@(*) begin
    // default assignment
    Yp_w = Yp_r;

    Yp_w[base_addr -: 64] = (wen_Yp) ? i_in_data : Yp_r[base_addr -: 64];
end
always@(posedge i_clk) begin
    if(i_rst) Yp_r <= 255'd0;
    else      Yp_r <= Yp_w;
end

// M
always@(*) begin
    // default assignment
    M_w = M_r;

    M_w[base_addr -: 64] = (wen_M) ? i_in_data : M_r[base_addr -: 64];
end
always@(posedge i_clk) begin
    if(i_rst) M_r <= 255'd0;
    else      M_r <= M_w;
end

// counter
always@(*) begin
    counter_w = counter_r;

    if(rst_counter) counter_w = 8'd0;
    else if(incr_counter) counter_w = counter_r + 8'd1;
end
always@(posedge i_clk) begin
    if(i_rst) counter_r <= 8'd0;
    else      counter_r <= counter_w;
end

assign M_bit_idx = (!ptadd_done) ? (8'd254-counter_r) : 8'd0;
assign base_addr = 8'd255 - {counter_r[1:0], 6'd0};

// check flag
always@(*) begin
    check_flag_w = check_flag_r;

    if(rst_check_flag) check_flag_w = 1'b0;
    else if(set_check_flag) check_flag_w = 1'b1;
end
always@(posedge i_clk) begin
    if(i_rst) check_flag_r <= 1'b0;
    else      check_flag_r <= check_flag_w;
end

// -------- data path for point adder ---------
assign stage1_done = valid_mm1_o && valid_mm2_o && valid_mm3_o && valid_mm4_o;
assign stage2_done = valid_mm1_o && valid_mm2_o && valid_add3_o && valid_add2_o;
assign stage3_done = valid_mm1_o && valid_mm2_o && valid_mm3_o;
assign stage4_done = valid_mm1_o && valid_mm2_o && valid_mm4_o;
assign comp_done   = stage1_done && stage2_done && stage3_done && stage4_done;

assign valid_mm4 = valid_add1_o && valid_add2_o;
assign ptadd_x3 = mm1_o;
assign ptadd_y3 = mm2_o;
assign ptadd_z3 = mm4_o;

// select point addtion's operand
assign X2 = (sel_point) ? Xp_r : Xr_r;
assign Y2 = (sel_point) ? Yp_r : Yr_r;
assign Z2 = (sel_point) ? 255'd1 : Zr_r;

// valid bit flags
always @(posedge i_clk) begin
    if(i_rst) begin
        valid_mm1_flag_r <= 1'b0;
        valid_mm2_flag_r <= 1'b0;
        valid_mm3_flag_r <= 1'b0;
    end
    else begin
        valid_mm1_flag_r <= valid_mm1_flag_w;
        valid_mm2_flag_r <= valid_mm2_flag_w;
        valid_mm3_flag_r <= valid_mm3_flag_w;
    end
end

// select MM1 operands
always@(*) begin
    mm1_a = 255'd0;
    case(sela_mm1)
        1'b0: mm1_a = Xr_r;
        1'b1: mm1_a = tmp_r[0];
    endcase
end
always@(*) begin
    mm1_b = 255'd0;
    case(selb_mm1)
        2'd0: mm1_b = X2;
        2'd1: mm1_b = tmp_r[0];
        2'd2: mm1_b = tmp_r[3];
        2'd3: mm1_b = add1_o;
    endcase
end
// select MM2 operands
always@(*) begin
    mm2_a = 255'd0;

    case(sela_mm2)
        2'd0: mm2_a = Yr_r;
        2'd1: mm2_a = tmp_r[0];
        2'd2: mm2_a = tmp_r[1];
    endcase
end
always@(*) begin
    mm2_b = 255'd0;

    case(selb_mm2)
        2'd0: mm2_b = Y2;
        2'd1: mm2_b = tmp_r[2];
        2'd2: mm2_b = tmp_r[4];
        2'd3: mm2_b = add2_o;
    endcase
end
// select MM3 operands
always@(*)begin
    mm3_a = 255'd0;

    case(sela_mm3)
        2'd0: mm3_a = Zr_r;
        2'd1: mm3_a = `CONST_D;
        2'd2: mm3_a = add1_o;
    endcase
end
always@(*) begin
    mm3_b = 255'd0;

    case(selb_mm3)
        2'd0: mm3_b = Z2;
        2'd1: mm3_b = add2_o;
        2'd2: mm3_b = tmp_r[2];
    endcase
end

// select ADD1 operands
always@(*) begin
    add1_a = 255'd0;

    case(sela_add1)
        2'd0: add1_a = Xr_r;
        2'd1: add1_a = tmp_r[2];
        2'd2: add1_a = tmp_r[3];
    endcase
end
always@(*) begin
    add1_b = 255'd0;

    case(selb_add1)
        2'd0: add1_b = Yr_r;
        2'd1: add1_b = tmp_r[1];
        2'd2: add1_b = tmp_r[3];
    endcase
end

// select ADD2 operands
always@(*) begin
    add2_a = 255'd0;

    case(sela_add2)
        2'd0: add2_a = X2;
        2'd1: add2_a = tmp_r[1];
        2'd2: add2_a = tmp_r[2];
    endcase
end
always@(*) begin
    add2_b = 255'd0;

    case(selb_add2)
        2'd0: add2_b = Y2;
        2'd1: add2_b = tmp_r[2];
        2'd2: add2_b = tmp_r[3];
    endcase
end

// arithmetic logic unit
ModMul MM1(.i_clk(i_clk), .i_rst(i_rst), .i_x(mm1_a), .i_y(mm1_b), .i_valid(valid_mm1), .o_mul(mm1_o), .o_valid(valid_mm1_o));
ModMul MM2(.i_clk(i_clk), .i_rst(i_rst), .i_x(mm2_a), .i_y(mm2_b), .i_valid(valid_mm2), .o_mul(mm2_o), .o_valid(valid_mm2_o));
ModMul MM3(.i_clk(i_clk), .i_rst(i_rst), .i_x(mm3_a), .i_y(mm3_b), .i_valid(valid_mm3), .o_mul(mm3_o), .o_valid(valid_mm3_o));
ModMul MM4(.i_clk(i_clk), .i_rst(i_rst), .i_x(add1_o), .i_y(add2_o), .i_valid(valid_mm4), .o_mul(mm4_o), .o_valid(valid_mm4_o));
ModAdder ADD1(.i_x(add1_a), .i_y(add1_b), .i_op(op_add1), .i_valid(valid_add1), .o_add(add1_o), .o_valid(valid_add1_o));
ModAdder ADD2(.i_x(add2_a), .i_y(add2_b), .i_op(op_add2), .i_valid(valid_add2), .o_add(add2_o), .o_valid(valid_add2_o));
ModAdder ADD3(.i_x(add1_o), .i_y(tmp_r[2]), .i_op(op_add3), .i_valid(valid_add1_o), .o_add(add3_o), .o_valid(valid_add3_o));

// buffer - reg1
always@(*) begin
    reg1_wdata = 255'd0;
    case(wbsel_reg1)
        1'b0: reg1_wdata = mm1_o;
        1'b1: reg1_wdata = mm3_o;
    endcase
end
always@(*) begin
    tmp_w[0] = (wen_reg1) ? reg1_wdata : tmp_r[0];
end

// buffer - reg2
always@(*) begin
    reg2_wdata = 255'd0;
    case(wbsel_reg2)
        1'b0: reg2_wdata = mm1_o;
        1'b1: reg2_wdata = mm2_o;
    endcase
end
always@(*) begin
    tmp_w[1] = (wen_reg2) ? reg2_wdata : tmp_r[1];
end

// buffer - reg3
always@(*) begin
    reg3_wdata = 255'd0;
    case(wbsel_reg3)
        1'b0: reg3_wdata = mm2_o;
        1'b1: reg3_wdata = tmp_r[1];
    endcase
end
always@(*) begin
    tmp_w[2] = (wen_reg3) ? reg3_wdata : tmp_r[2];
end

// buffer - reg4
always@(*) begin
    reg4_wdata = 255'd0;
    case(wbsel_reg4)
        2'd0: reg4_wdata = mm3_o;
        2'd1: reg4_wdata = mm4_o;
        2'd2: reg4_wdata = add3_o;
    endcase
end
always@(*) begin
    tmp_w[3] = (wen_reg4) ? reg4_wdata : tmp_r[3];
end

// buffer - reg5
always@(*) begin
    tmp_w[4] = (wen_reg5) ? add2_o : tmp_r[4];
end

// update all buffer
integer i;
always@(posedge i_clk) begin
    for(i=0; i<5; i=i+1) begin
        if(i_rst) tmp_r[i] <= 255'd0;
        else      tmp_r[i] <= tmp_w[i];
    end
end

// -------- controller --------  
// input signals
assign io_fire     = o_in_ready_w && i_in_valid;
assign reduce_fire = o_reduce_valid_w && i_reduce_ready;
assign load_done   = (counter_r == 8'd3);
assign ptadd_done  = (counter_r == 8'd255);

// CS
always@(posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS
always@(*) begin
    status_w = status_r;

    case(status_r)
        S_RESET:   status_w = S_RECV_M;
        S_RECV_M:  status_w = (load_done && io_fire) ? S_RECV_X : status_r;
        S_RECV_X:  status_w = (load_done && io_fire) ? S_RECV_Y : status_r;
        S_RECV_Y:  status_w = (load_done && io_fire) ? S_PTADD1 : status_r;
        S_PTADD1:  status_w = (ptadd_done) ? S_DONE_Z : ((stage1_done) ? S_PTADD2 : status_r);
        S_PTADD2:  status_w = (stage2_done) ? S_PTADD3 : status_r;
        S_PTADD3:  status_w = (stage3_done) ? S_PTADD4 : status_r;
        S_PTADD4:  status_w = (stage4_done) ? S_CHECK_M : status_r;
        S_CHECK_M: status_w = ((!check_flag_r) && M_r[M_bit_idx] && stage1_done) ? S_PTADD2 : S_PTADD1;
        S_DONE_Z:  status_w = (reduce_fire) ? S_DONE_X : status_r;
        S_DONE_X:  status_w = (reduce_fire) ? S_DONE_Y : status_r;
        S_DONE_Y:  status_w = (reduce_fire) ? S_RECV_M : status_r;
    endcase
end

// OL
always@(*) begin
    // default assignment
    // io
    o_in_ready_w = 1'b0;
    o_reduce_valid_w = 1'b0;

    // top level data path
    sel_point = 1'b0;

    rst_pointR = 1'b0;
    wen_pointR = 1'b0;

    wen_M  = 1'b0;
    wen_Xp = 1'b0;
    wen_Yp = 1'b0;

    rst_counter = 1'b0;
    incr_counter = 1'b0;

    rst_check_flag = 1'b0;
    set_check_flag = 1'b0;

    // point add data path
    sela_mm1 = 1'b0;
    selb_mm1 = 2'd0;
    valid_mm1 = 1'b0;

    sela_mm2 = 2'd0;
    selb_mm2 = 2'd0;
    valid_mm2 = 1'b0;

    sela_mm3 = 2'd0;
    selb_mm3 = 2'd0;
    valid_mm3 = 1'b0;

    sela_add1 = 2'd0;
    selb_add1 = 2'd0;
    op_add1   = 1'b0;
    valid_add1 = 1'b0;

    sela_add2 = 2'd0;
    selb_add2 = 2'd0;
    op_add2   = 1'b0;
    valid_add2 = 1'b0;

    op_add3 = 1'b0;

    wbsel_reg1 = 1'b0;
    wbsel_reg2 = 1'b0;
    wbsel_reg3 = 1'b0;
    wbsel_reg4 = 2'd0;

    wen_reg1 = 1'b0;
    wen_reg2 = 1'b0;
    wen_reg3 = 1'b0;
    wen_reg4 = 1'b0;
    wen_reg5 = 1'b0;

    valid_mm1_flag_w = valid_mm1_flag_r;
    valid_mm2_flag_w = valid_mm2_flag_r;
    valid_mm3_flag_w = valid_mm3_flag_r;

    case(status_r)
        S_RECV_M: begin
            o_in_ready_w = 1'b1;
            wen_M        = io_fire;
            incr_counter = (!load_done) && io_fire;
            rst_counter  = load_done && io_fire;
        end
        S_RECV_X: begin
            o_in_ready_w = 1'b1;
            wen_Xp       = io_fire;
            incr_counter = (!load_done) && io_fire;
            rst_counter  = load_done && io_fire;
        end
        S_RECV_Y: begin
            o_in_ready_w = 1'b1;
            wen_Yp       = io_fire;
            incr_counter = (!load_done) && io_fire;
            rst_counter  = load_done && io_fire;
        end
        S_PTADD1: begin
            if(!ptadd_done) begin
                sel_point = 1'b0;
                // stage 1 signals
                sela_mm1  = 1'd0; // x1
                selb_mm1  = 2'd0; // x2
                valid_mm1 = !valid_mm1_flag_r;

                sela_mm2  = 2'd0; // y1
                selb_mm2  = 2'd0; // y2
                valid_mm2 = !valid_mm2_flag_r;

                sela_mm3  = 2'd0; // z1
                selb_mm3  = 2'd0; // z2
                valid_mm3 = !valid_mm3_flag_r; 

                sela_add1  = 2'd0; // x1
                selb_add1  = 2'd0; // y1
                op_add1    = 1'b0; // add
                valid_add1 = 1'b1;

                sela_add2  = 2'd0; // x2
                selb_add2  = 2'd0; // y2
                op_add2    = 1'b0; // add
                valid_add2 = 1'b1;

                wbsel_reg1 = 1'b1; // mm3 (Z1Z2)
                wbsel_reg2 = 1'b0; // mm1 (X1X2)
                wbsel_reg3 = 1'b0; // mm2 (Y1Y2)
                wbsel_reg4 = 2'd1; // mm4 (X1+Y1)(X2+Y2)

                wen_reg1   = stage1_done;
                wen_reg2   = stage1_done;
                wen_reg3   = stage1_done;
                wen_reg4   = stage1_done;

                // Reset flags when stage is complete
                if(stage1_done) begin
                    valid_mm1_flag_w = 1'b0;
                    valid_mm2_flag_w = 1'b0;
                    valid_mm3_flag_w = 1'b0;
                end
                else begin
                    valid_mm1_flag_w = valid_mm1 ? 1'b1 : valid_mm1_flag_r;
                    valid_mm2_flag_w = valid_mm2 ? 1'b1 : valid_mm2_flag_r;
                    valid_mm3_flag_w = valid_mm3 ? 1'b1 : valid_mm3_flag_r;
                end
            end
        end
        S_PTADD2: begin
            // stage 2 signals
            sela_mm1  = 1'b1; // reg1(Z1Z2)
            selb_mm1  = 2'd1; // reg1(Z1Z2)
            valid_mm1 = !valid_mm1_flag_r;

            sela_mm2  = 2'd2; // reg2(X1X2)
            selb_mm2  = 2'd1; // reg3(Y1Y2)
            valid_mm2 = !valid_mm2_flag_r;

            sela_add1  = 2'd2; // reg4(X1+Y1)(X2+Y2) 
            selb_add1  = 2'd1; // reg2(X1X2)
            op_add1    = 1'b1; // sub
            op_add3    = 1'b1; // sub
            valid_add1 = 1'b1;

            sela_add2  = 2'd1; // reg2(X1X2)
            selb_add2  = 2'd1; // reg3(Y1Y2)
            op_add2    = 1'b0; // add
            valid_add2 = 1'b1;

            wbsel_reg2 = 1'b0; // mm1((Z1Z2)^2)
            wbsel_reg3 = 1'b0; // mm2(X1X2Y1Y2)
            wbsel_reg4 = 2'd2; // add3(X1Y2+X2Y1)

            wen_reg2 = stage2_done;
            wen_reg3 = stage2_done;
            wen_reg4 = stage2_done;
            wen_reg5 = stage2_done;

            // Reset flags when stage is complete
            if(stage2_done) begin
                valid_mm1_flag_w = 1'b0;
                valid_mm2_flag_w = 1'b0;
                valid_mm3_flag_w = 1'b0;
            end
            else begin
                valid_mm1_flag_w = valid_mm1 ? 1'b1 : valid_mm1_flag_r;
                valid_mm2_flag_w = valid_mm2 ? 1'b1 : valid_mm2_flag_r;
                valid_mm3_flag_w = valid_mm3 ? 1'b1 : valid_mm3_flag_r;
            end

        end
        S_PTADD3: begin
            // stage 3 signals
            sela_mm1 = 1'b1; // reg1(Z1Z2)
            selb_mm1 = 2'd2; // reg4(X1Y2+X2Y1)
            valid_mm1 = !valid_mm1_flag_r;

            sela_mm2 = 2'd1; // reg1(Z1Z2)
            selb_mm2 = 2'd2; // reg5(X1X2+Y1Y2)
            valid_mm2 = !valid_mm2_flag_r;

            sela_mm3 = 2'd1; // d
            selb_mm3 = 2'd2; // reg3(X1X2Y1Y2)
            valid_mm3 = !valid_mm3_flag_r;

            wbsel_reg1 = 1'b0; // mm1(Z1Z2(X1Y2+X2Y1))
            wbsel_reg2 = 1'b1; // mm2(Z1Z2(X1X2+Y1Y2))
            wbsel_reg3 = 1'b1; // reg2((Z1Z2)^2)
            wbsel_reg4 = 2'd0; // mm3(dX1X2Y1Y2)

            wen_reg1 = stage3_done;
            wen_reg2 = stage3_done;
            wen_reg3 = stage3_done;
            wen_reg4 = stage3_done;

            // Reset flags when stage is complete
            if(stage3_done) begin
                valid_mm1_flag_w = 1'b0;
                valid_mm2_flag_w = 1'b0;
                valid_mm3_flag_w = 1'b0;
            end
            else begin
                valid_mm1_flag_w = valid_mm1 ? 1'b1 : valid_mm1_flag_r;
                valid_mm2_flag_w = valid_mm2 ? 1'b1 : valid_mm2_flag_r;
                valid_mm3_flag_w = valid_mm3 ? 1'b1 : valid_mm3_flag_r;
            end

        end
        S_PTADD4: begin
            // stage 4 signals
            sela_mm1 = 1'b1; // reg1(Z1Z2(X1Y2+X2Y1))
            selb_mm1 = 2'd3; // add1((Z1Z2)^2-dX1X2Y1Y2)
            valid_mm1 = !valid_mm1_flag_r;

            sela_mm2 = 2'd2; // reg2(Z1Z2(X1X2+Y1Y2))
            selb_mm2 = 2'd3; // add2((Z1Z2)^2+dX1X2Y1Y2)
            valid_mm2 = !valid_mm2_flag_r;

            sela_add1 = 2'd1; // reg3((Z1Z2)^2)
            selb_add1 = 2'd2; // reg4(dX1X2Y1Y2)
            op_add1   = 1'b1; // sub
            valid_add1 = 1'b1;

            sela_add2 = 2'd2; // reg3((Z1Z2)^2)
            selb_add2 = 2'd2; // reg4(dX1X2Y1Y2)
            op_add2   = 1'b0; // add
            valid_add2 = 1'b1;

            wen_pointR = stage4_done;
            
            // Reset flags when stage is complete
            if(stage4_done) begin
                valid_mm1_flag_w = 1'b0;
                valid_mm2_flag_w = 1'b0;
                valid_mm3_flag_w = 1'b0;
            end
            else begin
                valid_mm1_flag_w = valid_mm1 ? 1'b1 : valid_mm1_flag_r;
                valid_mm2_flag_w = valid_mm2 ? 1'b1 : valid_mm2_flag_r;
                valid_mm3_flag_w = valid_mm3 ? 1'b1 : valid_mm3_flag_r;
            end

        end
        S_CHECK_M: begin
            if((!check_flag_r)&&M_r[M_bit_idx]) begin
                sel_point = 1'b1;
                set_check_flag = 1'b1;

                // stage 1 signals
                sela_mm1  = 1'd0; // x1
                selb_mm1  = 2'd0; // x2
                valid_mm1 = !valid_mm1_flag_r;

                sela_mm2  = 2'd0; // y1
                selb_mm2  = 2'd0; // y2
                valid_mm2 = !valid_mm2_flag_r;

                sela_mm3  = 2'd0; // z1
                selb_mm3  = 2'd0; // z2
                valid_mm3 = !valid_mm3_flag_r; 

                sela_add1  = 2'd0; // x1
                selb_add1  = 2'd0; // y1
                op_add1    = 1'b0; // add
                valid_add1 = 1'b1;

                sela_add2  = 2'd0; // x2
                selb_add2  = 2'd0; // y2
                op_add2    = 1'b0; // add
                valid_add2 = 1'b1;

                wbsel_reg1 = 1'b1; // mm3 (Z1Z2)
                wbsel_reg2 = 1'b0; // mm1 (X1X2)
                wbsel_reg3 = 1'b0; // mm2 (Y1Y2)
                wbsel_reg4 = 2'd1; // mm4 (X1+Y1)(X2+Y2)

                wen_reg1   = stage1_done;
                wen_reg2   = stage1_done;
                wen_reg3   = stage1_done;
                wen_reg4   = stage1_done;

                // Reset flags when stage is complete
                if(stage1_done) begin
                    valid_mm1_flag_w = 1'b0;
                    valid_mm2_flag_w = 1'b0;
                    valid_mm3_flag_w = 1'b0;
                end
                else begin
                    valid_mm1_flag_w = valid_mm1 ? 1'b1 : valid_mm1_flag_r;
                    valid_mm2_flag_w = valid_mm2 ? 1'b1 : valid_mm2_flag_r;
                    valid_mm3_flag_w = valid_mm3 ? 1'b1 : valid_mm3_flag_r;
                end
            end
            else begin
                incr_counter = 1'b1;
                rst_check_flag = 1'b1;
            end
        end
        S_DONE_Z: begin
            o_reduce_valid_w = 1'b1;           
        end
        S_DONE_X: begin
            o_reduce_valid_w = 1'b1;
        end
        S_DONE_Y: begin
            o_reduce_valid_w = 1'b1;
            rst_counter      = reduce_fire;
            rst_pointR       = reduce_fire;
        end
    endcase
end

// ---------- io ------------
assign o_reduce_xmp = Xr_r;
assign o_reduce_ymp = Yr_r;
assign o_reduce_zmp = Zr_r;
assign o_in_ready = o_in_ready_w;
assign o_reduce_valid = o_reduce_valid_w;

endmodule