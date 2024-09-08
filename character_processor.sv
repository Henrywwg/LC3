//Top module for instantiating components for the display
//Hopefully gives a hierarchical view of the project and helps show how it's laid out
module character_processor(
    input clk,                  //System signal
    input rst_n,                //System signal

    input [3:0]new_char,        //Signal from CPU
    input [11:0]waddr,          //Signal from CPU
    input text_en,              //Signal from CPU

    output logic [3:0]RED_VGA,  //Signal to VGA
    output logic [3:0]GRE_VGA,  //  ^
    output logic [3:0]BLU_VGA,   //  |
    output logic vsync,         //  |  
    output logic hsync          //  |
);

    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;
    logic [3:0]char;
    logic enable;
    logic calculated_pixel;
    logic [7:0]amber_pixel;
    logic active;

    logic [18:0]VGA_ADDR;

    //Counter to determine which value we read from the VRAM - changes only while display active
    always_ff @(posedge clk)
        if(!rst_n)
            VGA_ADDR <= '0;
        else if(VGA_ADDR == 19'd307199) //Max value of ram
            VGA_ADDR <= '0;
        else if(active)
            VGA_ADDR <= VGA_ADDR + 1'b1;

    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    text_buffer iBuffer(.clk(clk), .rst_n(rst_n), .new_char(new_char), .waddr(waddr), .we(text_en), .dot_counter(dot_counter), .scanline_counter(scanline_counter), .char(char));

    character_generator iCharGen(.clk(clk), .rst_n(rst_n), .en(enable), .dot_count(dot_counter[2:0]), .scan_count(scanline_counter[3:0]), .character(char), .pixel(calculated_pixel));

    VRAM iRAM(.clk(clk), .waddr({scanline_counter[8:0], dot_counter[9:0]}), .wdata(calculated_pixel), .raddr(VGA_ADDR), .data(amber_pixel));

    VGA iVGA(.clk(clk), .rst_n(rst_n), .img_reg(amber_pixel), .red(RED_VGA), .blue(BLU_VGA), .green(GRE_VGA), .vsync(vsync), .hsync(hsync), .active(active));
endmodule