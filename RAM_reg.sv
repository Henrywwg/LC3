module RAM_reg(
    input clk,
    input rst_n,
    input [15:0]bus,
    input [15:0]mem_data,
    input LD_MAR,
    input LD_MDR,
    input mem_en,
    
    output logic [15:0]addr,

    output logic [15:0]data   //data to ram and bus
);

    logic [15:0]data_in;

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

    //uhh its funky
    assign data_in = mem_en ? mem_data : bus;
        

endmodule