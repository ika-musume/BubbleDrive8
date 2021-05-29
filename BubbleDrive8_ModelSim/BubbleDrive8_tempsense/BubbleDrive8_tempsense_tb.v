`timescale 1ns/10ps
module BubbleDrive8_tempsense_tb;

reg             nSYSOK = 1'b1;
reg             MCLK = 1'b1;

reg             FORCESTART = 1'b0;

wire            nTEMPLO;
wire            nFANEN;
wire            nLED_DELAYING;

wire            nTEMPCS;
wire            TEMPSIO;
wire            TEMPCLK;



BubbleDrive8_tempsense Main
(
    .nSYSOK         (nSYSOK         ),
    .MCLK           (MCLK           ),

    .TEMPSW         (3'b111         ),
    
    .FORCESTART     (FORCESTART     ),

    .nTEMPLO        (nTEMPLO        ),
    .nFANEN         (nFANEN         ),
    .nLED_DELAYING  (nLED_DELAYING  ),
    
    .nTEMPCS        (nTEMPCS        ),
    .TEMPSIO        (TEMPSIO        ),
    .TEMPCLK        (TEMPCLK        )
);

TC77_fake Device0
(
    .nCS            (nTEMPCS        ),
    .SIO            (TEMPSIO        ),
    .CLK            (TEMPCLK        )
);

always #10.41 MCLK = ~MCLK;

initial
begin
    #83.28 nSYSOK = 1'b0;
end

endmodule