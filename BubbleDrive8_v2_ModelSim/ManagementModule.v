module ManagementModule
(
    //Master clock
    input   wire            master_clock, //48MHz master clock

    //Data from/to the BUBBLE SYSTEM board
    input   wire            power_good,
    output  reg             temperature_low = 1'b0, //This is the READY signal

    //Data from/to SPILoader
    output  wire    [2:0]   image_number, //management module latches them at the very initial time of total boot process
    
    //Data to BubbleInterface
    output  reg             bubble_module_enable = 1'b1, //active low

    //On-board components
    //input   wire    [11:0]  bubble_page_input, //PPPP/PPPP/PPPP
    input   wire    [2:0]   image_dip_switch
    //input   wire    [3:0]   function_dip_switch
);



/*
    GLOBAL REGISTERS
*/
//Synchronization registers
reg             stepOne = 1'b0;
reg             stepTwo = 1'b0;
reg             stepThree = 1'b0;
reg             powerGoodInternal = 1'b0;

reg     [31:0]  clockCounter = 32'd0;
localparam COUNTER_MAX = 32'd8191; //orig 48000000
//TTTT_TTTT_XXXX_XXXX_XXXX_XXXX_XXXX_XXXX (25bit)

reg     [2:0]   imageNumberLatch = 3'b000;
assign image_number = imageNumberLatch;



/*
    SYNCHRONIZER
*/
always @(posedge master_clock)
begin
    stepOne <= power_good;
    stepTwo <= stepOne;
    stepThree <= stepTwo;
end

always @(negedge master_clock)
begin
    powerGoodInternal <= stepThree;
end



/*
    CLOCK COUNTER
*/
always @(posedge master_clock)
begin
    if(powerGoodInternal == 1'b0)
    begin
        clockCounter <= 32'd0;    
    end
    else
    begin
        if(clockCounter < COUNTER_MAX)
        begin
            clockCounter <= clockCounter + 32'd1;
        end
        else
        begin
            clockCounter <= clockCounter;
        end
    end
end

always @(clockCounter[12:10] or image_dip_switch)
begin
    if(clockCounter[12:10] == 3'd0) //NOT_READY
    begin
        temperature_low <= 1'b0;
        bubble_module_enable <= 1'b1;
    end
    else if(clockCounter[12:10] == 3'd1)  //LATCH_IMAGE_NUMBER
    begin
        temperature_low <= 1'b0;
        bubble_module_enable <= 1'b1;
        imageNumberLatch <= ~image_dip_switch;
    end
    else if(clockCounter[12:10] == 3'd2) //RUN
    begin
        temperature_low <= 1'b1;
        bubble_module_enable <= 1'b0;
    end
    else
    begin
        temperature_low <= 1'b1;
        bubble_module_enable <= 1'b0;
    end
end
endmodule