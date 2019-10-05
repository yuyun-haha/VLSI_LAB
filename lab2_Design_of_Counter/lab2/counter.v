`timescale 1ns / 1ps
module counter(out, clk, rst, in);
  output reg [3:0] out;
  input clk;
  input rst; 
  input [1:0] in;
  reg updown;

always@(posedge clk or posedge rst )
begin
  if(rst)
    begin
    out=4'b0;
    updown=1'b1;
    end
  else
    if(updown==1'b1)
      begin
         if ((4'b1111-out)<in)
          begin
              out=4'b1111;
              updown=1'b0;
          end
         else out=out+in;
      end 
  else
   if(updown==1'b0)
    begin
      if(in>out)
        begin
        out=4'b0;
        updown=1'b1;
        end
      else  
      out=out-in;
   end   
           
end

endmodule

