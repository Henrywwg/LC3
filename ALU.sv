import LCp::*;

//ALU module for LC3 processor
//Pretty much just does addition lol
module ALU(
    input [1:0]operation,
    input [15:0]A,
    input [15:0]B,
    output logic [15:0]out
);

    //Yeah... this really didn't need it's own module
    always_comb begin
        case(operation)
            2'b01: out = A & B;
            2'b10: out = ~A;
            default: out = A + B;
        endcase
    end

endmodule