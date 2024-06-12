import LCp::*;

module LC3(
    input clk,
    input rst_n,
    input [15:0]cmd
);
    //Internal signals
    logic [15:0]PC;   //Program counter
    logic [15:0]IR;
    logic [3:0]op;   //opcode based on current instruction
    logic [1:0]ALUop;
    logic LD_IR, LD_CC, LD_PC, LD_REG, LD_MAR;
    logic [2:0]SR1, SR2, DR;    //Source and dest registers
    logic [15:0]FO1, FO2;       //Outputs of register file
    logic [15:0]BUS;              //The whole ass buss
    logic [15:0]ALUB;
    logic [2:0]NZP_val;
    logic we;
    logic s_flag;
    logic MDRchange, RAMchange;

    logic [15:0]MAR, MDR;   //Memory address and data registers

    logic [15:0]ram_data;

    logic mem_en;
    logic [15:0]mem_addr;
    logic [15:0]mem_data;

    logic [15:0]flopped_ram_data;
    

    //Bus gates
    logic gateMARMUX, gateALU, gatePC, gateMDR;
    

    //Mux signals (product of SM)
    logic [1:0]PCmuxsig;
    logic ADDR1muxsig;
    logic [1:0]ADDR2muxsig;
    logic [15:0]ADDR1mux, ADDR2mux, PCMUX, SR2mux;
    logic [15:0]ALUout;
    logic [15:0]ADDRsum;
    logic [15:0]MARMUX;
    logic MARMUXsig;


    //State machine type
    typedef enum logic [2:0]{FETCHTO_MEM, LOADTO_MDR, LOADTO_BUS, FETCHTO_IR, JSR_PC PROC_CMD} state_t;

    state_t state, nxt_state;

    //Internal assignments
    assign op = cmd[15:12]; //Make opcodes easier to work with

    ///////////////////
    // STATE MACHINE //
    ///////////////////

    //SM sequential logic
    //Reset to IDLE, otherwise advance to nxt_state
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            state <= IDLE;
        else
            state <= nxt_state;

    //Combination logic for SM
    always_comb begin
        //Default outputs

        //Flag
        s_flag = 0;

        //Active high//
        nxt_state = state;
        LD_REG = 0;
        LD_IR = 0;
        LD_CC = 0;
        LD_MAR = 0;
        LD_PC = 0;
        SR1 = '0;
        SR2 = '0;
        DR = '0;
        PCmuxsig = '0;
        SR2mux = 0;
        ADDR1muxsig = 0;
        ADDR2muxsig = '0;
        MARMUXsig = 0;
        ALUop = '0;
        mem_en = 0;
        we = 0;

        //Active low//
        gateALU = 1;
        gateMARMUX = 1;
        gateMDR = 1;
        gatePC = 1;
    
        case(state)
            //Fetch an instruction from memory
            FETCHTO_MEM: begin
                gatePC = 0; //Put PC on BUS
                LD_MAR = 1; //Load PC to mem address reg
                we = 0;     //Reading from mem
                mem_en = 1; //Enable RAM
                nxt_state = LOADTO_MDR;
            end

            LOADTO_MDR: begin
                mem_en = 1; //Still need mem enabled
                we = 0;     //Still reading...
                nxt_state = LOADTO_BUS;
            end

            LOADTO_BUS: begin
                mem_en = 1; //Still need mem enabled
                we = 0;     //Still reading...
                LD_MDR = 1; //Load mem value into MDR
                gateMDR = 0;//Put MDR onto bus
                nxt_state = FETCHTO_IR;
            end

            FETCHTO_IR: begin
                gateMDR = 0;//Keep MDR on Bus
                LD_IR = 1;  //Store in IR
                nxt_state = PROC_CMD;
            end
            
            PROC_CMD: begin
                case(op)
                    BR: if(|(NZP_val & cmd[11:9])) begin  //Might be broken... be careful
                            ADDR1muxsig = 0;            //MUX PC val
                            ADDR2muxsig = 2'b01;        //MUX SEXT 9bit
                            PCmuxsig = 2'b01;
                            LD_PC = 1;
                            nxt_state = FETCHTO_MEM;
                        end
                    ADD: begin
                        SR1 = cmd[8:6];
                        DR = cmd[11:9];
                        if(~cmd[5]) begin
                            SR2 = cmd[2:0];
                        end
                        else begin
                            SR2mux = 1; //Get immediate value
                        end
                        ALUop = 2'b00;
                        gateALU = 0;
                        LD_CC = 1;
                        LD_REG = 1;
                        LD_PC = 1;
                        nxt_state = FETCHTO_MEM;
                    end
                    LD: begin
                        DR = cmd[11:9];
                        MARMUXsig = 0; 
                        ADDR2muxsig = 2'b01;
                        ADDR1muxsig = 1'b0;
                        gateMARMUX = 0; //Put calculated address to bus
                        LD_MAR = 1;     //Clock in address to MAR
                        PCmuxsig = 2'b00;
                        LD_PC = 1;  //Load PC now since we won't do it later and it won't effect any control flow
                        nxt_state = LOADTO_MDR; //Jump to the loading IR
                    end
                    ST:;
                    JSR_save: begin
                        DR = 3'b111;    //Save return address (PC val)
                        gatePC = 0;     //Output PC to bus
                        LD_REG = 1;
                        nxt_state = JSR_PC;
                    end
                    AND: begin
                        SR1 = cmd[8:6];
                        DR = cmd[11:9];
                        SR2 = cmd[2:0];
                        if(cmd[5]) begin
                            SR2mux = 1; //Get immediate value
                        end
                        ALUop = 2'b01;
                        gateALU = 0;
                        LD_CC = 1;
                        LD_REG = 1;
                        LD_PC = 1;
                        nxt_state = FETCHTO_MEM;
                    end
                    LDR:;
                    STR:;
                    RTI:;
                    NOT: begin
                        DR = cmd[11:9];
                        SR1 = cmd[8:6];
                        ALUop = 2'b10;  //NOT
                        gateALU = 0;
                        LD_CC = 1;
                        LD_REG = 1;
                        LD_PC = 1;
                        nxt_state = FETCHTO_MEM;
                    end
                    LDI:;
                    STI:;
                    RET: begin
                        SR1 = cmd[8:6];
                        ALUop = 2'b11;  //NOP
                        gateALU = 0;
                        PCmuxsig = 2'b11;
                        LD_PC = 1;
                        nxt_state = FETCHTO_MEM;
                    end
                    RESERVED:;
                    LEA:;
                    TRAP:;
                endcase
            end

            JSR_PC: begin
                if(cmd[11]) begin
                    PCmuxsig = 2'b01;   //Get sum of two values for PC value
                    ADDR2muxsig = 2'b00;//SEXT 11 bit
                    ADDR1muxsig = 0;    //PC cur. val
                    LD_PC = 1;
                end 
                nxt_state = FETCHTO_MEM;
            end

            // LD_FETCH: begin
            //     mem_en = 1;
            //     if(MDRchange)begin
            //         gateMDR = 0;    //Put MDR onto bus
            //         LD_IR = 1;
            //     end
            //     else if (RAMchange) begin  //If value not loaded to MDR
            //         we = 1;         //permit writing
            //         LD_MDR = 1;     //write to MDR
            //     end
            //     else begin
            //         we = 0; //Read from RAM
            //     end
            // end

            default: nxt_state = FETCHTO_MEM;

        endcase

    end

    //////////////////////
    // PROGRAM COUNTER  //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            PC <= { {15{1'b0}},1'b1};
        else if (LD_PC)
            case(PCmuxsig)
                2'b00: PC <= PC + 1;    //PC incrementor
                2'b01: PC <= ADDRsum;   //Address sum
                default: PC <= BUS;     //Default to bus
            endcase

    //////////////////////
    // INSTRUCTION REG  //
    //////////////////////
     always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            IR <= '0;
        else if(LD_IR)
            IR <= BUS;   

    //////////////////////
    // Flopped RAM data //
    //////////////////////
     always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            flopped_ram_data <= '0;
        else
            flopped_ram_data <= ram_data;  

    assign RAMchange = flopped_ram_data != ram_data; 


    

    //MUX GALORE
    assign ALUB = SR2mux ? {{11{IR[4]}}, IR[4:0]} : FO2;   //ALU b input gets sign extended IR val or output of SR2 from file reg

    assign ADDR1mux = ADDR1muxsig ? FO1 : PC;
    assign ADDR2mux = ADDR2muxsig[0] ? (ADDR2muxsig[1] ? '0 : {{7{IR[8]}}, IR[8:0]}) : //11 & 01
                                       (ADDR2muxsig[1] ? {{10{IR[5]}}, IR[5:0]} : {{5{IR[10]}}, IR[10:0]}); //10 & 00

    assign MARMUX = MARMUXsig ? {{8'h00}, IR[7:0]} : ADDRsum;

    //ADDRsum is the sum of the ADDRs... simple enough
    assign ADDRsum = ADDR1mux + ADDR2mux;

    ///////////////
    // BUS LOGIC //
    ///////////////
    always_comb begin
        if(~gateALU)
            BUS = ALUout;
        else if (gateMARMUX)
            BUS = MARMUX;
        else if (gateMDR)
            BUS = mem_data;
        else if (gatePC)
            BUS = PC;
        else 
            BUS = 'Z;//Hi impedance
    end



    /////////////////////////
    // INSTANTIATE MODULES //
    /////////////////////////

    // Instantiate ALU //
    ALU iALU(.operation(ALUop), .A(FO1), .B(ALUB), .out(ALUout));
    
    // Instantiate NZP logic //
    NZP iNZP(.clk(clk), .rst_n(rst_n), .BUS(BUS), .NZP_en(LD_CC), .NZP_val(NZP_val));

    // Instantiate registers // done
    reg_file iREG(.clk(clk), .rst_n(rst_n), .SR1(SR1), .SR2(SR2), .DR(DR), .LD_REG(LD_REG), .BUS_IN(BUS), .OUT1(FO1), .OUT2(FO2));

    // Instantiate placeholder RAM //
    RAM iRAM(.clk(clk), .we(we), .mem_en(mem_en), .addr(mem_addr), .rdata(mem_data), .data(ram_data));

    // Instantiate RAM register //
    RAM_reg iRREG(.clk(clk), .rst_n(rst_n), .bus(BUS), .mem_data(ram_data), .LD_MAR(LD_MAR), .LD_MDR(LD_MDR), .mem_en(mem_en), .addr(mem_addr), .data(mem_data), .MDRchange(MDRchange));


endmodule