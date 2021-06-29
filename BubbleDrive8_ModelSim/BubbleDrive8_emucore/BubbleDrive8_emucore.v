module BubbleDrive8_emucore
(
    //48MHz input clock
    input   wire            MCLK,

    //module enable
    input   wire            nEN,

    //DIP switch
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
    output  wire            DOUT2,
    output  wire            DOUT3,

    //W25Q32
    output  wire            nROMCS,
    output  wire            ROMMOSI,
    input   wire            ROMMISO,
    output  wire            ROMCLK,
    
    //BUBBLE ACC LED
    output  wire            nACC
);

//TimingGenerator
wire    [2:0]   ACCTYPE;
wire    [12:0]  BOUTCYCLENUM;
wire    [11:0]  ABSPOS;
wire            nBINCLKEN;
wire            nBOUTCLKEN;
wire            nNOBUBBLE;
wire    [11:0]  CURRPAGE;

//SPILoader -> BubbleInterface
wire            nOUTBUFWCLKEN;
wire    [14:0]  OUTBUFWADDR;
wire            OUTBUFWDATA;

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
    .nNOBUBBLE      (nNOBUBBLE      ),

    .ABSPOS         (ABSPOS         )
);



BubbleInterface BubbleInterface_0
(
    .MCLK           (MCLK           ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .nBINCLKEN      (nBINCLKEN      ),
    .nBOUTCLKEN     (nBOUTCLKEN     ),
    .nNOBUBBLE      (nNOBUBBLE      ),

    .nOUTBUFWCLKEN  (nOUTBUFWCLKEN  ),
    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          ),
    .DOUT2          (DOUT2          ),
    .DOUT3          (DOUT3          )
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


endmodule