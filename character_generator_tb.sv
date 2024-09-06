module character_generator_tb();
    logic clk, rst_n;

    


    //Instantiate DUT(s)
    DUT iDUT(.clk(clk), .rst_n(rst_n), OTHER HOOKUPS);

    initial begin
        clk = 0;
        rst_n = 0;
        //PUT OTHER SIGNALS TO INIT

        repeat(2) @(negedge clk);
        rst_n = 1;
        
        

        $stop();
    end

    //Base system clock (10ns period)
    always
        #5 clk = ~clk;
endmodule