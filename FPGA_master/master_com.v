

module main_com_master(
clk,
rst,
fpga_out,
fpga_in,
Sstart,
sync_slave,
dspace_upper,
rst_slave,
frate_slave,
Vpa,
Vpb,
Vpc,
fin,
sw
);

//parameter dspace_rate = 750;//750 para 15 us casa 250 agrego o quito 5 us

parameter begin_trans = 4'd0;
parameter send_1 = 4'd1;
parameter send_2 = 4'd2;
parameter send_3 = 4'd3;
parameter send_4 = 4'd4;
parameter send_5 = 4'd5;
parameter send_6 = 4'd6;
parameter end_trans=4'd7;
parameter other_one=4'd8;

//parameter volt1 =8'd43;//1101_1101
//parameter volt2 = 8'd86;//0001_1010
//parameter volt3 = 8'd129;//1000_0111
//parameter volt4 = 8'd172;//0101_1110
//parameter volt5 = 8'd215;//0001_0000
//parameter volt6 = 8'd255;//1111_1000

input [1:0]sw;
output fin;
reg en1,en2;
parameter sinc_w = 4'b0000;
parameter sinc_f = 4'b1111;

output rst_slave;
input [7:0]Vpa,Vpb,Vpc;
wire [7:0]volt1,volt2,volt3;

assign volt1 = Vpa;
assign volt2 = Vpb;
assign volt3 = Vpc;
reg [10:0]dspace_rate;
reg [7:0]bit_rate_fpga;
input clk,rst,fpga_in;
output fpga_out,Sstart,sync_slave,frate_slave;
output [3:0] dspace_upper;
reg frate_slave;
reg Sstart;
reg [3:0] dspace_upper;
initial dspace_upper = 4'd0;
reg [3:0] est_com;
initial est_com = 4'd0;

reg [10:0] rate_counter;
initial rate_counter = 0;

wire flag_rate = (rate_counter == dspace_rate || rst);
wire Mstart;
wire beg_flag = (est_com == begin_trans || rst);
reg s1,s2;
wire [3:0]rxword1,rxword2,rxword3;
wire [3:0]txword1,txword2,txword3;
assign txword1 = volt1[7:4];
assign txword2 = volt2[7:4];
assign txword3 = volt3[7:4];
reg d1,d2,flag_rated;
reg Mstartd,Mstartd2;
//Modulo para intercambiar palabras entre fpga superior e inferior

always@(posedge clk)
case(sw)
0:begin 
	dspace_rate <= 500; //10us
	bit_rate_fpga <= 40;
  end
1:begin 
	dspace_rate <= 750; //15us
	bit_rate_fpga <= 60;
  end
2:begin 
	dspace_rate <= 1000; //20us
	bit_rate_fpga <= 75;
  end
3:begin 
	dspace_rate <= 1250; //25us
	bit_rate_fpga <= 95;
  end
default:
  begin 
	dspace_rate <= 750; //15us
	bit_rate_fpga <= 60;
  end
  endcase






always@(posedge clk)
if(flag_rate)frate_slave<=1;
else if(rate_counter==(dspace_rate>>1))frate_slave<=0;
else frate_slave<=frate_slave;

always@(posedge clk)if(est_com == end_trans)en1<=1;else en1<=0;
always@(posedge clk)en2<=en1;
assign fin = !en2&en1;


always@(posedge clk)d1<=flag_rate;
always@(posedge clk)d2<=d1;
always@(posedge clk)flag_rated<=d2;

dspace_com_master sub_master(
.clk(clk),
.rst(rst),
.fpga_in(fpga_in),
.fpga_out(fpga_out),
.reset_slave(rst_slave),
.Mstart(Mstartd2),
.sync_slave(sync_slave),
.rx_w1(rxword1),.rx_w2(rxword2),.rx_w3(rxword3),
.tx_w1(txword1),.tx_w2(txword2),.tx_w3(txword3),
.bit_rate_fpga(bit_rate_fpga)
);

always@(posedge clk)s1 <= beg_flag;
always@(posedge clk)s2 <= s1;

assign Mstart = !s2 && s1;
always@(posedge clk)Mstartd<=Mstart;
always@(posedge clk)Mstartd2<=Mstartd;


always@(posedge clk)
if(Mstart)Sstart <= 1;
else if(flag_rate) Sstart<=0;
else Sstart <= Sstart;

always@(posedge clk)
if(rst||rate_counter == dspace_rate||Mstartd2) rate_counter <= 0;
else rate_counter <= rate_counter + 1;

always@(posedge clk)
if(rst) est_com <= begin_trans;
else if(flag_rated)
	case(est_com)
		begin_trans:est_com <= send_1;
		send_1:est_com <= send_2;
		send_2:est_com <= send_3;
		send_3:est_com <= send_4;
		send_4:est_com <= send_5;
		send_5: est_com <= send_6;
		send_6:est_com <= end_trans;
		end_trans:est_com <= other_one;
		other_one:est_com <= begin_trans;
		default:est_com <= begin_trans;
	endcase
	else est_com<=est_com;
	//Envio a la dspace
always@(posedge clk)
if(flag_rate)
case(est_com)
begin_trans: dspace_upper <= sinc_w;
send_1:dspace_upper <= volt1[3:0]; //Vcpa
send_2:dspace_upper <= volt2[3:0]; //Vcpb
send_3:dspace_upper <= volt3[3:0]; //Vcpc
send_4:dspace_upper <= rxword1;
send_5:dspace_upper <= rxword2;
send_6:dspace_upper <= rxword3;
end_trans:dspace_upper <= sinc_f;
other_one:dspace_upper <= sinc_f;
default:dspace_upper <= sinc_w;
endcase
else 
dspace_upper<=dspace_upper;
endmodule
