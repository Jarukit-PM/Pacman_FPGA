module Check_collision
(
    input wire [1:0] direction,                           //current direction of pacman
    input wire [9:0] pacman_x, pacman_y,            //pacman's current location within display area
    input wire [9:0] blue_x, blue_y,                //Ghost's blue current location within display area
    input wire [9:0] red_x, red_y,                  //Ghost's red current location within display area
    output wire collision                          //collision signal
);

localparam [1:0] LEFT = 2'b00,
                 RIGHT = 2'b01,
                  UP = 2'b10,
                   DOWN = 2'b11;
                   
reg collided; //collision signal
always @*
    begin
        collided = 0;

        //check if pacman and ghost are within each other's display area 
        //if direction of pacman is left
        if(direction == LEFT)
            begin
                //if pacman and blue ghost are within each other's display area
                if(pacman_x - 13 <= blue_x && pacman_x >= blue_x - 13 && pacman_y - 13 <= blue_y && pacman_y >= blue_y - 13)
                    collided = 1;

                //if pacman and red ghost are within each other's display area
                if(pacman_x - 13 <= red_x && pacman_x >= red_x - 13 && pacman_y - 13 <= red_y && pacman_y >= red_y - 13)
                    collided = 1;
            end
        
        //if direction of pacman is right
        else if(direction == RIGHT)
            begin
                //if pacman and blue ghost are within each other's display area
                if(pacman_x + 13 >= blue_x && pacman_x <= blue_x + 13 && pacman_y - 13 <= blue_y && pacman_y >= blue_y - 13) 
                    collided = 1;

                //if pacman and red ghost are within each other's display area
                if(pacman_x + 13 >= red_x && pacman_x <= red_x + 13 && pacman_y - 13 <= red_y && pacman_y >= red_y - 13)
                    collided = 1;
            end
        
        //if direction of pacman is up
        else if(direction == UP)
            begin
                //if pacman and blue ghost are within each other's display area
                if(pacman_x - 13 <= blue_x && pacman_x >= blue_x - 13 && pacman_y - 13 <= blue_y && pacman_y >= blue_y - 13)
                    collided = 1;

                //if pacman and red ghost are within each other's display area
                if(pacman_x - 13 <= red_x && pacman_x >= red_x - 13 && pacman_y - 13 <= red_y && pacman_y >= red_y - 13)
                    collided = 1;
            end
        
        //if direction of pacman is down
        else if(direction == DOWN)
            begin
                //if pacman and blue ghost are within each other's display area
                if(pacman_x - 13 <= blue_x && pacman_x >= blue_x - 13 && pacman_y + 13 >= blue_y && pacman_y <= blue_y + 13)
                    collided = 1;

                //if pacman and red ghost are within each other's display area
                if(pacman_x - 13 <= red_x && pacman_x >= red_x - 13 && pacman_y + 13 >= red_y && pacman_y <= red_y + 13)
                    collided = 1;
            end

    end

assign collision = collided;

endmodule