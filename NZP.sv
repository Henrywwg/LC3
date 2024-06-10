module NZP(
    input clk,
    input rst_n,
    input [15:0]BUS,
    input NZP_en,
    output logic [2:0]NZP_val
);

    logic [2:0]NZP_comb;

    //Sequential logic to store NZP value
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            NZP_val <= '0;
        else if(NZP_en)
            NZP_val <= NZP_comb;


    //Combination logic to compute NZP value
    assign NZP_comb = ~|BUS ?  3'b010 : //Reduction or 
                    (BUS[15] ? 3'b100 : //Check MSB
                               3'b001);

endmodule