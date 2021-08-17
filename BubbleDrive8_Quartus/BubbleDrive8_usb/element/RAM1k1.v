module RAM1k1
(
    input   wire            MCLK,
    input   wire    [9:0]   RDADDR,
	input   wire    [9:0]   WRADDR,
	input   wire            DIN,
	output  reg             DOUT,
    input   wire            nWE,
	input   wire            nWRCLKEN,
	input   wire            nRDCLKEN
);

reg             RAM1k1 [1023:0];

always @(negedge MCLK)
begin
    if(nWRCLKEN == 1'b0)
    begin
       if (nWE == 1'b0)
       begin
           RAM1k1[WRADDR] <= DIN;
       end
    end
end

always @(negedge MCLK) //read 
begin
    if(nRDCLKEN == 1'b0)
    begin
        DOUT <= RAM1k1[RDADDR];
    end
end


endmodule