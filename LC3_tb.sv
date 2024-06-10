module LC3_tb();
    logic clk, rst_n;
    logic [15:0]cmd;

    LC3 iDUT(.clk(clk), .rst_n(rst_n), .cmd(cmd));


    initial begin
        clk = 0;
        rst_n = 0;
        cmd = 16'b1001000010111111; // R0 <- NOT R2
        repeat(4) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        //BEGIN THE TESTING
        $stop();
    end

    always
        #5 clk = ~clk;
endmodule