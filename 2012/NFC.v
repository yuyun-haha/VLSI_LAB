`timescale 1ns/100ps
module NFC(clk, rst, done, F_IO_A, F_CLE_A, F_ALE_A, F_REN_A, F_WEN_A, F_RB_A, F_IO_B, F_CLE_B, F_ALE_B, F_REN_B, F_WEN_B, F_RB_B);

  input clk;
  input rst;
  output reg done;
  inout [7:0] F_IO_A;
  output reg F_CLE_A;
  output reg F_ALE_A;
  output  reg F_REN_A;
  output  reg F_WEN_A;
  input   F_RB_A;
  inout [7:0] F_IO_B;
  output reg F_CLE_B;
  output reg F_ALE_B;
  output  F_REN_B;
  output reg F_WEN_B;
  input  F_RB_B;
  reg [7:0] a,b;
  reg [8:0]counter;
  reg [7:0]buffer [511:0];
  reg [8:0]page;
  parameter cmda=4'b0000,
			cmdb=4'b0001,
			cmdc=4'b0010,
			idle=4'b0011,
			start_to_read=4'b0100,
			start_to_write=4'b0101,
			datain=4'b0110,
			dataout=4'b0111,
			finish=4'b1000,
			idle2=4'b1001,
			idle3=4'b1010;
			
  reg [3:0] cur_st, nxt_st;
  
always@(posedge clk or posedge rst)
	if(rst)
		cur_st<=cmda;
	else 
		cur_st<=nxt_st;

always@(*)
begin
	case(cur_st)
		idle:nxt_st=datain;
		idle2:nxt_st=idle3;
		idle3:nxt_st=dataout;
		cmda:nxt_st=(rst)?cmda:start_to_read;
		start_to_read:nxt_st=(counter==3)?idle:start_to_read;
		datain:nxt_st=(counter==511)?cmdb:datain;
		cmdb:nxt_st=start_to_write;
		start_to_write:nxt_st=(counter==3)?idle2:start_to_write;
		dataout:nxt_st=(counter==0)?cmdc:dataout;
		cmdc:nxt_st=(page==0)?finish:cmda;
		finish:nxt_st=(counter==15)?idle:finish;
		default:nxt_st=idle; //finish
	

	endcase
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		done<=0;
	else if(cur_st==finish && counter==10)
		done<=1;
	else done<=0;
end
		
always@(posedge clk or posedge rst)
begin
	if(rst)
		F_CLE_A<=0;
	else if(cur_st==cmda)
		F_CLE_A<=1;
	else F_CLE_A<=0;
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		F_ALE_A<=0;
	else if(cur_st==start_to_read&&(counter==0||counter==1||counter==2))
		F_ALE_A<=1;
	else F_ALE_A<=0;
end		

always@(posedge clk or posedge rst)
begin
	if(rst)
		F_ALE_B<=0;
	else if(cur_st==start_to_write&&(counter==0||counter==1||counter==2))
		F_ALE_B<=1;
	else F_ALE_B<=0;
end

always@(posedge clk or posedge rst)
begin
	if(rst)
		F_CLE_B<=0;
	else if(cur_st==cmdb||cur_st==cmdc)
		F_CLE_B<=1;
	else F_CLE_B<=0;
end

assign F_IO_B=(cur_st==start_to_write)?b:'bz;	
	
always@(posedge clk or posedge rst)
begin
    if(rst)
		b<=0;
	else if(nxt_st==dataout)
		b<=buffer[counter];
	else if(cur_st==cmdb)
		b<=8'h80;
	else if(cur_st==cmdc)
		b<=8'h10;
	else if(cur_st==start_to_write&&counter==0)
		b<=8'b0;
	else if(cur_st==start_to_write&&counter==1)
		b<=page[8:1];
	else if(cur_st==start_to_write&&counter==2)
		b<={7'b0,page[0]};
end		

assign F_IO_B=(cur_st==start_to_write||cur_st==dataout||cur_st==cmda||cur_st==finish)?b:'bz;



always@(posedge clk or posedge rst)
begin
	if(rst)
		page<=0;
	else if(cur_st==dataout&&counter==0)
		page<=page+1;
end		

always@(posedge clk or posedge rst)
begin
	if(rst)
		counter<=0;
	else if(cur_st==idle||cur_st==idle2||cur_st==cmda||cur_st==cmdb||cur_st==cmdc)
		counter<=0;
	else
		counter<=counter+1;
end
  
always@(posedge clk)
	if(cur_st==datain)
		buffer[counter]<=F_IO_A;
		
always@(*)
	if(cur_st==start_to_read)
		F_WEN_A=clk;
 	else
		F_WEN_A=1;
		
 always@(*)
	if(cur_st==datain)
		F_REN_A=clk;
	else F_REN_A=1;
	
assign F_REN_B=1;  
  
 always@(*)
	if(cur_st==start_to_write||cur_st==dataout||cur_st==cmda||cur_st==finish)
		F_WEN_B=clk;
	else F_WEN_B=1;//////////////////////////////////////////////////////

assign F_REN_B=1;
	
always@(posedge clk or posedge rst)
begin
	if(rst)
		a<=0;
	else if(cur_st==cmda)
		a<=8'h00;
	else if(cur_st==start_to_read&&counter==0)
		a<=8'b0;
	else if(cur_st==start_to_read&&counter==1)
		a<=page[8:1];
	else if(cur_st==start_to_read&&counter==2)
		a<={7'b0,page[0]};
end
  
assign F_IO_A=(cur_st==start_to_read)?a:'bz;


endmodule
