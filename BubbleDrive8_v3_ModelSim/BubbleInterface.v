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
    input   wire    [11:0]  ABSPOS          //absolute position number
);

/*
    Block RAM Buffer Address [ODD/EVEN]
    13bit address

    0000-1986 : 11 = filler
    1987-2050 : X0 64 of ZEROs on EVEN channel
    2051      : X1 1 of ONE on EVEN channel
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

reg     [12:0]  bubble_buffer_read_address = 13'b1_1111_1111_1111

always @(*)
begin
    case (ACCTYPE)
        BOOT:
        begin
            bubble_buffer_read_address <= BOUTCYCLENUM;
        end
        USER:
        begin
            bubble_buffer_read_address <= {3'b111, BOUTCYCLENUM[9:0]};
        end
        default:
        begin
            bubble_buffer_read_address <= 13'b1_1111_1111_1111;
        end
    endcase
end









reg     [1:0]   bubbleBuffer[8191:0];
reg     [12:0]  bubbleBufferReadAddress = 13'b1_1111_1111_1111;
reg     [1:0]   bubbleBufferDataOutput;
reg             bubbleBufferReadClock = 1'b0;

always @(posedge bubble_buffer_write_clock) //write
begin
    if (bubble_buffer_write_enable == 1'b0)
    begin
        bubbleBuffer[bubble_buffer_write_address] <= bubble_buffer_write_data_input;
    end
end

always @(negedge bubbleBufferReadClock) //read 
begin   
    bubbleBufferDataOutput <= bubbleBuffer[bubbleBufferReadAddress];
end