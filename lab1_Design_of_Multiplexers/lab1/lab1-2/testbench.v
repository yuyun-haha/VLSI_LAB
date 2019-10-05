module testbench;

reg [1:0]sel;
reg a, b, c, d;
wire M;

mux_4_to_1 mux2(a, b, c, d, sel, M);

initial
begin
$monitor($time," a=%b b=%b c=%b d=%b sel =%b  M =%b ",a,b,c,d,sel,M);  

   a = 1; b = 1; c = 0; d = 0; sel[1] = 0; sel[0] = 0;
#5 c = 1;
#5 d = 1;
#5 a = 0;
#5 b = 0;
#5 c = 0;sel[1] = 0; sel[0] = 1;
#5 d = 0;
#5 a = 1;
#5 b = 1;
#5 c = 1;
#5 d = 1;sel[1] = 1; sel[0] = 0;
#5 a = 0;
#5 b = 0;
#5 c = 0;
#5 d = 0;
#5 a = 1;sel[1] = 1; sel[0] = 1;
#5 b = 1;
#5 d = 1;
#5 a = 0;
#5 b = 0;
#5 $finish;
end

endmodule
