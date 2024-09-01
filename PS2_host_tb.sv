module PS2_host_tb();

    logic clk, rst_n;           //System   -> Host      stim
    logic ps2_clk, ps2_data;    //Keyboard -> Host      stim
    logic cmd_rdy, cmd, error;  //Host     -> System    monitor
    
    logic ps2_clk_enable, kbd_clk;
    logic [8:0]data;
    logic ld;             //used for sending PS2 commands

    //////////////////////////////
    //Instantiate DUT and hookup//
    //////////////////////////////
    PS2_host iDUT(.clk(clk), .rst_n(.rst_n), .ps2_clk(ps2_clk), .ps2_data(ps2_data), .cmd_rdy(cmd_rdy), .cmd(cmd), .error(error));

    kbd_placeholder iDUTsupport(.kbd_clk(kbd_clk), .rst_n(.rst_n), .LD(ld), .data(data), .ps2_data(ps2_data));

    assign ps2_data = ;

    initial begin
        //Init stims
        clk = 0;
        ps2_clk = 0;
        //ps2_data = 1;
        rst_n = 0;  //Reset
        ps2_clk_enable = 0;

        @(negedge clk);
        rst_n = 1;  //Deassert reset
        data = 9'h0AB;

        @(negedge clk);
        ld = 1;             //Load 010101011 into reg (should not error)

        //The testing begins
        //After reset host should be idling - waiting for input.

        //Enable kbd_clk which should then begin tx ps2 data
        ps2_clk_enable = 1;

        repeat(9) @(negedge kbd_clk);   //Wait until a few kbd clocks are over then disable clk and check
        ps2_clk_enable = 0;



        $stop();
    end

    //Clk stimulus
    always #5 clk = ~clk; 

    //kbd clock
    always #50 ps2_clk = ~ps2_clk; //Order of magnitude slower

    //kbd clock only on when the kbd is transmitting or receiving
    assign kbd_clk = ps2_clk_enable & ps2_clk;

endmodule