module STI(clk ,reset, load, pi_data,  pi_msb, pi_low,
           so_data, so_valid );

input       clk, reset;
input       load, pi_msb, pi_low; 
input   [15:0]  pi_data;
output      so_data, so_valid;
/////////////////////////////////////////////////////////////////////
reg [4:0]counter;
reg[1:0] sel;
reg so_valid,so_data;
reg cur_st,nxt_st;

parameter orig=1'b0,
          work=1'b1;
        
always@(posedge clk or posedge reset)
 begin
    if(reset)
      so_valid<=0;
    case(cur_st)
      orig: so_valid<=0;             
      work: so_valid<=1;
    endcase  
 end


always@(posedge clk or posedge reset) 
  if (reset)
       sel<=0;
  else if(load)         
       sel<={pi_msb,pi_low}; 

    
 always@(posedge clk or posedge reset)          
   begin
      if(reset)
        counter<=0;
      case(cur_st)
        orig: counter<=0;
        work: counter<=counter+1;
      endcase
   end

   
   
always@(posedge clk or posedge reset)
    if(reset)
       cur_st<=orig;
    else 
       cur_st<=nxt_st;    
   
   
   
always@(*)
  begin
    case(cur_st) 
      orig : 
            if(load)
              nxt_st=work;
            else
              nxt_st=orig;
  
      work : case(sel) 
              2'b00,2'b10 : 
                     if(counter==5'd7)
                        nxt_st=orig;
                     else
                        nxt_st=work;
                       
              2'b01,2'b11 : 
                    if(counter==5'd15)
                        nxt_st=orig;
                    else
                        nxt_st=work;
            endcase     
    endcase
  end
  
  
always@(posedge clk or posedge reset)
    
    if(reset)
      so_data<=0;
      
    else if(cur_st==work)
     case(sel)
       2'b00:if(counter<=5'd7)             //0:7
              begin
              so_data<=pi_data[counter];
              end
       2'b01:if(counter<=5'd15)            //0:15
              begin
               so_data<=pi_data[counter];
              end
 	     2'b10:if(counter<=5'd7)              //7:0
              begin
               so_data<=pi_data[7-counter];
              end
       2'b11:if(counter<=5'd15)             //15:0
              begin
               so_data<=pi_data[15-counter];
              end
    endcase        



endmodule
