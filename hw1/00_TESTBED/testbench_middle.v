/********************************************************************
* Filename: testbench.v
* Authors:
*     Yi-Fan Shyu
* Description:
*     testbench for hw1 of CVSD 2024 Fall
* Parameters:
*
* Note:
*
* Review History:
*     2024.09.08             Yi-Fan Shyu
*********************************************************************/

`timescale 1ns/10ps
`define PERIOD    10.0
`define MAX_CYCLE 500000
`define RST_DELAY 2.0
`define PAT_LEN 10000
`define SEQ_LEN 50000

`ifdef IMIX
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_MIX_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_MIX_O.dat"
`elsif I0
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_0_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_0_O.dat"
`elsif I1
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_1_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_1_O.dat"
`elsif I2
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_2_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_2_O.dat"
`elsif I3
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_3_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_3_O.dat"
`elsif I4
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_4_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_4_O.dat"
`elsif I5
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_5_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_5_O.dat"
`elsif I6
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_6_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_6_O.dat"
`elsif I7
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_7_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_7_O.dat"
`elsif I8
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_8_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_8_O.dat"
`elsif I9
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_9_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_9_O.dat"
`else
    `define IDATA  "../00_TESTBED/my_pattern/INST_10K_MIX_I.dat"
    `define ODATA  "../00_TESTBED/my_pattern/INST_10K_MIX_O.dat"
`endif


module testbench #(
    parameter INST_W = 4,
    parameter INT_W  = 6,
    parameter FRAC_W = 10,
    parameter DATA_W = INT_W + FRAC_W
) ();

    // Ports
    wire              clk;
    wire              rst_n;
    reg               in_valid;
    reg  [INST_W-1:0] inst;
    reg  [DATA_W-1:0] idata_a;
    reg  [DATA_W-1:0] idata_b;

    wire              busy;
    wire              out_valid;
    wire [DATA_W-1:0] odata;

    // TB variables
    reg                        valid_seq   [0:`SEQ_LEN-1];
    reg  [INST_W+2*DATA_W-1:0] input_data  [0:`PAT_LEN-1];
    reg  [         DATA_W-1:0] golden_data [0:`PAT_LEN-1];

    integer input_end, output_end, test_end;
    integer i, j, k;
    integer correct, error;

    initial begin
        $readmemb("../00_TESTBED/my_pattern/VALID_10K.dat", valid_seq);
        $readmemb(`IDATA, input_data);
        $readmemb(`ODATA, golden_data);
    end

    clk_gen u_clk_gen (
        .clk   (clk  ),
        .rst   (     ),
        .rst_n (rst_n)
    );

    alu u_alu (
        .i_clk       (clk      ),
        .i_rst_n     (rst_n    ),
        .i_in_valid  (in_valid ),
        .o_busy      (busy     ),
        .i_inst      (inst     ),
        .i_data_a    (idata_a  ),
        .i_data_b    (idata_b  ),
        .o_out_valid (out_valid),
        .o_data      (odata    )
    );

    initial begin
       $fsdbDumpfile("alu.fsdb");
       $fsdbDumpvars(0, testbench, "+mda");
    end

    // Input
    initial begin
        input_end = 0;

        // reset
        wait (rst_n === 1'b0);
        in_valid =  1'b0;
        inst     =  4'b0;
        idata_a  = 16'b0;
        idata_b  = 16'b0;
        wait (rst_n === 1'b1);

        // start
        @(posedge clk);

        // loop
        i = 0; j = 0;
        while (i < `SEQ_LEN && j < `PAT_LEN) begin
            @(negedge clk);
            if (valid_seq[i]) begin
                if (!busy) begin
                    in_valid = 1'b1;
                    inst     = input_data[j][2*DATA_W +: INST_W];
                    idata_a  = input_data[j][  DATA_W +: DATA_W];
                    idata_b  = input_data[j][       0 +: DATA_W];
                    j = j+1;

                    i = i+1;
                end
                else begin
                    in_valid =  1'b0;
                    inst     =  4'bx;
                    idata_a  = 16'bx;
                    idata_b  = 16'bx;
                end
            end
            else begin
                in_valid =  1'b0;
                inst     =  4'bx;
                idata_a  = 16'bx;
                idata_b  = 16'bx;

                i = i+1;
            end
            @(posedge clk);
        end

        // final
        @(negedge clk);
        in_valid =  1'b0;
        inst     =  4'b0;
        idata_a  = 16'b0;
        idata_b  = 16'b0;

        input_end = 1;
    end

    // Output
    initial begin
        correct = 0;
        error   = 0;
        output_end = 0;

        // reset
        wait (rst_n === 1'b0);
        wait (rst_n === 1'b1);

        // start
        @(posedge clk);

        // loop
        k = 0;
        while (k < `PAT_LEN) begin
            @(negedge clk);
            if (out_valid) begin
                if (odata === golden_data[k]) begin
                    correct = correct + 1;
                end
                else begin
                    error = error + 1;
                    $display(
                        "Test[%d]: Error! Inst=%b, A=%b, B=%b, Golden=%b, Yours=%b",
                        k,
                        input_data[k][2*DATA_W +: INST_W],
                        input_data[k][  DATA_W +: DATA_W],
                        input_data[k][       0 +: DATA_W],
                        golden_data[k],
                        odata
                    );
                end
                k = k+1;
            end
            @(posedge clk);
        end

        // final
        output_end = 1;
    end

    // Result
    initial begin
        wait (input_end && output_end);

        if (error === 0 && correct === `PAT_LEN) begin
            $display("----------------------------------------------");
            $display("-                 ALL PASS!                  -");
            $display("----------------------------------------------");
        end
        else begin
            $display("----------------------------------------------");
            $display("  Wrong! Total Error: %d                      ", error);
            $display("----------------------------------------------");
        end

        # (2 * `PERIOD);
        $finish;
    end

endmodule


module clk_gen (
    output reg clk,
    output reg rst,
    output reg rst_n
);

    always #(`PERIOD / 2.0) clk = ~clk;

    initial begin
        clk = 1'b0;
        rst = 1'b0; rst_n = 1'b1; #(              0.25  * `PERIOD);
        rst = 1'b1; rst_n = 1'b0; #((`RST_DELAY - 0.25) * `PERIOD);
        rst = 1'b0; rst_n = 1'b1; #(         `MAX_CYCLE * `PERIOD);
        $display("Error! Runtime exceeded!");
        $finish;
    end

endmodule
