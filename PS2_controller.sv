module PS2_host(
    input clk,
    input rst_n,
    input ps2_data,
    input ps2_clk,
    output logic cmd_rdy,
    output logic [8:0]cmd,
    output error
);

    typedef enum logic [1:0]{IDLE, COLLECT, CMD_RECEIVED} state_t;

    state_t state, nxt_state;

    logic [3:0]cntr;
    logic PS2_clk_MS[0:2];
    logic PS2_data_MS[0:1];
    logic neg_edge_detect;

    logic inc, clr_cntr, done, enable_in;

    //Metastability for PS2 data
    always_ff @(posedge clk) begin
        PS2_data_MS[0] <= ps2_data;
        PS2_data_MS[1] <= PS2_data_MS[0];    //Stabilized data bit from the devce
    end

    //Metastability for PS2_clk
    always_ff @(posedge clk) begin
        PS2_clk_MS[0] <= ps2_clk;
        PS2_clk_MS[1] <= PS2_clk_MS[0];
        PS2_clk_MS[2] <= PS2_clk_MS[1];  //Third ff for edge detection
    end

    /////////////////////////////////////////
    // Edge detection                      //               
    // Goes high for one system clock when // 
    // the PS2 clock has a negative edge   //
    /////////////////////////////////////////
    assign neg_edge_detect = PS2_clk_MS[2] & ~PS2_clk_MS[1];

    //Shift register (as cmd)
    always_ff @(posedge clk) begin
        if(neg_edge_detect & enable_in) 
            cmd <= {cmd[7:0], PS2_data_MS[1]};
        else
        cmd <= cmd; //Redundant, but shows what's happening... cope
    end

    //4 Bit counter to keep track of how many bits read into shift reg
    always_ff @(posedge clk)
        if(clr_cntr)
            cntr <= '0; //Clear counter
        else if(neg_edge_detect & inc)
            cntr <= cntr + 1;

    //SM logic
    always_ff @(posedge clk)
        if(!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;
    
    always_comb begin
        //Define default next state
        nxt_state = state;
        //Default outputs
        clr_cntr = 0;
        inc = 0; 
        enable_in = 0;
        done = 0;

        case(state)
            IDLE: begin
                if(~PS2_data_MS[1] & neg_edge_detect) begin
                    nxt_state = COLLECT;
                    clr_cntr = 1;
                end
            end

            COLLECT: begin
                if(cntr == 4'b1000) //cnt to 10 clks
                    nxt_state = CMD_RECEIVED;
                inc = 1;
                enable_in = 1;
            end

            CMD_RECEIVED: begin
                if(cntr == 4'b1001) begin //count off one more clock then switch to IDLE
                    done = 1;
                    clr_cntr = 1;
                    nxt_state = IDLE;
                end
                else
                    inc = 1;
                    enable_in = 1;
            end

            default: nxt_state = IDLE;  //Recover back to IDLE

        endcase

    end

    //Output behaviour for done
    always_ff @(posedge clk)
            cmd_rdy <= done;    //keep cmd_rdy high for one clk

    assign error = ~^cmd;

endmodule