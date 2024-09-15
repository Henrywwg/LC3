///////////////////////
//  Text buffer
///////////////////////
//  Dual ported RAM for
//  read/write data for which
//  character is stored in 
//  a particular cell

module text_buffer(
    input clk,
    input rst_n,
    input [3:0]new_char,
    input [12:0]waddr,  //[12:7][6:0]
    input we,
    input [9:0]dot_counter, //9:3           x       hor 800         11 0001 1  111
    input [9:0]scanline_counter,//9:4       y       ver 600         10 0101    0111
    output logic [3:0]char           //Char for generator
);
    logic [3:0]char_intermediate;
    logic [12:0]current_char;
    logic [18:0]char_counter;
    assign current_char = {scanline_counter[9:4], dot_counter[9:3]};    //For better utilization sequential access though it shouldn't really matter - its not a cache

    // 1110 0111 0011 000 == 3699

    logic [3:0]text_buffer[0:4836]; //3800 chars can fit on 800*600 (100*38)

    always_ff @(posedge clk) begin
        if(we)
            text_buffer[waddr] <= new_char;                //when enabled write new char to waddr location of buffer
        
        //Always output char
        char_intermediate <= text_buffer[current_char];
   end

   assign char =  current_char == waddr ? {2'b0, 1'b1, char_intermediate[0]} : {3'b0, char_intermediate[0]};

endmodule