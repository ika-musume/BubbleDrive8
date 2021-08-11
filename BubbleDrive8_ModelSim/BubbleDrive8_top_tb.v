`timescale 10ns/10ns
module BubbleDrive8_top_tb;

reg             master_clock = 1'b1;
wire            clock_out;

reg             bubble_shift_enable = 1'b1;
reg             replicator_enable = 1'b1;
reg             bootloop_enable = 1'b0;

reg             power_good = 1'b1;
wire            temperature_low;

reg     [2:0]   image_dip_switch = 3'b000;

wire            bubble_out_0;
wire            bubble_out_1;

reg             i;


wire            nROMCS;
wire            ROMMOSI;
wire            ROMMISO;
wire            ROMCLK;
wire            nWP;
wire            nHOLD;

wire            nTEMPCS;
wire            TEMPCLK;
wire            TEMPSIO;

wire            nFANEN;

wire            nLED_ACC;
wire            nLED_DELAYING;
wire            nLED_STANDBY;
wire            nLED_PWROK;

wire    [7:0]   ADBUS;
wire    [5:0]   ACBUS;
assign ACBUS[5] = 1'b1;
assign ACBUS[4:2] = 3'bZZZ;
assign ACBUS[1:0] = 2'b00;



BubbleDrive8_top Main
(
    .MCLK           (master_clock   ),
    
    //emulator
    .CLKOUT         (clock_out      ),
    
    .nBSS           (1'b1           ),
    .nBSEN          (bubble_shift_enable),
    .nREPEN         (replicator_enable),
    .nBOOTEN        (bootloop_enable),
    .nSWAPEN        (1'b1           ),

    .MRST           (power_good     ),

    .DOUT0          (bubble_out_0   ),
    .DOUT1          (bubble_out_1   ),
    .DOUT2          (               ),
    .DOUT3          (               ),

    .IMGNUM         (3'b000         ),

    .nROMCS         (nROMCS         ),
    .ROMMOSI        (ROMMOSI        ),
    .ROMMISO        (ROMMISO        ),
    .ROMCLK         (ROMCLK         ),
    .nWP            (nWP            ),
    .nHOLD          (nHOLD          ),

    //temperature detector
    .TEMPSW         (3'b000         ),
    .FORCESTART     (1'b0           ),

    .nTEMPCS        (nTEMPCS        ),
    .TEMPCLK        (TEMPCLK        ),
    .TEMPSIO        (TEMPSIO        ),

    .nTEMPLO        (temperature_low),
    .nFANEN         (nFANEN         ),

    //MPSSE
    .PWRSTAT        (1'b0           ),
    .ADBUS          (ADBUS          ),
    .ACBUS          (ACBUS          ),

    .nLED_ACC       (nLED_ACC       ),
    .nLED_DELAYING  (nLED_DELAYING  ),
    .nLED_STANDBY   (nLED_STANDBY    ),
    .nLED_PWROK     (nLED_PWROK     )
);


W25Q32JVxxIM SPIFlash_0 
(
    .CSn            (nROMCS         ),
    .CLK            (ROMCLK         ),
    .DO             (ROMMISO        ),
    .DIO            (ROMMOSI        ),
    
    .WPn            (nWP            ),
    .HOLDn          (nHOLD          ),
    .RESETn         (nHOLD          )
);

TC77_fake TC77_0
(
    .nCS            (nTEMPCS        ),
    .SIO            (TEMPSIO        ),
    .CLK            (TEMPCLK        ),

    .nSYSOK         (power_good     )
);

always #1 master_clock = ~master_clock;

initial
begin
    #300000 power_good = 1'b0;
end

always @(posedge temperature_low)
begin
    //bootloader
    #50038 replicator_enable = 1'b0;
    
    while(bootloop_enable == 1'b0)
    begin
        #687 replicator_enable = 1'b1;
        #1233 replicator_enable = 1'b0;
    end
    #0 replicator_enable = 1'b1;

    //181
    #1788530 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
    //182
    #749977 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
    //183
    #749977 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
end

always @(posedge temperature_low)
begin
    //bootloader
    #50000 bubble_shift_enable = 1'b0;
    #4387745 bubble_shift_enable = 1'b1; //00붙임
    #423 bootloop_enable = 1'b1;
    //181
    #650000 bubble_shift_enable = 1'b0;
    #1814231 bubble_shift_enable = 1'b1;
    //182
    #75000 bubble_shift_enable = 1'b0;
    #675660 bubble_shift_enable = 1'b1;
    //183
    #75000 bubble_shift_enable = 1'b0;
    #675660 bubble_shift_enable = 1'b1;

    #1000 bootloop_enable = 1'b0;
    #50000 bubble_shift_enable = 1'b0;
    #438774500 bubble_shift_enable = 1'b1; //00붙임
end

endmodule