`timescale 1ns / 1ps
`define CYCLE 10
`define GOLDEN "./golden.dat"
`define OUTFILE "./out.dat"
module counter_tb;  
  wire [3:0] out;
  reg clk;
  reg rst;
  reg [1:0] in; // 1~3
  
  parameter t_rst =  `CYCLE * 1.2;
  
  integer num = 1;
  integer err = 0; //error numbers
  integer val_1;
  integer val_2;
  integer fp_out; //file pointer for output file
  integer fp_golden; //file pointer for golden file
  reg [3:0] correct; //correct answer read from golden file
  reg [3:0] ans; //answer read from output file
  
  counter counter_top(.out(out), .clk(clk), .rst(rst), .in(in));
  
  initial fp_out = $fopen(`OUTFILE, "w");
  
  initial begin
    clk = 1'd0;
    rst = 1'd1;
    in = 2'd1;
    #t_rst rst = 1'd0;
  end
  
  always begin
    #(`CYCLE/2) clk = ~clk;
  end
  
  always begin
      #`CYCLE;
      if(!rst) begin
        $fwrite(fp_out, "%d\n", out);
        num = num + 1;
      end
  end
  
  initial begin
    #(32*`CYCLE) in = 2'd2;
    
    #(17*`CYCLE) in = 2'd3;
    
    #(12*`CYCLE) in = 2'd1;
    
    #(7*`CYCLE) in = 2'd3;
    
    #(6*`CYCLE) in = 2'd2;
    
    #(6*`CYCLE) in = 2'd3;
    
    #(12*`CYCLE) in = 2'd1;
    
    #(10*`CYCLE);
    
    $fclose(fp_out);

    //compare answers
    num = 1;
    
    fp_golden = $fopen(`GOLDEN, "r");
    fp_out = $fopen(`OUTFILE, "r");
    
    while(!$feof(fp_golden)) begin
      val_1 = $fscanf(fp_golden, "%d", correct);
      val_2 = $fscanf(fp_out, "%d", ans); 
      
      if(correct == ans)
          $display("%d data is correct", num);
        else begin
          $display("%d data is error %d, correct is %d", num, ans, correct);
          err = err + 1;
        end
        num = num + 1;       
    end
    
    if(err==0) begin
	$display("-------------------   counter check successfully   -------------------");
	$display("            $$              ");
	$display("           $  $");
	$display("           $  $");
	$display("          $   $");
	$display("         $    $");
	$display("$$$$$$$$$     $$$$$$$$");
	$display("$$$$$$$              $");
	$display("$$$$$$$              $");
	$display("$$$$$$$              $");
	$display("$$$$$$$              $");
	$display("$$$$$$$              $");
	$display("$$$$$$$$$$$$         $$");
	$display("$$$$$      $$$$$$$$$$");
	end
	else $display("-------------------   There are %d errors   -------------------", err);
	$finish ;
    
    $fclose(fp_golden);
    $fclose(fp_out);
    
    $stop;    
  end
endmodule
