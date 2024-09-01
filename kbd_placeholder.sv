module kbd_placeholder(
    input kbd_clk,
    input rst_n,
    input LD,
    input [8:0]data,
    output ps2_data
);
    

    always_ff @(posedge kbd_clk) begin
        if(rst_n)
            {ps2_data, SHIFT_REG} <= '1;                        
        else if (LD)
            {ps2_data, SHIFT_REG} <= {1'b1, data};
        else
            {ps2_data, SHIFT_REG} <= {SHIFT_REG[8:1], 1'b1};    //Shift left and shift 1s into right side
    end




endmodule