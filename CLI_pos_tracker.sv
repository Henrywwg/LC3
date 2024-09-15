module CLI_pos_tracker(
    input rst_n,
    input clk,
    input inc_ptr,
    input [6:0]cpu_x,
    input [5:0]cpu_y,
    input select_output,        //0 is user controlled incrementation, 1 is processor addressing

    output logic [6:0]x_pos,
    output logic [5:0]y_pos
);

    logic [6:0]user_x;
    logic [5:0]user_y;

    assign x_pos = select_output ? cpu_x[6:0] : user_x[6:0];
    assign y_pos = select_output ? cpu_y[5:0] : user_y[5:0];

    always_ff @(posedge clk)
        if(!rst_n)
            user_x <= '0;
        else if (inc_ptr & (user_x == 99))
            user_x <= '0;
        else if (inc_ptr)
            user_x <= user_x + 1'b1;

    always_ff @(posedge clk)
        if(!rst_n)
            user_y <= '0;
        else if (user_y == 37)
            user_y <= '0;
        else if (inc_ptr & (x_pos == 99))
            user_y <= user_y + 1'b1;


endmodule