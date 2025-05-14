// ##################################################
// # SRAM Banks Controller                          #
// # ---------------------------------------------- #
// # The sram banks controller to handle the three  #
// # different operation mode, including load data, #
// # display, and read compute data.                #
// ##################################################
`define RESET_MODE  3'd0
`define LOAD_MODE   3'd1
`define DISP_MODE   3'd2
`define CONV_MODE   3'd3
`define SOBEL_MODE  3'd4
`define MEDIAN_MODE 3'd5

module sram_bank_controller(
    input i_clk,
    input i_rst_n,

    // inst from system controller
    input [2:0] i_mode,
    input i_inst_valid,
    output o_inst_ready,

    // valid/ready for load data
    input i_in_data_valid,
    output o_in_data_ready,

    // valid for displaying
    output o_disp_valid,

    // ------- status signals from data path ---------
    // load data 
    input [1:0] i_load_data_bank, // addr_ctr[1:0]
    input i_addr_done_load,       // addr_ctr == 2048

    // display
    input i_row_done_disp,    // row_ctr == 1
    input i_channel_done,     // channel_ctr == depth_r
    input [1:0] i_start_bank, // start bank for dispaly

    // read compute data
    input i_row_done_read,    // row_ctr == 3
    input i_pipeline_done,    // for load compute data, high when pipeline is empty
    input [3:0] i_oob_flag,
    
    // ----------- control signals to data path ------------
    // load data
    output o_rst_addr_ctr,    // reset addr_ctr
    output o_incr_addr_ctr,   // increase addr_ctr

    // sram
    output [3:0] o_sram_cen,  // sram control signals
    output [3:0] o_sram_wen,  // sram control signals
    
    // display & read compute data
    output o_rst_inst,        // for reset inst regs
    output o_wen_inst,        // for update inst regs
    
    // address generator
    output o_addr_gen_mode,   // for address generator (0 for display, 1 for load compute data)

    // channel ctr
    output o_rst_channel_ctr, // for reset channel counter
    output o_incr_channel_ctr,// for increase channel counter when display and load compute data

    // row ctr
    output o_rst_row_ctr,   // for reset row counter
    output o_incr_row_ctr,    // for increase row counter when display and load compute data

    // portnum register
    output o_rst_portnum_r,   // for reset portnum_r
    output o_wen_portnum_r,   // for enable writing portnum_r
    
    // s1 csr  
    output o_wen_s1_csr,

    // display 
    output o_wen_disp_buf,    
    output o_disp_sel
);

// parameters 
parameter S_RESET         = 3'd0,
          S_IDLE          = 3'd1,
          S_LOAD_DATA     = 3'd2,
          S_DISP_GEN_ADDR = 3'd3,
          S_DISP_0        = 3'd4,
          S_DISP_1        = 3'd5,
          S_READ_DATA     = 3'd6;


// wires and regs
reg [2:0] status_r, status_w;

reg [3:0] cen_mask_w;
reg [3:0] wen_mask_w;

reg o_inst_ready_w;
reg o_in_data_ready_w;
reg o_disp_valid_w;
reg o_rst_addr_ctr_w;
reg o_incr_addr_ctr_w;
reg [3:0] o_sram_cen_w;
reg [3:0] o_sram_wen_w;
reg o_rst_inst_w;
reg o_wen_inst_w;
reg o_addr_gen_mode_w;
reg o_rst_channel_ctr_w;
reg o_incr_channel_ctr_w;
reg o_rst_row_ctr_w;
reg o_incr_row_ctr_w;
reg o_rst_portnum_r_w;
reg o_wen_portnum_r_w;
reg o_wen_s1_csr_w;
reg o_wen_disp_buf_w;
reg o_disp_sel_w;


// ------------------- Controller -------------------
// CS
always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) status_r <= S_RESET;
    else         status_r <= status_w;
end

// NS
always@(*) begin
    status_w = S_RESET;
    case(status_r)
        S_RESET: begin
            status_w = S_IDLE;
        end
        S_IDLE: begin
            if(i_inst_valid) begin
                case(i_mode)
                    `LOAD_MODE:   status_w = S_LOAD_DATA;
                    `DISP_MODE:   status_w = S_DISP_GEN_ADDR;
                    `CONV_MODE:   status_w = S_READ_DATA;
                    `SOBEL_MODE:  status_w = S_READ_DATA;
                    `MEDIAN_MODE: status_w = S_READ_DATA;
                endcase
            end
            else begin
                status_w = S_IDLE;
            end
        end
        S_LOAD_DATA: begin
            status_w = (i_addr_done_load) ? S_IDLE : S_LOAD_DATA;
        end
        S_DISP_GEN_ADDR: begin
            status_w = (i_channel_done) ? S_IDLE : S_DISP_0;
        end
        S_DISP_0: begin
            status_w = S_DISP_1;
        end
        S_DISP_1: begin
            status_w = S_DISP_GEN_ADDR;
        end
        S_READ_DATA: begin
            status_w = (i_channel_done && i_pipeline_done) ? S_IDLE : S_READ_DATA;
        end
    endcase
end

// OL
always@(*) begin
    // default assignments
    o_inst_ready_w    = 1'b0;
    o_in_data_ready_w = 1'b0;
    o_disp_valid_w    = 1'b0;

    o_rst_addr_ctr_w  = 1'b0;
    o_incr_addr_ctr_w = 1'b0;

    o_sram_cen_w = 4'b1111;
    o_sram_wen_w = 4'b1111;

    o_rst_inst_w = 1'b0;
    o_wen_inst_w = 1'b0;

    o_addr_gen_mode_w = 1'b0; // 0 for display
    
    o_rst_channel_ctr_w  = 1'b0;
    o_incr_channel_ctr_w = 1'b0;
    o_rst_row_ctr_w      = 1'b0;
    o_incr_row_ctr_w     = 1'b0;

    o_rst_portnum_r_w = 1'b0;
    o_wen_portnum_r_w = 1'b0;
    
    o_wen_s1_csr_w   = 1'b0;

    o_wen_disp_buf_w = 1'b0;
    o_disp_sel_w     = 1'b0;

    case(status_r)
        S_IDLE: begin
            o_inst_ready_w = 1'b1;
            if(i_inst_valid && 
                ((i_mode == `DISP_MODE)||
                 (i_mode == `CONV_MODE)||
                 (i_mode == `MEDIAN_MODE)||
                 (i_mode == `SOBEL_MODE))) begin
                o_wen_inst_w = 1'b1;
            end
        end
        S_LOAD_DATA: begin
            if(i_addr_done_load) begin
                o_rst_addr_ctr_w = 1'b1;
            end
            else begin
                o_in_data_ready_w = 1'b1;
                o_sram_cen_w = (i_in_data_valid) ? cen_mask_w : 4'b1111;
                o_sram_wen_w = (i_in_data_valid) ? wen_mask_w : 4'b1111;
                o_incr_addr_ctr_w = (i_in_data_valid) ? 1'b1 : 1'b0;
            end
        end
        S_DISP_GEN_ADDR: begin
            if(i_channel_done) begin
                o_rst_inst_w        = 1'b1;
                o_rst_channel_ctr_w = 1'b1;
                o_rst_row_ctr_w     = 1'b1;
                o_rst_portnum_r_w   = 1'b1;
            end
            else begin
                o_disp_valid_w    = 1'b0;
                o_addr_gen_mode_w = 1'b0;
                o_sram_cen_w      = cen_mask_w;
                o_sram_wen_w      = wen_mask_w;
                o_wen_portnum_r_w = 1'b1;
            end
        end
        S_DISP_0: begin
            o_disp_valid_w   = 1'b1;
            o_disp_sel_w     = 1'b0;
            o_wen_disp_buf_w = 1'b1;
        end
        S_DISP_1: begin
            o_disp_valid_w       = 1'b1;
            o_disp_sel_w         = 1'b1;
            
            o_incr_row_ctr_w     = (!i_row_done_disp) ? 1'b1 : 1'b0;
            o_rst_row_ctr_w      = (i_row_done_disp) ? 1'b1 : 1'b0;
            o_incr_channel_ctr_w = (i_row_done_disp) ? 1'b1 : 1'b0;
        end
        S_READ_DATA: begin
            if(i_channel_done && i_pipeline_done) begin
                o_rst_inst_w        = 1'b1;
                o_rst_channel_ctr_w = 1'b1;
                o_rst_row_ctr_w     = 1'b1;
                o_rst_portnum_r_w   = 1'b1;
            end
            else if(i_channel_done && !i_pipeline_done) begin
                o_addr_gen_mode_w    = 1'b1;

                o_wen_portnum_r_w    = 1'b0;
                o_wen_s1_csr_w       = 1'b0;

                o_sram_cen_w         = cen_mask_w;
                o_sram_wen_w         = wen_mask_w;

                o_incr_row_ctr_w     = 1'b0;
                o_incr_channel_ctr_w = 1'b0;
            end
            else if(!i_channel_done) begin
                o_addr_gen_mode_w    = 1'b1;

                o_wen_portnum_r_w    = 1'b1;
                o_wen_s1_csr_w       = 1'b1;

                o_sram_cen_w         = cen_mask_w;
                o_sram_wen_w         = wen_mask_w;

                o_incr_row_ctr_w     = 1'b1;
                o_incr_channel_ctr_w = (i_row_done_read) ? 1'b1 : 1'b0;
            end
        end
    endcase
end

// --------- decoder for cen and wen ----------
always@(*) begin
    cen_mask_w = 4'b1111;
    wen_mask_w = 4'b1111;
    if(status_r == S_LOAD_DATA) begin
        case(i_load_data_bank)
            2'd0: begin
                cen_mask_w = 4'b1110;
                wen_mask_w = 4'b1110;
            end
            2'd1: begin
                cen_mask_w = 4'b1101;
                wen_mask_w = 4'b1101;
            end
            2'd2: begin
                cen_mask_w = 4'b1011;
                wen_mask_w = 4'b1011;
            end
            2'd3: begin
                cen_mask_w = 4'b0111;
                wen_mask_w = 4'b0111;
            end
        endcase
    end
    else if(status_r == S_DISP_GEN_ADDR) begin
        case(i_start_bank)
            2'd0: begin
                cen_mask_w = 4'b1100;
                wen_mask_w = 4'b1111;
            end
            2'd1: begin
                cen_mask_w = 4'b1001;
                wen_mask_w = 4'b1111;
            end
            2'd2: begin
                cen_mask_w = 4'b0011;
                wen_mask_w = 4'b1111;
            end
            2'd3: begin
                cen_mask_w = 4'b0110;
                wen_mask_w = 4'b1111;
            end
        endcase
    end
    else if(status_r == S_READ_DATA) begin
        case(i_oob_flag)
            4'b1000: cen_mask_w = 4'b0001;
            4'b0001: cen_mask_w = 4'b1000;
            default: cen_mask_w = i_oob_flag;
        endcase
        wen_mask_w = 4'b1111;
    end
end


assign o_inst_ready       = o_inst_ready_w;
assign o_in_data_ready    = o_in_data_ready_w;
assign o_disp_valid       = o_disp_valid_w;
assign o_rst_addr_ctr     = o_rst_addr_ctr_w;
assign o_incr_addr_ctr    = o_incr_addr_ctr_w;
assign o_sram_cen         = o_sram_cen_w;
assign o_sram_wen         = o_sram_wen_w;
assign o_rst_inst         = o_rst_inst_w;
assign o_wen_inst         = o_wen_inst_w;
assign o_addr_gen_mode    = o_addr_gen_mode_w;
assign o_rst_channel_ctr  = o_rst_channel_ctr_w;
assign o_incr_channel_ctr = o_incr_channel_ctr_w;
assign o_rst_row_ctr      = o_rst_row_ctr_w;
assign o_incr_row_ctr     = o_incr_row_ctr_w;
assign o_rst_portnum_r    = o_rst_portnum_r_w;
assign o_wen_portnum_r    = o_wen_portnum_r_w;
assign o_wen_s1_csr       = o_wen_s1_csr_w;
assign o_wen_disp_buf     = o_wen_disp_buf_w;
assign o_disp_sel         = o_disp_sel_w;


endmodule