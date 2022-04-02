module BubbleDrive8_tempsense
/*

*/

(
    //input clock
    input   wire            MCLK,

    //module enable
    input   wire            nEN,

    //startup delay set switch
    input   wire    [2:0]   SETTING, //[FAN/DELAY1/DELAY0]

    //force start switch
    input   wire            PUSHSW,

    //status
    output  reg             nTEMPLO = 1'b0,
    output  wire            nFANEN,
    output  reg             nDELAYING = 1'b0,

    //TC77
    output  wire            nTEMPCS,
    inout   wire            TEMPSIO,
    output  wire            TEMPCLK,

    output  reg     [12:0]  FIFOTEMP,
    output  reg     [11:0]  FIFODLYTIME,
    output  reg             nFIFOSENDTEMP = 1'b1
);

/*
    PARAMETER / REGISTERS
*/

//Temperature checking period(seconds)
localparam      CHECKING_PERIOD = 16'd20;
reg signed  [31:0]  delay_time = 32'd0;

reg             fanon_temphi_n = 1'b1;
reg             fanon_manual_n = 1'b1;
assign  nFANEN = fanon_temphi_n & fanon_manual_n;


/*
    MODULES
*/

//class TimeCounter
wire    [15:0]  TC_time;
reg             TC_reset;
reg             TC_start;
wire            TC_overflow;

TimeCounter TimeCounter_0
(
    .MCLK           (MCLK           ),
    
    .TIMEELAPSED    (TC_time        ),
    
    .nRESET         (TC_reset       ),
    .nSTART         (TC_start       ),
    .OVFL           (TC_overflow    )
);

//class TempLoader
wire    [13:0]  TL_data;
wire            TL_completion;
reg             TL_load;


TempLoader TempLoader_0
(
    .MCLK           (MCLK           ),

    .TEMPDATA       (TL_data        ),

    .nLOAD          (TL_load        ),
    .nCOMPLETE      (TL_completion  ),

    .nCS            (nTEMPCS        ),
    .SIO            (TEMPSIO        ),
    .CLK            (TEMPCLK        )
);



/*
    STARTUP DELAYING / FAN CONTROL STATE MACHINE
*/

//declare states
localparam RESET_S0 = 5'b0_0000;
localparam RESET_S1 = 5'b0_0001;            //nop
localparam RESET_S2 = 5'b0_0010;            //branch

localparam DELAY_FIXED_S0 = 5'b0_0011;      //여름(00) = 2초, 봄가을(01) = 80초, 겨울(10) = 260초 delay_time에 로드
localparam DELAY_FIXED_S1 = 5'b0_0100;      //타이머 시작
localparam DELAY_FIXED_S2 = 5'b0_0101;      //올리고 대기, 타이머 다 되면 S3으로, 아니면 S2, PUSHSW(1) 눌리면 S4로
localparam DELAY_FIXED_S3 = 5'b0_0110;      //타이머 리셋 0
localparam DELAY_FIXED_S4 = 5'b0_0111;      //리셋 올리기, 부팅 시작, FAN_CONTROL_S0으로

localparam DELAY_REALTEMP_S0 = 5'b1_0000;   //실제 온도(11), 타이머 시작
localparam DELAY_REALTEMP_S1 = 5'b1_0001;   //1초 되면 S2로
localparam DELAY_REALTEMP_S2 = 5'b1_0010;   //온도 로드, 타이머 리셋 0
localparam DELAY_REALTEMP_S3 = 5'b1_0011;   //올리고 대기, 로드되면 S4로
localparam DELAY_REALTEMP_S4 = 5'b1_0100;   //LSB 체크, 최초 변환 완료이면 S5, 아니면 S0
localparam DELAY_REALTEMP_S5 = 5'b1_0101;   //30도 넘으면 S12, 아니면 S6
localparam DELAY_REALTEMP_S6 = 5'b1_0110;   //t(T) = -16.8T + 484 -> -16.8 곱하기
localparam DELAY_REALTEMP_S7 = 5'b1_0111;   //t(T) = -16.8T + 484 -> 484 더하기 //카운터 계수 시 == 사용하면 1초가 더 세짐, 원래 485
localparam DELAY_REALTEMP_S8 = 5'b1_1000;   //delayingtime 정수 12비트만 남기기
localparam DELAY_REALTEMP_S9 = 5'b1_1001;   //타이머 시작
localparam DELAY_REALTEMP_S10 = 5'b1_1010;   //올리고 대기, 타이머 다 되면 S11, 아니면 S10 유지, PUSHSW(1) 눌리면 S12으로
localparam DELAY_REALTEMP_S11 = 5'b1_1011;   //타이머 리셋 0
localparam DELAY_REALTEMP_S12 = 5'b1_1100;  //리셋 올리기, 부팅 시작, FAN_CONTROL_S0으로

localparam FAN_CONTROL_S0 = 5'b0_1000;
localparam FAN_CONTROL_S1 = 5'b0_1001;      //타이머 시작
localparam FAN_CONTROL_S2 = 5'b0_1010;      //올리고 대기, CHECKING PERIOD 되면 S2로, 아니면 S1
localparam FAN_CONTROL_S3 = 5'b0_1011;      //온도 로드
localparam FAN_CONTROL_S4 = 5'b0_1100;      //올리고 대기, 로드되면 S4로
localparam FAN_CONTROL_S5 = 5'b0_1101;      //38도 이상이면 팬 켜기, 타이머 리셋 0
localparam FAN_CONTROL_S6 = 5'b0_1110;      //리셋 올리기, S0으로

reg     [4:0]   tempsense_state = RESET_S0;
reg             negtemp_retry = 1'b0;

//flow control
always @(posedge MCLK)
begin
    case(tempsense_state)
        //최초 리셋
        RESET_S0: 
            if(nEN == 1'b0)
            begin
                tempsense_state <= RESET_S1;
            end
            else
            begin
                tempsense_state <= RESET_S0;
            end
        RESET_S1: tempsense_state <= RESET_S2;
        RESET_S2: 
            case(SETTING[1:0])
                2'b00: tempsense_state <= DELAY_FIXED_S0;
                2'b01: tempsense_state <= DELAY_FIXED_S0;
                2'b10: tempsense_state <= DELAY_FIXED_S0;
                2'b11: tempsense_state <= DELAY_REALTEMP_S0;
            endcase

        //고정 딜레이
        DELAY_FIXED_S0: tempsense_state <= DELAY_FIXED_S1;
        DELAY_FIXED_S1: tempsense_state <= DELAY_FIXED_S2;
        DELAY_FIXED_S2:
            if(PUSHSW == 1'b1)
            begin
                tempsense_state <= DELAY_FIXED_S4;
            end
            else if(TC_time >= delay_time[19:8])
            begin
                tempsense_state <= DELAY_FIXED_S3;
            end
            else
            begin
                tempsense_state <= DELAY_FIXED_S2;
            end
        DELAY_FIXED_S3: tempsense_state <= DELAY_FIXED_S4;
        DELAY_FIXED_S4: tempsense_state <= FAN_CONTROL_S0;

        //실제 온도 딜레이
        DELAY_REALTEMP_S0: tempsense_state <= DELAY_REALTEMP_S1;
        DELAY_REALTEMP_S1: 
            if(TC_time > 16'd0) //from 1sec
            begin
                tempsense_state <= DELAY_REALTEMP_S2;
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S1;
            end
        DELAY_REALTEMP_S2: tempsense_state <= DELAY_REALTEMP_S3;
        DELAY_REALTEMP_S3:
            if(TL_completion == 1'b0)
            begin
                tempsense_state <= DELAY_REALTEMP_S4;
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S3;
            end
        DELAY_REALTEMP_S4:
            if(TL_data[0] == 1'b1)
            begin
                if(TL_data[13] == 1'b1) //if temperature is negative
                begin
                    if(negtemp_retry == 1'b0) //retry once
                    begin
                        tempsense_state <= DELAY_REALTEMP_S0;
                    end
                    else
                    begin
                        tempsense_state <= DELAY_REALTEMP_S5;
                    end
                end
                else
                begin
                    tempsense_state <= DELAY_REALTEMP_S5; //temperature conversion completed
                end
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S0;
            end
        DELAY_REALTEMP_S5:
            if(TL_data[13] == 1'b0) //from +27.0 degrees,
            begin
                if(TL_data[12:1] > 12'b0001_1010_1111)
                begin
                    tempsense_state <= DELAY_REALTEMP_S12;
                end
                else
                begin
                    tempsense_state <= DELAY_REALTEMP_S6;
                end
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S6;
            end
        DELAY_REALTEMP_S6: tempsense_state <= DELAY_REALTEMP_S7;
        DELAY_REALTEMP_S7: tempsense_state <= DELAY_REALTEMP_S8;
        DELAY_REALTEMP_S8: tempsense_state <= DELAY_REALTEMP_S9;
        DELAY_REALTEMP_S9: tempsense_state <= DELAY_REALTEMP_S10;
        DELAY_REALTEMP_S10:
            if(PUSHSW == 1'b1)
            begin
                tempsense_state <= DELAY_REALTEMP_S12;
            end
            else if(TC_time > delay_time[23:8])
            begin
                tempsense_state <= DELAY_REALTEMP_S11;
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S10;
            end
        DELAY_REALTEMP_S11: tempsense_state <= DELAY_REALTEMP_S12;
        DELAY_REALTEMP_S12: tempsense_state <= FAN_CONTROL_S0;

        //팬 가동
        FAN_CONTROL_S0: 
            if(SETTING[2] == 1'b1)
            begin
                tempsense_state <= FAN_CONTROL_S1;
            end
            else
            begin
                tempsense_state <= FAN_CONTROL_S0;
            end
        FAN_CONTROL_S1: tempsense_state <= FAN_CONTROL_S2;
        FAN_CONTROL_S2:
            if(TC_time > CHECKING_PERIOD) //1분
            begin
                tempsense_state <= FAN_CONTROL_S3;
            end
            else
            begin
                tempsense_state <= FAN_CONTROL_S2;
            end
        FAN_CONTROL_S3: tempsense_state <= FAN_CONTROL_S4;
        FAN_CONTROL_S4:
            if(TL_completion == 1'b0)
            begin
                tempsense_state <= FAN_CONTROL_S5;
            end
            else
            begin
                tempsense_state <= FAN_CONTROL_S4;
            end
        FAN_CONTROL_S5: tempsense_state <= FAN_CONTROL_S6;
        FAN_CONTROL_S6: tempsense_state <= FAN_CONTROL_S0;
    endcase
end

//IO control
always @(posedge MCLK)
begin
    case(tempsense_state)
        //리셋
        RESET_S0: 
        begin
            nDELAYING <= 1'b0;
            nTEMPLO <= 1'b0;
            fanon_manual_n <= 1'b1; fanon_temphi_n <= 1'b1;
            TC_reset <= 1'b1;
            TC_start <= 1'b1;
            TL_load <= 1'b1;
            nFIFOSENDTEMP <= 1'b1;
        end
        RESET_S1: 
        begin
            
        end
        RESET_S2:
        begin
            
        end

        //고정 시간 딜레이
        DELAY_FIXED_S0:
        begin
            case(SETTING[1:0])
                2'b00: delay_time <= 32'sh000_001_00; //1초
                2'b01: delay_time <= 32'sh000_050_00; //80초
                2'b10: delay_time <= 32'sh000_104_00; //260초
                2'b11: delay_time <= 32'sh000_000_00; //0초(온도감지, 여기 아님)
            endcase
        end
        DELAY_FIXED_S1:
        begin
            TC_start <= 1'b0;
        end
        DELAY_FIXED_S2:
        begin
            TC_start <= 1'b1;
        end
        DELAY_FIXED_S3:
        begin
            TC_reset <= 1'b0;
        end
        DELAY_FIXED_S4:
        begin
            TC_reset <= 1'b1;

            nDELAYING <= 1'b1;
            nTEMPLO <= 1'b1;
        end

        //실제 온도 감지
        DELAY_REALTEMP_S0: 
        begin
            TC_start <= 1'b0;
        end
        DELAY_REALTEMP_S1: 
        begin
            TC_start <= 1'b1;
        end
        DELAY_REALTEMP_S2: 
        begin
            TC_reset <= 1'b0;
            TL_load <= 1'b0;
        end
        DELAY_REALTEMP_S3: 
        begin
            TC_reset <= 1'b1;
            TL_load <= 1'b1;
        end
        DELAY_REALTEMP_S4:
        begin
            
        end
        DELAY_REALTEMP_S5: 
        begin
            if(TL_data[13] == 1'b1) //if temperature is negative
            begin
                negtemp_retry <= 1'b1;
            end
        end
        DELAY_REALTEMP_S6:
        /*
                                0+000_0001_0000.1101 = +16.8
                                1+111_1110_1111.0011 = -16.8 (2s complement)
          X                     S+SSS_TTTT_TTTT.TTTT =  TC77
          __________________________________________
            X+XXX_XXXX_XXXX_XXXX_XXXX_XXXX.XXXX_XXXX
            |--not used---| |-time value-| |not used|
        */
        begin
            delay_time <= $signed({TL_data[13], {{3{TL_data[13]}}, TL_data[12:1]}} ) * $signed({1'b1, 15'b111_1110_1111_0011}); //delay = TC77 airtemp * -16.8
            //                      (-(sign bit)-  -(sign bit ext.)-  --(temp data)-- ) *         -(sb)- -------( -16.8 )-------
        end
        DELAY_REALTEMP_S7:
        begin
            delay_time <= delay_time + 32'sh000_1E4_00; //delay = delay + 484
        end
        DELAY_REALTEMP_S8: 
        begin
            if(delay_time > 32'sh000_FFF_FF)
            begin
                delay_time <= 32'sh000_FFF_00;
            end
            else
            begin
                delay_time <= delay_time & 32'sh000_FFF_00; //leave only 12bit unsigned int
            end
        end
        DELAY_REALTEMP_S9:
        begin
            TC_start <= 1'b0;
            nFIFOSENDTEMP <= 1'b0;

            FIFOTEMP <= TL_data[13:1];
            FIFODLYTIME <= delay_time[19:8];  
        end
        DELAY_REALTEMP_S10:
        begin
            nDELAYING <= 1'b0;
            TC_start <= 1'b1; 
        end
        DELAY_REALTEMP_S11:
        begin
            TC_reset <= 1'b0;
            nFIFOSENDTEMP <= 1'b1;
        end
        DELAY_REALTEMP_S12:
        begin
            TC_reset <= 1'b1;

            nDELAYING <= 1'b1;
            nTEMPLO <= 1'b1;
        end
    
        //팬컨
        FAN_CONTROL_S0:
        begin
            fanon_manual_n <= (PUSHSW == 1'b1) ? 1'b0 : 1'b1;
        end
        FAN_CONTROL_S1:
        begin
            TC_start <= 1'b0;

            fanon_manual_n <= (PUSHSW == 1'b1) ? 1'b0 : 1'b1;
        end
        FAN_CONTROL_S2:
        begin
            TC_start <= 1'b1;

            fanon_manual_n <= (PUSHSW == 1'b1) ? 1'b0 : 1'b1;
        end
        FAN_CONTROL_S3:
        begin
            TL_load <= 1'b0;
        end
        FAN_CONTROL_S4:
        begin
            TL_load <= 1'b1;
        end
        FAN_CONTROL_S5:
        begin
            if(TL_data[13] == 1'b0 && TL_data[12:1] > 12'b0010_0110_0000) //temperature over +38 degrees,
            begin
                fanon_temphi_n <= 1'b0;
            end
            else
            begin
                fanon_temphi_n <= 1'b1;
            end

            TC_reset <= 1'b0;
        end
        FAN_CONTROL_S6:
        begin
            TC_reset <= 1'b1;
        end
    endcase
end

endmodule