module RAM_reg(
    input clk,
    input rst_n,
    input [15:0]bus,
    input [15:0]mem_data,
    input LD_MAR,
    input LD_MDR,
    input mem_en,
    
    output MDRchange,

    output logic [15:0]addr,

    output logic [15:0]data   //data to ram and bus
);

    logic [15:0]data_in;
    logic [15:0]flopped_data;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            addr <= '0;
        else if(LD_MAR)
            addr <= bus;
        

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            data <= '0;
        else if(LD_MDR)
            data <= data_in;

    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            flopped_data <= '0;
        else if(LD_MDR)
            flopped_data <= data;

    assign MDRchange = flopped_data != data;    //If data changes then MDRchange goes high for a clock

    //uhh its funky
    assign data_in = mem_en ? mem_data : bus;
        

endmodule