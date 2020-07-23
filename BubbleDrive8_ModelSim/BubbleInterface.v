module BubbleInterface
(
    //Master clock
    input   wire            master_clock, //48MHz master clock

    //Data from management module
    input   wire            bubble_module_enable, //active low

    //Timing signals from TimingGenerator module
    input   wire            position_change, //0 degree, bubble position change notification (active high)
    input   wire            data_out_strobe, //Starts at 180 degree, ends at 240 degree, can put bubble data at a falling edge (active high)
    input   wire            data_out_notice, //Same as replicator clamp (active high)
    input   wire            position_latch, //Current bubble position can be latched when this line has been asserted (active high)
    input   wire            page_select, //Bootloader select, synchronized signal of bootloop_enable (active high)
    input   wire            coil_run, //Goes high when bubble moves - same as COIL RUN (active high)

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
    output  reg             bubble_out_even
);



/*
    CONSTANTS
*/
/*
                    |-------(26420us)-------|(pos0)|-------(19290us)-------|
74LS32 pulse   |____|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|____|¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯¯|____|        (90 degree)
*/
localparam THE_NUMBER_OF_BUBBLE_POSITIONS = 12'd2053; //0000 - 2052: 2053 positions
localparam INITIAL_POSITION_VALUE = 12'd1464; //(initial value) + (pre-position 0 length) - 2053 = 0
localparam BOOTLOADER_OUT_LENGTH = 13'd4571; //total bootloader enable length: 2640 + 2(20us of start pattern) + 1929
localparam PAGE_OUT_LENGTH = 11'd703; //1 to 703



/*
    GLOBAL REGISTERS / NETS
*/
reg              bootloaderLoadOutEnable = 1'b1; //active low, goes low while bootloader load/out
assign           load_bootloader = bootloaderLoadOutEnable;
reg              pageLoadOutEnable = 1'b1; //active low,  goes low while page load/out
assign           load_page = pageLoadOutEnable;

wire             bufferDataOutCounterEnable; //active low, composite signal of above two
assign           bufferDataOutCounterEnable = bootloaderLoadOutEnable & pageLoadOutEnable;
reg     [13:0]   bufferDataOutNoticeCounter = 13'd0;
reg     [13:0]   bufferDataOutCounter = 13'd0;

reg              bufferReadAddressCountEnable = 1'b1; //active low, address incrementation enable
reg              bubbleReadClockEnable = 1'b0; //active low, bubble block RAM buffer read clock (negative edge of STROBE)

reg     [1:0]    bubbleOutMux = 2'b00;




/*
    ENABLE SIGNAL GENERATOR FOR BUBBLE OUT SEQUENCER / FLASH DATA LOADER
*/
//Signals from TimingGenerator module change at positive edges of 12MHz clock, and 12MHz clock alters at every positive edges of 48MHz master clock.
//We can capture signals at every negative edge of 48MHz master clock.
always @(negedge master_clock)
begin
    //bootloader load out
    bootloaderLoadOutEnable <= (page_select | ~coil_run); //goes 0 when bootloader shifting starts, goes 1 when bubble shifting ends

    //page load out: goes 0 when bubbles replicate out, goes 1 when bubble shifting ends
    case ({position_latch, coil_run})
        2'b00:  pageLoadOutEnable <= 1'b1;
        2'b01:  pageLoadOutEnable <= pageLoadOutEnable;
        2'b10:  pageLoadOutEnable <= pageLoadOutEnable;
        2'b11:  pageLoadOutEnable <= 1'b0;
    endcase
end



/*
    BUBBLE POSITION TO PAGE CONVERTER
*/
reg     [11:0]   positionCounter = INITIAL_POSITION_VALUE;

assign convert = position_latch & page_select; //only works when bootloader is not selected
assign bubble_position_output = positionCounter;

//position counter
always @(posedge position_change)
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



/*
    OUTPUT DATA MULTIPLEXER
*/
always @(*)
begin
    if(bubble_module_enable == 1'b1) //disabled
    begin
        bubble_out_odd <= 1'b0;
        bubble_out_even <= 1'b0;        
    end
    else //enabled
    begin
        if((bufferDataOutCounterEnable) == 1'b1)
        begin
            bubble_out_odd <= 1'b1;
            bubble_out_even <= 1'b1;   
        end
        else
        begin
            bubble_out_odd <= ~bubbleOutMux[1];
            bubble_out_even <= ~bubbleOutMux[0];   
        end
    end
end



/*
    BUBBLE OUTPUT BLOCK RAM BUFFER
*/
reg     [1:0]   bubbleBuffer[2047:0];
reg     [10:0]  bubbleBufferReadAddress;
reg     [1:0]   bubbleBufferDataOutput;
wire            bubbleBufferReadClock;
assign  bubbleBufferReadClock = data_out_strobe & ~bubbleReadClockEnable;

always @ (posedge bubble_buffer_write_clock) //write
begin
    if (bubble_buffer_write_enable == 1'b0)
    begin
        bubbleBuffer[bubble_buffer_write_address] <= bubble_buffer_write_data_input;
    end
end
    
always @ (negedge bubbleBufferReadClock) //read 
begin        
    bubbleBufferDataOutput <= bubbleBuffer[bubbleBufferReadAddress];
end



/*
    BUBBLE OUT SEQUENCER
*/
//Data out notice counter
always @(posedge data_out_notice or posedge bufferDataOutCounterEnable)
begin
    if(bufferDataOutCounterEnable == 1'b1) //counter stop
    begin
        bufferDataOutNoticeCounter <= 13'd0;
    end
    else //count up
    begin
        if(bufferDataOutNoticeCounter < BOOTLOADER_OUT_LENGTH)
        begin
            bufferDataOutNoticeCounter <= bufferDataOutNoticeCounter + 13'd1;
        end
        else
        begin
            bufferDataOutNoticeCounter <= bufferDataOutNoticeCounter;
        end
    end
end

//Data out bit counter
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

//Address counter
always @(posedge data_out_strobe or posedge bufferReadAddressCountEnable)
begin
    if(bufferReadAddressCountEnable == 1'b1) //counter stop
    begin
        bubbleBufferReadAddress <= 11'b111_1111_1111;
    end
    else
    begin
        if(bubbleBufferReadAddress < 11'b111_1111_1111)
        begin
            bubbleBufferReadAddress <= bubbleBufferReadAddress + 11'b1;
        end
        else
        begin
            bubbleBufferReadAddress <= 11'b0;
        end
    end
end

/*
BOOTLOADER OUT BIT COUNTER
1 to 4571 pulse (the number of DATA_OUT_STROBE pulse)
0001 - 2640: HIGH
2641 - 2642: START PATTERN 0111
2643 - 4562: BOOTLOADER (!!ERROR MAP LOW: 3971 - 4562 / 592 BITS PER CHANNEL!!) 
4563 - 4568: LOW (DUMMY DATA)
4569 - 4571: HIGH (DUMMY BITS: DON'T CARE)

PAGE OUT BIT COUNTER
1 to 703 (the number of DATA_OUT_STROBE pulse)
001 - 100: HIGH (DON'T CARE?)
101 - 612: DATA 1024 BITS
613 - 703: HIGH (DON'T CARE)
*/

//Controls address count enable, block RAM buffer read clock enable signals
always @(*)
begin
    case ({bootloaderLoadOutEnable, pageLoadOutEnable})
        2'b00:
            begin
                bufferReadAddressCountEnable <= 1'b1;
                bubbleReadClockEnable <= 1'b1;
            end
        2'b01: //bootloader enable
            begin
                if(bufferDataOutNoticeCounter >= 13'd2643 && bufferDataOutNoticeCounter <= 13'd4562)
                begin
                    bufferReadAddressCountEnable <= 1'b0;
                    bubbleReadClockEnable <= 1'b0;
                end
                else
                begin
                    bufferReadAddressCountEnable <= 1'b1;
                    bubbleReadClockEnable <= 1'b1;
                end
            end
        2'b10:
            begin
                if(bufferDataOutNoticeCounter >= 13'd101 && bufferDataOutNoticeCounter <= 13'd612)
                begin
                    bufferReadAddressCountEnable <= 1'b0;
                    bubbleReadClockEnable <= 1'b0;
                end
                else
                begin
                    bufferReadAddressCountEnable <= 1'b1;
                    bubbleReadClockEnable <= 1'b1;
                end
            end
        2'b11:
            begin
                bufferReadAddressCountEnable <= 1'b1;
                bubbleReadClockEnable <= 1'b1;
            end
    endcase
end

//Controls two-bit-width bubble data output
always @(*)
begin
    case ({bootloaderLoadOutEnable, pageLoadOutEnable})
        2'b00:
            begin
                bubbleOutMux[1] <= 1'b0;
                bubbleOutMux[0] <= 1'b0;
            end
        2'b01: //bootloader enable
            begin
                if(bufferDataOutCounter == 13'd2641)
                begin     
                    bubbleOutMux[1] <= 1'b0;
                    bubbleOutMux[0] <= 1'b1;
                end
                else if(bufferDataOutCounter == 13'd2642)
                begin
                    bubbleOutMux[1] <= 1'b1;
                    bubbleOutMux[0] <= 1'b1;
                end
                else if(bufferDataOutCounter >= 13'd2643 && bufferDataOutCounter <= 13'd4562)
                begin
                    bubbleOutMux[1] <= bubbleBufferDataOutput[1];
                    bubbleOutMux[0] <= bubbleBufferDataOutput[0];
                end
                else if(bufferDataOutCounter >= 13'd4563 && bufferDataOutCounter <= 13'd4568)
                begin
                    bubbleOutMux[1] <= 1'b1;
                    bubbleOutMux[0] <= 1'b1;
                end
                else
                begin                      
                    bubbleOutMux[1] <= 1'b0;
                    bubbleOutMux[0] <= 1'b0;
                end
            end
        2'b10:
            begin
                if(bufferDataOutCounter >= 13'd101 && bufferDataOutCounter <= 13'd612)
                begin
                    bubbleOutMux[1] <= bubbleBufferDataOutput[1];
                    bubbleOutMux[0] <= bubbleBufferDataOutput[0];
                end
                else
                begin
                    bubbleOutMux[1] <= 1'b0;
                    bubbleOutMux[0] <= 1'b0;
                end
            end
        2'b11:
            begin
                bubbleOutMux[1] <= 1'b0;
                bubbleOutMux[0] <= 1'b0;
            end
    endcase
end
endmodule