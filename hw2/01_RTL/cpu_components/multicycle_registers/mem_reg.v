module mem_reg(
    input i_clk,
    input i_rst_n,
    input i_wen,
    input [31:0] i_mem_rdata,
    output [31:0] o_mem_rdata
);

reg [31:0] mem_rdata_r;

always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        mem_rdata_r <= 32'd0;
    end
    else begin
        mem_rdata_r <= (i_wen) ? i_mem_rdata : mem_rdata_r; 
    end
end

assign o_mem_rdata = mem_rdata_r;

endmodule