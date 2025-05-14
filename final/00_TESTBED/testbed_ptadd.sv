`timescale 1ns/10ps

`define PERIOD 10.0
`define MAX_CYCLE 1000000
`define I_DELAY 1.0
`define O_DELAY 1.0

`include "../00_TESTBED/pattern/tb_dat_ptadd.sv"
module testbed_ptadd #(
    parameter DATA_W = 64,
    parameter PATN_W = 256,
    parameter IO_CYCLE = PATN_W/DATA_W
) ();

// ports
reg clk, rst;

reg in_valid;
wire in_ready;
reg [DATA_W-1:0] in_data;

wire reduce_valid;
reg reduce_ready;
wire [PATN_W-1:0] reduce_xmp, reduce_ymp, reduce_zmp;

// testbench variables
reg [PATN_W*3-1:0] output_data;

integer input_end, output_end;
integer i;

integer correct, error;

`ifdef PAT0
    import dat_0::*;
`elsif PAT1
    import dat_1::*;
`elsif PAT2
    import dat_2::*;
`else 
    import dat_0::*;
`endif

// cycle count
reg [31:0] cycle_count;

// clock 
initial clk = 1'b0;
always #(`PERIOD/2.0) clk = ~clk;

// reset 
initial begin
    rst = 1'b0; #(0.25*`PERIOD);
    rst = 1'b1; #((2.0-0.25)*`PERIOD);
    rst = 1'b0; #(`MAX_CYCLE*`PERIOD);
    $display("--------------------------");
    $display("ERROR ! Runtime exceeded !");
    $display("--------------------------");
    $finish;
end

// generate waveform (fsdb file)
initial begin
    $fsdbDumpfile("point_adder.fsdb");
    $fsdbDumpvars(0, testbed_ptadd, "+mda");
end

// DUT : point adder
PointAdder ptadd(
    .i_clk(clk),
    .i_rst(rst),

    .i_in_valid(in_valid),
    .o_in_ready(in_ready),
    .i_in_data(in_data),
    
    .o_reduce_valid(reduce_valid),
    .i_reduce_ready(reduce_ready),
    .o_reduce_xmp(reduce_xmp),
    .o_reduce_ymp(reduce_ymp),
    .o_reduce_zmp(reduce_zmp)
);

// input handshaking
initial begin
    in_valid = 1'b0;

    // reset
    wait(rst === 1'b1);
    wait(rst === 1'b0);

    while(!input_end) begin
        @(posedge clk); #(`I_DELAY);
        in_valid = 1'b1;
    end

    in_valid = 1'b0;
end

// output handshaking
initial begin
    reduce_ready = 1'b0;

    // reset
    wait(rst === 1'b1);
    wait(rst === 1'b0);

    while(!output_end) begin
        @(posedge clk); 
        #(`O_DELAY);
        reduce_ready = 1'b1;
    end

    reduce_ready = 1'b0;
end

// input data
initial begin
    input_end = 0;
    in_data   = 64'b0;
    
    // reset
    wait(rst === 1'b1);
    wait(rst === 1'b0);
    
    // send input data
    for(i=3*IO_CYCLE-1; i>=0; i=i-1) begin
        in_data = input_data[DATA_W*i +: DATA_W];

        @(posedge clk);
        while(!(in_valid && (in_ready === 1'b1))) begin
            @(posedge clk);
        end
        #(`I_DELAY);
    end
        
    // set the end flag
    input_end = 1;
    in_data   = 64'bx;
    $display("==> Send Input Done...");
    $display("==> Waiting Calculation...");

end

// Output
initial begin
    output_end = 0;
    
    // wait for handshaking 
    @(posedge clk);
    while(!((reduce_valid === 1'b1) && reduce_ready)) begin
        @(posedge clk);
    end

    output_end = 1;
    $display("==> Receive Output Done...");
end

// output data
initial begin
    // reset
    wait(rst === 1'b1);
    wait(rst === 1'b0);

    // wait for handshaking 
    @(posedge clk);
    while(!((reduce_valid === 1'b1) && reduce_ready)) begin
        @(posedge clk);
    end

    output_data[PATN_W*3-1 -: 256] = reduce_xmp;
    output_data[PATN_W*2-1 -: 256] = reduce_ymp;
    output_data[PATN_W-1   -: 256] = reduce_zmp;

end

// count calculation time
initial begin
    cycle_count = 0;
    wait(rst === 1'b1);
    wait(rst === 1'b0);

    while(1) begin
        @(posedge clk);
        cycle_count = cycle_count + 1;
    end
end

// Result
initial begin
    wait (input_end && output_end);

    $display("**********************************************");
    if (output_data === golden_data) begin
        $display("---------------------------------------");
        $display("                 PASS!                 ");
        $display("---------------------------------------");
    end
    else begin
        $display("---------------------------------------");
        $display("                 FAIL!                 ");
        $display("---------------------------------------");
        $display(
            "Scalar:  %h, \nInput:  (%h, %h), \nGolden: (%h, %h, %h), \nYours:  (%h, %h, %h)",
            input_data[2*PATN_W +: PATN_W],
            input_data[  PATN_W +: PATN_W],
            input_data[       0 +: PATN_W],
            golden_data[2*PATN_W +: PATN_W],
            golden_data[  PATN_W +: PATN_W],
            golden_data[       0 +: PATN_W],
            output_data[2*PATN_W +: PATN_W],
            output_data[  PATN_W +: PATN_W],
            output_data[       0 +: PATN_W]
        );
    end
    $display("----------------------------------------------");
    $display("Simulation Cycle: %6d, Time: %11.2f ns", cycle_count, `PERIOD*(cycle_count));
    $display("**********************************************");

    # (2 * `PERIOD);
    $finish;
end

endmodule