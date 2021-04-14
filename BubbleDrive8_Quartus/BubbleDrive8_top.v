module BubbleDrive8_top
(
    //48MHz input clock
    input   wire            MCLK,

    //input control
    //input   wire    [2:0]   IMGNUM,

    //4MHz output clock
    output  wire            CLKOUT,

    //Bubble control signal inputs
    //input   wire            nBSS,
    input   wire            nBSEN,
    input   wire            nREPEN,
    input   wire            nBOOTEN,
    //input   wire            nSWAPEN,

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
    //output  wire            TEMPCLK
     
     //debug
    output wire nBSENOUT,
    output wire nBOOTENOUT,
    output wire nREPENOUT
     
);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;


assign nBSENOUT = nBSEN;
assign nBOOTENOUT = nBOOTEN;
assign nREPENOUT = nREPEN;



//TimingGenerator
wire    [2:0]   ACCTYPE;
wire    [12:0]  BOUTCYCLENUM;
wire    [1:0]   BOUTTICKS;

wire    [11:0]  ABSPOS;

//SPILoader -> BubbleInterface
wire            nOUTBUFWCLKEN;
wire    [14:0]  OUTBUFWADDR;
wire            OUTBUFWDATA;


TimingGenerator TimingGenerator_0
(
    .MCLK           (MCLK           ),

    .nINCTRL        (1'b0           ),

    .CLKOUT         (CLKOUT         ),
    .nBSS           (1'b1           ),
    .nBSEN          (nBSEN          ),
    .nREPEN         (nREPEN         ),
    .nBOOTEN        (nBOOTEN        ),
    .nSWAPEN        (1'b1        ),

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

    .IMGNUM         (3'b000         ),

    .ACCTYPE        (ACCTYPE        ),
    .ABSPOS         (ABSPOS         ),

    .nOUTBUFWCLKEN  (nOUTBUFWCLKEN  ),
    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .nCS            (nROMCS         ),
    .MOSI           (ROMMOSI        ),
    .MISO           (ROMMISO        ),
    .CLK            (ROMCLK         )
);

endmodule