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


    input   wire    [14:0]  BUFWRADDR,      //bubble buffer write address
    input   wire            BUFWRCLK,       //bubble buffer write clk
    input   wire            BUFWRDATA,      //bubble buffer write data

    output  wire            D0,
    output  wire            D1
);

localparam 4BITMODE = 1'b0; //4bit mode off

/*
    BUFFER READ ADDRESS DECODER
*/

/*
    Block RAM Buffer Address [D1/D0]
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

reg     [12:0]  buffer_read_address = 13'b1_1111_1111_1111

always @(*)
begin
    case (ACCTYPE)
        BOOT:
        begin
            buffer_read_address <= BOUTCYCLENUM;
        end
        USER:
        begin
            buffer_read_address <= {3'b111, BOUTCYCLENUM[9:0]};
        end
        default:
        begin
            buffer_read_address <= 13'b1_1111_1111_1111;
        end
    endcase
end



/*
    BUFFER WRITE ADDRESS DECODER
*/

reg     [3:0]   buffer_write_en = 4'b1111; //D3 D2 D1 D0
reg     [12:0]  buffer_write_address;

always @(*)
begin
    case(4BITMODE)
        1'b0: //2BITMODE
        begin
            case(BUFWRADDR[0])
                1'b0:
                begin
                    buffer_write_address <= BUFWRADDR[13:1];
                    buffer_write_en <= 4'b1110;
                end
                1'b1:
                begin
                    buffer_write_address <= BUFWRADDR[13:1];
                    buffer_write_en <= 4'b1101;
                end
            endcase
        end
        1'b1: //4BITMODE: no game released
        begin
            case(BUFWRADDR[1:0])
                2'b00:
                begin
                    buffer_write_address <= BUFWRADDR[14:2];
                    buffer_write_en <= 4'b1110;
                end
                2'b01:
                begin
                    buffer_write_address <= BUFWRADDR[14:2];
                    buffer_write_en <= 4'b1101;
                end
                2'b10:
                begin
                    buffer_write_address <= BUFWRADDR[14:2];
                    buffer_write_en <= 4'b1011;
                end
                2'b11:
                begin
                    buffer_write_address <= BUFWRADDR[14:2];
                    buffer_write_en <= 4'b0111;
                end
            endcase
        end
    endcase
end



/*
    BUFFER
*/

//D0
reg             D0_buffer[8191:0];
reg             D0_buffer_read_data;
assign          D0 = D0_buffer_read_data;

always @(posedge BUFWRCLK) //write
begin
    if (buffer_write_en[0] == 1'b0)
    begin
        D0_buffer[BUFWRADDR] <= BUFWRDATA
    end
end

always @(posedge BOUTTICKS[1]) //read 
begin   
    D0_buffer_read_data <= D0_buffer[buffer_read_address];
end

//D1
reg             D1_buffer[8191:0];
reg             D1_buffer_read_data;
assign          D1 = D1_buffer_read_data;

always @(posedge BUFWRCLK) //write
begin
    if (buffer_write_en[1] == 1'b0)
    begin
        D1_buffer[BUFWRADDR] <= BUFWRDATA
    end
end

always @(posedge BOUTTICKS[1]) //read 
begin   
    D1_buffer_read_data <= D1_buffer[buffer_read_address];
end

endmodule