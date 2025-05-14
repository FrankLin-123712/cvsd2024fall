// ##############################################
// # Basic building block for common in engines.#
// ##############################################


module four2oneMux (o_out, i_in0, i_in1, i_in2, i_in3, i_sel);
parameter data_width = 8;

output reg [data_width-1:0] o_out;
input [data_width-1:0] i_in0, i_in1, i_in2, i_in3;
input [1:0] i_sel;

always@(*) begin
    o_out = {data_width{1'b0}};
    case(i_sel)
        2'b00: o_out = i_in0;
        2'b01: o_out = i_in1;
        2'b10: o_out = i_in2;
        2'b11: o_out = i_in3;
    endcase
end

endmodule