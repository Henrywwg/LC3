module text_counters(
    input clk,
    input rst_n,
    input active,
    output logic [9:0]dot_counter,
    output logic [9:0]scanline_counter
);

    logic end_of_line;
    logic end_of_screen;


    //Dot counter - counts x positions to determine which pixel we are writing now
    always_ff @(posedge clk) begin
        if(!rst_n)
            dot_counter <= '0;
        else if(end_of_line)
            dot_counter <= '0;
        else if(active)                 //these actives should be replaced with built in front and back porch - this is lazy
            dot_counter <= dot_counter + 1'b1;
    end

    //Scan counter counts y lines to also help determine which pixel we're on
    always_ff @(posedge clk) begin
        if(!rst_n)
            scanline_counter <= '0;
        else if(end_of_screen)
            scanline_counter <= '0;
        else if(end_of_line & active)
            scanline_counter <= scanline_counter + 1'b1;
    end

    //Simple assign to know when to reset counters and to control matrix traversal
    assign end_of_line = dot_counter == 10'd799;
    assign end_of_screen = scanline_counter == 10'd599;


    //11 0001 1111 = 799
    //10 0101 0111 = 599

endmodule