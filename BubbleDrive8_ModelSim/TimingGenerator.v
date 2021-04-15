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
    input   wire            nSWAPEN,
    
    //Emulator signal outputs
    output  wire    [2:0]   ACCTYPE,        //access type
    output  wire    [12:0]  BOUTCYCLENUM,   //bubble output cycle number
    output  wire    [1:0]   BOUTTICKS,      //bubble output asynchronous control ticks
    output  wire    [11:0]  ABSPOS          //absolute position number
);

localparam INITIAL_ABS_POSITION = 12'd1955; //0-2052



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
    step1[4] <= nINCTRL | nSWAPEN;
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
        5'b10111: //시작시 리셋상태 혹은 부트로더 액세스 후 잠깐
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

        5'b10011: //부트로더 액세스 시
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

        5'b11111: //평상시 리셋
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

        5'b11011: //페이지 seek 혹은 페이지 로딩
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

        5'b11001: //리플리케이션
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

        5'b11010: //스왑
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

reg     [11:0]  absolute_position_number = INITIAL_ABS_POSITION;
assign ABSPOS = absolute_position_number;

reg     [9:0]   bout_invalid_half_cycle_counter = 10'd1023;
reg     [14:0]  bout_valid_half_cycle_counter = 15'd32767;
assign BOUTCYCLENUM = bout_valid_half_cycle_counter[14:2];
assign BOUTTICKS = bout_invalid_half_cycle_counter[1:0] & bout_valid_half_cycle_counter[1:0];


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

    //53번째 pos엣지에서 -X방향
    else if(MCLK_counter == 10'd208)
    begin
        if(access_type[2] == 1'b0) //bubble rotation ends
        begin
            MCLK_counter <= 10'd0;
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


//absolute position counter
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

    //나머지
    else
    begin
        absolute_position_number <= absolute_position_number;
    end
end

//half cycle counter
always @(posedge MCLK)
begin
    //리셋상태
    if(MCLK_counter == 10'd0)
    begin
        bout_invalid_half_cycle_counter = 10'd1023;
        bout_valid_half_cycle_counter = 15'd32767;
    end

    //버블 시작, -X, -Y, +X, +Y에서 한번씩 체크
    else if(MCLK_counter == 10'd88 || MCLK_counter == 10'd208 || MCLK_counter == 10'd328 || MCLK_counter == 10'd448 || MCLK_counter == 10'd568) 
    begin
        //실제 액세스 안 하면 리셋상태
        if(access_type[1] == 1'b0)
        begin
            bout_invalid_half_cycle_counter = 10'd1023;
            bout_valid_half_cycle_counter = 15'd32767;
        end

        //싸이클 카운팅은 실제 액세스시에만 유효
        else
        begin
            if(bout_invalid_half_cycle_counter == 10'd1023 || bout_invalid_half_cycle_counter < 10'd391) //부트로더, 페이지 모두 첫 98싸이클 무효
            begin
                if(bout_invalid_half_cycle_counter < 10'd1023)
                begin
                    bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter + 10'd1;
                end
                else
                begin
                    bout_invalid_half_cycle_counter <= 10'd0;
                end
                bout_valid_half_cycle_counter <= 15'd32767;
            end
            else //99번째 싸이클부터
            begin
                if(access_type == 3'b110) //부트로더
                begin
                    if(bout_valid_half_cycle_counter < 15'd16423) //부트로더는 2053*2*4-1 카운트
                    begin
                        bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter;
                        bout_valid_half_cycle_counter <= bout_valid_half_cycle_counter + 15'd1; //+1
                    end
                    else
                    begin
                        bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter;
                        bout_valid_half_cycle_counter <= 15'd0; //bootloop는 계속 루프
                    end
                end
                else if(access_type == 3'b111) //페이지
                begin
                    if(bout_valid_half_cycle_counter == 15'd32767 || bout_valid_half_cycle_counter < 15'd2335) //페이지는 584*4-1 카운트
                    begin
                        bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter;
                        if(bout_valid_half_cycle_counter < 15'd32767)
                        begin
                            bout_valid_half_cycle_counter <= bout_valid_half_cycle_counter + 15'd1;
                        end
                        else
                        begin
                            bout_valid_half_cycle_counter <= 15'd0;
                        end
                    end
                    else
                    begin
                        if(bout_invalid_half_cycle_counter < 10'd1022)//584비트 전송 후에는 invalid +1
                        begin
                            bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter + 10'd1; 
                        end
                        else
                        begin
                            bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter;
                        end
                        bout_valid_half_cycle_counter <= 15'd32763;
                    end
                end
                else //가능성 없음
                begin
                    bout_invalid_half_cycle_counter = 10'd1023;
                    bout_valid_half_cycle_counter = 15'd32767;
                end
            end
        end
    end

    //나머지 때에는 값 유지
    else
    begin
        bout_invalid_half_cycle_counter <= bout_invalid_half_cycle_counter;
        bout_valid_half_cycle_counter <= bout_valid_half_cycle_counter;
    end
end

endmodule