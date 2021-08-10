module TEXTROM
(
    input   wire            MCLK,
    input   wire            nCLKEN,
    input   wire    [6:0]   ADDR,
    output  reg     [7:0]   DATA
);

reg     [7:0]   text_rom[127:0];

always @(negedge MCLK) //read 
begin   
    if(nCLKEN == 1'b0)
    begin
        DATA <= text_rom[ADDR];
    end
end

initial
begin
    $readmemh("ASCII_message.txt", text_rom);
end

endmodule