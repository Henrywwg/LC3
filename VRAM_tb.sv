//eh... good enough for now
module VRAM_tb();
    logic clk, rst_n;
    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;
    logic [18:0]VGA_ADDR;
    logic calculated_pixel;
    logic [15:0]iRAMoutput;

    //Instantiate DUT(s)
    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    VRAM iRAM(.clk(clk), .waddr({scanline_counter[8:0], dot_counter[9:0]}), .wdata(calculated_pixel), .raddr(VGA_ADDR), .data(iRAMoutput));

    initial begin
        clk = 0;
        rst_n = 0;
        calculated_pixel = 1'b1;
        VGA_ADDR = '0;

        repeat(2) @(negedge clk);
        rst_n = 1;

        repeat(2) @(negedge clk);
        
        repeat(307300) @(negedge clk);     //Write 1's over entirety of RAM


        repeat(300000) @(negedge clk) begin     //Make sure RAM is overwritten
            if (iRAMoutput != 16'hffbf)
                $display("Improperly written VRAM at %t\n should be & 16'hFFBF but is %h", $time, iRAMoutput);
            VGA_ADDR = VGA_ADDR + 1;
        end



        calculated_pixel = 1'b0;

        repeat(307300) @(negedge clk);     //Write 0's over entirety of RAM


        repeat(300000) @(negedge clk) begin     //Make sure RAM is overwritten again... not much more to test here
            if (iRAMoutput != 16'h0000)
                $display("Improperly written VRAM at %t\n should be & 16'h0000 but is %h", $time, iRAMoutput);
            VGA_ADDR = VGA_ADDR + 1;
        end
        

        $stop();
    end

    //Base system clock (10ns period)
    always
        #5 clk = ~clk;
endmodule