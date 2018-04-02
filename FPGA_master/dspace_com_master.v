

//Master fpga
module dspace_com_master(
 clk,
 rst,
 fpga_in,
 fpga_out,
 reset_slave,
 Mstart,
 sync_slave,
 rx_w1,rx_w2,rx_w3,
 tx_w1,tx_w2,tx_w3,
 bit_rate_fpga
);
//estados de envio y recepcion entre fpga's
//parameter bit_rate_fpga = 60;

parameter wait_ex = 3'd0;
parameter start_ex = 3'd1;
parameter end_ex = 3'd2;

parameter sinc1 = 1'd0;
parameter sinc2 = 1'd1; 


/*parameter w1 = 4'b1001;
parameter w2 = 4'b1100;
parameter w3 = 4'b1101;
*/
input [7:0]bit_rate_fpga;
output [3:0] rx_w1,rx_w2,rx_w3;
input [3:0] tx_w1,tx_w2,tx_w3;
input Mstart;//Indica inicio de comunicacion al maestro
input clk,rst,fpga_in;
output fpga_out;
output reset_slave;
output sync_slave;


//comienza el intercambio de bits una vez terminado el envio hacia la dspace
//Maestro controla los parametros de sincronizacion,
//primero se inicia la transmision,
wire sync_tx;
reg sync_rx;
reg s_1,s_2,s3;
wire [3:0]w1rx,w2rx,w3rx;
reg [3:0]rx_w1,rx_w2,rx_w3;
reg [8:0]fpga_count;

reg [2:0] ex_estados;
reg [7:0] sinc_counter;
initial sinc_counter = 0;
initial ex_estados = wait_ex;
initial fpga_count = 0;
wire ready_tx,ready_rx;
reg Rtx,Rrx;
//wire tx_test;

fpga_tx_com fpga_tx(.clk(clk),.reset(rst),.word1(tx_w1),.word2(tx_w2),.word3(tx_w3),.sync_tx(sync_tx),.tx(fpga_out),.ready_tx(ready_tx),.start_tx(Mstart));

fpga_rx_com fpga_rx(.clk(clk),.reset(rst),.word1(w1rx),.word2(w2rx),.word3(w3rx),.sync_rx(sync_rx),.rx(fpga_in),.ready_rx(ready_rx),.start_rx(Mstart));

reg sync_slave ;

always@(posedge clk)
if(s_1) sync_slave <= 1;
else if(fpga_count==(bit_rate_fpga>>1))sync_slave<=0;
else sync_slave <= sync_slave;

//assign fpga_out = tx_test;
assign reset_slave = rst;
always@(posedge clk)
if(rst || fpga_count == bit_rate_fpga || Mstart) fpga_count <= 0;
else fpga_count <= fpga_count + 1;

always@(posedge clk)
if(ex_estados == start_ex && ready_tx)Rtx <= 1;
else if (ex_estados == end_ex)Rtx <=0;
else Rtx <= Rtx;
always@(posedge clk)
if(ex_estados == start_ex && ready_rx)Rrx <= 1;
else if (ex_estados == end_ex)Rrx <=0;
else Rrx <=Rrx;

always@(posedge clk) 
if(fpga_count == bit_rate_fpga) s_1 <= 1;
	else s_1 <= 0;
always@(posedge clk)s_2 <= s_1;
always@(posedge clk)s3 <= s_2;
//always@(posedge clk)s4 <= s3;

assign sync_tx = s3||rst;
//Delay en sync_rx para recepcion.

always@(posedge clk)
if(rst||sinc_counter == ((bit_rate_fpga>>1)+1)||Mstart)sinc_counter <= 0;
else if(sync_tx) sinc_counter <= 1;
else if(sinc_counter >= 1)sinc_counter <= sinc_counter +1;
else sinc_counter <= sinc_counter;

always@(posedge clk)
if(rst) sync_rx <= 0;
else if(sinc_counter == bit_rate_fpga>>1) sync_rx <= 1;
else sync_rx <= 0;

always@(posedge clk)
if(rst) ex_estados <= wait_ex;
else 
	case(ex_estados)
	wait_ex:if(Mstart) ex_estados <= start_ex;
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
