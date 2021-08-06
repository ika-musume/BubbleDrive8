module BubbleDrive8_usb
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //FIFO/MPSSE mode select
    input   wire            nEN,
    input   wire            PWRSTAT, //(0 = FIFO 1 = MPSSE)

    //FIFO buffer interface
    input   wire            nFIFOEN,
    input   wire            nFIFOBUFWRCLKEN,
    input   wire    [12:0]  FIFOBUFWRADDR,   //13bit addr = 8k * 1bit
    input   wire            FIFOBUFWRDATA,
    input   wire            nFIFOSENDBOOT,
    input   wire            nFIFOSENDUSER,
    input   wire    [11:0]  FIFOCURRPAGE,

    //MPSSE input/output
    input   wire            nMPSSEON,
    output  wire            MPSSECLK,
    output  wire            MPSSEMOSI,
    input   wire            MPSSEMISO,
    output  wire            nMPSSECS,

    //FT232HL
    inout   wire    [7:0]   ADBUS,
    inout   wire    [5:0]   ACBUS
);



/*
    FIFO / MPSSE MUX
*/

/*
       MODE----------------+
                           |
    +-------------+    +---v---+              +--------+
    |             |    |       |              |        |
    |   W25Q32    |    |       |              |        |
    |  Flash ROM  |<-->|MPSSE  |     ADBUS    |        |
    |             |    |       |<------------>|        |
    +-------------+    |       |              |        |
                       |  BUS  |              |        |
                       |       |     ACBUS    | FT232H |<------->PC
                       |  MUX  |<------------>|        |
    +-------------+    |       <--------------|        |
    |             |    |       |   /MPSSEEN   |        |
    |  FIFO DATA  |--->|FIFO   |              |        |
    | transmitter |    |       |              |        |
    |             |    |       |              |        |
    +-------------+    +-------+              +--------+
*/

//enable signals(active low)
reg             fifo_output_driver_enable = 1'b1;
reg             mpsse_connection_enable = 1'b1;

//controls input / output driver
always @(*)
begin
    case({PWRSTAT, nMPSSEON})
        2'b00: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b1; end //illegal access(enabling MPSSE while FIFO accessing)
        2'b01: begin fifo_output_driver_enable <= nEN | 1'b0; mpsse_connection_enable <= nEN | 1'b1; end //stable FIFO
        2'b10: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b0; end //stable MPSSE
        2'b11: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b1; end //standby(FIFO, MPSSE is not reconfigured by a host PC)
    endcase
end

//declare fifo variables
wire    [7:0]   FIFO_OUTLATCH;  //ADBUS0-7
wire            nFIFORXF;       //ACBUS0
wire            nFIFOTXE;       //ACBUS1
reg             nFIFORD;        //ACBUS2
reg             nFIFOWR;        //ACBUS3
reg             nFIFOSIWU;      //ACBUS4

//MPSSE input / output driver
assign MPSSECLK = (mpsse_connection_enable == 1'b0) ? ADBUS[0] : 1'b1; //prevent unintended access
assign MPSSEMOSI = (mpsse_connection_enable == 1'b0) ? ADBUS[1] : 1'b0;
assign ADBUS[2] = (mpsse_connection_enable == 1'b0) ? MPSSEMISO : 1'bZ;
assign nMPSSECS = (mpsse_connection_enable == 1'b0) ? ADBUS[3] : 1'b1;

//FIFO input / output driver
assign ADBUS = (fifo_output_driver_enable == 1'b0) ? FIFO_OUTLATCH : 8'bZZZZ_ZZZZ;
assign nFIFORXF = ACBUS[0];
assign nFIFOTXE = ACBUS[1];
assign ACBUS[2] = (fifo_output_driver_enable == 1'b0) ? nFIFORD : 1'b1; //set pull-up resistor on the pin
assign ACBUS[3] = (fifo_output_driver_enable == 1'b0) ? nFIFOWR : 1'b1;
assign ACBUS[4] = (fifo_output_driver_enable == 1'b0) ? nFIFOSIWU : 1'b1;
assign nMPSSEON = ACBUS[5];




/*
    SIPO Buffer for serial to parallel conversion
*/

reg     [9:0]   FIFOBUFRDADDR = 10'd0;
wire    [7:0]   FIFOBUFRDDATA;
reg             nFIFOBUFRDCLKEN = 1'b1;

SIPOBuffer SIPOBuffer_0
(
    .MCLK               (MCLK               ),

    .nSIPOWREN          (nFIFOEN            ),
    .SIPOWRADDR         (FIFOBUFWRADDR      ),
    .SIPOWRDATA         (FIFOBUFWRDATA      ),
    .nSIPOWRCLKEN       (nFIFOBUFWRCLKEN    ),

    .SIPORDADDR         (FIFOBUFRDADDR      ),
    .SIPORDDATA         (FIFOBUFRDDATA      ),
    .nSIPORDCLKEN       (nFIFOBUFRDCLKEN    )
);



/*
    FIFO ASCII message memory
*/
reg             convert = 1'b0;
reg     [6:0]   text_addr = 7'h0;
wire    [7:0]   text_output;

MSGROM MSGROM_0
(
    .MCLK               (MCLK               ),
    .nCLKEN             (convert            ),
    .ADDR               (text_addr          ),
    .DATA               (text_output        )
);



/*
    FIFO transmitter
*/

reg     [23:0]  ascii_page_number = 24'h0;

reg     [11:0]  loop_counter = 12'd0;

//declare states
localparam FIFO_IDLE = 8'b0000_0001;
localparam FIFO_RESET = 8'b0000_0000;
localparam FIFO_TITLE_S0 = 8'b0001_0000;    //루프 횟수 set, 스트링 시작 어드레스 set
localparam FIFO_TITLE_S1 = 8'b0001_0001;    //루프 카운터가 다 차면 FIFO_BOOT_2B_S0으로 가기, TXE가 LO인지 체크해서 LO이면 S2, 아니면 S1
localparam FIFO_TITLE_S2 = 8'b0001_0010;    //메시지 롬 read = 0
localparam FIFO_TITLE_S3 = 8'b0001_0011;    //메시지 롬 read = 1, 메시지 가져다가 FIFO 출력에 넣기
localparam FIFO_TITLE_S4 = 8'b0001_0100;    //FIFO WR = 0
localparam FIFO_TITLE_S5 = 8'b0001_0101;    //nop
localparam FIFO_TITLE_S6 = 8'b0001_0110;    //FIFO WR = 1, 어드레스 증가, 루프 카운터 증가, S1로 되돌아가기




endmodule