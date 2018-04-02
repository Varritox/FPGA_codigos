`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    14:59:43 12/04/2016 
// Design Name: 
// Module Name:    prom 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module prom(
input [7:0]Vc,
input clk,
output reg [7:0]FVc,
input trig
    );

reg [7:0]Vc1,Vc2,Vc3,Vc4,Vc5,Vc6,Vc7,Vc8;
reg bo1,bo2;
wire ntrig;
reg[11:0] temp_vc;

always@(posedge clk) bo1<=trig;
always@(posedge clk) bo2<=bo1;
assign ntrig = !bo2&&bo1;

always@(posedge clk)
FVc <= temp_vc[7:0];

always@(posedge clk)
if(ntrig)
temp_vc <=((Vc+Vc1+Vc2+Vc3+Vc4+Vc5+Vc6+Vc7+Vc8)>>3);

always@(posedge clk) 
if(ntrig) Vc1<=Vc;
else Vc1 <= Vc1;

always@(posedge clk) 
if(ntrig) Vc2<=Vc1;
else Vc2 <= Vc2;

always@(posedge clk) 
if(ntrig) Vc3<=Vc2;
else Vc3 <= Vc3;

always@(posedge clk) 
if(ntrig) Vc4<=Vc3;
else Vc4 <= Vc4;

always@(posedge clk) 
if(ntrig) Vc5<=Vc4;
else Vc5 <= Vc5;

always@(posedge clk) 
if(ntrig) Vc6<=Vc5;
else Vc6 <= Vc6;

always@(posedge clk) 
if(ntrig) Vc7<=Vc6;
else Vc7 <= Vc7;

always@(posedge clk) 
if(ntrig) Vc8<=Vc7;
else Vc8 <= Vc8;




endmodule
