module inst_reg(
    input i_clk,
    input i_rst_n,
    input i_wen,
    input [31:0] i_inst,
    output [31:0] o_inst
);

reg [31:0] inst_r;

always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        inst_r <= 32'd0;
    end
    else begin
        inst_r <= (i_wen) ? i_inst : inst_r; 
    end
end

assign o_inst = inst_r;

endmodule