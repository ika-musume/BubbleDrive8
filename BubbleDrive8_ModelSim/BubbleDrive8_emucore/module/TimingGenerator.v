module TimingGenerator
/*
    BubbleDrive8_emucore > modules > TimingGenerator.v

    Copyright (C) 2020-2021, Raki

    TimingGenerator provides all timing signals related to 
    the bubble memory side. This module uses 48MHz as master clock, 
    x4 of the original function timing generator(FTG) MB14506.
    Thereby BubbleDrive8 can manage all bubble logic without using 
    a PLL block. 


    * more details of signals below can be found on bubsys85.net *

    CLKOUT: 
        4MHz clock for the bubble memory controller: maybe an MCU uses this
    nBSS: Bubble Shift Start
        a pulse to notify a start of access cycle
    nBSEN: Bubble Shift ENable
        magnetic field rotates when this signal goes low
    nREPEN: REPlicator ENable
        FTG use this signal to replicate a bubble 
    nBOOTEN: BOOTloop ENable
        controller can access two bootloops by driving this signal low
    nSWAPEN: SWAP gate ENable
        FTG use this signal to write a page to a bubble memory

    nEN: module enable signal
    ACCTYPE: bubble access mode type
    BOUTCYCLENUM: bubble output cycle number: counts serial bits
    nBINCLKEN: emulator samples bubble data for page write when this goes low
    nBOUTCLKEN: emulator launches bubble data when this goes low
    nNOBUBBLE: emulator launches 1(no bubble)

    ABSPOS: bubble memory's absolute position number


    * For my convenience, many comments are written in Korean *
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //4MHz output clock
    output  reg             CLKOUT = 1'b1,

    //Input control
    input   wire            nEN,

    //Bubble control signal inputs
    input   wire            nBSS,
    input   wire            nBSEN,
    input   wire            nREPEN,
    input   wire            nBOOTEN,
    input   wire            nSWAPEN,
    
    //Emulator signal outputs
    output  wire    [2:0]   ACCTYPE,
    output  reg     [12:0]  BOUTCYCLENUM,
    output  reg             nBINCLKEN = 1'b1,
    output  reg             nBOUTCLKEN = 1'b1,

    output  wire    [11:0]  ABSPOS
);

localparam  INITIAL_ABS_POSITION = 12'd1951; //0-2052


/*
    GLOBAL NET/REGS
*/
wire            nBSS_intl;
wire            nBSEN_intl;
wire            nREPEN_intl;
wire            nBOOTEN_intl;
wire            nSWAPEN_intl;



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
reg     [4:0]   step1 = 5'b11110;
reg     [4:0]   step2 = 5'b11110;
reg     [4:0]   step3 = 5'b11110;
reg     [4:0]   step4 = 5'b11110;
assign {nSWAPEN_intl, nBSS_intl, nBSEN_intl, nREPEN_intl, nBOOTEN_intl} = step4;

always @(posedge MCLK)
begin
    step1[4] <= nEN | nSWAPEN;
    step1[3] <= nEN | nBSS;
    step1[2] <= nEN | nBSEN;
    step1[1] <= nEN | (nREPEN | ~nBOOTEN);
    step1[0] <= ~nEN & nBOOTEN;

    step2 <= step1;
    step3 <= step2;
    step4 <= step3;
end



/*
    ACCESS STATE STATE MACHINE
*/

/*
    nREPEN            ¯¯¯¯¯¯¯¯¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯

    nBSS_intl         ¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    nBOOTEN_intl      ______________________________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    nBSEN_intl        ¯¯¯¯¯¯¯¯|____________________________________|¯¯¯¯¯¯¯¯¯|__________________________|¯¯¯¯¯¯|__________________________|¯¯¯
    nREPEN_intl       ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
    nSWAPEN_intl      ¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|_|¯¯¯¯¯¯¯¯
                              |----(bootloader load out enable)----|             |(page load out enable)|                          |(swap)|
    ----->TIME        A    |B |C                                   |A     |B |E  |D(HOLD)               |A  |B |E                  |F     |A
*/

//[magnetic field activation/data transfer/mode]
localparam RST = 3'b000;    //A
localparam STBY = 3'b001;   //B
localparam BOOT = 3'b110;   //C
localparam USER = 3'b111;   //D
localparam IDLE = 3'b100;   //E
localparam SWAP = 3'b101;   //F

reg     [2:0]   access_type = RST;
assign ACCTYPE = access_type;

always @(posedge MCLK)
begin
    case ({nBSS_intl, nBOOTEN_intl, nBSEN_intl, nREPEN_intl, nSWAPEN_intl})
        5'b10111: //최초 시작 후의 리셋 상태, 또는 부트로더 액세스가 끝난 후 아주 잠깐 발생
        begin
            if(access_type == STBY)
            begin
                access_type <= STBY;
            end
            else
            begin
                access_type <= RST;
            end
        end

        5'b00111: //부트로더 스탠바이
        begin
            if(access_type == RST)
            begin
                access_type <= STBY;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        5'b10011: //부트로더 액세스 중
        begin
            if(access_type == STBY || access_type == BOOT || access_type == RST)
            begin
                access_type <= BOOT;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        5'b11111: //유저 영역 리셋 상태
        begin
            if(access_type == STBY)
            begin
                access_type <= STBY;
            end
            else
            begin
                access_type <= RST;
            end
        end

        5'b01111: //페이지 스탠바이
        begin
            if(access_type == RST)
            begin
                access_type <= STBY;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        5'b11011: //페이지 seek중, 또는 페이지 로딩 중(로딩 중에는 리플리케이션을 유지)
        begin
            if(access_type == STBY || access_type == RST)
            begin
                access_type <= IDLE;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        5'b11001: //리플리케이션 펄스가 들어왔을 때
        begin
            if(access_type == IDLE)
            begin
                access_type <= USER;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        5'b11010: //스왑 펄스가 들어왔을 때
        begin
            if(access_type == IDLE)
            begin
                access_type <= SWAP;
            end
            else
            begin
                access_type <= access_type;
            end
        end

        default:
        begin
            access_type <= access_type;
        end
    endcase
end



/*
    BUBBLE CYCLE STATE MACHINE
*/
//12MHz 1 bubble cycle = 120clks
//48MHz 1 bubble cycle = 480clks
//48MHz 4클럭 또는 12MHz 1클럭 씹힘

reg     [9:0]   MCLK_counter = 10'd0; //마스터 카운터는 세기 쉽게 1부터 시작 0아님!!

//master clock counters
always @(posedge MCLK)
begin
    //시작
    if(MCLK_counter == 10'd0)
    begin
        if(access_type[2] == 1'b0)
        begin
            MCLK_counter <= 10'd0;
        end
        else
        begin
            MCLK_counter <= MCLK_counter + 10'd1;
        end
    end

    //53번째 pos엣지에서 half disk -X방향 위치
    else if(MCLK_counter == 10'd208)
    begin
        if(access_type[2] == 1'b0) //-X방향에서 자기장회전이 끝났다면
        begin
            MCLK_counter <= 10'd0; //그대로 정지
        end
        else
        begin
            MCLK_counter <= MCLK_counter + 10'd1;
        end
    end

    //143번째 pos엣지에서 half disk +Y방향 위치
    else if(MCLK_counter == 10'd568) 
    begin
       MCLK_counter <= 10'd89; 
    end

    else
    begin
        MCLK_counter <= MCLK_counter + 10'd1;
    end
end

/*
        -1
    ----O---- DETECTOR 1
     \  |0 /   <------------ bubble output signal latched here(magnetic field -Y) by MB3908 sense amplifier; stretcher patterns exist here
      --O--   DETECTOR 0
        |                                                   ←     ←     ←     ←     ←         propagation direction
        |1    2         95    96    97    98    99    100   101               680   681
        O-----O   ...   O-----O-----O-----O-----O-----O-----O--             --O-----O
                              ↑     ↑     ↑     ↑     ↑     ↑                 ↑     ↑  
                            __^__ __^__ __^__ __^__ __^__ __^__             __^__ __^__  <-- "block" replicators; replicators for two bootloops
                         ↓  |   | |   | |   | |   | |   | |   |             |   | |   |       can be operated independantly from page replicators
                            |   | |   | |   | |   | |   | |   |             |   | |   | 
                         ↓  | L | | L | | L | | L | | L | | L |             | L | | L | 
                            | O | | O | | O | | O | | O | | O |             | O | | O | 
        ←                ↓  | O | | O | | O | | O | | O | | O |    .....    | O | | O |  <-- each loop can hold 2053 magnetic bubbles
     ↙                     | P | | P | | P | | P | | P | | P |             | P | | P | 
     ↓  ↑ EXTERNAL       ↓  |B 0| |B 1| |  0| |  1| |  2| |  3|             |582| |583| 
        | MAGNETIC          |   | |   | |   | |   | |   | |   |             |   | |   | 
          FIELD             ~   ~ ~   ~ ~   ~ ~   ~ ~   ~ ~   ~             ~   ~ ~O N~ 
                            |   | |   | |   | |   | |   | |   |             |   | |L E| 
                            |   | |   | |   | |   | |   | |   |             |   | |D W| 
                            ¯↓^↑¯ ¯↓^↑¯ ¯↓^↑¯ ¯↓^↑¯ ¯↓^↑¯ ¯↓^↑¯             ¯↓^↑¯ ¯↓^↑¯  <-- swap gate swaps an old bubble with a new bubble at the same time: -Y
                             / \   / \   / \   / \   / \   / \               / \   / \                    2     1
                            /-O-\-/-O-\-/-O-\-/-O-\-/-O-\-/-O-\-            /-O-\-/-O-\---O-----O   ...   O-----O
                              626   625   624   623   622   621               42    41    40    39              |
                                                                                                      __________^_0________
                                                                                                      | G E N E R A T O R | <-- generates a bubble at +Y

    SEE JAPANESE PATENT:
    JPA 1992074376-000000 / 特許出願公開 平4-74376  ;contains replicator/swap gate diagram
    JPA 1989220199-000000 / 特許出願公開 平1-220199 ;explains bubble write procedure
*/

//absolute position counter
reg     [11:0]  absolute_position_number = INITIAL_ABS_POSITION;
assign ABSPOS = absolute_position_number;

always @(posedge MCLK)
begin
    //143번째 pos엣지에서 half disk +Y방향 위치
    if(MCLK_counter == 10'd568) 
    begin
        if(absolute_position_number < 12'd2052)
        begin
            absolute_position_number <= absolute_position_number + 12'd1;
        end
        else
        begin
            absolute_position_number <= 12'd0;
        end
    end
    //+Y 방향 빼고 나머지에서는
    else
    begin
        absolute_position_number <= absolute_position_number;
    end
end

//cycle counter
reg     [6:0]   bout_propagation_delay_counter = 7'd127; //96 or 98
reg     [9:0]   bout_page_cycle_counter = 10'd1023; //584
reg     [12:0]  bout_bootloop_cycle_counter = {1'b0, INITIAL_ABS_POSITION}; //4106

//assign BOUTCYCLENUM = bout_page_cycle_counter[14:2];

always @(posedge MCLK)
begin
    //리셋상태
    if(MCLK_counter == 10'd0)
    begin
        if(access_type == RST) //리셋 시
        begin
            BOUTCYCLENUM <= 13'd8191;

            bout_propagation_delay_counter <= 7'd127;

            bout_page_cycle_counter <= 10'd1023;

            bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter;
        end
        else //그냥 다른 때는 그대로 유지
        begin
            BOUTCYCLENUM <= BOUTCYCLENUM;

            bout_propagation_delay_counter <= bout_propagation_delay_counter;

            bout_page_cycle_counter <= bout_page_cycle_counter;

            bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter;
        end
    end

    //+Y에서 한번씩 체크
    else if(MCLK_counter == 10'd568) //magnetic field rotation activated
    begin
        if(access_type[1] == 1'b0) //IDLE 또는 SWAP: 실제로 데이터가 나가지 않음
        begin
            //empty propagation line
            BOUTCYCLENUM <= 13'd8191;

            //reset state
            bout_propagation_delay_counter <= 7'd127;

            //reset state
            bout_page_cycle_counter <= 10'd1023;

            //count up
            if(bout_bootloop_cycle_counter < 13'd4105)
            begin
                bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter + 13'd1; //bootloop cycle counter는 계속 세기
            end
            else
            begin
                bout_bootloop_cycle_counter <= 13'd0;
            end
        end

        else //BOOT 또는 USER
        begin
            if(bout_propagation_delay_counter == 7'd127 || bout_propagation_delay_counter < 7'd97) //부트로더(초반 2비트가 씹힘)와 페이지 공히 첫 98싸이클 무효
            begin
                //empty propagation line
                BOUTCYCLENUM <= 13'd8191;

                //count up
                if(bout_propagation_delay_counter < 7'd127)
                begin
                    bout_propagation_delay_counter <= bout_propagation_delay_counter + 7'd1;
                end
                else
                begin
                    bout_propagation_delay_counter <= 7'd0;
                end

                //reset state
                bout_page_cycle_counter <= 10'd1023;

                //count up
                if(bout_bootloop_cycle_counter < 13'd4105)
                begin
                    bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter + 13'd1; //bootloop cycle counter는 계속 세기
                end
                else
                begin
                    bout_bootloop_cycle_counter <= 13'd0;
                end
            end

            else //98사이클 지난 후부터
            begin
                if(access_type[0] == 1'b0) //BOOT 액세스,
                begin
                    //hold
                    bout_propagation_delay_counter <= bout_propagation_delay_counter;

                    //reset state
                    bout_page_cycle_counter <= 10'd1023;

                    //count up
                    if(bout_bootloop_cycle_counter < 13'd4105)
                    begin
                        bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter + 13'd1; //bootloop cycle counter는 계속 세기
                        BOUTCYCLENUM <= bout_bootloop_cycle_counter + 13'd1;
                    end
                    else
                    begin
                        bout_bootloop_cycle_counter <= 13'd0;
                        BOUTCYCLENUM <= 13'd0;
                    end
                end
                else //USER 액세스
                begin
                    if(bout_page_cycle_counter == 10'd1023 || bout_page_cycle_counter < 10'd583) //페이지는 584-1 카운트
                    begin
                        //hold
                        bout_propagation_delay_counter <= bout_propagation_delay_counter;

                        //count up
                        if(bout_page_cycle_counter < 10'd583)
                        begin
                            bout_page_cycle_counter <= bout_page_cycle_counter + 10'd1;
                            BOUTCYCLENUM <= {3'b000, (bout_page_cycle_counter + 10'd1)};
                        end
                        else
                        begin
                            bout_page_cycle_counter <= 10'd0;
                            BOUTCYCLENUM <= 13'd0;
                        end

                        //count up
                        if(bout_bootloop_cycle_counter < 13'd4105)
                        begin
                            bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter + 13'd1; //bootloop cycle counter는 계속 세기
                        end
                        else
                        begin
                            bout_bootloop_cycle_counter <= 13'd0;
                        end
                    end
                    else
                    begin
                        //hold
                        bout_propagation_delay_counter <= bout_propagation_delay_counter;

                        //hold
                        bout_page_cycle_counter <= bout_page_cycle_counter;

                        //count up
                        if(bout_bootloop_cycle_counter < 13'd4105)
                        begin
                            bout_bootloop_cycle_counter <= bout_bootloop_cycle_counter + 13'd1; //bootloop cycle counter는 계속 세기
                        end
                        else
                        begin
                            bout_bootloop_cycle_counter <= 13'd0;
                        end
                    end
                end
            end
        end
    end
end

//bubble output clock enable generator
always @(posedge MCLK)
begin
    //리셋상태
    if(MCLK_counter == 10'd0)
    begin
        nBOUTCLKEN <= 1'b1;
    end
    //버블 -Y에서 체크
    else if(MCLK_counter == 10'd328 - 10'd2) //propagation delay보상을 위해 신호를 15ns정도 일찍 보내기; 오래된 기판의 경우 LS244가 느려짐
    begin
        nBOUTCLKEN <= 1'b0;
    end
    else
    begin
        nBOUTCLKEN <= 1'b1;
    end
end

//bubble input enable generator
always @(posedge MCLK)
begin
    //리셋상태
    if(MCLK_counter == 10'd0)
    begin
        nBINCLKEN <= 1'b1;
    end
    //버블 시작, +Y에서 한번씩 체크
    else if(MCLK_counter == 10'd88 || MCLK_counter == 10'd568) 
    begin
        nBINCLKEN <= 1'b0;   
    end
    else
    begin
        nBINCLKEN <= 1'b1;
    end
end

endmodule