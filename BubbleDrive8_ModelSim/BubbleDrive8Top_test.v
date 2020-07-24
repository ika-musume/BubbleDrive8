`timescale 10ns/10ns
module BubbleDrive8Top_tb;

reg             master_clock = 1'b1;
wire            clock_out;

reg             bubble_shift_enable = 1'b1;
reg             replicator_enable = 1'b1;
reg             bootloop_enable = 1'b0;

reg             power_good = 1'b1;
wire            temperature_low;

reg     [2:0]   image_dip_switch = 3'b111;

wire            bubble_out_odd;
wire            bubble_out_even;


BubbleDrive8Top testBubbleDrive8Top
(
	.master_clock (master_clock),
    .clock_out (clock_out),

    .bubble_shift_enable (bubble_shift_enable),
    .replicator_enable (replicator_enable),
    .bootloop_enable (bootloop_enable),

    .power_good(power_good),
    .temperature_low(temperature_low),

    .image_dip_switch(image_dip_switch),

    .bubble_out_odd(bubble_out_odd),
    .bubble_out_even(bubble_out_even)
);

always #1 master_clock = ~master_clock;

initial
begin
    #300000 power_good = 1'b0;
end


always @(posedge temperature_low)
begin
    //bootloader
    #50000 bubble_shift_enable = 1'b0;
    #4387745 bubble_shift_enable = 1'b1;
    #423 bootloop_enable = 1'b1;

    //181
    #650000 bubble_shift_enable = 1'b0;
    #1139570 replicator_enable = 1'b0;
    #683 replicator_enable = 1'b1;
    #673978 bubble_shift_enable = 1'b1;
    //182
    #75000 bubble_shift_enable = 1'b0;
    #999 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673977 bubble_shift_enable = 1'b1;
    //183
    #75000 bubble_shift_enable = 1'b0;
    #998 replicator_enable = 1'b0;
    #684 replicator_enable = 1'b1;
    #673978 bubble_shift_enable = 1'b1;
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
end

endmodule