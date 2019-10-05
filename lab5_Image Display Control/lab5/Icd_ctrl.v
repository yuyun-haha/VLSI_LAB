module LCD_CTRL(clk, reset, IROM_Q, cmd, cmd_valid, IROM_EN, IROM_A, IRB_RW, IRB_D, IRB_A, busy, done);
input clk;
input reset;
input [7:0] IROM_Q;
input [2:0] cmd;
input cmd_valid;
output reg IROM_EN;
output reg [5:0] IROM_A;
output reg IRB_RW;
output [7:0] IRB_D;
output reg[5:0] IRB_A;
output reg busy;
output reg done;

parameter finish=2'b00,
          load=2'b01,
          work=2'b10,
          write=2'b11;

reg [1:0] cur_st,nxt_st;
reg [7:0] buffer [63:0];
reg [2:0] x,xreg;
reg [2:0] y,yreg;
reg [5:0] temp_a ;
wire [5:0] addr1,addr2,addr3,addr4;
wire [9:0] ave;
reg [7:0] data1,data2,data3,data4;


always@(posedge clk or posedge reset) //cur_st
  if(reset)
    cur_st<=load;
  else 
    cur_st<=nxt_st;
    

always@(*)     //nxt_st
  case(cur_st)
    finish:nxt_st=load;
    load:begin
            if((cmd_valid==1))
              nxt_st=work;
            else 
              nxt_st=load;
         end
    work: nxt_st=(cmd==0)?write:work;
    write:nxt_st=(IRB_A==63)?finish:write;
  endcase
  
 
 always@(posedge clk)
   case(nxt_st)
    finish:busy=0;
    load:if(temp_a==63)
			busy=0;
		 else busy=1;
    work:busy=0;
    write:busy=1;
   endcase  
    
always@(posedge clk or posedge reset)
  if(reset)
    IROM_EN<=0;
  else if(nxt_st==work)
	IROM_EN <= 1'd1;
    
always@(posedge clk or posedge reset)
  if(reset)
	IROM_A<=0;
  else if(cur_st==load )
    IROM_A <= IROM_A + 1'd1;
	
	
always@(posedge clk or posedge reset)
  if(reset)
      temp_a <=0;
  else
      temp_a <= IROM_A ;   
	  
 //------------write-------------//  
always@(posedge clk)
  if(nxt_st==write)
    IRB_RW<=0;
  else
    IRB_RW<=1;

assign IRB_D=buffer[IRB_A] ;
    
always@(posedge clk)
  if(nxt_st==finish)
    done<=1;
  else 
    done<=0;  
     
always@(posedge clk)
  if(reset)
    IRB_A<=0;
  else if(cur_st==write)
    IRB_A<=IRB_A+1'd1;  
  else if(IRB_A==6'd63)
    IRB_A<=0;
//------------------------------//

always@(posedge clk or posedge reset)
  begin
    if(reset)
     y<=3'd4;
    else if(nxt_st==work)
     y<=yreg;
  end
  
 always@(posedge clk or posedge reset)
  begin
    if(reset)
     x<=3'd4;
    else if(nxt_st==work)
     x<=xreg;
  end 
  
always@(*)
	case(cmd)
	3'd1:yreg=(y==1)?3'd1:y-1;//up
	3'd2:yreg=(y==7)?3'd7:y+1;//down
	default:yreg=y;
	endcase
	
always@(*)
	case(cmd)
	3'd3:xreg=(x==1)?3'd1:x-1;//left
	3'd4:xreg=(x==7)?3'd7:x+1;//right
	default:xreg=x;
	endcase	
	
	
assign addr1=(y<<3)+x-6'd9;
assign addr2=(y<<3)+x-6'd8;
assign addr3=(y<<3)+x;
assign addr4=(y<<3)+x-1'd1;

assign ave=((buffer[addr1]+buffer[addr2])+(buffer[addr3]+buffer[addr4]))>>2 ;
  

always@(posedge clk)
  if(nxt_st==load)
      buffer[temp_a]<=IROM_Q; 
  else if(nxt_st==work)
	begin
        buffer[addr1]<=data1;
        buffer[addr2]<=data2;
        buffer[addr3]<=data3;
        buffer[addr4]<=data4; 
      end
  
always@(*)
  case(cmd)
    3'd5:
	    begin
            data1=(ave[7:0]);//AVE.
            data2=(ave[7:0]);
            data3=(ave[7:0]);
            data4=(ave[7:0]);
        end
    3'd6:
		begin
            data1=buffer[addr4];//MIRR. X
            data4=buffer[addr1];
            data3=buffer[addr2];
            data2=buffer[addr3];
        end
    3'd7:
		begin
            data1=buffer[addr2];//MIRR. Y
            data2=buffer[addr1];
            data3=buffer[addr4];
            data4=buffer[addr3]; 
         end
	default:
		begin
            data1=buffer[addr1];
            data2=buffer[addr2];
            data3=buffer[addr3];
            data4=buffer[addr4]; 
         end
    endcase
 

 
      
endmodule

