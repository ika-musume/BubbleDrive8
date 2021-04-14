`timescale 10ns/10ns
module TimingGenerator_tb;

reg             master_clock = 1'b1;
wire            clock_out;

reg             standby_pulse = 1'b1;
reg             bubble_shift_enable = 1'b1;
reg             replicator_enable = 1'b1;
reg             bootloop_enable = 1'b0;

reg             power_good = 1'b1;

wire    [2:0]   ACCTYPE;        //access type
wire    [12:0]  BOUTCYCLENUM;   //bubble output cycle number
wire    [1:0]   BOUTTICKS;      //bubble output asynchronous control ticks
wire    [11:0]  ABSPOS;         //absolute position number

reg             i;
reg             temperature_low = 1'b0;

TimingGenerator test0
(
	.MCLK (master_clock),
    .CLKOUT (clock_out),

    .nBSS (standby_pulse),
    .nBSEN (bubble_shift_enable),
    .nREPEN (replicator_enable),
    .nBOOTEN (bootloop_enable),

    .nINCTRL(power_good),

    .ACCTYPE(ACCTYPE),
    .BOUTCYCLENUM(BOUTCYCLENUM),
    .BOUTTICKS(BOUTTICKS),
    .ABSPOS(ABSPOS)
);

always #1 master_clock = ~master_clock;

initial
begin
    #300000 power_good = 1'b0;
    #0 temperature_low = 1'b1;
end

always @(posedge temperature_low)
begin
    //bootloader
    #50038 replicator_enable = 1'b0;
    
    while(bootloop_enable == 1'b0)
    begin
        #687 replicator_enable = 1'b1;
        #1233 replicator_enable = 1'b0;
    end
    #0 replicator_enable = 1'b1;

    //181
    #1788530 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
    //182
    #749977 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
    //183
    #749977 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
end

always @(posedge temperature_low)
begin
    //bootloader
    #50000 bubble_shift_enable = 1'b0;
    #4387745 bubble_shift_enable = 1'b1;
    #423 bootloop_enable = 1'b1;

    
    //181
    #650000 bubble_shift_enable = 1'b0;
    #1814231 bubble_shift_enable = 1'b1;
    //182
    #75000 bubble_shift_enable = 1'b0;
    #675660 bubble_shift_enable = 1'b1;
    //183
    #75000 bubble_shift_enable = 1'b0;
    #675660 bubble_shift_enable = 1'b1;
    /*
    //184
    #75000 bubble_shift_enable = 1'b0;
    #999 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673977 bubble_shift_enable = 1'b1;
    //185
    #75000 bubble_shift_enable = 1'b0;
    #998 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673978 bubble_shift_enable = 1'b1;
    //186
    #75000 bubble_shift_enable = 1'b0;
    #999 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673977 bubble_shift_enable = 1'b1;
    //187
    #75000 bubble_shift_enable = 1'b0;
    #998 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673978 bubble_shift_enable = 1'b1;
    //187
    #75000 bubble_shift_enable = 1'b0;
    #999 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673977 bubble_shift_enable = 1'b1;
    //191
    #75000 bubble_shift_enable = 1'b0;
    #1465973 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //192
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //193
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //194
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //195
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //196
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //197
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //198
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //199
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19A
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19B
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19C
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //191
    #75000 bubble_shift_enable = 1'b0;
    #1745338 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //192
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //193
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //194
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //195
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //196
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //197
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //198
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //199
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19A
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19B
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //19C
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //101
    #75000 bubble_shift_enable = 1'b0;
    #997494 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //102
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //103
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //104
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //105
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //106
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //107
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //108
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //109
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10A
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10B
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10C
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10D
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10E
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //10F
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //110
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //101
    #75000 bubble_shift_enable = 1'b0;
    #1012850 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //102
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //103
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //104
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //105
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //106
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //107
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //108
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    //109
    #75000 bubble_shift_enable = 1'b0;
    #1000 replicator_enable = 1'b0;
    #682 replicator_enable = 1'b1;
    #673983 bubble_shift_enable = 1'b1;
    */
end

endmodule
