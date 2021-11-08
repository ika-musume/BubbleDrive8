`timescale 10ns/10ns
module SPIDriver_tb;

reg             master_clock = 1'b1;

reg     [2:0]   image_number = 3'b000;
reg     [2:0]   access_type = 3'b000;
reg     [11:0]  absolute_position = 12'd1018;

wire    [14:0]  write_addr;
wire            write_data;
wire            write_clock;


wire            nCS;
wire            MOSI;
wire            MISO;
wire            CLK;
wire            nWP;
wire            nHOLD;


SPILoader Main
(
    .MCLK(master_clock),
    .IMGNUM(image_number),
    .ACCTYPE(access_type),
    .ABSPOS(absolute_position),

    .OUTBUFWADDR(write_addr),
    .OUTBUFWDATA(write_data),
    .nOUTBUFWCLKEN(write_clock),

    .nCS(nCS),
    .MOSI(MOSI),
    .MISO(MISO),
    .CLK(CLK),
    .nWP(nWP),
    .nHOLD(nHOLD)
);

W25Q32JVxxIM Module0 (.CSn(nCS), .CLK(CLK), .DO(MISO), .DIO(MOSI), .WPn(nWP), .HOLDn(nHOLD), .RESETn(nHOLD));

always #1 master_clock = ~master_clock;

initial
begin
    #10000 access_type = 3'b110;
    #60000 access_type = 3'b000;
    #100 access_type = 3'b001;
    #100 access_type = 3'b111;
    #20000 access_type = 3'b000;
end

endmodule