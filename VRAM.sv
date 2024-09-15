//Dual ported ram that take in a dot matrix and outputs RGB of #FFBF00 (amber)
//In the topology, this exists directly before the VGA unit
// and after the character_generator 
//ie. bits written from the generator to the VRAM then are displayed from the VRAM to the display
module VRAM(
    input clk,
    input [9:0]dot_counter,  
    input [9:0]scanline_counter,
    input [1:0]wdata,                        //from text_buffer
    input [19:0]raddr,                  //independent counter
    output logic data   //just binary output - amber or not
);

logic [1:0]ram[0:479999];           //woof thats big

    logic [19:0]calculated_pixel_pos_in_linear_VRAM;
    logic [19:0]shifted_scan_count;
    logic [19:0]vert_calc;
    logic [31:0]blink_cntr;
    logic [1:0]data_intermediate;

    always_ff @(posedge clk)
        blink_cntr <= blink_cntr + 1'b1;



    //waddr[19:14] + <<

    //make a lookup table so no mult.
    always_comb 
        case(scanline_counter[3:0])
            4'h0: vert_calc = '0;
            4'h1: vert_calc = 20'd800;
            4'h2: vert_calc = 20'd1600;
            4'h3: vert_calc = 20'd2400;
            4'h4: vert_calc = 20'd3200;
            4'h5: vert_calc = 20'd4000;
            4'h6: vert_calc = 20'd4800;
            4'h7: vert_calc = 20'd5600;
            4'h8: vert_calc = 20'd6400;
            4'h9: vert_calc = 20'd7200;
            4'ha: vert_calc = 20'd8000;
            4'hb: vert_calc = 20'd8800;
            4'hc: vert_calc = 20'd9600;
            4'hd: vert_calc = 20'd10400;
            4'he: vert_calc = 20'd11200;
            default: vert_calc = 20'd12000;
        endcase

    assign calculated_pixel_pos_in_linear_VRAM = scanline_counter[9:4] * 20'd12000 + vert_calc + dot_counter[9:0];

    always_ff @(posedge clk) begin 
        ram[calculated_pixel_pos_in_linear_VRAM] <= wdata; //becuase constantly writing only increases 
        data_intermediate <= ram[raddr];  //always output raddr data -- this is data needed for constantly updating screen
    end

    assign data = (!(data_intermediate[1] & blink_cntr[26])) & data_intermediate[0];
endmodule