module kbd_placeholder(
    input clk,
    output logic kbd_clk,
    input rst_n,
    input LD,
    input [8:0]data,
    input sending,
    output logic ps2_data
);

    logic [9:0] SHIFT_REG; //10 bits- load with 10 xxxx xxxx P
    logic ps2_clk = 0;  //sloppy
    

    always_ff @(posedge ps2_clk) begin
        if(!rst_n)
            {SHIFT_REG} <= '1;                        
        else if (LD)
            {SHIFT_REG} <= {1'b0, data};
        else
            {SHIFT_REG[9:0]} <= {SHIFT_REG[8:0], 1'b1};    //Shift left and shift 1s into right side
    end


    //assign ps2_data = SHIFT_REG[9] | ~sending;

    always_ff @(posedge ps2_clk)
        ps2_data <= SHIFT_REG[9] | ~sending;

        //kbd clock
    always #50 ps2_clk = ~ps2_clk; //local kbdclk

    //kbd clock only on when the kbd is transmitting or receiving
    assign kbd_clk = (sending & ps2_clk) | ~sending;


endmodule