`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    18:27:40 08/29/2017 
// Design Name: 
// Module Name:    voltage_master 
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

//Voltages en el maestro corresponden a los de la rama positiva del MMC Vcpa1,Vcpa2,Vcpb1,Vcpb2,Vcpc1,Vcpc2;
module voltage_slave_mmc(
input clk,
input rst,
output [3:0]dspace_low,
output [11:0]TXFO,
output fpga_out,
input fpga_in,
input sync_slave,
input rst_slave,
input Start_switch,
input Sstart,
input [5:0]RXFO,
output [7:0]LED,
output [7:0]LCD_DB,
input [11:0]dspace_in,
input [3:0] SW,
output LCD_E,LCD_RW,LCD_RS
);
parameter delay_lcd = 25'd15_000_000;
parameter maxV = 8'd230;
//input clk,rst,fpga_in,sync_slave,rst_slave,Sstart,frate_slave;
//output fpga_out;
//input[5:0]RXFO; //Lecturas serial de FO desde el pic, celdas
//output [3:0] dspace_low;//Salidas hacia la dspace de lectura de voltage
//output [11:0] TXFO; //disparo de celdas
wire [7:0]Vc0,Vc1,Vc4,Vc5,Vc8,Vc9;
wire [7:0]FVc0,FVc1,FVc4,FVc5,FVc8,FVc9;

wire [5:0] ready_pic_read;
wire [39:0]pol;
wire [39:0]pol2;
reg [255:0] chars;
wire [8:0] V_prom_neg_a,V_prom_neg_b,V_prom_neg_c;
wire [1:0] cien_v0,cien_v1,cien_v4,cien_v5,cien_v8,cien_v9;
wire [3:0] diez_v0,diez_v1,diez_v4,diez_v5,diez_v8,diez_v9;
wire [3:0] unos_v0,unos_v1,unos_v4,unos_v5,unos_v8,unos_v9;
wire clk_50,pic_clk;
reg [5:0]rxdata;
reg fpga_inF,SstartF,sync_slaveF,rst_slaveF,frate_slaveF;
reg [11:0]dspace_inF;


assign pol="neg: ";
assign pol2="volt:";
assign LED[6:0] = {1'b0,ready_pic_read};
reg OV;
assign LED[7] = OV;
reg[24:0] lcd_act;
initial lcd_act = 0;
wire lcd_flag;
assign lcd_flag = lcd_act==delay_lcd;

//initial med_volt = 6'd0;

wire [23:0] med1;
wire[23:0] med2;
wire[23:0] med3;
wire[23:0] med4;
wire[23:0] med5;
wire[23:0] med6;
//Envio de datos a la dspace y entre fpga
reg[2:0]level_a,level_b,level_c;
reg[2:0]I;

reg enable_switch;
wire [7:0]ia,va,vc,vb,ib,ic;
wire [7:0] txa,txb,txc;
assign txa = {4'h3,TXFO[3:0]};
assign txb = {4'h3,TXFO[7:4]};
assign txc = {4'h3,TXFO[11:8]};



assign ia = {4'h3,3'd0,I[0]};
assign va = {4'h3,1'd0,level_a};

assign ib = {4'h3,3'd0,I[1]};
assign vb = {4'h3,1'd0,level_b};

assign ic = {4'h3,3'd0,I[2]};
assign vc = {4'h3,1'd0,level_c};

	assign med1 = {4'h3,2'b00,cien_v0,4'h3,diez_v0,4'h3,unos_v0};
	assign med2 = {4'h3,2'b00,cien_v1,4'h3,diez_v1,4'h3,unos_v1};
	assign med3 = {4'h3,2'b00,cien_v4,4'h3,diez_v4,4'h3,unos_v4};
	assign med4 = {4'h3,2'b00,cien_v5,4'h3,diez_v5,4'h3,unos_v5};
	assign med5 = {4'h3,2'b00,cien_v8,4'h3,diez_v8,4'h3,unos_v8};
	assign med6 = {4'h3,2'b00,cien_v9,4'h3,diez_v9,4'h3,unos_v9};
	
always@(posedge clk_50)
dspace_inF[11:0] <= dspace_in[11:0];

	always@(posedge clk_50)
	enable_switch <= Start_switch;
always@(posedge clk_50)
rxdata <= RXFO;

always@(posedge clk_50)
if(rst||lcd_act==delay_lcd)lcd_act <= 0;
else lcd_act <= lcd_act +1;

always@(posedge clk_50)
begin
fpga_inF <= fpga_in;
sync_slaveF<= sync_slave;
rst_slaveF <= rst_slave;
SstartF <= Sstart;
end
always@(posedge clk_50)
if(lcd_flag)
	if(SW[3])
	 chars[255:0] <= {"LA:",va," Ia:",ia," LB:",vb,"  Ib:",ib," LC:",vc," Ic:",ic,"  "}; 
	 //chars[255:0] <= {"A",va,4'h3,3'd0,dspace_inF[3],4'h3,3'd0,dspace_inF[2],4'h3,3'd0,dspace_inF[1],4'h3,3'd0,dspace_inF[0]," B",vb,4'h3,3'd0,dspace_inF[7],4'h3,3'd0,dspace_inF[6],4'h3,3'd0,dspace_inF[5],4'h3,3'd0,dspace_inF[4],"   C",vc,4'h3,3'd0,dspace_inF[11],4'h3,3'd0,dspace_inF[10],4'h3,3'd0,dspace_inF[9],4'h3,3'd0,dspace_inF[8],"          "}; 
	else
	  chars[255:0] <={pol,med2,",",med4,",",med6,pol2,med1,",",med3,",",med5};
else
	chars<=chars;
assign V_prom_neg_a = (FVc0+FVc1)>>1; // Voltage promedio entre 2 celdas
assign V_prom_neg_b = (FVc4+FVc5)>>1; // Voltage promedio entre 2 celdas
assign V_prom_neg_c = (FVc8+FVc9)>>1; // Voltage promedio entre 2 celdas

always@(posedge clk_50)
	I <= {dspace_inF[8],dspace_inF[4],dspace_inF[0]};
always@(posedge clk_50)
	level_a <= dspace_inF[3:1];	
always@(posedge clk_50)
	level_b <= dspace_inF[7:5];	
always@(posedge clk_50)
	level_c <= dspace_inF[11:9];	

pic_clk reloj_clk (
    .CLKIN_IN(clk), 
    .RST_IN(), 
    .CLKDV_OUT(pic_clk), 
    .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(clk_50)
    );

slave_com slave(
.clk(clk_50),
.rst(rst),
.rst_slave(rst_slaveF),
.fpga_out(fpga_out),
.fpga_in(fpga_inF),
.Sstart(SstartF),
.sync_slave(sync_slaveF),
.dspace_lower(dspace_low),
.Vna(V_prom_neg_a[7:0]),
.Vnb(V_prom_neg_b[7:0]),
.Vnc(V_prom_neg_c[7:0]),
.fin(),
.sw(2'b11)
);
//
bin2bcd v0(FVc0,unos_v0,diez_v0,cien_v0);	
bin2bcd v1(FVc1,unos_v1,diez_v1,cien_v1);	
bin2bcd v4(FVc4,unos_v4,diez_v4,cien_v4);	
bin2bcd v5(FVc5,unos_v5,diez_v5,cien_v5);	
bin2bcd v8(FVc8,unos_v8,diez_v8,cien_v8);	
bin2bcd v9(FVc9,unos_v9,diez_v9,cien_v9);	

//Lectura de V2 celda 2
uart_8bit v0read(rxdata[0],pic_clk,Vc0,rst||rst_slave,ready_pic_read[0]);
uart_8bit v1read(rxdata[1],pic_clk,Vc1,rst||rst_slave,ready_pic_read[1]);
uart_8bit v4read(rxdata[2],pic_clk,Vc4,rst||rst_slave,ready_pic_read[2]);
uart_8bit v5read(rxdata[3],pic_clk,Vc5,rst||rst_slave,ready_pic_read[3]);
uart_8bit v8read(rxdata[4],pic_clk,Vc8,rst||rst_slave,ready_pic_read[4]);
uart_8bit v9read(rxdata[5],pic_clk,Vc9,rst||rst_slave,ready_pic_read[5]);

always@(posedge clk_50)
if(rst) OV<= 0;
else if(FVc0 > maxV || FVc1 > maxV || FVc4 > maxV || FVc5 > maxV || FVc8 > maxV || FVc9 > maxV)
	OV<= 1;
else OV<= 0;
//pol,4'h3,2'b00,cien_v1,4'h3,diez_v1,4'h3,unos_v1,",",4'h3,2'b00,cien_v5,4'h3,diez_v5,4'h3,unos_v5,",",4'h3,2'b00,cien_v9,4'h3,diez_v9,4'h3,unos_v9

                     //pol2,4'h3,2'b00,cien_v0,4'h3,diez_v0,4'h3,unos_v0,",",4'h3,2'b00,cien_v4,4'h3,diez_v4,4'h3,unos_v4,",",4'h3,2'b00,cien_v8,4'h3,diez_v8,4'h3,unos_v8
assign LCD_DB[3:0] = 4'hf;

LCDv2 lcd(clk_50,	chars,LCD_RS, LCD_RW, LCD_E, LCD_DB[4], LCD_DB[5], LCD_DB[6], LCD_DB[7]);

disparo shoots_negative (
    .va1(FVc0), 
    .va2(FVc1), 
    .vb1(FVc4), 
    .vb2(FVc5), 
    .vc1(FVc8), 
    .vc2(FVc9), 
    .clk(clk_50), 
    .rst(rst), 
    .va_level(level_a), 
    .vb_level(level_b), 
    .vc_level(level_c), 
    .signI(I), 
    .Fo_disparo(TXFO), 
	 .switch(enable_switch||OV),
	 .sel(SW[2:1])
    );


prom Vc0_prom (
    .Vc(Vc0), 
    .clk(clk_50), 
    .FVc(FVc0), 
    .trig(ready_pic_read[0])
    );

prom Vc1_prom (
    .Vc(Vc1), 
    .clk(clk_50), 
    .FVc(FVc1), 
    .trig(ready_pic_read[1])
    );
prom Vc4_prom (
    .Vc(Vc4), 
    .clk(clk_50), 
    .FVc(FVc4), 
    .trig(ready_pic_read[2])
    );

prom Vc5_prom (
    .Vc(Vc5), 
    .clk(clk_50), 
    .FVc(FVc5), 
    .trig(ready_pic_read[3])
    );
prom Vc8_prom (
    .Vc(Vc8), 
    .clk(clk_50), 
    .FVc(FVc8), 
    .trig(ready_pic_read[4])
    );

prom Vc9_prom (
    .Vc(Vc9), 
    .clk(clk_50), 
    .FVc(FVc9), 
    .trig(ready_pic_read[5])
    );

endmodule
