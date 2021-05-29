`timescale 1ns/10ps
module TC77_fake
/*

*/

(
    input   reg             nCS,
    inout   wire            SIO,
    input   reg             CLK
);


localparam TEMP_VALUE = 13'b0_0001_1001_0000; //25 degrees
localparam IS_CONVERTED = 1'b1; //converted
localparam FILLER = 2'bZZ;

reg     [15:0]  tempreg = 16'b0;
reg             OUTLATCH = 1'bZ;
assign  #20    SIO = (nCS == 1'b1) ? 1'bZ : OUTLATCH;

always @(negedge nCS)
begin
    tempreg <= {TEMP_VALUE, IS_CONVERTED, FILLER};
end

always @(negedge CLK)
begin
    OUTLATCH <= #80 tempreg[15];
    tempreg[15:1] <= #80 tempreg[14:0];
end

endmodule