module TimingGenerator
/*

    BubbleDrive_v2
    
    TimingGenerator.v

    This Verilog model partially emulates MB14056's timing signal generation future, but I generated several new signals for BubbleDrive8

*/

(
    //48MHz input clock
    input   wire            master_clock,

    //Control
    input   wire            bubble_module_enable,

    //4MHz output clock
    output  reg             clock_out = 1'b1,

    //Bubble control signal inputs
    input   wire            bubble_shift_enable,
    input   wire            replicator_enable,
    input   wire            bootloop_enable,
    
    //Emulator signal outputs
    output  reg             position_change, //0 degree, bubble position change notification (active high)
    output  wire            data_out_strobe, //Starts at 180 degree, ends at 240 degree, can put bubble data at a falling edge (active high)
    output  wire            position_latch, //Current bubble position can be latched when this line has been asserted (active high)
    output  wire            page_select, //Program page select, synchronized signal of bootloop_enable (active high)
    output  wire            coil_enable, //Goes high when bubble moves - same as COIL RUN (active low)
    output  reg             bubble_data_out_clock = 1'b0 //Clock for the BubbleInferface bubble data output logic
);



/*
    GLOBAL REGISTERS
*/
//Global clock
wire            clock12MHz;

//Synchronization registers HI[bubble_shift_enable / replicator_enable / bootloop_enable]LO
reg     [2:0]   stepOne = 3'b110;
reg     [2:0]   stepTwo = 3'b110;
reg     [2:0]   stepThree = 3'b110;
reg             bubbleShiftEnableInternal = 1'b1;
reg             replicatorEnableInternal = 1'b1;
reg             bootloopEnableInternal = 1'b0;

//State counters
reg     [7:0]   mainStateCounter = 8'd0;

//Function signals
reg             detectorStrobe = 1'b0;
reg             functionRepOut = 1'b1;
reg             coilRun = 1'b1; //Goes HIGH while driving



/*
    SIGNAL ASSIGNMENTS
*/
assign data_out_strobe = detectorStrobe;
assign position_latch = ~functionRepOut & bootloopEnableInternal; 
assign page_select = bootloopEnableInternal;
assign coil_enable = ~coilRun;
 


/*
    SYNCHRONIZER
*/
always @(posedge clock12MHz)
begin
    stepOne[2] <= bubble_module_enable | bubble_shift_enable;
    stepOne[1] <= bubble_module_enable | replicator_enable;
    stepOne[0] <= ~bubble_module_enable & bootloop_enable;

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
assign clock12MHz = divide4[1];
reg     [2:0]   divide12 = 3'd0;

always @(posedge master_clock)
begin
    //Internal 12MHz clock
    if(divide4 < 2'd3)
    begin
        divide4 <= divide4 + 2'd1;
    end
    else
    begin
        divide4 <= 2'd0;
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
//Because of the 12MHz synchronizer, there's a delay of 3 clock cycles on three internal signal BS, REPEN, and BOOTEN. 
//I subtracted 3 from the reg mainStateCounter for timing compensation.

always @(posedge clock12MHz)
begin
    if(bubbleShiftEnableInternal == 1'b1) //STOP
    begin
        if(coilRun == 1'b0) //COIL STOP
        begin
            mainStateCounter <= 8'd0;
        end
        else //WHILE RUNNING
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
        if(mainStateCounter == 8'd139) //After a full rotation
        begin
            mainStateCounter <= 8'd20; //Loop
        end
        else
        begin
            mainStateCounter <= mainStateCounter + 8'd1;
        end
    end
end


//position_change
always @(mainStateCounter)
begin
    if(mainStateCounter == 8'd138 || mainStateCounter == 8'd139)
    begin
        position_change <= 1'b1;
    end
	else
	begin
	    position_change <= 1'b0;
	end
end

//coil_enable
always @(mainStateCounter)
begin
    if(mainStateCounter >= 8'd18 && mainStateCounter <= 8'd168)
    begin
        coilRun <= 1'b1;
    end
	else
	begin
	    coilRun <= 1'b0;
	end
end

//functionRepOut
always @(mainStateCounter or replicatorEnableInternal)
begin
    if(replicatorEnableInternal == 1'b1)
    begin
        functionRepOut <= 1'b1;
    end
    else
    begin
        if(mainStateCounter >= 8'd21 && mainStateCounter <= 8'd23)
        begin
            functionRepOut <= 1'b0;
        end
        else if(mainStateCounter >= 8'd141 && mainStateCounter <= 8'd143)
        begin
            functionRepOut <= 1'b0;
        end
        else
        begin
            functionRepOut <= 1'b1;
        end
    end
end

//bubble_data_out_clock
always @(mainStateCounter)
begin
    if(mainStateCounter >= 8'd24 && mainStateCounter <= 8'd33)
    begin
        bubble_data_out_clock <= 1'b1;
    end
    else if(mainStateCounter >= 8'd84 && mainStateCounter <= 8'd93)
    begin
        bubble_data_out_clock <= 1'b1;
    end
    else
    begin
        bubble_data_out_clock <= 1'b0;
    end
end

//will delete in the near future
always @(mainStateCounter)
begin
    if(mainStateCounter >= 8'd78 && mainStateCounter <= 8'd93)
    begin
        detectorStrobe <= 1'b1;
    end
    else
    begin
        detectorStrobe <= 1'b0;
    end
end
endmodule