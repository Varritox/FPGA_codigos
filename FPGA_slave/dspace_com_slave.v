

//Master fpga
module dspace_com_slave(
 clk,
 rst,
 fpga_in,
 fpga_out,
 Sstart,
 sync_slave,
  rx_w1,rx_w2,rx_w3,
 tx_w1,tx_w2,tx_w3,
 bit_rate_fpga
);
//estados de envio y recepcion entre fpga's
input [7:0]bit_rate_fpga;
parameter wait_ex = 3'd0;
parameter start_ex = 3'd1;
parameter end_ex = 3'd2;
/*
parameter w1 = 4'b0101;
parameter w2 = 4'b0111;
parameter w3 = 4'b1101;
*/
output [3:0] rx_w1,rx_w2,rx_w3;
input [3:0] tx_w1,tx_w2,tx_w3;
input Sstart;//Indica inicio de comunicacion al esclavo
input clk,rst,fpga_in; 
output fpga_out;
input sync_slave;

//comienza el intercambio de bits una vez terminado el envio hacia la dspace
//Maestro controla los parametros de sincronizacion,
//primero se inicia la transmision,
reg sync_rx;
wire [3:0]w1rx,w2rx,w3rx;
reg [3:0]rx_w1,rx_w2,rx_w3;
reg [7:0] sinc_counter;
initial sinc_counter = 0;

reg [2:0] ex_estados;

initial ex_estados = wait_ex;

wire ready_tx,ready_rx;
reg Rtx,Rrx;

fpga_tx_com fpga_tx(.clk(clk),.reset(rst),.word1(tx_w1),.word2(tx_w2),.word3(tx_w3),.sync_tx(sync_slave),.tx(fpga_out),.ready_tx(ready_tx),.start_tx(Sstart));

fpga_rx_com fpga_rx(.clk(clk),.reset(rst),.word1(w1rx),.word2(w2rx),.word3(w3rx),.sync_rx(sync_rx),.rx(fpga_in),.ready_rx(ready_rx),.start_rx(Sstart));


always@(posedge clk)
if(rst) sync_rx <= 0;
else if(sinc_counter == bit_rate_fpga>>1) sync_rx <= 1;
else sync_rx <= 0;


always@(posedge clk)
if(rst||sinc_counter == ((bit_rate_fpga>>1)+1)||Sstart)sinc_counter <= 0;
else if(sync_slave) sinc_counter <= 1;
else if(sinc_counter >= 1)sinc_counter <= sinc_counter +1;
else sinc_counter <= sinc_counter;



always@(posedge clk)
if(ex_estados == start_ex && ready_tx)Rtx <= 1;
else if (ex_estados == end_ex)Rtx <=0;
else Rtx <= Rtx;
always@(posedge clk)
if(ex_estados == start_ex && ready_rx)Rrx <= 1;
else if (ex_estados == end_ex)Rrx <=0;
else Rrx <=Rrx;
//Delay en sync_rx para recepcion.

always@(posedge clk)
if(rst) ex_estados <= wait_ex;
else 
	case(ex_estados)
	wait_ex:if(Sstart) ex_estados <= start_ex;
			else ex_estados <= ex_estados;
	start_ex:if(Rtx&&Rrx)
				ex_estados<=end_ex;
			 else
				ex_estados <= ex_estados;
	end_ex:ex_estados<=wait_ex;
	default:ex_estados<= wait_ex;
endcase


always@(posedge clk)
if(rst) rx_w1 <= 4'd0;
else if(ex_estados==end_ex)rx_w1<=w1rx;
else rx_w1<=rx_w1;

always@(posedge clk)
if(rst) rx_w2 <= 4'd0;
else if(ex_estados==end_ex)rx_w2<=w2rx;
else rx_w2<=rx_w2;

always@(posedge clk)
if(rst) rx_w3 <= 4'd0;
else if(ex_estados==end_ex)rx_w3<=w3rx;
else rx_w3<=rx_w3;






endmodule
