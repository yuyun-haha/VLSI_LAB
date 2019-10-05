module STI_DAC(clk ,reset, load, pi_data, pi_length, pi_fill, pi_msb, pi_low, pi_end,
	       so_data, so_valid,
	       oem_finish, oem_dataout, oem_addr,
	       odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr);

input		clk, reset;
input		load, pi_msb, pi_low, pi_end; 
input	[15:0]	pi_data;
input	[1:0]	pi_length;
input		pi_fill;
output reg		so_data, so_valid;

output  reg oem_finish, odd1_wr, odd2_wr, odd3_wr, odd4_wr, even1_wr, even2_wr, even3_wr, even4_wr;
output reg[4:0] oem_addr;
output reg[7:0] oem_dataout;

//==============================================================================

parameter   idle=3'b000,
		    work8=3'b100,
			work16=3'b101,
			work24=3'b110,
			work32=3'b111,
			zero=3'b001,
			blank=3'b011;
	
reg [7:0] block_count;
reg [2:0] cur_st,nxt_st;
reg [1:0] sel;
reg [4:0] counter;
reg [2:0] counter_b;
reg row;
reg so_data_temp;

always@(posedge clk or posedge reset)
	if(reset)
		cur_st<=idle;
	else
		cur_st<=nxt_st;
			
always@(*)
	case(cur_st)
		idle:nxt_st=(load)?{1'b1,pi_length}:((pi_end)?blank:idle);
		work8:nxt_st=(counter==5'd7)?idle:work8;
		work16:nxt_st=(counter==5'd15)?idle:work16;
        work24:nxt_st=(counter==5'd23)?idle:work24;
		work32:nxt_st=(counter==5'd31)?idle:work32;
		blank:nxt_st=zero;
		default:nxt_st=blank;
	endcase




		
always@(posedge clk or posedge reset)
begin
	if(reset)
		sel<=2'd0;
	else if(load)
	begin
		if(pi_length==2'b00)
			sel<={pi_low,pi_msb};
		else if(pi_length==2'b01)	
			sel<={1'b0,pi_msb};
		else sel<={pi_fill,pi_msb};
	end
end	


	
always@(posedge clk or posedge reset)
begin
	if(reset)
		counter<=5'd0;
	else if(cur_st==work8||cur_st==work16||cur_st==work24||cur_st==work32)
		counter<=counter+5'd1;
	else counter<=5'd0;

end


always@(posedge clk or posedge reset)
begin
		if(reset)
			so_valid<=1'b0;
		else if(cur_st==work8||cur_st==work16||cur_st==work24||cur_st==work32)
			so_valid<=1'b1;
		else so_valid<=1'b0;	
end

always@(*)  
    begin
    if(cur_st==work8)
		begin
			case(sel)
				2'b00:so_data_temp=pi_data[counter];     //count to 7
				2'b01:so_data_temp=pi_data[5'd7-counter] ;  //count to 7
				2'b10:so_data_temp=pi_data[counter+5'd8] ;  //count to 7
				2'b11:so_data_temp=pi_data[5'd15-counter];  //count to 7
			endcase
		end
    else if(cur_st==work16)
		begin
			case(sel[0])
				1'b0:so_data_temp=pi_data[counter]; //count to 15
				1'b1:so_data_temp=pi_data[5'd15-counter]; //count to 15
			endcase
		end
	else if(cur_st==work24)
		begin
			case(sel)
				2'b00:so_data_temp=(counter<5'd16)?pi_data[counter]:0;   //count to 23
				2'b01:so_data_temp=(counter<5'd8)?0:pi_data[5'd23-counter];  //count to 23
				2'b10:so_data_temp=(counter<5'd8)?0:pi_data[counter-5'd8];   //count to 23
				2'b11:so_data_temp=(counter<5'd16)?pi_data[5'd15-counter]:0;  //count to 23
			endcase	
		end
	else if(cur_st==work32)
		begin
			case(sel)
				2'b00:so_data_temp=(counter<5'd16)?pi_data[counter]:0;   //count to 31
				2'b01:so_data_temp=(counter<5'd16)?0:pi_data[5'd31-counter];  //count to 31
				2'b10:so_data_temp=(counter<5'd16)?0:pi_data[counter-5'd16];   //count to 31
				2'b11:so_data_temp=(counter<5'd16)?pi_data[5'd15-counter]:0;  //count to 31
			endcase	
		end
	else 
		so_data_temp=0;
	end

always@(posedge clk or posedge reset)
	if(reset)
		so_data<=0;
	else
		so_data<=so_data_temp;
		
	
	
always@(posedge clk or posedge reset)  		
	begin
		if(reset)
			oem_dataout<=8'd0;
		else if(cur_st==zero)	
			oem_dataout<=8'd0;
		else  
			oem_dataout[3'd7-counter_b]<=so_data;
	end
 
always@(posedge clk or posedge reset)
	if(reset)
		counter_b<=0;
	else
		counter_b<=counter[2:0];
	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			block_count<=0;
		else if (cur_st==zero)
			block_count<=block_count+1;
		else if(counter_b==3'd7)
			block_count<=block_count+1;			
	end
/////////////////////////////////////////////////////////////////////////////
always@(posedge clk or posedge reset)
	begin
		if(reset)
			row<=0; //1 bit
		else if(block_count[2:0]==3'b111 &&cur_st==zero)
			row<=row+1'b1;
		else if(block_count[2:0]==3'b111 && counter_b==3'd7)
			row<=row+1'b1;
	end
	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			odd1_wr<=0;	
		else if(block_count>8'd63)
			odd1_wr<=0;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& (cur_st==zero))
			odd1_wr<=1;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& counter_b==3'd7 )
			odd1_wr<=1;
		else odd1_wr<=0;	
	end
always@(posedge clk or posedge reset)
	begin
		if(reset)
			even1_wr<=0;	
		else if(block_count>8'd63)
			even1_wr<=0;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& (cur_st==zero) )
			even1_wr<=1;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& counter_b==3'd7 ) 
			even1_wr<=1;
		else even1_wr<=0;			
	end	
	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			odd2_wr<=0;	
		else if(block_count>8'd127||block_count<8'd64)
			odd2_wr<=0;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& (cur_st==zero))
			odd2_wr<=1;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& counter_b==3'd7 )
			odd2_wr<=1;
		else odd2_wr<=0;	
	end
always@(posedge clk or posedge reset)
	begin
		if(reset)
			even2_wr<=0;	
		else if(block_count>8'd127||block_count<8'd64)
			even2_wr<=0;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& (cur_st==zero) )
			even2_wr<=1;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& counter_b==3'd7 )
			even2_wr<=1;	
		else even2_wr<=0;
	end	
	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			odd3_wr<=0;	
		else if(block_count>8'd191||block_count<8'd128)
			odd3_wr<=0;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& (cur_st==zero))
			odd3_wr<=1;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& counter_b==3'd7 )
			odd3_wr<=1;
		else odd3_wr<=0;	
	end
always@(posedge clk or posedge reset)
	begin
		if(reset)
			even3_wr<=0;	
		else if(block_count>8'd191||block_count<8'd128)
			even3_wr<=0;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& (cur_st==zero) )
			even3_wr<=1;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& counter_b==3'd7 )
			even3_wr<=1;
		else even3_wr<=0;
	end	

always@(posedge clk or posedge reset)
	begin
		if(reset)
			odd4_wr<=0;	
		else if(block_count<8'd192)
			odd4_wr<=0;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& (cur_st==zero))
			odd4_wr<=1;
		else if(((row==0 && block_count[0]==0 )||(row==1 && block_count[0]==1 ))&& counter_b==3'd7 )
			odd4_wr<=1;
		else odd4_wr<=0;	
	end
always@(posedge clk or posedge reset)
	begin
		if(reset)
			even4_wr<=0;	
		else if(block_count<8'd192)
			even4_wr<=0;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& (cur_st==zero) )
			even4_wr<=1;
		else if(((row==0 && block_count[0]==1 )||(row==1 && block_count[0]==0 ))&& counter_b==3'd7 )
			even4_wr<=1;
		else even4_wr<=0;	
	end	
		
////////////////////////////////////////////////////////////////////	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			oem_addr<=0;
		else oem_addr<=(block_count>>1);
	end

	
	
always@(posedge clk or posedge reset)
	begin
		if(reset)
			oem_finish<=0;
		else if(block_count==8'd0&&cur_st==blank)
			oem_finish<=1;
	end
endmodule		