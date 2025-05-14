`timescale 1ns/1ps
`include "modmul_singlecycle.v"

module ModP();

reg [254:0] A;
reg [254:0] B;
reg [510:0] golden;
reg [254:0] golden_modP;

reg [128:0] A1, A2;
reg [128:0] B1, B2;

reg [257:0] H, L;
reg [259:0] M;

reg [390:0] C1;
reg [265:0] CH;
reg [391:0] T;
reg [136:0] TH;
reg [254:0] T1;
reg [255:0] T2;
wire [254:0] result;
reg [254:0] p;


reg i_valid;
wire o_valid;
reg [129:0] A1_add_A2, B1_add_B2;
reg [260:0] M_sub_H;
reg [260:0] M_sub_H_sub_L;
wire [259:0] H0, L0, M0; // Outputs



// Multiplier uut (
//         .A2(A2),
//         .B2(B2),
//         .A1(A1),
//         .B1(B1),
//         .H0(H0),
//         .L0(L0),
//         .M0(M0)
//     );

// mod_q  modq(H0,L0,M0,result);
ModMul ModMul1(.i_x(A),.i_y(B),.i_valid(i_valid), .o_mul(result),.o_valid(o_valid));
initial begin
    i_valid=1;
    $monitor("i_valid: %d\no_valid: %d\nresult:%d\n",i_valid, o_valid,result);
    A = 255'h2e2c9fbf00b87ab7cde15119d1c5b09aa9743b5c6fb96ec59dbf2f30209b133c;
	B = 255'h116943db82ba4a31f240994b14a091fb55cc6edd19658a06d5f4c5805730c232;
    p = 'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101101;
    A1 = A[128:0];
    A2 = {3'b0, A[254:129]};
    B1 = B[128:0];
    B2 = {3'b0, B[254:129]};


    H = (A2 * B2);
    L = (A1 * B1);
    A1_add_A2 = A1 + A2;
    B1_add_B2 = B1 + B2;
    M = A1_add_A2 * B1_add_B2;

    CH = (152*H) + L;
    M_sub_H = M - H;
    M_sub_H_sub_L = M_sub_H - L;
    C1 = M_sub_H_sub_L << 129;
    T = CH + C1;

    TH = T[391:255];
    T1 = T[254:0];

    T2 = TH*19 + T1;
    // result = (T2 > p)? T2 - p : T2;

    golden = (A * B);
    golden_modP = golden % p;
#1
    if(golden_modP !== result)begin
        $display(" golden_modP : %d\n", golden_modP );

        // $display("wrong answer!!!");
        // $display("golden modP : %d\n", golden_modP);
        $display("your answer : %d\n", result );
        // $display("golden : %d\n", golden);
        // $display("p : %b\n", p);
        // $display("A1: %b\n", A1);
        // $display("A2: %b\n", A2);
        // $display("B1: %b\n", B1);
        // $display("B2: %b\n", B2);
        // $display("H: %b\n", H);
        // $display("L: %b\n", L);
        // $display("M: %b\n", M);
         
    end
    else begin
        $display("GOOOOOOD!!!!");
    end

    # 10;
    $finish;
end



endmodule