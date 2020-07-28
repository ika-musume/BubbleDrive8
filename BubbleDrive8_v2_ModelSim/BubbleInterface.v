module BubbleInterface
(
    //Master clock
    input   wire            master_clock, //48MHz master clock

    //Data from management module
    input   wire            bubble_module_enable, //active low

    //Timing signals from TimingGenerator module
    input   wire            position_change, //0 degree, bubble position change notification (active high)
    input   wire            data_out_strobe, //Starts at 180 degree, ends at 240 degree, can put bubble data at a falling edge (active high)
    input   wire            position_latch, //Current bubble position can be latched when this line has been asserted (active high)
    input   wire            page_select, //Bootloader select, synchronized signal of bootloop_enable (active high)
    input   wire            coil_enable, //Goes low when bubble moves - same as COIL RUN (active low)

    //Bubble position to page converter I/O
    output  wire            convert,
    output  wire    [11:0]  bubble_position_output, //12 bit counter


    //SPI Loader
    input   wire    [10:0]  bubble_buffer_write_address,
    input   wire    [1:0]   bubble_buffer_write_data_input,
    input   wire            bubble_buffer_write_enable,
    input   wire            bubble_buffer_write_clock,
    output  wire            load_page,
    output  wire            load_bootloader,
    
    //Bubble data output
    output  reg             bubble_out_odd,
    output  reg             bubble_out_even,



    input   wire            bubble_data_out_clock //test
);



/*
    CONSTANTS
*/
/*
                    |-------(26420us)-------|(pos0)|-------(19290us)-------|
74LS32 pulse   |____|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|____|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|____|        (90 degree)
*/
localparam THE_NUMBER_OF_BUBBLE_POSITIONS = 12'd2053; //0000 - 2052: 2053 positions
localparam BOOTLOADER_OUT_LENGTH = 13'd4571; //total bootloader enable length: 2640 + 2(20us of start pattern) + 1929



/*
    GLOBAL REGISTERS / NETS
*/
reg              bootloaderLoadOutEnable = 1'b1; //active low, goes low while bootloader load/out
assign           load_bootloader = bootloaderLoadOutEnable;
reg              pageLoadOutEnable = 1'b1; //active low,  goes low while page load/out
assign           load_page = pageLoadOutEnable;

wire             bufferDataOutCounterEnable; //active low, composite signal of above two
assign           bufferDataOutCounterEnable = bootloaderLoadOutEnable & pageLoadOutEnable;
reg     [13:0]   bufferDataOutCounter = 13'd0;

reg              positionReset = 1'b1;




/*
    ENABLE SIGNAL STATE MACHINE FOR BUBBLE OUT SEQUENCER / FLASH DATA LOADER
*/

/*
~functionRepOut     ____|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_|¯|_______________________|¯|_________________________

page_select         ________________________________________|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯
coil_enable         ¯¯|_______________________________________|¯¯¯¯¯¯¯¯¯|____________________________________|¯¯
position_latch      ______________________________________________________________|¯|___________________________
                      |----(bootloader load out enable)-----|                     |--(page load out enable)--|
----->TIME          A                    B                   D     C        D      E            D             C           X: POSSIBLE GLITCH

A: INITIAL_STANDBY
B: BOOTLOADER_ACCESS
C: NORMAL_STANDBY
D: NORMAL_ACCESS
E: PAGE_LATCH
X: POSSIBLE GLITCH - HOLD PREVIOUS STATE
*/

localparam BOOTLOADER_ACCESS = 3'b000;  //B
localparam INITIAL_STANDBY = 3'b010;    //A
localparam NORMAL_ACCESS = 3'b100;      //D
localparam PAGE_LATCH = 3'b101;         //E
localparam NORMAL_STANDBY = 3'b110;     //C

reg     [2:0]    bubbleAccessState = INITIAL_STANDBY;

always @(posedge master_clock)
begin
    case ({page_select, coil_enable, position_latch})
        BOOTLOADER_ACCESS: //B
        begin
            if(bubbleAccessState == NORMAL_ACCESS || bubbleAccessState == PAGE_LATCH) //D or E->B: GLITCH
            begin
                bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
                pageLoadOutEnable <= pageLoadOutEnable;
                bubbleAccessState <= bubbleAccessState;
            end
            else
            begin
                bootloaderLoadOutEnable <= 1'b0;
                pageLoadOutEnable <= 1'b1;
                bubbleAccessState <= BOOTLOADER_ACCESS;
            end
        end
        3'b001: //X
        begin
            bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
            pageLoadOutEnable <= pageLoadOutEnable;
            bubbleAccessState <= bubbleAccessState;
        end
        INITIAL_STANDBY: //A
        begin
            if(bubbleAccessState == PAGE_LATCH) //E->A: GLITCH
            begin
                bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
                pageLoadOutEnable <= pageLoadOutEnable;
                bubbleAccessState <= bubbleAccessState;
            end
            else
            begin
                bootloaderLoadOutEnable <= 1'b1;
                pageLoadOutEnable <= 1'b1;
                bubbleAccessState <= INITIAL_STANDBY;
            end
        end
        3'b011: //X
        begin
            bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
            pageLoadOutEnable <= pageLoadOutEnable;
            bubbleAccessState <= bubbleAccessState;
        end
        NORMAL_ACCESS: //D 
        begin
            bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
            pageLoadOutEnable <= pageLoadOutEnable;
            bubbleAccessState <= NORMAL_ACCESS;
        end
        PAGE_LATCH: //E
        begin
            if(bubbleAccessState == INITIAL_STANDBY || bubbleAccessState == BOOTLOADER_ACCESS || bubbleAccessState == NORMAL_STANDBY) //ONLY D->E ALLOWED
            begin
                bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
                pageLoadOutEnable <= pageLoadOutEnable;
                bubbleAccessState <= bubbleAccessState;
            end
            else
            begin
                bootloaderLoadOutEnable <= 1'b1;
                pageLoadOutEnable <= 1'b0;
                bubbleAccessState <= PAGE_LATCH;
            end
        end
        NORMAL_STANDBY: //C
        begin
            if(bubbleAccessState == PAGE_LATCH) //E->C GLITCH
            begin
                bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
                pageLoadOutEnable <= pageLoadOutEnable;
                bubbleAccessState <= bubbleAccessState;
            end
            else
            begin
                bootloaderLoadOutEnable <= 1'b1;
                pageLoadOutEnable <= 1'b1;
                bubbleAccessState <= NORMAL_STANDBY;
            end
        end
        3'b111: //X
        begin
            bootloaderLoadOutEnable <= bootloaderLoadOutEnable;
            pageLoadOutEnable <= pageLoadOutEnable;
            bubbleAccessState <= bubbleAccessState;
        end
    endcase
end


/*
    BUBBLE POSITION TO PAGE CONVERTER
*/
reg     [11:0]   positionCounter = 12'd0;

assign convert = position_latch; //only works when bootloader is not selected
assign bubble_position_output = positionCounter;

//position counter
always @(posedge position_change)
begin
    if(positionReset == 1'b0)
    begin
        if(positionCounter < THE_NUMBER_OF_BUBBLE_POSITIONS - 12'd1)
        begin
            positionCounter <= positionCounter + 12'd1;
        end
        else
        begin
            positionCounter <= 12'd0;
        end
    end
    else
    begin
        positionCounter <= 12'd0;
    end
end



/*
    BUBBLE OUTPUT BLOCK RAM BUFFER
*/
reg     [1:0]   bubbleBuffer[2047:0];
reg     [10:0]  bubbleBufferReadAddress = 11'b111_1111_1111;
reg     [1:0]   bubbleBufferDataOutput;
reg             bubbleBufferReadClock = 1'b0;
//assign  bubbleBufferReadClock = data_out_strobe & ~bubbleReadClockEnable;

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







/*
    BUBBLE OUT SEQUENCER.
*/

/*
Data out bit counter: will delete in the near future
BOOTLOADER OUT BIT COUNTER
1 to 4571 pulse (the number of DATA_OUT_STROBE pulse)
0001 - 2640: HIGH
2641 - 2642: START PATTERN 0111
2643 - 4562: BOOTLOADER (!!ERROR MAP LOW: 3971 - 4562 / 592 BITS PER CHANNEL!!) 
4563 - 4568: LOW (DUMMY DATA)
4569 - 4571: HIGH (DUMMY BITS: DON'T CARE)
(ORIGx2) - 1 = NEW
- 2 = state assign pos

PAGE OUT BIT COUNTER
1 to 703 (the number of DATA_OUT_STROBE pulse)
001 - 100: HIGH (DON'T CARE?)
101 - 612: DATA 1024 BITS
613 - 703: HIGH (DON'T CARE)
*/
always @(negedge data_out_strobe or posedge bufferDataOutCounterEnable)
begin
    if(bufferDataOutCounterEnable == 1'b1) //counter stop
    begin
        bufferDataOutCounter <= 13'd0;
    end
    else //count up
    begin
        if(bufferDataOutCounter < BOOTLOADER_OUT_LENGTH)
        begin
            bufferDataOutCounter <= bufferDataOutCounter + 13'd1;
        end
        else
        begin
            bufferDataOutCounter <= bufferDataOutCounter;
        end
    end
end


/*
    BUBBLE OUT SEQUENCER STATE MACHINE TEST
*/

localparam PAGE_STARTING_POINT = 14'd201;

localparam RESET = 4'b1000;
localparam ADDRESS_INCREMENT = 4'b1001;
localparam DATA_OUT = 4'b1010;
localparam WAIT = 4'b1011;

reg     [13:0]  bubbleDataOutClockCounter = 14'd16383;
reg     [3:0]   bubbleDataOutState = RESET;

//COUNT
always @(negedge bubble_data_out_clock or posedge bufferDataOutCounterEnable) //bufferDataOutCounterEnable변수명은 나중에 수정
begin
    if(bufferDataOutCounterEnable == 1'b1) //counter stop
    begin
        bubbleDataOutClockCounter <= 14'd16383;
    end
    else //count up
    begin
        if(bubbleDataOutClockCounter < 14'd16383)
        begin
            bubbleDataOutClockCounter <= bubbleDataOutClockCounter + 14'd1;
        end
        else
        begin
            bubbleDataOutClockCounter <= 14'd0;
        end
    end
end

//DETECT
always @(negedge bubble_data_out_clock)
begin
    case ({bootloaderLoadOutEnable, pageLoadOutEnable})
        2'b00:
            begin
                bubbleDataOutState <= RESET;
            end
        2'b01: //bootloader enable
            begin
                if(bubbleDataOutClockCounter >= 14'd5282 && bubbleDataOutClockCounter <= 14'd9121)
                begin
                    case(bubbleDataOutClockCounter[0])
                        1'b0: bubbleDataOutState <= ADDRESS_INCREMENT;
                        1'b1: bubbleDataOutState <= DATA_OUT;
                    endcase
                end
                else
                begin
                    bubbleDataOutState <= RESET;
                end
            end
        2'b10:
            begin
                if(bubbleDataOutClockCounter == PAGE_STARTING_POINT - 14'd4)
                begin
                    bubbleDataOutState <= ADDRESS_INCREMENT;
                end
                else if(bubbleDataOutClockCounter == PAGE_STARTING_POINT - 14'd3)
                begin
                    bubbleDataOutState <= DATA_OUT;
                end
                else if(bubbleDataOutClockCounter == PAGE_STARTING_POINT - 14'd2) 
                begin
                    bubbleDataOutState <= WAIT;
                end
                else if(bubbleDataOutClockCounter >= PAGE_STARTING_POINT - 14'd1 && bubbleDataOutClockCounter <= PAGE_STARTING_POINT + 14'd1020)
                begin
                    case(bubbleDataOutClockCounter[0])
                        1'b0: bubbleDataOutState <= ADDRESS_INCREMENT;
                        1'b1: bubbleDataOutState <= DATA_OUT;
                    endcase
                end
                else
                begin
                    bubbleDataOutState <= RESET;
                end
            end
        2'b11:
            begin
                bubbleDataOutState <= RESET;
            end
    endcase
end

//EXECUTE
always @(negedge bubble_data_out_clock)
begin
    case(bubbleDataOutState)
        RESET:
        begin
            bubbleBufferReadClock <= 1'b1;
            bubbleBufferReadAddress <= 11'b111_1111_1111;
        end
        ADDRESS_INCREMENT:
        begin
            bubbleBufferReadClock <= 1'b1;
            if(bubbleBufferReadAddress < 11'b111_1111_1111)
            begin
                bubbleBufferReadAddress <= bubbleBufferReadAddress + 11'b1;
            end
            else
            begin
                bubbleBufferReadAddress <= 11'b0;
            end
        end
        DATA_OUT:
        begin
            bubbleBufferReadClock <= 1'b0;
            bubbleBufferReadAddress <= bubbleBufferReadAddress;
        end
        WAIT:
        begin
            bubbleBufferReadClock <= bubbleBufferReadClock;
            bubbleBufferReadAddress <= bubbleBufferReadAddress;
        end
        default:
        begin
            bubbleBufferReadClock <= 1'b1;
            bubbleBufferReadAddress <= 11'b111_1111_1111;
        end
    endcase
end



/*
    POSITION INITIALIZER
*/
always @(negedge bubble_data_out_clock)
begin
    if(bubbleDataOutClockCounter == 14'd5282 || bubbleDataOutClockCounter == 14'd5283)
    begin
        positionReset <= 1'b1;
    end
    else
    begin
        positionReset <= 1'b0;
    end
end



/*
    OUTPUT DATA MULTIPLEXER
*/
always @(*)
begin
    case ({bubble_module_enable, bootloaderLoadOutEnable, pageLoadOutEnable})
        3'b000:
            begin
                bubble_out_odd <= 1'b1;
                bubble_out_even <= 1'b1; 
            end
        3'b001: //bootloader enable
            begin
                if(bubbleDataOutClockCounter == 14'd5281 || bubbleDataOutClockCounter == 14'd5282)
                begin
                    bubble_out_odd <= 1'b1;
                    bubble_out_even <= 1'b0;
                end
                else if(bubbleDataOutClockCounter == 14'd5283 || bubbleDataOutClockCounter == 14'd5284)
                begin
                    bubble_out_odd <= 1'b0;
                    bubble_out_even <= 1'b0;
                end
                else if(bubbleDataOutClockCounter >= 14'd5285 && bubbleDataOutClockCounter <= 14'd9124)
                begin
                    bubble_out_odd <= ~bubbleBufferDataOutput[1];
                    bubble_out_even <= ~bubbleBufferDataOutput[0];
                end
                else if(bubbleDataOutClockCounter >= 14'd9125 && bubbleDataOutClockCounter <= 14'd9136)
                begin
                    bubble_out_odd <= 1'b0;
                    bubble_out_even <= 1'b0;
                end
                else
                begin
                    bubble_out_odd <= 1'b1;
                    bubble_out_even <= 1'b1; 
                end
            end
        3'b010: //page enable
            begin
                if(bubbleDataOutClockCounter >= PAGE_STARTING_POINT && bubbleDataOutClockCounter <= PAGE_STARTING_POINT + 14'd1023)
                begin
                    bubble_out_odd <= ~bubbleBufferDataOutput[1];
                    bubble_out_even <= ~bubbleBufferDataOutput[0];
                end
                else
                begin
                    bubble_out_odd <= 1'b1;
                    bubble_out_even <= 1'b1;
                end
            end
        3'b011:
            begin
                bubble_out_odd <= 1'b1;
                bubble_out_even <= 1'b1;
            end
        3'b100:
            begin
                bubble_out_odd <= 1'b0;
                bubble_out_even <= 1'b0;
            end
        3'b101:
            begin
                bubble_out_odd <= 1'b0;
                bubble_out_even <= 1'b0;
            end
        3'b110:
            begin
                bubble_out_odd <= 1'b0;
                bubble_out_even <= 1'b0;
            end
        3'b111:
            begin
                bubble_out_odd <= 1'b0;
                bubble_out_even <= 1'b0;
            end
    endcase
end
endmodule