`define LOAD_IF  4'b0000
`define ORI_RS   4'b0001
`define ORI_LS   4'b0010
`define ORI_US   4'b0011
`define ORI_DS   4'b0100
`define RDU_CH   4'b0101
`define INC_CH   4'b0110
`define OUTPUT   4'b0111
`define CONV     4'b1000
`define MED_FLT  4'b1001
`define SOBELNMS 4'b1010

`define RESET_MODE  3'd0
`define LOAD_MODE   3'd1
`define DISP_MODE   3'd2
`define CONV_MODE   3'd3
`define SOBEL_MODE  3'd4
`define MEDIAN_MODE 3'd5

`define MV_RIGHT  3'd0
`define MV_LEFT   3'd1
`define MV_UP     3'd2
`define MV_DOWN   3'd3
`define REDUCE_CH 3'd4
`define INCRE_CH  3'd5

`define SEQ_CONV   2'd0
`define SEQ_MEDIAN 2'd1
`define SEQ_SOBEL  2'd2

module system_controller(
    input i_clk,
    input i_rst_n, 
    // ----- system IO ------
    // op
    input i_op_valid,
    input [3:0] i_op_mode,
    output o_op_ready,
    // data in
    input i_in_valid,
    output o_in_ready,
    // data out
    output o_out_valid,
    output [13:0] o_out_data,
    // ------ compute engine ------
    // sobel nms
    output o_sobel_rst_eng,
    output o_sobel_set_eng,
    output o_sobel_in_valid,
    // conv
    output o_conv_rst_eng,
    output o_conv_set_eng,
    output o_conv_in_valid,
    // median
    output o_median_rst_eng,
    output o_median_set_eng,
    output o_median_in_valid,
    // tensor shape
    output o_tensor_in_valid,
    output [2:0] o_tensor_op,
    // ------ sram controller ------
    // inst
    output [2:0] o_sram_mode,
    output o_sram_inst_valid,
    input i_sram_inst_ready,
    // load data
    output o_sram_in_data_valid,
    input i_sram_in_data_ready,
    // display
    input [7:0] i_sram_disp_data,
    input i_sram_disp_valid,
    // stream out data to compute engine
    input i_sram_out_data_valid,
    // --------- sequence out block ---------
    output o_rst_seq_out,
    input i_seq_out_valid,
    input [13:0] i_seq_out_data,
    // --------- engine done register ---------
    output o_rst_eng_done_r,    
    input i_eng_done_r,
    // ----------- sel signals for both --------
    output o_sel_valid,
    output [1:0] o_sel_eng


);

// parameters
parameter       S_RESET =  4'd0, S_IDLE           =  4'd1, S_WAIT_OP    =  4'd2, S_LOAD   =  4'd3,
            S_LOAD_COMP =  4'd4, S_MV_DISP_REGION =  4'd5, S_MV_COMP    =  4'd6, S_DISP   =  4'd7, 
            S_DISP_COMP =  4'd8, S_CONV           =  4'd9, S_CONV_COMP  = 4'd10, S_MEDIAN = 4'd11, 
          S_MEDIAN_COMP = 4'd12, S_SOBEL          = 4'd13, S_SOBEL_COMP = 4'd14;



// regs and wires
reg [3:0] status_r, status_w;

reg o_op_ready_w;           
reg o_in_ready_w;           
reg o_out_valid_w;          
reg [13:0] o_out_data_w;           
reg o_sobel_rst_eng_w;      
reg o_sobel_set_eng_w;      
reg o_sobel_in_valid_w;     
reg o_conv_rst_eng_w;       
reg o_conv_set_eng_w;       
reg o_conv_in_valid_w;      
reg o_median_rst_eng_w;     
reg o_median_set_eng_w;     
reg o_median_in_valid_w;    
reg o_tensor_in_valid_w;    
reg [2:0] o_tensor_op_w;          
reg [2:0] o_sram_mode_w;          
reg o_sram_inst_valid_w;
reg o_sram_in_data_valid_w; 
reg o_rst_seq_out_w;        
reg o_rst_eng_done_r_w;     
reg o_sel_valid_w;          
reg [1:0] o_sel_eng_w;            


// CS
always@(negedge i_rst_n or posedge i_clk) begin
    if(!i_rst_n) status_r <= S_RESET;
    else         status_r <= status_w;
end

// NS
always@(*) begin
    status_w = S_RESET;
    case(status_r)
        S_RESET:   status_w = S_IDLE;
        S_IDLE:    status_w = S_WAIT_OP;
        S_WAIT_OP: begin
            if(i_op_valid) begin
                case(i_op_mode)
                    `LOAD_IF:  status_w = S_LOAD;
                    `ORI_RS:   status_w = S_MV_DISP_REGION;
                    `ORI_LS:   status_w = S_MV_DISP_REGION;
                    `ORI_US:   status_w = S_MV_DISP_REGION; 
                    `ORI_DS:   status_w = S_MV_DISP_REGION;
                    `RDU_CH:   status_w = S_MV_DISP_REGION;
                    `INC_CH:   status_w = S_MV_DISP_REGION;
                    `OUTPUT:   status_w = S_DISP;
                    `CONV:     status_w = S_CONV;
                    `MED_FLT:  status_w = S_MEDIAN;
                    `SOBELNMS: status_w = S_SOBEL;
                endcase
            end
            else begin
                status_w = S_WAIT_OP;
            end
        end
        S_LOAD:           status_w = (i_sram_inst_ready) ? S_LOAD_COMP : S_LOAD;
        S_LOAD_COMP:      status_w = S_WAIT_OP;
        S_DISP:           status_w = (i_sram_inst_ready) ? S_DISP_COMP : S_DISP;
        S_DISP_COMP:      status_w = S_WAIT_OP;
        S_MV_DISP_REGION: status_w = S_MV_COMP;
        S_MV_COMP:        status_w = S_WAIT_OP;
        S_CONV:           status_w = (i_eng_done_r && (!i_seq_out_valid)) ? S_CONV_COMP : S_CONV;
        S_CONV_COMP:      status_w = S_WAIT_OP;
        S_MEDIAN:         status_w = (i_eng_done_r && (!i_seq_out_valid)) ? S_MEDIAN_COMP : S_MEDIAN;
        S_MEDIAN_COMP:    status_w = S_WAIT_OP;
        S_SOBEL:          status_w = (i_eng_done_r && (!i_seq_out_valid)) ? S_SOBEL_COMP : S_SOBEL;
        S_SOBEL_COMP:     status_w = S_WAIT_OP;
    endcase
end

// OL
always@(*) begin
    o_op_ready_w           = 1'b0;
    o_in_ready_w           = 1'b0;

    o_out_valid_w          = 1'b0;
    o_out_data_w           = 14'd0;

    o_sobel_rst_eng_w      = 1'b0;
    o_sobel_set_eng_w      = 1'b0;
    o_sobel_in_valid_w     = 1'b0;

    o_conv_rst_eng_w       = 1'b0;
    o_conv_set_eng_w       = 1'b0;
    o_conv_in_valid_w      = 1'b0;

    o_median_rst_eng_w     = 1'b0;
    o_median_set_eng_w     = 1'b0;
    o_median_in_valid_w    = 1'b0;

    o_tensor_in_valid_w    = 1'b0;
    o_tensor_op_w          = 3'b000;

    o_sram_mode_w          = 3'b000;
    o_sram_inst_valid_w    = 1'b0; 
    
    o_sram_in_data_valid_w = 1'b0;

    o_rst_seq_out_w        = 1'b0;
    o_rst_eng_done_r_w     = 1'b0;
    o_sel_valid_w          = 1'b0;
    o_sel_eng_w            = 2'b00;

    case(status_r)
        // S_RESET : make all output to be 0
        S_IDLE: begin
            o_op_ready_w = 1'b1;
        end    
        S_WAIT_OP: begin
            if(i_op_valid) begin
                case(i_op_mode)
                    `LOAD_IF: begin
                        o_sram_inst_valid_w = 1'b1;
                        o_sram_mode_w       = `LOAD_MODE;
                    end
                    `ORI_RS: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `MV_RIGHT;
                    end
                    `ORI_LS: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `MV_LEFT;
                    end
                    `ORI_US: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `MV_UP;
                    end
                    `ORI_DS: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `MV_DOWN;
                    end
                    `RDU_CH: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `REDUCE_CH;
                    end
                    `INC_CH: begin
                        o_tensor_in_valid_w = 1'b1;
                        o_tensor_op_w       = `INCRE_CH;
                    end
                    `OUTPUT: begin
                        o_sram_inst_valid_w = 1'b1;
                        o_sram_mode_w       = `DISP_MODE;
                    end
                    `CONV: begin
                        o_conv_set_eng_w    = 1'b1;
                        o_sram_inst_valid_w = 1'b1;
                        o_sram_mode_w       = `CONV_MODE;
                        o_sel_valid_w       = 1'b1;
                        o_sel_eng_w         = `SEQ_CONV;
                    end
                    `MED_FLT: begin
                        o_median_set_eng_w  = 1'b1;
                        o_sram_inst_valid_w = 1'b1;
                        o_sram_mode_w       = `MEDIAN_MODE;
                        o_sel_valid_w       = 1'b1;
                        o_sel_eng_w         = `SEQ_MEDIAN;
                    end
                    `SOBELNMS: begin
                        o_sobel_set_eng_w   = 1'b1;
                        o_sram_inst_valid_w = 1'b1;
                        o_sram_mode_w       = `SOBEL_MODE;
                        o_sel_valid_w       = 1'b1;
                        o_sel_eng_w         = `SEQ_SOBEL;
                    end
                endcase
            end
        end
        S_LOAD: begin
            if(!i_sram_inst_ready) begin
                o_sram_in_data_valid_w = i_in_valid;
                o_in_ready_w           = i_sram_in_data_ready;
            end
        end
        S_LOAD_COMP: begin
            o_op_ready_w = 1'b1;
        end
        S_DISP: begin
            if(!i_sram_inst_ready) begin
                o_out_data_w  = {6'b00_0000, i_sram_disp_data};
                o_out_valid_w = i_sram_disp_valid;
            end
        end
        S_DISP_COMP: begin
            o_op_ready_w = 1'b1;
        end     
        // S_MV_DISP_REGION : output set to 0
        S_MV_COMP: begin
            o_op_ready_w = 1'b1;
        end
        S_CONV: begin
            if(i_eng_done_r && (!i_seq_out_valid)) begin
                o_conv_rst_eng_w   = 1'b1;
                o_rst_eng_done_r_w = 1'b1;
                o_rst_seq_out_w = 1'b1;
            end
            else begin
                o_conv_in_valid_w = i_sram_out_data_valid;
                o_out_valid_w     = i_seq_out_valid;
                o_out_data_w      = i_seq_out_data;
            end
        end
        S_CONV_COMP: begin
            o_op_ready_w = 1'b1;
        end
        S_MEDIAN: begin
            if(i_eng_done_r && (!i_seq_out_valid)) begin
                o_median_rst_eng_w = 1'b1;
                o_rst_eng_done_r_w = 1'b1;
                o_rst_seq_out_w    = 1'b1;
            end
            else begin
                o_median_in_valid_w = i_sram_out_data_valid;
                o_out_valid_w       = i_seq_out_valid;
                o_out_data_w        = i_seq_out_data;
            end
        end
        S_MEDIAN_COMP: begin
            o_op_ready_w = 1'b1;
        end
        S_SOBEL: begin
            if(i_eng_done_r && (!i_seq_out_valid)) begin
                o_sobel_rst_eng_w  = 1'b1;
                o_rst_eng_done_r_w = 1'b1;
                o_rst_seq_out_w    = 1'b1;
            end
            else begin
                o_sobel_in_valid_w = i_sram_out_data_valid;
                o_out_valid_w      = i_seq_out_valid;
                o_out_data_w       = i_seq_out_data;
            end
        end
        S_SOBEL_COMP: begin
            o_op_ready_w = 1'b1;
        end
    endcase
end

assign o_op_ready           = o_op_ready_w;
assign o_in_ready           = o_in_ready_w;
assign o_out_valid          = o_out_valid_w;
assign o_out_data           = o_out_data_w;
assign o_sobel_rst_eng      = o_sobel_rst_eng_w;
assign o_sobel_set_eng      = o_sobel_set_eng_w;
assign o_sobel_in_valid     = o_sobel_in_valid_w;
assign o_conv_rst_eng       = o_conv_rst_eng_w;
assign o_conv_set_eng       = o_conv_set_eng_w;
assign o_conv_in_valid      = o_conv_in_valid_w;
assign o_median_rst_eng     = o_median_rst_eng_w;
assign o_median_set_eng     = o_median_set_eng_w;
assign o_median_in_valid    = o_median_in_valid_w;
assign o_tensor_in_valid    = o_tensor_in_valid_w;
assign o_tensor_op          = o_tensor_op_w;
assign o_sram_mode          = o_sram_mode_w;
assign o_sram_inst_valid    = o_sram_inst_valid_w;
assign o_sram_in_data_valid = o_sram_in_data_valid_w;
assign o_rst_seq_out        = o_rst_seq_out_w;
assign o_rst_eng_done_r     = o_rst_eng_done_r_w;
assign o_sel_valid          = o_sel_valid_w;
assign o_sel_eng            = o_sel_eng_w;


endmodule