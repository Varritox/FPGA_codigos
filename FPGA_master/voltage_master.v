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

//Voltages en el maestro corresponden a los de la rama positiva del MMC Vcpa1,Vc2,Vcpb1,Vcpb2,Vcpc1,Vcpc2;
module MMC_voltage_master(
input clk,
input rst,
output [3:0]dspace_upper,
output fpga_out,
input fpga_in,
output sync_slave,
output rst_slave,
output Start_switch,
input conmutacion,
output Sstart,
input [5:0]RXFO,
output [7:0]LCD_DB,
output LCD_E,LCD_RW,LCD_RS,
output [7:0]LED,
input [11:0]dspace_in,
output [11:0]TXFO,
input [3:0] SW
);

parameter delay_lcd = 25'd15_000_000;
parameter maxV = 8'd230;
wire [7:0]Vc2,Vc3,Vc6,Vc7,Vc10,Vc11;
wire [7:0]FVc2,FVc3,FVc6,FVc7,FVc10,FVc11;


wire [5:0] ready_pic_read;
wire end_trans;
wire [8:0] V_prom_pos_a,V_prom_pos_b,V_prom_pos_c;
reg fpga_inF;
wire pic_clk,clk_50;
reg [255:0]chars;
assign LCD_DB[3:0] = 4'hf;
wire [39:0]pol;
wire [39:0]pol2;
assign pol ="pos: ";
assign pol2 ="volt:";

//Envio de datos a la dspace y entre fpga
wire [1:0] cien_v2,cien_v3,cien_v6,cien_v7,cien_v10,cien_v11;
wire [3:0] diez_v2,diez_v3,diez_v6,diez_v7,diez_v10,diez_v11;
wire [3:0] unos_v2,unos_v3,unos_v6,unos_v7,unos_v10,unos_v11;

reg[24:0] lcd_act;
initial lcd_act = 0;
wire lcd_flag;
assign lcd_flag = lcd_act==delay_lcd;

assign LED[6:0] = {1'b0,ready_pic_read};
wire [2:0] st1,st2,st3,st4,st5,st6;
reg [5:0]rxdata;

wire[23:0] med1;
wire[23:0] med2;
wire[23:0] med3;
wire[23:0] med4;
wire[23:0] med5;
wire[23:0] med6;
reg c1,c2;
wire c3;
reg enable_switch;
initial enable_switch = 0;
reg[2:0]level_a,level_b,level_c;
reg[2:0]I;
wire [7:0]ia,va,vc,vb,ib,ic;

reg OV;
assign LED[7] = OV;

assign ia = {4'h3,3'd0,I[0]};
assign va = {4'h3,1'd0,level_a};

assign ib = {4'h3,3'd0,I[1]};
assign vb = {4'h3,1'd0,level_b};

assign ic = {4'h3,3'd0,I[2]};
assign vc = {4'h3,1'd0,level_c};


	assign med1 = {4'h3,2'b00,cien_v3,4'h3,diez_v3,4'h3,unos_v3};
	assign med2 = {4'h3,2'b00,cien_v7,4'h3,diez_v7,4'h3,unos_v7};
	assign med3 = {4'h3,2'b00,cien_v11,4'h3,diez_v11,4'h3,unos_v11};
	assign med4 = {4'h3,2'b00,cien_v2,4'h3,diez_v2,4'h3,unos_v2};
	assign med5 = {4'h3,2'b00,cien_v6,4'h3,diez_v6,4'h3,unos_v6};
	assign med6 = {4'h3,2'b00,cien_v10,4'h3,diez_v10,4'h3,unos_v10};


assign V_prom_pos_a = (FVc2+FVc3)>>1; // Voltage promedio entre 2 celdas
assign V_prom_pos_b = (FVc6+FVc7)>>1; // Voltage promedio entre 2 celdas
assign V_prom_pos_c = (FVc10+FVc11)>>1; // Voltage promedio entre 2 celdas


always@(posedge clk_50)c1<=conmutacion;


always@(posedge clk_50) enable_switch <= c1;


assign Start_switch = enable_switch;

always@(posedge clk_50)
rxdata <= RXFO;
//magic
always@(posedge clk_50)
	I <= {dspace_in[8],dspace_in[4],dspace_in[0]};
always@(posedge clk_50)
	level_a <= dspace_in[3:1];	
always@(posedge clk_50)
	level_b <= dspace_in[7:5];	
always@(posedge clk_50)
	level_c <= dspace_in[11:9];	
	
always@(posedge clk_50)
fpga_inF<=fpga_in;
//ralentiza cambios en el display para que sea mas entendible
always@(posedge clk_50)
if(rst||lcd_act==delay_lcd)lcd_act <= 0;
else lcd_act <= lcd_act +1;

always@(posedge clk_50)
if(lcd_flag)
	if(SW[3])
	 chars[255:0] <= {"LA:",va," Ia:",ia," LB:",vb,"  Ib:",ib," LC:",vc," Ic:",ic,"  "};
	else
	  chars[255:0] <={pol,med1,",",med2,",",med3,pol2,med4,",",med5,",",med6};
else
	chars<=chars;
	

pic_clk clk_8(
    .CLKIN_IN(clk), 
    .RST_IN(), 
    .CLKDV_OUT(pic_clk), 
	 .CLKIN_IBUFG_OUT(), 
    .CLK0_OUT(clk_50)
    );

main_com_master mast(
.clk(clk_50),
.rst(rst),
.fpga_out(fpga_out),
.fpga_in(fpga_inF),
.Sstart(Sstart),
.sync_slave(sync_slave),
.dspace_upper(dspace_upper),
.rst_slave(rst_slave),
.frate_slave(frate_slave),
.Vpa(V_prom_pos_a[7:0]),
.Vpb(V_prom_pos_b[7:0]),
.Vpc(V_prom_pos_c[7:0]),
.fin(end_trans),
.sw(2'b11)
);

bin2bcd vp2(FVc2,unos_v2,diez_v2,cien_v2);	
bin2bcd vp3(FVc3,unos_v3,diez_v3,cien_v3);	
bin2bcd vp6(FVc6,unos_v6,diez_v6,cien_v6);	
bin2bcd vp7(FVc7,unos_v7,diez_v7,cien_v7);	
bin2bcd vp10(FVc10,unos_v10,diez_v10,cien_v10);	
bin2bcd vp11(FVc11,unos_v11,diez_v11,cien_v11);	

//assign chars[256:0] ={pol,med1,",",med2,",",med3,pol2,med4,",",med5,",",med6};

LCDv2 lcd(clk_50,	chars,LCD_RS, LCD_RW, LCD_E, LCD_DB[4], LCD_DB[5], LCD_DB[6], LCD_DB[7]);

//Lectura de voltajes por parte del pic

uart_8bit v2read(.Rx_data(rxdata[0]),.clk(pic_clk),.Rx_reg(Vc2),.reset(rst),.listo(ready_pic_read[0]),.estado(st1));
uart_8bit v3read(.Rx_data(rxdata[1]),.clk(pic_clk),.Rx_reg(Vc3),.reset(rst),.listo(ready_pic_read[1]),.estado(st2));
uart_8bit v6read(rxdata[2],pic_clk,Vc6,rst,ready_pic_read[2],st3);
uart_8bit v7read(rxdata[3],pic_clk,Vc7,rst,ready_pic_read[3],st4);
uart_8bit v10read(rxdata[4],pic_clk,Vc10,rst,ready_pic_read[4],st5);
uart_8bit v11read(rxdata[5],pic_clk,Vc11,rst,ready_pic_read[5],st6);
always@(posedge clk_50)
if(rst)OV<= 0;
else if(FVc2>maxV || FVc3 > maxV || FVc6 > maxV || FVc7 > maxV || FVc10 > maxV || FVc11 > maxV)
OV <= 1;
else OV<= 0;
disparo shoots (
    .va1(FVc2), 
    .va2(FVc3), 
    .vb1(FVc6), 
    .vb2(FVc7), 
    .vc1(FVc10), 
    .vc2(FVc11), 
    .clk(clk_50), 
    .rst(rst), 
    .va_level(level_a), 
    .vb_level(level_b), 
    .vc_level(level_c), 
    .signI(I), 
    .Fo_disparo(TXFO), 
    .Vcref(Vcref),
	 .switch(enable_switch||OV),
	 .sel(SW[2:1])
    );
	 
prom Vc2_prom (
    .Vc(Vc2), 
    .clk(clk_50), 
    .FVc(FVc2), 
    .trig(ready_pic_read[0])
    );

prom Vc3_prom (
    .Vc(Vc3), 
    .clk(clk_50), 
    .FVc(FVc3), 
    .trig(ready_pic_read[1])
    );
prom Vc6_prom (
    .Vc(Vc6), 
    .clk(clk_50), 
    .FVc(FVc6), 
    .trig(ready_pic_read[2])
    );

prom Vc7_prom (
    .Vc(Vc7), 
    .clk(clk_50), 
    .FVc(FVc7), 
    .trig(ready_pic_read[3])
    );
prom Vc10_prom (
    .Vc(Vc10), 
    .clk(clk_50), 
    .FVc(FVc10), 
    .trig(ready_pic_read[4])
    );

prom Vc11_prom (
    .Vc(Vc11), 
    .clk(clk_50), 
    .FVc(FVc11), 
    .trig(ready_pic_read[5])
    );
/*

fir_vc vc2 (
    .clk(clk_50), 
    .trig(ready_pic_read[0]), 
    .Vc(Vc2), 
    .FVc(FVc2)
    );

fir_vc vc3 (
    .clk(clk_50), 
    .trig(ready_pic_read[1]), 
    .Vc(Vc3), 
    .FVc(FVc3)
    );
	 
fir_vc vc6 (
    .clk(clk_50), 
    .trig(ready_pic_read[2]), 
    .Vc(Vc6), 
    .FVc(FVc6)
    );
	 fir_vc vc7 (
    .clk(clk_50), 
    .trig(ready_pic_read[3]), 
    .Vc(Vc7), 
    .FVc(FVc7)
    );
	 
	 fir_vc vc10 (
    .clk(clk_50), 
    .trig(ready_pic_read[4]), 
    .Vc(Vc10), 
    .FVc(FVc10)
    );
	 fir_vc vc11 (
    .clk(clk_50), 
    .trig(ready_pic_read[5]), 
    .Vc(Vc11), 
    .FVc(FVc11)
    );
	 */
endmodule
