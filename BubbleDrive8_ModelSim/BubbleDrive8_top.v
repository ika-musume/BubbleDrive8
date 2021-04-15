module BubbleDrive8_top
(
    //48MHz input clock
    input   wire            MCLK,

    //input control
    input   wire    [2:0]   IMGNUM,

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

    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMMOSI,
    input   wire            ROMMISO,
    output  wire            ROMCLK,
    output  wire            nWP,
    output  wire            nHOLD,

    //ADT7311
    //output  wire            nTEMPCS,
    //output  wire            nTEMPMOSI,
    //input   wire            nTEMPMISO,
    //output  wire            TEMPCLK,

    //LED
    output  wire            nACCLED,
    output  wire            nWAITLED,
    output  wire            nREADLED,
    output  wire            nWRITELED,

    output  wire    [7:0]   nFND, //a b c d e f g dp
    output  wire    [2:0]   nANODE
);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;

//TimingGenerator
wire    [2:0]   ACCTYPE;
wire    [12:0]  BOUTCYCLENUM;
wire    [1:0]   BOUTTICKS;

wire    [11:0]  ABSPOS;

//SPILoader -> BubbleInterface
wire            nOUTBUFWCLKEN;
wire    [14:0]  OUTBUFWADDR;
wire            OUTBUFWDATA;

//LEDDriver
wire    [11:0]  CURRPAGE;



TimingGenerator TimingGenerator_0
(
    .MCLK           (MCLK           ),

    .nINCTRL        (1'b0           ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (nBSS           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (nSWAPEN        ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .BOUTTICKS      (BOUTTICKS      ),
    .ABSPOS         (ABSPOS         )
);



BubbleInterface BubbleInterface_0
(
    .MCLK           (MCLK           ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .BOUTTICKS      (BOUTTICKS      ),

    .nOUTBUFWCLKEN  (nOUTBUFWCLKEN  ),
    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          )
);



SPILoader SPILoader_0
(
    .MCLK           (MCLK           ),

    .IMGNUM         (IMGNUM         ),

    .ACCTYPE        (ACCTYPE        ),
    .ABSPOS         (ABSPOS         ),
    .CURRPAGE       (CURRPAGE       ),

    .nOUTBUFWCLKEN  (nOUTBUFWCLKEN  ),
    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .nCS            (nROMCS         ),
    .MOSI           (ROMMOSI        ),
    .MISO           (ROMMISO        ),
    .CLK            (ROMCLK         )
);



LEDDriver LEDDriver_0
(
    .MCLK           (MCLK           ),

    .nWAIT          (nBOOTEN        ),
    .ACCTYPE        (ACCTYPE        ),
    .CURRPAGE       (CURRPAGE       ),

    .nACCLED        (nACCLED        ),
    .nWAITLED       (nWAITLED       ),
    .nREADLED       (nREADLED       ),
    .nWRITELED      (nWAITLED       ),

    .nFND           (nFND           ),
    .nANODE         (nANODE         )
);

endmodule