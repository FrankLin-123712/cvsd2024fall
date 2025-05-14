/* #############################
 * # arithmetic building block #
 * # ------------------------- #
 * # Implements all modular    #
 * # operations here.          #
 * #############################
 *
 *
 */
`define CONST_Q 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED
// module ModAdder(
//     input [254:0] i_x,
//     input [254:0] i_y,
//     input i_op,   //0 for +    1 for -
//     input i_valid,
//     output [254:0] o_add,
//     output o_valid
// );

// wire [255:0] sum;  // 加法可能溢出到 256 位
// wire [255:0] q_b;

// assign sum     = (i_op) ? (i_x - i_y) : (i_x + i_y);
// assign q_b     = (i_op) ? (`CONST_Q - i_y) : 0;
// assign o_add   = (i_op) ? ((i_x < i_y) ? (i_x + q_b) : sum) : ((sum >= `CONST_Q) ? sum - `CONST_Q : sum);
// assign o_valid = i_valid;

// endmodule

module ModAdd(
    input [254:0] i_x,
    input [254:0] i_y, 
    output [254:0] o_add
);

wire [255:0] sum_w;

assign sum_w = i_x + i_y;
assign o_add = (sum_w >= `CONST_Q) ? sum_w - `CONST_Q : sum_w;

endmodule


module ModSub(
    input [254:0] i_x,
    input [254:0] i_y,
    output [254:0] o_sub
);

wire [255:0] sub_w;
wire [255:0] q_y;

assign sub_w = i_x - i_y;
assign q_y   = `CONST_Q - i_y;
assign o_sub = (i_x < i_y) ? (i_x + q_y) : sub_w;

endmodule

// module ModularInversion (
//     input [254:0] i_b,        // 輸入值 b
//     input i_valid,       
//     input clk,                
//     input rst,
//     output reg [254:0] result,   // 結果 result = a/b mod q
//     output reg o_valid        
// );
//     parameter Q = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949; // q = 2^255 - 19
//     parameter Q_MINUS_2 = 255'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101011; // q-2
//     // parameter Q_MINUS_2 =255'b101;
//     reg [254:0] r;             // 中間結果寄存器
//     reg [254:0] base;          // 基數寄存器
//     reg [254:0] exp;           // 指數寄存器
//     reg [8:0] bit_counter;     // 位元計數器

//     wire [254:0] mul_result;   // ModMul 輸出結果
//     wire mul_valid1,mul_valid2;            // ModMul 輸出有效信號
//     reg mul_start1,mul_start2;             // 啟動模數乘法
//     wire [254:0] r_temp1,r_temp2,o_r_temp;             // 中間結果寄存器

//     // 實例化模數乘法模塊

//     ModMul modmul_inst (
//         .i_x(r),               // 輸入值 r
//         .i_y(r),                // 輸入值 r
//         .i_valid(mul_start1),   // 啟用信號
//         .o_mul(r_temp1),    // 輸出模數乘法結果
//         .o_valid(mul_valid1)    // 輸出有效信號
//     );
//     ModMul modmul_inst2 (
//         .i_x(r_temp1),               // 輸入值 r
//         .i_y(base),            // 輸入值 base
//         .i_valid(mul_start2),   // 啟用信號
//         .o_mul(r_temp2),    // 輸出模數乘法結果
//         .o_valid(mul_valid2)    // 輸出有效信號
//     );
    
//     // ModMul modmul_inst3 (
//     //     .i_x(i_a),               // 輸入值 r
//     //     .i_y(r_temp2),            // 輸入值 base
//     //     .i_valid(mul_start3),   // 啟用信號
//     //     .o_mul(o_r_temp),    // 輸出模數乘法結果
//     //     .o_valid(mul_valid3)    // 輸出有效信號
//     // );
//     // 狀態機
//     parameter IDLE=2'b00;
//     parameter EXPONENTIATION=2'b01;
//     parameter DONE=2'b10;

//     // typedef enum reg [1:0] {
//     //     IDLE,           // 初始化
//     //     EXPONENTIATION, // 指數運算
//     //     DONE            // 完成
//     // } state_t;
//     // state_t state;
//     reg [1:0 ]state; 
//     always @(posedge clk) begin
//         if (rst) begin
//             state <= IDLE;
//             r <= 255'd1;          // 初始值 r = 1
//             base <= i_b;          // 初始基數 b
//             exp <= Q_MINUS_2;     // 指數 q-2
//             bit_counter <= 9'd255;
//             o_valid <= 1'b0;
//             mul_start1 <= 1'b1;
//             mul_start2 <= 1'b1;
//             end else begin
//             case (state)
//                 IDLE: begin
//                     o_valid <= 1'b0; 

//                     if (i_valid) begin
//                         state <= EXPONENTIATION;
//                         r <= 255'd1;          // 初始化 r
//                         base <= i_b;          // 初始化基數
//                         exp <= Q_MINUS_2;     // 初始化指數
//                         bit_counter <= 9'd254;
//                         mul_start1 <= 1'b1;
//                         mul_start2 <= 1'b1;

//                     end
//                     else
//                     state <= IDLE;

//                 end
//                 EXPONENTIATION: begin
//                         if (exp[bit_counter]) begin
//                             r <= r_temp2;  // 當前位為 1，執行 r = (r * base) mod q
//                         end
//                         else 
//                             r <= r_temp1;  // 當前位為 0，執行 r = (r * r) mod q
                            
//                         bit_counter <= bit_counter - 1;
//                         if (bit_counter == 0) begin
//                             state <= DONE;
//                             result <= r_temp2;       // 將最終結果輸出
//                             o_valid <= 1'b1;
//                         end

//                 end
//                 DONE: begin
//                     state <= IDLE;  // 回到空閒狀態
//                     bit_counter <=0;
//                     o_valid <= 1'b0;
//                     mul_start1 <= 1'b0;
//                     mul_start2 <= 1'b0;
//                 end
//             endcase
//         end
//     end
// endmodule

// module ModDiv (
//     input [254:0] i_a,        // 輸入值 a
//     input [254:0] i_b,        // 輸入值 b
//     input i_valid,
//     input clk,                
//     input rst,                
//     output reg [254:0] result,   // 結果 result = a/b mod q
//     output reg o_valid        
// );
//     parameter Q = 255'd57896044618658097711785492504343953926634992332820282019728792003956564819949; // q = 2^255 - 19
//     parameter Q_MINUS_2 = 255'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101011; // q-2
//     // parameter Q_MINUS_2 =255'b101;
//     reg [254:0] r;             // 中間結果寄存器
//     reg [254:0] base;          // 基數寄存器
//     reg [254:0] exp;           // 指數寄存器
//     reg [8:0] bit_counter;     // 位元計數器

//     wire [254:0] mul_result;   // ModMul 輸出結果
//     wire mul_valid1,mul_valid2,mul_valid3;            // ModMul 輸出有效信號
//     reg mul_start1,mul_start2,mul_start3;             // 啟動模數乘法
//     wire [254:0] r_temp1,r_temp2,o_r_temp;             // 中間結果寄存器

//     // 實例化模數乘法模塊

//     ModMul modmul_inst (
//         .i_x(r),               // 輸入值 r
//         .i_y(r),                // 輸入值 r
//         .i_valid(mul_start1),   // 啟用信號
//         .o_mul(r_temp1),    // 輸出模數乘法結果
//         .o_valid(mul_valid1)    // 輸出有效信號
//     );
//     ModMul modmul_inst2 (
//         .i_x(r_temp1),               // 輸入值 r
//         .i_y(base),            // 輸入值 base
//         .i_valid(mul_start2),   // 啟用信號
//         .o_mul(r_temp2),    // 輸出模數乘法結果
//         .o_valid(mul_valid2)    // 輸出有效信號
//     );
    
//     ModMul modmul_inst3 (
//         .i_x(i_a),               // 輸入值 r
//         .i_y(r_temp2),            // 輸入值 base
//         .i_valid(mul_start3),   // 啟用信號
//         .o_mul(o_r_temp),    // 輸出模數乘法結果
//         .o_valid(mul_valid3)    // 輸出有效信號
//     );
//     // 狀態機
//     parameter IDLE=2'b00;
//     parameter EXPONENTIATION=2'b01;
//     parameter DONE=2'b10;

//     // typedef enum reg [1:0] {
//     //     IDLE,           // 初始化
//     //     EXPONENTIATION, // 指數運算
//     //     DONE            // 完成
//     // } state_t;
//     // state_t state;
//     reg [1:0 ]state; 
//     always @(posedge clk or posedge rst) begin
//         if (rst) begin
//             state <= IDLE;
//             r <= 255'd1;          // 初始值 r = 1
//             base <= i_b;          // 初始基數 b
//             exp <= Q_MINUS_2;     // 指數 q-2
//             bit_counter <= 9'd255;
//             o_valid <= 1'b0;
//             mul_start1 <= 1'b1;
//             mul_start2 <= 1'b1;
//             mul_start3 <= 1'b0;        
//             end else begin
//             case (state)
//                 IDLE: begin
//                     o_valid <= 1'b0;

//                     if (i_valid) begin
//                         state <= EXPONENTIATION;
//                         r <= 255'd1;          // 初始化 r
//                         base <= i_b;          // 初始化基數
//                         exp <= Q_MINUS_2;     // 初始化指數
//                         bit_counter <= 9'd254;
//                         mul_start1 <= 1'b1;
//                         mul_start2 <= 1'b1;
//                         mul_start3 <= 1'b0;

//                     end
//                     else
//                     state <= IDLE;

//                 end
//                 EXPONENTIATION: begin
//                         if (exp[bit_counter]) begin
//                             r <= r_temp2;  // 當前位為 1，執行 r = (r * base) mod q
//                         end
//                         else 
//                             r <= r_temp1;  // 當前位為 0，執行 r = (r * r) mod q



//                         bit_counter <= bit_counter - 1;
//                         if (bit_counter == 1) begin
//                             mul_start3 <= 1'b1;                

//                         end
//                         else if (bit_counter == 0) begin
//                             state <= DONE;
//                             result <= o_r_temp;       // 將最終結果輸出
//                             o_valid <= 1'b1;
//                         end

//                 end
//                 DONE: begin
//                     state <= IDLE;  // 回到空閒狀態
//                     bit_counter <=0;
//                     o_valid <= 1'b0;

//                         mul_start1 <= 1'b0;
//                         mul_start2 <= 1'b0;
//                         mul_start3 <= 1'b0;                
//                 end
//             endcase
//         end
//     end
// endmodule

module ModMul(
    input i_clk,
    input i_rst,
    input [254:0] i_x,
    input [254:0] i_y,
    input i_valid,
    output [254:0] o_mul,
    output o_valid
);

// ------- wires and regs ------
// modmul input : A1, A2, B1, B2
wire [128:0] A1_w, A2_w;
wire [128:0] B1_w, B2_w;

// modmul output : H0, L0, M0
wire [257:0] H0_w, L0_w; 
wire [259:0] M0_w;         

// pipeline reg for 130x130 multiplication
reg mul_valid_r;
reg [257:0] H0_r, L0_r;
reg [259:0] M0_r;

// modq output : XY mod q
wire [254:0] modQ_w;

// ------ data path ------
// ###### stage 1 : perform 130x130 multiplication ######
// computation
assign A1_w = i_x[128:0];
assign A2_w = {3'b0, i_x[254:129]};
assign B1_w = i_y[128:0];
assign B2_w = {3'b0, i_y[254:129]};

Multiplier uut(
    .A2(A2_w), .B2(B2_w), .A1(A1_w), .B1(B1_w),
    .H0(H0_w), .L0(L0_w), .M0(M0_w)
);

// pipeline reg
always@(posedge i_clk) begin
    if(i_rst) mul_valid_r <= 1'b0;
    else      mul_valid_r <= i_valid;
end
always@(posedge i_clk) begin
    if(i_rst) begin
        H0_r <= 258'd0;
        L0_r <= 258'd0;
        M0_r <= 260'd0;
    end
    else begin
        H0_r <= H0_w;
        L0_r <= L0_w;
        M0_r <= M0_w;
    end
end

// ###### stage 2 : modular q ######
// perform modular q
mod_q modq(.i_H0(H0_r), .i_L0(L0_r), .i_M0(M0_r), .o_modq(modQ_w));

// io
assign o_valid = (mul_valid_r);
assign o_mul   = (mul_valid_r) ? modQ_w : 255'b0;

endmodule

module KaratsubaMultiplier130x130 (
    input  [129:0] A, // 130-bit input A
    input  [129:0] B, // 130-bit input B
    output [259:0] P  // 260-bit product
);

// Split inputs into high and low parts
wire [64:0] A_H = A[129:65];
wire [64:0] A_L = A[64:0];
wire [64:0] B_H = B[129:65];
wire [64:0] B_L = B[64:0];

// Compute partial products
wire [65:0] sum_A = A_H + A_L;
wire [65:0] sum_B = B_H + B_L;

wire [129:0] M1;
wire [129:0] M2;
wire [131:0] M3;

assign M1 = A_H * B_H;
assign M2 = A_L * B_L;
assign M3 = sum_A * sum_B;

// Cross term
wire [132:0] M4 = M3 - M1 - M2;

// Shift results and sum them
wire [259:0] shifted_M1 = {M1, 130'b0}; // Shift M1 by 130 bits
wire [197:0] shifted_M4 = {M4, 65'b0};  // Shift M4 by 65 bits
assign P = shifted_M1 + shifted_M4 + M2;

endmodule


module Multiplier (
    input  [128:0] A2, // 129-bit input A
    input  [128:0] B2, // 129-bit input B
    input  [128:0] A1, // 129-bit input A
    input  [128:0] B1, // 129-bit input B
    output  [257:0] H0,// 258-bit product
    output  [257:0] L0,// 258-bit product
    output  [259:0] M0 // 260-bit product
);

// Compute partial products
wire [259:0] M1, M2;
wire [259:0] temp_H0, temp_L0, temp_M0;
wire [129:0] A2_130 = {1'b0,A2}; 
wire [129:0] A1_130 = {1'b0,A1};
wire [129:0] B2_130 = {1'b0,B2}; 
wire [129:0] B1_130 = {1'b0,B1};
wire [259:0] H0_260;
wire [259:0] L0_260;

assign H0 = H0_260[257:0];
assign L0 = L0_260[257:0];

KaratsubaMultiplier130x130 mult1 (.A(A2_130), .B(B2_130), .P(H0_260)); // A_H * B_H
KaratsubaMultiplier130x130 mult2 (.A(A1_130), .B(B1_130), .P(L0_260)); // A_L * B_L

// Compute (A_H + A_L) * (B_H + B_L)
wire [129:0] sum_A = A2 + A1;
wire [129:0] sum_B = B2 + B1;
KaratsubaMultiplier130x130 mult3 (.A(sum_A), .B(sum_B), .P(M0)); // (A_H + A_L) * (B_H + B_L)

endmodule


module mod_q (
    input [257:0] i_H0,       // 258-bit product
    input [257:0] i_L0,       // 258-bit product
    input [259:0] i_M0,       // 260-bit product
    output [254:0] o_modq     // 255-bit product
);

// -------- wires and regs --------
// #### stage 1 : Calculate 152*C_h and C_1 ####
// (M0 - H0 - L0)
wire [260:0] m0_minus_l0;      // 260+1 bits
wire [261:0] m0_l0_minus_h0;   // 261+1 bits

// ((H0_sft7 + H0_sft4) + (H0_sft3 + L0))
wire [265:0] h0_sft7_sft4;   // 258+7+1 bits
wire [261:0] h0_sft3_l0;     // 258+3+1 bits
wire [266:0] h0_sft743_l0;   // 266+1 bits


// #### stage 2 : First round modular  ####
// T1 = 152*C_h + C_1
wire [391:0] T1_w;

// #### stage 3 : Second round modular ####
wire [136:0] T1H_w;        // 137 bits
wire [254:0] T1L_w;        // 255 bits

wire [141:0] T1H_sft4_sft1_w; // 137+4+1 bits
wire [255:0] T1L_T1H_w;       // 255+1 bits
wire [255:0] T2_w;            // 256 bits

// #### stage 4 : Third round modular ####
wire overflow_flag;        // high when result larger than q
wire [255:0] T2_minus_q_w; // 256 bits
wire [254:0] T3_w;         // 256 bits

// -------- data path --------
// stage 1 : Calculate 152*C_h and C_1
// (1) m0_l0_minus_h0_r <= (M0-L0-H0)
assign m0_minus_l0    = i_M0 - i_L0;
assign m0_l0_minus_h0 = m0_minus_l0 - i_H0;
// (2) ((H0 << 7)+(H0 << 4)) + ((H0 << 3)+L0)
assign h0_sft7_sft4 = {i_H0, 7'b0} + {i_H0, 4'b0};
assign h0_sft3_l0   = {i_H0, 3'b0} + i_L0;
assign h0_sft743_l0 = h0_sft7_sft4 + h0_sft3_l0;

// stage 2 : First round modular 
// T1 = 152*C_h + C_1
assign T1_w = {m0_l0_minus_h0, 129'b0} + h0_sft743_l0;

// stage 3 : Second round modular
// T2 = 19*T1_H + T1_L
assign T1H_w = T1_w[391:255];
assign T1L_w = T1_w[254:0];

assign T1H_sft4_sft1_w = {T1H_w, 4'b0} + {T1H_w, 1'b0};
assign T1L_T1H_w       = T1H_w + T1L_w;
assign T2_w            = T1H_sft4_sft1_w + T1L_T1H_w;

// stage 4 : Third round modular
// directly return if not larger than q
// otherwise return T2 - q
assign overflow_flag = (T2_w >= `CONST_Q);
assign T2_minus_q_w  = (T2_w - `CONST_Q);
assign T3_w = (overflow_flag) ? T2_minus_q_w : T2_w;

// io
assign o_modq = T3_w;

endmodule