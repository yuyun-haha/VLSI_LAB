// Serial Input BitStream Pattern Detector
module fsm_bspd(clk, reset, bit_in, det_out);
input clk, reset, bit_in;
output det_out;

////////////////////////////////////////////////////////////

reg [1:0] currentstate,nextstate;
parameter s0=2'b00,
          s1=2'b01,
          s2=2'b10,
          s3=2'b11;
          
//current state
always@(posedge clk,posedge reset)
 if(reset)
   currentstate<=s0;
 else
   currentstate<=nextstate;
   
//nextstate
always@(currentstate,bit_in)
  case(currentstate)
    s0:nextstate=bit_in?s0:s1;
    s1:nextstate=bit_in?s0:s2;
    s2:nextstate=bit_in?s3:s2;
    s3:nextstate=bit_in?s0:s1;
    default:nextstate=s0;
endcase
    
//output
 assign det_out=((currentstate==s3)&&(bit_in==0))?1:0;



////////////////////////////////////////////////////////////
endmodule

