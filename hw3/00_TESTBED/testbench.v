`timescale 1ns/1ps
`define CYCLE       5.0     // CLK period.
`define HCYCLE      (`CYCLE/2)
`define MAX_CYCLE   1000000
`define RST_DELAY   2


`ifdef tb1
    `define INFILE "../00_TESTBED/PATTERN/indata1.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode1.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden1.dat"
    `define TEST_OP_NUM 41
`elsif tb2
    `define INFILE "../00_TESTBED/PATTERN/indata2.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode2.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden2.dat"
    `define TEST_OP_NUM 41
`elsif tb3
    `define INFILE "../00_TESTBED/PATTERN/indata3.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode3.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden3.dat"
    `define TEST_OP_NUM 41
`elsif tb4
    `define INFILE "../00_TESTBED/PATTERN/indata4.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode4.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden4.dat"
    `define TEST_OP_NUM 121
`elsif tbh
    `define INFILE "../00_TESTBED/PATTERN/indatah.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmodeh.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/goldenh.dat"
    `define TEST_OP_NUM 501
`else
    `define INFILE "../00_TESTBED/PATTERN/indata0.dat"
    `define OPFILE "../00_TESTBED/PATTERN/opmode0.dat"
    `define GOLDEN "../00_TESTBED/PATTERN/golden0.dat"
    `define TEST_OP_NUM 41
`endif

`define SDFFILE "../02_SYN/Netlist/core_syn.sdf"  // Modify your sdf file name


module testbed;

    parameter INST_BW     = 4;
    parameter INPUT_BW    = 8;
    parameter IMG_W       = 8;
    parameter IMG_MAX_CH  = 32;
    parameter IMG_MIN_CH  = 8;
    parameter IMG_W_BW    = $clog2(IMG_W);
    parameter IMG_CH_BW   = $clog2(IMG_MAX_CH);
    parameter IMG_SIZE    = IMG_W * IMG_W * IMG_MAX_CH;
    parameter DISP_W      = 2;
    parameter DISP_NUM    = DISP_W * DISP_W * IMG_MAX_CH;
    parameter DISP_NUM_BW = $clog2(DISP_NUM);
    parameter OUTPUT_BW   = IMG_CH_BW + INPUT_BW + 1;  // + 1 sign bit

    parameter MEDF_CH = 4;
    parameter GRAD_CH = 4;

	localparam MODE_LOAD = 4'b0000;
	localparam MODE_SHFR = 4'b0001;
	localparam MODE_SHFL = 4'b0010;
	localparam MODE_SHFU = 4'b0011;
	localparam MODE_SHFD = 4'b0100;
	localparam MODE_SCAD = 4'b0101;
	localparam MODE_SCAU = 4'b0110;
	localparam MODE_DISP = 4'b0111;
	localparam MODE_CONV = 4'b1000;
    localparam MODE_MEDF = 4'b1001;
    localparam MODE_GRAD = 4'b1010;
     
    reg                  clk, rst_n;
    reg                  op_valid;
    reg  [  INST_BW-1:0] op_mode;
    wire                 op_ready;
    reg                  in_valid;
    reg  [ INPUT_BW-1:0] in_data;
    wire                 in_ready;
    wire                 out_valid;
    wire [OUTPUT_BW-1:0] out_data;

    integer              i;
    integer              cnt_pixel;
    integer              cnt_out_valid;
    integer              a; //output address
    integer              num_out;
    integer              depth;
    integer              t0, t1;

    reg  [ INPUT_BW-1:0] indata_mem [0:IMG_SIZE-1];
    reg  [  INST_BW-1:0] opmode_mem [      0:1023];
    reg  [OUTPUT_BW-1:0] golden_mem [      0:4095];


    // For gate-level simulation only
    `ifdef SDF
        initial $sdf_annotate(`SDFFILE, u_core);
        initial #1 $display("SDF File %s were used for this simulation.", `SDFFILE);
    `endif

    // Write out waveform file
    initial begin
      $fsdbDumpfile("core.fsdb");
      $fsdbDumpvars(0, "+mda");
    end


    core u_core (
    	.i_clk(clk),
    	.i_rst_n(rst_n),
    	.i_op_valid(op_valid),
    	.i_op_mode(op_mode),
        .o_op_ready(op_ready),
    	.i_in_valid(in_valid),
    	.i_in_data(in_data),
    	.o_in_ready(in_ready),
    	.o_out_valid(out_valid),
    	.o_out_data(out_data)
    );

    // Read in test pattern and golden pattern
    initial $readmemb(`INFILE, indata_mem);
    initial $readmemb(`OPFILE, opmode_mem);
    initial $readmemb(`GOLDEN, golden_mem);

    // Clock generation
    initial clk = 1'b0;
    always begin #(`CYCLE/2) clk = ~clk; end

    // Reset generation
    initial begin
        rst_n = 1; # (               0.25 * `CYCLE);
        rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
        rst_n = 1; # (         `MAX_CYCLE * `CYCLE);
        $display("Error! Runtime exceeded!");
        $finish;
    end

    // ==============================================
    // TODO: Check pattern after process finish
    // ==============================================

    initial begin

        i             = 0;
        a             = 0;
        cnt_pixel     = 0;
        cnt_out_valid = 0;
        num_out       = 0;
        depth         = 32;
        op_valid      = 0;
        op_mode       = 0;
        in_valid      = 0;
        in_data       = 0;
        rst_n         = 1;
        t0            = 0;
        t1            = 0;

        reset;

        @(negedge clk);
        // load image
        while (op_ready == 1'b0) begin
            @(negedge clk);
        end
        @(negedge clk);
        op_valid  =  1'b1;
        op_mode   =  4'b0;

        @(negedge clk);
        if (op_ready) begin
            $display("Error: o_op_ready & i_op_valid overlapped!!");
            // $finish;
        end
        op_valid  = 1'b0;
        in_valid  = 1'b1;
        in_data   = indata_mem[cnt_pixel];

        t0 = $realtime;
        while (cnt_pixel < IMG_SIZE-1) begin
            @(negedge clk);
            if (in_ready == 1'b1) begin
                cnt_pixel = cnt_pixel + 1;
                in_data   = indata_mem[cnt_pixel];
            end
            if (op_ready) begin
                $display("Error: o_op_ready & i_in_valid overlapped!!");
                // $finish;
            end
        end

        while (in_ready == 1'b0) begin
            @(negedge clk);
            if (op_ready) begin
                $display("Error: o_op_ready & i_in_valid overlapped!!");
                // $finish;
            end
        end
        @(negedge clk);
        in_valid  = 1'b0;
        in_data   = 0;

        t1 = $realtime;
        $display("Data loading took %d", t1-t0);
        if (t1 - t0 > 3000 * `CYCLE) begin
            $display("Error: data loading exceeded 3000 cycles!!");
            // $finish;
        end

        for (i = 1; i < `TEST_OP_NUM; i = i + 1) begin
            cnt_out_valid = 0;
            while (op_ready == 1'b0) begin
                @(negedge clk);
            end
            if (out_valid && op_ready) begin
                $display("Error: o_out_valid & o_op_ready overlapped!!");
                // $finish;
            end
            t1 = $realtime;

            @(negedge clk);
            op_valid  =  1'b1;
            op_mode   =  opmode_mem[i];
            if (out_valid) begin
                $display("Error: o_out_valid & i_op_valid overlapped!!");
                // $finish;
            end
            
            // Get the depth of image
            if (opmode_mem[i] == MODE_SCAD) begin
                case (depth)
                    32:      depth = 16;
                    16:      depth = 8;
                    default: depth = depth;
                endcase
            end
            else if (opmode_mem[i] == MODE_SCAU) begin
                case (depth)
                    8:       depth = 16;
                    16:      depth = 32;
                    default: depth = depth;
                endcase
            end
            
            // Get the number of output for the current operation
            if (opmode_mem[i] == MODE_CONV) begin      // convolution
                num_out = DISP_W * DISP_W;
            end
            else if (opmode_mem[i] == MODE_DISP) begin // display
                num_out = DISP_W * DISP_W * depth;
            end
            else if (opmode_mem[i] == MODE_MEDF) begin // median filter
                num_out = DISP_W * DISP_W * MEDF_CH;
            end
            else if (opmode_mem[i] == MODE_GRAD) begin // Sobel gradient + NMS
                num_out = DISP_W * DISP_W * GRAD_CH;
            end
            else begin
                num_out = 0;
            end

            @(negedge clk);
            if (op_ready) begin
                $display("Error: o_op_ready & i_op_valid overlapped!!");
                // $finish;
            end
            op_valid  = 1'b0;
            op_mode   = 0;
            t0        = $realtime;
            if (out_valid == 1'b1) begin
                $display("Error: o_out_valid & i_in_valid overlapped!!");
                // $finish;
            end
            
            $display("Idx[%d] Op: %d, require %d outputs", i, opmode_mem[i], num_out);

            while (cnt_out_valid < num_out) begin
                @(negedge clk);
                if (op_ready) begin
                    $display("Error: You can't raise o_op_ready to high before output %d values", num_out);
                    // $finish;
                end
                if (out_valid) begin
                    if (golden_mem[a] !== out_data) begin
                        $display("Error: golden=[%b], your answer=[%b], T: %d", golden_mem[a], out_data, t0);
                        $finish;
                    end
                    cnt_out_valid = cnt_out_valid + 1;
                    a = a + 1;
                end
            end
        end

        $display("-----PASS!!-----");

        # ( 2 * `CYCLE);
        $finish;

    end

    task reset; begin
        # ( 0.25 * `CYCLE);
        rst_n = 0;    
        # ((`RST_DELAY - 0.25) * `CYCLE);
        rst_n = 1;    
    end endtask

endmodule
