///////////////////////
//  ROM text generator
///////////////////////
//  uses a lookup table to determine dot map for writing characters
//
//

module character_generator #(
    parameter DEPTH = 160
)
(
    input clk,
    input rst_n,
    input en,
    input [3:0]character,   //16 characters
    input [2:0]dot_count,
    input [3:0]scan_count,
    output pixel
);

//logic char_data[0:7][0:DEPTH-1];     //8*DEPTH array of single bits
logic char_data;
// logic [7:0]calculated_scan_count;
// // // // // // // // //
// BEGIN
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
// ...
// ...
// ...
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
//  x  x  x  x  x  x  x  x
// END

assign calculated_scan_count = {character[3:0], scan_count[3:0]};


assign pixel = character[0];    //I'm lazy but this should work for testing


// always_ff @(posedge clk)
//     if(rst_n)

//     else if(en)
//         pixel <= char_data[dot_count][calculated_scan_count];

endmodule