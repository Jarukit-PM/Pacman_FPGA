module Stars
(
    input wire clk,rst,
    input wire [9:0] pacman_x, pacman_y,
    input [1:0]direction,
    input wire [9:0] x,y,
    output wire stars_on,
    output wire [11:0] color_data, 
    output wire [13:0] score,
    output wire new_score
);

localparam [1:0] LEFT = 2'b00,
                RIGHT = 2'b01,
                UP = 2'b10,
                DOWN = 2'b11;


//location of stars
reg [9:0] star_x_reg, star_y_reg;
reg [9:0] star_x_next, star_y_next;

//infer star location
always @ (posedge clk, posedge rst)
begin
    if (rst)
    begin
        star_x_reg <= 296;
        star_y_reg <= 364;
    end
    else
    begin
        star_x_reg <= star_x_next;
        star_y_reg <= star_y_next;
    end
end


//register to area of stars that can generate points (10 areas)
reg [2:0] area_select_reg;
wire [2:0] area_select_next;

//infer area of stars that can generate points
always @ (posedge clk, posedge rst)
begin
    if (rst)
    begin
        area_select_reg <= 6;
    end
    else
    begin
        area_select_reg <= area_select_next;
    end
end

assign area_select_next = area_select_reg + 1;
//Area location register
//when new star spawns, it will be assigned to one of the 10 areas
reg [7:0] B32_reg; //Block B31 [48 - 144]
reg [9:0] B21_reg; //Block B21 [496 - 576]
reg [9:0] B41_reg; //Block B41 [496 - 592]

reg [8:0] C1_reg; //Block C1 [256 - 400]
reg [8:0] C2_reg; //Block C2 [256 - 400]

reg [7:0] D1_reg; //Block D1 [128 - 240]
reg [8:0] D2_reg; //Block D2 [384 - 496]
reg [8:0] D4_reg; //Block D4 [384 - 496]

//infer area location
always @ (posedge clk, posedge rst)
begin
    if (rst)
    begin
        B32_reg <= 64;
        B21_reg <= 496;
        B41_reg <= 496;

        C1_reg <= 256;
        C2_reg <= 256;

        D1_reg <= 128;
        D2_reg <= 384;
        D4_reg <= 384;
    end
    else
    begin
        B32_reg <= (B32_reg <= 144)? B32_reg + 1 : 48;
        B21_reg <= (B21_reg <= 576)? B21_reg + 1 : 496;
        B41_reg <= (B41_reg <= 576)? B41_reg + 1 : 496;

        C1_reg <= (C1_reg <= 400)? C1_reg + 1 : 256;
        C2_reg <= (C2_reg <= 400)? C2_reg + 1 : 256;
        
        D1_reg <= (D1_reg <= 240)? D1_reg + 1 : 128;
        D2_reg <= (D2_reg <= 496)? D2_reg + 1 : 384;
        D4_reg <= (D4_reg <= 496)? D4_reg + 1 : 384;

    end
end

//star FSM state register
reg [1:0] star_state_reg, star_state_next;
localparam waitting = 1'b0,             //waitting for pacman to eat 
            respawn = 1'b1;             //respawn after pacman eat

//infer star FSM state
always @ (posedge clk, posedge rst) 
begin
    if(rst)
    begin
        star_state_reg <= waitting;
    end
    else
        star_state_reg <= star_state_next;
end

//star FSM next state logic
always @ (*)
    begin
        //default
        star_state_next = star_state_reg;
        star_x_next = star_x_reg;
        star_y_next = star_y_reg;
        new_score_next = 0;

        case(star_state_reg)

            waitting:               //star already exist, waitting for pacman to eat
                begin
                    
                    //if pacman collide with facing LEFT
                    if(direction == LEFT && pacman_x - 13 <= star_x_reg && pacman_x >= star_x_reg - 13 && pacman_y - 13 <= star_y_reg && pacman_y >= star_y_reg - 13)
                        begin
                            star_state_next = respawn;
                            new_score_next = 1;
                        end
                    
                    //if pacman collide with facing RIGHT
                    else if(direction == RIGHT && pacman_x + 13 >= star_x_reg && pacman_x <= star_x_reg + 13 && pacman_y - 13 <= star_y_reg && pacman_y >= star_y_reg - 13)
                        begin
                            star_state_next = respawn;
                            new_score_next = 1;
                        end
                    
                    //if pacman collide with facing UP
                    else if(direction == UP && pacman_x - 13 <= star_x_reg && pacman_x >= star_x_reg - 13 && pacman_y - 13 <= star_y_reg && pacman_y >= star_y_reg - 13)
                        begin
                            star_state_next = respawn;
                            new_score_next = 1;
                        end

                    //if pacman collide with facing DOWN    
                    else if(direction == DOWN && pacman_x - 13 <= star_x_reg && pacman_x >= star_x_reg - 13 && pacman_y + 13 >= star_y_reg && pacman_y <= star_y_reg + 13)
                        begin
                            star_state_next = respawn;
                            new_score_next = 1;
                        end
                end

            
            respawn:                //star respawn after pacman eat
                begin
                    if(area_select_reg == 0) //B32
                        begin
                            star_y_next = 368;       //(on top of area)
                            star_x_next = B32_reg;
                        end
                    else if(area_select_reg == 1) //B21
                        begin
                            star_y_next = 64;
                            star_x_next = B21_reg;
                        end
                    else if(area_select_reg == 2) //B41
                        begin
                            star_y_next = 368;
                            star_x_next = B41_reg;
                        end
                    else if(area_select_reg == 3) //C1
                        begin
                            star_y_next = 32;
                            star_x_next = C1_reg;
                        end
                    else if(area_select_reg == 4) //C2
                        begin   
                            star_y_next = 400;
                            star_x_next = C2_reg;
                        end
                    else if(area_select_reg == 5) //D1
                        begin
                            star_y_next = 144;
                            star_x_next = D1_reg;
                        end
                    else if(area_select_reg == 6) //D2
                        begin
                            star_y_next = 144;
                            star_x_next = D2_reg;
                        end
                    else                    //area_select = 7 (D4)
                        begin
                            star_y_next = 224;
                            star_x_next = D4_reg;
                        end

                    star_state_next = waitting;
                end


                
        endcase
    end

//new score register , signal when a new score is calculated
reg new_score_reg, new_score_next;

//infer new score
always @ (posedge clk, posedge rst)
begin
    if (rst)
    begin
        new_score_reg <= 0;
    end
    else
    begin
        new_score_reg <= new_score_next;
    end
end

assign new_score = new_score_reg;

//score reg and next state logic
reg [13:0] score_reg;
wire [13:0] score_next;

//infer score
always @ (posedge clk, posedge rst)
begin
    if (rst)
    begin
        score_reg <= 0;
    end
    else
    begin
        score_reg <= score_next;
    end
end

//score update logic
assign score_next = (rst || new_score_next && score_reg == 9999)? 0 : score_reg + 10;

//output score
assign score = score_reg;

//sprite coordinate register to display stars
wire [3:0] col;
wire [3:0] row;

//current pixel coordinate - star coordinate = pixel coordinate of star
assign col = x - star_x_reg;
assign row = y - star_y_reg;
wire [11:0] color_data_star;

Star_rom Star_rom_unit (.clk(clk), .col(col), .row(row), .color_data(color_data_star));

//assign stars_on for output
assign stars_on = (x >= star_x_reg && x < star_x_reg + 16 && y >= star_y_reg && y < star_y_reg + 16 && color_data != 12'b111111111110)? 1 : 0;

//assign rgb_out for output
assign color_data = color_data_star;

endmodule

