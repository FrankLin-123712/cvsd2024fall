module alu_out_reg(
    input i_clk,
    input i_rst_n,
    input i_wen,
    input [31:0] i_alu_out,
    input [3:0] i_alu_flag,
    output [31:0] o_alu_out,
    output [3:0] o_alu_flag
);


reg [31:0] alu_out_r;
reg [31:0] alu_flag_r;

always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        alu_out_r <= 32'd0;
    end
    else begin
        alu_out_r <= (i_wen) ? i_alu_out : alu_out_r; 
    end
end

always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        alu_flag_r <= 4'd0;
    end
    else begin
        alu_flag_r <= (i_wen) ? i_alu_flag : alu_flag_r; 
    end
end

assign o_alu_out = alu_out_r;
assign o_alu_flag = alu_flag_r;

endmodule