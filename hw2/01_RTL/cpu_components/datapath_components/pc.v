module pc(
    input i_clk,
    input i_rst_n,
    input i_wen_pc,
    input [31:0] i_pc_next,
    output [31:0] o_pc
);

// wires and regs
reg [31:0] pc;

assign o_pc = pc;

always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        pc <= 32'h0000_0000;
    end
    else begin
        pc <= (i_wen_pc) ? i_pc_next : pc;
    end
end


endmodule