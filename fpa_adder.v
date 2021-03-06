/*
This Part of code represents the floating point CALC state and is designed to fetch two iEE754 format inputs from Floating Point input 1 and Input 2 state
and to perform the addition on them by first separating the inputs into sign,exponent and mantissa.It also performs normalization and checks the underflow and overflow condition.

-Akashay Singla
*/

module fpa_adder(input clk,
input [15:0]Finput1,Finput2,
output reg[15:0]FPSUM,
output reg ovf,unf);

reg ovf1,unf1;
reg [12:0] M1,M2,M1_St0,M2_St0,M1_St1,M2_St1,M1_St2,M2_St2;
reg [4:0]E1,E2,E1_St0,E2_St0,E_Final1,E_Final2;
reg S1,S2,S1_St1,S2_St1,S1_St2,S2_St2;
reg [14:0] Sum;
reg FV,FU;
reg [12:0 ]Frac;
reg [4:0] Exp;
integer loop_limit=0;

initial begin
M1 =0;
M2=0;
M1_St1=0;
M2_St1=0;
M1_St2 =0;
M2_St2=0;
E1=0;E2=0;
E_Final2=0;E_Final1=0;
S1=0;S2=0; S2_St1=0; S1_St1=0; S1_St2 =0; S2_St2=0;
Sum=0;
ovf=0;
unf=0;
end
//Stage 1 fetching the data into registers & alligning the data
always @(posedge clk) begin
 $display("Finput1: %h, Finput2: %h ",Finput1,Finput2 );
  S1 <= Finput1[15] ;
  E1 <= Finput1[14:10];
  M1[11:0] <= {Finput1[9:0],2'b00};
  S2 <= Finput2[15];
  E2 <= Finput2[14:10];
  M2[11:0] <= {Finput2[9:0],2'b00};
if (Finput1 == 0) begin
M1[12] <= 1'b0 ;
end
else begin
M1[12] <= 1'b1 ;
end
if (Finput2 == 0) begin
M2[12] <= 1'b0 ;
end
else begin
M2[12] <= 1'b1 ;

end
#5;

//Align stage
	  loop_limit=0;
     if(M1!= 0 & M2!= 0) begin
    while ((E1!=E2) && (loop_limit<200) ) begin
    if (E1 < E2) begin
      M1 <= M1>>1;//{1'b0, M1[25:1]} ;
      E1 <= E1 + 1 ;
      #0.05;
    end
    else if (E2 < E1) begin
     M2 <= {1'b0, M2[12:1]} ;
     E2 <= E2 + 1 ;
     #0.05;
    end
	 loop_limit = loop_limit+1;
    end
   end
end

always@(posedge clk) begin
     S1_St1 <= S1;
     S2_St1 <= S2;
     M1_St0 <= M1;
     E1_St0 <= E1;
     M2_St0 <= M2;
     E2_St0 <= E2;
  
end
wire[14:0] F1comp,F2comp,Addout,Fsum; 
assign F1comp = (S1_St1== 1'b1) ? (~{2'b00, M1_St0}) + 1 : {2'b00, M1_St0} ;
assign F2comp = (S2_St1 == 1'b1) ? (~{2'b00, M2_St0}) + 1 : {2'b00, M2_St0} ;

assign Addout = F1comp + F2comp ;
assign Fsum = ((Addout[14]) == 1'b0) ? Addout : ~Addout + 1 ;

always@(posedge clk) begin
S1_St2 <= Addout[14];
 FV = Fsum[14] ^ Fsum[13] ;
 Frac = (FV==1'b1)? Fsum[13:1] : Fsum[12:0];
 Exp = (FV==1'b1) ? E1_St0 +1 : E1_St0;
 loop_limit=0;

while ((Frac[12] != 1)  && (Exp!=0) && (loop_limit <200)) begin
Frac= {Frac[12:0], 1'b0};
Exp = Exp-1;
#0.05;

loop_limit = loop_limit +1;
end
$display("Exp: %d",Exp);
if(Exp == 31) begin
  ovf1<= 1'b1;
  unf<=1'b0;
  FPSUM <= 16'h0000;
end

else if (Exp <= 5'b00000) begin
  unf<=1'b1;
  ovf <=1'b0;
  FPSUM <= 16'h0000;
end
else begin
  ovf <=1'b0;
  unf <= 1'b0;
  FPSUM <= {S1_St2,Exp,Frac[11:2]};
  end
  
 //$display("Exp: %h, Frac[24:2]: %h, FPSUM: %h",Exp,Frac[11:2],FPSUM);
end

endmodule
