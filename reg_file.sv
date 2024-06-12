import LCp::*;

//Models a register file of 8 gp registers
module reg_file(
    input clk,
    input rst_n,

    input [2:0]SR1,
    input [2:0]SR2,
    input [2:0]DR,
    input LD_REG,

    input [15:0]BUS_IN,

    output logic [15:0]OUT1,
    output logic [15:0]OUT2
);

    //Instantiate registers
    logic [15:0]gen_reg[7:0];

    //Clear each register on rst
    // Otherwise if LD_REG, load the specified reg with the value from the bus
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[0] <= 16'h0000;
        else if(LD_REG && (DR == 3'b000))
            gen_reg[0] <=  BUS_IN;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[1] <= 16'h0000;
        else if(LD_REG && (DR == 3'b001))
            gen_reg[1] <=  BUS_IN;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[2] <= 16'h0000;
        else if(LD_REG && (DR == 3'b010))
            gen_reg[2] <=  BUS_IN;


    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[3] <= 16'h0000;
        else if(LD_REG && (DR == 3'b011))
            gen_reg[3] <=  BUS_IN;


    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[4] <= '0;
        else if(LD_REG && (DR == 3'b100))
            gen_reg[4] <=  BUS_IN;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[5] <= '0;
        else if(LD_REG && (DR == 3'b101))
            gen_reg[5] <=  BUS_IN;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[6] <= '0;
        else if(LD_REG && (DR == 3'b110))
            gen_reg[6] <=  BUS_IN;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            gen_reg[7] <= '0;
        else if(LD_REG && (DR == 3'b111))
            gen_reg[7] <=  BUS_IN;


    //Assign outputs based on SRs picked
    always_comb begin
        case(SR1)
            3'b000: OUT1 = gen_reg[0];
            3'b001: OUT1 = gen_reg[1];
            3'b010: OUT1 = gen_reg[2];
            3'b011: OUT1 = gen_reg[3];
            3'b100: OUT1 = gen_reg[4];
            3'b101: OUT1 = gen_reg[5];
            3'b110: OUT1 = gen_reg[6];
            default: OUT1 = gen_reg[7];
        endcase

        case(SR2)
            3'b000: OUT2 = gen_reg[0];
            3'b001: OUT2 = gen_reg[1];
            3'b010: OUT2 = gen_reg[2];
            3'b011: OUT2 = gen_reg[3];
            3'b100: OUT2 = gen_reg[4];
            3'b101: OUT2 = gen_reg[5];
            3'b110: OUT2 = gen_reg[6];
            default: OUT2 = gen_reg[7];
        endcase
    end
endmodule