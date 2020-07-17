module TimingGenerator
//This module partially emulates Fujitsu MB14506's timing control feature.
/*
Original pinout below:
             +---------+
    CLKOUT<--|    U    |---+5V
      /REP-->|         |-->/CLAMP
    /SWAP?-->|         |-->STROBE
       GND---|         |-->/REPEN
       /BS-->|         |-->/REPOUT
      /BSS-->| MB14506 |-->/SWAPEN?
(floating)---|         |-->/WRITEEN
     CLKIN-->|         |-->+X
         ?-->|         |-->-X
       GND---|         |-->+Y
       GND---|         |-->-Y
             +---------+
1. CLKOUT: 4MHz clock out
2. REP: Replicator enable
3. SWAP: Swap gate enable
5. BS: Shifts bubbles during LOW
6. BSS: Bubble shift start pulse
8. CLKIN: 12MHz clock in
9. ?: Something related to a voltage detection circuit, grounded.
12. -Y: -Y driver enable
13. +Y: +Y driver enable
14. -X: -X driver enable
15. +X: +X driver enable
16. WRITEEN: 74LS32 write data enable
17. SWAPEN: Swap gate enable (MB3910 Pin 5)
18. REPOUT: Replicate out pulse (MB3910 Pin 7)
19. REPEN: Replicator enable (MB3910 Pin 6)
20. STROBE: Bubble data out strobe (MB3908 Pin 10)
21. CLAMP: Clamps bubble detector signal (MB3908 Pin 11)
*/
(
    //48MHz input clock
    input   wire            master_clock,
    //4MHz output clock
    output  reg             clock_out = 1'b1,

    //Bubble control signal inputs
    //input   wire            bubble_shift_start,
    input   wire            bubble_shift_enable,
    input   wire            replicator_enable,
    input   wire            bootloop_enable,
    
    //Emulator signal outputs
    output  wire            position_change, //0 degree, bubble position change notification (active high)
    output  wire            data_out_strobe, //Starts at 180 degree, ends at 240 degree, can put bubble data at a falling edge (active high)
    output  wire            data_out_notice, //Same as replicator clamp (active high)
    output  wire            position_latch, //Current bubble position can be latched when this line has been asserted (active high)
    output  wire            bootloader_select, //Bootloader select, bypass signal of bootloop_enable (active high)
    output  wire            coil_run //Goes high when bubble moves - same as COIL RUN (active high)
);



/*
    GLOBAL REGISTERS
*/
//Global clock
reg             clock12MHz = 1'b1;

//Synchronization registers HI[bubble_shift_start / bubble_shift_enable / replicator_enable / bootloop_enable]LO
reg     [2:0]   stepOne = 3'b111;
reg     [2:0]   stepTwo = 3'b111;
reg     [2:0]   stepThree = 3'b111;
reg             bubbleShiftEnableInternal = 1'b1;
reg             replicatorEnableInternal = 1'b1;
reg             bootloopEnableInternal = 1'b0;

//State counters
reg     [7:0]   mainStateCounter = 8'd0;
reg     [7:0]   replicatorStateCounter = 6'd0;   

//Function signals
reg     [3:0]   coilEnable = 4'b1111; //HI[+Y -Y -X +X]LO
reg             detectorClamp = 1'b1;
reg             detectorStrobe = 1'b0;
reg             functionRepEnable = 1'b1;
reg             functionRepOut = 1'b1;
reg             dataInEnable = 1'b1;
reg             coilRun = 1'b0; //Goes HIGH while driving



/*
    SIGNAL ASSIGNMENTS
*/
assign position_change = ~(coilEnable[3] || coilEnable[1]); 
assign data_out_notice = ~detectorClamp;
assign data_out_strobe = detectorStrobe;
assign position_latch = ~functionRepOut; 
assign bootloader_select = ~bootloopEnableInternal;
assign coil_run = coilRun;
 


/*
    SYNCHRONIZER
*/
always @(posedge clock12MHz)
begin
    stepOne[2] <= bubble_shift_enable;
    stepOne[1] <= replicator_enable;
    stepOne[0] <= bootloop_enable;

    stepTwo <= stepOne;
    stepThree <= stepTwo;
end

always @(negedge clock12MHz)
begin
    bubbleShiftEnableInternal <= stepThree[2];
    replicatorEnableInternal <= stepThree[1];
    bootloopEnableInternal <= stepThree[0];
end



/*
    CLOCK DIVIDER
*/
reg     [1:0]   divide4 = 2'd0;
reg     [2:0]   divide12 = 3'd0;

always @(posedge master_clock)
begin
    //Internal 12MHz clock
    if(divide4 >= 2'd1)
    begin
        divide4 <= 2'd0;
        clock12MHz <= ~clock12MHz;
    end
    else
    begin
        divide4 <= divide4 + 2'd1;
    end
    
    //External 4MHz clock
    if(divide12 >= 3'd5)
    begin
        divide12 <= 3'd0;
        clock_out <= ~clock_out;
    end
    else
    begin
        divide12 <= divide12 + 3'd1;
    end
end



/*
    MAIN SEQUENCER
*/
always @(posedge clock12MHz)
begin
    if(bubbleShiftEnableInternal == 1'b1) //STOP
    begin
        if(coilRun == 1'b0) //COIL STOP
        begin
            mainStateCounter <= 8'd0;
        end
        else //COIL RUN
        begin
            if(mainStateCounter >= 8'd18 && mainStateCounter <= 8'd44) //-X vector
            begin
                mainStateCounter <= mainStateCounter + 8'd1;
            end
            else if(mainStateCounter == 8'd45) //Just before -Y vector starts
            begin
                mainStateCounter <= 8'd166;
            end
            else if(mainStateCounter >= 8'd46 && mainStateCounter <= 8'd168)
            begin
                mainStateCounter <= mainStateCounter + 8'd1;
            end
            else
            begin
                mainStateCounter <= 8'd0;
            end
        end
    end
    else //SHIFTING
    begin
        if(mainStateCounter == 8'd139) //After first rotation
        begin
            mainStateCounter <= 8'd20; //Loop
        end
        else
        begin
            mainStateCounter <= mainStateCounter + 8'd1;
        end
    end
end

//Coil driver signal generation
always @(*)
begin
    if(mainStateCounter >= 8'd0 && mainStateCounter <= 8'd17) //intro
    begin
        coilEnable <= 4'b1111; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b0;
    end
    else if(mainStateCounter >= 8'd18 && mainStateCounter <= 8'd45)
    begin
        coilEnable <= 4'b1101; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd46 && mainStateCounter <= 8'd48)
    begin
        coilEnable <= 4'b1001; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd49 && mainStateCounter <= 8'd72)
    begin
        coilEnable <= 4'b1011; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd73 && mainStateCounter <= 8'd79)
    begin
        coilEnable <= 4'b1010; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd80 && mainStateCounter <= 8'd105) //MB3910 strobe goes LOW, clamp goes HIGH at positive edge of 97th clock
    begin
        coilEnable <= 4'b1110; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd106 && mainStateCounter <= 8'd109)
    begin
        coilEnable <= 4'b0110; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd110 && mainStateCounter <= 8'd137)
    begin
        coilEnable <= 4'b0111; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd138 && mainStateCounter <= 8'd139)
    begin
        coilEnable <= 4'b0101; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else if(mainStateCounter >= 8'd140 && mainStateCounter <= 8'd168)
    begin
        coilEnable <= 4'b1101; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b1;
    end
    else
    begin
        coilEnable <= 4'b1111; //HI[+Y -Y -X +X]LO
        coilRun <= 1'b0;
    end
end

//Data in enable(74LS32) signal generation
always @(*)
begin
    if(mainStateCounter >= 8'd16 && mainStateCounter <= 8'd18)
    begin
        dataInEnable <= 1'b0;
    end
    else if(mainStateCounter >= 8'd136 && mainStateCounter <= 8'd138)
    begin
        dataInEnable <= 1'b0;
    end
    else
    begin
        dataInEnable <= 1'b1;
    end
end

//Sense amplifier signal generation
always @(*)
begin
    if(mainStateCounter >= 8'd56 && mainStateCounter <= 8'd77)
    begin
        detectorClamp <= 1'b0;
        detectorStrobe <= 1'b0;
    end
    else if(mainStateCounter >= 8'd78 && mainStateCounter <= 8'd93)
    begin
        detectorClamp <= 1'b0;
        detectorStrobe <= 1'b1;
    end
    else
    begin
        detectorClamp <= 1'b1;
        detectorStrobe <= 1'b0;
    end
end



/*
    REPLICATOR SEQUENCER
*/
reg             replicatorRun = 1'b0; //Goes HIGH while running
always @(posedge clock12MHz)
begin
    if(replicatorEnableInternal == 1'b1) //STOP
    begin
        if(replicatorRun == 1'b0) //REPLICATOR STOP
        begin
            replicatorStateCounter <= 8'd0;
        end
        else //REPLICATOR RUN
        begin
            replicatorStateCounter <= replicatorStateCounter + 8'd1;
        end
    end
    else //RUN
    begin
        replicatorStateCounter <= replicatorStateCounter + 8'd1;
    end
end

//Replicator signal generation
always @(*)
begin
    if(replicatorStateCounter >= 8'd14 && replicatorStateCounter <= 8'd15)
    begin
        functionRepEnable <= 1'b0;
        functionRepOut <= 1'b1;
        replicatorRun <= 1'b1;
    end
    else if(replicatorStateCounter >= 8'd16 && replicatorStateCounter <= 8'd18)
    begin
        functionRepEnable <= 1'b0;
        functionRepOut <= 1'b0;
        replicatorRun <= 1'b1;
    end
    else if(replicatorStateCounter >= 8'd19 && replicatorStateCounter <= 8'd49)
    begin
        functionRepEnable <= 1'b0;
        functionRepOut <= 1'b1;
        replicatorRun <= 1'b1;
    end
    else
    begin
        functionRepEnable <= 1'b1;
        functionRepOut <= 1'b1;
        replicatorRun <= 1'b0;
    end
end
endmodule