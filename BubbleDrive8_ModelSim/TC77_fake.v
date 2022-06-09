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

reg     [15:0]  SERIALREG;
assign  #7    SIO = (nCS == 1'b1) ? 1'bZ : SERIALREG[15];

//temperature list
reg     [15:0]  TEMPERATURE_LIST [3:0];
initial 
begin
    TEMPERATURE_LIST[0] <= 16'b0_0001_1001_0000_0_ZZ; //not ready
    TEMPERATURE_LIST[1] <= 16'b1_0001_0000_0000_1_ZZ; //negative retry
    TEMPERATURE_LIST[2] <= 16'b0_0001_0000_0000_1_ZZ; //16
    TEMPERATURE_LIST[3] <= 16'b0_0010_0100_0000_1_ZZ; //36
    TEMPERATURE_LIST[4] <= 16'b0_0001_1000_0000_1_ZZ; //24
    TEMPERATURE_LIST[5] <= 16'b0_0010_0111_0000_1_ZZ; //39
end


reg     [3:0]   LISTCOUNTER = 4'd15;

always @(posedge nCS)
begin
    if(LISTCOUNTER == 4'd15)
    begin
        LISTCOUNTER <= 4'd0;
    end
    else
    begin
        LISTCOUNTER <= LISTCOUNTER + 4'd1;
    end
end

always @(negedge nCS)
begin
    SERIALREG <= TEMPERATURE_LIST[LISTCOUNTER];
end

always @(negedge CLK)
begin
    SERIALREG[15:1] <= #3 SERIALREG[14:0];
end

endmodule