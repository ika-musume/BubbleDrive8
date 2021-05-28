module BubbleDrive8_tempsense
/*

*/

(
    //input clock
    input   wire            MCLK,

    //startup delay set switch
    input   wire    [2:0]   TEMPSW, //[FAN/DELAY1/DELAY0]

    //force start
    input   wire            FORCESTART,

    //status
    output  wire            nTEMPLO,
    output  wire            nFANEN,

    //TC77
    output  wire            nTEMPCS,
    inout   wire            TEMPSIO,
    output  wire            TEMPCLK
);

localparam      CHECKING_PERIOD = 16'd60;

reg     [2:0]   dip_switch_settings = 3'b000;
reg     [31:0]  delaying_time = 32'd0;

reg             heated = 1'b0;
reg             fan_on = 1'b0;
assign  nTEMPLO = heated | FORCESTART;
assign  nFANEN  = ~fan_on;


reg     [15:0]  TC_time;
reg             TC_reset;
reg             TC_start;
reg             TC_overflow;

reg     [13:0]  TL_data;
reg             TL_completion;
reg             TL_load;

TimeCounter TimeCounter_0
(
    .MCLK           (MCLK           ),
    
    .TIMEELAPSED    (TC_time        ),
    
    .nRESET         (TC_reset       ),
    .nSTART         (TC_start       ),
    .OVFL           (TC_overflow    )
);

TempLoader TempLoader_0
(
    .MCLK           (MCLK           ),

    .TEMPDATA       (TL_data        ),

    .nLOAD          (TL_load        ),
    .nCOMPLETE      (TL_completion  ),

    .CS             (nTEMPCS        ),
    .SIO            (TEMPSIO        ),
    .CLK            (TEMPCLK        )
);


localparam RESET_S0 = 5'b0_1000;
localparam RESET_S1 = 5'b0_1001;            //딥스위치 데이터 래치
localparam RESET_S2 = 5'b0_1010;            //branch

localparam DELAY_FIXED_S0 = 5'b1_0000;      //여름(00) = 5초, 봄가을(01) = 80초, 겨울(10) = 260초 delaying_time에 로드
localparam DELAY_FIXED_S1 = 5'b1_0001;      //타이머 시작
localparam DELAY_FIXED_S2 = 5'b1_0010;      //올리고 대기, 타이머 다 되면 S3으로, 아니면 S2
localparam DELAY_FIXED_S3 = 5'b1_0011;      //타이머 리셋 0
localparam DELAY_FIXED_S4 = 5'b1_0100;      //리셋 올리기, 부팅 시작, FAN_CONTROL_S0으로

localparam DELAY_REALTEMP_S0 = 5'b0_0000;   //실제 온도(11), 온도 로드
localparam DELAY_REALTEMP_S1 = 5'b0_0001;   //올리고 대기, 로드되면 S2로
localparam DELAY_REALTEMP_S2 = 5'b0_0010;   //LSB 체크, 최초 변환 완료이면 S3, 아니면 S0
localparam DELAY_REALTEMP_S3 = 5'b0_0011;   //26.5도 넘으면 S8, 아니면 S4
localparam DELAY_REALTEMP_S4 = 5'b0_0100;   //t(T) = -16.8T + 485 -> -16.8 곱하기
localparam DELAY_REALTEMP_S5 = 5'b0_0101;   //t(T) = -16.8T + 485 -> 485 더하기
localparam DELAY_REALTEMP_S6 = 5'b0_0110;   //타이머 시작
localparam DELAY_REALTEMP_S7 = 5'b0_0111;   //올리고 대기, 타이머 다 되면 S8, 아니면 S7 유지
localparam DELAY_REALTEMP_S8 = 5'b1_1000;   //타이머 리셋 0
localparam DELAY_REALTEMP_S9 = 5'b0_1001;   //리셋 올리기, 부팅 시작, FAN_CONTROL_S0으로

localparam FAN_CONTROL_S0 = 5'b1_0100;      //타이머 시작
localparam FAN_CONTROL_S1 = 5'b1_0101;      //올리고 대기, CHECKING PERIOD 되면 S2로, 아니면 S1
localparam FAN_CONTROL_S2 = 5'b1_0110;      //온도 로드
localparam FAN_CONTROL_S3 = 5'b1_0111;      //올리고 대기, 로드되면 S4로
localparam FAN_CONTROL_S4 = 5'b1_1000;      //35도 이상이면 팬 켜기, 타이머 리셋 0
localparam FAM_CONTROL_S5 = 5'b1_1001;      //리셋 올리기, S0으로

reg     [4:0]   tempsense_state = RESET_S0;

always @(posedge MCLK)
begin
    case(tempsense_state)
        //최초 리셋
        RESET_S0: tempsense_state <= RESET_S1;
        RESET_S1: tempsense_state <= RESET_S2;
        RESET_S2: 
            case(dip_switch_settings)
                2'b00: tempsense_state <= DELAY_FIXED_S0;
                2'b01: tempsense_state <= DELAY_FIXED_S0;
                2'b10: tempsense_state <= DELAY_FIXED_S0;
                2'b11: tempsense_state <= DELAY_REALTEMP_S0;
            endcase

        //고정 딜레이
        DELAY_FIXED_S0: tempsense_state <= DELAY_FIXED_S1;
        DELAY_FIXED_S1: tempsense_state <= DELAY_FIXED_S2;
        DELAY_FIXED_S2:
            if(TC_time == delaying_time[23:8])
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
            if(TL_completion == 1'b0)
            begin
                tempsense_state <= DELAY_REALTEMP_S2;
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S1;
            end
        DELAY_REALTEMP_S2:
            if(TL_data[0] == 1'b1)
            begin
                tempsense_state <= DELAY_REALTEMP_S3; //temperature conversion completed
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S0;
            end
        DELAY_REALTEMP_S3:
            if(TL_data[13] == 1'b0 && TL_data[12:1] > 12'b0001_1010_1000) //temperature over +26.5 degrees,
            begin
                tempsense_state <= DELAY_REALTEMP_S8
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S4
            end
        DELAY_REALTEMP_S4: tempsense_state <= DELAY_REALTEMP_S5;
        DELAY_REALTEMP_S5: tempsense_state <= DELAY_REALTEMP_S6;
        DELAY_REALTEMP_S6: tempsense_state <= DELAY_REALTEMP_S7;
        DELAY_REALTEMP_S7:
            if(TC_time == delaying_time[23:8])
            begin
                tempsense_state <= DELAY_REALTEMP_S8;
            end
            else
            begin
                tempsense_state <= DELAY_REALTEMP_S7;
            end
        DELAY_REALTEMP_S8: tempsense_state <= DELAY_REALTEMP_S9;
        DELAY_REALTEMP_S9: tempsense_state <= FAN_CONTROL_S0;

        //팬 가동
        FAN_CONTROL_S0: tempsense_state <= FAN_CONTROL_S1;
        FAN_CONTROL_S1:
            if(TC_time == CHECKING_PERIOD) //1분
            begin
                tempsense_state <= FAN_CONTROL_S2;
            end
            else
            begin
                tempsense_state <= FAN_CONTROL_S1;
            end
        FAN_CONTROL_S2: tempsense_state <= FAN_CONTROL_S3;
        FAN_CONTROL_S3:
            if(TL_completion == 1'b0)
            begin
                tempsense_state <= FAN_CONTROL_S4;
            end
            else
            begin
                tempsense_state <= FAN_CONTROL_S3;
            end
        FAN_CONTROL_S4: tempsense_state <= FAN_CONTROL_S5;
        FAN_CONTROL_S5: tempsense_state <= FAN_CONTROL_S0;
    endcase
end



always @(posedge MCLK)
begin
    case(tempsense_state)
        //리셋
        RESET_S0: 
        begin
            heated <= 1'b0;
            fan_on <= 1'b0; 
            TC_reset <= 1'b1;
            TC_start <= 1'b1;
            TL_load <= 1'b1;
        end
        RESET_S1: 
        begin
            dip_switch_settings <= TEMPSW;
        end
        RESET_S2:
        begin
            
        end

        //고정 시간 딜레이
        DELAY_FIXED_S0:
        begin
            case(dip_switch_settings[1:0])
                2'b00: delaying_time <= 32'b0000_0000_0000_0000_0000_0101_0000_0000; //5초
                2'b01: delaying_time <= 32'b0000_0000_0000_0000_0110_0000_0000_0000; //80초
                2'b10: delaying_time <= 32'b0000_0000_0000_0001_0000_0100_0000_0000; //260초
                2'b11: delaying_time <= 32'b0000_0000_0000_0000_0000_0000_0000_0000; //0초(온도감지, 여기 아님)
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
            heated <= 1'b1;
        end

        //실제 온도 감지
        DELAY_REALTEMP_S0: 
        begin
            TL_load <= 1'b0;
        end
        DELAY_REALTEMP_S1: 
        begin
            TL_load <= 1'b1;
        end
        DELAY_REALTEMP_S2:
        begin
            
        end
        DELAY_REALTEMP_S3: 
        begin
        
        end
        DELAY_REALTEMP_S4:
        /*
                                0+000_0001_0000.1101 = +16.8
                                1+111_1110_1111.0011 = -16.8 (2s complement)
          X                     S+SSS_TTTT_TTTT.TTTT =  TC77
          __________________________________________
            X+XXX_XXXX_XXXX_XXXX_XXXX_XXXX.XXXX_XXXX
        */
        begin
            delaying_time <= {4{TL_data[13]}, TL_data[12:1]} * 16'b1111_1110_1111_0100; //delay = TC77 airtemp * -16.8
        end
        DELAY_REALTEMP_S5: 
        begin
            delaying_time <= delaying_time + 32'b0000_0000_0000_0001_1110_0101_0000_0000; //delay = delay + 485
        end
        DELAY_REALTEMP_S6:
        begin
            TC_start <= 1'b0;
        end
        DELAY_REALTEMP_S7:
        begin
            TC_start <= 1'b1;
        end
        DELAY_REALTEMP_S8:
        begin
            TC_reset <= 1'b0;
        end
        DELAY_REALTEMP_S9:
        begin
            TC_reset <= 1'b1;
            heated <= 1'b1;
        end
    
        //팬컨
        FAN_CONTROL_S0:
        begin
            TC_start <= 1'b0;
        end
        FAN_CONTROL_S1:
        begin
            TC_start <= 1'b1;
        end
        FAN_CONTROL_S2:
        begin
            TL_load <= 1'b0;
        end
        FAN_CONTROL_S3:
        begin
            
        end
        FAN_CONTROL_S4:
        begin
            if(TL_data[13] == 1'b0 && TL_data[12:1] > 12'b0010_0000_0000) //temperature over +32 degrees,
            begin
                fan_on <= 1'b1;
            end
            else
            begin
                fan_on <= 1'b0;
            end

            TC_reset <= 1'b0;
        end
        FAN_CONTROL_S5:
        begin
            TC_reset <= 1'b1;
        end
    endcase
end

endmodule