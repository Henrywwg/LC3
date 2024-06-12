module LC3_tb();
    logic clk, rst_n;
    logic [15:0]cmd;

    //RAM hookups
    logic we, mem_en;
    logic [15:0]mem_addr, mem_data, ram_data;


    //Instantiate DUT
    LC3 iDUT(.clk(clk), .rst_n(rst_n), .ram_data(ram_data), .mem_data(mem_data), .mem_addr(mem_addr), .we(we), .mem_en(mem_en));

    //Instantiate placeholder RAM for testing
    RAM iRAM(.clk(clk), .we(we), .mem_en(mem_en), .addr(mem_addr), .rdata(mem_data), .data(ram_data));

    initial begin
        $readmemh("testprog.txt",iRAM.mem);

        clk = 0;
        rst_n = 0;
        repeat(4) @(negedge clk);
        rst_n = 1;
        @(negedge clk);
        repeat (50) @(posedge clk);
        $stop();
    end

    always
        #5 clk = ~clk;
endmodule