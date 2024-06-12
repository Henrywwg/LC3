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
    logic MDRchange, RAMchange, MARchange, REGchange;

    logic [15:0]MAR, MDR;   //Memory address and data registers

    logic [15:0]ram_data;

    logic mem_en;
    logic [15:0]mem_addr;
    logic [15:0]mem_data;

    logic [15:0]flopped_ram_data;
    logic [15:0]flopped_MAR;
    logic flopped_LD_REG;   //i might be a genius

    //counter for clocks in instruction (a sub PC PC if you will)
    logic [2:0]INSTRUCTION_COUNTER;

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

    ///////////////////////////////
    // Processor Status Register //
    ///////////////////////////////
    logic [15:0]PSR;
    logic [15:3]PSR_new; //NZP is always defined


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
        INC_INSTRUCTION_COUNTER = 0;
        RESET_INSTRUCTION_COUNTER = 1;

        //PSR gets itself unless modified
        PSR_new = PSR[15:3];

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
                        mem_en = 1;
                        if(~(MARchange | MDRchange | RAMchange)) begin    //Step 1 - no modification to any registers yet 
                            MARMUXsig = 0;          //Sum of addr
                            ADDR2muxsig = 2'b01;    //SEXT 9
                            ADDR1muxsig = 1'b0;     //PC
                            //ADDR = PC + SEXT 9
                            gateMARMUX = 0;         //Put calculated address to bus
                            LD_MAR = 1;             //Clock in address to MAR
                        end
                        else if (MARchange)         //Step 2 give 1 cc for RAM to read data from location
                            we = 0;                 //Read from RAM
                        else if (RAMchange) begin   //Step 3 clock RAM value into MDR
                            we = 0;                 //Still just reading
                            LD_MDR = 1;             //write to MDR
                        end
                        else if(MDRchange)begin     //Step 4 - Put MDR on bus and load DR with data it
                            gateMDR = 0;            //Put MDR onto bus
                            LD_REG = 1;             //clock into DR
                            PCmuxsig = 2'b00;
                            LD_PC = 1;              //Inc program counter
                            LD_CC = 1;              //Get NZP val
                            nxt_state = FETCHTO_MEM;//Get next instruction
                        end
                    end
                    
                    ST: begin
                        SR1 = cmd[11:9];
                        if(~(MARchange | MDRchange | RAMchange)) begin//Step 1 - Load MAR with SEXT 9 + PC
                            MARMUXsig = 0;          //Sum of addr
                            ADDR2muxsig = 2'b01;    //SEXT 9
                            ADDR1muxsig = 1'b0;     //PC
                            gateMARMUX = 0;         //Put calculated address to bus
                            LD_MAR = 1;             //Clock in address to MAR
                        end
                        else if (MARchange) begin   //Step 2 - Load MDR with SR
                            ALUop = 2'b11;          //NOP
                            gateALU = 0;            //Put SR1 to bus
                            LD_MDR = 1;             //Load bus to MDR
                        end
                        else if (MDRchange) begin   //Step 3 - Store MDR to RAM
                            mem_en = 1;             //Enable that suckah
                            we = 1;                 //Write on next cc
                            PCmuxsig = 2'b00;
                            LD_PC = 1;              //Inc program counter
                            nxt_state = FETCHTO_MEM;//Get next instruction
                        end
                    end

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
                   
                    LDR:begin
                        DR = cmd[11:9];
                        SR1 = cmd[8:6]; //Base register
                        mem_en = 1;
                        if(~(MARchange | MDRchange | RAMchange)) begin    //Step 1 - no modification to any registers yet 
                            MARMUXsig = 0; 
                            ADDR2muxsig = 2'b10;    //SEXT 6 bit
                            ADDR1muxsig = 1'b1;     //SR1 register
                            gateMARMUX = 0; //Put calculated address to bus
                            LD_MAR = 1;     //Clock in address to MAR
                        end
                        else if (MARchange) //Step 2 give 1 cc for RAM to read data from location
                            we = 0; //Read from RAM
                        else if (RAMchange) begin  //Step 3 clock RAM value into MDR
                            we = 0;         //Still just reading
                            LD_MDR = 1;     //write to MDR
                        end
                        else if(MDRchange)begin  //Step 4 - Put MDR on bus and load DR with data it
                            gateMDR = 0;    //Put MDR onto bus
                            LD_REG = 1;     //clock into DR
                            PCmuxsig = 2'b00;
                            LD_PC = 1;  //Inc program counter
                            LD_CC = 1;              //Get NZP val
                            nxt_state = FETCHTO_MEM;//Get next instruction
                        end

                    end
                   
                    STR: begin
                        SR1 = cmd[11:9];
                        if(~(MARchange | MDRchange | RAMchange)) begin//Step 1 - Load MAR with SEXT 9 + PC
                            MARMUXsig = 0;          //Sum of addr
                            ADDR2muxsig = 2'b10;    //SEXT 6
                            ADDR1muxsig = 1'b1;     //PC
                            gateMARMUX = 0;         //Put calculated address to bus
                            LD_MAR = 1;             //Clock in address to MAR
                        end
                        else if (MARchange) begin   //Step 2 - Load MDR with SR
                            ALUop = 2'b11;          //NOP
                            gateALU = 0;            //Put SR1 to bus
                            LD_MDR = 1;             //Load bus to MDR
                        end
                        else if (MDRchange) begin   //Step 3 - Store MDR to RAM
                            mem_en = 1;             //Enable that suckah
                            we = 1;                 //Write on next cc
                            PCmuxsig = 2'b00;
                            LD_PC = 1;              //Inc program counter
                            nxt_state = FETCHTO_MEM;//Get next instruction
                        end
                    end
                 
                    RTI:;   //Uhh not actually sure about this one (return from interrupt) we'll just hope we don't use this one...
                 
                    NOT: begin
                        DR = cmd[11:9];
                        SR1 = cmd[8:6];
                        ALUop = 2'b10;  //NOT
                        gateALU = 0;
                        LD_CC = 1;
                        LD_REG = 1;
                        LD_PC = 1;  //increment PC
                        nxt_state = FETCHTO_MEM;
                    end
                 
                    LDI: begin //MEM[MEM[PC + SEXT 9]]
                        INC_INSTRUCTION_COUNTER = 1;
                        RESET_INSTRUCTION_COUNTER = 0;  //Enable the mega counting to begin :3
                        DR = cmd[11:9];                                
                        case(INSTRUCTION_COUNTER)
                            3'b000: begin                       //MAR <- PC + SEXT 9            MDR <- MEM[PC + SEXT 9]]
                                        mem_en = 1;
                                        MARMUXsig = 0;          //Sum of addr
                                        ADDR2muxsig = 2'b01;    //SEXT 9
                                        ADDR1muxsig = 1'b0;     //PC
                                        //ADDR = PC + SEXT 9
                                        gateMARMUX = 0;         //Put calculated address to bus
                                        LD_MAR = 1;             //Clock in address to MAR
                                    end
                            3'b001: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end
                            3'b010: begin                       //MDR <- MEM[MAR]   
                                        mem_en = 1;
                                        we = 0;                 //Still just reading
                                        LD_MDR = 1;             //write to MDR
                                    end

                            3'b011: begin
                                        mem_en = 1;
                                        gateMDR = 0;            //Put MDR onto bus
                                        LD_MAR = 1;             //clock into MAR again
                                    end

                            3'b100: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end

                            3'b101: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end

                            3'b110: begin                       //MDR <- MEM[MAR]   
                                        mem_en = 1;
                                        gateMDR = 0;            //Put MDR onto bus
                                        LD_REG = 1;             //write to DR
                                        PCmuxsig = 2'b00;
                                        LD_PC = 1;              //Inc program counter
                                        LD_CC = 1;              //Get NZP val
                                        nxt_state = FETCHTO_MEM;//Get next instruction
                                    end
                            default: nxt_state = default;   //Should never get here... but if we do halt in default

                        endcase
                    end
                
                    STI: begin
                        INC_INSTRUCTION_COUNTER = 1;
                        RESET_INSTRUCTION_COUNTER = 0;  //Enable the mega counting to begin :3
                        DR = cmd[11:9];                                
                        case(INSTRUCTION_COUNTER)
                            3'b000: begin                       //MAR <- PC + SEXT 9            MDR <- MEM[PC + SEXT 9]]
                                        mem_en = 1;
                                        MARMUXsig = 0;          //Sum of addr
                                        ADDR2muxsig = 2'b01;    //SEXT 9
                                        ADDR1muxsig = 1'b0;     //PC
                                        //ADDR = PC + SEXT 9
                                        gateMARMUX = 0;         //Put calculated address to bus
                                        LD_MAR = 1;             //Clock in address to MAR
                                    end
                            3'b001: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end
                            3'b010: begin                       //MDR <- MEM[MAR]   
                                        mem_en = 1;
                                        we = 0;                 //Still just reading
                                        LD_MDR = 1;             //write to MDR
                                    end

                            3'b011: begin
                                        mem_en = 1;
                                        gateMDR = 0;            //Put MDR onto bus
                                        LD_MAR = 1;             //clock into MAR again
                                    end

                            3'b100: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end

                            3'b101: begin
                                        mem_en = 1;
                                        we = 0;  
                                        LD_MDR = 1;             //Read from RAM
                                    end

                            3'b110: begin                       //MDR <- MEM[MAR]   
                                        mem_en = 1;
                                        gateMDR = 0;            //Put MDR onto bus
                                        LD_REG = 1;             //write to DR
                                        PCmuxsig = 2'b00;
                                        LD_PC = 1;              //Inc program counter
                                        LD_CC = 1;              //Get NZP val
                                        nxt_state = FETCHTO_MEM;//Get next instruction
                                    end
                            default: nxt_state = default;   //Should never get here... but if we do halt in default
                    end
               
                    RET: begin
                        SR1 = cmd[8:6];
                        ALUop = 2'b11;  //NOP
                        gateALU = 0;
                        PCmuxsig = 2'b11;
                        LD_PC = 1;
                        nxt_state = FETCHTO_MEM;
                    end
                  
                    RESERVED:begin  //Throw Illegal Op instruction      can't really be fucked to do this...
                        PSR_new[15] = 0; //Pass control to Kernel
                        //R6 <- PC
                        //MEM[PC] = PC
                    end
                  
                    LEA:begin //Went from hating this instruction to realizing it's neat AF
                        DR = cmd[11:9];
                        ADDR1muxsig = 0;        //PC
                        ADDR2muxsig = 2'b01;    //SEXT 9
                        MARMUXsig = 0;          //Put effective address to bus
                        gateMARMUX = 0;         //enable
                        LD_REG = 1;
                        PCmuxsig = 2'b11;
                        LD_PC = 1;              //Increment PC
                        LD_CC = 1;              //Get NZP val
                        nxt_state = FETCHTO_MEM;//Get next instruction
                    end
                  
                    TRAP: begin
                        mem_en = 1;
                        if(~REGchange) begin        //R7 <- PC
                            DR = 3'b111;    
                            gatePC = 0;
                            LD_REG = 1;
                        end
                        else if(~(MARchange | MDRchange | RAMchange)) begin    //MAR = ZEXT 8 
                            MARMUXsig = 1;          //Sum of addr
                            //ADDR = ZEXT 8
                            gateMARMUX = 0;         //Put calculated address to bus
                            LD_MAR = 1;             //Clock in address to MAR
                        end
                        else if (MARchange) begin   //Step 2 give 1 cc for RAM to read data from location
                            we = 0;                 //Read from RAM
                            LD_MDR = 1;
                        end
                        else if (RAMchange) begin   //Step 3 clock RAM value into MDR
                            we = 0;                 //Still just reading
                            LD_MDR = 1;             //write to MDR
                        end
                        else if(MDRchange)begin     //Step 4 - Put MDR on bus and load DR with data it
                            gateMDR = 0;            //Put MDR onto bus
                            PCmuxsig = 2'b1?;       //Load PC val from bus
                            LD_PC = 1;              //clock into PC
                            nxt_state = FETCHTO_MEM;//Get next instruction
                        end

                    end
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

            default: ; //Halt state incase we fuck up... keeps the program from running wild

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
    // INSTRUCTION CNT  //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            INSTRUCTION_COUNTER <= '0;
        else if(RESET_INSTRUCTION_COUNTER)
            INSTRUCTION_COUNTER <= '0;
        else if(INC_INSTRUCTION_COUNTER)
            INSTRUCTION_COUNTER <= INSTRUCTION_COUNTER + 1;

    ///////////////
    // PSR LOGIC //
    ///////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            PSR <= '0;
        else
            PSR <= {PSR_new, NZP_val};   

    //////////////////////
    // Flopped RAM data //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            flopped_ram_data <= '0;
        else
            flopped_ram_data <= ram_data;  
    assign RAMchange = flopped_ram_data != ram_data; 

    //////////////////////
    // Flopped MAR val. //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            flopped_MAR <= '0;
        else
            flopped_MAR <= mem_addr;  
    assign MARchange = flopped_MAR != mem_addr; 

    //////////////////////
    // Flopped REG val. //
    //////////////////////
    always_ff @(posedge clk, negedge rst_n)
        if(!rst_n)
            flopped_LD_REG <= '0;
        else
            flopped_LD_REG <= LD_REG; 
    assign REGchange = flopped_LD_REG != LD_REG;


    

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