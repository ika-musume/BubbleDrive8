module BubbleDrive8_usb
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //FIFO/MPSSE mode select
    input   wire            nEN,
    input   wire            nMPSSESTBY, //(0=MPSSE 1=FIFO)

    //Emulator signal outputs
    input   wire    [2:0]   ACCTYPE,        //access type

    //FIFO buffer interface
    input   wire            nFIFOEN = 1'b1,
    input   wire            nFIFOBUFWRCLKEN = 1'b1,
    input   wire    [12:0]  FIFOBUFWRADDR = 13'd0,   //13bit addr = 8k * 1bit
    input   wire            FIFOBUFWRDATA = 1'b1,

    //MPSSE input/output
    input   wire            nMPSSEON,
    output  wire            MPSSECLK,
    output  wire            MPSSEMOSI,
    input   wire            MPSSEMISO,
    output  wire            nMPSSECS,

    //FT232HL
    inout   wire    [7:0]   ADBUS,
    inout   wire    [4:0]   ACBUS
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
    case({nMPSSESTBY, nMPSSEON})
        2'b00: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b0; end //stable MPSSE
        2'b01: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b1; end //standby(FIFO, MPSSE is not reconfigured by a host PC)
        2'b10: begin fifo_output_driver_enable <= nEN | 1'b1; mpsse_connection_enable <= nEN | 1'b1; end //illegal access(enabling MPSSE while FIFO accessing)
        2'b11: begin fifo_output_driver_enable <= nEN | 1'b0; mpsse_connection_enable <= nEN | 1'b1; end //stable FIFO
    endcase
end

//declare fifo variables
wire    [7:0]   FIFO_OUTLATCH,  //ADBUS0-7
wire            nFIFORXF,       //ACBUS0
wire            nFIFOTXE,       //ACBUS1
reg             nFIFORD,        //ACBUS2
reg             nFIFOWR,        //ACBUS3
reg             nFIFOSIWU       //ACBUS4
wire            nMPSSEON        //ACBUS5

//MPSSE input / output driver
assign MPSSECLK = (mpsse_connection_enable == 1'b0) ? ADBUS[0] : 1'b0; //prevent unintended access
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

SIPOBuffer SIPOBuffer_0
(
    .MCLK               (MCLK               ),

    .SIPOWRADDR         (FIFOBUFWRADDR      ),
    .SIPODIN            (FIFOBUFWRDATA      ),
    .nSIPOWRCLKEN       (nFIFOBUFWRCLKEN    ),

    .SIPORDADDR         (                   ),
    .SIPODOUT           (                   ),
    .nSIPORDCLKEN       (                   )
)


endmodule