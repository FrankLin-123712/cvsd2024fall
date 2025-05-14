`define ENCRYPT_MODE 2'd0
`define DECRYPT_MODE 2'd1
`define CRC_GEN_MODE 2'd2

module EnDecryptCrcgen(
    input i_clk,
    input i_rst,
    input i_en,
    input [1:0] i_sel_fn,
    input [127:0] i_iot_in,
    output o_done,
    output [127:0] o_iot_out
);

// ---------- wires and regs -----------
// iot data buffer
reg [127:0] iot_buf_r, iot_buf_w;
wire wen_iot_buf;

// counter
reg [3:0] ctr_r, ctr_w;
wire rst_ctr, incr_ctr;

// subkey generator
wire sel_key_in, mode, wen_ckey;
wire [3:0] round_out;
wire [47:0] key_n;

// plaintext codec
wire sel_text_in, en_switch, wen_ctext;
wire [63:0] ciphertext_w;

// crc generator
wire rst_remain, wen_remain;
wire [127:0] crc_out;

// select output data
wire sel_iot_out;

// ---------- module registers ---------
// iot data buffer
always@(*) begin
    if(wen_iot_buf) iot_buf_w = i_iot_in;
    else            iot_buf_w = iot_buf_r;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) iot_buf_r <= 128'd0;
    else      iot_buf_r <= iot_buf_w;
end

// round counter
always@(*) begin
    // default assignment
    ctr_w = ctr_r;

    if(rst_ctr)       ctr_w = 4'd0;
    else if(incr_ctr) ctr_w = ctr_r + 4'd1;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) ctr_r <= 4'd0;
    else      ctr_r <= ctr_w;
end

// ---------- CryptCRC_controller -----------
CryptCRC_controller controller(
    // io
    .i_clk(i_clk), .i_rst(i_rst), 
    .i_en(i_en), .i_sel_fn(i_sel_fn), 
    .o_done(o_done), .o_sel_iot_out(sel_iot_out),

    // data path control signals - engine wise
    .o_wen_iot_buf(wen_iot_buf),
    .o_rst_ctr(rst_ctr), .o_incr_ctr(incr_ctr),

    // data path control signals - subkey generator
    .o_sel_key_in(sel_key_in), .o_mode(mode), .o_round_out(round_out), 
    .o_wen_ckey(wen_ckey),

    // data path control signals - plaintext codec
    .o_sel_text_in(sel_text_in), .o_en_switch(en_switch),
    .o_wen_ctext(wen_ctext),

    // data path control signals - crc generator
    .o_rst_remain(rst_remain), .o_wen_remain(wen_remain),

    // data path status signals
    .i_round_in(ctr_r)
);
// --------- crc generator ------------
crc_generator crc_generator0(
    .i_clk(i_clk), .i_rst(i_rst),
    .i_iot_in(iot_buf_r), .i_ctr(ctr_r),
    .i_rst_remain(rst_remain), .i_wen_remain(wen_remain),
    .o_crc_out(crc_out)
);
// ---------- subkey generator -----------
subkey_generator subkey_generator0(
    .i_clk(i_clk), .i_rst(i_rst),
    .i_mainkey(iot_buf_r[127:64]),
    .i_sel_key_in(sel_key_in), .i_mode(mode), .i_round(round_out),
    .i_wen_ckey(wen_ckey),
    .o_kn(key_n)
);

// ---------- plaintext codec -----------
plaintext_codec plaintext_codec0(
    .i_clk(i_clk), .i_rst(i_rst),
    .i_plaintext(iot_buf_r[63:0]), .i_kn(key_n),
    .i_sel_text_in(sel_text_in), .i_en_switch(en_switch),
    .i_wen_ctext(wen_ctext),
    .o_ciphertext(ciphertext_w)
);

// ---------- result out ------------
assign o_iot_out = (sel_iot_out) ? crc_out : {iot_buf_r[127:64], ciphertext_w};

endmodule


module CryptCRC_controller(
    // ---------- engine io ---------- 
    input i_clk,
    input i_rst,
    input i_en,
    input [1:0] i_sel_fn,
    output o_done,
    output o_sel_iot_out,
    // ---------- data path control signals ---------- 
    // engine-wise
    output o_wen_iot_buf,
    output o_rst_ctr,
    output o_incr_ctr,
    // key generator
    output o_sel_key_in,
    output o_mode,
    output [3:0] o_round_out,
    output o_wen_ckey,
    // encrypter
    output o_sel_text_in,
    output o_en_switch,
    output o_wen_ctext,
    // crc generator
    output o_rst_remain,
    output o_wen_remain,
    
    // data path status signals
    input [3:0] i_round_in
);

localparam S_RESET    = 3'd0, 
           S_IDLE     = 3'd1,
           S_ENC      = 3'd2,
           S_ENC_DONE = 3'd3,
           S_DEC      = 3'd4,
           S_DEC_DONE = 3'd5,
           S_CRC_GEN  = 3'd6,
           S_CRC_DONE = 3'd7;

// --------- wires and registers --------- 
reg [2:0] status_r, status_w;
// io
reg o_done_w, o_sel_iot_out_w;
// module registers
reg o_wen_iot_buf_w,
    o_rst_ctr_w, o_incr_ctr_w;
// key generator
reg o_sel_key_in_w, o_mode_w;
reg [3:0] o_round_out_w;
reg o_wen_ckey_w;
// encrypter
reg o_sel_text_in_w, o_en_switch_w,
    o_wen_ctext_w;
// crc generator
reg o_rst_remain_w, o_wen_remain_w;

// CS
always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) status_r <= S_RESET;
    else      status_r <= status_w;
end

// NS
always@(*) begin
    status_w = S_IDLE;
    case(status_r)
        S_RESET: status_w = S_IDLE;
        S_IDLE: begin
            if(i_en) begin
                case(i_sel_fn)
                    `ENCRYPT_MODE: status_w = S_ENC;
                    `DECRYPT_MODE: status_w = S_DEC;
                    `CRC_GEN_MODE: status_w = S_CRC_GEN;
                endcase
            end
        end
        S_ENC: begin
            if(i_round_in == 4'd15) status_w = S_ENC_DONE;
            else                    status_w = S_ENC;
        end
        S_ENC_DONE: status_w = S_IDLE;
        S_DEC: begin
            if(i_round_in == 4'd15) status_w = S_DEC_DONE;
            else                    status_w = S_DEC;
        end
        S_DEC_DONE: status_w = S_IDLE;
        S_CRC_GEN: begin
            if(i_round_in == 4'd15) status_w = S_CRC_DONE;
            else                    status_w = S_CRC_GEN;
        end
        S_CRC_DONE: status_w = S_IDLE;
    endcase
end

// OL
always@(*) begin
    // io
    o_done_w        = 1'b0;
    o_sel_iot_out_w = 1'b0;
    // module registers
    o_wen_iot_buf_w = 1'b0;
    o_rst_ctr_w     = 1'b0;
    o_incr_ctr_w    = 1'b0;
    // key generator
    o_sel_key_in_w  = 1'b0;
    o_mode_w        = 1'b0;
    o_round_out_w   = 4'd0;
    o_wen_ckey_w    = 1'b0;
    // encrypter
    o_sel_text_in_w = 1'b0;
    o_en_switch_w   = 1'b0;
    o_wen_ctext_w   = 1'b0;
    // crc generator
    o_rst_remain_w = 1'b0;
    o_wen_remain_w = 1'b0;

    case(status_r)
        // S_RESET
        S_IDLE: begin
            o_wen_iot_buf_w = i_en;
        end
        S_ENC: begin
            // data path control signals
            o_sel_key_in_w  = (i_round_in != 4'd0);
            o_mode_w        = 1'b0;
            o_round_out_w   = i_round_in;

            o_sel_text_in_w = (i_round_in != 4'd0);
            o_en_switch_w   = (i_round_in != 4'd15);
            
            if(i_round_in < 4'd15) begin
                // data path registers wen signals
                o_wen_ckey_w  = 1'b1;
                o_wen_ctext_w = 1'b1;
                // module registers
                o_incr_ctr_w = 1'b1;
            end
            else if(i_round_in == 4'd15) begin
                // data path registers wen signals
                o_wen_ctext_w = 1'b1;
            end
        end
        S_ENC_DONE: begin
            // io
            o_done_w        = 1'b1;
            o_sel_iot_out_w = 1'b0;
            // module registers
            o_rst_ctr_w     = 1'b1;
        end
        S_DEC: begin
            // data path control signals
            o_sel_key_in_w  = (i_round_in != 4'd0);
            o_mode_w        = 1'b1;
            o_round_out_w   = i_round_in;

            o_sel_text_in_w = (i_round_in != 4'd0);
            o_en_switch_w   = (i_round_in != 4'd15);

            if(i_round_in < 4'd15) begin
                // data path registers wen signals
                o_wen_ckey_w = 1'b1;
                o_wen_ctext_w   = 1'b1;
                // module registers
                o_incr_ctr_w = 1'b1;
            end
            else if(i_round_in == 4'd15) begin
                // data path registers wen signals
                o_wen_ctext_w = 1'b1;
            end
        end
        S_DEC_DONE: begin
            // io
            o_done_w        = 1'b1;
            o_sel_iot_out_w = 1'b0;
            // module registers
            o_rst_ctr_w     = 1'b1;
        end
        S_CRC_GEN: begin
            if(i_round_in < 4'd15) begin
                // data path registers wen signals
                o_wen_remain_w = 1'b1;
                // module registers
                o_incr_ctr_w = 1'b1;
            end
            else if(i_round_in == 4'd15) begin
                // data path registers wen signals
                o_wen_remain_w = 1'b1;
            end
        end
        S_CRC_DONE: begin
            // io
            o_done_w        = 1'b1;
            o_sel_iot_out_w = 1'b1;
            // module registers
            o_rst_ctr_w     = 1'b1;
            // data path register
            o_rst_remain_w  = 1'b1;
        end
    endcase
end

// io
assign o_done        = o_done_w;
assign o_sel_iot_out = o_sel_iot_out_w;

// iot_buf
assign o_wen_iot_buf = o_wen_iot_buf_w;
assign o_rst_ctr     = o_rst_ctr_w;
assign o_incr_ctr    = o_incr_ctr_w;

// key generator
assign o_sel_key_in = o_sel_key_in_w;
assign o_mode       = o_mode_w;
assign o_round_out  = o_round_out_w;
assign o_wen_ckey   = o_wen_ckey_w;

// encrypter
assign o_sel_text_in = o_sel_text_in_w;
assign o_en_switch   = o_en_switch_w;
assign o_wen_ctext   = o_wen_ctext_w;

// crc generator
assign o_rst_remain  = o_rst_remain_w;
assign o_wen_remain  = o_wen_remain_w;

endmodule

module crc_generator(
    input i_clk,
    input i_rst,
    input [127:0] i_iot_in,
    input [3:0] i_ctr,
    input i_rst_remain,
    input i_wen_remain,
    output [127:0] o_crc_out
);

// -------- wires and regs ---------
reg [2:0] crc_r, crc_w;

wire [7:0] partial_div;
wire [6:0] base_addr;
wire [2:0] crc_check;

// --------- computing crc --------
// Select 8 bits (starting from MSB)
assign base_addr   = {3'b000, i_ctr} << 3;
assign partial_div = i_iot_in[(7'd127-base_addr) -: 8];

// perform mod2 polynomial division
assign crc_check[2] = crc_r[1]^crc_r[0]^partial_div[6]^partial_div[5]^partial_div[3]^partial_div[2];
assign crc_check[1] = crc_r[2]^crc_r[1]^partial_div[7]^partial_div[6]^partial_div[4]^partial_div[3]^partial_div[1];
assign crc_check[0] = partial_div[0];

// ---------- crc register -----------
always@(*) begin
    if(i_rst_remain)      crc_w = 3'd0;
    else if(i_wen_remain) crc_w = crc_check;
    else                  crc_w = crc_r;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) crc_r <= 3'd0;
    else      crc_r <= crc_w;
end

// ---------- output ------------
assign o_crc_out = {125'd0, crc_r[2]^crc_r[0], crc_r[1]^crc_r[0], 1'b0};

endmodule


module subkey_generator(
    input i_clk,
    input i_rst,
    input [63:0] i_mainkey,
    input i_sel_key_in,
    input i_mode,
    input [3:0] i_round,
    input i_wen_ckey,
    output [47:0] o_kn
);

// -------------- wires and regs ----------------
wire [55:0] init_ckey, ckey2cs, sft_ckey;
reg [55:0] ckey_r, ckey_w;

// perform PC1
assign init_ckey = PC1(i_mainkey);

// ckey register
always@(*) begin
    if(i_wen_ckey) ckey_w = sft_ckey;
    else           ckey_w = ckey_r;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) ckey_r <= 56'd0;
    else      ckey_r <= ckey_w;
end

// perform circular shift
assign ckey2cs = (i_sel_key_in) ? ckey_r : init_ckey;

circular_shifter circular_shifter0(
    .i_mode(i_mode), .i_round(i_round), 
    .i_ckey(ckey2cs), .o_sft_ckey(sft_ckey)
);

assign o_kn = PC2(sft_ckey);

// PC1
function automatic [55:0] PC1;
    input [63:0] i_mainkey;
    begin
        PC1[55] = i_mainkey[7];
        PC1[54] = i_mainkey[15];
        PC1[53] = i_mainkey[23];
        PC1[52] = i_mainkey[31];
        PC1[51] = i_mainkey[39];
        PC1[50] = i_mainkey[47];
        PC1[49] = i_mainkey[55];
        PC1[48] = i_mainkey[63];
    
        PC1[47] = i_mainkey[6];
        PC1[46] = i_mainkey[14];
        PC1[45] = i_mainkey[22];
        PC1[44] = i_mainkey[30];
        PC1[43] = i_mainkey[38];
        PC1[42] = i_mainkey[46];
        PC1[41] = i_mainkey[54];
        PC1[40] = i_mainkey[62];
    
        PC1[39] = i_mainkey[5];
        PC1[38] = i_mainkey[13];
        PC1[37] = i_mainkey[21];
        PC1[36] = i_mainkey[29];
        PC1[35] = i_mainkey[37];
        PC1[34] = i_mainkey[45];
        PC1[33] = i_mainkey[53];
        PC1[32] = i_mainkey[61];
    
        PC1[31] = i_mainkey[4];
        PC1[30] = i_mainkey[12];
        PC1[29] = i_mainkey[20];
        PC1[28] = i_mainkey[28];
        PC1[27] = i_mainkey[1];
        PC1[26] = i_mainkey[9];
        PC1[25] = i_mainkey[17];
        PC1[24] = i_mainkey[25];
    
        PC1[23] = i_mainkey[33];
        PC1[22] = i_mainkey[41];
        PC1[21] = i_mainkey[49];
        PC1[20] = i_mainkey[57];
        PC1[19] = i_mainkey[2];
        PC1[18] = i_mainkey[10];
        PC1[17] = i_mainkey[18];
        PC1[16] = i_mainkey[26];
    
        PC1[15] = i_mainkey[34];
        PC1[14] = i_mainkey[42];
        PC1[13] = i_mainkey[50];
        PC1[12] = i_mainkey[58];
        PC1[11] = i_mainkey[3];
        PC1[10] = i_mainkey[11];
        PC1[9]  = i_mainkey[19];
        PC1[8]  = i_mainkey[27];
    
        PC1[7] = i_mainkey[35];
        PC1[6] = i_mainkey[43];
        PC1[5] = i_mainkey[51];
        PC1[4] = i_mainkey[59];
        PC1[3] = i_mainkey[36];
        PC1[2] = i_mainkey[44];
        PC1[1] = i_mainkey[52];
        PC1[0] = i_mainkey[60];
    end
endfunction

// PC2
function automatic [47:0] PC2;
    input [55:0] i_key;
    begin
        PC2[47] = i_key[42];
        PC2[46] = i_key[39];
        PC2[45] = i_key[45];
        PC2[44] = i_key[32];
        PC2[43] = i_key[55];
        PC2[42] = i_key[51];
        PC2[41] = i_key[53];
        PC2[40] = i_key[28];
        
        PC2[39] = i_key[41];
        PC2[38] = i_key[50];
        PC2[37] = i_key[35];
        PC2[36] = i_key[46];
        PC2[35] = i_key[33];
        PC2[34] = i_key[37];
        PC2[33] = i_key[44];
        PC2[32] = i_key[52];
        
        PC2[31] = i_key[30];
        PC2[30] = i_key[48];
        PC2[29] = i_key[40];
        PC2[28] = i_key[49];
        PC2[27] = i_key[29];
        PC2[26] = i_key[36];
        PC2[25] = i_key[43];
        PC2[24] = i_key[54];
        
        PC2[23] = i_key[15];
        PC2[22] = i_key[4];
        PC2[21] = i_key[25];
        PC2[20] = i_key[19];
        PC2[19] = i_key[9];
        PC2[18] = i_key[1];
        PC2[17] = i_key[26];
        PC2[16] = i_key[16];
        
        PC2[15] = i_key[5];
        PC2[14] = i_key[11];
        PC2[13] = i_key[23];
        PC2[12] = i_key[8];
        PC2[11] = i_key[12];
        PC2[10] = i_key[7];
        PC2[9]  = i_key[17];
        PC2[8]  = i_key[0];
        
        PC2[7] = i_key[22];
        PC2[6] = i_key[3];
        PC2[5] = i_key[10];
        PC2[4] = i_key[14];
        PC2[3] = i_key[6];
        PC2[2] = i_key[20];
        PC2[1] = i_key[27];
        PC2[0] = i_key[24];
    end
endfunction
endmodule


`define SFT_LEFT 1'b0
`define SFT_RIGHT 1'b1

module circular_shifter(
    input i_mode, // 0 for encrypter, 1 for decrypter
    input [3:0] i_round,
    input [55:0] i_ckey,
    output [55:0] o_sft_ckey
);

// -------------- wires and regs ----------------
wire [27:0] right_ckey, left_ckey;
reg [27:0] sft_right_ckey, sft_left_ckey;
reg sft_direct; // 0 for left shift, 1 for right shift
reg [1:0] sft_amount;

assign {left_ckey, right_ckey} = i_ckey;

// LUT for sft_direct and sft_amount
always@(*) begin
    if(i_mode == 1'b0) begin // encrypter
        sft_direct = `SFT_LEFT;
        if((i_round == 4'd0) || (i_round == 4'd1) || 
           (i_round == 4'd8) || (i_round == 4'd15)) sft_amount = 2'd1;
        else                                        sft_amount = 2'd2;
    end
    else begin // decrypter
        sft_direct = `SFT_RIGHT;
        if((i_round == 4'd1) || (i_round == 4'd8) || (i_round == 4'd15)) sft_amount = 2'd1;
        else if(i_round == 4'd0)                                         sft_amount = 2'd0;
        else                                                             sft_amount = 2'd2;
    end
end

// shifter
always@(*) begin
    // default assignment
    sft_left_ckey = left_ckey;
    sft_right_ckey = right_ckey; 

    if(sft_direct == `SFT_LEFT) begin  // shift left
        if(sft_amount == 2'd2) begin
            sft_left_ckey = {left_ckey[25:0], left_ckey[27:26]};
            sft_right_ckey = {right_ckey[25:0], right_ckey[27:26]};
        end
        else if(sft_amount == 2'd1) begin
            sft_left_ckey = {left_ckey[26:0], left_ckey[27]};
            sft_right_ckey = {right_ckey[26:0], right_ckey[27]};
        end
    end
    else begin  // shift right
        if(sft_amount == 2'd2) begin
            sft_left_ckey = {left_ckey[1:0], left_ckey[27:2]};
            sft_right_ckey = {right_ckey[1:0], right_ckey[27:2]};
        end
        else if(sft_amount == 2'd1) begin
            sft_left_ckey = {left_ckey[0], left_ckey[27:1]};
            sft_right_ckey = {right_ckey[0], right_ckey[27:1]};
        end
    end
end

assign o_sft_ckey = {sft_left_ckey, sft_right_ckey};

endmodule

module plaintext_codec(
    input i_clk,
    input i_rst,
    input [63:0] i_plaintext,
    input [47:0] i_kn,
    input i_sel_text_in,
    input i_en_switch,
    input i_wen_ctext,
    output [63:0] o_ciphertext
);

// ----------- wires and regs -----------
wire [63:0] init_plaintext, plaintext2F;
reg [63:0] ctext_r, ctext_w;
wire [31:0] R0_F, R0_w, L0_w;
wire [31:0] R0_switch, L0_switch;

assign init_plaintext = initial_permutation(i_plaintext);
assign plaintext2F = (i_sel_text_in) ? ctext_r : init_plaintext;

assign R0_w = plaintext2F[31:0];
F F0(.i_r(plaintext2F[31:0]), .i_k(i_kn), .o_F(R0_F));
assign L0_w = plaintext2F[63:32] ^ R0_F;

assign R0_switch = (i_en_switch) ? L0_w : R0_w;
assign L0_switch = (i_en_switch) ? R0_w : L0_w;

// ctext register
always@(*) begin
    if(i_wen_ctext) ctext_w = {L0_switch, R0_switch};
    else            ctext_w = ctext_r;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) ctext_r <= 64'd0;
    else      ctext_r <= ctext_w;
end

// perform final permutation
assign o_ciphertext = final_permutation(ctext_r);

// inital permutation
function automatic [63:0] initial_permutation;
    input [63:0] i_plaintext;
    begin
        initial_permutation[63] = i_plaintext[6];
        initial_permutation[62] = i_plaintext[14];
        initial_permutation[61] = i_plaintext[22];
        initial_permutation[60] = i_plaintext[30];
        initial_permutation[59] = i_plaintext[38];
        initial_permutation[58] = i_plaintext[46];
        initial_permutation[57] = i_plaintext[54];
        initial_permutation[56] = i_plaintext[62];

        initial_permutation[55] = i_plaintext[4];
        initial_permutation[54] = i_plaintext[12];
        initial_permutation[53] = i_plaintext[20];
        initial_permutation[52] = i_plaintext[28];
        initial_permutation[51] = i_plaintext[36];
        initial_permutation[50] = i_plaintext[44];
        initial_permutation[49] = i_plaintext[52];
        initial_permutation[48] = i_plaintext[60];

        initial_permutation[47] = i_plaintext[2];
        initial_permutation[46] = i_plaintext[10];
        initial_permutation[45] = i_plaintext[18];
        initial_permutation[44] = i_plaintext[26];
        initial_permutation[43] = i_plaintext[34];
        initial_permutation[42] = i_plaintext[42];
        initial_permutation[41] = i_plaintext[50];
        initial_permutation[40] = i_plaintext[58];

        initial_permutation[39] = i_plaintext[0];
        initial_permutation[38] = i_plaintext[8];
        initial_permutation[37] = i_plaintext[16];
        initial_permutation[36] = i_plaintext[24];
        initial_permutation[35] = i_plaintext[32];
        initial_permutation[34] = i_plaintext[40];
        initial_permutation[33] = i_plaintext[48];
        initial_permutation[32] = i_plaintext[56];

        initial_permutation[31] = i_plaintext[7];
        initial_permutation[30] = i_plaintext[15];
        initial_permutation[29] = i_plaintext[23];
        initial_permutation[28] = i_plaintext[31];
        initial_permutation[27] = i_plaintext[39];
        initial_permutation[26] = i_plaintext[47];
        initial_permutation[25] = i_plaintext[55];
        initial_permutation[24] = i_plaintext[63];

        initial_permutation[23] = i_plaintext[5];
        initial_permutation[22] = i_plaintext[13];
        initial_permutation[21] = i_plaintext[21];
        initial_permutation[20] = i_plaintext[29];
        initial_permutation[19] = i_plaintext[37];
        initial_permutation[18] = i_plaintext[45];
        initial_permutation[17] = i_plaintext[53];
        initial_permutation[16] = i_plaintext[61];

        initial_permutation[15] = i_plaintext[3];
        initial_permutation[14] = i_plaintext[11];
        initial_permutation[13] = i_plaintext[19];
        initial_permutation[12] = i_plaintext[27];
        initial_permutation[11] = i_plaintext[35];
        initial_permutation[10] = i_plaintext[43];
        initial_permutation[9]  = i_plaintext[51];
        initial_permutation[8]  = i_plaintext[59];

        initial_permutation[7] = i_plaintext[1];
        initial_permutation[6] = i_plaintext[9];
        initial_permutation[5] = i_plaintext[17];
        initial_permutation[4] = i_plaintext[25];
        initial_permutation[3] = i_plaintext[33];
        initial_permutation[2] = i_plaintext[41];
        initial_permutation[1] = i_plaintext[49];
        initial_permutation[0] = i_plaintext[57];
    end
endfunction

// final_permutation
function automatic [63:0] final_permutation;
    input [63:0] i_r16code;
    begin
        final_permutation[63] = i_r16code[24];
        final_permutation[62] = i_r16code[56];
        final_permutation[61] = i_r16code[16];
        final_permutation[60] = i_r16code[48];
        final_permutation[59] = i_r16code[8];
        final_permutation[58] = i_r16code[40];
        final_permutation[57] = i_r16code[0];
        final_permutation[56] = i_r16code[32];

        final_permutation[55] = i_r16code[25];
        final_permutation[54] = i_r16code[57];
        final_permutation[53] = i_r16code[17];
        final_permutation[52] = i_r16code[49];
        final_permutation[51] = i_r16code[9];
        final_permutation[50] = i_r16code[41];
        final_permutation[49] = i_r16code[1];
        final_permutation[48] = i_r16code[33];

        final_permutation[47] = i_r16code[26];
        final_permutation[46] = i_r16code[58];
        final_permutation[45] = i_r16code[18];
        final_permutation[44] = i_r16code[50];
        final_permutation[43] = i_r16code[10];
        final_permutation[42] = i_r16code[42];
        final_permutation[41] = i_r16code[2];
        final_permutation[40] = i_r16code[34];

        final_permutation[39] = i_r16code[27];
        final_permutation[38] = i_r16code[59];
        final_permutation[37] = i_r16code[19];
        final_permutation[36] = i_r16code[51];
        final_permutation[35] = i_r16code[11];
        final_permutation[34] = i_r16code[43];
        final_permutation[33] = i_r16code[3];
        final_permutation[32] = i_r16code[35];

        final_permutation[31] = i_r16code[28];
        final_permutation[30] = i_r16code[60];
        final_permutation[29] = i_r16code[20];
        final_permutation[28] = i_r16code[52];
        final_permutation[27] = i_r16code[12];
        final_permutation[26] = i_r16code[44];
        final_permutation[25] = i_r16code[4];
        final_permutation[24] = i_r16code[36];

        final_permutation[23] = i_r16code[29];
        final_permutation[22] = i_r16code[61];
        final_permutation[21] = i_r16code[21];
        final_permutation[20] = i_r16code[53];
        final_permutation[19] = i_r16code[13];
        final_permutation[18] = i_r16code[45];
        final_permutation[17] = i_r16code[5];
        final_permutation[16] = i_r16code[37];

        final_permutation[15] = i_r16code[30];
        final_permutation[14] = i_r16code[62];
        final_permutation[13] = i_r16code[22];
        final_permutation[12] = i_r16code[54];
        final_permutation[11] = i_r16code[14];
        final_permutation[10] = i_r16code[46];
        final_permutation[9]  = i_r16code[6];
        final_permutation[8]  = i_r16code[38];

        final_permutation[7] = i_r16code[31];
        final_permutation[6] = i_r16code[63];
        final_permutation[5] = i_r16code[23];
        final_permutation[4] = i_r16code[55];
        final_permutation[3] = i_r16code[15];
        final_permutation[2] = i_r16code[47];
        final_permutation[1] = i_r16code[7];
        final_permutation[0] = i_r16code[39];
    end
endfunction




endmodule

`define ROW_BOX(x) {x[5], x[0]}
`define COL_BOX(x) x[4:1]

module F(
    input [31:0] i_r,
    input [47:0] i_k,
    output [31:0] o_F
);

wire [47:0] eps_w, eps_xor_k_w;
reg [5:0] sbox_i[0:7]; 
reg [3:0] sbox_o[0:7];
wire [31:0] p_in;

assign eps_w = expansion(i_r);
assign eps_xor_k_w = eps_w ^ i_k;

integer i;
always@(*) begin
    for(i=0; i<8; i=i+1) begin
        sbox_i[i] = eps_xor_k_w[(7-i)*6 +: 6];
    end
end

// s1 box
always@(*) begin
    sbox_o[0] = 4'b0000;
    case(`ROW_BOX(sbox_i[0]))
        2'b00: begin
            case(`COL_BOX(sbox_i[0]))
                4'b0000: sbox_o[0] = 4'd14;
                4'b0001: sbox_o[0] = 4'd4;
                4'b0010: sbox_o[0] = 4'd13;
                4'b0011: sbox_o[0] = 4'd1;
                4'b0100: sbox_o[0] = 4'd2;
                4'b0101: sbox_o[0] = 4'd15;
                4'b0110: sbox_o[0] = 4'd11;
                4'b0111: sbox_o[0] = 4'd8;
                4'b1000: sbox_o[0] = 4'd3;
                4'b1001: sbox_o[0] = 4'd10;
                4'b1010: sbox_o[0] = 4'd6;
                4'b1011: sbox_o[0] = 4'd12;
                4'b1100: sbox_o[0] = 4'd5;
                4'b1101: sbox_o[0] = 4'd9;
                4'b1110: sbox_o[0] = 4'd0;
                4'b1111: sbox_o[0] = 4'd7;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[0]))
                4'b0000: sbox_o[0] = 4'd0;
                4'b0001: sbox_o[0] = 4'd15;
                4'b0010: sbox_o[0] = 4'd7;
                4'b0011: sbox_o[0] = 4'd4;
                4'b0100: sbox_o[0] = 4'd14;
                4'b0101: sbox_o[0] = 4'd2;
                4'b0110: sbox_o[0] = 4'd13;
                4'b0111: sbox_o[0] = 4'd1;
                4'b1000: sbox_o[0] = 4'd10;
                4'b1001: sbox_o[0] = 4'd6;
                4'b1010: sbox_o[0] = 4'd12;
                4'b1011: sbox_o[0] = 4'd11;
                4'b1100: sbox_o[0] = 4'd9;
                4'b1101: sbox_o[0] = 4'd5;
                4'b1110: sbox_o[0] = 4'd3;
                4'b1111: sbox_o[0] = 4'd8;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[0]))
                4'b0000: sbox_o[0] = 4'd4;
                4'b0001: sbox_o[0] = 4'd1;
                4'b0010: sbox_o[0] = 4'd14;
                4'b0011: sbox_o[0] = 4'd8;
                4'b0100: sbox_o[0] = 4'd13;
                4'b0101: sbox_o[0] = 4'd6;
                4'b0110: sbox_o[0] = 4'd2;
                4'b0111: sbox_o[0] = 4'd11;
                4'b1000: sbox_o[0] = 4'd15;
                4'b1001: sbox_o[0] = 4'd12;
                4'b1010: sbox_o[0] = 4'd9;
                4'b1011: sbox_o[0] = 4'd7;
                4'b1100: sbox_o[0] = 4'd3;
                4'b1101: sbox_o[0] = 4'd10;
                4'b1110: sbox_o[0] = 4'd5;
                4'b1111: sbox_o[0] = 4'd0;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[0]))
                4'b0000: sbox_o[0] = 4'd15;
                4'b0001: sbox_o[0] = 4'd12;
                4'b0010: sbox_o[0] = 4'd8;
                4'b0011: sbox_o[0] = 4'd2;
                4'b0100: sbox_o[0] = 4'd4;
                4'b0101: sbox_o[0] = 4'd9;
                4'b0110: sbox_o[0] = 4'd1;
                4'b0111: sbox_o[0] = 4'd7;
                4'b1000: sbox_o[0] = 4'd5;
                4'b1001: sbox_o[0] = 4'd11;
                4'b1010: sbox_o[0] = 4'd3;
                4'b1011: sbox_o[0] = 4'd14;
                4'b1100: sbox_o[0] = 4'd10;
                4'b1101: sbox_o[0] = 4'd0;
                4'b1110: sbox_o[0] = 4'd6;
                4'b1111: sbox_o[0] = 4'd13;
            endcase
        end
    endcase
end

// s2 box
always@(*) begin
    sbox_o[1] = 4'b0000;
    case(`ROW_BOX(sbox_i[1]))
        2'b00: begin
            case(`COL_BOX(sbox_i[1]))
                4'b0000: sbox_o[1] = 4'd15;
                4'b0001: sbox_o[1] = 4'd1;
                4'b0010: sbox_o[1] = 4'd8;
                4'b0011: sbox_o[1] = 4'd14;
                4'b0100: sbox_o[1] = 4'd6;
                4'b0101: sbox_o[1] = 4'd11;
                4'b0110: sbox_o[1] = 4'd3;
                4'b0111: sbox_o[1] = 4'd4;
                4'b1000: sbox_o[1] = 4'd9;
                4'b1001: sbox_o[1] = 4'd7;
                4'b1010: sbox_o[1] = 4'd2;
                4'b1011: sbox_o[1] = 4'd13;
                4'b1100: sbox_o[1] = 4'd12;
                4'b1101: sbox_o[1] = 4'd0;
                4'b1110: sbox_o[1] = 4'd5;
                4'b1111: sbox_o[1] = 4'd10;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[1]))
                4'b0000: sbox_o[1] = 4'd3;
                4'b0001: sbox_o[1] = 4'd13;
                4'b0010: sbox_o[1] = 4'd4;
                4'b0011: sbox_o[1] = 4'd7;
                4'b0100: sbox_o[1] = 4'd15;
                4'b0101: sbox_o[1] = 4'd2;
                4'b0110: sbox_o[1] = 4'd8;
                4'b0111: sbox_o[1] = 4'd14;
                4'b1000: sbox_o[1] = 4'd12;
                4'b1001: sbox_o[1] = 4'd0;
                4'b1010: sbox_o[1] = 4'd1;
                4'b1011: sbox_o[1] = 4'd10;
                4'b1100: sbox_o[1] = 4'd6;
                4'b1101: sbox_o[1] = 4'd9;
                4'b1110: sbox_o[1] = 4'd11;
                4'b1111: sbox_o[1] = 4'd5;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[1]))
                4'b0000: sbox_o[1] = 4'd0;
                4'b0001: sbox_o[1] = 4'd14;
                4'b0010: sbox_o[1] = 4'd7;
                4'b0011: sbox_o[1] = 4'd11;
                4'b0100: sbox_o[1] = 4'd10;
                4'b0101: sbox_o[1] = 4'd4;
                4'b0110: sbox_o[1] = 4'd13;
                4'b0111: sbox_o[1] = 4'd1;
                4'b1000: sbox_o[1] = 4'd5;
                4'b1001: sbox_o[1] = 4'd8;
                4'b1010: sbox_o[1] = 4'd12;
                4'b1011: sbox_o[1] = 4'd6;
                4'b1100: sbox_o[1] = 4'd9;
                4'b1101: sbox_o[1] = 4'd3;
                4'b1110: sbox_o[1] = 4'd2;
                4'b1111: sbox_o[1] = 4'd15;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[1]))
                4'b0000: sbox_o[1] = 4'd13;
                4'b0001: sbox_o[1] = 4'd8;
                4'b0010: sbox_o[1] = 4'd10;
                4'b0011: sbox_o[1] = 4'd1;
                4'b0100: sbox_o[1] = 4'd3;
                4'b0101: sbox_o[1] = 4'd15;
                4'b0110: sbox_o[1] = 4'd4;
                4'b0111: sbox_o[1] = 4'd2;
                4'b1000: sbox_o[1] = 4'd11;
                4'b1001: sbox_o[1] = 4'd6;
                4'b1010: sbox_o[1] = 4'd7;
                4'b1011: sbox_o[1] = 4'd12;
                4'b1100: sbox_o[1] = 4'd0;
                4'b1101: sbox_o[1] = 4'd5;
                4'b1110: sbox_o[1] = 4'd14;
                4'b1111: sbox_o[1] = 4'd9;
            endcase
        end
    endcase
end

// S3 Look-up Table Implementation
always@(*) begin
    sbox_o[2] = 4'b0000;
    case(`ROW_BOX(sbox_i[2]))
        2'b00: begin
            case(`COL_BOX(sbox_i[2]))
                4'b0000: sbox_o[2] = 4'd10;
                4'b0001: sbox_o[2] = 4'd0;
                4'b0010: sbox_o[2] = 4'd9;
                4'b0011: sbox_o[2] = 4'd14;
                4'b0100: sbox_o[2] = 4'd6;
                4'b0101: sbox_o[2] = 4'd3;
                4'b0110: sbox_o[2] = 4'd15;
                4'b0111: sbox_o[2] = 4'd5;
                4'b1000: sbox_o[2] = 4'd1;
                4'b1001: sbox_o[2] = 4'd13;
                4'b1010: sbox_o[2] = 4'd12;
                4'b1011: sbox_o[2] = 4'd7;
                4'b1100: sbox_o[2] = 4'd11;
                4'b1101: sbox_o[2] = 4'd4;
                4'b1110: sbox_o[2] = 4'd2;
                4'b1111: sbox_o[2] = 4'd8;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[2]))
                4'b0000: sbox_o[2] = 4'd13;
                4'b0001: sbox_o[2] = 4'd7;
                4'b0010: sbox_o[2] = 4'd0;
                4'b0011: sbox_o[2] = 4'd9;
                4'b0100: sbox_o[2] = 4'd3;
                4'b0101: sbox_o[2] = 4'd4;
                4'b0110: sbox_o[2] = 4'd6;
                4'b0111: sbox_o[2] = 4'd10;
                4'b1000: sbox_o[2] = 4'd2;
                4'b1001: sbox_o[2] = 4'd8;
                4'b1010: sbox_o[2] = 4'd5;
                4'b1011: sbox_o[2] = 4'd14;
                4'b1100: sbox_o[2] = 4'd12;
                4'b1101: sbox_o[2] = 4'd11;
                4'b1110: sbox_o[2] = 4'd15;
                4'b1111: sbox_o[2] = 4'd1;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[2]))
                4'b0000: sbox_o[2] = 4'd13;
                4'b0001: sbox_o[2] = 4'd6;
                4'b0010: sbox_o[2] = 4'd4;
                4'b0011: sbox_o[2] = 4'd9;
                4'b0100: sbox_o[2] = 4'd8;
                4'b0101: sbox_o[2] = 4'd15;
                4'b0110: sbox_o[2] = 4'd3;
                4'b0111: sbox_o[2] = 4'd0;
                4'b1000: sbox_o[2] = 4'd11;
                4'b1001: sbox_o[2] = 4'd1;
                4'b1010: sbox_o[2] = 4'd2;
                4'b1011: sbox_o[2] = 4'd12;
                4'b1100: sbox_o[2] = 4'd5;
                4'b1101: sbox_o[2] = 4'd10;
                4'b1110: sbox_o[2] = 4'd14;
                4'b1111: sbox_o[2] = 4'd7;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[2]))
                4'b0000: sbox_o[2] = 4'd1;
                4'b0001: sbox_o[2] = 4'd10;
                4'b0010: sbox_o[2] = 4'd13;
                4'b0011: sbox_o[2] = 4'd0;
                4'b0100: sbox_o[2] = 4'd6;
                4'b0101: sbox_o[2] = 4'd9;
                4'b0110: sbox_o[2] = 4'd8;
                4'b0111: sbox_o[2] = 4'd7;
                4'b1000: sbox_o[2] = 4'd4;
                4'b1001: sbox_o[2] = 4'd15;
                4'b1010: sbox_o[2] = 4'd14;
                4'b1011: sbox_o[2] = 4'd3;
                4'b1100: sbox_o[2] = 4'd11;
                4'b1101: sbox_o[2] = 4'd5;
                4'b1110: sbox_o[2] = 4'd2;
                4'b1111: sbox_o[2] = 4'd12;
            endcase
        end
    endcase
end

// S4 Look-up Table Implementation
always@(*) begin
    sbox_o[3] = 4'b0000;
    case(`ROW_BOX(sbox_i[3]))
        2'b00: begin
            case(`COL_BOX(sbox_i[3]))
                4'b0000: sbox_o[3] = 4'd7;
                4'b0001: sbox_o[3] = 4'd13;
                4'b0010: sbox_o[3] = 4'd14;
                4'b0011: sbox_o[3] = 4'd3;
                4'b0100: sbox_o[3] = 4'd0;
                4'b0101: sbox_o[3] = 4'd6;
                4'b0110: sbox_o[3] = 4'd9;
                4'b0111: sbox_o[3] = 4'd10;
                4'b1000: sbox_o[3] = 4'd1;
                4'b1001: sbox_o[3] = 4'd2;
                4'b1010: sbox_o[3] = 4'd8;
                4'b1011: sbox_o[3] = 4'd5;
                4'b1100: sbox_o[3] = 4'd11;
                4'b1101: sbox_o[3] = 4'd12;
                4'b1110: sbox_o[3] = 4'd4;
                4'b1111: sbox_o[3] = 4'd15;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[3]))
                4'b0000: sbox_o[3] = 4'd13;
                4'b0001: sbox_o[3] = 4'd8;
                4'b0010: sbox_o[3] = 4'd11;
                4'b0011: sbox_o[3] = 4'd5;
                4'b0100: sbox_o[3] = 4'd6;
                4'b0101: sbox_o[3] = 4'd15;
                4'b0110: sbox_o[3] = 4'd0;
                4'b0111: sbox_o[3] = 4'd3;
                4'b1000: sbox_o[3] = 4'd4;
                4'b1001: sbox_o[3] = 4'd7;
                4'b1010: sbox_o[3] = 4'd2;
                4'b1011: sbox_o[3] = 4'd12;
                4'b1100: sbox_o[3] = 4'd1;
                4'b1101: sbox_o[3] = 4'd10;
                4'b1110: sbox_o[3] = 4'd14;
                4'b1111: sbox_o[3] = 4'd9;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[3]))
                4'b0000: sbox_o[3] = 4'd10;
                4'b0001: sbox_o[3] = 4'd6;
                4'b0010: sbox_o[3] = 4'd9;
                4'b0011: sbox_o[3] = 4'd0;
                4'b0100: sbox_o[3] = 4'd12;
                4'b0101: sbox_o[3] = 4'd11;
                4'b0110: sbox_o[3] = 4'd7;
                4'b0111: sbox_o[3] = 4'd13;
                4'b1000: sbox_o[3] = 4'd15;
                4'b1001: sbox_o[3] = 4'd1;
                4'b1010: sbox_o[3] = 4'd3;
                4'b1011: sbox_o[3] = 4'd14;
                4'b1100: sbox_o[3] = 4'd5;
                4'b1101: sbox_o[3] = 4'd2;
                4'b1110: sbox_o[3] = 4'd8;
                4'b1111: sbox_o[3] = 4'd4;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[3]))
                4'b0000: sbox_o[3] = 4'd3;
                4'b0001: sbox_o[3] = 4'd15;
                4'b0010: sbox_o[3] = 4'd0;
                4'b0011: sbox_o[3] = 4'd6;
                4'b0100: sbox_o[3] = 4'd10;
                4'b0101: sbox_o[3] = 4'd1;
                4'b0110: sbox_o[3] = 4'd13;
                4'b0111: sbox_o[3] = 4'd8;
                4'b1000: sbox_o[3] = 4'd9;
                4'b1001: sbox_o[3] = 4'd4;
                4'b1010: sbox_o[3] = 4'd5;
                4'b1011: sbox_o[3] = 4'd11;
                4'b1100: sbox_o[3] = 4'd12;
                4'b1101: sbox_o[3] = 4'd7;
                4'b1110: sbox_o[3] = 4'd2;
                4'b1111: sbox_o[3] = 4'd14;
            endcase
        end
    endcase
end


// S5 Look-up Table Implementation
always@(*) begin
    sbox_o[4] = 4'b0000;
    case(`ROW_BOX(sbox_i[4]))
        2'b00: begin
            case(`COL_BOX(sbox_i[4]))
                4'b0000: sbox_o[4] = 4'd2;
                4'b0001: sbox_o[4] = 4'd12;
                4'b0010: sbox_o[4] = 4'd4;
                4'b0011: sbox_o[4] = 4'd1;
                4'b0100: sbox_o[4] = 4'd7;
                4'b0101: sbox_o[4] = 4'd10;
                4'b0110: sbox_o[4] = 4'd11;
                4'b0111: sbox_o[4] = 4'd6;
                4'b1000: sbox_o[4] = 4'd8;
                4'b1001: sbox_o[4] = 4'd5;
                4'b1010: sbox_o[4] = 4'd3;
                4'b1011: sbox_o[4] = 4'd15;
                4'b1100: sbox_o[4] = 4'd13;
                4'b1101: sbox_o[4] = 4'd0;
                4'b1110: sbox_o[4] = 4'd14;
                4'b1111: sbox_o[4] = 4'd9;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[4]))
                4'b0000: sbox_o[4] = 4'd14;
                4'b0001: sbox_o[4] = 4'd11;
                4'b0010: sbox_o[4] = 4'd2;
                4'b0011: sbox_o[4] = 4'd12;
                4'b0100: sbox_o[4] = 4'd4;
                4'b0101: sbox_o[4] = 4'd7;
                4'b0110: sbox_o[4] = 4'd13;
                4'b0111: sbox_o[4] = 4'd1;
                4'b1000: sbox_o[4] = 4'd5;
                4'b1001: sbox_o[4] = 4'd0;
                4'b1010: sbox_o[4] = 4'd15;
                4'b1011: sbox_o[4] = 4'd10;
                4'b1100: sbox_o[4] = 4'd3;
                4'b1101: sbox_o[4] = 4'd9;
                4'b1110: sbox_o[4] = 4'd8;
                4'b1111: sbox_o[4] = 4'd6;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[4]))
                4'b0000: sbox_o[4] = 4'd4;
                4'b0001: sbox_o[4] = 4'd2;
                4'b0010: sbox_o[4] = 4'd1;
                4'b0011: sbox_o[4] = 4'd11;
                4'b0100: sbox_o[4] = 4'd10;
                4'b0101: sbox_o[4] = 4'd13;
                4'b0110: sbox_o[4] = 4'd7;
                4'b0111: sbox_o[4] = 4'd8;
                4'b1000: sbox_o[4] = 4'd15;
                4'b1001: sbox_o[4] = 4'd9;
                4'b1010: sbox_o[4] = 4'd12;
                4'b1011: sbox_o[4] = 4'd5;
                4'b1100: sbox_o[4] = 4'd6;
                4'b1101: sbox_o[4] = 4'd3;
                4'b1110: sbox_o[4] = 4'd0;
                4'b1111: sbox_o[4] = 4'd14;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[4]))
                4'b0000: sbox_o[4] = 4'd11;
                4'b0001: sbox_o[4] = 4'd8;
                4'b0010: sbox_o[4] = 4'd12;
                4'b0011: sbox_o[4] = 4'd7;
                4'b0100: sbox_o[4] = 4'd1;
                4'b0101: sbox_o[4] = 4'd14;
                4'b0110: sbox_o[4] = 4'd2;
                4'b0111: sbox_o[4] = 4'd13;
                4'b1000: sbox_o[4] = 4'd6;
                4'b1001: sbox_o[4] = 4'd15;
                4'b1010: sbox_o[4] = 4'd0;
                4'b1011: sbox_o[4] = 4'd9;
                4'b1100: sbox_o[4] = 4'd10;
                4'b1101: sbox_o[4] = 4'd4;
                4'b1110: sbox_o[4] = 4'd5;
                4'b1111: sbox_o[4] = 4'd3;
            endcase
        end
    endcase
end

// S6 Look-up Table Implementation
always@(*) begin
    sbox_o[5] = 4'b0000;
    case(`ROW_BOX(sbox_i[5]))
        2'b00: begin
            case(`COL_BOX(sbox_i[5]))
                4'b0000: sbox_o[5] = 4'd12;
                4'b0001: sbox_o[5] = 4'd1;
                4'b0010: sbox_o[5] = 4'd10;
                4'b0011: sbox_o[5] = 4'd15;
                4'b0100: sbox_o[5] = 4'd9;
                4'b0101: sbox_o[5] = 4'd2;
                4'b0110: sbox_o[5] = 4'd6;
                4'b0111: sbox_o[5] = 4'd8;
                4'b1000: sbox_o[5] = 4'd0;
                4'b1001: sbox_o[5] = 4'd13;
                4'b1010: sbox_o[5] = 4'd3;
                4'b1011: sbox_o[5] = 4'd4;
                4'b1100: sbox_o[5] = 4'd14;
                4'b1101: sbox_o[5] = 4'd7;
                4'b1110: sbox_o[5] = 4'd5;
                4'b1111: sbox_o[5] = 4'd11;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[5]))
                4'b0000: sbox_o[5] = 4'd10;
                4'b0001: sbox_o[5] = 4'd15;
                4'b0010: sbox_o[5] = 4'd4;
                4'b0011: sbox_o[5] = 4'd2;
                4'b0100: sbox_o[5] = 4'd7;
                4'b0101: sbox_o[5] = 4'd12;
                4'b0110: sbox_o[5] = 4'd9;
                4'b0111: sbox_o[5] = 4'd5;
                4'b1000: sbox_o[5] = 4'd6;
                4'b1001: sbox_o[5] = 4'd1;
                4'b1010: sbox_o[5] = 4'd13;
                4'b1011: sbox_o[5] = 4'd14;
                4'b1100: sbox_o[5] = 4'd0;
                4'b1101: sbox_o[5] = 4'd11;
                4'b1110: sbox_o[5] = 4'd3;
                4'b1111: sbox_o[5] = 4'd8;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[5]))
                4'b0000: sbox_o[5] = 4'd9;
                4'b0001: sbox_o[5] = 4'd14;
                4'b0010: sbox_o[5] = 4'd15;
                4'b0011: sbox_o[5] = 4'd5;
                4'b0100: sbox_o[5] = 4'd2;
                4'b0101: sbox_o[5] = 4'd8;
                4'b0110: sbox_o[5] = 4'd12;
                4'b0111: sbox_o[5] = 4'd3;
                4'b1000: sbox_o[5] = 4'd7;
                4'b1001: sbox_o[5] = 4'd0;
                4'b1010: sbox_o[5] = 4'd4;
                4'b1011: sbox_o[5] = 4'd10;
                4'b1100: sbox_o[5] = 4'd1;
                4'b1101: sbox_o[5] = 4'd13;
                4'b1110: sbox_o[5] = 4'd11;
                4'b1111: sbox_o[5] = 4'd6;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[5]))
                4'b0000: sbox_o[5] = 4'd4;
                4'b0001: sbox_o[5] = 4'd3;
                4'b0010: sbox_o[5] = 4'd2;
                4'b0011: sbox_o[5] = 4'd12;
                4'b0100: sbox_o[5] = 4'd9;
                4'b0101: sbox_o[5] = 4'd5;
                4'b0110: sbox_o[5] = 4'd15;
                4'b0111: sbox_o[5] = 4'd10;
                4'b1000: sbox_o[5] = 4'd11;
                4'b1001: sbox_o[5] = 4'd14;
                4'b1010: sbox_o[5] = 4'd1;
                4'b1011: sbox_o[5] = 4'd7;
                4'b1100: sbox_o[5] = 4'd6;
                4'b1101: sbox_o[5] = 4'd0;
                4'b1110: sbox_o[5] = 4'd8;
                4'b1111: sbox_o[5] = 4'd13;
            endcase
        end
    endcase
end

// S7 Look-up Table Implementation
always@(*) begin
    sbox_o[6] = 4'b0000;
    case(`ROW_BOX(sbox_i[6]))
        2'b00: begin
            case(`COL_BOX(sbox_i[6]))
                4'b0000: sbox_o[6] = 4'd4;
                4'b0001: sbox_o[6] = 4'd11;
                4'b0010: sbox_o[6] = 4'd2;
                4'b0011: sbox_o[6] = 4'd14;
                4'b0100: sbox_o[6] = 4'd15;
                4'b0101: sbox_o[6] = 4'd0;
                4'b0110: sbox_o[6] = 4'd8;
                4'b0111: sbox_o[6] = 4'd13;
                4'b1000: sbox_o[6] = 4'd3;
                4'b1001: sbox_o[6] = 4'd12;
                4'b1010: sbox_o[6] = 4'd9;
                4'b1011: sbox_o[6] = 4'd7;
                4'b1100: sbox_o[6] = 4'd5;
                4'b1101: sbox_o[6] = 4'd10;
                4'b1110: sbox_o[6] = 4'd6;
                4'b1111: sbox_o[6] = 4'd1;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[6]))
                4'b0000: sbox_o[6] = 4'd13;
                4'b0001: sbox_o[6] = 4'd0;
                4'b0010: sbox_o[6] = 4'd11;
                4'b0011: sbox_o[6] = 4'd7;
                4'b0100: sbox_o[6] = 4'd4;
                4'b0101: sbox_o[6] = 4'd9;
                4'b0110: sbox_o[6] = 4'd1;
                4'b0111: sbox_o[6] = 4'd10;
                4'b1000: sbox_o[6] = 4'd14;
                4'b1001: sbox_o[6] = 4'd3;
                4'b1010: sbox_o[6] = 4'd5;
                4'b1011: sbox_o[6] = 4'd12;
                4'b1100: sbox_o[6] = 4'd2;
                4'b1101: sbox_o[6] = 4'd15;
                4'b1110: sbox_o[6] = 4'd8;
                4'b1111: sbox_o[6] = 4'd6;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[6]))
                4'b0000: sbox_o[6] = 4'd1;
                4'b0001: sbox_o[6] = 4'd4;
                4'b0010: sbox_o[6] = 4'd11;
                4'b0011: sbox_o[6] = 4'd13;
                4'b0100: sbox_o[6] = 4'd12;
                4'b0101: sbox_o[6] = 4'd3;
                4'b0110: sbox_o[6] = 4'd7;
                4'b0111: sbox_o[6] = 4'd14;
                4'b1000: sbox_o[6] = 4'd10;
                4'b1001: sbox_o[6] = 4'd15;
                4'b1010: sbox_o[6] = 4'd6;
                4'b1011: sbox_o[6] = 4'd8;
                4'b1100: sbox_o[6] = 4'd0;
                4'b1101: sbox_o[6] = 4'd5;
                4'b1110: sbox_o[6] = 4'd9;
                4'b1111: sbox_o[6] = 4'd2;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[6]))
                4'b0000: sbox_o[6] = 4'd6;
                4'b0001: sbox_o[6] = 4'd11;
                4'b0010: sbox_o[6] = 4'd13;
                4'b0011: sbox_o[6] = 4'd8;
                4'b0100: sbox_o[6] = 4'd1;
                4'b0101: sbox_o[6] = 4'd4;
                4'b0110: sbox_o[6] = 4'd10;
                4'b0111: sbox_o[6] = 4'd7;
                4'b1000: sbox_o[6] = 4'd9;
                4'b1001: sbox_o[6] = 4'd5;
                4'b1010: sbox_o[6] = 4'd0;
                4'b1011: sbox_o[6] = 4'd15;
                4'b1100: sbox_o[6] = 4'd14;
                4'b1101: sbox_o[6] = 4'd2;
                4'b1110: sbox_o[6] = 4'd3;
                4'b1111: sbox_o[6] = 4'd12;
            endcase
        end
    endcase
end

// S8 Look-up Table Implementation
always@(*) begin
    sbox_o[7] = 4'b0000;
    case(`ROW_BOX(sbox_i[7]))
        2'b00: begin
            case(`COL_BOX(sbox_i[7]))
                4'b0000: sbox_o[7] = 4'd13;
                4'b0001: sbox_o[7] = 4'd2;
                4'b0010: sbox_o[7] = 4'd8;
                4'b0011: sbox_o[7] = 4'd4;
                4'b0100: sbox_o[7] = 4'd6;
                4'b0101: sbox_o[7] = 4'd15;
                4'b0110: sbox_o[7] = 4'd11;
                4'b0111: sbox_o[7] = 4'd1;
                4'b1000: sbox_o[7] = 4'd10;
                4'b1001: sbox_o[7] = 4'd9;
                4'b1010: sbox_o[7] = 4'd3;
                4'b1011: sbox_o[7] = 4'd14;
                4'b1100: sbox_o[7] = 4'd5;
                4'b1101: sbox_o[7] = 4'd0;
                4'b1110: sbox_o[7] = 4'd12;
                4'b1111: sbox_o[7] = 4'd7;
            endcase
        end
        2'b01: begin
            case(`COL_BOX(sbox_i[7]))
                4'b0000: sbox_o[7] = 4'd1;
                4'b0001: sbox_o[7] = 4'd15;
                4'b0010: sbox_o[7] = 4'd13;
                4'b0011: sbox_o[7] = 4'd8;
                4'b0100: sbox_o[7] = 4'd10;
                4'b0101: sbox_o[7] = 4'd3;
                4'b0110: sbox_o[7] = 4'd7;
                4'b0111: sbox_o[7] = 4'd4;
                4'b1000: sbox_o[7] = 4'd12;
                4'b1001: sbox_o[7] = 4'd5;
                4'b1010: sbox_o[7] = 4'd6;
                4'b1011: sbox_o[7] = 4'd11;
                4'b1100: sbox_o[7] = 4'd0;
                4'b1101: sbox_o[7] = 4'd14;
                4'b1110: sbox_o[7] = 4'd9;
                4'b1111: sbox_o[7] = 4'd2;
            endcase
        end
        2'b10: begin
            case(`COL_BOX(sbox_i[7]))
                4'b0000: sbox_o[7] = 4'd7;
                4'b0001: sbox_o[7] = 4'd11;
                4'b0010: sbox_o[7] = 4'd4;
                4'b0011: sbox_o[7] = 4'd1;
                4'b0100: sbox_o[7] = 4'd9;
                4'b0101: sbox_o[7] = 4'd12;
                4'b0110: sbox_o[7] = 4'd14;
                4'b0111: sbox_o[7] = 4'd2;
                4'b1000: sbox_o[7] = 4'd0;
                4'b1001: sbox_o[7] = 4'd6;
                4'b1010: sbox_o[7] = 4'd10;
                4'b1011: sbox_o[7] = 4'd13;
                4'b1100: sbox_o[7] = 4'd15;
                4'b1101: sbox_o[7] = 4'd3;
                4'b1110: sbox_o[7] = 4'd5;
                4'b1111: sbox_o[7] = 4'd8;
            endcase
        end
        2'b11: begin
            case(`COL_BOX(sbox_i[7]))
                4'b0000: sbox_o[7] = 4'd2;
                4'b0001: sbox_o[7] = 4'd1;
                4'b0010: sbox_o[7] = 4'd14;
                4'b0011: sbox_o[7] = 4'd7;
                4'b0100: sbox_o[7] = 4'd4;
                4'b0101: sbox_o[7] = 4'd10;
                4'b0110: sbox_o[7] = 4'd8;
                4'b0111: sbox_o[7] = 4'd13;
                4'b1000: sbox_o[7] = 4'd15;
                4'b1001: sbox_o[7] = 4'd12;
                4'b1010: sbox_o[7] = 4'd9;
                4'b1011: sbox_o[7] = 4'd0;
                4'b1100: sbox_o[7] = 4'd3;
                4'b1101: sbox_o[7] = 4'd5;
                4'b1110: sbox_o[7] = 4'd6;
                4'b1111: sbox_o[7] = 4'd11;
            endcase
        end
    endcase
end

// aggregate all sbox output
assign p_in = {sbox_o[0], sbox_o[1], sbox_o[2], sbox_o[3], sbox_o[4], sbox_o[5], sbox_o[6], sbox_o[7]};

// perform P
assign o_F = P(p_in);

// expansion
function automatic [47:0] expansion;
    input [31:0] i_r;
    begin
        expansion[47] = i_r[0];
        expansion[46] = i_r[31];
        expansion[45] = i_r[30];
        expansion[44] = i_r[29];
        expansion[43] = i_r[28];
        expansion[42] = i_r[27];
        expansion[41] = i_r[28];
        expansion[40] = i_r[27];
        
        expansion[39] = i_r[26];
        expansion[38] = i_r[25];
        expansion[37] = i_r[24];
        expansion[36] = i_r[23];
        expansion[35] = i_r[24];
        expansion[34] = i_r[23];
        expansion[33] = i_r[22];
        expansion[32] = i_r[21];
        
        expansion[31] = i_r[20];
        expansion[30] = i_r[19];
        expansion[29] = i_r[20];
        expansion[28] = i_r[19];
        expansion[27] = i_r[18];
        expansion[26] = i_r[17];
        expansion[25] = i_r[16];
        expansion[24] = i_r[15];
        
        expansion[23] = i_r[16];
        expansion[22] = i_r[15];
        expansion[21] = i_r[14];
        expansion[20] = i_r[13];
        expansion[19] = i_r[12];
        expansion[18] = i_r[11];
        expansion[17] = i_r[12];
        expansion[16] = i_r[11];
        
        expansion[15] = i_r[10];
        expansion[14] = i_r[9];
        expansion[13] = i_r[8];
        expansion[12] = i_r[7];
        expansion[11] = i_r[8];
        expansion[10] = i_r[7];
        expansion[9]  = i_r[6];
        expansion[8]  = i_r[5];
        
        expansion[7] = i_r[4];
        expansion[6] = i_r[3];
        expansion[5] = i_r[4];
        expansion[4] = i_r[3];
        expansion[3] = i_r[2];
        expansion[2] = i_r[1];
        expansion[1] = i_r[0];
        expansion[0] = i_r[31];
    end
endfunction

function automatic [31:0] P;
    input [31:0] i_sbox;
    begin
        P[31] = i_sbox[16];
        P[30] = i_sbox[25];
        P[29] = i_sbox[12];
        P[28] = i_sbox[11];
        P[27] = i_sbox[3];
        P[26] = i_sbox[20];
        P[25] = i_sbox[4];
        P[24] = i_sbox[15];
        
        P[23] = i_sbox[31];
        P[22] = i_sbox[17];
        P[21] = i_sbox[9];
        P[20] = i_sbox[6];
        P[19] = i_sbox[27];
        P[18] = i_sbox[14];
        P[17] = i_sbox[1];
        P[16] = i_sbox[22];
        
        P[15] = i_sbox[30];
        P[14] = i_sbox[24];
        P[13] = i_sbox[8];
        P[12] = i_sbox[18];
        P[11] = i_sbox[0];
        P[10] = i_sbox[5];
        P[9]  = i_sbox[29];
        P[8]  = i_sbox[23];
        
        P[7] = i_sbox[13];
        P[6] = i_sbox[19];
        P[5] = i_sbox[2];
        P[4] = i_sbox[26];
        P[3] = i_sbox[10];
        P[2] = i_sbox[21];
        P[1] = i_sbox[28];
        P[0] = i_sbox[7];
    end
endfunction
endmodule