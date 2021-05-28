module BubbleDrive8_top
(
    /////////////////////////////////////////////
    ////MASTER CLOCK
    //48MHz input clock
    input   wire            MCLK,


    /////////////////////////////////////////////
    ////SWITCHES
    //image number
    input   wire    [2:0]   IMGNUM,


    /////////////////////////////////////////////
    ////BUBBLE I/O
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

    //Peripheral
    output  wire            READY,  


    /////////////////////////////////////////////
    ////BUBBLE IMAGE SPI FLASH
    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMMOSI,
    input   wire            ROMMISO,
    output  wire            ROMCLK,
    output  wire            nROMWP,
    output  wire            nROMHOLD,


    /////////////////////////////////////////////
    ////TEMPERATURE SENSOR
    //TC77
    //output  wire            nTEMPCS,
    //output  wire            nTEMPSIO,
    //output  wire            TEMPSCLK,
    
    
    /////////////////////////////////////////////
    ////LED
    //LED
    output  wire            BUBBLE_ACC,
    output  wire            STANDBY,
    output  wire            STARTUP_DELAYING,
    output  wire            MODE,
    output  wire            POWER_OK
);

assign READY = 1'b1;


BubbleDrive8_emucore Main
(
    .MCLK           (MCLK           ),

    .IMGNUM         (IMGNUM         ),
    .nINCTRL        (1'b0           ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (1'b1           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (1'b1           ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          ),
    .DOUT2          (DOUT2          ),
    .DOUT3          (DOUT3          ),

    .nROMCS         (nROMCS         ),
    .ROMMOSI        (ROMMOSI        ),
    .ROMMISO        (ROMMISO        ),
    .ROMCLK         (ROMCLK         ),

    .nACCLED        (nACCLED        )
);

assign nROMWP = 1'bZ;
assign nROMHOLD = 1'bZ;



endmodule