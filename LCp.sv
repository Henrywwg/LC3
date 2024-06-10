package LCp;

    //Definition of opcodes
    typedef enum logic [3:0]{
        BR,
        ADD,
        LD,
        ST,
        JSR,
        AND,
        LDR,
        STR,
        RTI,
        NOT,
        LDI,
        STI,
        RET,
        RESERVED,
        LEA,
        TRAP
    } opcode;

endpackage