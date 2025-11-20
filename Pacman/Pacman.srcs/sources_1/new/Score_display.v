module Score_display
(
    input wire clk,rst,
    input wire new_score,
    input wire [13:0] score,
    input wire [9:0] x,y,
    output reg [7:0] sseg,            //7-segment display output(0-9)
    output reg [3:0] an,                //7-segment display anode output(4-bit)
    output reg score_on,                 //score display on signal
    output wire [11:0] color_data
);

//initial output for binary to bcd converter
wire [3:0] bcd3, bcd2, bcd1, bcd0;

//instantiate binary to bcd converter
binary2bcd binary2bcd_unit (.clk(clk), .rst(rst), .start(new_score), .in(score), .bcd3(bcd3), .bcd2(bcd2), .bcd1(bcd1), .bcd0(bcd0));

//instantiate bcd to 7-segment decoder
reg [3:0] decoder_reg, decoder_next;

//inder decoder register
always @(posedge clk, posedge rst)
    if(rst)
        decoder_reg <= 0;
    else
        decoder_reg <= decoder_next;

//decoder next state logic to 7-segment display
	always @*
		case(decoder_reg)
			0: sseg = 8'b10000001;
			1: sseg = 8'b11001111;
			2: sseg = 8'b10010010;
			3: sseg = 8'b10000110;
			4: sseg = 8'b11001100;
			5: sseg = 8'b10100100;
			6: sseg = 8'b10100000;
			7: sseg = 8'b10001111;
			8: sseg = 8'b10000000;
			9: sseg = 8'b10000100;
			default: sseg = 8'b11111111;
		endcase

// seven-segment multiplexing circuit @ 381 Hz
	reg [16:0] m_count_reg;
	
	// infer multiplexing counter register and next-state logic
	always @(posedge clk, posedge rst)
		if(rst)
			m_count_reg <= 0;
		else
			m_count_reg <= m_count_reg + 1;
	
// multiplex two digits using MSB of m_count_reg 
always @*
   case (m_count_reg[16:15])
      0: begin
         an = 4'b1110;
         decoder_next = bcd0; // Corrected assignment
         end
      1: begin
         an = 4'b1101;
         decoder_next = bcd1; // Corrected assignment
         end    
         
      2: begin
         an = 4'b1011;
         decoder_next = bcd2; // Corrected assignment
         end
         
      3: begin
         an = 4'b0111;
         decoder_next = bcd3; // Corrected assignment
         end 
   endcase
	
	// *** on screen score display ***
	
	// row and column regs to index numbers_rom
	reg [7:0] row;
	reg [3:0] col;
	
	// infer number bitmap rom
    Score_rom Score_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data));
	
	// display 4 digits on screen
	always @* 
		begin
		// defaults
		score_on = 0;
		row = 0;
		col = 0;
		
		// if vga pixel within bcd3 location on screen
		if(x >= 336 && x < 352 && y >= 16 && y < 32)
			begin
			col = x - 336;
			row = y - 16 + (bcd3 * 16); // offset row index by scaled bcd3 value
			if(color_data == 12'b000000000000)      // if bit is 1, assert score_on output
				score_on = 1;
			end
		
		// if vga pixel within bcd2 location on screen
		if(x >= 352 && x < 368 && y >= 16 && y < 32)
			begin
			col = x - 336;
			row = y - 16 + (bcd2 * 16); // offset row index by scaled bcd2 value
			if(color_data == 12'b000000000000)      // if bit is 1, assert score_on output
				score_on = 1;
			end
		
		// if vga pixel within bcd1 location on screen
		if(x >= 368 && x < 384 && y >= 16 && y < 32)
			begin
			col = x - 336;
			row = y - 16 + (bcd1 * 16); // offset row index by scaled bcd1 value
			if(color_data == 12'b000000000000)      // if bit is 1, assert score_on output
				score_on = 1;
			end
		
		// if vga pixel within bcd0 location on screen
		if(x >= 384 && x < 400 && y >= 16 && y < 32)
			begin
			col = x - 336;
			row = y - 16 + (bcd0 * 16); // offset row index by scaled bcd0 value
			if(color_data == 12'b000000000000)      // if bit is 1, assert score_on output
				score_on = 1;
			end
		end
		

endmodule
