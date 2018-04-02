

module slave_com(
clk,
rst,
rst_slave,
fpga_out,
fpga_in,
Sstart,
sync_slave,
dspace_lower,
Vna,
Vnb,
Vnc,
fin,
sw
);
//parameter dspace_rate = 750;//1500 para 30 us
//parameter bit_rate_fpga = 60;
parameter begin_trans = 4'd0;
parameter send_1 = 4'd1;
parameter send_2 = 4'd2;
parameter send_3 = 4'd3;
parameter send_4 = 4'd4;
parameter send_5 = 4'd5;
parameter send_6 = 4'd6;
parameter end_trans =4'd7;
parameter other_one =4'd8;

/*
parameter volt1 = 8'd172;//0101_1110
parameter volt2 = 8'd215;//0001_0000
parameter volt3 = 8'd254;//1111_1000
parameter volt4 =8'd43;//1101_1101
parameter volt5 = 8'd86;//0001_1010
parameter volt6 = 8'd129;//1000_0111
*/
parameter sinc_f = 4'b1111;

parameter sinc_w = 4'b0000;
input [7:0]Vna,Vnb,Vnc;
input [1:0]sw;
wire [7:0]volt1,volt2,volt3;
output fin;

reg [10:0]dspace_rate;
reg [7:0]bit_rate_fpga;

assign volt1 = Vna;
assign volt2 = Vnb;
assign volt3 = Vnc;

input clk,rst,fpga_in,Sstart,sync_slave,rst_slave;
output fpga_out;
output [3:0] dspace_lower;

reg [3:0] dspace_lower;
initial dspace_lower = 4'd0;

reg [3:0] est_com;
initial est_com = 4'd0;

reg [10:0] rate_counter;
initial rate_counter = 0;
wire flag_rate;

assign flag_rate = (rate_counter == dspace_rate || rst || rst_slave);

reg s1,s2;
wire [3:0]rxword1,rxword2,rxword3;
wire [3:0]txword1,txword2,txword3;

assign txword1 = volt1[3:0];
assign txword2 = volt2[3:0];
assign txword3 = volt3[3:0];
wire slave_start;
reg en1,en2;

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
always@(posedge clk)if(est_com == end_trans)en1<=1;else en1<=0;
always@(posedge clk)en2<=en1;
assign fin = !en2&en1;




always@(posedge clk) s1<=Sstart;
always@(posedge clk) s2<= s1;
assign slave_start = !s2&&s1;

/*
always@(posedge clk) f1<=frate;
always@(posedge clk) f2<= f1;
assign flag_rate = !f2&&f1;
*/
reg s3,s4;
wire syncs_slave;
always@(posedge clk) s3<=sync_slave;
always@(posedge clk) s4<= s3;
assign syncs_slave = !s4&&s3;

dspace_com_slave sub_slave(
 .clk(clk),
 .rst(rst||rst_slave),
 .fpga_in(fpga_in),
 .fpga_out(fpga_out),
 .Sstart(slave_start),
 .sync_slave(syncs_slave),
 .rx_w1(rxword1),.rx_w2(rxword2),.rx_w3(rxword3),
.tx_w1(txword1),.tx_w2(txword2),.tx_w3(txword3),
.bit_rate_fpga(bit_rate_fpga)
);

always@(posedge clk)
if(rst||rate_counter == dspace_rate||rst_slave||slave_start) rate_counter <= 0;
else rate_counter <= rate_counter + 1;


always@(posedge clk)
if(rst||rst_slave||slave_start) est_com <= begin_trans;
else if(flag_rate)
	case(est_com)
		begin_trans:est_com <= send_1;
		send_1:est_com <= send_2;				
		send_2:est_com <= send_3;			
		send_3:est_com <= send_4;					
		send_4: est_com <= send_5;				
		send_5:est_com <= send_6;					
		send_6:est_com <= end_trans;	
		end_trans:est_com <=other_one;
		other_one:est_com<=begin_trans;//estado para compensar error de lecturas en dspace
		default:est_com <= begin_trans;
	endcase
else est_com<=est_com;
	
always@(posedge clk)
if(flag_rate)
	case(est_com)
	begin_trans: dspace_lower <= sinc_w;
	send_1:dspace_lower <= rxword1; //Vcpa
	send_2:dspace_lower <= rxword2; //Vcpb
	send_3:dspace_lower <= rxword3; //Vcpc
	send_4:dspace_lower <= volt1[7:4];
	send_5:dspace_lower <= volt2[7:4];
	send_6:dspace_lower <= volt3[7:4];
	end_trans:dspace_lower <= sinc_f;
	other_one:dspace_lower <= sinc_f;
	default:dspace_lower <= sinc_w;
	endcase
else 
dspace_lower<=dspace_lower;

endmodule
