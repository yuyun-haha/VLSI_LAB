module DT(
	input 			clk, 
	input			reset,
	output			done ,
	output	reg		sti_rd ,
	output	reg 	[9:0]	sti_addr ,
	input		[15:0]	sti_di,
	output	reg		res_wr ,
	output	reg		res_rd ,
	output	reg 	[13:0]	res_addr ,
	output	reg 	[7:0]	res_do,
	input		[7:0]	res_di
	);

parameter idle=4'd0,

		  load_for=4'd1,
		  recog_for=4'd2,
		  cal_for=4'd3,
		  write_for=4'd4,
		  
		  recog_bound=4'd5,
		  write_bound=4'd6,
		  
		  load_back=4'd7,
		  recog_back=4'd8,
		  cal_back=4'd9,
		  write_back=4'd10,
		  
		  finish=4'd11;

reg [3:0] counter;		  
reg [3:0] cur_st,nxt_st;
reg [6:0] x;
reg [2:0] y;
reg [2:0]for_counter,back_counter;
wire b_enable;
wire get1;	
reg [15:0] buffer;
reg [7:0] min_back,min_for;
reg [13:0]addr[4:0];   /*更改順序*/
wire [13:0]cen;
always@(posedge clk or negedge reset)
begin
	if(!reset)
		min_for<=8'd0;
	else if((cur_st==cal_for)&&(for_counter==3'd0))
		min_for<=res_di;
	else if((cur_st==cal_for)&&(min_for>res_di))
		min_for<=res_di;		
end


always@(posedge clk or negedge reset)
begin
	if(!reset)
		min_back<=8'd0;
	else if((cur_st==cal_back)&&(back_counter==3'd0))
		min_back<=res_di;
	else if((cur_st==cal_back)&&(min_back>(res_di+8'd1)))
		min_back<=res_di+8'd1;
end

assign cen={x,y,counter};
always@(*)
begin
	case(cur_st)
		cal_for:
			begin
				addr[0]=cen-14'd1; /*改成14d*/
				addr[1]=cen-14'd127;
				addr[2]=cen-14'd128;
				addr[3]=cen-14'd129;
				addr[4]=cen-14'd1;
			end
		cal_back:
			begin
				addr[0]=cen;
				addr[1]=cen-14'd127;
				addr[2]=cen-14'd128;
				addr[3]=cen-14'd129;
				addr[4]=cen-14'd1;
			
			end
			
		default	:
			begin
				addr[0]=cen;
				addr[1]=cen;
				addr[2]=cen;
				addr[3]=cen;
				addr[4]=cen;
			end
		endcase
end



always@(posedge clk)
begin
	if((cur_st==load_back)||(cur_st==load_for))
		buffer<=sti_di;
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		sti_rd<=1'd0;
	else if(nxt_st==load_for)
		sti_rd<=1'd1;	
	else sti_rd<=1'd0;
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		sti_addr<=10'd0;
	else if(nxt_st==load_for||nxt_st==load_back) /*加了nxt_st==load_back*/
		sti_addr<={x,y};	
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		res_wr<=1'd0;
	else if(nxt_st==write_back||nxt_st==write_bound||nxt_st==write_for)
		res_wr<=1'd1;
	else res_wr<=1'd0;
end


always@(posedge clk or negedge reset)
begin
	if(!reset)
		res_rd<=1'd0;
	else if(nxt_st==recog_for||nxt_st==recog_back||nxt_st==cal_for||nxt_st==cal_back)
		res_rd<=1'd1;
	else res_rd<=1'd0;		
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		res_addr<=14'd0;
	else if(cur_st==write_back||cur_st==write_bound||cur_st==write_for)   
		res_addr<={x,y,counter};
	else if(cur_st==cal_back)
		res_addr<=addr[back_counter];
	else if(cur_st==cal_for)
		res_addr<=addr[for_counter]	;
end

always@(posedge clk or negedge reset) 
begin
	if(!reset)
		res_do<=8'd0;
	else if(cur_st==write_bound)
		res_do<=8'd1;
	else if(cur_st==write_back)
		res_do<=min_back;
	else if(cur_st==write_for)
		res_do<=min_for+8'd1;		
end

assign done=(cur_st==finish)?1:0;
		
always@(posedge clk or negedge reset)   
    if(!reset)
       cur_st<=idle;
    else 
       cur_st<=nxt_st;    


	   
always@(*)
  begin
    case(cur_st)
		idle:nxt_st=load_for;
		
		load_for:nxt_st=((x==7'd1)||(x==7'd126))?recog_bound:recog_for;
		recog_for:nxt_st=(get1)?cal_for:(counter==4'd15)?load_for:recog_for;
        cal_for:nxt_st=(for_counter==3'd4)?write_for:cal_for;
		write_for:nxt_st=(counter==4'd15)?load_for:recog_for;
		
		recog_bound:nxt_st=(b_enable)?load_back:(get1)?write_bound:(counter==4'd15)?load_for:recog_bound;
		write_bound:nxt_st=(b_enable)?load_back:(counter==4'd15)?load_for:recog_bound;
		
		load_back:nxt_st=(x==7'd1)?finish:(x<7'd126)?recog_back:load_back;
		recog_back:nxt_st=(get1)?cal_back:(counter==4'd15)?load_back:recog_back;/*加了counter.....*/
		cal_back:nxt_st=(back_counter==3'd5)?write_back:cal_back;
		write_back:nxt_st=(counter==4'd15)?load_back:recog_back;
		
		finish:nxt_st=idle;
		
    endcase
  end
  	   
always@(posedge clk or negedge reset)
begin
	if(!reset)
		counter<=4'd0;
	else if(counter==4'd15&&cur_st==load_for)
		counter<=4'd0;
	else if((cur_st==recog_for||cur_st==recog_bound||cur_st==recog_back)&&(~get1))
		counter<=counter+4'd1;
	else if (cur_st==write_back||cur_st==write_bound||cur_st==write_for)
		counter<=counter+4'd1;
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		x<=7'd1;
	else if((nxt_st==load_for)&&(y==3'd7))   /*改成nxt*/
		x<=x+7'd1;
	else if ((nxt_st==load_back)&&(y==3'd7)) /*加上y 改成nxt*/
		x<=x-7'd1;
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		y<=3'd0;
	else if(counter==4'd15&&nxt_st==load_for)
		y<=y+3'd1;
	else if (counter==4'd15&&cur_st==recog_back)/*加上counter 改成recog*/
		y<=y-3'd1;
end

always@(posedge clk or negedge reset)
begin
	if(!reset)
		for_counter<=3'd0;
	else if (for_counter==3'd4)
		for_counter<=3'd0;
	else if (cur_st==cal_for)
		for_counter<=for_counter+3'd1;
end
	
always@(posedge clk or negedge reset)
begin
	if(!reset)
		back_counter<=3'd0;
	else if (back_counter==3'd5)
		back_counter<=3'd0;
	else if (cur_st==cal_back)
		back_counter<=back_counter+3'd1;
end

assign b_enable=({x,y,counter}==15'd16255);  //x=7'd126 y=3'd7 counter=4'd15
assign get1=(buffer[counter]==1'd1)?1'd1:1'd0;

endmodule
