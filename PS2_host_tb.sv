module PS2_host_tb();

    logic clk, rst_n;           //System   -> Host      stim
    logic ps2_clk, ps2_data;    //Keyboard -> Host      stim
    logic cmd_rdy, error;       //Host     -> System    monitor
    logic [8:0]cmd;             //Host     -> System    monitor
    
    logic ps2_clk_enable, kbd_clk;
    logic [8:0]data;
    logic ld;             //used for sending PS2 commands

    //////////////////////////////
    //Instantiate DUT and hookup//
    //////////////////////////////
    PS2_host iDUT(.clk(clk), .rst_n(rst_n), .ps2_clk(ps2_clk), .ps2_data(ps2_data), .cmd_rdy(cmd_rdy), .cmd(cmd), .error(error));

    kbd_placeholder iDUTsupport(.kbd_clk(ps2_clk), .rst_n(rst_n), .LD(ld), .data(data), .ps2_data(ps2_data), .sending(ps2_clk_enable), .clk(clk));

    assign kbd_clk = ps2_clk;
    initial begin
        //Init stims
        clk = 0;
        //ps2_data = 1;
        rst_n = 0;  //Reset
        ps2_clk_enable = 0;

        @(negedge clk);
        rst_n = 1;  //Deassert reset
        data = 9'h0A8;

        repeat(2) @(negedge clk);
        ld = 1;             //Load 010101011 into reg (should not error)
        //The testing begins
        //After reset host should be idling - waiting for input.

        //Enable kbd_clk which should then begin tx ps2 data

        //TEST 1
        repeat(2) @(negedge clk);
        ld = 0;

        repeat(2) @(negedge clk);
        ps2_clk_enable = 1;

        repeat(12) @(negedge kbd_clk);   //Wait until a few kbd clocks are over then disable clk and check
        ps2_clk_enable = 0;

        repeat(80) @(negedge clk);


        //TEST 2
        data = 9'h0A9;

        repeat(2) @(negedge clk);
        ld = 1;             //Load 010101011 into reg (should not error)
        //The testing begins
        //After reset host should be idling - waiting for input.
        
        repeat(20) @(negedge clk);
        //Enable kbd_clk which should then begin tx ps2 data
        ps2_clk_enable = 1;
        ld = 0;

        repeat(12) @(negedge kbd_clk);   //Wait until a few kbd clocks are over then disable clk and check
        ps2_clk_enable = 0;

        repeat(20) @(negedge clk);

        $stop();
    end

    //Clk stimulus
    always #5 clk = ~clk; 

endmodule