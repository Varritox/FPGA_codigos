//Modulo encargado de la señales de disparo y del balance para el MMC parte positiva o negativa
//De acuerdo a los niveles de voltaje requeridos hay opciones de conmutación, por cada rama hay 5 niveles de voltaje disponibles por fase
// V   sa1 sb1 sa2 sb2
// 2:	1	0	1	0
// 1:	1	0	1	1
//		1	0	0	0
//		0	0	1	0
//		1	1	1	0
// 0:	1	1	1	1
//	:	0	0	0	0
//	:	0	1	1	0
//	:	1	0	0	1
//-1:	0	1	0	0 //descargo c1, mantengo c2 si I >0
//	:	0	1	1	1 //descargo c1, mantengo c2
//	:	0	0	0	1 //mantengo c1, descargo c2
//	:	1	1	0	1 // ""
//-2:	0	1	0	1
// celda 1 esta abajo de celda 2

module disparo (
input [7:0]va1,va2,vb1,vb2,vc1,vc2,
input clk,
input rst,
input [2:0] va_level,vb_level,vc_level, //Desde dspace niveles de voltaje deseados
input [2:0] signI,//desde dspace signo de corriente de cada fase
output reg[11:0]Fo_disparo,
input [7:0]Vcref,
input switch,
input [1:0] sel
);

///parameter period =  15'd5000 ; //frecuencia de conmutacion de celdas, clk es de 50 MHz, 20 ns 25.000 para 2 Khz, 10_000 para 5 Kh , 5000 para 10 kHz
reg [14:0]period;
wire [3:0]Foa,Fob,Foc; //{vx2,vx1}=xa2xb2_xa1xb1  
//reg [3:0]Foa_1,Fob_1,Foc_1;//Salida anterior para minimizar conmutaciones
reg [14:0] period_count;
initial Fo_disparo =12'b1010_1010_1010;

always@(posedge clk)
case (sel)
	0:period <=25000; //2Khz
	1:period <= 20000;//2.5 KHz
	2:period <= 10000;//5KHz
	3:period <= 5000; // 10KHz
	default:period <= 10000;
endcase
//initial Foa = 4'b1010;
//initial Fob = 4'b1010;
//initial Foc = 4'b1010;
//initial Foa_1 = 4'b1010;
//initial Fob_1 = 4'b1010;
//initial Foc_1 = 4'b1010;
initial period_count = 0;
wire period_flag;
assign period_flag = (period_count == period);

always@(posedge clk)
if(rst || period_count == period) period_count <= 0;
else period_count <= period_count + 1;

always@(posedge clk)
if(rst||switch)Fo_disparo <= 12'b1010_1010_1010;
else Fo_disparo <={Foc,Fob,Foa};

//always@(posedge clk)
//if(period_flag)
//begin
//	Foa_1<=Foa;
//	Fob_1<=Fob;
//	Foc_1<=Foc;
//end
//else 
//begin
//	Foa_1<=Foa_1;
//	Fob_1<=Fob_1;
//	Foc_1<=Foc_1;
//end

arm_balance phaseA (
    .clk(clk), 
    .rst(rst), 
	 .period_flag(period_flag),
    .signI(signI[0]), 
    .vc_level(va_level), 
    .vc1(va1), 
    .vc2(va2), 
    .Fo(Foa)
    );

arm_balance phaseB (
    .clk(clk), 
    .rst(rst), 
	 .period_flag(period_flag),
    .signI(signI[1]), 
    .vc_level(vb_level), 
    .vc1(vb1), 
    .vc2(vb2), 
    .Fo(Fob)
    );

arm_balance phaseC (
    .clk(clk), 
    .rst(rst), 
	 .period_flag(period_flag),
    .signI(signI[2]), 
    .vc_level(vc_level), 
    .vc1(vc1), 
    .vc2(vc2), 
    .Fo(Foc)
    );


/////////////////////////////////////////////////Fase A /////////////////////////////////////////////////////
//
//always@(posedge clk)
//if(rst) Foa <= Foa;
//else if(period_flag)
//	case(va_level)
//	0:Foa <= 4'b01_01;//-2vdc
//	1:case(signI[0])//generar -vdc
//		0:if(va2>va1) //Corriente positiva, descargo condensadores
//			if(Foa_1[1:0]==2'b11)
//				Foa<= 4'b01_11;
//			else 
//				Foa<=4'b01_00;
//		  else //va2<va1
//			if(Foa_1[3:2]==2'b11) 
//				Foa<= 4'b11_01;
//			else 
//				Foa<=4'b00_01;
//		1:if(va2>va1) //Corriente negativa, cargo condensadores para generar -vdc
//			if(Foa_1[3:2]==2'b11) //
//				Foa<= 4'b11_01;
//			else 
//				Foa<=4'b00_01;
//		  else
//			if(Foa_1[1:0]==2'b11)
//				Foa<= 4'b01_11;
//			else 
//				Foa<=4'b01_00;
//				endcase
//	2:case(signI[0])//generar 0 en este caso puedo cargar uno y descargar otro o dejar los 2 abiertos o cerrados si son iguales
//		0:if(va2<va1) //Corriente positiva
//				Foa<= 4'b10_01; //cargo va2 y descargo va1
//		  else if(va1==va2)
//				if(Foa_1[3:2]==2'b11)
//					if(Foa_1[1:0]==2'b11)
//						Foa<=4'b11_11;
//					else
//						Foa<=4'b11_00;
//				else
//					if(Foa_1[1:0]==2'b11)
//						Foa<=4'b00_11;
//					else
//						Foa<=4'b00_00;
//		  else //va1<va2
//			Foa<=4'b01_10; //cargo va1 y descargo va2
//	1:if(va2<va1) //Corriente negativa
//			Foa<= 4'b01_10; //cargo va2, descargo va1
//	  else if(va1==va2)
//			if(Foa_1[3:2]==2'b11)
//				if(Foa_1[1:0]==2'b11)
//						Foa<=4'b11_11;
//				else
//						Foa<=4'b11_00;
//			else
//				if(Foa_1[1:0]==2'b11)
//						Foa<=4'b00_11;
//				else
//						Foa<=4'b00_00;
//		else //va1<va2
//			Foa<=4'b10_01; //cargo va1 y descargo va2
//			endcase
//	3:case(signI[0]) ////////////////Vdc 4 opciones	
//		0:if(va2<va1)
//				if(Foa_1[1:0] == 2'b11)
//					Foa<=4'b10_11;
//				else
//					Foa<=4'b10_00;
//		  else //va2>va1
//				if(Foa_1[3:2] == 2'b11)
//					Foa<=4'b11_10;
//				else
//					Foa<=4'b00_10;
//			
//		1:if(va2<va1) //corriente negativa, descargo al generar Vdc
//				if(Foa_1[3:2] == 2'b11)
//					Foa<=4'b11_10;
//				else
//					Foa<=4'b00_10;
//		  else //va2>va1
//				if(Foa_1[1:0] == 2'b11)
//					Foa<=4'b10_11;
//				else
//					Foa<=4'b10_00;
//		endcase
//	4:Foa <= 4'b10_10;
//
//	default:Foa<=Foa;
//	endcase
//else
//	Foa<=Foa;
//
/////////////////////////////////////////////Fase B ///////////////////////////////////////////////////////////
//
//always@(posedge clk)
//if(rst) Fob <= Fob;
//else if(period_flag)
//	case(vb_level)
//	0:Fob <= 4'b01_01;//-2vdc
//	1:case(signI[1])//generar -vdc
//		0:if(vb2>vb1) //Corriente positivb, descargo condensadores
//			if(Fob_1[1:0]==2'b11)
//				Fob<= 4'b01_11;
//			else 
//				Fob<=4'b01_00;
//		  else //vb2<vb1
//			if(Fob_1[3:2]==2'b11) 
//				Fob<= 4'b11_01;
//			else 
//				Fob<=4'b00_01;
//		1:if(vb2>vb1) //Corriente negativb, cargo condensadores para generar -vdc
//			if(Fob_1[3:2]==2'b11) //
//				Fob<= 4'b11_01;
//			else 
//				Fob<=4'b00_01;
//		  else
//			if(Fob_1[1:0]==2'b11)
//				Fob<= 4'b01_11;
//			else 
//				Fob<=4'b01_00;
//			endcase
//	2:case(signI[1])//generar 0 en este caso puedo cargar uno y descargar otro o dejar los 2 abiertos o cerrados si son iguales
//		0:if(vb2<vb1) //Corriente positivb
//				Fob<= 4'b10_01; //cargo vb2 y descargo vb1
//		  else if(vb1==vb2)
//				if(Fob_1[3:2]==2'b11)
//					if(Fob_1[1:0]==2'b11)
//						Fob<=4'b11_11;
//					else
//						Fob<=4'b11_00;
//				else
//					if(Fob_1[1:0]==2'b11)
//						Fob<=4'b00_11;
//					else
//						Fob<=4'b00_00;
//		  else //vb1<vb2
//			Fob<=4'b01_10; //cargo vb1 y descargo vb2
//		1:if(vb2<vb1) //Corriente negativb
//				Fob<= 4'b01_10; //cargo vb2, descargo vb1
//		  else if(vb1==vb2)
//				if(Fob_1[3:2]==2'b11)
//					if(Fob_1[1:0]==2'b11)
//						Fob<=4'b11_11;
//					else
//						Fob<=4'b11_00;
//				else
//					if(Fob_1[1:0]==2'b11)
//						Fob<=4'b00_11;
//					else
//						Fob<=4'b00_00;
//		  else //vb1<vb2
//			Fob<=4'b10_01; //cargo vb1 y descargo vb2
//		endcase
//	3:case(signI[1]) ////////////////Vdc 4 opciones	
//		0:if(vb2<vb1)
//				if(Fob_1[1:0] == 2'b11)
//					Fob<=4'b10_11;
//				else
//					Fob<=4'b10_00;
//		  else //vb2>vb1
//				if(Fob_1[3:2] == 2'b11)
//					Fob<=4'b11_10;
//				else
//					Fob<=4'b00_10;
//			
//		1:if(vb2<vb1) //corriente negativb, descargo al generar Vdc
//				if(Fob_1[3:2] == 2'b11)
//					Fob<=4'b11_10;
//				else
//					Fob<=4'b00_10;
//		  else //vb2>vb1
//				if(Fob_1[1:0] == 2'b11)
//					Fob<=4'b10_11;
//				else
//					Fob<=4'b10_00;
//				endcase
//	4:Fob <= 4'b10_10;
//
//	default:Fob<=Fob;
//	endcase
//else
//Fob<=Fob;
//
/////////////////////////////////////////////Fase C /////////////////////////////////////////7
//
//always@(posedge clk)
//if(rst) Foc <= Foc;
//else if(period_flag)
//	case(vc_level)
//	0:Foc <= 4'b01_01;//-2vdc
//	1:case(signI[2])//generar -vdc
//		0:if(vc2>vc1) //Corriente positivc, descargo condensadores
//			if(Foc_1[1:0]==2'b11)
//				Foc<= 4'b01_11;
//			else 
//				Foc<=4'b01_00;
//		  else //vc2<vc1
//			if(Foc_1[3:2]==2'b11) 
//				Foc<= 4'b11_01;
//			else 
//				Foc<=4'b00_01;
//		1:if(vc2>vc1) //Corriente negativc, cargo condensadores para generar -vdc
//			if(Foc_1[3:2]==2'b11) //
//				Foc<= 4'b11_01;
//			else 
//				Foc<=4'b00_01;
//		  else
//			if(Foc_1[1:0]==2'b11)
//				Foc<= 4'b01_11;
//			else 
//				Foc<=4'b01_00;
//			endcase
//	2:case(signI[2])//generar 0 en este caso puedo cargar uno y descargar otro o dejar los 2 abiertos o cerrados si son iguales
//		0:if(vc2<vc1) //Corriente positivc
//				Foc<= 4'b10_01; //cargo vc2 y descargo vc1
//		  else if(vc1==vc2)
//				if(Foc_1[3:2]==2'b11)
//					if(Foc_1[1:0]==2'b11)
//						Foc<=4'b11_11;
//					else
//						Foc<=4'b11_00;
//				else
//					if(Foc_1[1:0]==2'b11)
//						Foc<=4'b00_11;
//					else
//						Foc<=4'b00_00;
//		  else //vc1<vc2
//			Foc<=4'b01_10; //cargo vc1 y descargo vc2
//		1:if(vc2<vc1) //Corriente negativc
//				Foc<= 4'b01_10; //cargo vc2, descargo vc1
//		  else if(vc1==vc2)
//				if(Foc_1[3:2]==2'b11)
//					if(Foc_1[1:0]==2'b11)
//						Foc<=4'b11_11;
//					else
//						Foc<=4'b11_00;
//				else
//					if(Foc_1[1:0]==2'b11)
//						Foc<=4'b00_11;
//					else
//						Foc<=4'b00_00;
//		  else //vc1<vc2
//			Foc<=4'b10_01; //cargo vc1 y descargo vc2
//		endcase
//	3:case(signI[2]) ////////////////Vdc 4 opciones	
//		0:if(vc2<vc1)
//				if(Foc_1[1:0] == 2'b11)
//					Foc<=4'b10_11;
//				else
//					Foc<=4'b10_00;
//		  else //vc2>vc1
//				if(Foc_1[3:2] == 2'b11)
//					Foc<=4'b11_10;
//				else
//					Foc<=4'b00_10;
//			
//		1:if(vc2<vc1) //corriente negativc, descargo al generar Vdc
//				if(Foc_1[3:2] == 2'b11)
//					Foc<=4'b11_10;
//				else
//					Foc<=4'b00_10;
//		  else //vc2>vc1
//				if(Foc_1[1:0] == 2'b11)
//					Foc<=4'b10_11;
//				else
//					Foc<=4'b10_00;
//			endcase
//	4:Foc <= 4'b10_10;
//	default:Foc<=Foc;
//	endcase
//else
//Foc<=Foc;


endmodule
