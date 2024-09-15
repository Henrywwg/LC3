//Top module for instantiating components for the display
//Hopefully gives a hierarchical view of the project and helps show how it's laid out
module character_processor(
    input clk,                  //System signal
    input rst_n,                //System signal

    input [3:0]new_char,        //Signal from CPU
    //input [11:0]waddr,          //Signal from CPU
    input text_en,              //Signal from CPU
    input btn_pressed,

    output logic [3:0]RED_VGA,  //Signal to VGA
    output logic [3:0]GRE_VGA,  //  ^
    output logic [3:0]BLU_VGA,   // |
    output logic vsync,         //  |  
    output logic hsync          //  |
);

    logic [9:0]dot_counter;
    logic [9:0]scanline_counter;
    logic [3:0]char;
    logic enable;
    logic [1:0]calculated_pixel;
    logic amber_pixel;
    logic active;
    logic [12:0]waddr;

    logic [19:0]VGA_ADDR;

    //Counter to determine which value we read from the VRAM - changes only while display active
    always_ff @(posedge clk)
        if(!rst_n)
            VGA_ADDR <= '0;
        else if((VGA_ADDR == 20'd479999) & active) //Max value of ram
            VGA_ADDR <= '0;
        else if(active)
            VGA_ADDR <= VGA_ADDR + 1'b1;

    CLI_pos_tracker iPTR(.clk(clk), .rst_n(rst_n), .inc_ptr(btn_pressed), .cpu_x(), .cpu_y(), .select_output(1'b0), .x_pos(waddr[6:0]), .y_pos(waddr[12:7]));

    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter), .active(active));

    text_buffer iBuffer(.clk(clk), .rst_n(rst_n), .new_char(new_char), .waddr(waddr), .we(text_en), .dot_counter(dot_counter), .scanline_counter(scanline_counter), .char(char));

    character_generator iCharGen(.clk(clk), .rst_n(rst_n), .en(enable), .dot_count(dot_counter[2:0]), .scan_count(scanline_counter[3:0]), .character(char), .pixel(calculated_pixel));

    VRAM iRAM(.clk(clk), .scanline_counter(scanline_counter[9:0]), .dot_counter(dot_counter[9:0]), .wdata(calculated_pixel), .raddr(VGA_ADDR), .data(amber_pixel));

    VGA iVGA(.clk(clk), .rst_n(rst_n), .img_reg(amber_pixel), .red(RED_VGA), .blue(BLU_VGA), .green(GRE_VGA), .VGA_VS(vsync), .VGA_HS(hsync), .active(active));
endmodule