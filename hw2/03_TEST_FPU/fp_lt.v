// define macro for floating-point adder
`define SIGN(X) X[31]
`define EXP(X) X[30:23]
`define MTS(X) X[22:0]
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