module VRAM_tb();
    logic clk, rst_n;
    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;
    logic [18:0]VGA_ADDR;
    logic calculated_pixel;
    logic iRAMoutput;

    //Instantiate DUT(s)
    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    VRAM iRAM(.clk(clk), .waddr({scanline_counter[8:0], dot_counter[9:0]}), .wdata(calculated_pixel), .raddr(VGA_ADDR), .data(amber_pixel));

    initial begin
        clk = 0;
        rst_n = 0;
        calculated_pixel = 1'b0;
        VGA_ADDR = '0;

        repeat(2) @(negedge clk);
        rst_n = 1;

        repeat(2) @(negedge clk);
        
        repeat(307300) @(negedge clk) begin
            VGA_ADDR += 1;

        end


        repeat(300000) @(negedge clk) begin


        end
        

        $stop();
    end

    //Base system clock (10ns period)
    always
        #5 clk = ~clk;
endmodule