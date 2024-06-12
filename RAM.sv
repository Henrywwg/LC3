module RAM(
    input clk,
    input we,   //High is write - low is read
    input mem_en,
    input [15:0]addr,
    input [15:0]rdata,
    output logic [15:0]data
);

logic [15:0]mem[0:511];           //set to 65535 for full size testing - 511 for ez testing

    always_ff @(posedge clk) begin
        if (we && mem_en)
            mem[addr] <= rdata;
        else if(mem_en)
            data <= mem[addr];
    end


endmodule