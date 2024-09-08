//Dual ported ram that take in a dot matrix and outputs RGB of #FFBF00 (amber)
//In the topology, this exists directly before the VGA unit
// and after the character_generator 
//ie. bits written from the generator to the VRAM then are displayed from the VRAM to the display
module VRAM(
    input clk,
    input [18:0]waddr,  //19 whole bits... woof
    input wdata,
    input [18:0]raddr,
    output logic [7:0]data //12 bits for RGB value
);

logic ram[0:307199];           //woof thats big

    always_ff @(posedge clk) begin
        ram[waddr] <= wdata; //becuase constantly writing only increases 
        data <= {8{ram[raddr]}} & 8'hFC;  //always output raddr data -- this is data needed for constantly updating screen
                                        // amber color code FFBF00 - omit blue data since it is fixed 0
    end
endmodule