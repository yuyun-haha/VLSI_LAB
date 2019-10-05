module testbench;

reg a, b, sel;
wire M;

mux_2_to_1 mux(.M(M),.a(a),.b(b),.sel(sel));

initial
begin
   a = 0; b = 1; sel = 1;
#5 b = 0;
#5 a = 1;
#5 b = 1;
#5 a = 0; sel = 0;
#5 b = 0;
#5 a = 1;
#5 b = 1;
#5 $finish;
end


initial
$monitor ($time, "M = %b, a = %b, b = %b, sel = %b", M, a, b, sel);
endmodule
