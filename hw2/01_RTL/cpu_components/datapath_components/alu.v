// define macro for floating-point adder
`define SIGN(X) X[31]
`define EXP(X) X[30:23]
`define MTS(X) X[22:0]

module alu(
    input [6:0] i_op_code,
    input [3:0] i_op_alu,
    input signed [31:0] i_src_a,
    input signed [31:0] i_src_b,
    output signed [31:0] o_alu_out,
    output [3:0] o_alu_flag
);

// -------- wires and regs ---------
// alu computation
reg signed [31:0] alu_out;
wire signed [31:0] add_w;
wire signed [31:0] sub_w;
wire signed [31:0] sll_w;
wire signed [31:0] srl_w;
wire signed [31:0] int_eq_w;
wire signed [31:0] int_lt_w;
wire signed [31:0] fp_add_sub_w;
wire signed [31:0] fclass_w;
wire signed [31:0] fp_lt_w;
// op for fp_adder_suber
wire fp_adder_op;


// invalid operation detection
wire infinit_flag;
wire nan_flag;
wire addr_oob_flag;
wire overflow_flag;

wire a_e_all_1;
wire b_e_all_1;
wire o_e_all_1;
wire a_m_all_0;
wire b_m_all_0;
wire o_m_all_0;
wire mem_oob;
wire inst_oob;
wire diff_sign_ab;

assign a_e_all_1 = &(`EXP(i_src_a));
assign b_e_all_1 = &(`EXP(i_src_b));
assign o_e_all_1 = &(`EXP(alu_out));
assign a_m_all_0 = !(|`MTS(i_src_a));
assign b_m_all_0 = !(|`MTS(i_src_b));
assign o_m_all_0 = !(|`MTS(alu_out));
// -------- detection of fp infinit --------
assign infinit_flag = ((i_op_alu == `FADD) || 
                       (i_op_alu == `FSUB) || 
                       (i_op_alu == `FP_LT)) &&
                      ((a_e_all_1 && a_m_all_0) ||
                       (b_e_all_1 && b_m_all_0) ||
                       (o_e_all_1 && o_m_all_0));
// -------- detection of fp nan ----------
assign nan_flag = ((i_op_alu == `FADD) || 
                   (i_op_alu == `FSUB) || 
                   (i_op_alu == `FP_LT)) && 
                  ((a_e_all_1 && (!a_m_all_0)) ||
                   (b_e_all_1 && (!b_m_all_0)) ||
                   (o_e_all_1 && (!o_m_all_0)));
// -------- detection of addr out of bound --------
assign mem_oob = ((i_op_code == `LOAD)  || 
                  (i_op_code == `FLOAD) ||    
                  (i_op_code == `STORE) ||
                  (i_op_code == `FSTORE)) && 
                 ((alu_out[31:12] != 20'd1));

assign inst_oob = (i_op_code == `BRANCH) && (alu_out[31:12] != 20'd0);
assign addr_oob_flag = mem_oob || inst_oob;
// -------- detection of int overflow --------
assign diff_sign_ab = `SIGN(i_src_a) ^ `SIGN(i_src_b);
assign overflow_flag = ((((i_op_code == `OP_INT) && (i_op_alu == `ADD)) ||
                         (i_op_code == `OP_INT_IMM)                     ||
                         (i_op_code == `LOAD)                           ||
                         (i_op_code == `FLOAD)                          ||
                         (i_op_code == `STORE)                          ||
                         (i_op_code == `FSTORE)                         ||
                         (i_op_code == `BRANCH)
                        ) && (
                         (!diff_sign_ab) && (`SIGN(alu_out) ^ `SIGN(i_src_a))
                        )) || (
                         (i_op_code == `OP_INT) && (i_op_alu == `SUB) && 
                          diff_sign_ab && (`SIGN(alu_out) ^ `SIGN(i_src_a)));

// output invalid operation flag
assign o_alu_flag = {infinit_flag, nan_flag, addr_oob_flag, overflow_flag};

// -------- add --------
assign add_w = i_src_a + i_src_b;
// -------- sub --------
assign sub_w = i_src_a - i_src_b;
// -------- sll --------
assign sll_w = i_src_a << i_src_b;
// -------- srl --------
assign srl_w = i_src_a >> i_src_b;
// -------- int_eq --------
assign int_eq_w = i_src_a == i_src_b;
// -------- int_lt --------
assign int_lt_w = i_src_a < i_src_b;
// -------- fadd/fsub --------
assign fp_adder_op = (i_op_alu == `FSUB) ? 1'b1 : 1'b0;
fp_adder fp_adder_suber(.i_src_a(i_src_a), .i_src_b(i_src_b), .i_op(fp_adder_op), .o_out(fp_add_sub_w));
// -------- fclass --------
fclass fclass_0(.i_src_a(i_src_a), .o_out(fclass_w));
// -------- fp_lt --------
fp_lt fp_lt_0(.i_src_a(i_src_a), .i_src_b(i_src_b), .o_out(fp_lt_w));


// Mux for selecting result according to op_alu
always @(*)
begin
    alu_out = 32'h0000_0000;
    case(i_op_alu)
        `ADD:    alu_out = add_w;
        `SUB:    alu_out = sub_w;
        `SLL:    alu_out = sll_w;
        `SRL:    alu_out = srl_w;
        `INT_EQ: alu_out = int_eq_w;
        `INT_LT: alu_out = int_lt_w;
        `FADD:   alu_out = fp_add_sub_w;
        `FSUB:   alu_out = fp_add_sub_w;
        `FCLASS: alu_out = fclass_w;
        `FP_LT:  alu_out = fp_lt_w;
    endcase
end

assign o_alu_out = alu_out;

endmodule




module fp_adder(
    input [31:0] i_src_a,
    input [31:0] i_src_b,
    input i_op,              // 0 for add, 1 for sub
    output [31:0] o_out
);
// --------------------------------- Assumption ------------------------------------------
// 1. The possible input would be +-0, +- normal, +- subnormal (6 possibility)
// 2. Any output of zero should be expressed as positive zero.
// 3. Any number whose absolute value is larger than 2^128 is regared as Pos/Neg infinite.
// 4. Any pair of input with Pos/Neg infinite and Nan are excluded.
// ---------------------------------------------------------------------------------------

// ----- wire and reg -----
// input 
wire sign_a;
wire [7:0] exp_a;
wire [22:0] mts_a;

wire sign_b; 
wire [7:0] exp_b;
wire [22:0] mts_b;

// output
wire sign_o;
wire [7:0] exp_o;
wire [22:0] mts_o;

// signals for calculation
wire diff;              // perform sum or diff between mts_a and mts_b
wire pivot;             // 0 for a being pivot, 1 for b being pivot.
                        // Pivot number has larger exp.
wire [7:0] delta_e;     // the delta of exp_a and exp_b. (unsigned)
wire [7:0] exp_pivot;   // the exponent value of pivot number
wire [7:0] exp_a_cal; 
wire [7:0] exp_b_cal;

// intermidiate representation for calculating mantissa
wire [277:0] mts_a_concat; // the mts_a with signed bit and the digit at 2^0
wire [277:0] mts_b_concat; // the mts_b with signed bit and the digit at 2^0

wire [277:0] mts_a_int; // the representation of mts_a at integer domain 
wire [277:0] mts_b_int; // the representation of mts_b at integer domain
wire [277:0] mts_o_int; // the representation of mts_o at integer domain
wire [277:0] mts_o_int_comp; // the 2's comp of mts_o_int

// signals for normalization
wire [277:0] seq2count;
wire [8:0] clz_o; // clz of mts_o_int
wire [8:0] room_bits2sll; // available bits for normalization
wire [8:0] need_bits2sll; // the bits required for normalization
reg [277:0] mts_o_norm; // the representation of mts_o_int after normalized
reg [7:0]   exp_o_norm; // the exponent value of o after normalized
reg sign_o_norm;      // the sign bit of o 

// flags for rounding
wire g; // guard bit of mts_o_norm
wire r; // round bit of mts_o_norm
wire s; // sticky bit of mts_o_norm
wire [24:0] mts_o_round;

// --------------------- STEP 0 -------------------------
// prepare ingrediants for fp calculation decision
// ------------------------------------------------------
assign sign_a = `SIGN(i_src_a);
assign sign_b = `SIGN(i_src_b) ^ i_op; // flip the sign bit of i_src_b if i_op == 1

assign exp_a = `EXP(i_src_a);
assign exp_b = `EXP(i_src_b);

assign exp_a_cal = (exp_a == 8'd0) ? 8'd1 : exp_a;
assign exp_b_cal = (exp_b == 8'd0) ? 8'd1 : exp_b;

assign mts_a = `MTS(i_src_a);
assign mts_b = `MTS(i_src_b);

assign diff = sign_a ^ sign_b;
assign pivot = (exp_a < exp_b);
assign delta_e = (pivot) ? (exp_b_cal - exp_a_cal) : (exp_a_cal - exp_b_cal);

assign exp_pivot = (pivot) ? exp_b_cal : exp_a_cal;

// --------------------- STEP 1 -------------------------
// convert the fp_a and fp_b into 2's comp integer domain
// ------------------------------------------------------

// concat 2'b0Y to the MSB side of mts_a, mts_b and concat 253'd0 to the LSB side.
assign mts_a_concat = {1'b0, {(exp_a == 8'h00) ? 1'b0 : 1'b1}, mts_a, 253'd0};
assign mts_b_concat = {1'b0, {(exp_b == 8'h00) ? 1'b0 : 1'b1}, mts_b, 253'd0};

// shift the non-pivot operand arithmetically delta_e bits.
assign mts_a_int = (pivot) ? (mts_a_concat >>> delta_e) : (mts_a_concat);
assign mts_b_int = (pivot) ? (mts_b_concat) : (mts_b_concat >>> delta_e);

// --------------------- STEP 2 -------------------------
// perform add/sub to mts_a_int and mts_b_int
// ------------------------------------------------------
assign mts_o_int = (diff) ? (mts_a_int - mts_b_int) : (mts_a_int + mts_b_int);
assign mts_o_int_comp = ~mts_o_int + 278'd1;

// --------------------- STEP 3 -------------------------
// normalize mts_o_int and obtain mts_o_norm
// ------------------------------------------------------

// count leading zero of mts_o_int
assign seq2count = (mts_o_int[277] && diff) ? mts_o_int_comp : mts_o_int;
clz_278 clz0(.i_seq(seq2count), .o_lz(clz_o));

assign room_bits2sll = (exp_pivot == 8'd0) ? 8'd0 : (exp_pivot - 1);
assign need_bits2sll = (clz_o == 9'd0) ? 9'd0 : (clz_o - 1);

// normalize mts_o_int
always @(*)
begin
    sign_o_norm = 1'b0;
    exp_o_norm  = 8'd0;
    mts_o_norm  = 278'd0;

    if(diff) begin
        // Case 1: subtracting the coefficients (mts_a_int & mts_b_int)
        if(mts_o_int[277]) begin
            // The result is negative
            sign_o_norm = sign_b;
            if(clz_o == 1) begin
                // The result is 01.xxx >> already normalized
                exp_o_norm  = exp_pivot;
                mts_o_norm  = mts_o_int_comp;
            end
            else begin
                // The result is 00.000xxx >> shift left logical n bits
                if(exp_pivot > need_bits2sll) begin
                    // The exponent is enough for normalization
                    exp_o_norm  = exp_pivot - need_bits2sll;
                    mts_o_norm  = mts_o_int_comp << need_bits2sll;
                end
                else begin
                    // The exponent is not enough for normalization
                    exp_o_norm  = 8'd0;
                    mts_o_norm  = mts_o_int_comp << room_bits2sll;
                end
            end
        end
        else begin
            // The result is positive
            sign_o_norm = sign_a;
            if(clz_o == 1) begin
                // The result is 01.xxx >> already normalized
                exp_o_norm  = exp_pivot;
                mts_o_norm  = mts_o_int;
            end
            else begin
                // The result is 00.000xxx >> shift left logical n bits
                if(exp_pivot > need_bits2sll) begin
                    // The exponent is enough for normalization
                    exp_o_norm  = exp_pivot - need_bits2sll;
                    mts_o_norm  = mts_o_int << need_bits2sll;
                end
                else begin
                    // The exponent is not enough for normalization
                    exp_o_norm  = 8'd0;
                    mts_o_norm  = mts_o_int << room_bits2sll;
                end
            end
        end
    end
    else begin
        // Case 2: adding up the coefficients (mts_a_int & mts_b_int)
        if((exp_pivot == 8'd254)&&(mts_o_int[277])) begin
            // The result is out of fp32 expression range.
            sign_o_norm = sign_a;
            exp_o_norm  = 8'd255;
            mts_o_norm  = 23'd0;
        end
        else begin
            if(clz_o == 0) begin
                // The result is 1x.xxx >> shift right logical 1 bits
                sign_o_norm = sign_a;
                exp_o_norm  = exp_pivot + 8'd1;
                mts_o_norm  = mts_o_int >> 1;
            end
            else if(clz_o == 1) begin
                // The result is 01.xxx >> already normalized
                sign_o_norm = sign_a;
                exp_o_norm  = exp_pivot;
                mts_o_norm  = mts_o_int;
            end
            else begin
                // The result is 00.000xxx >> shift left logical n bits
                if(exp_pivot > need_bits2sll) begin
                    // The exponent is enough for normalization
                    sign_o_norm = sign_a;
                    exp_o_norm  = exp_pivot - need_bits2sll;
                    mts_o_norm  = mts_o_int << need_bits2sll;
                end
                else begin
                    // The exponent is not enough for normalization
                    sign_o_norm = sign_a;
                    exp_o_norm  = 8'd0;
                    mts_o_norm  = mts_o_int << room_bits2sll;
                end
            end
        end
    end
end


// --------------------- STEP 4 -------------------------
// round mts_o_normal to the nearest even
// ------------------------------------------------------
assign g = mts_o_norm[253];
assign r = mts_o_norm[252];
assign s = |mts_o_norm[251:0];

assign mts_o_round = ((g&&r)||(r&&s)) ? (mts_o_norm[277:253] + 25'd1) : mts_o_norm[277:253];

// --------------------- STEP 5 -------------------------------------------
// check if the mantissa is in normalized form, and assign result to output
// ------------------------------------------------------------------------
assign mts_o = (mts_o_round[24]) ? mts_o_round[23-:23] : mts_o_round[22-:23];
assign exp_o = (mts_o_round[24]) ? (exp_o_norm + 8'd1) : exp_o_norm;
assign sign_o = (mts_o == 23'd0 && exp_o == 8'd0) ? 1'b0 : sign_o_norm;

assign o_out = {sign_o, exp_o, mts_o};

endmodule

module clz_278 (
    input [277:0] i_seq,
    output signed [8:0] o_lz
);
    
    reg [15:0] lz_w;
    reg [15:0] data [17:0];      // 18 chunks, as the last one is only 6 bits
                                 // chunk 0 mapping to MSB 16 bits and goes on,
                                 // the chunk 0 mapping to LSB 6 bits concat with 10'hfff.
    wire [15:0] data_enc [17:0]; // seq after encoding

    integer i;
    always @(*) begin
        // divide data into 16-bit chunks and encode leading zeros
        for (i=0; i<18; i=i+1) begin
            if (i == 17) begin
                data[i] = {i_seq[5:0], 10'b11_1111_1111};  // Last chunk has only 6 bits
            end 
            else begin
                data[i] = i_seq[(277-i*16)-:16];
            end
        end
    end
    
    // encode each chunk with 16 bits clz modules
    genvar g_k;
    generate
    for (g_k=0; g_k<18; g_k=g_k+1) begin : array
        clz_16 clz_chunk(.data(data[g_k]), .leading_zero(data_enc[g_k]));
    end
    endgenerate

    always @(*) begin
        if (data_enc[0] != 16'b10000) begin
            lz_w = data_enc[0];
        end else if (data_enc[1] != 16'b10000) begin
            lz_w = 16'd16 + data_enc[1];
        end else if (data_enc[2] != 16'b10000) begin
            lz_w = 16'd32 + data_enc[2];
        end else if (data_enc[3] != 16'b10000) begin
            lz_w = 16'd48 + data_enc[3];
        end else if (data_enc[4] != 16'b10000) begin
            lz_w = 16'd64 + data_enc[4];
        end else if (data_enc[5] != 16'b10000) begin
            lz_w = 16'd80 + data_enc[5];
        end else if (data_enc[6] != 16'b10000) begin
            lz_w = 16'd96 + data_enc[6];
        end else if (data_enc[7] != 16'b10000) begin
            lz_w = 16'd112 + data_enc[7];
        end else if (data_enc[8] != 16'b10000) begin
            lz_w = 16'd128 + data_enc[8];
        end else if (data_enc[9] != 16'b10000) begin
            lz_w = 16'd144 + data_enc[9];
        end else if (data_enc[10] != 16'b10000) begin
            lz_w = 16'd160 + data_enc[10];
        end else if (data_enc[11] != 16'b10000) begin
            lz_w = 16'd176 + data_enc[11];
        end else if (data_enc[12] != 16'b10000) begin
            lz_w = 16'd192 + data_enc[12];
        end else if (data_enc[13] != 16'b10000) begin
            lz_w = 16'd208 + data_enc[13];
        end else if (data_enc[14] != 16'b10000) begin
            lz_w = 16'd224 + data_enc[14];
        end else if (data_enc[15] != 16'b10000) begin
            lz_w = 16'd240 + data_enc[15];
        end else if (data_enc[16] != 16'b10000) begin
            lz_w = 16'd256 + data_enc[16];
        end else if (data_enc[17] != 16'b10000) begin
            lz_w = 16'd262 + data_enc[17];
        end else begin
            lz_w = 16'd278;  // All bits are zero
        end
    end

    assign o_lz = lz_w[8:0];

endmodule

module clz_16 (
    input [15:0] data,
    output [15:0] leading_zero
);
    
    reg [15:0] data_enc;
    reg [15:0] leading_zero_w;

    always @(*) begin
        data_enc = {bits_enc(data[15:12]),bits_enc(data[11:8]),bits_enc(data[7:4]),bits_enc(data[3:0])};

        leading_zero_w = (data_enc[15:12] == 4'b0100) ? (
            (data_enc[11:8] == 4'b0100) ? (
                (data_enc[7:4] == 4'b0100) ? (
                    (data_enc[3:0] == 4'b0100) ? (
                        16'd16
                    ) : (16'd12 + data_enc[3:0])
                ) : (16'd8 + data_enc[7:4])
            ) : (16'd4 + data_enc[11:8])
        ) : (data_enc[15:12]);
        
    end

    assign leading_zero = leading_zero_w;


    function [3:0] bits_enc;
        input [3:0] bits;        
        begin
            bits_enc = (bits[3:0] == 4'b0000) ? 4'b0100 : (   // bit pattern 0000 has 4 leading zero
                (bits[3:0] == 4'b0001) ? 4'b0011 : (      // bit pattern 0001 has 3 leading zero
                    (bits[3:1] == 3'b001) ? 4'b0010 : ( // bit pattern 001x has 2 leading zeros
                        (bits[3:2] == 2'b01) ? 4'b0001 : ( // bit pattern 01xx has 1 leading zeros
                            4'b0000
                        )
                    )
                )
            );
        end
    endfunction

endmodule

module fp_lt(
    input [31:0] i_src_a,
    input [31:0] i_src_b,
    output [31:0] o_out
);

wire sign_a;
wire sign_b;
wire [7:0] exp_a;
wire [7:0] exp_b;
wire [22:0] mts_a;
wire [22:0] mts_b;
reg lt_w;

wire a_zero;
wire b_zero;

assign sign_a = `SIGN(i_src_a);
assign sign_b = `SIGN(i_src_b);
assign exp_a  = `EXP(i_src_a);
assign exp_b  = `EXP(i_src_b);
assign mts_a  = `MTS(i_src_a);
assign mts_b  = `MTS(i_src_b);

assign a_zero = (exp_a == 8'd0) && (mts_a == 23'd0);
assign b_zero = (exp_b == 8'd0) && (mts_b == 23'd0);

always @(*)
begin
    lt_w = 1'b0;

    if(exp_a < exp_b) begin
        lt_w = 1'b1;
    end
    else if(exp_a == exp_b) begin
        if(mts_a < mts_b) begin
            lt_w = 1'b1;
        end
        else begin
            lt_w = 1'b0;
        end 
    end
    else begin
        lt_w = 1'b0;
    end
end

assign o_out = (a_zero && b_zero) ? 32'd0 : ((i_src_a == i_src_b) ? 32'd0 : (sign_a && (!lt_w)) || ((!sign_b) && lt_w));


endmodule


module fclass (
    input [31:0] i_src_a,
    output [31:0] o_out
);

wire sign;
wire e_all_1;
wire e_all_0;
wire e_between_1_254;
wire m_all_zero;
reg [3:0] category;

assign sign = i_src_a[31];
assign e_all_1 = (&i_src_a[30:23]);
assign e_all_0 = !(|i_src_a[30:23]); 
assign e_between_1_254 = ((i_src_a[30:23] > 8'd0) && (i_src_a[30:23] < 8'd255));
assign m_all_zero = !(|i_src_a[22:0]);

always @(*)
begin
    // default assignment
    category = `FLOAT_NAN;

    case({sign, e_all_1, e_all_0, e_between_1_254, m_all_zero})
        5'b11001: category = `FLOAT_NEG_INF;
        5'b10010: category = `FLOAT_NEG_NORM;
        5'b10011: category = `FLOAT_NEG_NORM;
        5'b10100: category = `FLOAT_NEG_SUBNORM;
        5'b10101: category = `FLOAT_NEG_ZERO;
        5'b00101: category = `FLOAT_POS_ZERO;
        5'b00100: category = `FLOAT_POS_SUBNORM;
        5'b00011: category = `FLOAT_POS_NORM;
        5'b00010: category = `FLOAT_POS_NORM;
        5'b01001: category = `FLOAT_POS_INF;
        5'b11000: category = `FLOAT_NAN;
        5'b01000: category = `FLOAT_NAN;
    endcase
end

assign o_out = category;

endmodule