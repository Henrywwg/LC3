module text_counters_tb();
    logic clk, rst_n;
    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;

    //Instantiate DUT(s)
    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    initial begin
        clk = 0;
        rst_n = 0;

        repeat(2) @(negedge clk);
        rst_n = 1;

        repeat(638) @(negedge clk);
        if(scanline_counter != 0)
            $display("scanline_counter is %d but should be 0", scanline_counter);
        if(dot_counter != 638)
            $display("dot_counter is %d but should be 638", dot_counter);
        
        if((scanline_counter != 0) | (dot_counter != 638))
            $stop();

        @(negedge clk);
        if(scanline_counter != 0)
            $display("scanline_counter is %d but should be 0", scanline_counter);
        if(dot_counter != 639)
            $display("dot_counter is %d but should be 639", dot_counter);
        
        if((scanline_counter != 0) | (dot_counter != 639))
            $stop();

        @(negedge clk);
        if(scanline_counter != 1)
            $display("scanline_counter is %d but should be 1", scanline_counter);
        if(dot_counter != 0)
            $display("dot_counter is %d but should be 0", dot_counter);
        if((scanline_counter != 1) | (dot_counter != 0))
            $stop();
        
        $display("YAHOO! All tests passed!");
        $stop();
    end

    //Base system clock (10ns period)
    always
        #5 clk = ~clk;
endmodule