module mux_4_to_1 (a, b, c, d, sel,M);
  input a, b, c, d;
  input [1:0]sel;
  output M;
  wire [1:0]temp;
  
  /* 00 d
     01 b
     10 c
     11 a 
  */
      
  mux_2_to_1 m1(.M(temp[1]),.a(a),.b(b),.sel(sel[1]));
  mux_2_to_1 m2(.M(temp[0]),.a(c),.b(d),.sel(sel[1]));
  mux_2_to_1 m3(.M(M),.a(temp[1]),.b(temp[0]),.sel(sel[0]));
  
endmodule

module mux_2_to_1(M,a,b,sel);

input a,b,sel;
output M;
wire [2:0]temp;

and u1(temp[2],a,sel);
not u2(temp[1],sel);
and u3(temp[0],b,temp[1]);
or u4(M,temp[0],temp[2]);


endmodule