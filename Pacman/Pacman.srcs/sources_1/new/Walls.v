module Walls
(
    input wire clk,
    input wire video_on,
    input wire [9:0] x,y,               //location of VGA pixel
    output reg [11:0] rgb_out,          //output rgb data to VGA DAC
    output reg walls_on
);

    reg [4:0] row;
    reg [3:0] col;

    wire [11:0] walls_color_data;

    Walls_rom Walls_unit (.clk(clk), .row(row), .col(col), .color_data(walls_color_data));

    always @*
        begin 
                //default
                rgb_out = 12'b000000000000;
                walls_on = 0;
                row = 0;
                col = 0;
    
                if(video_on)
                    begin
    
                    //top wall
                    if (y >= 0 && y <= 15)
                        begin
                            row = y;
                            col = x;
                            if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                        end
                    
                    //bottom wall
                    if(y >= 464)
                        begin
                            row = y - 464;
                            col = x;
                            if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                        end
                    
                    //left wall
                    if(x >= 0 && x <= 15)
                        begin
                            row = y;
                            col = x;
                            if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                        end
                    
                    //right wall
                    if(x >= 624)
                        begin
                            row = y;
                            col = x - 624;
                            if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                        end    
                    
                    //Block A1
                    if(x >=192 && x <= 208 && y>=16 && y<=96)
                        begin
                            row = y;
                            col = x - 192;
                            if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                         end
                     
                     //Block A2
                     if(x >=448 && x <= 464 && y>=16 && y<=96)
                         begin
                             row = y;
                             col = x - 448;
                             if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                          end
    
                     //Block A3
                     if(x >=192 && x <= 208 && y>=384 && y<=464)
                         begin
                             row = y-384;
                             col = x - 192;
                             if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                          end     
    
                     //Block A4
                     if(x >=448 && x <= 464 && y>=384 && y<=464)
                         begin
                             row = y-384;
                             col = x - 448;
                             if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                          end          
                          
                        //Block B1
                        //B11
                        if(x>=48 && x <=64 && y>=80 && y<=176)
                            begin
                            row = y-80;
                            col = x-48;
                             if(walls_color_data != 12'b011011011110)
                                begin
                                    rgb_out = walls_color_data;
                                    walls_on = 1;
                                end
                            end
                       //B12
                       if(x>=48 && x <= 144 && y>=80 && y<=96)
                            begin 
                            row = y-80;
                            col = x-48;
                             if(walls_color_data != 12'b011011011110)
                               begin
                                   rgb_out = walls_color_data;
                                   walls_on = 1;
                               end
                           end
                           
                        //Block B2
                        //B21
                        if(x>=496 && x<=576 && y>=80 && y<=96)
                                begin
                                row = y-80;
                                col = x-496;
                                 if(walls_color_data != 12'b011011011110)
                                  begin
                                      rgb_out = walls_color_data;
                                      walls_on = 1;
                                  end
                              end      
                       
                        //B22
                           if(x>=576 && x<=592 && y>=80 && y<=176)
                                   begin
                                   row = y-80;
                                   col = x-576;
                                   if(walls_color_data != 12'b011011011110)
                                        begin
                                            rgb_out = walls_color_data;
                                            walls_on = 1;
                                        end
                                   end    
                                
                         //Block B3
                         //B31
                         if(x>=48 && x<=64 && y>=304 && y<=384)
                            begin
                            row = y-304;
                            col = x-48;
                            if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                            end      
                         
                         //B32
                         if(x>=48 && x<=144 && y>=384 && y <= 400)   
                            begin 
                            row = y-384;
                            col = x-48;
                            if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                            end
                            
                            
                         //Block B4
                         //B41
                         if(x>=496 && x<=592 && y>=384 && y<=400)
                            begin
                            row = y-384;
                            col = x-496;
                            if(walls_color_data != 12'b011011011110)
                                 begin
                                     rgb_out = walls_color_data;
                                     walls_on = 1;
                                 end
                            end       
                        
                        //B42
                        if(x>=576 && x<=592 && y>=304 && y<=384)
                            begin 
                            row = y-304;
                            col = x-576;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end    
                            
                            
                        //Block C1
                        if(x>=256 && x<=400 && y>=48 && y<= 64)
                            begin
                            row = y-64;
                            col = x-256;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end  
                            
                        //Block C2
                        if(x>=256 && x<=400 && y>=416 && y<=432)
                            begin 
                            row = y-416;
                            col = x-256;  
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end        
                            
                        //Block D1
                        if(x>=128 && x<= 240 && y>=160 & y<=176)
                            begin
                            row = y-160;
                            col = x-128;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end 
                            
                        //Block D2
                        if(x>=384 && x<=496 && y>=160 && y<=176)
                            begin
                            row = y-160;
                            col = x-384;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end 
                            
                            
                        //Block D3
                        if(x>=128 && x<= 240 && y>=288 && y<=304)
                            begin
                            row = y-288;
                            col = x-128;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end 
                            
                            
                        //Block D4
                        if(x>=384 && x<=496 && y>=288 && y<=304)
                            begin
                            row = y-288;
                            col = x-384;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end    
                            
                        //Block E
                        if(x>=256 && x<=368 && y>=192 && y<=272)
                            begin
                            row = y-192;
                            col = x-256;
                            if(walls_color_data != 12'b011011011110)
                             begin
                                 rgb_out = walls_color_data;
                                 walls_on = 1;
                             end
                            end 
                                                                                                                                                    
                 end
        end
endmodule