//Status - tb passed
module text_buffer_tb();
    logic clk, rst_n;
    logic [3:0]new_char, char;
    logic [11:0]waddr;
    logic text_en;
    logic [9:0]dot_counter;
    logic [8:0]scanline_counter;

    //char is the only thing we monitor

    
    text_counters iCounter(.clk(clk), .rst_n(rst_n), .dot_counter(dot_counter), .scanline_counter(scanline_counter));

    //Instantiate DUT(s)
    text_buffer iBuffer(.clk(clk), .rst_n(rst_n), .new_char(new_char), .waddr(waddr), .we(text_en), .dot_counter(dot_counter), .scanline_counter(scanline_counter), .char(char));

    initial begin
        clk = 0;
        rst_n = 0;
        new_char = 4'b1010;
        waddr = 11'h0000;
        text_en = 1;
        
        repeat(2) @(negedge clk);
        rst_n = 1;

        repeat(2400) @(negedge clk) 
            waddr = waddr + 1;


        repeat(2400) @(negedge clk) begin
            if(char != 4'b1010) begin
                $display("Char not correct at %d", waddr);
                $stop();
            end
            waddr = waddr + 1;

        end

        
        $display("YAHOO! All tests passed!");
        
        $stop();
    end

    //Base system clock (10ns period)
    always
        #5 clk = ~clk;
endmodule