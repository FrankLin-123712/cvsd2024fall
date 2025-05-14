module alu #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
)(
    input                      i_clk,
    input                      i_rst_n,

    input                      i_in_valid,
    output                     o_busy,
    input         [INST_W-1:0] i_inst,
    input  signed [DATA_W-1:0] i_data_a,
    input  signed [DATA_W-1:0] i_data_b,

    output                     o_out_valid,
    output        [DATA_W-1:0] o_data
);
    // State encoding
    parameter S_RST     = 2'b00,
              S_ACCEPT  = 2'b01,
              S_PROCESS = 2'b10,
              S_DONE    = 2'b11;
    
    // Instruction encoding
    parameter INST_SADD = 4'b0000,
              INST_SSUB = 4'b0001,
              INST_SMUL = 4'b0010,
              INST_SACC = 4'b0011,
              INST_SFPS = 4'b0100,
              INST_XOR  = 4'b0101,
              INST_ARST = 4'b0110,
              INST_LROT = 4'b0111,
              INST_CLZR = 4'b1000, 
              INST_RMT4 = 4'b1001;

    /* 
     * ######################
     * ### Wires and Regs ###
     * ######################
     */

    // ---- wires -----
    // output port
    reg o_busy_w;
    reg o_out_valid_w;
    // control signal for data path
    reg en_in_w;
    reg en_acc_w;
    // wires for data path
    wire signed [DATA_W-1:0] sadd_w;
    wire signed [DATA_W-1:0] ssub_w;
    wire signed [DATA_W-1:0] smul_w;
    wire signed [DATA_W-1:0] sacc_w;
    wire signed [DATA_W-1:0] sfps_w;
    wire signed [DATA_W-1:0] xor_w;
    wire signed [DATA_W-1:0] arst_w;
    wire signed [DATA_W-1:0] lrot_w;
    wire signed [DATA_W-1:0] clzr_w;
    wire signed [DATA_W-1:0] rmt4_w;
    reg signed [DATA_W-1:0] alu_out;
    // wires for s_add
    wire signed [16:0] data_a_add_w;
    wire signed [16:0] data_b_add_w;
    // wires for s_sub
    wire signed [16:0] data_a_sub_w;
    wire signed [16:0] data_b_comp_w;
    
    // ---- registers ----
    // state reg
    reg [1:0] next_state;
    reg [1:0] state;

    // input buffer
    reg [3:0]  inst_reg;
    reg signed [DATA_W-1:0] data_a_reg;
    reg signed [DATA_W-1:0] data_b_reg;

    /* 
     * #################
     * ### Data Path ###
     * #################
     */
    // ---------- signed add ----------
    assign data_a_add_w = data_a_reg;
    assign data_b_add_w = data_b_reg;
    signed_add sadd_for_add(.data_a(data_a_add_w), .data_b(data_b_add_w), .data_o(sadd_w));
    // ---------- signed sub ----------
    assign data_a_sub_w = data_a_reg;
    assign data_b_comp_w = $signed(~data_b_reg) + 17'sb0_0001;
    signed_add sadd_for_sub(.data_a(data_a_sub_w), .data_b(data_b_comp_w), .data_o(ssub_w));
    // ---------- signed mul ----------
    signed_mul smul_1(.data_a(data_a_reg), .data_b(data_b_reg), .data_o(smul_w));
    // ---------- signed accumulate ----------
    signed_acc acc_1(.i_clk(i_clk), 
                     .i_rst_n(i_rst_n), 
                     .en_acc(en_acc_w), 
                     .index(data_a_reg), 
                     .value(data_b_reg),
                     .acc_o(sacc_w));
    // ---------- softplus----------
    softplus sfps_1(.data_a(data_a_reg), .data_o(sfps_w));
    // ---------- xor ----------
    assign xor_w  = data_a_reg ^ data_b_reg;
    // ---------- arithmetic right shift----------
    assign arst_w = data_a_reg >>> data_b_reg;
    // ---------- left rotation ----------
    function [DATA_W-1:0] left_rotation;
        input [DATA_W-1:0] data, sft_amount;
        reg [DATA_W*2-1:0] data_concat;
        begin
            data_concat = {data, data};
            left_rotation = data_concat[((DATA_W*2-1)-sft_amount) -: 16];
        end
    endfunction
    assign lrot_w = left_rotation(data_a_reg, data_b_reg);
    // ---------- count leading zero ----------
    count_leading_zero clz_1(.data(data_a_reg), .leading_zero(clzr_w));
    // ---------- reverse match 4 ----------
    reverse_match_4 rmt4_1(.data_a(data_a_reg), .data_b(data_b_reg), .data_o(rmt4_w));


    // ---------- data path selection ----------
    
    // mux for select output
    always @(*)
    begin
        // default assignment
        alu_out = 16'b0000;
        case(inst_reg)
            INST_SADD: alu_out = sadd_w;
            INST_SSUB: alu_out = ssub_w;
            INST_SMUL: alu_out = smul_w;
            INST_SACC: alu_out = sacc_w;
            INST_SFPS: alu_out = sfps_w;
            INST_XOR:  alu_out = xor_w;
            INST_ARST: alu_out = arst_w;
            INST_LROT: alu_out = lrot_w;
            INST_CLZR: alu_out = clzr_w;
            INST_RMT4: alu_out = rmt4_w;
        endcase
    end

    assign o_data = alu_out;
    

    


    // ---------- update pipeline reg ----------
    always @(negedge i_rst_n or posedge i_clk)
    begin
        if(!i_rst_n) begin
            inst_reg   <= 4'b0;
            data_a_reg <= 16'b0;
            data_b_reg <= 16'b0;
        end
        else begin
            inst_reg   <= (en_in_w) ? i_inst : inst_reg;
            data_a_reg <= (en_in_w) ? i_data_a : data_a_reg;
            data_b_reg <= (en_in_w) ? i_data_b : data_b_reg;
        end
    end

    

    /* 
     * ##################
     * ### Controller ###
     * ##################
     */

    // ---------- CS ----------
    always @(negedge i_rst_n or posedge i_clk)
    begin
        if(!i_rst_n) state <= S_RST;
        else         state <= next_state; 
    end

    // ---------- NL ----------
    always @(*)
    begin
        case(state)
            S_RST:     next_state = (!i_rst_n) ? (S_RST) : S_ACCEPT;
            S_ACCEPT:  next_state = (i_in_valid) ? S_PROCESS : S_ACCEPT;
            S_PROCESS: next_state = S_DONE;
            S_DONE:    next_state = S_ACCEPT;
        endcase
    end

    // ---------- OL ----------
    always @(*)
    begin
        case(state)
            S_RST: begin
                o_busy_w    = 1'b1;
                o_out_valid_w = 1'b0;
                en_in_w     = 1'b0;
                en_acc_w    = 1'b0;
            end
            S_ACCEPT: begin
                o_busy_w    = 1'b0;
                o_out_valid_w = 1'b0; 
                en_in_w     = 1'b1;
                en_acc_w    = 1'b0;
            end
            S_PROCESS: begin
                o_busy_w    = 1'b1;
                o_out_valid_w = 1'b0;
                en_in_w     = 1'b0;
                en_acc_w    = 1'b1 && (inst_reg == INST_SACC);
            end
            S_DONE: begin
                o_busy_w    = 1'b1;
                o_out_valid_w = 1'b1;
                en_in_w     = 1'b0;
                en_acc_w    = 1'b0;
            end
        endcase
    end

    assign o_busy      = o_busy_w;
    assign o_out_valid = o_out_valid_w;
endmodule

module signed_add(
    input signed [16:0] data_a,
    input signed [16:0] data_b,
    output signed [15:0] data_o
);
    wire signed [17:0] data_inter;
    wire overflow_flag;

    assign data_inter = data_a + data_b;
    assign overflow_flag = (data_a[16] && // negitive numbers overflow
                            data_b[16] && 
                            ((&data_inter[(17) -: 3]) == 1'b0)) ||  
                           ((!data_a[16]) && // positive numbers overflow
                            (!data_b[16]) && 
                            ((|data_inter[(17) -: 3]) == 1'b1));    

    assign data_o = (!overflow_flag) ? data_inter[15:0] : (
                        ((!data_a[16]) && (!data_b[16])) ? 16'h7fff : (       // positive numbers overflow => saturate to maximum
                            (data_a[16] && data_b[16]) ? 16'h8000 : 16'h0000  // negitive numbers overflow => saturate to minimum
                        )
                    ); 

endmodule

module signed_mul(
    input signed [15:0] data_a,
    input signed [15:0] data_b,
    output signed [15:0] data_o
);

    reg signed [31:0] data_inter;
    reg signed [31:0] data_rounded;
    reg [15:0] data_o_w;

    always @(*)
    begin
        // multiplication
        data_inter = data_a * data_b;
        // rounding
        data_rounded = (data_inter[9] == 1'b1) ? (data_inter + 32'h00000400) : data_inter;
        // saturation
        if(data_a[15] ^ data_b[15]) begin 
            // data_a, data_b are different signed num ==> neg output (need to make sure data_a and data_b aren't 0)
            data_o_w = (&data_inter[31:25] == 1'b0 && (|data_a != 1'b0) && (|data_b != 1'b0)) ? 16'h8000 : data_rounded[25:10];
        end
        else begin
            // data_a, data_b are same signed num ==> pos output 
            data_o_w = (|data_inter[31:25] == 1'b1) ? 16'h7fff : data_rounded[25:10];
        end
    end

    assign data_o = data_o_w;

endmodule

module signed_acc(
    input i_clk,
    input i_rst_n,
    input en_acc,
    input [15:0] index,
    input signed [15:0] value,
    output signed [15:0] acc_o 
);
    
    reg signed [19:0] mem[0:15]; // memory array
    reg signed [15:0] acc_o_w;

    // update memory units
    integer i;
    always @(negedge i_rst_n or posedge i_clk)
    begin
        if(!i_rst_n) begin
            for(i=0; i<16; i = i+1) begin
                mem[i] <= 20'h00000;
            end
        end
        else begin
            for(i=0; i<16; i = i+1) begin
                mem[i] <= (en_acc && (i==index)) ? (mem[i] + value) : mem[i];
            end
        end
    end


    // saturate the output
    always @(*)
    begin
        acc_o_w = 16'h0000;

        if(mem[index][19] == 1'b0) begin // positive
            acc_o_w = (|mem[index][18:15] == 1'b1) ? 16'h7fff : mem[index][15:0];
        end
        else begin
            acc_o_w = (&mem[index][18:15] == 1'b0) ? 16'h8000 : mem[index][15:0];
        end
    end

    assign acc_o = acc_o_w;

endmodule

module softplus(
    input signed [15:0] data_a,
    output signed [15:0] data_o
);

    // ################################################################
    // ### To maintain the precision,                               ###
    // ### we need to use 2+16+20 bits register to store the value. ###
    // ################################################################

    // add additional 1 bit for shifting
    reg signed [16:0] data_shift;
    // add additional 1 bit for adding
    reg signed [17:0] data_add;
    // add addtional 20 bits for division
    reg signed [37:0] data_result;
    // for rounding
    reg signed [37:0] data_rounded;
    // for finalized result
    reg signed [15:0] data_o_w;
    reg [5:0] decision_flag;

    always @(*)
    begin
        // default assignment
        data_shift = 17'sh0_0000;
        data_add   = 18'sh0_0000;
        data_result = 38'sh00_0000_0000;
        data_rounded = 38'sh0000;
        data_o_w = 16'sh0000;

        // set the flag for branching
        decision_flag = { (data_a >= 16'sh0800),  // x >=  2
                          (data_a < 16'sh0800) && (data_a >= 16'sh0000),  // 2 > x >=  0
                          (data_a < 16'sh0000) && (data_a >= 16'shfc00),  // 0 > x >= -1
                          (data_a < 16'shfc00) && (data_a >= 16'shf800),  //-1 > x >= -2
                          (data_a < 16'shf800) && (data_a >= 16'shf400),  //-2 > x >= -3
                          (data_a < 16'shf400)  // -3 > x
                        };

        if(decision_flag[5] == 1'b1) begin
            // x >= 2, output : x
            data_shift = data_a;
            data_add = data_shift;
            data_result = data_add;
            data_rounded = data_result;
            data_o_w = data_rounded[15:0];
        end
        else if(decision_flag[4] == 1'b1) begin
            // 2 > x >= 0, output : (2x+2)/3
            // left shift 1 (x2) [17 bits signed]
            data_shift = data_a <<< 1;
            // add 2 (+2) [18 bits signed]
            data_add = data_shift + 18'sh0800;
            // divided by 3 (x1/3) [38 bits signed]
            data_result = data_add * 38'sh5_5555;
            // rounding [38 bits signed]
            data_rounded = (data_result[19] == 1'b1) ? (data_result + 38'sh00_0010_0000) : data_result;
            // finalized result [16 bits signed]
            data_o_w = data_rounded[35:20];
        end
        else if(decision_flag[3] == 1'b1) begin
            // 0 > x >= -1, output : (x+2)/3
            // no shift [17 bits signed]
            data_shift = data_a;
            // add 2 (+2) [18 bits signed]
            data_add = data_shift + 18'sh0800;
            // divided by 3 (x1/3) [38 bits signed]
            data_result = data_add * 38'sh5_5555;
            // rounding [38 bits signed]
            data_rounded = (data_result[19] == 1'b1) ? (data_result + 38'sh00_0010_0000) : data_result;
            // finalized result [16 bits signed]
            data_o_w = data_rounded[35:20];
        end
        else if(decision_flag[2] == 1'b1) begin
            // -1 > x >= -2, output : (2x+5)/9
            // left shift 1 (x2) [17 bits signed]
            data_shift = data_a <<< 1;
            // add 5 (+5) [18 bits signed]
            data_add = data_shift + 18'sh0_1400;
            // divided by 9 (x1/9) [38 bits signed]
            data_result = data_add * 38'sh1_c71c;
            // rounding
            data_rounded = (data_result[19] == 1'b1) ? (data_result + 38'sh00_0010_0000) : data_result;
            // finalized result [16 bits signed]
            data_o_w = data_rounded[35:20];
        end
        else if(decision_flag[1] == 1'b1) begin 
            // -2 > x >= -3, output : (x+3)/9
            // no shift [17 bits signed]
            data_shift = data_a;
            // add 3 (+3) [18 bits signed]
            data_add = data_shift + 18'sh0_0c00;
            // divided by 9 (x1/9) [38 bits signed]
            data_result = data_add * 38'sh1_c71c;
            // rounding
            data_rounded = (data_result[19] == 1'b1) ? (data_result + 38'sh00_0010_0000) : data_result;
            // finalized result [16 bits signed]
            data_o_w = data_rounded[35:20];
        end
        else if(decision_flag[0] == 1'b1) begin
            // -3 > x, output : 0
            data_shift = 16'sh0000;
            data_add = data_shift;
            data_result = data_add;
            data_rounded = data_result;
            data_o_w = data_rounded[15:0];
        end
        else begin
            data_shift = 17'sh0_0000;
            data_add   = 18'sh0_0000;
            data_result = 38'sh00_0000_0000;
            data_rounded = 38'sh0000;
            data_o_w = 16'sh0000;
        end 

    end

    assign data_o = data_o_w;


endmodule

module count_leading_zero (
    input [15:0] data,
    output signed [15:0] leading_zero
);
    
    reg [15:0] data_enc;
    reg [15:0] leading_zero_w;

    always @(*) begin
        data_enc = {bits_enc(data[15:12]),bits_enc(data[11:8]),bits_enc(data[7:4]),bits_enc(data[3:0])};

        leading_zero_w = (data_enc[15:12] == 4'b0100) ? (
            (data_enc[11:8] == 4'b0100) ? (
                (data_enc[7:4] == 4'b0100) ? (
                    (data_enc[3:0] == 4'b0100) ? (
                        16'd16
                    ) : (16'd12 + data_enc[3:0])
                ) : (16'd8 + data_enc[7:4])
            ) : (16'd4 + data_enc[11:8])
        ) : (data_enc[15:12]);
        
    end

    assign leading_zero = leading_zero_w;


    function [3:0] bits_enc;
        input [3:0] bits;        
        begin
            bits_enc = (bits[3:0] == 4'b0000) ? 4'b0100 : (   // bit pattern 0000 has 4 leading zero
                (bits[3:0] == 4'b0001) ? 4'b0011 : (      // bit pattern 0001 has 3 leading zero
                    (bits[3:1] == 3'b001) ? 4'b0010 : ( // bit pattern 001x has 2 leading zeros
                        (bits[3:2] == 2'b01) ? 4'b0001 : ( // bit pattern 01xx has 1 leading zeros
                            4'b0000
                        )
                    )
                )
            );
        end
    endfunction

endmodule


module reverse_match_4(
    input [15:0] data_a,
    input [15:0] data_b,
    output [15:0] data_o
);

    reg [15:0] data_o_w;

    integer i;
    always @(*)
    begin
        data_o_w = 16'h0000;
        for(i=0; i<13; i = i+1) begin
            data_o_w[i] = (data_a[i +: 4] == data_b[(15-i) -: 4]) ? 1'b1 : 1'b0;
        end
    end

    assign data_o = data_o_w;

endmodule