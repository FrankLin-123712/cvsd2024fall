`timescale 1ns/1ps
`include "Reducer.v"

`define CYCLE       6.0     // CLK period.
`define MAX_CYCLE   10000

module ModularInversion_tb();

    // Parameters
    parameter Q = 255'h7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFED; // q = 2^255 - 19

    // Inputs
    reg [254:0] i_a,i_b,i_c;         // 輸入值 b
    reg i_valid;             // 啟用信號
    reg clk,i_ptadd_valid,i_dataout_ready;                 // 時鐘信號
    reg rst;                 // 重置信號
    wire o_dataout_valid; 
    // Outputs
    wire [254:0] o_r,o_dataout_xg,o_dataout_yg;        // 輸出結果 r
    wire o_valid;            // 輸出有效信號
    // Write out waveform file
    initial begin
      $fsdbDumpfile("modinv.fsdb");
      $fsdbDumpvars(0, "+mda");
    end
    // Instantiate the ModularInversion module
Reducer Reducer( 
    clk,
    rst,
    i_ptadd_valid,
    i_a,
    i_b,
    i_c,
    o_ptadd_ready,
    i_dataout_ready,
    o_dataout_xg,
    o_dataout_valid
);
// module Reducer(
//     input i_clk,
//     input i_rst,
//     // --- PointAdder ---
//     input i_ptadd_valid,
//     input [254:0] i_ptadd_xmp,
//     input [254:0] i_ptadd_ymp,
//     input [254:0] i_ptadd_zmp,
//     output o_ptadd_ready,
//     // --- DataOut ---
//     input i_dataout_ready,
//     output [254:0] o_dataout_xg,
//     output [254:0] o_dataout_yg,
//     output o_dataout_valid
// );

    task terminate; begin
        $finish;
    end 
    endtask
    // Reset generation
    initial begin

       # (         `MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        terminate;
    end
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10 ns 時鐘週期
    end

    // Testbench logic
    initial begin
        // Initialize inputs
        rst = 1;
        i_dataout_ready=0;
        i_ptadd_valid = 0;
        i_a=255'd0;
        i_b=255'd0;
        i_c=255'd0;
        // Apply reset
        #10;
        rst = 0;

        // Test case 1
        #10;
        i_a=255'h2f8a66a8da71da5f8c006b1aa2fd5320e6dab0b39ff360b34fe0392898690125;
        i_b=255'h45a22939c0fc3f79f416185ad1e5404ad7266f50b66617b28733045dbbf700a2;
        i_c=255'h52310c49eea9ed11b646027438b6ae9e7e7885841a35ed71e541e372bdd37189; 
        i_dataout_ready=1;
        i_ptadd_valid=1;



        // 等待運算完成
        wait(o_dataout_valid);
        #1
        $display("Test case 1:");
        $display("Input a:  %h", i_a);
        $display("Input b:  %h", i_b);
        $display("Input c:  %h", i_c);

        $display("my       x: %h", o_dataout_xg);
        $display("Expected x: 0x0fa4d2a95dafe3275eaf3ba907dbb1da819aba3927450d7399a270ce660d2fae");
        #15
        $display("my       y: %h", o_dataout_xg);
        $display("Expected y: 0x2f0fe2678dedf6671e055f1a557233b324f44fb8be4afe607e5541eb11b0bea2");
        i_ptadd_valid=0;

        // Test case 2

        #20;
        i_a=255'h7074238c34bf23a70a4eb431e085dd6e83f54385c101e15b04a02078e25e169c;
        i_b=255'h573b99fd279b58c07c642837f47d5ffe2e94f81a92d111af2f134f44a1d24d1c;
        i_c=255'h3966bdd9ab22ad41aa04ada33003ad2511a5920b3e9c6f395f952374ca68549e; 
        i_dataout_ready=1;
        i_ptadd_valid=1;

        //等待運算完成
        wait(o_dataout_valid);
        #1

        $display("Test case 2:");
        $display("Input a:  %h", i_a);
        $display("Input b:  %h", i_b);
        $display("Input c:  %h", i_c);

        $display("my       x: %h", o_dataout_xg);
        $display("Expected x: %h",255'h2e2c9fbf00b87ab7cde15119d1c5b09aa9743b5c6fb96ec59dbf2f30209b133c);
        #15

        $display("my       y: %h", o_dataout_xg);
        $display("Expected y: %h",255'h116943db82ba4a31f240994b14a091fb55cc6edd19658a06d5f4c5805730c232);
        i_ptadd_valid=0;


        // #20;
        // i_a=255'd44873298311524575324566159965450165653038269314647444355672739890465219754518;
        // i_b=255'd24449367738082702130814043811174634991362570104618139254148826692766934492785;
        // i_c=255'd54434023785281952637929364378794824238165920007345577063601644873509633916448; 
        // i_dataout_ready=1;
        // i_ptadd_valid=1;

        // // 等待運算完成
        // wait(o_dataout_valid);
        // #1

        // $display("Test case 3:");
        // $display("Input a:  %d", i_a);
        // $display("Input b:  %d", i_b);
        // $display("Input b:  %d", i_c);

        // $display("my       x: %d", o_dataout_xg);
        // $display("Expected x: 46387676971434704141330038257840750783462085422367757602802696758255145043974");
        // $display("my       y: %d", o_dataout_yg);
        // $display("Expected y: 19791577449530997332347783501460479847041625921011949123245807872029423857352");
        // i_ptadd_valid=0;

        // #20;







        // 結束模擬
        #20;
        $finish;
    end

endmodule
