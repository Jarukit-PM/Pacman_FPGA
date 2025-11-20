module Ghost_blue
(
    input wire clk,rst,
    input wire [9:0] pacman_x, pacman_y,        //pacman's current location within display area
    input wire [9:0] x,y,                      //location of VGA pixel
    input wire [25:0] speed_offset,            //speed of ghost depends on score
    output wire [9:0] blue_x, blue_y,          //Blue ghost's current location within display area
    output reg ghost_blue_on,                //ghost blue on signal
    output reg [11:0] rgb_out                //rgb output signal
);

//constants declaration
//pixel coordinates boundaries for VGA display area
localparam MAX_X = 640;
localparam MAX_Y = 480;

//tile width and height
localparam T_W = 16;
localparam T_H = 16;

/***********************************************************************************/
/*                           sprite location registers                             */
/***********************************************************************************/
//sprite location registers(Blue ghost)
reg [9:0] s_x_reg, s_x_next;
reg [9:0] s_y_reg, s_y_next;

//initialize sprite location registers(Bottom right corner of display area)
always @(posedge clk, posedge rst)
begin
    if(rst)
        begin
            s_x_reg <= MAX_X - 2*T_W;
            s_y_reg <= MAX_Y - 2*T_H;
        end
    else
        begin
            s_x_reg <= s_x_next;
            s_y_reg <= s_y_next;
        end
end

/***********************************************************************************/
/*                           wall detection logic                             */
/***********************************************************************************/
function check_wall(input [9:0] x, y);
    if ((x >= 192 && x <= 208 && y >= 16 && y <= 96) ||
        (x >= 448 && x <= 464 && y >= 16 && y <= 96) ||
        (x >= 192 && x <= 208 && y >= 384 && y <= 464) ||
        (x >= 448 && x <= 464 && y >= 384 && y <= 464) ||
        (x >= 48 && x <= 64 && y >= 80 && y <= 176) ||
        (x >= 48 && x <= 144 && y >= 80 && y <= 96) ||
        (x >= 496 && x <= 576 && y >= 80 && y <= 96) ||
        (x >= 576 && x <= 592 && y >= 80 && y <= 176) ||
        (x >= 48 && x <= 64 && y >= 304 && y <= 384) ||
        (x >= 48 && x <= 144 && y >= 384 && y <= 400) ||
        (x >= 496 && x <= 592 && y >= 384 && y <= 400) ||
        (x >= 576 && x <= 592 && y >= 304 && y <= 384) ||
        (x >= 256 && x <= 400 && y >= 48 && y <= 64) ||
        (x >= 256 && x <= 400 && y >= 416 && y <= 432) ||
        (x >= 128 && x <= 240 && y >= 160 && y <= 176) ||
        (x >= 384 && x <= 496 && y >= 160 && y <= 176) ||
        (x >= 128 && x <= 240 && y >= 288 && y <= 304) ||
        (x >= 384 && x <= 496 && y >= 288 && y <= 304) ||
        (x >= 256 && x <= 368 && y >= 192 && y <= 272))
        check_wall = 1;
    else
        check_wall = 0;
endfunction


/***********************************************************************************/
/*                           Direction Register                                    */
/***********************************************************************************/
localparam [1:0] LEFT = 2'b00,
                RIGHT = 2'b01,
                UP = 2'b10,
                DOWN = 2'b11;

reg [1:0] dir_reg, dir_next;

//initialize direction register
always @(posedge clk, posedge rst)
begin
    if(rst)
        dir_reg <= LEFT;
    else
        dir_reg <= dir_next;
end

//direction register next state logic(depend on pacman location(pacman_x, pacman_y))
always @*
    begin
    //default
    dir_next = dir_reg;
    if(pacman_x < s_x_reg)
        dir_next = LEFT;
    else if(pacman_x > s_x_reg)
        dir_next = RIGHT;
    else if(pacman_y < s_y_reg)
        dir_next = UP;
    else if(pacman_y > s_y_reg)
        dir_next = DOWN;
    end

/***********************************************************************************/
/*                           Sprite motion                                         */
/***********************************************************************************/

localparam TIME_MAX = 4600000; //(second / 25MHz) = 0.184s

reg [25:0] time_reg;             //time register to keep track of time
wire [25:0] time_next;           
wire time_reg_max;                //to keep that time_reg is at max value

//initialize time register
always @(posedge clk, posedge rst)
begin
    if(rst)
        time_reg <= 0;
    else
        time_reg <= time_next;
end

//next state logic for time register, increment time_reg by 1 every clock cycle
assign time_next = (time_reg < TIME_MAX - speed_offset) ? time_reg + 1 : 0;

//time register max logic
assign time_reg_max = (time_reg == TIME_MAX - speed_offset) ? 1 : 0;

//sprite location next state logic
always @(posedge time_reg_max, posedge rst)
    begin
        //default
        s_x_next = s_x_reg;
        s_y_next = s_y_reg;
        if(rst)
            begin
                s_x_next = MAX_X - 2*T_W;
                s_y_next = MAX_Y - 2*T_H;
            end

        //move sprite left
        else if(pacman_x < s_x_reg && !check_wall(s_x_reg - 1, s_y_reg))
            s_x_next = s_x_reg - 1;
        
        //move sprite right
        else if(pacman_x > s_x_reg && !check_wall(s_x_reg + 1, s_y_reg))
            s_x_next = s_x_reg + 1;

        //move sprite up
        else if(pacman_y < s_y_reg && !check_wall(s_x_reg, s_y_reg - 1))
            s_y_next = s_y_reg - 1;

        //move sprite down
        else if(pacman_y > s_y_reg && !check_wall(s_x_reg, s_y_reg + 1))
            s_y_next = s_y_reg + 1;
        
    end


/***********************************************************************************/
/*                          Blue ghost display area logic                          */
/***********************************************************************************/
wire [3:0] row;
wire [3:0] col;

//current pixel coordinates - current sprite coordinates = pixe coordinates within display area
assign col = (dir_reg == LEFT && ghost_blue_area) ? T_W - 1 - (x - s_x_reg) : 
             (dir_reg == RIGHT && ghost_blue_area) ? x - s_x_reg : 
             (dir_reg == UP && ghost_blue_area) ? x - s_x_reg : 
             (dir_reg == DOWN && ghost_blue_area) ? x - s_x_reg : 0;

assign row = (dir_reg == LEFT && ghost_blue_area) ? y - s_y_reg :
            (dir_reg == RIGHT && ghost_blue_area) ? y - s_y_reg :
            (dir_reg == UP && ghost_blue_area) ? y - s_y_reg :
            (dir_reg == DOWN && ghost_blue_area) ? y - s_y_reg : 0;
        

//Blue ghost rom
wire [11:0] color_data_Blue_ghost;
Blue_Ghost_rom Blue_Ghost_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data_Blue_ghost));

//check if pixel is within display area
wire ghost_blue_area;
assign ghost_blue_area = (x >= s_x_reg && x <= s_x_reg + T_W - 1  && y >= s_y_reg && y <= s_y_reg + T_H - 1) ? 1 : 0;

//assign output
assign blue_x = s_x_reg;
assign blue_y = s_y_reg;

//ghost blue on signal and rgb output
always @*
    begin 
        if(ghost_blue_area)
            begin
                ghost_blue_on = 1;
                rgb_out = color_data_Blue_ghost;
            end
        else
            begin
                ghost_blue_on = 0;
                rgb_out = 12'b0;
            end
    end
endmodule