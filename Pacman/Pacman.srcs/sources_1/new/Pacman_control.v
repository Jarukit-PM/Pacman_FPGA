module Pacman_control
(
    input wire clk,rst,
    input wire btnL, btnR,btnU, btnD,
    input wire video_on,   
    input wire [9:0] x, y,
    input wire game_over,
    input wire collision,
    output reg [11:0] rgb_out,
    output reg pacman_on,
    output wire [9:0] pacman_x, pacman_y,       //output signals for pacman's current location within display area
    output wire [1:0] direction                       //output signal conveying pacman's direction of motion
);

//constants declaration
//pixel coordinate boundaries for VGA display area
localparam MAX_X = 640;
localparam MAX_Y = 480;

//tile width and height
localparam T_W = 16;
localparam T_H = 16;

/***********************************************************************************/
/*                           sprite location registers                             */
/***********************************************************************************/
//sprite coordinate registers(pacman's current location within display area)
reg [9:0] s_x_reg, s_y_reg;
reg [9:0] s_x_next, s_y_next;

//initial sprite location (left corner of display area)
always @(posedge clk, posedge rst)
    if (rst)
        begin
        s_x_reg <= 17;
        s_y_reg <= 17;
        end
    else
        begin
        s_x_reg <= s_x_next;
        s_y_reg <= s_y_next;
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
/*                           Direction Register                                     */
/***********************************************************************************/
localparam [1:0] LEFT = 2'b00,
                RIGHT = 2'b01,
                UP = 2'b10,
                DOWN = 2'b11;

reg [1:0] dir_reg, dir_next;

//initial direction register
always @(posedge clk, posedge rst)
    if (rst)
        begin
        dir_reg <= RIGHT;        //Default direction is right
        end
    else
        begin
        dir_reg <= dir_next;
        end

//direction register next-state logic
always @*
    begin
    //default
    dir_next = dir_reg;

    if(btnL && !btnR && !btnU && !btnD) //if left button is pressed, set direction to left
        dir_next = LEFT;
    else if(btnR && !btnL && !btnU && !btnD) //if right button is pressed, set direction to right
        dir_next = RIGHT;
    else if(btnU && !btnL && !btnR && !btnD) //if up button is pressed, set direction to up
        dir_next = UP;
    else if(btnD && !btnL && !btnR && !btnU) //if down button is pressed, set direction to down
        dir_next = DOWN;
    end
/***********************************************************************************/
/*                           FSMD for x and y motion                               */
/***********************************************************************************/
localparam [2:0] no_dir = 3'b000,
                left = 3'b001,
                right = 3'b010,
                up = 3'b011,
                down = 3'b100;

reg [2:0] motion_state_reg, motion_state_next;          //motion state of pacman
reg [19:0] time_reg, time_next;                         //time counter for each motion state (time to wait before pacman starts moving) (speed)
reg [19:0] start_reg, start_next;                       //time counter for each motion state
localparam TIME_START = 800000;                         //time to wait before pacman starts moving
localparam TIME_STEP = 6000;                            //time step for each motion state
localparam TIME_MIN = 500000;                           //minimum time to wait before pacman starts moving  

//initial motion state
always @(posedge clk, posedge rst)
    if (rst)
        begin
        motion_state_reg <= no_dir;
        time_reg <= 0;
        start_reg <= 0;
            
        end
    else
        begin
        motion_state_reg <= motion_state_next;
        time_reg <= time_next;
        start_reg <= start_next;
        end

//FSM next-state logic and data path
always @*
    begin
    //default
    motion_state_next = motion_state_reg;
    s_x_next = s_x_reg;
    s_y_next = s_y_reg;
    time_next = time_reg;
    start_next = start_reg;
    case(motion_state_reg)

    no_dir:
        begin
        if(btnL && !btnR && !btnU && !btnD && (s_x_reg >= 1))
            begin
            motion_state_next = left;
            time_next = TIME_START;
            start_next = TIME_START;
            end
        else if(btnR && !btnL && !btnU && !btnD && (s_x_reg + 1 < MAX_X - T_W  + 1))
            begin
            motion_state_next = right;
            time_next = TIME_START;
            start_next = TIME_START;
            end
        else if(btnU && !btnL && !btnR && !btnD && (s_y_reg >= 1))
            begin
            motion_state_next = up;
            time_next = TIME_START;
            start_next = TIME_START;
            end
        else if(btnD && !btnL && !btnR && !btnU && (s_y_reg + 1 < MAX_Y - T_H + 1))    
            begin
            motion_state_next = down;
            time_next = TIME_START;
            start_next = TIME_START;
            end
        end
    
    left:
        begin
        if(time_reg > 0)                                            //wait for time_reg to reach 0 before moving pacman 
            time_next = time_reg - 1;
        else if(time_reg == 0)
            begin
            if(s_x_reg >= 17 && !check_wall(s_x_reg - 1, s_y_reg))      //if pacman can move left, and next pixel is not a wall, decrement s_x_reg by 1(move left)
                s_x_next = s_x_reg - 1;
            if(!btnL || btnR || btnU || btnD)                       // Reset motion state to no_dir if btnL is uspressed or btnR, btnU, btnD are pressed
                begin
                motion_state_next = no_dir;
                start_next = 0;
                end
            if(start_reg > TIME_MIN)                           // If btnL is pressed and start_reg is greater than TIME_MIN, decrement start_reg by TIME_STEP
                begin
                time_next = start_reg - TIME_STEP;
                start_next = start_reg - TIME_STEP;
                end
            else
                begin
                    time_next = start_reg;
                    start_next = start_reg;
                end
            end
        end

    right:
        begin
        if(time_reg > 0)
            time_next = time_reg - 1;
        else if(time_reg == 0)
            begin
            if((s_x_reg + 1 < MAX_X - T_W - 15) && !check_wall(s_x_reg + 15, s_y_reg))
                s_x_next = s_x_reg + 1;
            if(!btnR || btnL || btnU || btnD) // Reset motion state to no_dir if btnR is uspressed or btnL, btnU, btnD are pressed
                begin
                motion_state_next = no_dir;
                start_next = 0;
                end
            if(start_reg > TIME_MIN)
                begin
                time_next = start_reg - TIME_STEP;
                start_next = start_reg - TIME_STEP;
                end
            else
                begin
                    time_next = start_reg;
                    start_next = start_reg;
                end
            end
        end
    
    up:
        begin
        if(time_reg > 0)
            time_next = time_reg - 1;
        else if(time_reg == 0)
            begin
            if(s_y_reg >= 17 && !check_wall(s_x_reg, s_y_reg - 1))
                s_y_next = s_y_reg - 1;
            if(!btnU || btnR || btnL || btnD) // Reset motion state to no_dir if btnU is uspressed or btnR, btnL, btnD are pressed
                begin
                motion_state_next = no_dir;
                start_next = 0;
                end
            if(btnU && start_reg > TIME_MIN)
                begin
                time_next = start_reg - TIME_STEP;
                start_next = start_reg - TIME_STEP;
                end
            else
                begin
                    time_next = start_reg;
                    start_next = start_reg;
                end
            end
        end
    
    down:
        begin
        if(time_reg > 0)
            time_next = time_reg - 1;
        else if(time_reg == 0)
            begin
            if(s_y_reg + 1 < MAX_Y - T_H - 15 && !check_wall(s_x_reg, s_y_reg + 15))
                s_y_next = s_y_reg + 1;
            if(!btnD || btnR || btnU || btnL) // Reset motion state to no_dir if btnD is uspressed or btnR, btnU, btnL are pressed
                begin
                motion_state_next = no_dir;
                start_next = 0;
                end
            if(btnD && start_reg > TIME_MIN)
                begin
                time_next = start_reg - TIME_STEP;
                start_next = start_reg - TIME_STEP;
                end
            else
                begin
                    time_next = start_reg;
                    start_next = start_reg;
                end
            end

        end
    endcase
    end

/***********************************************************************************/
/*                           Pacman display area logic                             */
/***********************************************************************************/
//Pacman display area boundaries
wire [3:0] row;
wire [3:0] col;

//current pixel coordinates - current sprite coordinates = pixel coordinates within pacman area
assign col = (dir_reg == LEFT && pacman_area) ? T_W - 1 - (x - s_x_reg) : 
             (dir_reg == RIGHT && pacman_area) ? x - s_x_reg : 
             (dir_reg == UP && pacman_area) ? x - s_x_reg : 
             (dir_reg == DOWN && pacman_area) ? x - s_x_reg : 0;

assign row = (dir_reg == LEFT && pacman_area) ? y - s_y_reg :
            (dir_reg == RIGHT && pacman_area) ? y - s_y_reg :
            (dir_reg == UP && pacman_area) ? y - s_y_reg :
            (dir_reg == DOWN && pacman_area) ? y - s_y_reg : 0;

                                                                                                                                                                                                                                                                                                                      
//Pacman rom
//vector for rom color_data output
wire [11:0] color_data_pacman, color_data_pacman_ghost;
Pacman_rom Pacman_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data_pacman));
Pacman_Ghost_rom Pacman_ghost_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data_pacman_ghost));




//vector to signal when vga_sync is in the pacman area
wire pacman_area;
assign pacman_area = (x >= s_x_reg && x <= s_x_reg + T_W - 1 && y >= s_y_reg && y <= s_y_reg + T_H - 1) ? 1 : 0;

//assign module output signals
assign pacman_x = s_x_reg;
assign pacman_y = s_y_reg;
assign direction = dir_reg;

//if collision occurs, turn pacman into ghost for 2 seconds (12000000 cycles)
reg [27:0] collision_time_reg;
wire [27:0] collision_time_next;

always @(posedge clk, posedge rst)
    if (rst)
        begin
        collision_time_reg <= 0;
        end
    else
        begin
        collision_time_reg <= collision_time_next;
        end

//when collision occurs, set collision_time_next to 200000000 (2 seconds)
assign collision_time_next = (collision) ? 200000000 : 
                                (collision_time_reg > 0) ? collision_time_reg - 1 : 0;

//rgb output
always @*
    begin
    //default
    pacman_on = 0;
    rgb_out = 0;
    if(pacman_area && video_on)
        begin
            if(game_over || collision_time_reg > 0) //if collision occurs or game over, turn pacman into ghost
                begin
                rgb_out = color_data_pacman_ghost;
                pacman_on = 1;
                end
            else
                begin
                rgb_out = color_data_pacman;
                pacman_on = 1;
                end
        end
    end
endmodule