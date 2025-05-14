module regfile(
    input i_clk,
    input i_rst_n,
    input [4:0] i_src1_idx,
    input [4:0] i_src2_idx,
    input [4:0] i_dest_idx,
    input signed [31:0] i_wdata,
    input i_wen,
    output signed [31:0] o_src1,
    output signed [31:0] o_src2
);
// ######################################################
//   Asynchronous Read & Synchronous Write Register File
// ######################################################
// regs
reg signed [31:0] mem [0:31];
// wires
reg signed [31:0] rdata_1;
reg signed [31:0] rdata_2;



// asynchronous read port x2
always @(*)
begin
    rdata_1 = mem[i_src1_idx];
    rdata_2 = mem[i_src2_idx];
end

assign o_src1 = rdata_1;
assign o_src2 = rdata_2;

// synchronous write port
integer i;
always @(negedge i_rst_n or posedge i_clk)
begin
    if(!i_rst_n) begin
        for(i=0; i<32; i=i+1)begin
            mem[i] <= 32'h0000_0000;
        end
    end
    else begin
        for(i=0; i<32; i=i+1) begin
            mem[i] <= (i_wen && (i == i_dest_idx)) ? i_wdata : mem[i];
        end
    end
end

endmodule