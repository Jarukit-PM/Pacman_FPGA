module Game_state_machine
(
    input wire clk,rst,
    input wire start_btn,                               //start button
    input wire collision,
    output wire [1:0] num_hearts,
    output wire [1:0] game_state,                       //(start,playing,hit,gameover)
    output wire game_en,
    output reg game_reset                               //reset game use with reset button
);
//positive edge detection for start button
reg start_btn_reg;
wire start_btn_posedge;

//infer positive edge detection for start button
always @(posedge clk, posedge rst)
    if(rst)
        start_btn_reg <= 0;
    else
        start_btn_reg <= start_btn;

assign start_btn_posedge = start_btn_reg & ~start_btn;




localparam [1:0] start = 2'b00,
                    playing = 2'b01,
                    hit = 2'b10,
                    gameover = 2'b11;

reg [1:0] game_state_reg, game_state_next;              //FSM state register
reg [27:0] timer_reg, timer_next;                         //timer register to time of pacman invincibility after hit
reg [1:0] hearts_reg, hearts_next;                      //store number of hearts to display
reg game_en_reg, game_en_next;                          //game enable register

//infer game state machine, use timer to time invincibility after hit ,game enable 
always @(posedge clk, posedge rst)
    if(rst)
        begin
            game_state_reg <= start;
            timer_reg <= 0;
            hearts_reg <= 3;
            game_en_reg <= 0;
        end
    else
        begin
            game_state_reg <= game_state_next;
            timer_reg <= timer_next;
            hearts_reg <= hearts_next;
            game_en_reg <= game_en_next;
        end

always @*
    begin
        //default
        game_state_next = game_state_reg;
        timer_next = timer_reg;
        hearts_next = hearts_reg;
        game_en_next = game_en_reg;
        game_reset = 0;

        case(game_state_reg)
            start:
                begin
                    if(start_btn_posedge)
                        begin
                            game_state_next = playing;
                            game_reset = 1;
                            game_en_next = 1;
                        end
                end
            playing:
                begin
                    if(collision)
                        begin
                            if(hearts_reg == 1)     //if has 1 heart left
                                begin
                                    hearts_next = hearts_reg - 1;     //decrement heart 
                                    game_state_next = gameover;
                                    game_en_next = 0;
                                end
                            else
                                begin
                                    game_state_next = hit;
                                    if (timer_reg == 0)  // Only set the timer if it's not already set
                                        timer_next = 200000000;
                                    hearts_next = hearts_reg - 1;
                                end
                        end
                end
            hit:
                begin
                    if(timer_reg > 0)//pacman can not hit again until timer is 0 (wait 2 seconds)
                        begin
                            timer_next = timer_reg - 1;
                        end
                    else
                        begin
                            game_state_next = playing;
                            timer_next = 0;
                        end
                end
            gameover:
                begin
                    if(start_btn_posedge)                               //wait for start button to be pressed to restart game
                        begin
                            game_state_next = start;
                            game_reset = 1;
                            hearts_next = 3;
                        end
                end
            
        endcase
    end

assign num_hearts = hearts_reg;
assign game_state = game_state_reg;
assign game_en = game_en_reg;

endmodule

