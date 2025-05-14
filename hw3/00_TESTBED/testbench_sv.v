`timescale 1ns/1ps
`define HCYCLE      (`CYCLE/2)

`define TA_PAT_NUM 5
`define HIDDEN_PAT_NUM 11

`ifdef ALL
  `define MAX_CYCLE 20000 * `TA_PAT_NUM
  `define MULTI_PATTERN
`elsif Hidden
  `define MAX_CYCLE 20000 * `HIDDEN_PAT_NUM
  `define MULTI_PATTERN
`else
  `define MAX_CYCLE 20000
`endif

`define RST_DELAY 2

// Modify your sdf file name
`define SDFFILE "../02_SYN/Netlist/core_syn.sdf"

`define TEST_VALID

module testbed;

logic                        clk;
logic                      rst_n;
logic                   op_valid;
logic [ 3:0]             op_mode;
logic                   op_ready;
logic                   in_valid;
logic [ 7:0]             in_data;
logic                   in_ready;
logic                  out_valid;
logic [13:0]            out_data;

logic [ 7:0] indata_mem [0:2047];
logic [ 3:0] opmode_mem [0:1023];
logic [13:0] golden_mem [0:8000];

integer    dataIdx;
integer   errorNum;
integer  goldenIdx;
integer      opIdx;
integer totalCycle;
string sTmp;

integer golden_len [16] = {1984, 80, 320, 320, 708, 
                          49*32*4, 49*16*4, 49*8*4,
                          49*4, 48*4, 49*4, 49*4,
                          49*16,
                          49*16,
                          2864, 3652
                        };

// ==============================================
// TODO: Declare regs and wires you need
// ==============================================


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

`ifdef ALL
  `define times `TA_PAT_NUM
  `define startIdx 0

`elsif Hidden
  `define times `HIDDEN_PAT_NUM
  `define startIdx 5

`else
  `define times 1
  `define startIdx 0
	string pattern_num;
  string pattern_int;
  integer idxTmp;
  string stringTmp;
  initial begin
    $value$plusargs("pattern_num=%s", pattern_num);
    pattern_int = pattern_num.substr(2, 3);
    if(pattern_int.atoi() >= 10)idxTmp = pattern_int.atoi();
    else idxTmp = pattern_num[2] - "0";
    stringTmp.itoa(idxTmp);
    $readmemb({"../00_TESTBED/PATTERN_sv/indata", stringTmp, ".dat"}, indata_mem);
    $readmemb({"../00_TESTBED/PATTERN_sv/opmode", stringTmp, ".dat"}, opmode_mem);
    $readmemb({"../00_TESTBED/PATTERN_sv/golden", stringTmp, ".dat"}, golden_mem);
  end
`endif

core u_core (
	.i_clk       (      clk),
	.i_rst_n     (    rst_n),
	.i_op_valid  ( op_valid),
	.i_op_mode   (  op_mode),
  .o_op_ready  ( op_ready),
	.i_in_valid  ( in_valid),
	.i_in_data   (  in_data),
	.o_in_ready  ( in_ready),
	.o_out_valid (out_valid),
	.o_out_data  ( out_data)
);


// Clock generation
initial clk = 1'b0;
always begin #(`CYCLE/2) clk = ~clk; end

initial begin
  $display("********************************");
  `ifdef SDF
  $display("**   Simulation Start (SYN)   **");
  `else
  $display("**   Simulation Start (RTL)   **");
  `endif
  $display("********************************\n");
end 

// Runtime limit
initial begin
    # (`MAX_CYCLE * `CYCLE);
    $write("%c[1;34m",27);
    $display("Error! Runtime exceeded!");
		$write("%c[0m",27);
    $finish;
end

// !!!! check spec rule
always@(negedge clk)begin
  if(in_valid === 1 && out_valid === 1)begin
    $write("%c[1;31m",27);
    $display("Violate rule No.1, i_in_valid and o_out_valid can't be high in the same time");
    $write("%c[0m",27);
    #(`HCYCLE)$finish;
  end
  else if(op_valid === 1 && out_valid === 1)begin
    $write("%c[1;31m",27);
    $display("Violate rule No.2, i_op_valid and o_out_valid can't be high in the same time");
    $write("%c[0m",27);
    #(`HCYCLE)$finish;
  end
  else if(in_valid === 1 && op_ready === 1)begin
    $write("%c[1;31m",27);
    $display("Violate rule No.3, i_in_valid and o_op_ready can't be high in the same time");
    $write("%c[0m",27);
    #(`HCYCLE)$finish;
  end
  else if(op_valid === 1 && op_ready === 1)begin
    $write("%c[1;31m",27);
    $display("Violate rule No.4, i_op_valid and o_op_ready can't be high in the same time");
    $write("%c[0m",27);
    #(`HCYCLE)$finish;
  end
  else if(op_ready === 1 && out_valid === 1)begin
    $write("%c[1;31m",27);
    $display("Violate rule No.5, o_op_ready and o_out_valid can't be high in the same time");
    $write("%c[0m",27);
    #(`HCYCLE)$finish;
  end
end


always begin

  @(negedge clk);

  if(op_ready === 1)begin
    
    `ifdef TEST_VALID
      repeat({$random}%10 + 1)@(negedge clk);
    `else
      @(negedge clk);
    `endif

    if(opmode_mem[opIdx] !== 4'dx)op_mode = opmode_mem[opIdx];
    else op_mode = 4'd0;

    if(opmode_mem[opIdx] !== 4'dx)op_valid = 1;
    else op_valid = 0;

    @(negedge clk);
    op_mode = 4'd0;
    op_valid = 0;
    // if opmode == Load ifmap
    if(opmode_mem[opIdx] === 4'd0)begin
      while(dataIdx < 2048)begin
        
        if(in_ready)begin
          in_valid = 1;
          in_data = indata_mem[dataIdx];
        end
        else begin//stall
          in_valid = 1;
        end
        
        `ifdef TEST_VALID
          if (dataIdx == 2047)begin
            @(negedge clk);
          end
          else begin
            repeat({$random}%5 + 1)@(negedge clk)begin
              in_valid = 0;
              in_data = 'dz;
            end
          end
        `else
          @(negedge clk);
        `endif
        
        dataIdx = dataIdx + 1;
      end
      in_valid = 0;
      in_data = 0;
      opIdx = opIdx+ 1;
    end
    else begin
      op_mode = 4'd0;
      op_valid = 0;
      opIdx = opIdx+ 1;
    end
  end
end


initial begin
  opIdx    = 0;
  errorNum = 0;
  dataIdx  = 0;
  goldenIdx= 0;
  op_valid = 0;
  op_mode  = 4'd0;
  in_valid = 1'b0;
  in_data  = 8'd0;
end


integer pat_idx;

initial begin
  
  for(pat_idx=(0+`startIdx) ; pat_idx<(`times+`startIdx) ; pat_idx++)begin
    opIdx    = 0;
    errorNum = 0;
    dataIdx  = 0;
    goldenIdx= 0;
    op_valid = 0;
    op_mode  = 4'd0;
    in_valid = 1'b0;
    in_data  = 8'd0;

		`ifdef MULTI_PATTERN
      sTmp.itoa(pat_idx);
      $readmemb({"../00_TESTBED/PATTERN_sv/indata", sTmp, ".dat"}, indata_mem);
      $readmemb({"../00_TESTBED/PATTERN_sv/opmode", sTmp, ".dat"}, opmode_mem);
      $readmemb({"../00_TESTBED/PATTERN_sv/golden", sTmp, ".dat"}, golden_mem);
    `endif
    
    release clk;
    resetTask();

    while(1)begin
      @(negedge clk);
      if(out_valid === 1)begin
        if(out_data !== golden_mem[goldenIdx] && golden_mem[goldenIdx] !== 14'dx)begin
          $write("%c[1;31m",27);
          $display("golden_mem[%0d]: Error! Golden = %d ,Yours = %d", goldenIdx, golden_mem[goldenIdx], out_data);
          $write("%c[0m",27);
          errorNum = errorNum + 1;
          #(`CYCLE * 20);
          $finish;
        end
        
        goldenIdx = goldenIdx + 1;

        `ifdef MULTI_PATTERN
				  if(goldenIdx === golden_len[pat_idx])break;
        `else
          if(goldenIdx === golden_len[idxTmp])break;
        `endif
      end
    end
    resultTask(errorNum);
    force clk = 0;
    
  end
  $finish;

end

always@(posedge clk or negedge rst_n)begin
  if(!rst_n)totalCycle <= 0;
  else      totalCycle <= totalCycle + 1;
end


// reset task
task resetTask;
begin
  rst_n = 1; # (0.25 * `CYCLE);
  $write("%c[1;34m",27);
  $display("  Reset Start  ");
	$write("%c[0m",27);
  rst_n = 0; # ((`RST_DELAY - 0.25) * `CYCLE);
  rst_n = 1;
  $write("%c[1;34m",27);
  $display("  Reset Finish  ");
	$write("%c[0m",27);
end
endtask

// << resultTask  >>
task resultTask;
input integer error;
begin
	if(error === 0) begin
			$write("%c[1;32m",27);
			$display("");
			`ifdef MULTI_PATTERN
				$display("	Pattern : tb%0s ", sTmp);
			`else
				$display("	Pattern : %3s ", pattern_num);
			`endif
			$display("	******************************               ");
			$display("	**                          **       |\__||  ");
			$display("	**    Congratulations !!    **      / O.O  | ");
			$display("	**                          **    /_____   | ");
			$display("	**    Simulation PASS!!     **   /^ ^ ^ \\  |");
			$display("	**                          **  |^ ^ ^ ^ |w| ");
			$display("	******************************   \\m___m__|_|");
      `ifdef MULTI_PATTERN
			$display("	Correct / ALL = %0d / %0d                    ", goldenIdx, golden_len[pat_idx]);
      `else
      $display("	Correct / ALL = %0d / %0d                    ", goldenIdx, golden_len[idxTmp]);
      `endif
			$display("	Total cycle   = %0d                          ", totalCycle);
      $display("	CLK period    = %.2f ns                      ", `CYCLE);
      $display("	Elapsed time  = %.2f ns                    \n", totalCycle* `CYCLE);
			$write("%c[0m",27);
	end
	else begin
			$write("%c[1;31m",27);
			$display("");
			`ifdef MULTI_PATTERN
				$display("	Pattern : tb%0s ", sTmp);
			`else
				$display("	Pattern : %3s ", pattern_num);
			`endif
			$display("	******************************               ");
			$display("	**                          **       |\__||  ");
			$display("	**    OOPS!!                **      / X,X  | ");
			$display("	**                          **    /_____   | ");
			$display("	**    Simulation Failed!!   **   /^ ^ ^ \\  |");
			$display("	**                          **  |^ ^ ^ ^ |w| ");
			$display("	******************************   \\m___m__|_|");
			$display("	Totally has %d errors                      \n", error); 
			$write("%c[0m",27);
	end
end
endtask



endmodule
