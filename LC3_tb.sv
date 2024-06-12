module LC3_tb();
    logic clk, rst_n;
    logic [15:0]cmd;


    //Instantiate DUT
    LC3 iDUT(.clk(clk), .rst_n(rst_n), .cmd(cmd), .ram_data(ram_data), .mem_data(mem_data), .mem_addr(mem_addr), .we(we), .mem_en(mem_en));


    //Instantiate placeholder RAM for testing
    RAM iRAM(.clk(clk), .we(we), .mem_en(mem_en), .addr(mem_addr), .rdata(mem_data), .data(ram_data));


    logic we, mem_en;
    logic [15:0]mem_addr, mem_data, ram_data;

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