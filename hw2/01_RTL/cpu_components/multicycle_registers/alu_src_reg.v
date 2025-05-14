module alu_src_reg(
    input i_clk,
    input i_rst_n,
    input i_wen,
    input [31:0] i_rs1,
    input [31:0] i_rs2,
    input [31:0] i_fs1,
    input [31:0] i_fs2,
    input [31:0] i_imm,
    output [31:0] o_rs1,
    output [31:0] o_rs2,
    output [31:0] o_fs1,
    output [31:0] o_fs2,
    output [31:0] o_imm
);

reg [31:0] src_r [0:4];

integer i;
always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        for(i=0; i<5; i=i+1) src_r[i] <= 32'd0;
    end
    else begin
        src_r[0] <= (i_wen) ? i_rs1 : src_r[0];
        src_r[1] <= (i_wen) ? i_rs2 : src_r[1];
        src_r[2] <= (i_wen) ? i_fs1 : src_r[2];
        src_r[3] <= (i_wen) ? i_fs2 : src_r[3];
        src_r[4] <= (i_wen) ? i_imm : src_r[4];
    end
end

assign o_rs1 = src_r[0];
assign o_rs2 = src_r[1];
assign o_fs1 = src_r[2];
assign o_fs2 = src_r[3];
assign o_imm = src_r[4];


endmodule