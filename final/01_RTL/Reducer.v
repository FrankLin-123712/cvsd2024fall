//`include "utils.v"

module Reducer(
    input i_clk,
    input i_rst,
    // --- PointAdder ---
    input i_ptadd_valid,
    input [254:0] i_ptadd_xmp,
    input [254:0] i_ptadd_ymp,
    input [254:0] i_ptadd_zmp,
    output o_ptadd_ready,
    // --- io ---
    input i_out_ready,
    output [63:0] o_out_data,
    output o_out_valid

);
    parameter Q = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED; // q = 2^255 - 19
    parameter Q_MINUS_2 = 255'b111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111111101011; // q-2
    parameter IDLE=2'b00;
    parameter OPERATION=2'b01;
    parameter DONE=2'b10;
    reg o_dataout_valid_r;
    wire [254:0] o_out_data_w;
    reg [7:0] bit_counter;     // 位元計數器
    reg [9:0] counter;
    wire mul_valid1;            // ModMul 輸出有效信號
    wire [7:0] base_addr;
    wire [254:0]r;
    reg mul_start1;             // 啟動模數乘法
    reg [254:0] i_x_mux_out,i_y_mux_out,z_inv;   
    reg  [254:0]b;
    // 實例化模數乘法模塊
    wire [254:0]q_minus_x;
    reg o_ptadd_ready_w;
    reg to_adder_valid;
    reg [254:0]o_out_data_y_reg;
    reg [254:0]o_out_data_y_w;





    ModMul modmul_inst (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_x(i_x_mux_out),               // 輸入值 r
        .i_y(i_y_mux_out),                // 輸入值 r
        .i_valid(mul_start1),   // 啟用信號
        .o_mul(r),    // 輸出模數乘法結果
        .o_valid(mul_valid1)    // 輸出有效信號
    );
    ModAdder adder1(
        .i_x(Q),
        .i_y(r),
        .i_op(mul_valid1),   //0 for +    1 for -
        .i_valid(to_adder_valid),
        .o_add(q_minus_x),
        .o_valid()
    );
    reg [1:0]state,n_state; 
    always@(*)begin
        o_ptadd_ready_w=0;

                
        case  (state)    
            OPERATION: begin

                    if(counter==0)begin
                        o_ptadd_ready_w=1;
                        i_x_mux_out=i_ptadd_zmp;
                        i_y_mux_out=i_ptadd_zmp;
                    end
                    else begin
                        o_ptadd_ready_w=0;
                        i_x_mux_out=(mul_valid1)?r:1;   //fowarding
                        b=(Q_MINUS_2[bit_counter])?i_ptadd_zmp:1;
                        i_y_mux_out=(counter[1:0]==2'b10)?b:(counter[1:0]==2'b00 && counter!=0)?r:1;
                    end
            end
            DONE:begin

                if (counter==10'd1016)begin
                    i_x_mux_out=r;   //z inv
                     o_ptadd_ready_w=1;
                    i_y_mux_out=i_ptadd_xmp;

                
                end
                else begin
                    i_x_mux_out=z_inv;   //z inv
                    i_y_mux_out=i_ptadd_ymp;
                end

                o_ptadd_ready_w=0;
                    if(counter==10'd1021)
                        o_ptadd_ready_w=1;


                


            end
            default:begin
                    i_x_mux_out=0;   //z inv
                    i_y_mux_out=0;
            end

        endcase
    end

    always@(*)begin
        to_adder_valid=0;
        case (state)    
            OPERATION: begin
                if(counter[0]==0)
                    mul_start1=1;
                else 
                    mul_start1=0;
            end
            DONE:begin
                to_adder_valid=1;
                if(counter==10'd1016||counter==10'd1017)
                 mul_start1=1;
                else 
                 mul_start1=0;

            end
            default: mul_start1=0;
        endcase

    end


    always@(*)begin

        case (state)    
            IDLE: begin
                if (i_ptadd_valid) begin
                    n_state = OPERATION;
                end
                else
                    n_state = IDLE;
            end
            OPERATION: begin

                if (bit_counter==0 &&counter==10'd1015) begin
                    n_state = DONE;

                end
                else
                    n_state = OPERATION;
            end
            DONE: begin

                if (counter==8) begin
                    n_state = IDLE;

                end
                else
                    n_state = DONE;
            end
            default:                    n_state = IDLE;

        endcase

    end

    always@(*)begin
        o_out_data_y_w=0;
        case (state)    
            DONE:begin
                o_out_data_y_w=((mul_valid1)&&(r[0]))?q_minus_x:r;

            end
        endcase

    end
    always@(posedge i_clk)begin
        if(i_rst)begin
            o_out_data_y_reg<=0;
        end    
        else if(state==DONE && mul_valid1) begin
            o_out_data_y_reg<=o_out_data_y_w;
        end
    end

    always@(posedge i_clk)begin
        if(i_rst)begin
            z_inv<=0;
        end    
        else if(counter==10'd1016) begin
            z_inv<=r;
        end
        else if(counter==10'd1019) begin
            z_inv<=o_out_data_y_reg; //hardware sharing
        end
    end



    always@(posedge i_clk)begin
        if(i_rst)begin
            state<=IDLE;
        end    
        else begin
            state<=n_state;
        end
    end
    always@(posedge i_clk)begin
        if(i_rst)begin
            bit_counter <= 9'd253;
        end    
        else if(state==OPERATION &&counter[1:0]==2'b11)begin
            bit_counter <= bit_counter-1;

        end
        else if(state==IDLE)begin
            bit_counter <= 9'd253;

        end
    end
    always@(posedge i_clk)begin
        if(i_rst)begin
            counter<=0;
        end    
        else if(state==OPERATION)begin
            counter<=counter+1;
        end

        else if(state==DONE&&counter==10'd1019)begin
            counter<=0;
        end
        else if(state==DONE&&counter[9:3]!=0)begin
            counter<=counter+1;
        end
        else if(state==DONE&&i_out_ready)begin
            counter<=counter+1;
        end


        else if(state==IDLE)begin
            counter<=0;
        end


        
    end


    always@(posedge i_clk)begin
        if(i_rst)
            o_dataout_valid_r<=0;
        else if(state==DONE && mul_valid1 &&counter==10'd1019)
            o_dataout_valid_r<=mul_valid1;
        else if(state==DONE &&counter==8 )
            o_dataout_valid_r<=0;
        else if(state==IDLE)
            o_dataout_valid_r<=0;

    end
    assign o_out_valid= o_dataout_valid_r;
    assign o_ptadd_ready= o_ptadd_ready_w;
    assign base_addr = 8'd255 - {counter, 6'd0};
    assign o_out_data_w=(counter[9:2]==0)?z_inv:(counter[9:2]!=0)?o_out_data_y_reg:0;
    assign o_out_data=(counter==0|| counter==4)?{1'b0,o_out_data_w[(base_addr-1) -: 63]}:o_out_data_w[base_addr -: 64];


endmodule
