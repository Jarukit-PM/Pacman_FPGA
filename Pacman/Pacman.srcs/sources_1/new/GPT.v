module Pacman_control
    (
        input wire clk, rst,         // clock/rst inputs for synchronous registers 
        input wire btnL, btnR, btnU, btnD, // inputs used to move Pacman
        input wire video_on,           // input from vga_sync signaling when video signal is on
        input wire [9:0] x, y,         // current pixel coordinates from vga_sync circuit
        output reg [11:0] rgb_out,     // output rgb signal for current Pacman pixel
        output reg pacman_on,          // output signal asserted when input x/y are within Pacman sprite in display area
        output wire [9:0] pacman_x, pacman_y,    // output signals for Pacman sprite's current location within display area
        output wire direction          // output signal conveying Pacman's direction of motion
    );
   
    // constant declarations
    // pixel coordinate boundaries for VGA display area
    localparam MAX_X = 640;
    localparam MAX_Y = 480;
   
    // tile width and height
    localparam T_W = 16;
    localparam T_H = 16;
   
    // Pacman sprite size
    localparam PACMAN_SIZE = 16;
   
    /***********************************************************************************/
    /*                           sprite location registers                             */  
    /***********************************************************************************/
    // Pacman sprite location regs, pixel location with respect to top left corner
    reg [9:0] p_x_reg, p_y_reg;
    reg [9:0] p_x_next, p_y_next;
   
    // infer registers for sprite location
    always @(posedge clk, posedge rst)
        if (rst)
            begin
            p_x_reg     <= 320;            // initialize to middle of screen,
            p_y_reg     <= 240;            // initialize to middle of screen
            end
        else
            begin
            p_x_reg     <= p_x_next;
            p_y_reg     <= p_y_next;
            end
   
    /***********************************************************************************/
    /*                                direction register                               */  
    /***********************************************************************************/
    // symbolic states for Pacman motion
    localparam UP    = 2'b00;
    localparam DOWN  = 2'b01;
    localparam LEFT  = 2'b10;
    localparam RIGHT = 2'b11;
   
    reg dir_reg, dir_next;
   
    // infer register
    always @(posedge clk, posedge rst)
        if (rst)
            dir_reg     <= RIGHT;
        else
            dir_reg     <= dir_next;
    
	// direction register next-state logic
    always @*
        begin
        dir_next = dir_reg;   // default, stay the same
       
        if(btnU && !btnD)     // if up button pressed, change value to UP
            dir_next = UP;  
           
        if(btnD && !btnU)     // if down button pressed, change value to DOWN
            dir_next = DOWN;
           
        if(btnL && !btnR)     // if left button pressed, change value to LEFT
            dir_next = LEFT;  
           
        if(btnR && !btnL)     // if right button pressed, change value to RIGHT
            dir_next = RIGHT;
        end
   
    /***********************************************************************************/
    /*                           FSMD for x and y motion                              */  
    /***********************************************************************************/
   
    // symbolic state representations for FSM
    localparam no_dir = 3'b000;
    localparam up     = 3'b001;
    localparam down   = 3'b010;
    localparam left   = 3'b011;
    localparam right  = 3'b100;

    // constant parameters that determine motion speed              
    localparam SPEED_X = 2;  // speed in x direction
    localparam SPEED_Y = 2;  // speed in y direction
               
    reg [2:0] motion_state_reg, motion_state_next;  // register for FSMD motion state
    reg [11:0] x_time_reg, x_time_next;             // register to keep track of x motion time
    reg [11:0] y_time_reg, y_time_next;             // register to keep track of y motion time
   
    // infer registers for FSMD state and motion time
    always @(posedge clk, posedge rst)
        if (rst)
            begin
            motion_state_reg <= no_dir;
            x_time_reg       <= 0;
            y_time_reg       <= 0;
            end
        else
            begin
            motion_state_reg <= motion_state_next;
            x_time_reg       <= x_time_next;
            y_time_reg       <= y_time_next;
            end
   
    // FSM next-state logic and data path
    always @*
        begin
        // defaults
        p_x_next        = p_x_reg;
        p_y_next        = p_y_reg;
        motion_state_next = motion_state_reg;
        x_time_next      = x_time_reg;
        y_time_next      = y_time_reg;
       
        case (motion_state_reg)
            
            no_dir:
                begin
                if(btnL && !btnR && (p_x_reg >= SPEED_X))                       // if left button pressed and can move left                  
                    begin
                    motion_state_next = left;                                    // go to left state
                    x_time_next       = SPEED_X;                                // set x_time reg to start time
                    end
                else if(!btnL && btnR && (p_x_reg + PACMAN_SIZE + SPEED_X < MAX_X)) // if right button pressed and can move right
                    begin
                    motion_state_next = right;                                   // go to right state
                    x_time_next       = SPEED_X;                                // set x_time reg to start time
                    end
                else if(btnU && !btnD && (p_y_reg >= SPEED_Y))                   // if up button pressed and can move up                  
                    begin
                    motion_state_next = up;                                      // go to up state
                    y_time_next       = SPEED_Y;                                // set y_time reg to start time
                    end
                else if(!btnU && btnD && (p_y_reg + PACMAN_SIZE + SPEED_Y < MAX_Y)) // if down button pressed and can move down
                    begin
                    motion_state_next = down;                                    // go to down state
                    y_time_next       = SPEED_Y;                                // set y_time reg to start time
                    end
                end
               
            up:
                begin
                if(y_time_reg > 0)                                              // if y_time reg > 0,
                    y_time_next = y_time_reg - 1;                               // decrement
                   
                else if(y_time_reg == 0)                                        // if y_time reg = 0
                    begin 
                    if(p_y_reg >= SPEED_Y)                                      // is sprite can move up,
                        p_y_next = p_y_reg - SPEED_Y;                           // move up
                    
                    if(btnU)                                                    // if up button pressed
                        y_time_next = T_H - 1;                                   // set time reg to full time
                    else
                        motion_state_next = no_dir;                             // if no button pressed, return to no_dir state
                    end
                end
               
            down:
                begin
                if(y_time_reg > 0)                                              // if y_time reg > 0,
                    y_time_next = y_time_reg - 1;                               // decrement
                   
                else if(y_time_reg == 0)                                        // if y_time reg = 0
                    begin 
                    if(p_y_reg + PACMAN_SIZE + SPEED_Y < MAX_Y)                 // if sprite can move down,
                        p_y_next = p_y_reg + SPEED_Y;                           // move down
                    
                    if(btnD)                                                    // if down button pressed
                        y_time_next = T_H - 1;                                   // set time reg to full time
                    else
                        motion_state_next = no_dir;                             // if no button pressed, return to no_dir state
                    end
                end
               
            left:
                begin
                if(x_time_reg > 0)                                              // if x_time reg > 0,
                    x_time_next = x_time_reg - 1;                               // decrement
                   
                else if(x_time_reg == 0)                                        // if x_time reg = 0
                    begin 
                    if(p_x_reg >= SPEED_X)                                      // if sprite can move left,
                        p_x_next = p_x_reg - SPEED_X;                           // move left
                    
                    if(btnL)                                                    // if left button pressed
                        x_time_next = T_W - 1;                                   // set time reg to full time
                    else
                        motion_state_next = no_dir;                             // if no button pressed, return to no_dir state
                    end
                end
               
            right:
                begin
                if(x_time_reg > 0)                                              // if x_time reg > 0,
                    x_time_next = x_time_reg - 1;                               // decrement
                   
                else if(x_time_reg == 0)                                        // if x_time reg = 0
                    begin 
                    if(p_x_reg + PACMAN_SIZE + SPEED_X < MAX_X)                 // if sprite can move right,
                        p_x_next = p_x_reg + SPEED_X;                           // move right
                    
                    if(btnR)                                                    // if right button pressed
                        x_time_next = T_W - 1;                                   // set time reg to full time
                    else
                        motion_state_next = no_dir;                             // if no button pressed, return to no_dir state
                    end
                end
           
        endcase
        end
       
    /***********************************************************************************/
    /*                          Pacman display area logic                            */  
    /***********************************************************************************/
    // outputs for Pacman display area logic
    wire [11:0] sprite_color;

    // Pacman rom
    Pacman_rom pacman_rom_inst(.clk(clk),
                                .col(p_x_reg),
                                .row(p_y_reg), 
                                .color_data(sprite_color));
   
    // infer output logic for Pacman display area
    always @*
        begin
        // defaults
        rgb_out     = 12'b0;
        pacman_on   = 1'b0;
        
       
        // check if Pacman is within display area
        if ((x >= p_x_reg) && (x < p_x_reg + PACMAN_SIZE) &&
            (y >= p_y_reg) && (y < p_y_reg + PACMAN_SIZE))
            begin
            // Pacman is within display area
            pacman_on   = 1'b1;
            rgb_out = sprite_color;
            end
        end
   
    /***********************************************************************************/
    /*                          outputs to other circuits                             */  
    /***********************************************************************************/
    // outputs to other circuits
    assign p_x        = p_x_reg;
    assign p_y        = p_y_reg;
    assign direction = dir_reg;
   
    endmodule
