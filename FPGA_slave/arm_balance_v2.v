`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    16:26:41 11/15/2017 
// Design Name: 
// Module Name:    arm_balance 
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
module arm_balance(
input clk,
input rst,
input period_flag,
input signI,
input [2:0]vc_level,
input [7:0]vc1, vc2,
output reg [3:0]Fo
    );

reg[3:0] Fo_1;
initial Fo_1 = 4'b1010;
always@(posedge clk)
if(period_flag)
	Fo_1<=Fo;
else 
	Fo_1<=Fo_1;

always@(posedge clk)
if(rst) Fo <= Fo;
else if(period_flag)
	case(vc_level)
	0:Fo <= 4'b01_01;//-2vdc
	1:case(signI)//generar -vdc
		0:if(vc2>vc1) //Corriente positivc, descargo condensadores
				Fo<= 4'b01_11;
		  else //vc2<vc1
				Fo<=4'b00_01;
		1:if(vc2>vc1) //Corriente negativc, cargo condensadores para generar -vdc
				Fo<= 4'b11_01;
		  else
				Fo<= 4'b01_11;
		
	endcase
	2:Fo<=4'b0000;
	/*case(signI)//generar 0 en este caso puedo cargar uno y descargar otro o dejar los 2 abiertos o cerrados si son iguales
		0:if(vc2<vc1) //Corriente positivc
				Fo<= 4'b10_01; //cargo vc2 y descargo vc1
		  else if(vc1==vc2)
				if(Fo_1[3:2]==2'b11)
					if(Fo_1[1:0]==2'b11)
						Fo<=4'b11_11;
					else
						Fo<=4'b11_00;
				else
					if(Fo_1[1:0]==2'b11)
						Fo<=4'b00_11;
					else
						Fo<=4'b00_00;
		  else //vc1<vc2
			Fo<=4'b01_10; //cargo vc1 y descargo vc2
	1:if(vc2<vc1) //Corriente negativc
			Fo<= 4'b01_10; //cargo vc2, descargo vc1
	  else if(vc1==vc2)
			if(Fo_1[3:2]==2'b11)
				if(Fo_1[1:0]==2'b11)
						Fo<=4'b11_11;
				else
						Fo<=4'b11_00;
			else
				if(Fo_1[1:0]==2'b11)
						Fo<=4'b00_11;
				else
						Fo<=4'b00_00;
		else //vc1<vc2
			Fo<=4'b10_01; //cargo vc1 y descargo vc2
			endcase*/
	3:case(signI) ////////////////Vdc 4 opciones	
		0:if(vc2<vc1)
					Fo<=4'b10_11;
		  else //vc2>vc1
					Fo<=4'b11_10;
			
		1:if(vc2<vc1) //corriente negativc, descargo al generar Vdc
					Fo<=4'b00_10;
		  else //vc2>vc1
					Fo<=4'b10_00;
		endcase
	4:Fo <= 4'b10_10;

	default:Fo<=Fo;
	endcase
else
	Fo<=Fo;


endmodule
