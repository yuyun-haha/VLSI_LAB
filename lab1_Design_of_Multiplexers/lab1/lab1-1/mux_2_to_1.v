module mux_2_to_1(M,a,b,sel);

input a,b,sel;
output M;
wire [2:0]temp;  /*1 a
                   0 b */

and u1(temp[2],a,sel);
not u2(temp[1],sel);
and u3(temp[0],b,temp[1]);
or u4(M,temp[0],temp[2]);


endmodule

