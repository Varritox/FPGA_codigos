

module fpga_tx_com(clk,reset,word1,word2,word3,sync_tx,tx,ready_tx,start_tx);

parameter wait_tx = 3'd0;
parameter tx_1 = 3'd1;
parameter tx_2 =3'd2;
parameter tx_3 = 3'd3;
parameter end_tx = 3'd4;

input clk,reset,sync_tx,start_tx;
output tx;
reg tx;
input [3:0] word1,word2,word3;
reg [3:0] word1s,word2s,word3s;
output ready_tx;
initial word1s = 4'd0;
initial word2s = 4'd0;
initial word3s = 4'd0;

reg [2:0] ST_tx;
initial ST_tx = 0;

reg[2:0] count_bit;
initial count_bit = 0 ;

assign ready_tx = (ST_tx==end_tx);

always@(posedge clk)
if(reset)ST_tx <= wait_tx;
else 
	case(ST_tx)
		wait_tx:if(start_tx) ST_tx<=tx_1;
				else ST_tx <= ST_tx;
		tx_1:if(count_bit == 4 )ST_tx <= tx_2;
			 else ST_tx<=ST_tx;
		tx_2:if(count_bit == 4 )ST_tx <= tx_3;
			 else ST_tx<=ST_tx;
		tx_3:if(count_bit == 4 )ST_tx <= end_tx;
			 else ST_tx<=ST_tx;
		end_tx:if(sync_tx)ST_tx<=wait_tx;
				else ST_tx <= ST_tx;
	default:ST_tx<=wait_tx;
	endcase
	
always@(posedge clk)
if(reset||count_bit==4)count_bit <= 0;
else if(sync_tx)
	case(ST_tx)
		wait_tx: count_bit <= 0;
		tx_1: count_bit<=count_bit+1;
		tx_2: count_bit<=count_bit+1;
		tx_3: count_bit<=count_bit+1;
		end_tx:count_bit<=0;
	default:count_bit<=count_bit;
	endcase	
else count_bit <= count_bit;

always@(posedge clk)
if(sync_tx)
case(ST_tx)
		wait_tx: tx<=0;
		tx_1: tx<=word1s[3];
		tx_2: tx<=word2s[3];
		tx_3: tx<=word3s[3];
		end_tx:tx<=0;
	default:tx<=tx;
endcase	
else tx<=tx;

always@(posedge clk)
if(reset)word1s <= 4'd0;
else 
	case(ST_tx)
		wait_tx: word1s <= word1;
		tx_1: if(sync_tx)word1s<={word1s[2:0],word1s[3]};
				else word1s<=word1s;
		tx_2: word1s<=word1s;
		tx_3: word1s<=word1s;
		end_tx:word1s<=word1s;
	default:word1s<=word1s;
	endcase	

always@(posedge clk)
if(reset)word2s <= 4'd0;
else 
	case(ST_tx)
		wait_tx: word2s <= word2;
		tx_2: if(sync_tx) word2s<={word2s[2:0],word2s[3]};
			else word2s<=word2s;
		tx_1: word2s<=word2s;
		tx_3: word2s<=word2s;
		end_tx:word2s<=word2s;
	default:word2s<=word2s;
	endcase	

always@(posedge clk)
if(reset)word3s <= 4'd0;
else 
	case(ST_tx)
		wait_tx: word3s <= word3;
		tx_3: if(sync_tx) word3s<={word3s[2:0],word3s[3]};
			else word3s<=word3s;
		tx_2: word3s<=word3s;
		tx_1: word3s<=word3s;
		end_tx:word3s<=word3s;
	default:word3s<=word3s;
	endcase	



endmodule
