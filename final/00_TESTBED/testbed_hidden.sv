/********************************************************************
* Filename: testbed.v
* Authors:
*     Yu-Cheng Lin
* Description:
*     testbench for final project of CVSD 2024 Fall
* Parameters:
*
* Note:
*
* Review History:
*     2024.10.02             Yu-Cheng Lin
*********************************************************************/

`timescale 1ns/10ps
`define PERIOD    10.0
`define MAX_CYCLE 1_000_000
`define RST_CYCLE 5
`define NUM_PATTERNS 100

`define I_DELAY 1
`define O_DELAY 1

`ifdef GATE
    `define SDF
    `define SDF_FILE "../03_GATE/ed25519_syn.sdf" // Modify your sdf file name
`elsif POST
    `define SDF
    `define SDF_FILE "../05_POST/ed25519_pr.sdf"  // Modify your sdf file name
`endif

`include "../00_TESTBED/pattern/tb_dat_hidden.sv"

// TODO: You should make sure your design can correctly handle the random IO handshake
// `define RANDOM_IO_HANDSHAKE

module testbench #(
    parameter DATA_W = 64,
    parameter PATN_W = 256,
    parameter IO_CYCLE = PATN_W/DATA_W
) ();

    import test_patterns_pkg::*;

    // Ports
    wire              clk;
    wire              rst;

    reg               in_valid;
    wire              in_ready;
    reg  [DATA_W-1:0] in_data;

    wire              out_valid;
    reg               out_ready;
    wire [DATA_W-1:0] out_data;

    // TB variables
    reg  [PATN_W*2-1:0] output_data;

    integer pattern_idx;
    integer input_end, output_end;
    integer i, j, k;
    integer correct, error;
    integer total_cycles;

    // Cycle counting
    reg [31:0] cycle_count;   // To count the number of clock cycles

    // Current pattern data
    reg [767:0] current_input;
    reg [511:0] current_golden;

    clk_gen u_clk_gen (
        .clk   (clk  ),
        .rst   (rst  ),
        .rst_n (     )
    );

    ed25519 u_ed25519 (
        .i_clk       (clk      ),
        .i_rst       (rst      ),
        .i_in_valid  (in_valid ),
        .o_in_ready  (in_ready ),
        .i_in_data   (in_data  ),
        .o_out_valid (out_valid),
        .i_out_ready (out_ready),
        .o_out_data  (out_data )
    );

`ifdef SDF
    initial begin
        $sdf_annotate(`SDF_FILE, u_ed25519);
    `ifdef FSDB
        $fsdbDumpfile("ed25519_gate.fsdb");
        $fsdbDumpvars(0, testbench, "+mda");
    `elsif VCD
        $dumpfile("ed25519_gate.vcd");
        $dumpvars();
    `endif
    end
`else
    `ifdef FSDB
    initial begin
        $fsdbDumpfile("ed25519.fsdb");
        $fsdbDumpvars(0, testbench, "+mda");
    end
    `endif
`endif

    task run_single_pattern;
        input integer pat_idx;
        begin
            // Reset signals
            in_valid    = 1'b0;
            out_ready   = 1'b0;

            // initialze variables 
            input_end   = 0;
            output_end  = 0;
            cycle_count = 0;

            // Load pattern data
            current_input = test_patterns[pat_idx].input_data;
            current_golden = test_patterns[pat_idx].golden_data;

            // Start input
            for (i = 3 * IO_CYCLE - 1; i >= 0; i = i - 1) begin
                #(`I_DELAY);
                in_valid = 1'b1;
                in_data = current_input[DATA_W*i +: DATA_W];
                @(posedge clk);
                while (!(in_valid && in_ready)) begin
                    @(posedge clk);
                end
            end
            input_end = 1;
            in_valid  = 1'b0;
            in_data   = 64'bx;

            // Get output
            j = 2 * IO_CYCLE - 1;
            out_ready = 1'b1;
            while (j >= 0) begin
                if (out_valid && out_ready) begin
                    output_data[DATA_W*j +: DATA_W] = out_data;
                    j = j - 1;
                end
                @(posedge clk);
            end

            // Check result
            if (output_data === current_golden) begin
                correct = correct + 1;
            end else begin
                error = error + 1;
                $display("----------------------------------------------");
                $display(
                    "Pattern %0d\nScalar:  %h, \nInput:  (%h, %h), \nGolden: (%h, %h), \nYours:  (%h, %h)",
                    pat_idx,
                    current_input[2*PATN_W +: PATN_W],
                    current_input[  PATN_W +: PATN_W],
                    current_input[       0 +: PATN_W],
                    current_golden[  PATN_W +: PATN_W],
                    current_golden[       0 +: PATN_W],
                    output_data[  PATN_W +: PATN_W],
                    output_data[       0 +: PATN_W]
                );
            end

            output_end = 1;
            total_cycles = total_cycles + cycle_count;
            
            // Wait a few cycles between patterns
            repeat(5) @(posedge clk);
        end
    endtask

    // Main test process
    initial begin
        // Initialize
        pattern_idx = 0;
        correct = 0;
        error = 0;
        total_cycles = 0;

        // Wait for initial reset
        wait (rst === 1'b1);
        wait (rst === 1'b0);

        // Run all patterns
        for (pattern_idx = 0; pattern_idx < NUM_PATTERNS; pattern_idx = pattern_idx + 1) begin
            run_single_pattern(pattern_idx);
        end

        // Final results
        $display("**********************************************");
        $display("                 Test Complete                ");
        $display("----------------------------------------------");
        $display("Total Patterns: %d", NUM_PATTERNS);
        $display("Correct: %d", correct);
        $display("Error: %d", error);
        $display("Total Cycles: %d, Time: %11.2f ns", total_cycles, `PERIOD*total_cycles);
        $display("**********************************************");

        #(2 * `PERIOD);
        $finish;
    end

    // Count cycles for each pattern
    always @(posedge clk) begin
        if (!output_end) cycle_count = cycle_count + 1;
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
        rst = 1'b0; rst_n = 1'b1; 
        @(posedge clk);
        rst = 1'b1; rst_n = 1'b0; 
        #(`RST_CYCLE * `PERIOD);
        rst = 1'b0; rst_n = 1'b1; 
        #(`MAX_CYCLE * `PERIOD);
        $display("----------------------------------------------");
        $display("Error! Runtime exceeded!");
        $display("----------------------------------------------");
        $finish;
    end

endmodule
