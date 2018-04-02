`timescale 1ns / 1ps

module LCDv2(
	clk,
	chars,
	lcd_rs, lcd_rw, lcd_e, lcd_4, lcd_5, lcd_6, lcd_7);

	// inputs and outputs
	input       	clk;
	input [256:0] 	chars;
	output      	lcd_rs, lcd_rw, lcd_e, lcd_4, lcd_5, lcd_6, lcd_7;

	wire [256:0] 	chars;
	reg	 	lcd_rs, lcd_rw, lcd_e, lcd_4, lcd_5, lcd_6, lcd_7;

	// internal variables
	reg [5:0] 	lcd_code;
	wire [1:0] 	write;	// write code has 10 for rs rw
	assign write = 2'b10;
	// delays
	wire [1:0]	before_delay ;	// time before on
	wire [3:0]	on_delay ;		// time on
	reg [23:0]	off_delay;	// time off
	assign before_delay = 2;
	assign on_delay = 12;
	initial off_delay=750_001;
	// states and counters
	reg [6:0]	Cs = 0;
	reg [19:0]	count = 0;
	reg [1:0]	delay_state = 0;
	
	// character data
	reg [256:0]	chars_hold;
	initial chars_hold = "                                ";
	wire [3:0]	chars_data [63:0];	// array of characters

	// redirects characters data to an array
	/*generate
	genvar i;
		for (i = 64; i > 0; i = i-1)
			begin : for_name
				assign chars_data[64-i] = chars_hold[i*4-1:i*4-4];
			end
	endgenerate*/
	// assign character data
	reg [3:0]charact;
	initial charact = 0;
always@(Cs)
case(Cs)
77:charact <= chars_hold[3:0];
76:charact <= chars_hold[7:4];
75:charact <= chars_hold[11:8];
74:charact <= chars_hold[15:12];
73:charact <= chars_hold[19:16];
72:charact <= chars_hold[23:20];
71:charact <= chars_hold[27:24];
70:charact <= chars_hold[31:28];
69:charact <= chars_hold[35:32];
68:charact <= chars_hold[39:36];
67:charact <= chars_hold[43:40];
66:charact <= chars_hold[47:44];
65:charact <= chars_hold[51:48];
64:charact <= chars_hold[55:52];
63:charact <= chars_hold[59:56];
62:charact <= chars_hold[63:60];
61:charact <= chars_hold[67:64];
60:charact <= chars_hold[71:68];
59:charact <= chars_hold[75:72];
58:charact <= chars_hold[79:76];
57:charact <= chars_hold[83:80];
56:charact <= chars_hold[87:84];
55:charact <= chars_hold[91:88];
54:charact <= chars_hold[95:92];
53:charact <= chars_hold[99:96];
52:charact <= chars_hold[103:100];
51:charact <= chars_hold[107:104];
50:charact <= chars_hold[111:108];
49:charact <= chars_hold[115:112];
48:charact <= chars_hold[119:116];
47:charact <= chars_hold[123:120];
46:charact <= chars_hold[127:124];
//44 y 45 salto de linea
43:charact <= chars_hold[131:128];
42:charact <= chars_hold[135:132];
41:charact <= chars_hold[139:136];
40:charact <= chars_hold[143:140];
39:charact <= chars_hold[147:144];
38:charact <= chars_hold[151:148];
37:charact <= chars_hold[155:152];
36:charact <= chars_hold[159:156];
35:charact <= chars_hold[163:160];
34:charact <= chars_hold[167:164];
33:charact <= chars_hold[171:168];
32:charact <= chars_hold[175:172];
31:charact <= chars_hold[179:176];
30:charact <= chars_hold[183:180];
29:charact <= chars_hold[187:184];
28:charact <= chars_hold[191:188];
27:charact <= chars_hold[195:192];
26:charact <= chars_hold[199:196];
25:charact <= chars_hold[203:200];
24:charact <= chars_hold[207:204];
23:charact <= chars_hold[211:208];
22:charact <= chars_hold[215:212];
21:charact <= chars_hold[219:216];
20:charact <= chars_hold[223:220];
19:charact <= chars_hold[227:224];
18:charact <= chars_hold[231:228];
17:charact <= chars_hold[235:232];
16:charact <= chars_hold[239:236];
15:charact <= chars_hold[243:240];
14:charact <= chars_hold[247:244];
13:charact <= chars_hold[251:248];
12:charact <= chars_hold[255:252];
default:charact <= 4'd0;
endcase

	always @ (posedge clk) begin

		// store character data
		if (Cs == 10 && count == 0) begin
			chars_hold <= chars;
		end

		// set time when enable is off
		if (Cs < 3) begin
			case (Cs)
				0: off_delay <= 750_001;	// 15ms delay
				1: off_delay <= 250_001;	// 5ms delay
				2: off_delay <= 5_001;		// 0.1ms delay
			endcase
		end else begin
			if (Cs > 12) begin
				off_delay	<= 2_001;	// 40us delay
			end else begin
				if(Cs>9) off_delay <= 82001;
				else off_delay	<= 2001;	// 250000 5ms delay
			end
		end

		// delays during each state
		if (Cs < 80) begin
		case (delay_state)
			0: begin
					// enable is off
					lcd_e <= 0;
					{lcd_rs,lcd_rw,lcd_7,lcd_6,lcd_5,lcd_4} <= lcd_code;
					if (count == off_delay) begin
						count <= 0;
						delay_state <= delay_state + 1;
					end else begin
						count <= count + 1;
					end
				end
			1: begin
					// data set before enable is on
					lcd_e <= 0;
					if (count == before_delay) begin
						count <= 0;
						delay_state <= delay_state + 1;
					end else begin
						count <= count + 1;
					end
				end
			2: begin
					// enable on
					lcd_e <= 1;
					if (count == on_delay) begin
						count <= 0;
						delay_state <= delay_state + 1;
					end else begin
						count <= count + 1;
					end
				end
			3: begin
					// enable off with data set
					lcd_e <= 0;
					if (count == before_delay) begin
						count <= 0;
						delay_state <= 0;
						Cs <= Cs + 1;		// next case
					end else begin
						count <= count + 1;
					end
				end
		endcase
		end

		// set lcd_code
		if (Cs < 12) begin
			// initialize LCD
			case (Cs)
				0: lcd_code <= 6'h03;        // power-on initialization
				1: lcd_code <= 6'h03;
				2: lcd_code <= 6'h03;
				3: lcd_code <= 6'h02;
				4: lcd_code <= 6'h02;        // function set
				5: lcd_code <= 6'h08;
				6: lcd_code <= 6'h00;        // entry mode set
				7: lcd_code <= 6'h06;
				8: lcd_code <= 6'h00;        // display on/off control
				9: lcd_code <= 6'h0C;
				10:lcd_code <= 6'h00;        // display clear
				11:lcd_code <= 6'h01;
				default: lcd_code <= 6'h10;
			endcase
		end else begin

			// set character data to lcd_code
			if (Cs == 44) begin			// change address at end of first line
				lcd_code <= {2'b00, 4'b1100};	// 0100 0000 address change
			end else if (Cs == 45) begin
				lcd_code <= {2'b00, 4'b0000};
			end else begin
				if (Cs < 44) begin
					lcd_code <= {write, charact};//chars_data[Cs-12]};
				end else begin
					lcd_code <= {write, charact};//chars_data[Cs-14]};
				end
			end

		end

		// hold and loop back
		if (Cs == 78) begin
			lcd_e <= 0;
			if (count == off_delay) begin
				Cs 			<= 8;
				count 		<= 0;
			end else begin
				count <= count + 1;
			end
		end

	end

endmodule
