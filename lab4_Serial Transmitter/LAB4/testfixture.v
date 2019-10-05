`timescale 1ns/10ps
`define SDFFILE    "./syn/STI_DAC_syn.sdf"    // Modify your sdf file name
`define cycle 12
`define terminate_cycle 100000

module testfixture1;



	`define Pattern "./dat/Pattern.dat"
	`define Stimulus "./dat/Stimulus.dat"
	`define Expected "./dat/Expected_so.dat"
	`define Pat_num 9
	`define Exp_num 103




reg [15:0] pattern_in;
reg [2:0] stimulus_in;

reg Exp_so;

reg pi_end;

reg load, reset;
reg clk = 0;
wire pi_length = stimulus_in[2];
wire msb_first = stimulus_in[1];
wire low_en = stimulus_in[0];
wire [15:0] pi_data = pattern_in;
wire 		so_data, so_valid;



// ---------------------------------------- DUT instance ----------------------------------------------------------------------------------------------------
STI u_rtl(.clk(clk) ,.reset(reset), .load(load), .pi_data(pi_data),  
	      .pi_msb(msb_first), .pi_low(low_en), 
	      .so_data(so_data), .so_valid(so_valid) );

`ifdef SDF
initial $sdf_annotate(`SDFFILE, u_rtl);
`endif



reg [15:0] 	Pat_memory [0:`Pat_num];
reg 	   	Exp_memory [0:`Exp_num];
reg		Real_memory [0:`Exp_num];
reg [15:0] 	Sti_memory [0:`Pat_num];
initial begin
	$readmemh(`Pattern, Pat_memory);
	$readmemb(`Stimulus, Sti_memory);
	$readmemh(`Expected, Exp_memory);

	$display("--------------------------- Simulation Pattern is ready !!---------------------------");
end



always #(`cycle/2) clk = ~clk;

integer k;
integer i;
integer err_cnt;
integer c;
reg so_pass, Real_so, so_exp;
//------------- SPI module test ------------------------------------------------------------------------------------------------------------------------
initial begin
	$fsdbDumpfile("STI.fsdb");
	$fsdbDumpvars;
	
      $display("--------------------------- [ testfuxture1.v ] Simulation START !!---------------------------");
      $timeformat(-9, 1, " ns", 9); //Display time in nanoseconds
      
      err_cnt = 0;   
      reset = 0;
      load = 0;
      # `cycle;
      stimulus_in = 0;
      pattern_in = 0;
      reset = 1; 
      pi_end = 0;
      # `cycle;
      reset = 0; 
      i = 0;
      
        $display("--------------------------- Simulation at parallel data input stage !!---------------------------");
	for (k = 0; k <= `Pat_num; k = k+1)
	begin      
		
			@(negedge clk)
			//change inputs at strobe point
          		#(`cycle/4) load = 1;
				stimulus_in = Sti_memory[k];                
      				pattern_in = Pat_memory[k];
				$display("Pattern %d in !", k);
			#(`cycle/2) load = 0;
          		//Wait for PSI to process inputs
			if (k==`Pat_num) pi_end = 1;
          		wait(so_valid) 
			$display("Pattern %d done !", k);
			record_outputs; //call a task to verify outputs
	
	end
	
	// check_outputs	
	$display("--------------------------- Simulation at serial data output and result verify !! ---------------------------");
	for (c = 0; c <= `Exp_num; c = c+1) 
	begin
		
		#1;
		if (Real_memory[c] == Exp_memory[c]) begin  so_pass = Real_memory[c]; so_exp =  Exp_memory[c]; end
		else begin err_cnt = err_cnt + 1;  
			so_pass = Real_memory[c]; so_exp =  Exp_memory[c];
			$display("---------- ERROR at pattern No. %d,  REAL OUTPUT : so_data = %b,  EXPECTED OUTPUT so_data = %b\n",
      			c, Real_memory[c], Exp_memory[c]); end
	end 
	
     #`cycle 
     $display("--------------------------- so_data simulation FINISH !!---------------------------");
     if (err_cnt) begin 
     	$display("============================================================================");
     	$display("\n (T_T)  The simulation result of so_data is FAIL!!! there were %d errors in all.\n", err_cnt);
	$display("============================================================================");
	end
     else begin 
     	$display("============================================================================");
	$display("\n \\(^o^)/  The simulation result of so_data is PASS!!!\n");
	$display("============================================================================");
	end
     $finish;
end


initial begin 
	#`terminate_cycle;
	$display("================================================================================================================");
	$display("--------------------------- (/`n`)/ ~#  There was something wrong with your code !! ---------------------------"); 
	$display("--------------------------- The simulation can't finished!!, Please check it !!! ---------------------------"); 
	$display("================================================================================================================");
	$finish;
end

//--------------------------- check SPI outputs -----------------------------------------------------------------
  task record_outputs;	
  	while(so_valid)  begin
  		@(negedge clk); 
		if (so_valid) begin
		Real_memory[i] = so_data;
		Real_so = Real_memory[i];
		i = i+1;
  		end
	end 
  endtask

endmodule
