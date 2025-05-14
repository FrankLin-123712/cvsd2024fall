`define CONST_D 255'h52036cee2b6ffe738cc740797779e89800700a4d4141d8ab75eb4dca135978a3
`define CONST_Q 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED

// `include "./define.v"
// `include "./utils.v"
`define M regfile_r[4]

module ed25519(
    input i_clk,
    input i_rst ,
    input i_in_valid,
    output o_in_ready,
    input [63:0] i_in_data,
    output o_out_valid,
    input  i_out_ready,
    output [63:0]o_out_data
);

integer i;
parameter Q_MINUS_2 = 256'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEB;
// ------- wires and regs -------

// regfile for intermediate value
reg [255:0] regfile_r [0:7];
reg [255:0] regfile_w [0:7];
reg wen_reg0, wen_reg1, wen_reg2, wen_reg3, wen_reg4, wen_reg5, wen_reg6, wen_reg7;
reg [1:0] sel_reg0, sel_reg1, sel_reg2, sel_reg3, sel_reg4, sel_reg5, sel_reg6, sel_reg7;
reg rst_pointR, set_r_one;

// in data for update M, X, Y
reg [255:0] in_wdata, default_wdata;

// modmul
reg [254:0] modmul_a, modmul_b;
wire [254:0] modmul_o;
wire valid_mul;
reg en_mul;       // control signals
reg [3:0] sela_mul;
reg [2:0] selb_mul;

// modadd
reg [254:0] modadd_a, modadd_b;
wire [254:0] modadd_o;
reg [2:0] sela_add, selb_add;

// modsub
reg [254:0] modsub_a, modsub_b;
wire [254:0] modsub_o;
reg [3:0] sela_sub;
reg [2:0] selb_sub;

// iteration counter
reg [7:0] iter_r, iter_w;
reg rst_iter, incr_iter;  // control signals

// general counter
reg [3:0] ctr_r, ctr_w;
reg rst_ctr, incr_ctr;  // control signals
wire [7:0] bit_idx;

// #### controller ####
localparam S_RESET        = 4'd0,
           S_RECV_M       = 4'd1,
           S_RECV_X       = 4'd2,
           S_RECV_Y       = 4'd3,
           S_PRECOMP      = 4'd4,
           S_DOUBPT       = 4'd5,
           S_PTADD        = 4'd6,
           S_INV_PRECOMP  = 4'd7,
           S_INV_MUL      = 4'd8,
           S_INV_POSTCOMP = 4'd9,
           S_CAL_XGYG     = 4'd10,
           S_OUTPUT_X     = 4'd11,
           S_OUTPUT_Y     = 4'd12;
reg [3:0] status_r, status_w;
// #### controller : output signals ####
reg o_out_valid_w, o_in_ready_w; // io
reg sel_out_data;
// #### controller : input signals ####
wire io_in_fire, io_out_fire;
// out data
wire [255:0] out_data;
wire [7:0] base_addr;
// ----------- data path -------------
assign base_addr = 8'd255 - {ctr_r, 6'd0};
assign out_data = (sel_out_data) ? regfile_r[1] : regfile_r[0];

// counters
always@(*) begin
    if(rst_iter)       iter_w = 8'd0;
    else if(incr_iter) iter_w = iter_r + 8'd1;
    else               iter_w = iter_r;
end
always@(posedge i_clk) begin
    if(i_rst) iter_r <= 8'd0;
    else      iter_r <= iter_w;
end

always@(*) begin
    if(rst_ctr)       ctr_w = 4'd0;
    else if(incr_ctr) ctr_w = ctr_r + 4'd1;
    else              ctr_w = ctr_r;
end
always@(posedge i_clk) begin
    if(i_rst) ctr_r <= 4'd0;
    else      ctr_r <= ctr_w;
end

// in_wdata
always@(*) begin
    // default assignment
    default_wdata = 256'd0; 

    case({wen_reg4, wen_reg5, wen_reg6})
        3'b100: default_wdata = regfile_r[4];
        3'b010: default_wdata = regfile_r[5];
        3'b001: default_wdata = regfile_r[6];
    endcase
end
always@(*) begin
    // default assignment
    in_wdata = default_wdata;

    // partial update with input data
    in_wdata[base_addr -: 64] = i_in_data;
end

// regfile for intermediate value
always@(*) begin
    // default assignment
    for(i=0; i<8; i=i+1) regfile_w[i] = regfile_r[i];

    // pointR : Xr
    if(rst_pointR)        regfile_w[0] = 256'd0;
    else if(wen_reg0) begin
        case(sel_reg0)
            `REGF_WD_MUL: regfile_w[0] = {1'b0, modmul_o};
            `REGF_WD_ADD: regfile_w[0] = {1'b0, modadd_o};
            `REGF_WD_SUB: regfile_w[0] = {1'b0, modsub_o};
        endcase
    end

    // pointR : Yr
    if(rst_pointR)        regfile_w[1] = 256'd1;
    else if(wen_reg1) begin
        case(sel_reg1)
            `REGF_WD_MUL: regfile_w[1] = {1'b0, modmul_o};
            `REGF_WD_ADD: regfile_w[1] = {1'b0, modadd_o};
            `REGF_WD_SUB: regfile_w[1] = {1'b0, modsub_o};
        endcase
    end

    // pointR : Zr
    if(rst_pointR)        regfile_w[2] = 256'd1;
    else if(wen_reg2) begin
        case(sel_reg2)
            `REGF_WD_MUL: regfile_w[2] = {1'b0, modmul_o};
            `REGF_WD_ADD: regfile_w[2] = {1'b0, modadd_o};
            `REGF_WD_SUB: regfile_w[2] = {1'b0, modsub_o};
        endcase
    end
    
    // pointR : Tr
    if(rst_pointR)        regfile_w[3] = 256'd0;
    else if(set_r_one)    regfile_w[3] = 256'd1;
    else if(wen_reg3) begin
        case(sel_reg3)
            `REGF_WD_MUL: regfile_w[3] = {1'b0, modmul_o};
            `REGF_WD_ADD: regfile_w[3] = {1'b0, modadd_o};
            `REGF_WD_SUB: regfile_w[3] = {1'b0, modsub_o};
        endcase
    end

    // M 
    if(wen_reg4) begin
        case(sel_reg4)
            `REGF_WD_MUL:     regfile_w[4] = {1'b0, modmul_o};
            `REGF_WD_ADD:     regfile_w[4] = {1'b0, modadd_o};
            `REGF_WD_SUB:     regfile_w[4] = {1'b0, modsub_o};
            `REGF_WD_INDATA : regfile_w[4] = {in_wdata};
        endcase
    end

    // X
    if(wen_reg5) begin
        case(sel_reg5)
            `REGF_WD_MUL:     regfile_w[5] = {1'b0, modmul_o};
            `REGF_WD_ADD:     regfile_w[5] = {1'b0, modadd_o};
            `REGF_WD_SUB:     regfile_w[5] = {1'b0, modsub_o};
            `REGF_WD_INDATA : regfile_w[5] = {in_wdata};
        endcase
    end

    // Y
    if(wen_reg6) begin
        case(sel_reg6)
            `REGF_WD_MUL:     regfile_w[6] = {1'b0, modmul_o};
            `REGF_WD_ADD:     regfile_w[6] = {1'b0, modadd_o};
            `REGF_WD_SUB:     regfile_w[6] = {1'b0, modsub_o};
            `REGF_WD_INDATA : regfile_w[6] = {in_wdata};
        endcase
    end

    // reg7 
    if(wen_reg7) begin
        case(sel_reg7)
            `REGF_WD_MUL:     regfile_w[7] = {1'b0, modmul_o};
            `REGF_WD_ADD:     regfile_w[7] = {1'b0, modadd_o};
            `REGF_WD_SUB:     regfile_w[7] = {1'b0, modsub_o};
        endcase
    end
end

always@(posedge i_clk) begin
    if(i_rst) begin
        regfile_r[0] <= 256'd0;
        regfile_r[1] <= 256'd1;
        regfile_r[2] <= 256'd1;
        regfile_r[3] <= 256'd0;
        regfile_r[4] <= 256'd0;
        regfile_r[5] <= 256'd0;
        regfile_r[6] <= 256'd0;
        regfile_r[7] <= 256'd0;
    end
    else begin
        for(i=0; i<8; i=i+1) regfile_r[i] <= regfile_w[i];
    end
end

// modmul 
always@(*) begin // select modmul_a
    // default assignment
    modmul_a = 255'd0;

    case(sela_mul)
        `MUL_A_REG0:     modmul_a = regfile_r[0][254:0];
        `MUL_A_REG1:     modmul_a = regfile_r[1][254:0];
        `MUL_A_REG2:     modmul_a = regfile_r[2][254:0];
        `MUL_A_REG3:     modmul_a = regfile_r[3][254:0];
        `MUL_A_REG4:     modmul_a = regfile_r[4][254:0];
        `MUL_A_REG5:     modmul_a = regfile_r[5][254:0];
        `MUL_A_REG6:     modmul_a = regfile_r[6][254:0];
        `MUL_A_REG7:     modmul_a = regfile_r[7][254:0];
        `MUL_A_CONST_D : modmul_a = `CONST_D;
    endcase
end
always@(*) begin // select modmul_b
    // default assignment
    modmul_b = 255'd0;

    case(selb_mul)
        `MUL_B_REG0: modmul_b = regfile_r[0][254:0];
        `MUL_B_REG1: modmul_b = regfile_r[1][254:0];
        `MUL_B_REG2: modmul_b = regfile_r[2][254:0];
        `MUL_B_REG3: modmul_b = regfile_r[3][254:0];
        `MUL_B_REG4: modmul_b = regfile_r[4][254:0];
        `MUL_B_REG5: modmul_b = regfile_r[5][254:0];
        `MUL_B_REG6: modmul_b = regfile_r[6][254:0];
        `MUL_B_REG7: modmul_b = regfile_r[7][254:0];
    endcase
end

ModMul modmul0(
    .i_clk(i_clk), .i_rst(i_rst), 
    .i_x(modmul_a), .i_y(modmul_b), .i_valid(en_mul),
    .o_mul(modmul_o), .o_valid(valid_mul)
);

// modadd
always@(*) begin // select modadd_a
    // default assignment
    modadd_a = 255'd0;

    case(sela_add)
        `ADD_A_REG0: modadd_a = regfile_r[0][254:0];
        `ADD_A_REG1: modadd_a = regfile_r[1][254:0];
        `ADD_A_REG2: modadd_a = regfile_r[2][254:0];
        `ADD_A_REG3: modadd_a = regfile_r[3][254:0];
        `ADD_A_REG4: modadd_a = regfile_r[4][254:0];
        `ADD_A_REG5: modadd_a = regfile_r[5][254:0];
        `ADD_A_REG6: modadd_a = regfile_r[6][254:0];
        `ADD_A_REG7: modadd_a = regfile_r[7][254:0];
    endcase
end
always@(*) begin // select modadd_b
    // default assignment
    modadd_b = 255'd0;

    case(selb_add)
        `ADD_B_REG0: modadd_b = regfile_r[0][254:0];
        `ADD_B_REG1: modadd_b = regfile_r[1][254:0];
        `ADD_B_REG2: modadd_b = regfile_r[2][254:0];
        `ADD_B_REG3: modadd_b = regfile_r[3][254:0];
        `ADD_B_REG4: modadd_b = regfile_r[4][254:0];
        `ADD_B_REG5: modadd_b = regfile_r[5][254:0];
        `ADD_B_REG6: modadd_b = regfile_r[6][254:0];
        `ADD_B_REG7: modadd_b = regfile_r[7][254:0];
    endcase
end
ModAdd modadd0(.i_x(modadd_a), .i_y(modadd_b), .o_add(modadd_o));

// modsub
always@(*) begin // select modsub_a
    // default assignment
    modsub_a = 255'd0;

    case(sela_sub)
        `SUB_A_REG0:    modsub_a = regfile_r[0][254:0];
        `SUB_A_REG1:    modsub_a = regfile_r[1][254:0];
        `SUB_A_REG2:    modsub_a = regfile_r[2][254:0];
        `SUB_A_REG3:    modsub_a = regfile_r[3][254:0];
        `SUB_A_REG4:    modsub_a = regfile_r[4][254:0];
        `SUB_A_REG5:    modsub_a = regfile_r[5][254:0];
        `SUB_A_REG6:    modsub_a = regfile_r[6][254:0];
        `SUB_A_REG7:    modsub_a = regfile_r[7][254:0];
        `SUB_A_CONST_Q: modsub_a = `CONST_Q;
    endcase
end
always@(*) begin // select modsub_b
    // default assignment
    modsub_b = 255'd0;

    case(selb_sub)
        `SUB_B_REG0: modsub_b = regfile_r[0][254:0];
        `SUB_B_REG1: modsub_b = regfile_r[1][254:0];
        `SUB_B_REG2: modsub_b = regfile_r[2][254:0];
        `SUB_B_REG3: modsub_b = regfile_r[3][254:0];
        `SUB_B_REG4: modsub_b = regfile_r[4][254:0];
        `SUB_B_REG5: modsub_b = regfile_r[5][254:0];
        `SUB_B_REG6: modsub_b = regfile_r[6][254:0];
        `SUB_B_REG7: modsub_b = regfile_r[7][254:0];
    endcase
end
ModSub modsub0(.i_x(modsub_a), .i_y(modsub_b), .o_sub(modsub_o));

// ----------- controller -------------
assign io_in_fire  = i_in_valid && o_in_ready_w;
assign io_out_fire = o_out_valid_w && i_out_ready;

assign bit_idx = 8'd254 - iter_r;

// CS
always@(posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NL
always@(*) begin
    status_w = status_r;

    case(status_r)
        S_RESET:   status_w = S_RECV_M;
        S_RECV_M:  status_w = ((ctr_r == 4'd3) && io_in_fire) ? S_RECV_X : status_r;
        S_RECV_X:  status_w = ((ctr_r == 4'd3) && io_in_fire) ? S_RECV_Y : status_r;
        S_RECV_Y:  status_w = ((ctr_r == 4'd3) && io_in_fire) ? S_PRECOMP : status_r;
        S_PRECOMP: status_w = (ctr_r == 4'd3) ? S_DOUBPT : status_r;
        S_DOUBPT: begin
            if(iter_r < 8'd255) begin
                if(ctr_r == 4'd9) begin
                    status_w = (`M[bit_idx]) ? S_PTADD : S_DOUBPT;
                end
                else status_w = status_r;
            end
            else status_w = S_INV_PRECOMP;
        end
        S_PTADD:        status_w = (ctr_r == 4'd8) ? S_DOUBPT : status_r;
        S_INV_PRECOMP:  status_w = (ctr_r == 4'd3) ? S_INV_MUL : status_r;
        S_INV_MUL:      status_w = (iter_r == 8'd248) ? S_INV_POSTCOMP : status_r;
        S_INV_POSTCOMP: status_w = (ctr_r == 4'd14) ? S_CAL_XGYG : status_r;
        S_CAL_XGYG:     status_w = (ctr_r == 4'd3) ? S_OUTPUT_X : status_r;
        S_OUTPUT_X:     status_w = ((ctr_r == 4'd3) && io_out_fire) ? S_OUTPUT_Y : status_r;
        S_OUTPUT_Y:     status_w = ((ctr_r == 4'd3) && io_out_fire) ? S_RECV_M : status_r;
    endcase
end

// OL
always@(*) begin
    // default assignment
    // io
    o_in_ready_w  = 1'b0;
    o_out_valid_w = 1'b0;
    sel_out_data  = 1'b0;
    
    // regfile
    wen_reg0   = 1'b0;
    wen_reg1   = 1'b0;
    wen_reg2   = 1'b0;
    wen_reg3   = 1'b0;
    wen_reg4   = 1'b0;
    wen_reg5   = 1'b0;
    wen_reg6   = 1'b0;
    wen_reg7   = 1'b0;

    sel_reg0   = 1'b0;
    sel_reg1   = 1'b0;
    sel_reg2   = 1'b0;
    sel_reg3   = 1'b0;
    sel_reg4   = 1'b0;
    sel_reg5   = 1'b0;
    sel_reg6   = 1'b0;
    sel_reg7   = 1'b0;
    
    rst_pointR = 1'b0;
    set_r_one  = 1'b0;

    // modmul 
    en_mul     = 1'b0;
    sela_mul   = 4'd0;
    selb_mul   = 4'd0;
    // modadd
    sela_add   = 3'd0;
    selb_add   = 3'd0;
    // modsub 
    sela_sub   = 1'b0;
    selb_sub   = 1'b0;

    // iter
    rst_iter   = 1'b0;
    incr_iter  = 1'b0;
    // ctr
    rst_ctr    = 1'b0;
    incr_ctr   = 1'b0;

    case(status_r)
        S_RECV_M: begin
            o_in_ready_w = 1'b1;
            wen_reg4     = io_in_fire;
            sel_reg4     = `REGF_WD_INDATA;
            incr_ctr     = (ctr_r == 4'd3) ? 1'b0 : io_in_fire;
            rst_ctr      = (ctr_r == 4'd3) ? io_in_fire : 1'b0;
        end
        S_RECV_X: begin
            o_in_ready_w = 1'b1;
            wen_reg5     = io_in_fire;
            sel_reg5     = `REGF_WD_INDATA;
            incr_ctr     = (ctr_r == 4'd3) ? 1'b0 : io_in_fire;
            rst_ctr      = (ctr_r == 4'd3) ? io_in_fire : 1'b0;
        end
        S_RECV_Y: begin
            o_in_ready_w = 1'b1;
            wen_reg6     = io_in_fire;
            sel_reg6     = `REGF_WD_INDATA;
            incr_ctr     = (ctr_r == 4'd3) ? 1'b0 : io_in_fire;
            rst_ctr      = (ctr_r == 4'd3) ? io_in_fire : 1'b0;
        end 
        S_PRECOMP: begin
            case(ctr_r)
                4'd0: begin
                    // modmul
                    sela_mul = `MUL_A_REG5; // Xp
                    selb_mul = `MUL_B_REG6; // Yp
                    en_mul   = 1'b1;
                    // modadd
                    sela_add = `ADD_A_REG6; // Yp
                    selb_add = `ADD_B_REG5; // Xp
                    // modsub
                    sela_sub = `SUB_A_REG6; // Yp
                    selb_sub = `SUB_B_REG5; // Xp
                    // write back
                    wen_reg6 = 1'b1; // Yp-Xp
                    sel_reg6 = `REGF_WD_SUB;
                    wen_reg7 = 1'b1; // Yp+Xp
                    sel_reg7 = `REGF_WD_ADD;
                    // ctr
                    incr_ctr = 1'b1;
                end 
                4'd1: begin
                    // write back
                    wen_reg5 = valid_mul;  // Tp
                    sel_reg5 = `REGF_WD_MUL;
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd2: begin
                    // modmul
                    sela_mul = `MUL_A_CONST_D; // const d
                    selb_mul = `MUL_B_REG5;    // Tp(XpYp)
                    en_mul   = 1'b1;
                    // ctr
                    incr_ctr  = 1'b1;
                end
                4'd3: begin
                    // write back
                    wen_reg5 = valid_mul;
                    sel_reg5 = `REGF_WD_MUL; // dTp 
                    // ctr
                    rst_ctr = 1'b1;
                end
            endcase
        end
        S_DOUBPT: begin
            if(iter_r < 8'd255) begin
                case(ctr_r)
                    4'd0: begin
                        // modmul (compute A=Xr*Xr)
                        sela_mul = `MUL_A_REG0; // Xr
                        selb_mul = `MUL_B_REG0; // Xr
                        en_mul   = 1'b1;
                        // modadd (compute Xr+Yr)
                        sela_add = `ADD_A_REG0; // Xr
                        selb_add = `ADD_B_REG1; // Yr
                        // write back
                        wen_reg3 = 1'b1;  // Xr+Yr
                        sel_reg3 = `REGF_WD_ADD;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd1: begin
                        // modmul (compute B=Yr*Yr)
                        sela_mul = `MUL_A_REG1; // Yr
                        selb_mul = `MUL_B_REG1; // Yr
                        en_mul   = 1'b1;
                        // write back
                        wen_reg0 = valid_mul;
                        sel_reg0 = `REGF_WD_MUL;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd2: begin
                        // modmul (compute Zr*Zr)
                        sela_mul = `MUL_A_REG2; // Zr
                        selb_mul = `MUL_B_REG2; // Zr
                        en_mul   = 1'b1;
                        // write back
                        wen_reg1 = valid_mul;
                        sel_reg1 = `REGF_WD_MUL; // B
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd3: begin
                        // modmul (compute (Xr+Yr)^2)
                        sela_mul = `MUL_A_REG3; // (Xr+Yr)
                        selb_mul = `MUL_B_REG3; // (Xr+Yr)
                        en_mul   = 1'b1;
                        // modadd (compute H=A+B)
                        sela_add = `ADD_A_REG0; // A
                        selb_add = `ADD_B_REG1; // B
                        // modsub (compute G=A-B)
                        sela_sub = `SUB_A_REG0; // A
                        selb_sub = `SUB_B_REG1; // B
                        // write back
                        wen_reg0 = 1'b1; // H
                        sel_reg0 = `REGF_WD_ADD;   
                        wen_reg1 = 1'b1; // G
                        sel_reg1 = `REGF_WD_SUB;
                        wen_reg2 = valid_mul; // Zr^2
                        sel_reg2 = `REGF_WD_MUL;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd4: begin
                        // modadd (compute C=Zr^2+Zr^2)
                        sela_add = `ADD_A_REG2; // Zr^2
                        selb_add = `ADD_B_REG2; // Zr^2
                        // write back
                        wen_reg2 = 1'b1;
                        sel_reg2 = `REGF_WD_ADD;  // C
                        wen_reg3 = valid_mul;
                        sel_reg3 = `REGF_WD_MUL;  // (Xr+Yr)^2
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd5: begin
                        // modmul (compute Y3=G*H)
                        sela_mul = `MUL_A_REG0;   // H 
                        selb_mul = `MUL_B_REG1;   // G
                        en_mul   = 1'b1;
                        // modadd (compute F=C+G)
                        sela_add = `ADD_A_REG2; // C
                        selb_add = `ADD_B_REG1; // G
                        // modsub (compute E=H-(Xr+Yr)^2)
                        sela_sub = `SUB_A_REG0; // H
                        selb_sub = `SUB_B_REG3; // (Xr+Yr)^2
                        // write back
                        wen_reg2 = 1'b1; // F
                        sel_reg2 = `REGF_WD_ADD;
                        wen_reg3 = 1'b1; // E
                        sel_reg3 = `REGF_WD_SUB;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd6: begin
                        // modmul (compute Z3=F*G)
                        sela_mul = `MUL_A_REG2; // F
                        selb_mul = `MUL_B_REG1; // G
                        en_mul   = 1'b1;
                        // write back
                        wen_reg1 = valid_mul; // Y3
                        sel_reg1 = `REGF_WD_MUL;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd7: begin
                        // modmul (compute X3=E*F)
                        sela_mul = `MUL_A_REG3; // E 
                        selb_mul = `MUL_B_REG2; // F
                        en_mul   = 1'b1;
                        // write back
                        wen_reg2 = valid_mul; // Z3
                        sel_reg2 = `REGF_WD_MUL;
                        // ctr
                        incr_ctr = 1'b1;
                    end
                    4'd8: begin
                        // modmul (compute T3=E*H)
                        sela_mul = `MUL_A_REG3; // E
                        selb_mul = `MUL_B_REG0; // H
                        en_mul   = 1'b1;
                        // write back
                        wen_reg0 = valid_mul; // X3
                        sel_reg0 = `REGF_WD_MUL;
                        // ctr
                        incr_ctr = 1'b1;
                   end
                    4'd9: begin
                        // write back
                        wen_reg3 = valid_mul; // T3 
                        sel_reg3 = `REGF_WD_MUL;
                        // ctr
                        if(`M[bit_idx]) begin
                            rst_ctr = 1'b1;
                        end
                        else begin
                            incr_iter = 1'b1;
                            rst_ctr   = 1'b1;
                        end
                    end

                endcase
            end
            else begin
                rst_iter = 1'b1;
                // set reg3 to 1 (prepare r for finding inverse z)
                set_r_one = 1'b1;
            end
        end
        S_PTADD: begin
            case(ctr_r)
                4'd0: begin
                    // modmul (compute Tr*dTp)
                    sela_mul = `MUL_A_REG3; // Tr
                    selb_mul = `MUL_B_REG5; // dTp 
                    en_mul   = 1'b1;
                    // modadd (compute sum1=Yr+Xr)
                    sela_add = `ADD_A_REG1; // Yr
                    selb_add = `ADD_B_REG0; // Xr
                    // modsub (compute sub1=Yr-Xr)
                    sela_sub = `SUB_A_REG1; // Yr
                    selb_sub = `SUB_B_REG0; // Xr
                    // write back
                    wen_reg0 = 1'b1; // sub1
                    sel_reg0 = `REGF_WD_SUB;
                    wen_reg1 = 1'b1; // sum1
                    sel_reg1 = `REGF_WD_ADD;
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd1: begin
                    // modmul (compute A=sub1*sub2)
                    sela_mul = `MUL_A_REG0; // sub1=Yr-Xr 
                    selb_mul = `MUL_B_REG6; // sub2=Yp-Xp
                    en_mul   = 1'b1;
                    // modadd (compute D=Zr+Zr)
                    sela_add = `ADD_A_REG2; // Zr
                    selb_add = `ADD_B_REG2; // Zr
                    // write back
                    wen_reg2 = 1'b1;
                    sel_reg2 = `REGF_WD_ADD; // D 
                    wen_reg3 = valid_mul;
                    sel_reg3 = `REGF_WD_MUL; // dTrTp
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd2: begin
                    // modmul (compute B=sum1*sum2)
                    sela_mul = `MUL_A_REG1; // sum1
                    selb_mul = `MUL_B_REG7; // sum2
                    en_mul   = 1'b1;
                    // modadd (compute C=dTrTp+dTrTp)
                    sela_add = `ADD_A_REG3; // dTrTp
                    selb_add = `ADD_B_REG3; // dTrTp
                    // write back
                    wen_reg0 = valid_mul;
                    sel_reg0 = `REGF_WD_MUL; // A
                    wen_reg3 = 1'b1;
                    sel_reg3 = `REGF_WD_ADD; // C
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd3: begin
                    // modadd
                    sela_add = `ADD_A_REG2; // D
                    selb_add = `ADD_B_REG3; // C
                    // modsub
                    sela_sub = `SUB_A_REG2; // D
                    selb_sub = `SUB_B_REG3; // C
                    // write back
                    wen_reg1 = valid_mul;
                    sel_reg1 = `REGF_WD_MUL; // B
                    wen_reg2 = 1'b1;
                    sel_reg2 = `REGF_WD_SUB; // F
                    wen_reg3 = 1'b1;
                    sel_reg3 = `REGF_WD_ADD; // G
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd4: begin
                    // modmul (compute Z3=F*G)
                    sela_mul = `MUL_A_REG2; // F
                    selb_mul = `MUL_B_REG3; // G
                    en_mul   = 1'b1;
                    // modadd (compute H=B+A)
                    sela_add = `ADD_A_REG1; // B
                    selb_add = `ADD_B_REG0; // A
                    // modsub (compute E=B-A)
                    sela_sub = `SUB_A_REG1; // B
                    selb_sub = `SUB_B_REG0; // A
                    // write back
                    wen_reg0 = 1'b1;
                    sel_reg0 = `REGF_WD_SUB; // E
                    wen_reg1 = 1'b1;
                    sel_reg1 = `REGF_WD_ADD; // H
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd5: begin
                    // modmul (compute X3=E*F)
                    sela_mul = `MUL_A_REG0; // E
                    selb_mul = `MUL_B_REG2; // F
                    en_mul   = 1'b1;
                    // write back
                    wen_reg2 = valid_mul;
                    sel_reg2 = `REGF_WD_MUL; // Z3
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd6: begin
                    // modmul (compute T3=E*H)
                    sela_mul = `MUL_A_REG0; // E
                    selb_mul = `MUL_B_REG1; // H
                    en_mul   = 1'b1;
                    // write back
                    wen_reg0 = valid_mul;
                    sel_reg0 = `REGF_WD_MUL; // X3
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd7: begin
                    // modmul (compute Y3=G*H)
                    sela_mul = `MUL_A_REG1; // H
                    selb_mul = `MUL_B_REG3; // G
                    en_mul   = 1'b1;
                    // write back
                    wen_reg3 = valid_mul;
                    sel_reg3 = `REGF_WD_MUL; // T3
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd8: begin
                    // write back
                    wen_reg1 = valid_mul; 
                    sel_reg1 = `REGF_WD_MUL; // Y3
                    // ctr
                    incr_iter = 1'b1;
                    rst_ctr   = 1'b1;
                end
            endcase
        end
        S_INV_PRECOMP: begin
            // ctr
            {rst_ctr, incr_ctr} = (ctr_r == 4'd3) ? 2'b10 : 2'b01;
            // compute unit
            case(ctr_r)
                4'd0: begin
                    // modmul (compute b^2)
                    sela_mul = `MUL_A_REG2; // b
                    selb_mul = `MUL_B_REG2; // b
                    en_mul   = 1'b1;
                end
                4'd1: begin
                    // write back
                    wen_reg4 = valid_mul;
                    sel_reg4 = `REGF_WD_MUL; // b^2
                end
                4'd2: begin
                    // modmul (comptue b^4)
                    sela_mul = `MUL_A_REG4; // b^2
                    selb_mul = `MUL_B_REG4; // b^2
                    en_mul   = 1'b1;
                end
                4'd3: begin
                    // write back
                    wen_reg5 = valid_mul;
                    sel_reg5 = `REGF_WD_MUL; // b^4
                end
            endcase
        end
        S_INV_MUL: begin
            // ctr
            if(iter_r < 8'd248) begin
                if(((iter_r < 8'd247) && (ctr_r == 4'd1)) || ((iter_r == 8'd247) && (ctr_r == 4'd2))) begin
                    incr_iter = 1'b1;       
                    rst_ctr   = 1'b1;
                end
                else incr_ctr = 1'b1;
            end
            else begin
                rst_iter = 1'b1;
            end 
            // compute unit 
            if(iter_r == 8'd0) begin
                if(ctr_r == 1'b0) begin
                    // modmul (comptue b^3)
                    sela_mul = `MUL_A_REG2; // b
                    selb_mul = `MUL_B_REG4; // b^2
                    en_mul   = 1'b1;
                end 
                else begin
                    // modmul (compute b^4)
                    sela_mul = `MUL_A_REG5; // b^4
                    selb_mul = `MUL_B_REG5; // b^4
                    en_mul   = 1'b1;
                    // write back
                    wen_reg3 = valid_mul;
                    sel_reg3 = `REGF_WD_MUL;
                    wen_reg4 = valid_mul;
                    sel_reg4 = `REGF_WD_MUL;
                end
            end
            else if(iter_r == 8'd247) begin
                case(ctr_r)
                    4'd0: begin
                        // modmul
                        sela_mul = `MUL_A_REG4;
                        selb_mul = `MUL_B_REG5;
                        en_mul   = 1'b1;
                        // write back
                        wen_reg6 = valid_mul;
                        sel_reg6 = `REGF_WD_MUL;
                    end
                    4'd1: begin
                        // modmul
                        sela_mul = `MUL_A_REG6;
                        selb_mul = `MUL_B_REG6;
                        en_mul   = 1'b1;
                        // write back
                        wen_reg4 = valid_mul;
                        sel_reg4 = `REGF_WD_MUL;
                    end
                    4'd2: begin
                        // write back
                        wen_reg5 = valid_mul;
                        sel_reg5 = `REGF_WD_MUL;
                    end
                endcase
            end
            else begin
                if(ctr_r == 4'd1) begin
                    // modmul (compute b^(2^(2+iter)))
                    sela_mul = (iter_r[0]) ? `MUL_A_REG6 : `MUL_A_REG5;
                    selb_mul = (iter_r[0]) ? `MUL_B_REG6 : `MUL_B_REG5;
                    en_mul   = 1'b1;
                    // write back
                    wen_reg4 = valid_mul;
                    sel_reg4 = `REGF_WD_MUL;
                end
                else begin
                    // modmul (compute b^(2^(1+iter)-1))
                    sela_mul = `MUL_A_REG4;
                    selb_mul = (iter_r[0]) ? `MUL_B_REG5 : `MUL_B_REG6;
                    en_mul   = 1'b1;
                    // write back
                    {wen_reg6, wen_reg5} = (iter_r[0]) ? {valid_mul, 1'b0} : {1'b0, valid_mul};
                    {sel_reg6, sel_reg5} = {`REGF_WD_MUL, `REGF_WD_MUL};
                end
            end
        end
        S_INV_POSTCOMP: begin
            // ctr
            {rst_ctr, incr_ctr} = (ctr_r == 4'd14) ? 2'b10 : 2'b01;
            // compute unit
            case(ctr_r)
                4'd0: begin
                    // modmul (compute C=A*A)
                    sela_mul = `MUL_A_REG4; // A
                    selb_mul = `MUL_B_REG4; // A
                    en_mul   = 1'b1;
                end
                4'd1: begin
                    // modmul (compute D=B*B)
                    sela_mul = `MUL_A_REG5; // B
                    selb_mul = `MUL_B_REG5; // B
                    en_mul   = 1'b1;
                    // write back
                    wen_reg4 = valid_mul;  // C
                    sel_reg4 = `REGF_WD_MUL;
                end
                4'd2: begin
                    // modmul (compute E=C*C)
                    sela_mul = `MUL_A_REG4; // C
                    selb_mul = `MUL_B_REG4; // C
                    en_mul   = 1'b1;
                    // write back
                    wen_reg5 = valid_mul; // D
                    sel_reg5 = `REGF_WD_MUL;
                end
                4'd3: begin
                    // modmul (compute F=b*D)
                    sela_mul = `MUL_A_REG2; // b
                    selb_mul = `MUL_B_REG5; // D
                    en_mul   = 1'b1;
                    // write back
                    wen_reg4 = valid_mul;  // E
                    sel_reg4 = `REGF_WD_MUL;
                end
                4'd4: begin
                    // write back
                    wen_reg5 = valid_mul; // F
                    sel_reg5 = `REGF_WD_MUL;
                end
                4'd5: begin
                    // modmul (compute G=E*F)
                    sela_mul = `MUL_A_REG4; // E
                    selb_mul = `MUL_B_REG5; // F
                    en_mul   = 1'b1;
                end
                4'd6: begin
                    // write back
                    wen_reg4 = valid_mul; // G
                    sel_reg4 = `REGF_WD_MUL;
                end
                4'd7: begin
                    // modmul (compute H=G*G)
                    sela_mul = `MUL_A_REG4; // G
                    selb_mul = `MUL_B_REG4; // G
                    en_mul   = 1'b1;
                end
                4'd8: begin
                    // write back
                    wen_reg5 = valid_mul; // H
                    sel_reg5 = `REGF_WD_MUL;
                end
                4'd9: begin
                    // modmul (compute I=H*H)
                    sela_mul = `MUL_A_REG5; // H
                    selb_mul = `MUL_B_REG5; // H
                    en_mul   = 1'b1;
                end
                4'd10: begin
                    // write back
                    wen_reg4 = valid_mul; // I
                    sel_reg4 = `REGF_WD_MUL;
                end
                4'd11: begin
                    // modmul (compute J=I*I)
                    sela_mul = `MUL_A_REG4; // I
                    selb_mul = `MUL_B_REG4; // I
                    en_mul   = 1'b1;
                end
                4'd12: begin
                    // write back
                    wen_reg5 = valid_mul; // J
                    sel_reg5 = `REGF_WD_MUL;
                end
                4'd13: begin
                    // modmul (compute b^-1=J*(b^3))
                    sela_mul = `MUL_A_REG5; // J
                    selb_mul = `MUL_B_REG3; // b^3
                    en_mul   = 1'b1;
                end
                4'd14: begin
                    // write back
                    wen_reg3 = valid_mul; // b^-1
                    sel_reg3 = `REGF_WD_MUL;
                end
            endcase
        end
        S_CAL_XGYG: begin
            case(ctr_r)
                4'd0: begin
                    // modmul (compute X*inv_Z)
                    sela_mul = `MUL_A_REG0; // X
                    selb_mul = `MUL_B_REG3; // inv_Z
                    en_mul   = 1'b1;
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd1: begin
                    // modmul (compute Y*inv_Z)
                    sela_mul = `MUL_A_REG1; // Y
                    selb_mul = `MUL_B_REG3; // inv_Z
                    en_mul   = 1'b1;
                    // write back
                    wen_reg0 = valid_mul;  // X/Z
                    sel_reg0 = `REGF_WD_MUL;
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd2: begin
                    // modsub
                    sela_sub = `SUB_A_CONST_Q;  // Q
                    selb_sub = `SUB_B_REG0;     // X/Z
                    // write back
                    wen_reg0 = regfile_r[0][0]; // if x/z is odd, then update to q-x/z
                    sel_reg0 = `REGF_WD_SUB;
                    wen_reg1 = valid_mul;    // Y/Z
                    sel_reg1 = `REGF_WD_MUL;
                    // ctr
                    incr_ctr = 1'b1;
                end
                4'd3: begin
                    // modsub
                    sela_sub = `SUB_A_CONST_Q;  // Q
                    selb_sub = `ADD_B_REG1;     // Y/Z 
                    // write back
                    wen_reg1 = regfile_r[1][0]; // if y/z is odd, then update to q-y/z
                    sel_reg1 = `REGF_WD_SUB;
                    // ctr
                    rst_ctr = 1'b1;
                end
            endcase
        end
        S_OUTPUT_X: begin
            o_out_valid_w = 1'b1;
            sel_out_data  = 1'b0; // Xg
            incr_ctr      = (ctr_r == 4'd3) ? 1'b0 : io_out_fire;
            rst_ctr       = (ctr_r == 4'd3) ? io_out_fire : 1'b0;
        end
        S_OUTPUT_Y: begin
            o_out_valid_w = 1'b1;
            sel_out_data  = 1'b1; // Yg
            incr_ctr      = (ctr_r == 4'd3) ? 1'b0 : io_out_fire;
            rst_ctr       = (ctr_r == 4'd3) ? io_out_fire : 1'b0;
            rst_pointR    = (ctr_r == 4'd3) ? io_out_fire : 1'b0;
        end
    endcase
end


// ---------- io ------------
assign o_in_ready = o_in_ready_w;
assign o_out_valid = o_out_valid_w;
assign o_out_data = out_data[base_addr -: 64];


endmodule