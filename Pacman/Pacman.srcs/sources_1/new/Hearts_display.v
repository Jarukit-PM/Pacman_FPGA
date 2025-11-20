module  Hearts_display
(
    input wire clk,
    input wire [9:0] x,y,               //location of VGA pixel
    input wire [1:0] num_hearts,       //number of hearts to display (get from game state machine) (0-3)
    output wire [11:0] color_data,      //color of VGA pixel
    output reg hearts_on              //signal to turn on hearts
);


//row and col reg to keep track of current pixel in heart rom
reg [4:0] row;
reg [3:0] col;

//heart rom 
Hearts_rom Hearts_rom_unit (.clk(clk), .row(row), .col(col), .color_data(color_data));

//heart control
always @*
    begin
        //default 
        row = 0;
        col = 0;
        hearts_on = 0;

        //if 1 heart(left)
        if(x >= 240 && x < 256 && y >= 16 && y < 32)
            begin
                col = x-240;
                if(num_hearts > 0)                              //if  num_hearts > 0 (1,2,3) left heart is on
                    row = y - 16;                               //set full heart
                    
                else                                            //else (0) left heart is off
                    row = y;                                    //set empty heart
                hearts_on = 1;
            end


        //if 2 hearts(center)
        if(x >= 256 && x < 272 && y>= 16 && y < 32)
            begin
                col = x-256;
                if(num_hearts > 1)                              //if  num_hearts > 1 (2,3) center heart is on
                    row = y - 16;                               //set full heart
                    
                else                                            //else (0,1) center heart is off
                    row = y;                                    //set empty heart
                hearts_on = 1;
            end

        //if 3 hearts(right)
        if(x >= 272 && x < 288 && y >= 16 && y<32)
            begin
                col = x-272;
                if(num_hearts > 2)                              //if  num_hearts > 2 (3) right heart is on
                    row = y - 16;                               //set full heart
                    
                else                                            //else (0,1,2) right heart is off
                    row = y;                                    //set empty heart
                hearts_on = 1;
            end

    end
endmodule