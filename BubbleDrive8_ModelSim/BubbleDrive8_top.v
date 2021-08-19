module BubbleDrive8_top
(
    /////////////////////////////////////////////
    //// EMULATOR CORE

    //48MHz input clock
    input   wire            MCLK,

    //4MHz output clock
    output  wire            CLKOUT,

    //Bubble control signal inputs
    input   wire            nBSS,
    input   wire            nBSEN,
    input   wire            nREPEN,
    input   wire            nBOOTEN,
    input   wire            nSWAPEN,

    //Bubble data outputs
    output  wire            DOUT0,
    output  wire            DOUT1,
    output  wire            DOUT2,
    output  wire            DOUT3,

    //PCB power status input
    input   wire            MRST,

    //control inputs
    input   wire    [2:0]   IMGNUM,

    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMCLK,
    inout   wire            ROMIO0,
    input   wire            ROMIO1,
    input   wire            ROMIO2,
    input   wire            ROMIO3,


    /////////////////////////////////////////////
    //// TEMPERATURE DETECTOR CORE

    //control inputs
    input   wire    [2:0]   TEMPSW,
    input   wire            FORCESTART,

    //TC77
    output  wire            nTEMPCS,
    output  wire            TEMPCLK,
    inout   wire            TEMPSIO,

    //status signals
    output  wire            nTEMPLO,
    output  wire            nFANEN,


    /////////////////////////////////////////////
    //// FT232 CORE

    //power MUX status
    input   wire            PWRSTAT, //0 = motherboard / 1 = USB
    inout   wire    [7:0]   ADBUS,
    inout   wire    [5:0]   ACBUS,


    /////////////////////////////////////////////
    //// LEDS
    output  wire            nLED_ACC,
    output  wire            nLED_DELAYING,
    output  wire            nLED_STANDBY,
    output  wire            nLED_PWROK
);

reg             BITWIDTH4 = 1'b0;

reg             emucore_en = 1'b1;
reg             tempsense_en = 1'b1;
reg             usb_en = 1'b1;

wire            led_delaying;

wire            nFIFOBUFWRCLKEN;
wire    [12:0]  FIFOBUFWRADDR;
wire            FIFOBUFWRDATA;
wire            nFIFOSENDBOOT;
wire            nFIFOSENDUSER;
wire    [11:0]  FIFORELPAGE;

BubbleDrive8_emucore BubbleDrive8_emucore_0
(
    .MCLK           (MCLK           ),
    .nEN            (emucore_en     ),
    .IMGNUM         (IMGNUM         ),
    .BITWIDTH4      (BITWIDTH4      ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (nBSS           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (nSWAPEN        ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          ),
    .DOUT2          (DOUT2          ),
    .DOUT3          (DOUT3          ),

    .nROMCS         (nROMCS         ),
    .ROMCLK         (ROMCLK         ),
    .ROMIO0         (ROMIO0         ),
    .ROMIO1         (ROMIO1         ),
    .ROMIO2         (ROMIO2         ),
    .ROMIO3         (ROMIO3         ),

    .nFIFOBUFWRCLKEN(nFIFOBUFWRCLKEN),
    .FIFOBUFWRADDR  (FIFOBUFWRADDR  ),
    .FIFOBUFWRDATA  (FIFOBUFWRDATA  ),
    .nFIFOSENDBOOT  (nFIFOSENDBOOT  ),
    .nFIFOSENDUSER  (nFIFOSENDUSER  ),
    .FIFORELPAGE    (FIFORELPAGE    ),

    .nACC           (nLED_ACC       )
);

BubbleDrive8_tempsense BubbleDrive8_tempsense_0
(
    .MCLK           (MCLK           ),

    .TEMPSW         (TEMPSW         ),
    .nEN            (tempsense_en   ),

    .FORCESTART     (FORCESTART     ),

    .nTEMPLO        (nTEMPLO        ),
    .nFANEN         (nFANEN         ),
    .nDELAYING      (led_delaying   ),

    .nTEMPCS        (nTEMPCS        ),
    .TEMPSIO        (TEMPSIO        ),
    .TEMPCLK        (TEMPCLK        )
);

BubbleDrive8_usb BubbleDrive8_usb_0
(
    .MCLK           (MCLK           ),

    .PWRSTAT        (PWRSTAT        ),
    .nEN            (usb_en         ),

    .BITWIDTH4      (BITWIDTH4      ),

    .nFIFOBUFWRCLKEN(nFIFOBUFWRCLKEN),
    .FIFOBUFWRADDR  (FIFOBUFWRADDR  ),
    .FIFOBUFWRDATA  (FIFOBUFWRDATA  ),
    .nFIFOSENDBOOT  (nFIFOSENDBOOT  ),
    .nFIFOSENDUSER  (nFIFOSENDUSER  ),
    .FIFORELPAGE    (FIFORELPAGE    ),

    .MPSSECLK       (               ),
    .MPSSEMOSI      (               ),
    .MPSSEMISO      (               ),
    .nMPSSECS       (               ),

    .ADBUS          (ADBUS          ),
    .ACBUS          (ACBUS          )
);







/*
    BLINKER
*/
localparam CLOCK = 48'd8192; //00000;
localparam RESET = 1'b0;
localparam RUN = 1'b1;

reg             blinker_state = RESET;
reg             blinker_start = 1'b1;
reg             blinker_stop = 1'b1;
reg             blinker = 1'b1;

always @(posedge MCLK)
begin
    case(blinker_state)
        RESET:
        begin
            if(blinker_start == 1'b0)
            begin
                blinker_state <= RUN;
            end
        end
        RUN:
        begin
            if(blinker_stop == 1'b0)
            begin
                blinker_state <= RESET;
            end
        end
    endcase
end

//counter
reg     [47:0]  clock_counter = 48'd0;

always @(posedge MCLK)
begin
    case(blinker_state)
        RESET:
        begin
            blinker <= 1'b1;
            clock_counter <= 18'd0;
        end
        RUN:
        begin
            if(clock_counter < CLOCK)
            begin
                clock_counter <= clock_counter + 48'd1;
            end
            else
            begin
                blinker <= ~blinker;
                clock_counter <= 48'd0;
            end
        end
    endcase
end



/*
    STARTUP CONTROL
*/

//declare states
localparam RESET_S0 = 3'b000;           //최초 리셋

localparam MODE_SELECT_S0 = 3'b001;     //에뮬/MPSSE 선택

localparam EMULATOR_S0 = 3'b010;        //4비트 모드 체크
localparam EMULATOR_S1 = 3'b011;        //버블 모듈 enable, FIFO enable, MPSSE disable

localparam MPSSE_STANDBY_S0 = 3'b101;   //버블 모듈 diasble, FIFO disable, MPSSE enable하면서 대기, 버블쪽 파워가 들어올 경우 에뮬레이터 모드로

localparam ERROR_S0 = 3'b110;           //FPGA는 켜졌으나 기판 MRST가 1일때(-12V 등 불량)
localparam ERROR_S1 = 3'b111;           //전원공급은 USB이나 기판 MRST가 0일때(애매한 상태)

//emulator state
reg     [2:0]   emulator_state = RESET_S0;
reg             ledctrl_delaying = 1'b1;
reg             ledctrl_pwrok = 1'b1;
reg             ledctrl_standby = 1'b1;

assign nLED_DELAYING = ledctrl_delaying | led_delaying;
assign nLED_PWROK = ledctrl_pwrok & blinker;
assign nLED_STANDBY = (ledctrl_standby | blinker) & ~led_delaying;

//state flow control
always @(posedge MCLK)
begin
    case(emulator_state)
        RESET_S0: emulator_state <= MODE_SELECT_S0;

        MODE_SELECT_S0: 
            case({PWRSTAT, MRST})
                2'b00: emulator_state <= EMULATOR_S1;
                2'b01: emulator_state <= ERROR_S0;
                2'b10: emulator_state <= ERROR_S1;
                2'b11: emulator_state <= MPSSE_STANDBY_S0;
            endcase

        EMULATOR_S0: emulator_state <= EMULATOR_S1;
        EMULATOR_S1: emulator_state <= EMULATOR_S1;

        MPSSE_STANDBY_S0:
            if({PWRSTAT, MRST} == 2'b00)
            begin
                emulator_state <= RESET_S0;
            end
            else
            begin
                emulator_state <= MPSSE_STANDBY_S0;
            end

        ERROR_S0:
            if(MRST == 1'b1)
            begin
                emulator_state <= ERROR_S0;
            end
            else
            begin
                emulator_state <= RESET_S0;
            end
        ERROR_S1:
            if({PWRSTAT, MRST} == 2'b11)
            begin
                emulator_state <= ERROR_S1;
            end
            else
            begin
                emulator_state <= RESET_S0;
            end
    endcase
end

//output control
always @(posedge MCLK)
begin
    case(emulator_state)
        RESET_S0: 
        begin
            emucore_en <= 1'b1;
            tempsense_en <= 1'b1;
            usb_en <= 1'b1;

            ledctrl_delaying <= 1'b1;
            ledctrl_pwrok <= 1'b1;
            ledctrl_standby <= 1'b1;

            blinker_stop <= 1'b0;
            blinker_start <= 1'b1;
        end

        MODE_SELECT_S0:
        begin 
        end

        EMULATOR_S0:
        begin
        end
        EMULATOR_S1:
        begin
            emucore_en <= 1'b0;
            tempsense_en <= 1'b0;
            usb_en <= 1'b0;

            ledctrl_delaying <= 1'b0;
            ledctrl_pwrok <= 1'b0;
            ledctrl_standby <= 1'b1;
        end

        MPSSE_STANDBY_S0:
        begin
            usb_en <= 1'b0;

            ledctrl_delaying <= 1'b1;
            ledctrl_pwrok <= 1'b1;
            ledctrl_standby <= 1'b0;

            blinker_stop <= 1'b1;
            blinker_start <= 1'b0;
        end

        ERROR_S0:
        begin
            ledctrl_delaying <= 1'b1;
            ledctrl_pwrok <= 1'b1;
            ledctrl_standby <= 1'b1;

            blinker_stop <= 1'b1;
            blinker_start <= 1'b0;
        end
        ERROR_S1:
        begin
            ledctrl_delaying <= 1'b1;
            ledctrl_pwrok <= 1'b1;
            ledctrl_standby <= 1'b1;
            
            ledctrl_pwrok <= 1'b1;
            blinker_stop <= 1'b1;
            blinker_start <= 1'b0;
        end

        default: begin end
    endcase    
end

endmodule