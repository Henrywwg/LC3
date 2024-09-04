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
    input [11:0]waddr,
    input we,
    input [9:0]dot_counter, //9:3
    input [8:0]scanline_counter,//8:4
    output [3:0]char           //Char for generator
);

    logic current_char;

    assign current_char = {scanline_counter[8:4], dot_counter[9:3]};    //For better utilization sequential access though it shouldn't really matter - its not a cache

    logic [8:0]text_buffer[0:2399]; //2400 chars can fit on 640*480 (80*30)

    //buffer logic
    //
    // Always update char 
    // write new char to memory only when needed by
    always_ff @(posedge clk) begin
        if(!rst_n)
            text_buffer[3:0][0:2399] <= '{default:4'b0000};     //fill all cells to 0
        else if(we)
            text_buffer[3:0][waddr] <= new_char;                //when enabled write new char to waddr location of buffer
        
        //Always output char
        char <= text_buffer[3:0][current_char];
   end

endmodule