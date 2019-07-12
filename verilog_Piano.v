//En primer lugar, se importa el modulo DAC subido en el material docente de ucursos
`timescale 1ns / 1ps
module DAC(clk, enable, done, data, address,	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO, SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B); //modulo de ucursos

	// input and outputs
	input 	clk, enable, SPI_MISO;
	output	done;			// goes high for one clock cycle when done
	input 	[11:0]	data;		// desired DAC value
	input 	[3:0]	address;	// DAC want to use
	output 	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	output 	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;

	wire 	clk, enable, SPI_MISO;
	reg		done;
	wire 	[11:0]	data;
	wire 	[3:0]	address;
	reg 	SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	reg 	SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B;

	// internal variables
	reg [2:0] 	Cs = 0;
	reg [31:0]	send;
	reg [5:0]	bit_pos = 32;	

	always @(posedge clk) begin
		// when enable is on
		if (enable == 1) begin
			// disable other SPI devices
			SPI_SS_B 	<= 1;
			AMP_CS 		<= 1;
			AD_CONV 		<= 0;
			SF_CE0 		<= 1;
			FPGA_INIT_B <= 1;

			case (Cs)
				0:	begin
						// initial
						DAC_CS 	<= 1;
						SPI_MOSI <= 0;
						SPI_SCK	<= 0;
						DAC_CLR	<= 1;
						done 		<= 0;
						Cs <= Cs + 1;
					end
				1: begin
						// set data to be sent
						send <= {8'b00000000, 4'b0011, address, data, 4'b0000};

						// set for next
						bit_pos <= 32;
						Cs <= Cs + 1;
					end
				2: begin
						// start sending
						DAC_CS 	<= 0;

						// lower clock
						SPI_SCK	<= 0;

						// set data pin
						SPI_MOSI <= send[bit_pos-1];
						bit_pos <= bit_pos - 1;
						Cs <= Cs + 1;
					end
				3: begin
						// rise spi clock
						if (bit_pos > 0) begin
							SPI_SCK <= 1;
							Cs <= 2;
						end else begin
							SPI_SCK <= 1;
							Cs <= Cs + 1;
						end
					end
				4: begin
						SPI_SCK <= 0;
						Cs <= Cs + 1;
					end
				5: begin
						DAC_CS <= 1;
						Cs <= Cs + 1;
					end
				6: begin
						done <= 1;	// send done signal
						Cs <= Cs + 1;
					end
				7: begin
						done <= 0;	// go back to loop
						Cs <= 1;
					end
				default: begin
						DAC_CS 	<= 1;
						SPI_MOSI <= 0;
						SPI_SCK	<= 0;
						DAC_CLR	<= 1;
					end
			endcase
		end else begin
			// reset
			DAC_CS 	<= 1;
			SPI_MOSI <= 0;
			SPI_SCK	<= 0;
			DAC_CLR	<= 1;
			done 		<= 0;
			Cs 		<= 0;
			bit_pos 	<= 32;
		end
	end
endmodule

//Posteriormente se crea el modulo que interpreta las señales enviadas por el teclado.
module PianoG1(CLK, CLK_K, K_DATA, SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO, SPI_SS_B, SF_CE0, FPGA_INIT_B, AD_CONV, AMP_CS);

	//Declaramos entradas
	input CLK; //Reloj de la FGPA
	input CLK_K, K_DATA; //Reloj y datos del teclado
	input SPI_MISO; //Entrada DAC

	//Salidas DAC
	output SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR;
	output SPI_SS_B, SF_CE0, FPGA_INIT_B, AD_CONV, AMP_CS;
	
	//Codificamos las teclas a usar del teclado (8 bits)
	wire [7:0] A=8'h1C;
	wire [7:0] S=8'h1B;
	wire [7:0] D=8'h23;
	wire [7:0] F=8'h2B;
	wire [7:0] G=8'h34;
	wire [7:0] H=8'h33;
	wire [7:0] J=8'h3B;
	wire [7:0] K=8'h42;
	wire [7:0] L=8'h4B;
	wire [7:0] Q=8'h15;
	wire [7:0] W=8'h1D;
	wire [7:0] E=8'h24;
	wire [7:0] R=8'h2D;
	wire [7:0] T=8'h2C;
	wire [7:0] Y=8'h35;
	wire [7:0] U=8'h3C;
	wire [7:0] I=8'h43;
	wire [7:0] O=8'h44;
	wire [7:0] P=8'h4D;
	
	//Definimos las notas, las cuales actualizaran su valor si se pulsa una tecla 
	reg LAmm;
	reg SImm;
	reg DOm;
	reg REm;
	reg MIm;
	reg FAm;
	reg SOLm;
	reg LAm;
	reg SIm;
	reg DO;
	reg RE;
	reg MI;
	reg FA;
	reg SOL;
	reg LA;
	reg SI;
	reg DOM;
	reg REM;
	reg MIM;
	
	//Definimos las variables que controlan las frecuencias para cada nota
	reg [20:0] FRECLAmm;
	reg [20:0] FRECSImm;
	reg [20:0] FRECDOm;
	reg [20:0] FRECREm;
	reg [20:0] FRECMIm;
	reg [20:0] FRECFAm;
	reg [20:0] FRECSOLm;
	reg [20:0] FRECLAm;
	reg [20:0] FRECSIm;
	reg [20:0] FRECDO;
	reg [20:0] FRECRE;
	reg [20:0] FRECMI;
	reg [20:0] FRECFA;
	reg [20:0] FRECSOL;
	reg [20:0] FRECLA;
	reg [20:0] FRECSI;
	reg [20:0] FRECDOM;
	reg [20:0] FRECREM;
	reg [20:0] FRECMIM;
	
	//Definimos el estado de cada nota, esto es, si va a sonar o no
	reg notaLAmm;
	reg notaSImm;
	reg notaDOm;
	reg notaREm;
	reg notaMIm;
	reg notaFAm;
	reg notaSOLm;
	reg notaLAm;
	reg notaSIm;
	reg notaDO;
	reg notaRE;
	reg notaMI;
	reg notaFA;
	reg notaSOL;
	reg notaLA;
	reg notaSI;
	reg notaDOM;
	reg notaREM;
	reg notaMIM;
	reg nota;

	// Codigo de lectura del teclado, obtenido en:
	//https://www.instructables.com/id/PS2-Keyboard-for-FPGA/
	reg read ;//this is 1 if still waits to receive more bits 
	reg [11:0] count_reading; //this is used to detect how much time passed since it received the previous codeword
	reg PREVIOUS_STATE;//used to check the previous state of the keyboard clock signal to know if it changed
	reg scan_err; //this becomes one if an error was received somewhere in the packet
	reg [10:0] scan_code; //this stores 11 received bits
	reg [7:0] CODEWORD; //this stores only the DATA codeword
	reg TRIG_ARR; //this is triggered when full 11 bits are received
	reg [3:0] COUNT; //tells how many bits were received until now (from 0 to 11)
	reg TRIGGER=0; //This acts as a 250 times slower than the board clock. 
	reg [7:0] DOWNCOUNTER=0; //This is used together with TRIGGER - look the code
	reg [7:0]LAST_KEY=8'h0; //Usada para setear en 0 cuando se deje de presionar una tecla
	
	
	//Set initial values
	initial begin
		PREVIOUS_STATE = 1;		
		scan_err = 0;		
		scan_code = 0;
		COUNT = 0;			
		CODEWORD = 0;
		read = 0;
		count_reading = 0;
		
		//Seteamos en 0 tambien las notas
		LAmm = 0;
		SImm = 0;
		DOm = 0;
		REm = 0;
		MIm = 0;
		FAm = 0;
		SOLm = 0;
		LAm = 0;
		SIm = 0;
		DO = 0;
		RE = 0;
		MI = 0;
		FA = 0;
		SOL = 0;
		LA = 0;
		SI = 0;
		DOM = 0;
		REM = 0;
		MIM = 0;
	end
	
		always @(posedge CLK) begin//This reduces the frequency 250 times			
		if (DOWNCOUNTER < 249) begin//uses variable TRIGGER as the new board clock 
			DOWNCOUNTER <= DOWNCOUNTER + 1;
			TRIGGER <= 0;
		end
		else begin
			DOWNCOUNTER <= 0;
			TRIGGER <= 1;
		end
	end
	
	always @(posedge CLK) begin	
		if (TRIGGER) begin
			if (read)//if it still waits to read full packet of 11 bits, then (read == 1)
				count_reading <= count_reading + 1;	//and it counts up this variable
			else //and later if check to see how big this value is.
				count_reading <= 0;	//if it is too big, then it resets the received data
		end
	end


	always @(posedge CLK) begin		
	if (TRIGGER) begin//If the down counter (CLK/250) is ready
		if (CLK_K != PREVIOUS_STATE) begin//if the state of Clock pin changed from previous state
			if (!CLK_K) begin//and if the keyboard clock is at falling edge
				read <= 1;//mark down that it is still reading for the next bit
				scan_err <= 0;//no errors
				scan_code[10:0] <= {K_DATA, scan_code[10:1]};//add up the data received by shifting bits and adding one new bit
				COUNT <= COUNT + 1;			//
			end
		end
		else if (COUNT == 11) begin	//if it already received 11 bits
			COUNT <= 0;
			read <= 0;//mark down that reading stopped
			TRIG_ARR <= 1;//trigger out that the full pack of 11bits was received
			//calculate scan_err using parity bit
			if (!scan_code[10] || scan_code[0] || !(scan_code[1]^scan_code[2]^scan_code[3]^scan_code[4]
				^scan_code[5]^scan_code[6]^scan_code[7]^scan_code[8]
				^scan_code[9]))
				scan_err <= 1;
			else 
				scan_err <= 0;
		end	
		else  begin	//if it yet not received full pack of 11 bits
			TRIG_ARR <= 0;	//tell that the packet of 11bits was not received yet
			if (COUNT < 11 && count_reading >= 4000) begin	
			//and if after a certain time no more bits were received, then
				COUNT <= 0;	//reset the number of bits received
				read <= 0;	//and wait for the next packet
			end
		end
	PREVIOUS_STATE <= CLK_K;//mark down the previous state of the keyboard clock
	end
	end


	always @(posedge CLK) begin
		if (TRIGGER) begin	//if the 250 times slower than board clock triggers
			if (TRIG_ARR) begin	//and if a full packet of 11 bits was received
				if (scan_err) begin	//BUT if the packet was NOT OK
					CODEWORD <= 8'd0;//then reset the codeword register
				end
				else begin
					CODEWORD <= scan_code[8:1];	//else drop down the unnecessary  bits and transport the 7 DATA bits to CODEWORD reg
				end	//notice, that the codeword is also reversed! This is because the first bit to received
			end	//is supposed to be the last bit in the codeword…
			else CODEWORD <= 8'd0;	//not a full packet received, thus reset codeword
		end
		else CODEWORD <= 8'd0;	//no clock trigger, no data…
	end
	
	
	//Con esto seteamos en 0 si dejamos de presionar la tecla, y 1 en caso contrario
	always @(posedge CLK) begin
	if (CODEWORD != 8'd0)
		begin 
		case(CODEWORD)
			A: LAmm<= (LAST_KEY == 8'hF0)? 0:1;
			S: SImm<= (LAST_KEY == 8'hF0)? 0:1;
			D: DOm<= (LAST_KEY == 8'hF0)? 0:1;
			F: REm<= (LAST_KEY == 8'hF0)? 0:1;
			G: MIm<= (LAST_KEY == 8'hF0)? 0:1;
			H: FAm<= (LAST_KEY == 8'hF0)? 0:1;
			J: SOLm<= (LAST_KEY == 8'hF0)? 0:1;
			K: LAm<= (LAST_KEY == 8'hF0)? 0:1;
			L: SIm<= (LAST_KEY == 8'hF0)? 0:1;
			Q: DO<= (LAST_KEY == 8'hF0)? 0:1;
			W: RE<= (LAST_KEY == 8'hF0)? 0:1;
			E: MI<= (LAST_KEY == 8'hF0)? 0:1;
			R: FA<= (LAST_KEY == 8'hF0)? 0:1;
			T: SOL<= (LAST_KEY == 8'hF0)? 0:1;
			Y: LA<= (LAST_KEY == 8'hF0)? 0:1;
			U: SI<= (LAST_KEY == 8'hF0)? 0:1;
			I: DOM<= (LAST_KEY == 8'hF0)? 0:1;
			O: REM<= (LAST_KEY == 8'hF0)? 0:1;
			P: MIM<= (LAST_KEY == 8'hF0)? 0:1;
			
		endcase
		LAST_KEY <= CODEWORD;
		end
	end
	

	//Podemos crear las frecuencias de las notas con la tecnica de CLOCK-DIVIDER
	//Siempre que estemos en el flanco positivo del reloj del teclado, entramos
	always @(posedge CLK) begin
	//Preguntamos si el contador alcanzo la frecuencia ponderada de la nota
	
	//LA2
	if (FRECLAmm == 454545)
		//Si se cumple la condicion, resetamos el contador a 0
		FRECLAmm <= 0;
	//Si no hemos alcanzado la frecuencia ponderada, aumentamos en uno el contador
	else 
		FRECLAmm <= FRECLAmm + 1;
	//Preguntamos si se esta presionando la tecla LA1
	if (LAmm)
		//Si es asi, entonces lo que va a sonar sera el bit mas significativo del contador
		notaLAmm <= FRECLAmm[16];
		
	//Repetimos este proceso para el resto de notas
	//SI2
	if (FRECSImm == 404957)
		FRECSImm <= 0;
	else 
		FRECSImm <= FRECSImm + 1;
	if (SImm)
		notaSImm <= FRECSImm[16];
	
	//DO3
	if (FRECDOm == 382234)
		FRECDOm <= 0;
	else 
		FRECDOm <= FRECDOm + 1;
	if (DOm)
		notaDOm <= FRECDOm[16];
	
	//RE3
	if (FRECREm == 340530)
		FRECREm <= 0;
	else 
		FRECREm <= FRECREm + 1;
	if (REm)
		notaREm <= FRECREm[16];	
	
	//MI3
	if (FRECMIm == 303380)
		FRECMIm <= 0;
	else 
		FRECMIm <= FRECMIm + 1;
	if (MIm)
		notaMIm <= FRECMIm[16];	
		
	//FA3
	if (FRECFAm == 286352)
		FRECFAm <= 0;
	else 
		FRECFAm <= FRECFAm + 1;
	if (FAm)
		notaFAm <= FRECFAm[16];	
		
	//SOL3
	if (FRECSOLm == 255102)
		FRECSOLm <= 0;
	else 
		FRECSOLm <= FRECSOLm + 1;
	if (SOLm)
		notaSOLm <= FRECSOLm[16];	
		
	//LA3
	if (FRECLAm == 227272)
		FRECLAm <= 0;
	else 
		FRECLAm <= FRECLAm + 1;
	if (LAm)
		notaLAm <= FRECLAm[16];	
		
	//SI3
	if (FRECSIm == 202478)
		FRECSIm <= 0;
	else 
		FRECSIm <= FRECSIm + 1;
	if (SIm)
		notaSIm <= FRECSIm[16];
		
	//DO4	
	if (FRECDO == 191109)
		FRECDO <= 0;
	else 
		FRECDO <= FRECDO + 1;
	if (DO)
		notaDO <= FRECDO[16];
		
	//RE4	
	if (FRECRE == 170648)
		FRECRE <= 0;
	else 
		FRECRE <= FRECRE + 1;
	if (RE)
		notaRE <= FRECRE[16];

	//MI4
	if (FRECMI == 151976)
		FRECMI <= 0;
	else 
		FRECMI <= FRECMI + 1;
	if (MI)
		notaMI <= FRECMI[16];
		
	//FA4
	if (FRECFA == 143266)
		FRECFA <= 0;
	else 
		FRECFA <= FRECFA + 1;
	if (FA)
		notaFA <= FRECFA[16];
		
	//SOL4
	if (FRECSOL == 127877)
		FRECSOL <= 0;
	else 
		FRECSOL <= FRECSOL + 1;
	if (SOL)
		notaSOL <= FRECSOL[16];
	
	//LA4
	if (FRECLA == 113636)
		FRECLA <= 0;
	else 
		FRECLA <= FRECLA + 1;
	if (LA)
		notaLA <= FRECLA[16];
		
	//SI4
	if (FRECSI == 101420)
		FRECSI <= 0;
	else 
		FRECSI <= FRECSI + 1;
	if (SI)
		notaSI <= FRECSI[16];	
		
	//DO5
	if (FRECDOM == 95602)
		FRECDOM <= 0;
	else 
		FRECDOM <= FRECDOM + 1;
	if (DOM)
		notaDOM <= FRECDOM[16];	
	
	//RE5
	if (FRECREM == 85131)
		FRECREM <= 0;
	else 
		FRECREM <= FRECREM + 1;
	if (REM)
		notaREM <= FRECREM[16];	
	
	//MI5
	if (FRECMIM == 75843)
		FRECMIM <= 0;
	else 
		FRECMIM <= FRECMIM + 1;
	if (MIM)
		notaMIM <= FRECMIM[16];	
	end
	
	//Siempre que estemos en el flanco positivo del reloj del teclado, entramos
	always @(posedge CLK)
	begin
		//Empezamos a preguntar que notas tenemos individuales estan presionadas
		//Si entramos en un if, configuramos lo que va a sonar con el sonido
		//que tendria cada nota
		if(LAmm)
			nota=notaLAmm;
		if(SImm)
			nota=notaSImm;
		if(DOm)
			nota=notaDOm;
		if(REm)
			nota=notaREm;
		if(MIm)
			nota=notaMIm;
		if(FAm)
			nota=notaFAm;
		if(SOLm)
			nota=notaSOLm;
		if(LAm)
			nota=notaLAm;
		if(SIm)
			nota=notaSIm;
		if(DO)
			nota=notaDO;
		if(RE)
			nota=notaRE;
		if(MI)
			nota=notaMI;
		if(FA)
			nota=notaFA;
		if(SOL)
			nota=notaSOL;
		if(LA)
			nota=notaLA;
		if(SI)
			nota=notaSI;
		if(DOM)
			nota=notaDOM;
		if(REM)
			nota=notaREM;
		if(MIM)
			nota=notaMIM;
			
		//Hacemos lo mismo, pero para todas las diadas posibles
		if (LAmm&&SImm)
			nota=notaLAmm|notaSImm;
		if (LAmm&&DOm)
			nota=notaLAmm|notaDOm;
		if (LAmm&&REm)
			nota=notaLAmm|notaREm;
		if (LAmm&&MIm)
			nota=notaLAmm|notaMIm;
		if (LAmm&&FAm)
			nota=notaLAmm|notaFAm;
		if (LAmm&&SOLm)
			nota=notaLAmm|notaSOLm;
		if (LAmm&&LAm)
			nota=notaLAmm|notaLAm;
		if (LAmm&&SIm)
			nota=notaLAmm|notaSIm;
		if (LAmm&&DO)
			nota=notaLAmm|notaDO;
		if (LAmm&&RE)
			nota=notaLAmm|notaRE;
		if (LAmm&&MI)
			nota=notaLAmm|notaMI;
		if (LAmm&&FA)
			nota=notaLAmm|notaFA;
		if (LAmm&&SOL)
			nota=notaLAmm|notaSOL;
		if (LAmm&&LA)
			nota=notaLAmm|notaLA;
		if (LAmm&&SI)
			nota=notaLAmm|notaSI;
		if (LAmm&&DOM)
			nota=notaLAmm|notaDOM;
		if (LAmm&&REM)
			nota=notaLAmm|notaREM;
		if (LAmm&&MIM)
			nota=notaLAmm|notaMIM;
		
		if (SImm&&DOm)
			nota=notaSImm|notaDOm;
		if (SImm&&REm)
			nota=notaSImm|notaREm;
		if (SImm&&MIm)
			nota=notaSImm|notaMIm;
		if (SImm&&FAm)
			nota=notaSImm|notaFAm;
		if (SImm&&SOLm)
			nota=notaSImm|notaSOLm;
		if (SImm&&LAm)
			nota=notaSImm|notaLAm;
		if (SImm&&SIm)
			nota=notaSImm|notaSIm;
		if (SImm&&DO)
			nota=notaSImm|notaDO;
		if (SImm&&RE)
			nota=notaSImm|notaRE;
		if (SImm&&MI)
			nota=notaSImm|notaMI;
		if (SImm&&FA)
			nota=notaSImm|notaFA;
		if (SImm&&SOL)
			nota=notaSImm|notaSOL;
		if (SImm&&LA)
			nota=notaSImm|notaLA;
		if (SImm&&SI)
			nota=notaSImm|notaSI;
		if (SImm&&DOM)
			nota=notaSImm|notaDOM;
		if (SImm&&REM)
			nota=notaSImm|notaREM;
		if (SImm&&MIM)
			nota=notaSImm|notaMIM;
			
		if (DOm&&REm)
			nota=notaDOm|notaREm;
		if (DOm&&MIm)
			nota=notaDOm|notaMIm;
		if (DOm&&FAm)
			nota=notaDOm|notaFAm;
		if (DOm&&SOLm)
			nota=notaDOm|notaSOLm;
		if (DOm&&LAm)
			nota=notaDOm|notaLAm;
		if (DOm&&SIm)
			nota=notaDOm|notaSIm;
		if (DOm&&DO)
			nota=notaDOm|notaDO;
		if (DOm&&RE)
			nota=notaDOm|notaRE;
		if (DOm&&MI)
			nota=notaDOm|notaMI;
		if (DOm&&FA)
			nota=notaDOm|notaFA;
		if (DOm&&SOL)
			nota=notaDOm|notaSOL;
		if (DOm&&LA)
			nota=notaDOm|notaLA;
		if (DOm&&SI)
			nota=notaDOm|notaSI;
		if (DOm&&DOM)
			nota=notaDOm|notaDOM;
		if (DOm&&REM)
			nota=notaDOm|notaREM;
		if (DOm&&MIM)
			nota=notaDOm|notaMIM;
			
		if (REm&&MIm)
			nota=notaREm|notaMIm;
		if (REm&&FAm)
			nota=notaREm|notaFAm;
		if (REm&&SOLm)
			nota=notaREm|notaSOLm;
		if (REm&&LAm)
			nota=notaREm|notaLAm;
		if (REm&&SIm)
			nota=notaREm|notaSIm;
		if (REm&&DO)
			nota=notaREm|notaDO;
		if (REm&&RE)
			nota=notaREm|notaRE;
		if (REm&&MI)
			nota=notaREm|notaMI;
		if (REm&&FA)
			nota=notaREm|notaFA;
		if (REm&&SOL)
			nota=notaREm|notaSOL;
		if (REm&&LA)
			nota=notaREm|notaLA;
		if (REm&&SI)
			nota=notaREm|notaSI;
		if (REm&&DOM)
			nota=notaREm|notaDOM;
		if (REm&&REM)
			nota=notaREm|notaREM;
		if (REm&&MIM)
			nota=notaREm|notaMIM;
			
		if (MIm&&FAm)
			nota=notaMIm|notaFAm;
		if (MIm&&SOLm)
			nota=notaMIm|notaSOLm;
		if (MIm&&LAm)
			nota=notaMIm|notaLAm;
		if (MIm&&SIm)
			nota=notaMIm|notaSIm;
		if (MIm&&DO)
			nota=notaMIm|notaDO;
		if (MIm&&RE)
			nota=notaMIm|notaRE;
		if (MIm&&MI)
			nota=notaMIm|notaMI;
		if (MIm&&FA)
			nota=notaMIm|notaFA;
		if (MIm&&SOL)
			nota=notaMIm|notaSOL;
		if (MIm&&LA)
			nota=notaMIm|notaLA;
		if (MIm&&SI)
			nota=notaMIm|notaSI;
		if (MIm&&DOM)
			nota=notaMIm|notaDOM;
		if (MIm&&REM)
			nota=notaMIm|notaREM;
		if (MIm&&MIM)
			nota=notaMIm|notaMIM;
			
		if (FAm&&SOLm)
			nota=notaFAm|notaSOLm;
		if (FAm&&LAm)
			nota=notaFAm|notaLAm;
		if (FAm&&SIm)
			nota=notaFAm|notaSIm;
		if (FAm&&DO)
			nota=notaFAm|notaDO;
		if (FAm&&RE)
			nota=notaFAm|notaRE;
		if (FAm&&MI)
			nota=notaFAm|notaMI;
		if (FAm&&FA)
			nota=notaFAm|notaFA;
		if (FAm&&SOL)
			nota=notaFAm|notaSOL;
		if (FAm&&LA)
			nota=notaFAm|notaLA;
		if (FAm&&SI)
			nota=notaFAm|notaSI;
		if (FAm&&DOM)
			nota=notaFAm|notaDOM;
		if (FAm&&REM)
			nota=notaFAm|notaREM;
		if (FAm&&MIM)
			nota=notaFAm|notaMIM;

		if (SOLm&&LAm)
			nota=notaSOLm|notaLAm;
		if (SOLm&&SIm)
			nota=notaSOLm|notaSIm;
		if (SOLm&&DO)
			nota=notaSOLm|notaDO;
		if (SOLm&&RE)
			nota=notaSOLm|notaRE;
		if (SOLm&&MI)
			nota=notaSOLm|notaMI;
		if (SOLm&&FA)
			nota=notaSOLm|notaFA;
		if (SOLm&&SOL)
			nota=notaSOLm|notaSOL;
		if (SOLm&&LA)
			nota=notaSOLm|notaLA;
		if (SOLm&&SI)
			nota=notaSOLm|notaSI;
		if (SOLm&&DOM)
			nota=notaSOLm|notaDOM;
		if (SOLm&&REM)
			nota=notaSOLm|notaREM;
		if (SOLm&&MIM)
			nota=notaSOLm|notaMIM;

		if (LAm&&SIm)
			nota=notaLAm|notaSIm;
		if (LAm&&DO)
			nota=notaLAm|notaDO;
		if (LAm&&RE)
			nota=notaLAm|notaRE;
		if (LAm&&MI)
			nota=notaLAm|notaMI;
		if (LAm&&FA)
			nota=notaLAm|notaFA;
		if (LAm&&SOL)
			nota=notaLAm|notaSOL;
		if (LAm&&LA)
			nota=notaLAm|notaLA;
		if (LAm&&SI)
			nota=notaLAm|notaSI;
		if (LAm&&DOM)
			nota=notaLAm|notaDOM;
		if (LAm&&REM)
			nota=notaLAm|notaREM;
		if (LAm&&MIM)
			nota=notaLAm|notaMIM;
		
		if (SIm&&DO)
			nota=notaSIm|notaDO;
		if (SIm&&RE)
			nota=notaSIm|notaRE;
		if (SIm&&MI)
			nota=notaSIm|notaMI;
		if (SIm&&FA)
			nota=notaSIm|notaFA;
		if (SIm&&SOL)
			nota=notaSIm|notaSOL;
		if (SIm&&LA)
			nota=notaSIm|notaLA;
		if (SIm&&SI)
			nota=notaSIm|notaSI;
		if (SIm&&DOM)
			nota=notaSIm|notaDOM;
		if (SIm&&REM)
			nota=notaSIm|notaREM;
		if (SIm&&MIM)
			nota=notaSIm|notaMIM;
		
		//Desde aqui comienza la generacion de acordes original
		if (DO&&RE)
			nota=notaDO|notaRE;
		if (DO&&MI)
			nota=notaDO|notaMI;
		if (DO&&FA)
			nota=notaDO|notaFA;
		if (DO&&SOL)
			nota=notaDO|notaSOL;
		if (DO&&LA)
			nota=notaDO|notaLA;
		if (DO&&SI)
			nota=notaDO|notaSI;
		if (DO&&DOM)
			nota=notaDO|notaDOM;
		if (DO&&REM)
			nota=notaDO|notaREM;
		if (DO&&MIM)
			nota=notaDO|notaMIM;
			
		if (RE&&MI)
			nota=notaRE|notaMI;
		if (RE&&FA)
			nota=notaRE|notaFA;
		if (RE&&SOL)
			nota=notaRE|notaSOL;
		if (RE&&LA)
			nota=notaRE|notaLA;
		if (RE&&SI)
			nota=notaRE|notaSI;
		if (RE&&DOM)
			nota=notaRE|notaDOM;
		if (RE&&REM)
			nota=notaRE|notaREM;
		if (RE&&MIM)
			nota=notaRE|notaMIM;
			
		if (MI&&FA)
			nota=notaMI|notaFA;
		if (MI&&SOL)
			nota=notaMI|notaSOL;
		if (MI&&LA)
			nota=notaMI|notaLA;
		if (MI&&SI)
			nota=notaMI|notaSI;
		if (MI&&DOM)
			nota=notaMI|notaDOM;
		if (MI&&REM)
			nota=notaMI|notaREM;
		if (MI&&MIM)
			nota=notaMI|notaMIM;
			
		if (FA&&SOL)
			nota=notaFA|notaSOL;
		if (FA&&LA)
			nota=notaFA|notaLA;
		if (FA&&SI)
			nota=notaFA|notaSI;
		if (FA&&DOM)
			nota=notaFA|notaDOM;
		if (FA&&REM)
			nota=notaFA|notaREM;
		if (FA&&MIM)
			nota=notaFA|notaMIM;
			
		if (SOL&&LA)
			nota=notaSOL|notaLA;
		if (SOL&&SI)
			nota=notaSOL|notaSI;
		if (SOL&&DOM)
			nota=notaSOL|notaDOM;
		if (SOL&&REM)
			nota=notaSOL|notaREM;
		if (SOL&&MIM)
			nota=notaSOL|notaMIM;
			
		if (LA&&SI)
			nota=notaLA|notaSI;
		if (LA&&DOM)
			nota=notaLA|notaDOM;
		if (LA&&REM)
			nota=notaLA|notaREM;
		if (LA&&MIM)
			nota=notaLA|notaMIM;
		
		if (SI&&DOM)
			nota=notaSI|notaDOM;
		if (SI&&REM)
			nota=notaSI|notaREM;
		if (SI&&MIM)
			nota=notaSI|notaMIM;
			
		if (DOM&&REM)
			nota=notaDOM|notaREM;
		if (DOM&&MIM)
			nota=notaDOM|notaMIM;
			
		if (REM&&MIM)
			nota=notaREM|notaMIM;
		
		//Nuevamente, lo mismo de antes, pero con triadas (acordes)
		//Solamente se generaran para las notas originales por simplicidad de codigo
		//Nota base DO
		if(DO&&RE&&MI)
			nota=notaDO|notaRE|notaMI;
		if(DO&&RE&&FA)
			nota=notaDO|notaRE|notaFA;
		if(DO&&RE&&SOL)
			nota=notaDO|notaRE|notaSOL;
		if(DO&&RE&&LA)
			nota=notaDO|notaRE|notaLA;
		if(DO&&RE&&SI)
			nota=notaDO|notaRE|notaSI;
		if(DO&&RE&&DOM)
			nota=notaDO|notaRE|notaDOM;
		if(DO&&MI&&FA)
			nota=notaDO|notaMI|notaFA;
		if(DO&&MI&&SOL)
			nota=notaDO|notaMI|notaSOL;
		if(DO&&MI&&LA)
			nota=notaDO|notaMI|notaLA;
		if(DO&&MI&&SI)
			nota=notaDO|notaMI|notaSI;
		if(DO&&MI&&DOM)
			nota=notaDO|notaMI|notaDOM;
		if(DO&&FA&&SOL)
			nota=notaDO|notaFA|notaSOL;
		if(DO&&FA&&LA)
			nota=notaDO|notaFA|notaLA;
		if(DO&&FA&&SI)
			nota=notaDO|notaFA|notaSI;
		if(DO&&FA&&DOM)
			nota=notaDO|notaFA|notaDOM;
		if(DO&&SOL&&LA)
			nota=notaDO|notaSOL|notaLA;
		if(DO&&SOL&&SI)
			nota=notaDO|notaSOL|notaSI;
		if(DO&&SOL&&DOM)
			nota=notaDO|notaSOL|notaDOM;
		if(DO&&LA&&SI)
			nota=notaDO|notaLA|notaSI;
		if(DO&&LA&&DOM)
			nota=notaDO|notaLA|notaDOM;
		if(DO&&SI&&DOM)
			nota=notaDO|notaSI|notaDOM;
		
		//Nota base RE
		if(RE&&MI&&FA)
			nota=notaRE|notaMI|notaFA;
		if(RE&&MI&&SOL)
			nota=notaRE|notaMI|notaSOL;
		if(RE&&MI&&LA)
			nota=notaRE|notaMI|notaLA;
		if(RE&&MI&&SI)
			nota=notaRE|notaMI|notaSI;
		if(RE&&MI&&DOM)
			nota=notaRE|notaMI|notaDOM;
		if(RE&&FA&&SOL)
			nota=notaRE|notaFA|notaSOL;
		if(RE&&FA&&LA)
			nota=notaRE|notaFA|notaLA;
		if(RE&&FA&&SI)
			nota=notaRE|notaFA|notaSI;
		if(RE&&FA&&DOM)
			nota=notaRE|notaFA|notaDOM;
		if(RE&&SOL&&LA)
			nota=notaRE|notaSOL|notaLA;
		if(RE&&SOL&&SI)
			nota=notaRE|notaSOL|notaSI;
		if(RE&&SOL&&DOM)
			nota=notaRE|notaSOL|notaDOM;
		if(RE&&LA&&SI)
			nota=notaRE|notaLA|notaSI;
		if(RE&&LA&&DOM)
			nota=notaRE|notaLA|notaDOM;
		if(RE&&SI&&DOM)
			nota=notaRE|notaSI|notaDOM;

		//Nota base MI
		if(MI&&FA&&SOL)
			nota=notaMI|notaFA|notaSOL;
		if(MI&&FA&&LA)
			nota=notaMI|notaFA|notaLA;
		if(MI&&FA&&SI)
			nota=notaMI|notaFA|notaSI;
		if(MI&&FA&&DOM)
			nota=notaMI|notaFA|notaDOM;
		if(MI&&SOL&&LA)
			nota=notaMI|notaSOL|notaLA;
		if(MI&&SOL&&SI)
			nota=notaMI|notaSOL|notaSI;
		if(MI&&SOL&&DOM)
			nota=notaMI|notaSOL|notaDOM;
		if(MI&&LA&&SI)
			nota=notaMI|notaLA|notaSI;
		if(MI&&LA&&DOM)
			nota=notaMI|notaLA|notaDOM;
		if(MI&&SI&&DOM)
			nota=notaMI|notaSI|notaDOM;
			
		//Nota base FA
		if(FA&&SOL&&LA)
			nota=notaFA|notaSOL|notaLA;
		if(FA&&SOL&&SI)
			nota=notaFA|notaSOL|notaSI;
		if(FA&&SOL&&DOM)
			nota=notaFA|notaSOL|notaDOM;
		if(FA&&LA&&SI)
			nota=notaFA|notaLA|notaSI;
		if(FA&&LA&&DOM)
			nota=notaFA|notaLA|notaDOM;
		if(FA&&SI&&DOM)
			nota=notaFA|notaSI|notaDOM;
		
		//Nota base SOL
		if(SOL&&LA&&SI)
			nota=notaSOL|notaLA|notaSI;
		if(SOL&&LA&&DOM)
			nota=notaSOL|notaLA|notaDOM;
		if(SOL&&SI&&DOM)
			nota=notaSOL|notaSI|notaDOM;
			
		//Nota base LA
		if(LA&&SI&&DOM)
			nota=notaLA|notaSI|notaDOM;
	end

	//Modificamos algunas variables
	wire enable;
	wire done;
	wire [11:0] data;
	wire [3:0] address;
	assign enable=1; 
	assign data={nota, 11'b00000000000};
	assign address=0; 
	
	//Llamamos al modulo DAC para convertir las notas en sonido 
	DAC mod(CLK, enable, done, data, address, SPI_MOSI, DAC_CS, SPI_SCK, DAC_CLR, SPI_MISO, SPI_SS_B, AMP_CS, AD_CONV, SF_CE0, FPGA_INIT_B);	
endmodule
