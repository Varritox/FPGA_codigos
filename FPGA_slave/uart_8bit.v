


//`timescale 10ns/1ps
//Descripcion del modoulo:Modulo para recibir uart y ajustar reloj de lectura de datos de acuerdo a frecuencia de envio de cada
//microcontrolador, el cual envia datos a 3.3 us de BIT rate. El microcontralor inicia el envio de datos enviando un 0 y luego un 1
//como start bits, luego envia la señal de voltaje del adc en los siguientes 8 bits en donde el MSB se envia primero. Finalmente
//envia un 1 como stop bit y espera 10 us para el siguiente ciclo de datos que es lo que tarda el adc en capturar el voltaje.
//En total el proceso entre cada dato es de 43 us app.
//El modulo captura los 8 bit de acuerdo al protocolo de envio del microcontrolador y los guarda en el registro Rx_reg una vez
//que se termina una adquisicion exitosa. Si esta resulta en error (stop bit no coincide) se descarta y vuelve a esperar el 
//por otra transmision un tiempo dado por el el registro Max_count

module uart_8bit(Rx_data,clk,Rx_reg,reset,listo,estado);
parameter max_count_bit = 7;
parameter espera = 3'b000;
parameter inicio_lectura = 3'b001;//Se detecta bit de inicio de transimion
parameter nuevo_reloj=3'b010;//Estado de ajuste del nuevo reloj basado en los 2 primeros bits de inicio de transmision
parameter escritura = 3'b011;// Estado en donde se reciben los datos y se guardan en un buffer
parameter fin_recepcion = 3'b100;//Estado en donde se termina de recibir, y el modulo envía aviso de que la lectura esta terminada y pasara al modo de espera
parameter check = 3'b101;//Estado en donde se termina de recibir, y el modulo envía aviso de que la lectura esta terminada y pasara al modo de espera
parameter error_lectura = 3'b111;//Estado en donde se termina de recibir, y el modulo envía aviso de que la lectura esta terminada y pasara al modo de espera
parameter sync = 3'b110;//Estado cuando todo sale mal...debo leer 3 unos seguidos
parameter default_count = 7'd50;

parameter espera_error = 5'b11100;//contador del c_nclk hasta volver al estado de espera en caso de error de lectura
parameter start_bit = 1'b0;
parameter start_bit2 = 1'b1;
parameter Max_count = 8'd25;//80
parameter stop_bit = 1'b1;

output listo;//Flag que avisa cuando se termina de recibir los 8 bits
output [7:0]Rx_reg;
input reset;
input clk;
input Rx_data; //Dato que se recibe desde el micro, se lee en todo momento
output [2:0]estado;



//reg data;
reg [7:0]Rx_total;//Salida y registro donde se almacenan los bits recibidos, se borra una vez comienza el proceso de 

reg[max_count_bit:0]count_clk;//contador que determina nuevo reloj
reg[4:0]count_bit=5'b00000;//Cuenta cada posedge de nclk que coincide con los bits leidos -1
reg [2:0] Rx_state; //Estados que definen comportamiento del modulo
reg [7:0]Rx_reg;//Registro que almacena cada muestra exitosa
initial Rx_reg = 0;
reg listo; //Indica cuando una  medicion esta lista
reg[max_count_bit:0]count_clk2;
reg [max_count_bit:0]reg_count;
initial reg_count = 0;
reg nclk;
reg [4:0]c_nclk; //Contador de numeros de ciclos del nuevo reloj , que seran 20 
reg [6:0]sync_count;//Contador para el nuevo estado
initial sync_count = 0;
assign estado = Rx_state;
reg r1,r2;


initial Rx_state = error_lectura;
always @(posedge clk)r1<=nclk;
always @(posedge clk)r2<= r1;
assign nclk2 = !r2&&r1;
//////// Syncronization
/*
initial sync = 2'b00;
initial DATA = 1'b1;
initial Rx_total = 8'h00;
*/
////////////////
/////////////Determination what data is

//adj_clk

always@(posedge clk)
if(reset||(Rx_state==espera)) 
	count_clk<=1;
else if(Rx_state==inicio_lectura)
	count_clk<=count_clk+1;
else if(Rx_state==nuevo_reloj)
	count_clk<=count_clk;//Dejo de contar y tomo la cantidad para el nuevo reloj
else 
	count_clk<=1;

//Registro que almacena duración del dato 

always@(posedge clk)
if(reset) 
	reg_count <=0;
else if(Rx_state==nuevo_reloj)
	reg_count<=count_clk;
else 
	reg_count<=reg_count;

//Contador para el nuevo relok nclk

always@(posedge clk)
if(reset||Rx_state==espera)
	count_clk2<=0;
else if(count_clk2==((reg_count>>1)-1)) 
	count_clk2<=0;
else if(Rx_state==nuevo_reloj||Rx_state==escritura||Rx_state==check||Rx_state==error_lectura||Rx_state==fin_recepcion)
	count_clk2<= count_clk2+1;
else
	count_clk2<=count_clk2;

//Nuevo reloj basado en el contador del primer star bit

always@(posedge clk)
if(reset||(Rx_state==espera))
	nclk<=0;
else if(count_clk2==((reg_count>>1)-1)&&Rx_state!=espera&&Rx_state!=inicio_lectura)
	nclk<=~nclk;
else 
	nclk<=nclk;

always@(posedge clk)
if(reset||(Rx_state==espera)||Rx_state==inicio_lectura)
	c_nclk<=0;
else if(count_clk2==((reg_count>>1)-1)&&Rx_state!=espera&&Rx_state!=inicio_lectura&&nclk)
	c_nclk<=c_nclk+1;
else c_nclk<=c_nclk;

always@(posedge clk)
if(Rx_state == sync && Rx_data == 1'b1)sync_count <= sync_count+1;
else sync_count<=0;
	

//Definicion de estados
always@(posedge clk)
if(reset)
	Rx_state <= espera;
else 
	case(Rx_state)
		espera:if(Rx_data==1'b0)//Canto de bajada iniciado
					Rx_state<=inicio_lectura;
				else
					Rx_state<=espera;
		inicio_lectura:if(Rx_data==start_bit2)
						Rx_state<=nuevo_reloj;
					   else if(count_clk ==Max_count)
						Rx_state<=sync;
					   else 
						Rx_state<=inicio_lectura;
		sync:if(sync_count == default_count)
				Rx_state <= espera;
				else Rx_state <= sync;
		nuevo_reloj:if(count_clk2==((reg_count>>1)-1)&&nclk)
						Rx_state<=escritura;
					else
						Rx_state<=nuevo_reloj;
		escritura://Utilizo ciclos del nuevo reloj
				   if(c_nclk==9)
						Rx_state<=check;
				   else
					 Rx_state<=escritura;
		check:if(count_clk2==((reg_count>>1)-1)&&nclk)
					if(Rx_data==stop_bit)
						Rx_state<=fin_recepcion;
					else
						Rx_state<=error_lectura;
		error_lectura://if(c_nclk==espera_error)
						Rx_state<=sync;
					  //else
					    //Rx_state<=error_lectura;
		fin_recepcion:if(c_nclk>=9)
						Rx_state<=espera;
					  else
						Rx_state<=fin_recepcion;
		default:Rx_state<=espera;
		endcase		
		
always@(posedge clk)
if(reset||Rx_state==espera||Rx_state==nuevo_reloj||Rx_state==error_lectura)
	Rx_total<=8'h00;
else if(Rx_state==escritura&&nclk2)
	Rx_total<={Rx_total[6:0],Rx_data};
else
	Rx_total<=Rx_total;
	/*			//////TESTING
always@(negedge nclk)
if(reset||Rx_state==espera||Rx_state==nuevo_reloj||Rx_state==error_lectura)
	data<=0;
else if(Rx_state==escritura)
	data<=Rx_data;
else
	data<=data;			*/	
always@(negedge nclk)
if(reset)count_bit <=0;
else if(Rx_state==escritura)
	count_bit<=count_bit+1;
	else
	count_bit <=0;
				
				
always@(posedge clk)
if(reset)
	Rx_reg <= 8'h00;
else if(Rx_state == fin_recepcion) 
	Rx_reg<=Rx_total;
	//Rx_reg<=reg_count;
else 
	Rx_reg <= Rx_reg;		
	
always@(posedge clk)
if(Rx_state==fin_recepcion||Rx_state==espera||reset)
	listo<=1;
else 
	listo <=0;

endmodule

