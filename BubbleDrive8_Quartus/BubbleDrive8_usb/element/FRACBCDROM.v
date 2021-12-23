module FRACBCDROM
(
    input   wire            MCLK,
    input   wire            nCLKEN,
    input   wire    [3:0]   ADDR,
    output  reg     [15:0]  DATA
);

always @(posedge MCLK) //read 
begin   
    if(nCLKEN == 1'b0)
    begin
        case(ADDR)
            4'b0000: DATA <= 16'h0000;
            4'b0001: DATA <= 16'h0625;
            4'b0010: DATA <= 16'h1250;
            4'b0011: DATA <= 16'h1875;
            4'b0100: DATA <= 16'h2500;
            4'b0101: DATA <= 16'h3125;
            4'b0110: DATA <= 16'h3750;
            4'b0111: DATA <= 16'h4375;
            4'b1000: DATA <= 16'h5000;
            4'b1001: DATA <= 16'h5625;
            4'b1010: DATA <= 16'h6250;
            4'b1011: DATA <= 16'h6875;
            4'b1100: DATA <= 16'h7500;
            4'b1101: DATA <= 16'h8125;
            4'b1110: DATA <= 16'h8750;
            4'b1111: DATA <= 16'h9375;
        endcase
    end
end

endmodule