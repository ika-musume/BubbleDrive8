`timescale 10ps/1ps
module BubbleDrive8Top_tb;

reg             master_clock = 1'b1;
wire            clock_out;

reg             bubble_shift_enable = 1'b1;
reg             replicator_enable = 1'b1;
reg             bootloop_enable = 1'b0;

reg             power_good = 1'b0;

reg     [2:0]   image_dip_switch = 3'b000;

wire            bubble_out_odd;
wire            bubble_out_even;

reg     [10:0]  bubble_buffer_write_address = 11'd0;
reg     [1:0]   bubble_buffer_write_data_input = 2'b00;
reg             bubble_buffer_write_enable = 1'b1;
reg             bubble_buffer_write_clock = 1'b0;
wire            load_page;
wire            load_bootloader;

BubbleDrive8Top testBubbleDrive8Top
(
	.master_clock (master_clock),
    .clock_out (clock_out),

    .bubble_shift_enable (bubble_shift_enable),
    .replicator_enable (replicator_enable),
    .bootloop_enable (bootloop_enable),

    .power_good(power_good),

    .image_dip_switch(image_dip_switch),

    .bubble_out_odd(bubble_out_odd),
    .bubble_out_even(bubble_out_even),

    .bubble_buffer_write_address(bubble_buffer_write_address),
    .bubble_buffer_write_data_input(bubble_buffer_write_data_input),
    .bubble_buffer_write_enable(bubble_buffer_write_enable),
    .bubble_buffer_write_clock(bubble_buffer_write_clock),
    .load_page(load_page),
    .load_bootloader(load_bootloader)
);

always #1 master_clock = ~master_clock;

initial
begin

//bootloader
#90000 bubble_shift_enable = 1'b0;
#4387745 bubble_shift_enable = 1'b1;
#423 bootloop_enable = 1'b1;

//181
#650000 bubble_shift_enable = 1'b0;
#1139570 replicator_enable = 1'b0;
#683 replicator_enable = 1'b1;
#673986 bubble_shift_enable = 1'b1;
//182
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//183
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//184
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//185
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//186
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//187
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
//188
#75000 bubble_shift_enable = 1'b0;
#1000 replicator_enable = 1'b0;
#682 replicator_enable = 1'b1;
#673983 bubble_shift_enable = 1'b1;
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

initial
begin
#10 bubble_buffer_write_enable = 1'b0;

#1bubble_buffer_write_data_input = 2'b11;
bubble_buffer_write_address = 11'd0;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b10;
bubble_buffer_write_address = 11'd1;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b01;
bubble_buffer_write_address = 11'd2;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b00;
bubble_buffer_write_address = 11'd3;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b11;
bubble_buffer_write_address = 11'd511;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b11;
bubble_buffer_write_address = 11'd1023;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b11;
bubble_buffer_write_address = 11'd1417;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b00;
bubble_buffer_write_address = 11'd1918;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#1bubble_buffer_write_data_input = 2'b00;
bubble_buffer_write_address = 11'd1919;
#1 bubble_buffer_write_clock = 1'b1;
#1 bubble_buffer_write_clock = 1'b0;

#10 bubble_buffer_write_enable = 1'b1;
end

endmodule
