module BubbleDrive8_top
(
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

);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;

//TimingGenerator
wire    [2:0]   ACCTYPE;
wire    [12:0]  BOUTCYCLENUM;
wire    [1:0]   BOUTTICKS;

wire    [11:0]  ABSPOS;

//SPILoader -> BubbleInterface
wire    [14:0]  OUTBUFWADDR;
wire            OUTBUFWCLK;
wire            OUTBUFWDATA;

//BubbleInterface
wire            DOUT0;
wire            DOUT1;


TimingGenerator Main
(
    .MCLK           (MCLK           ),
    .CLKOUT         (CLKOUT         ),
    
    .nINCTRL        (1'b0           ),

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


BubbleInterface Main
(
    .MCLK           (MCLK           ),

    .ACCTYPE        (ACCTYPE        ),
    .BOUTCYCLENUM   (BOUTCYCLENUM   ),
    .BOUTTICKS      (BOUTTICKS      ),

    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWCLK     (OUTBUFWCLK     ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .DOUT0          (DOUT0          ),
    .DOUT1          (DOUT1          )
);



SPILoader Main
(
    .IMGNUM         (3'b000         ),

    .MCLK           (MCLK           ),

    .ACCTYPE        (ACCTYPE        ),
    .ABSPOS         (ABSPOS         ),

    .OUTBUFWADDR    (OUTBUFWADDR    ),
    .OUTBUFWCLK     (OUTBUFWCLK     ),
    .OUTBUFWDATA    (OUTBUFWDATA    ),

    .nCS            (nROMCS         ),
    .MOSI           (ROMMOSI        ),
    .MISO           (ROMMISO        ),
    .CLK            (ROMCLK         )
);


W25Q32JVxxIM Module0 
(
    .CSn(nCS),
    .CLK(CLK),
    .DO(MISO),
    .DIO(MOSI),
    
    .WPn(nWP),
    .HOLDn(nHOLD),
    .RESETn(nHOLD)
);

endmodule