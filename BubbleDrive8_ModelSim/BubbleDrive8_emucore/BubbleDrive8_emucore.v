module BubbleDrive8_emucore
(
    //48MHz input clock
    input   wire            MCLK,

    //module enable
    input   wire            nEN,

    //DIP switch
    input   wire    [2:0]   IMGNUM,

    //4bit width mode
    input   wire            BITWIDTH4,

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

    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMCLK,
    inout   wire            ROMIO0,
    input   wire            ROMIO1,
    input   wire            ROMIO2,
    input   wire            ROMIO3,
    
    //FIFO buffer
    output  wire            nFIFOBUFWRCLKEN,
    output  wire    [12:0]  FIFOBUFWRADDR,
    output  wire            FIFOBUFWRDATA,
    output  wire            nFIFOSENDBOOT,
    output  wire            nFIFOSENDUSER,
    output  wire    [11:0]  FIFORELPAGE,
    
    //BUBBLE ACC LED
    output  wire            nACC
);

//TimingGenerator
wire    [2:0]   ACCTYPE;
wire    [12:0]  BOUTCYCLENUM;
wire    [11:0]  ABSPAGE;
wire            nBINCLKEN;
wire            nBOUTCLKEN;

//SPILoader -> BubbleInterface
wire            nOUTBUFWRCLKEN;
wire    [14:0]  OUTBUFWRADDR;
wire            OUTBUFWRDATA;

assign nACC = ~ACCTYPE[2];


TimingGenerator TimingGenerator_0
(
    .MCLK           (MCLK           ),

    .nEN            (nEN            ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (nBSS           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (nSWAPEN        ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .nBINCLKEN      (nBINCLKEN      ),
    .nBOUTCLKEN     (nBOUTCLKEN     ),

    .ABSPAGE        (ABSPAGE         )
);



BubbleInterface BubbleInterface_0
(
    .MCLK           (MCLK           ),

    .BITWIDTH4      (BITWIDTH4      ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .nBINCLKEN      (nBINCLKEN      ),
    .nBOUTCLKEN     (nBOUTCLKEN     ),

    .nOUTBUFWRCLKEN (nOUTBUFWRCLKEN ),
    .OUTBUFWRADDR   (OUTBUFWRADDR   ),
    .OUTBUFWRDATA   (OUTBUFWRDATA   ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          ),
    .DOUT2          (DOUT2          ),
    .DOUT3          (DOUT3          )
);



SPILoader SPILoader_0
(
    .MCLK           (MCLK           ),

    .IMGNUM         (IMGNUM         ),

    .BITWIDTH4      (BITWIDTH4      ),

    .ACCTYPE        (ACCTYPE        ),
    .ABSPAGE        (ABSPAGE         ),
    .RELPAGE        (FIFORELPAGE   ),

    .nOUTBUFWRCLKEN (nOUTBUFWRCLKEN ),
    .OUTBUFWRADDR   (OUTBUFWRADDR   ),
    .OUTBUFWRDATA   (OUTBUFWRDATA   ),

    .nCS            (nROMCS         ),
    .CLK            (ROMCLK         ),
    .IO0            (ROMIO0         ),
    .IO1            (ROMIO1         ),
    .IO2            (ROMIO2         ),
    .IO3            (ROMIO3         ),

    .nFIFOBUFWRCLKEN(nFIFOBUFWRCLKEN),
    .FIFOBUFWRADDR  (FIFOBUFWRADDR  ),
    .FIFOBUFWRDATA  (FIFOBUFWRDATA  ),
    .nFIFOSENDBOOT  (nFIFOSENDBOOT  ),
    .nFIFOSENDUSER  (nFIFOSENDUSER  )
);


endmodule