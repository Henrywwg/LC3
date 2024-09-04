///////////////////////
//  ROM text generator
///////////////////////
//  uses a lookup table to determine dot map for writing characters
//
//

module text_buffer(
    input clk,
    input rst_n,
    input [9:0]dot_counter, //9:3
    input [8:0]scanline_counter//8:4
    output [3:0]char           //Char for generator
);

    logic current_char;

    assign current_char = {scanline_counter[8:4], dot_counter[9:3]};    //For better utilization sequential access though it shouldn't really matter - its not a cache

    logic [8:0]text_buffer[0:2399]; //2400 chars can fit on 640*480

    always_ff @(posedge clk)
        if(!rst_n)
            text_buffer[2:0][0:2399] <= '{default:3'b000};  //fill all cells to 0
        
    assign char = text_buffer[3:0][current_char];   //Put data 
endmodule