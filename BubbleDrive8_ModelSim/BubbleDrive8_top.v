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
    //output  wire            DOUT2,
    //output  wire            DOUT3,

    //control inputs
    input   wire    [2:0]   IMGNUM,

    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMMOSI,
    input   wire            ROMMISO,
    output  wire            ROMCLK,
    output  wire            nWP,
    output  wire            nHOLD,


    /////////////////////////////////////////////
    //// TEMPERATURE DETECTOR CORE

    //control inputs
    input   wire    [2:0]   TEMPSW,
    input   wire            FORCEBOOT,

    //TC77
    output  wire            nTEMPCS,
    output  wire            TEMPCLK,
    inout   wire            TEMPSIO,

    //status signals
    output  wire            nTEMPLO,
    output  wire            nFANEN,


    input wire nSYSOK, // test


    /////////////////////////////////////////////
    //// LEDS
    output  wire            nLED_ACC,
    output  wire            nLED_DELAYING    
);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;
//assign nFANEN = 1'b1;




BubbleDrive8_emucore BubbleDrive8_emucore_0
(
    .MCLK           (MCLK           ),

    .IMGNUM         (IMGNUM         ),
    .nSYSOK         (nSYSOK         ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (nBSS           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (nSWAPEN        ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          ),
    .DOUT2          (               ),
    .DOUT3          (               ),

    .nROMCS         (nROMCS         ),
    .ROMMOSI        (ROMMOSI        ),
    .ROMMISO        (ROMMISO        ),
    .ROMCLK         (ROMCLK         ),

    .nACC           (nLED_ACC       )
);

BubbleDrive8_tempsense BubbleDrive8_tempsense_0
(
    .MCLK           (MCLK           ),

    .TEMPSW         (3'b111         ),
    .nSYSOK         (nSYSOK         ),

    .FORCESTART     (1'b0           ),

    .nTEMPLO        (nTEMPLO        ),
    .nFANEN         (nFANEN         ),
    .nDELAYING      (nLED_DELAYING  ),

    .nTEMPCS        (nTEMPCS        ),
    .TEMPSIO        (TEMPSIO        ),
    .TEMPCLK        (TEMPCLK        )
);

endmodule