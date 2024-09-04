module text_counters(
    input clk,
    input rst_n,
    output logic [9:0]dot_counter,
    output logic [8:0]scanline_counter
);

    //For ease of use later in the program... not even sure I actually used them...
    assign y_dot = scanline_counter[3:0];   //Lower 4 bits - 16 dots
    assign x_dot = dot_counter[2:0];        //Lower 3 bits - 8 dots giving 8*16 pixels per char

    assign x_char = dot_counter[9:4];       //Upper 5 bits - 32 chars
    assign y_char = scanline_counter[8:3];   //Upper

    logic end_of_line;
    logic end_of_screen;


    //Dot counter - counts x positions to determine which pixel we are writing now
    always_ff @(posedge clk) begin
        if(!rst_n)
            dot_counter <= '0;
        else if(end_of_line)
            dot_counter <= '0;
        else
            dot_counter <= dot_counter + 1'b1;
    end

    //Scan counter counts y lines to also help determine which pixel we're on
    always_ff @(posedge clk) begin
        if(!rst_n)
            scanline_counter <= '0;
        else if(end_of_screen)
            scanline_counter <= '0;
        else if(end_of_line)
            scanline_counter <= scanline_counter + 1'b1;
    end

    //Simple assign to know when to reset counters and to control matrix traversal
    assign end_of_line = dot_counter == 10'd639;
    assign end_of_screen = scanline_counter == 9'd479;




endmodule