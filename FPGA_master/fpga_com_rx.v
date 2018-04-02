

module fpga_rx_com(clk,reset,word1,word2,word3,sync_rx,rx,ready_rx,start_rx);

parameter wait_rx = 3'd0;
parameter rx_1 = 3'd1;
parameter rx_2 =3'd2;
parameter rx_3 = 3'd3;
parameter end_rx = 3'd4;

input clk,reset,sync_rx,rx,start_rx;
output [3:0] word1,word2,word3;
reg [3:0] word1,word2,word3;
output ready_rx;

reg [2:0] ST_rx;
initial ST_rx = 0;

reg[2:0] count_bit;
initial count_bit = 0 ;
reg start_rx2;
initial start_rx2 = 0;
assign ready_rx = (ST_rx==end_rx);

always@(posedge clk)
if(ST_rx == wait_rx && start_rx)start_rx2 <= 1;
else if (ST_rx != wait_rx)start_rx2 <=0;
else start_rx2 <= start_rx2;

always@(posedge clk)
if(reset)ST_rx <= wait_rx;
else 
	case(ST_rx)
		wait_rx:if(start_rx2) ST_rx<=rx_1;
				else ST_rx <= ST_rx;
		rx_1:if(count_bit == 4)ST_rx <= rx_2;
			 else ST_rx<=ST_rx;
		rx_2:if(count_bit == 4 )ST_rx <= rx_3;
			 else ST_rx<=ST_rx;
		rx_3:if(count_bit == 4 )ST_rx <= end_rx;
			 else ST_rx<=ST_rx;
		end_rx:if(sync_rx)ST_rx<=wait_rx;
				else ST_rx <= ST_rx;
	default:ST_rx <= wait_rx;
	endcase
	
always@(posedge clk)
if(reset||count_bit==4||start_rx)count_bit <= 0;
else if(sync_rx)
	case(ST_rx)
		wait_rx: count_bit <= 0;
		rx_1: count_bit<=count_bit+1;
		rx_2: count_bit<=count_bit+1;
		rx_3: count_bit<=count_bit+1;
		end_rx:count_bit<=0;
	default:count_bit<=count_bit;
	endcase	
else count_bit <= count_bit;

always@(posedge clk)
if(reset)word1 <= 4'd0;
else if(sync_rx)
	case(ST_rx)
		wait_rx: word1 <= 4'd0;
		rx_1: word1<={word1[2:0],rx};
		rx_2: word1<=word1;
		rx_3: word1<=word1;
		end_rx:word1<=word1;
	default:word1<=word1;
	endcase	
else word1 <= word1;

always@(posedge clk)
if(reset)word2 <= 4'd0;
else if(sync_rx)
	case(ST_rx)
		wait_rx: word2 <= 4'd0;
		rx_1: word2<=word2;
		rx_2: word2<={word2[2:0],rx};
		rx_3: word2<=word2;
		end_rx:word2<=word2;
	default:word2<=word2;
	endcase	
else word2 <= word2;

always@(posedge clk)
if(reset)word3 <= 4'd0;
else if(sync_rx)
	case(ST_rx)
		wait_rx: word3 <= 4'd0;
		rx_1: word3<=word3;
		rx_2: word3<=word3;
		rx_3: word3<={word3[2:0],rx};
		end_rx:word3<=word3;
	default:word3<=word3;
	endcase	
else word3 <= word3;



endmodule
