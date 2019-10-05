module SET ( clk , rst, en, central, radius, mode, busy, valid, candidate );

input clk, rst;
input en;
input [23:0] central;
input [11:0] radius;
input [1:0] mode;
output reg busy;
output reg valid;
output reg[7:0] candidate;

parameter idle=3'b000,
		  work0=3'b100,
		  work1=3'b101,
		  work2=3'b110,
		  work3=3'b111;
		  
		  
reg [2:0] cur_st,nxt_st;
reg [5:0] r1_sq,r2_sq,r3_sq;
reg [3:0] r1,r2,r3;
reg [3:0] x1c,x2c,x3c,y1c,y2c,y3c; //CENTER
reg [3:0] a1_dx,a1_dy,a2_dx,a2_dy,a3_dx,a3_dy; 
reg [7:0] a1,a2,a3;
reg [4:0] dlx,dly,uly,drx,movx,movy;

always@(posedge clk or posedge rst)
	if(rst)
		cur_st<=idle;
	else 
		cur_st<=nxt_st;
	
always@(posedge clk or posedge rst)
 begin
    if(rst)
		valid<=0;
    else if((cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)&&(movy==uly&&movx==drx))            
		valid<=1;
	else
		valid<=0;
 end
 
always@(*)
	case(cur_st)
		idle:nxt_st=(en)?{1'b1,mode}:idle;
		work0:nxt_st=(movy==uly&&movx==drx)?idle:work0;
		work1:nxt_st=(movy==uly&&movx==drx)?idle:work1;
		work2:nxt_st=(movy==uly&&movx==drx)?idle:work2;
		work3:nxt_st=(movy==uly&&movx==drx)?idle:work3;
	endcase

always@(posedge clk or posedge rst)
	begin
	if(rst)
		busy<=0;
	else if(cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)
		busy<=1;
	else 
		busy<=0;
	end


	
	
always@(*)
begin
	x1c<=central[23:20];
	y1c<=central[19:16];	
end

always@(*)
begin
	r1<=radius[11:8];
end

always@(*)
begin
	x2c<=central[15:12];
	y2c<=central[11:8];
end

always@(*)
begin
	r2<=radius[7:4];
end

always@(*)
begin
	x3c<=central[7:4];
	y3c<=central[3:0];
		
end

always@(*)
begin
	r3<=radius[3:0];
end		
		
always@(*)
begin
	case (mode)
	2'b00,2'b01:
		if(x1c<(5'd1+r1)) 
			dlx=5'd1;
		else 
		dlx=x1c-r1;	
	2'b10,2'b11:
		dlx=5'd1;
	default:dlx=5'd1;
	endcase
end
		
always@(*)
begin
	case(mode)
	2'b00,2'b01:
		if(x1c+r1>5'd8)
			drx=5'd8;		
		else 
		drx=x1c+r1;
	2'b10,2'b11:
		drx=5'd8;
	default:drx=1;
	endcase
end
	
always@(*)
begin
	case(mode)
	2'b00,2'b01:
		if(y1c<(5'd1+r1)) 
			dly=5'd1;
		else
		dly=y1c-r1;	
	2'b10,2'b11:
		dly=5'd1;
	default:dly=5'd1;
	endcase
end
		
always@(*)
begin
	case(mode)
	2'b00,2'b01:
		if(y1c+r1>5'd8)
			uly=5'd8; 
		else 
		uly=y1c+r1; 
	2'b10,2'b11:
		uly=5'd8; 
	default:uly=5'd1;
	endcase
end
	
always@(posedge clk or posedge rst)
begin
	if(rst)
		movx<=0;
	else if	(en)
		movx<=dlx;
	else if(movx==drx)
		movx<=dlx;
	else if(cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)
		movx<=movx+1;
end
	
always@(posedge clk or posedge rst)
begin
	if(rst)
		movy<=0;
	else if	(en)
		movy<=dly;		
	else if((cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)&&movx==drx)
		movy<=movy+1;
end		

always@(*)
begin
	a1_dx=(movx>x1c)?movx-x1c:x1c-movx;
end

always@(*)
begin
	a1_dy=(movy>y1c)?movy-y1c:y1c-movy;
end

always@(*)
begin
	a2_dx=(movx>x2c)?movx-x2c:x2c-movx;
end

always@(*)
begin
	a2_dy=(movy>y2c)?movy-y2c:y2c-movy;
end	

always@(*)
begin
	a3_dx=(movx>x3c)?movx-x3c:x3c-movx;
end

always@(*)
begin
	a3_dy=(movy>y3c)?movy-y3c:y3c-movy;
end

always@(*)
begin
	if(cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)
		a1=a1_dx*a1_dx+a1_dy*a1_dy;
	else a1=0;
end


always@(*)
begin
	if(cur_st==work1||cur_st==work2||cur_st==work3)
		a2=a2_dx*a2_dx+a2_dy*a2_dy;
	else a2=0;
end


always@(*)
begin
	if(cur_st==work3)
		a3=a3_dx*a3_dx+a3_dy*a3_dy;
	else a3=0;
end	


always@(*)
begin
	if(cur_st==work0||cur_st==work1||cur_st==work2||cur_st==work3)
		r1_sq=r1*r1;
	else r1_sq=0;
end

always@(*)
begin
	if(cur_st==work1||cur_st==work2||cur_st==work3)
		r2_sq=r2*r2;
	else r2_sq=0;
end

always@(*)
begin
	if(cur_st==work3)
		r3_sq=r3*r3;
	else r3_sq=0;
end


always@(posedge clk or posedge rst)
	begin
	if(rst)
		candidate<=0;
	else
	case(cur_st)
	work0:if(a1<=r1_sq)
			candidate<=candidate+1;
	work1:if(a1<=r1_sq&&a2<=r2_sq)
			candidate<=candidate+1;
	work2:if((a1<=r1_sq&&a2>r2_sq)||(a1>r1_sq&&a2<=r2_sq))
			candidate<=candidate+1;
	work3:if(((a1<=r1_sq&&a2<=r2_sq)||(a1<=r1_sq&&a3<=r3_sq)||(a2<=r2_sq&&a3<=r3_sq))&&(~((a1<=r1_sq)&&(a2<=r2_sq)&&(a3<=r3_sq))))
			candidate<=candidate+1;
	default:candidate<=0;
	endcase
	
	
	
	end
		  

endmodule


