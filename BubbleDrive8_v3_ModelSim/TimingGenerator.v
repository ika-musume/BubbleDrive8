module TimingGenerator
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //4MHz output clock
    output  reg             CLKOUT = 1'b1,

    //Input control
    input   wire            nINCTRL,

    //Bubble control signal inputs
    input   wire            nBSS,
    input   wire            nBSEN,
    input   wire            nREPEN,
    input   wire            nBOOTEN,
    
    //Emulator signal outputs
    output  wire    [2:0]   ACCST,
    output  wire    [1:0]   BOUTTICKS,
    output  reg             nBACT = 1'b1
);

localparam INITIAL_ABS_POSITION = 12'd2051; //0-2052



/*
    GLOBAL NET/REGS
*/
wire            nBSS_intl;
wire            nBSEN_intl;
wire            nREPEN_intl;
wire            nBOOTEN_intl;



/*
    CLOCK DIVIDER
*/
reg     [2:0]   divide12 = 3'd0;

always @(posedge MCLK)
begin
    if(divide12 >= 3'd5)
    begin
        divide12 <= 3'd0;
        CLKOUT <= ~CLKOUT;
    end
    else
    begin
        divide12 <= divide12 + 3'd1;
    end
end



/*
    SYNCHRONIZER CHAIN
*/
reg     [3:0]   step1 = 4'b1110;
reg     [3:0]   step2 = 4'b1110;
reg     [3:0]   step3 = 4'b1110;
reg     [3:0]   step4 = 4'b1110;
assign {nBSS_intl, nBSEN_intl, nREPEN_intl, nBOOTEN_intl} = step4;

always @(posedge MCLK)
begin
    step1[3] <= nINCTRL | nBSS;
    step1[2] <= nINCTRL | nBSEN;
    step1[1] <= nINCTRL | (nREPEN | ~nBOOTEN);
    step1[0] <= ~nINCTRL & nBOOTEN;

    step2 <= step1;
    step3 <= step2;
    step4 <= step3;
end



/*
    ACCESS STATE STATE MACHINE
*/

/*
nREPEN            ¯¯¯¯¯¯¯¯¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

nBOOTEN_intl      ______________________________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
nBSS_intl         ¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
nBSEN_intl        ¯¯¯¯¯¯¯¯|____________________________________|¯¯¯¯¯¯¯¯¯|___________________________________|¯¯¯¯¯

nREPEN_intl       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
                              |----(bootloader load out enable)--   --|               |(page load out enable)|
----->TIME        A    |B |C                                   |A     |B |E           |D                     |A 
A: RESET
B: STANDBY
C: LOAD_BOOTLOADER
D: LOAD_PAGE
*/

localparam RST = 3'b000;    //A
localparam STBY = 3'b001;   //B
localparam BOOT = 3'b100;   //C
localparam USER = 3'b101;   //D
localparam IDLE = 3'b110;   //E

reg access_state = 3'b000;
assign ACCST = access_state;

always @(posedge MCLK)
begin
    case ({nBOOTEN_intl, nBSS_intl, nBSEN_intl})
        3'b000: //GLITCH
        begin
            access_state <= access_state;
        end
        3'b001: //STANDBY
        begin
            if(access_state == RST)
            begin
                access_state <= STBY;
            end
            else
            begin
                access_state <= access_state;
            end
        end
        3'b010: //BOOT
        begin
            if(access_state == STBY)
            begin
                access_state <= BOOT;
            end
            else
            begin
                access_state <= access_state;
            end
        end
        3'b011: //RESET
        begin
            if(access_state == IDLE || naccess_state == BOOT || access_state == USER)
            begin
                access_state <= RST;
            end
            else
            begin
                access_state <= access_state;
            end
        end
        3'b100: //GLITCH
        begin
            access_state <= access_state;
        end
        3'b101: //STANDBY
        begin
            if(access_state == RST)
            begin
                access_state <= STBY;
            end
            else
            begin
                access_state <= access_state;
            end
        end
        3'b110: //IDLE
        begin
            if(access_state == STBY)
            begin
                access_state <= IDLE;
            end
            else
            begin
                if(nREPEN_intl == 1'b0)
                begin
                    access_state <= USER;
                end
                else
                begin
                    access_state <= access_state;
                end
            end
        end
        3'b111: //RESET
        begin
            if(access_state == IDLE || access_state == BOOT || access_state == USER)
            begin
                access_state <= RST;
            end
            else
            begin
                access_state <= access_state;
            end
        end
    endcase
end



/*
    BUBBLE CYCLE STATE MACHINE
*/
//12MHz 1 bubble cycle = 120clks
//48MHz 1 bubble cycle = 480clks
//48MHz 4클럭 또는 12MHz 1클럭 씹힘

reg     [9:0]   MCLK_counter = 10'd0; //카운터는 세기 쉽게 1부터 시작 0아님!!
reg     [1:0]   bubble_half_cycle_counter = 2'd3;
reg     [11:0]  absolute_position_number = INITIAL_ABS_POSITION;
assign BOUTTICKS = bubble_half_cycle_counter;

always @(posedge MCLK)
begin
    //시작
    if(MCLK_counter == 10'd0)
    begin
        if(access_state[2] == 1'b1)
        begin
            MCLK_counter <= 10'd0;

            nBACT <= 1'b1;

            bubble_half_cycle_counter <= 2'd3;

            absolute_position_number <= absolute_position_number;
        end
        else
        begin
            MCLK_counter <= MCLK_counter + 1'd1;

            nBACT <= 1'b1;

            bubble_half_cycle_counter <= 2'd3;

            absolute_position_number <= absolute_position_number;
        end
    end

    //반클럭+1클럭 씹고 23번째 pos엣지에서 버블 돌리기 시작
    else if(MCLK_counter == 10'd88) 
    begin
        MCLK_counter <= MCLK_counter + 1'd1;

        nBACT <= 1'b0;

        if(bubble_half_cycle_counter == 2'd3)
        begin
            bubble_half_cycle_counter <= 2'd0;
        end
        else
        begin
            bubble_half_cycle_counter <= bubble_half_cycle_counter + 1'd1;
        end
    end

    //53번째 pos엣지에서 -X방향
    else if(MCLK_counter == 10'd208)
    begin
        if(access_state[2] == 1'b0) //bubble rotation ends
        begin
            MCLK_counter <= 10'd0;

            nBACT <= 1'b1;

            bubble_half_cycle_counter <= 2'd3;
        end
        else
        begin
            MCLK_counter <= MCLK_counter + 1'd1;

            nBACT <= nBACT;

            if(bubble_half_cycle_counter == 2'd3)
            begin
                bubble_half_cycle_counter <= 2'd0;
            end
            else
            begin
                bubble_half_cycle_counter <= bubble_half_cycle_counter + 1'd1;
            end
        end
    end

    //83번째 pos엣지에서 half disk -Y방향 위치 (여기서 버블 출력)
    else if(MCLK_counter == 10'd328) 
    begin
        MCLK_counter <= MCLK_counter + 1'd1;

        nBACT <= nBACT;

        if(bubble_half_cycle_counter == 2'd3)
        begin
            bubble_half_cycle_counter <= 2'd0;
        end
        else
        begin
            bubble_half_cycle_counter <= bubble_half_cycle_counter + 1'd1;
        end
    end   

    //113번째 pos엣지에서 +X
    else if(MCLK_counter == 10'd468) 
    begin
        MCLK_counter <= MCLK_counter + 1'd1;     

        nBACT <= nBACT;
        
        if(bubble_half_cycle_counter == 2'd3)
        begin
            bubble_half_cycle_counter <= 2'd0;
        end
        else
        begin
            bubble_half_cycle_counter <= bubble_half_cycle_counter + 1'd1;
        end
    end   

    //143번째 pos엣지에서 half disk +Y방향 위치
    else if(MCLK_counter == 10'd568) 
    begin
        MCLK_counter <= 10'd89;

        nBACT <= nBACT;

        if(bubble_half_cycle_counter == 2'd3)
        begin
            bubble_half_cycle_counter <= 2'd0;
        end
        else
        begin
            bubble_half_cycle_counter <= bubble_half_cycle_counter + 1'd1;
        end

        if(absolute_position_number < 12'd2052)
        begin
            absolute_position_number <= absolute_position_number + 12'd1;
        end
        else
        begin
            absolute_position_number <= 12'd0;
        end
    end

    //나머지
    else
    begin
        MCLK_counter <= MCLK_counter + 1'd1;

        nBACT <= nBACT;

        bubble_half_cycle_counter <= bubble_half_cycle_counter;

        absolute_position_number <= absolute_position_number;
    end
end

endmodule