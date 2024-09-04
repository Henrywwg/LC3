//Top module for instantiating components for the display
//Hopefully gives a hierarchical view of the project and helps show how it's laid out
module character_processor(
    input clk,
    input rst_n,
);

    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;
    logic [3:0]char;
    logic enable;
    logic calculated_pixel;
    logic [15:0]amber_pixel;

    logic [18:0]VGA_ADDR;

    //Counter to determine which value we read from the VRAM - changes only while display active
    always_ff @(posedge clk)
        if(!rst_n)
            VGA_ADDR <= '0;
        else if(VGA_ADDR == 19'd307199) //Max value of ram
            VGA_ADDR <= '0;
        else if(active)
            VGA_ADDR <= VGA_ADDR + 1;

    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    text_buffer iBuffer(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter), .char(char));

    character_generator iBuffer(.clk(clk), .rst_n(rst_n), .en(enable), .dot_count(dot_counter[2:0]), .scan_count(scanline_counter[3:0]), .char(char), .pixel(calculated_pixel));

    VRAM iRAM(.clk(clk), .raddr({scanline_counter[8:0], dot_counter[9:0]}), .wdata(calculated_pixel), .raddr(VGA_ADDR), .data(amber_pixel));

    VGA iVGA(.clk(clk), .rst_n(rst_n), .img_reg(amber_pixel), .red(TO PHYSICAL VGA), .blue(TO PHYSICAL VGA), .green(TO PHYSICAL VGA), .vsync(TO PHYSICAL VGA), .hsync(TO PHYSICAL VGA), .active(active));
endmodule