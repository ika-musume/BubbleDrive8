`timescale 10ns/10ns
module TC77_fake
/*

*/

(
    input   reg             nCS,
    inout   wire            SIO,
    input   reg             CLK,

    input   wire            nSYSOK
);


reg     [12:0]  TEMP_VALUE = 13'b0_0001_1001_0000; //25 degrees
reg             IS_CONVERTED = 1'b0; //converted
localparam FILLER = 2'bZZ;

always @(negedge nSYSOK)
begin
    #0 TEMP_VALUE <= 13'b0_0001_1001_0000;  //not ready
    #0 IS_CONVERTED <= 1'b0;

    #4200 TEMP_VALUE <= 13'b0_0001_0000_0000; //16 degrees
    #0 IS_CONVERTED <= 1'b1;

    #4000 TEMP_VALUE <= 13'b0_0010_0100_0000; //36 degrees
    #0 IS_CONVERTED <= 1'b1;

    #3420 TEMP_VALUE <= 13'b0_0001_1000_0000; //25 degrees
    #0 IS_CONVERTED <= 1'b1;

    #8240 TEMP_VALUE <= 13'b0_0010_0100_0000; //36 degrees
    #0 IS_CONVERTED <= 1'b1;
end


reg     [15:0]  tempreg = 16'b0;
reg             OUTLATCH = 1'bZ;
assign  #2    SIO = (nCS == 1'b1) ? 1'bZ : OUTLATCH;

always @(negedge nCS)
begin
    tempreg <= {TEMP_VALUE, IS_CONVERTED, FILLER};
end

always @(negedge CLK)
begin
    OUTLATCH <= #8 tempreg[15];
    tempreg[15:1] <= #8 tempreg[14:0];
end

endmodule