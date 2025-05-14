`timescale 1ns/10ps
`define PERIOD 10.0    // Cycle time
`define MAX_CYCLE 100000000
`define TEST_NUM 1000000

//pre-sim
`include "./fp_adder.v"
`include "./fp_lt.v"
 
`ifdef ADD
	`define A_data_path "./MY_pattern/ADD/A.dat"
	`define B_data_path "./MY_pattern/ADD/B.dat"
	`define OUT_data_path "./MY_pattern/ADD/OUT.dat"
	`define INST 1'b0
`elsif SUB
	`define A_data_path "./MY_pattern/SUB/A.dat"
	`define B_data_path "./MY_pattern/SUB/B.dat"
	`define OUT_data_path "./MY_pattern/SUB/OUT.dat"
	`define INST 1'b1
`elsif CMP
	`define A_data_path "./MY_pattern/CMP/A.dat"
	`define B_data_path "./MY_pattern/CMP/B.dat"
	`define OUT_data_path "./MY_pattern/CMP/OUT.dat"
	`define INST 1'b0 // DONTCARE
`else 
	`define A_data_path "./MY_pattern/ADD/A.dat"
	`define B_data_path "./MY_pattern/ADD/B.dat"
	`define OUT_data_path "./MY_pattern/ADD/OUT.dat"
	`define INST 1'b0
`endif


module test(); 


reg	clk;

reg [31:0]testing_input_A, testing_input_B;
reg testing_input_inst;

wire [31:0]result_wire;
wire less_than_flag_wire;

// TB variables
reg [31:0]A_data[0:`TEST_NUM-1];
reg [31:0]B_data[0:`TEST_NUM-1];
reg [31:0]OUT_data[0:`TEST_NUM-1];



integer i, j;
integer error, correct;
integer output_finish_flag;

// USE UR DESIGN
`ifdef ADD
	fp_adder fp_adder_u(.o_out(result_wire), .i_src_a(testing_input_A), .i_src_b(testing_input_B), .i_op(testing_input_inst)); // INST == 0: ADD, INST == 1: SUB
`elsif SUB
	fp_adder fp_adder_u(.o_out(result_wire), .i_src_a(testing_input_A), .i_src_b(testing_input_B), .i_op(testing_input_inst)); // INST == 0: ADD, INST == 1: SUB
`elsif CMP
	fp_lt fp_lt_u(.o_out(less_than_flag_wire), .i_src_a(testing_input_A), .i_src_b(testing_input_B)); 
`else
	fp_adder fp_adder_u(.o_out(result_wire), .i_src_a(testing_input_A), .i_src_b(testing_input_B), .i_op(testing_input_inst)); // INST == 0: ADD, INST == 1: SUB
`endif

// dump waveform
initial begin
	`ifdef ADD
		$fsdbDumpfile("FPU_add_sub.fsdb");
	`elsif SUB
		$fsdbDumpfile("FPU_add_sub.fsdb");
	`elsif CMP
		$fsdbDumpfile("FPU_cmp.fsdb");
	`else
		$fsdbDumpfile("FPU_add_sub.fsdb");
	`endif
	
    $fsdbDumpvars(0, test);
end

//clock generator
initial begin
	clk = 0;
end
always #(`PERIOD/2) clk = ~clk;


// read testing data & golden data
initial begin
	$readmemb(`A_data_path, A_data);
	$readmemb(`B_data_path, B_data);
	$readmemb(`OUT_data_path, OUT_data);
end


// input loop
initial begin
	#(`PERIOD * 0.25);
	i = 0;
	
	while(i < `TEST_NUM)begin
		@(negedge clk);
		testing_input_A = A_data[i];
		testing_input_B = B_data[i];
		testing_input_inst = `INST;
		
		@(posedge clk);
		i = i + 1;
	end
end
// output loop 
initial begin
	@(posedge clk);
	#(`PERIOD * 0.25);
	j = 0;
	error = 0;
	correct = 0;
	output_finish_flag = 0;
	
	`ifdef CMP
		while(j < `TEST_NUM)begin
			@(posedge clk);
			if(less_than_flag_wire !== OUT_data[j][0])begin
				$display(
				"Error! A[%d] = %b(%h), B[%d] = %b(%h) \n Golden = %b. Yours = %b", 
				j, A_data[j], A_data[j], j, B_data[j], B_data[j],
				OUT_data[j][0], less_than_flag_wire
				);
				error = error + 1;
			end
			else begin
				correct = correct + 1;
			end
			
			@(negedge clk);
			j = j + 1;
		end
	`else  //ADD ,SUB 
		while(j < `TEST_NUM)begin
			@(posedge clk);
			if(result_wire === OUT_data[j])begin
				correct = correct + 1;
			end
			else if(OUT_data[j] === {1'b1, 31'b0} && result_wire === 32'b0)begin //result should be neg zero, but in this homework, all opertion with zeros result in (+0)
				$display(
				"Warning! Result should be neg zero, but get pos zero! \n A[%d] = %b(%h), B[%d] = %b(%h), INST = %b, \n Golden = %b(%h). Yours = %b(%h)", 
				j, A_data[j], A_data[j], j, B_data[j], B_data[j], `INST,
				OUT_data[j], OUT_data[j], result_wire, result_wire
				);
				correct = correct + 1;
			end
			else begin
				$display(
				"Error! A[%d] = %b(%h), B[%d] = %b(%h), INST = %b, \n Golden = %b(%h). Yours = %b(%h)", 
				j, A_data[j], A_data[j], j, B_data[j], B_data[j], `INST,
				OUT_data[j], OUT_data[j], result_wire, result_wire
				);
				error = error + 1;
			end
			
			@(negedge clk);
			j = j + 1;
		end
	`endif
	
	output_finish_flag = 1;
end

// Show reult
initial begin
	wait(output_finish_flag);
	
	if(error == 0 && correct == `TEST_NUM)begin
		$display("----------------------------------------------");
        $display("-                  ALL PASS!                 -");
        $display("----------------------------------------------");
	end
	else begin
		$display("----------------------------------------------");
        $display("  Wrong! Total  Error: %d                     ", error);
        $display("----------------------------------------------");
	end
	
	#(`PERIOD);
	$finish;
end



// force to finish if exceed MAX_CYCLE
initial begin
	#(`MAX_CYCLE * `PERIOD);
	#(`PERIOD);
	$display("Error! Execution time exceed limitation! ");
	$finish;
end
endmodule

