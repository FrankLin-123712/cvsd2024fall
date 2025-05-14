`define ENCRYPT  3'b001
`define DECRYPT  3'b010
`define CRC_GEN  3'b011
`define TOP2MAX  3'b100
`define LAST2MIN 3'b101

`define SEL_CR   1'd0
`define SEL_COMP 1'd1

`define ENCRYPT_MODE 2'd0
`define DECRYPT_MODE 2'd1
`define CRC_GEN_MODE 2'd2

module SystemController(
    // ------- io -------
    input i_clk,
    input i_rst,
    input i_en,
    input [2:0] i_sel_fn,
    output o_valid,

    // select engine
    output o_sel_iot_eng,

    // data loader
    output o_dl_dready,
    input i_dl_dvalid,

    // encrypter / decrypter / crc
    output o_cr_en,
    output [1:0] o_cr_sel_fn,
    input i_cr_done,

    // comparator
    output o_comp_set_mode,
    output o_comp_sel_fn,
    input i_comp_setted,
    output o_comp_en,
    input i_comp_ready,
    input i_comp_done
);

localparam S_RESET          = 4'd0,
           S_IDLE           = 4'd1,
           S_ENC_WAIT_DATA  = 4'd2,
           S_DEC_WAIT_DATA  = 4'd3,
           S_CRC_WAIT_DATA  = 4'd4,
           S_CR_PROCESS     = 4'd5,
           S_COMP_WAIT_DATA = 4'd6,
           S_COMP_OUTPUT1   = 4'd7,
           S_COMP_OUTPUT2   = 4'd8,
           S_SET_COMP       = 4'd9;

// ------- wires and regs ----------
// status registers
reg [3:0] status_r, status_w;

// output signals 
reg o_valid_w;
// data path control signals
reg o_sel_iot_eng_w;          // select engine
reg o_dl_dready_w,            // data loader
    o_cr_en_w,                // encrypter / decrypter / crc_generator
    o_comp_set_mode_w, o_comp_sel_fn_w, o_comp_en_w; // comparator
reg [1:0] o_cr_sel_fn_w;

// counter for comparator
reg [3:0] iot_in_ctr_r, iot_in_ctr_w;
reg rst_iot_in_ctr, incr_iot_in_ctr;
wire push8data;


// ------------ counter ----------------
always@(*) begin
    // default assignment
    iot_in_ctr_w = iot_in_ctr_r;

    if(rst_iot_in_ctr)       iot_in_ctr_w = 4'd0;
    else if(incr_iot_in_ctr) iot_in_ctr_w = iot_in_ctr_r + 4'd1;
end

always@(posedge i_rst or posedge i_clk) begin
    if(i_rst) iot_in_ctr_r <= 4'd0;
    else      iot_in_ctr_r <= iot_in_ctr_w;
end

assign push8data = (iot_in_ctr_r == 4'd8);

// ------------ controller ----------------
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
                    `ENCRYPT:  status_w = S_ENC_WAIT_DATA;
                    `DECRYPT:  status_w = S_DEC_WAIT_DATA;
                    `CRC_GEN:  status_w = S_CRC_WAIT_DATA;
                    `TOP2MAX: begin
                        status_w = (i_comp_setted) ? S_SET_COMP : S_COMP_WAIT_DATA;
                    end
                    `LAST2MIN: begin
                        status_w = (i_comp_setted) ? S_SET_COMP : S_COMP_WAIT_DATA;
                    end
                endcase
            end
        end
        S_ENC_WAIT_DATA: status_w = (i_dl_dvalid) ? S_CR_PROCESS : S_ENC_WAIT_DATA;
        S_DEC_WAIT_DATA: status_w = (i_dl_dvalid) ? S_CR_PROCESS : S_DEC_WAIT_DATA;
        S_CRC_WAIT_DATA: status_w = (i_dl_dvalid) ? S_CR_PROCESS : S_CRC_WAIT_DATA;
        S_CR_PROCESS: begin
            if(i_cr_done) begin
                case(i_sel_fn)
                    `ENCRYPT: status_w = S_ENC_WAIT_DATA;
                    `DECRYPT: status_w = S_DEC_WAIT_DATA;
                    `CRC_GEN: status_w = S_CRC_WAIT_DATA;
                endcase
            end
            else status_w = S_CR_PROCESS;
        end
        
        S_SET_COMP:       status_w = S_IDLE;
        S_COMP_WAIT_DATA: status_w = (push8data) ? S_COMP_OUTPUT1 : S_COMP_WAIT_DATA;
        S_COMP_OUTPUT1:   status_w = (i_comp_done) ? S_COMP_OUTPUT2 : S_COMP_OUTPUT1;
        S_COMP_OUTPUT2:   status_w = (i_comp_done) ? S_COMP_WAIT_DATA : S_COMP_OUTPUT2;
    endcase
end

// OL
always@(*) begin
    // -------- default assignment -----------
    // output signals 
    o_valid_w = 1'b0;
    // data path control signals
    o_sel_iot_eng_w   = 1'b0; // select engine
    o_dl_dready_w     = 1'b0; // data loader
    o_cr_en_w         = 1'b0; // encrypter/decrypter/crc
    o_cr_sel_fn_w     = 2'b00;
    o_comp_set_mode_w = 1'b0; // comparator
    o_comp_sel_fn_w   = 1'b0; 
    o_comp_en_w       = 1'b0; 
    // counter
    rst_iot_in_ctr  = 1'b0;
    incr_iot_in_ctr = 1'b0;

    case(status_r)
        // S_RESET: all output set to 0
        S_IDLE: begin
            if(i_en && ((i_sel_fn == `TOP2MAX)||(i_sel_fn == `LAST2MIN)) && (!i_comp_setted)) begin
                o_comp_set_mode_w = 1'b1;
                o_comp_sel_fn_w   = (i_sel_fn == `LAST2MIN);
            end
        end
        S_ENC_WAIT_DATA: begin
            // data loader
            o_dl_dready_w = 1'b1;
            // encrypter
            o_cr_en_w       = i_dl_dvalid;
            o_cr_sel_fn_w   = `ENCRYPT_MODE;
            o_sel_iot_eng_w = `SEL_CR;
        end
        S_DEC_WAIT_DATA: begin
            // data loader
            o_dl_dready_w = 1'b1;
            // encrypter
            o_cr_en_w       = i_dl_dvalid;
            o_cr_sel_fn_w   = `DECRYPT_MODE;
            o_sel_iot_eng_w = `SEL_CR;
        end
        S_CRC_WAIT_DATA: begin
            // data loader
            o_dl_dready_w = 1'b1;
            // encrypter
            o_cr_en_w       = i_dl_dvalid;
            o_cr_sel_fn_w   = `CRC_GEN_MODE;
            o_sel_iot_eng_w = `SEL_CR;
        end
        S_CR_PROCESS: begin
            o_valid_w       = i_cr_done;
            o_sel_iot_eng_w = `SEL_CR;
        end
        // S_SET_COMP: no output
        S_COMP_WAIT_DATA: begin
            if(!push8data) begin
                // data loader
                o_dl_dready_w = i_comp_ready;
                // comparator
                o_comp_en_w     = i_dl_dvalid;
                o_sel_iot_eng_w = `SEL_COMP;
                // counter
                incr_iot_in_ctr = i_dl_dvalid;
            end
        end
        S_COMP_OUTPUT1: begin
            o_valid_w       = i_comp_done;
            o_sel_iot_eng_w = `SEL_COMP;
        end
        S_COMP_OUTPUT2: begin
            o_valid_w = i_comp_done;
            o_sel_iot_eng_w = `SEL_COMP;
            // counter
            rst_iot_in_ctr = i_comp_done;
        end
    endcase
end

// output signals 
assign o_valid = o_valid_w ;

// data path control signals
assign o_sel_iot_eng   = o_sel_iot_eng_w;   // select engine

assign o_dl_dready     = o_dl_dready_w;     // data loader

assign o_cr_en         = o_cr_en_w;         // encrypter / decrypter / crc_generator
assign o_cr_sel_fn     = o_cr_sel_fn_w;

assign o_comp_set_mode = o_comp_set_mode_w; // comparator
assign o_comp_sel_fn   = o_comp_sel_fn_w; 
assign o_comp_en       = o_comp_en_w; 

endmodule