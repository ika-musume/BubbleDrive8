module BubbleInterface
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,


    //Emulator signal outputs
    input   wire    [2:0]   ACCTYPE,        //access type
    input   wire    [12:0]  BOUTCYCLENUM,   //bubble output cycle number
    input   wire    [1:0]   BOUTTICKS,      //bubble output asynchronous control ticks
    input   wire    [11:0]  ABSPOS,         //absolute position number


    input   wire    [14:0]  OUTBUFWADDR,      //bubble outbuffer write address
    input   wire            OUTBUFWCLK,       //bubble outbuffer write clk
    input   wire            OUTBUFWDATA,      //bubble outbuffer write data

    output  wire            DOUT0,
    output  wire            DOUT1
);

localparam 4BITMODE = 1'b0; //4bit mode off

/*
    OUTBUFFER READ ADDRESS DECODER
*/

/*
    Block RAM Buffer Address [DOUT1/DOUT0]
    13bit address
    0000-1986 : 11 = filler
    1987-2050 : X0 = 64 of ZEROs on EVEN channel
    2051      : X1 = 1 of ONE on EVEN channel
    2052      : XX
    2053-3972 : 480bytes = 3840bits bootloader
    3973-4105 : 11 = filler
    7168-7170 : 00 = 3 position shifted page data
    7171-7682 : 128bytes = 1024bits page data
    7683-7751 : 00 = filler
    8190      : 00 = empty bubble propagation line
    8191      : 00 = empty bubble propagation line
*/

localparam BOOT = 3'b110;   //C
localparam USER = 3'b111;   //D

reg     [12:0]  outbuffer_read_address = 13'b1_1111_1111_1111

always @(*)
begin
    case (ACCTYPE)
        BOOT:
        begin
            outbuffer_read_address <= BOUTCYCLENUM;
        end
        USER:
        begin
            outbuffer_read_address <= {3'b111, BOUTCYCLENUM[9:0]};
        end
        default:
        begin
            outbuffer_read_address <= 13'b1_1111_1111_1111;
        end
    endcase
end



/*
    OUTBUFFER WRITE ADDRESS DECODER
*/

reg     [3:0]   outbuffer_write_en = 4'b1111; //D3 D2 DOUT1 DOUT0
reg     [12:0]  outbuffer_write_address;

always @(*)
begin
    case(4BITMODE)
        1'b0: //2BITMODE
        begin
            case(OUTBUFWADDR[0])
                1'b0:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[13:1];
                    outbuffer_write_en <= 4'b1110;
                end
                1'b1:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[13:1];
                    outbuffer_write_en <= 4'b1101;
                end
            endcase
        end
        1'b1: //4BITMODE: no game released
        begin
            case(OUTBUFWADDR[1:0])
                2'b00:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_write_en <= 4'b1110;
                end
                2'b01:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_write_en <= 4'b1101;
                end
                2'b10:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_write_en <= 4'b1011;
                end
                2'b11:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_write_en <= 4'b0111;
                end
            endcase
        end
    endcase
end



/*
    OUTBUFFER
*/

//DOUT0
reg             D0_outbuffer[8191:0];
reg             D0_outbuffer_read_data;
assign          DOUT0 = D0_outbuffer_read_data;

always @(posedge OUTBUFWCLK) //write
begin
    if (outbuffer_write_en[0] == 1'b0)
    begin
        D0_outbuffer[OUTBUFWADDR] <= OUTBUFWDATA
    end
end

always @(posedge BOUTTICKS[1]) //read 
begin   
    D0_outbuffer_read_data <= D0_outbuffer[outbuffer_read_address];
end

//DOUT1
reg             D1_outbuffer[8191:0];
reg             D1_outbuffer_read_data;
assign          DOUT1 = D1_outbuffer_read_data;

always @(posedge OUTBUFWCLK) //write
begin
    if (outbuffer_write_en[1] == 1'b0)
    begin
        D1_outbuffer[OUTBUFWADDR] <= OUTBUFWDATA
    end
end

always @(posedge BOUTTICKS[1]) //read 
begin   
    D1_outbuffer_read_data <= D1_outbuffer[outbuffer_read_address];
end

endmodule