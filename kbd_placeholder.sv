module kbd_placeholder(
    input kbd_clk,
    input rst_n,
    input LD,
    input [8:0]data,
    output logic ps2_data
);

    logic [10:0] SHIFT_REG; //10 bits- load with 10 xxxx xxxx P
    

    always_ff @(posedge kbd_clk) begin
        if(!rst_n)
            {ps2_data, SHIFT_REG} <= '1;                        
        else if (LD)
            {ps2_data, SHIFT_REG} <= {1'b1, 1'b0, data};
        else
            {SHIFT_REG[10:1]} <= {SHIFT_REG[9:0], 1'b1};    //Shift left and shift 1s into right side
    end


    assign PS2_data = SHIFT_REG[10];




endmodule