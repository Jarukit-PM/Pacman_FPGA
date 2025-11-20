module top_module
(
    input wire clk,
    input wire Phycal_rst,
    input wire btnL, btnR,
    input wire btnU, btnD,
    input wire start_btn,                               //start button
    output wire vga_hsync,vga_vsync,
    output wire [11:0] vga_color
);

    wire video_on,pixel_tick;                   //route VGA signals
    wire [9:0] x,y;                             //location of VGA pixel
    reg [11:0] rgb_reg, rgb_next;               //rgb output

    //pacman control signals
    wire [9:0] pacman_x, pacman_y;              //pacman's current location within display area
    wire [1:0] direction;                             //pacman's direction of motion

    //ghost control signals
    wire [9:0] blue_x, blue_y;                  //Ghost's blue current location within display area
    wire [9:0] red_x, red_y;                    //Ghost's red current location within display area

    //Heart display signals
    wire [1:0] num_hearts;                      //number of hearts to display (get from game state machine) (0-3)

    wire collision;                             //collision signal

    //Game state machine signals
    wire [1:0] game_state;                      //(start,playing,hit,gameover)
    wire game_en;                               //game enable signal
    wire game_reset;                            //reset game use with reset button
    localparam [1:0] start = 2'b00,
                    playing = 2'b01,
                    hit = 2'b10,
                    gameover = 2'b11;

    //reset signal
    wire rst;
    assign rst = Phycal_rst || game_reset;
    


    wire [25:0] speed_offset_blue,speed_offset_red;                   //speed of ghost depends on score
    assign speed_offset_blue = 2750000; //need to edit (2750000 = half of time max for ghost to move one tile)
    assign speed_offset_red = 3200000; //need to edit 

    //Color definitions
    wire [11:0] bg_rgb, walls_rgb, pacman_rgb , ghost_blue_rgb, ghost_red_rgb , hearts_rgb;

    //On signals
    wire walls_on, pacman_on, ghost_blue_on, ghost_red_on, hearts_on;



    //Game over signal(for pacman control)
    wire game_over;
    assign game_over = (game_state == gameover)? 1:0;

   //assign direction of pacman
   wire pacman_up, pacman_down, pacman_left, pacman_right;
   assign pacman_up = btnU && game_en;        
   assign pacman_down = btnD && game_en;
   assign pacman_left = btnL && game_en;
   assign pacman_right = btnR && game_en;
    
    
	// instantiate vga_sync circuit
    vga_sync vsync_unit (.clk(clk), .reset(Phycal_rst), .hsync(vga_hsync), .vsync(vga_vsync),
                             .video_on(video_on), .p_tick(pixel_tick), .x(x), .y(y));
                             
    // instantiate Background rom 
    Background_rom Background_unit (.clk(clk), .row(y[7:0]), .col(x[7:0]), .color_data(bg_rgb));

    // instantiate Walls 
    Walls Walls_unit (.clk(clk), .video_on(video_on), .x(x), .y(y), .rgb_out(walls_rgb), .walls_on(walls_on));

    // instantiate Pacman control
    Pacman_control Pacman_unit (.clk(clk), .rst(rst), .btnL(pacman_left), .btnR(pacman_right), .btnU(pacman_up), .btnD(pacman_down), 
                                .video_on(video_on), .x(x), .y(y), .game_over(game_over), .collision(collision), 
                                .rgb_out(pacman_rgb), .pacman_on(pacman_on), .pacman_x(pacman_x), 
                                .pacman_y(pacman_y), .direction(direction));

    // instantiate Ghost_blue
    Ghost_blue Ghost_blue_unit (.clk(clk), .rst(rst), .pacman_x(pacman_x), .pacman_y(pacman_y), .x(x), .y(y), 
                                .speed_offset(speed_offset_blue), .blue_x(blue_x), .blue_y(blue_y), 
                                .ghost_blue_on(ghost_blue_on), .rgb_out(ghost_blue_rgb));

    // instantiate Ghost_red
    Ghost_red Ghost_red_unit (.clk(clk), .rst(rst), .pacman_x(pacman_x), .pacman_y(pacman_y), .x(x), .y(y), 
                                .speed_offset(speed_offset_red), .red_x(red_x), .red_y(red_y), 
                                .ghost_red_on(ghost_red_on), .rgb_out(ghost_red_rgb));

    // instantiate Check_collision
    Check_collision Check_collision_unit (.direction(direction), .pacman_x(pacman_x), .pacman_y(pacman_y), 
                                            .blue_x(blue_x), .blue_y(blue_y), .red_x(red_x), .red_y(red_y), 
                                            .collision(collision));

    // instantiate Hearts_display
    Hearts_display Hearts_display_unit (.clk(clk), .x(x), .y(y), .num_hearts(num_hearts), .color_data(hearts_rgb), 
                                        .hearts_on(hearts_on));

    // instantiate Game_state_machine
    Game_state_machine Game_state_machine_unit (.clk(clk), .rst(Phycal_rst), .start_btn(start_btn), .collision(collision), 
                                                .num_hearts(num_hearts), .game_state(game_state), 
                                                .game_en(game_en), .game_reset(game_reset));


    always @*
        begin
        if(~video_on)
            rgb_next = 12'b0; //Black
        else if(walls_on)
            rgb_next = walls_rgb;

        else if(pacman_on && game_state == !start)
            rgb_next = pacman_rgb;
        
        else if(ghost_blue_on && game_state == !start)
            rgb_next = ghost_blue_rgb;
        
        else if(ghost_red_on && game_state == !start)
            rgb_next = ghost_red_rgb;
        
        else if(hearts_on)
            rgb_next = hearts_rgb;
        else
            rgb_next =  bg_rgb;
        
        end


	// rgb buffer register
	always @(posedge clk)
		if (pixel_tick)
			rgb_reg <= rgb_next;		
			
	// output rgb data to VGA DAC
	assign vga_color = rgb_reg;

endmodule
