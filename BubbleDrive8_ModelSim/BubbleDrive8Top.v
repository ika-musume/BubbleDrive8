module BubbleDrive8Top
(
    input   wire            master_clock,
    output  wire            clock_out,
    
    input   wire            bubble_shift_enable,
    input   wire            replicator_enable,
    input   wire            bootloop_enable,

    input   wire            power_good,

    input   wire    [2:0]   image_dip_switch,

    output  wire            bubble_out_odd,
    output  wire            bubble_out_even,


    input   wire    [10:0]  bubble_buffer_write_address,
    input   wire    [1:0]   bubble_buffer_write_data_input,
    input   wire            bubble_buffer_write_enable,
    input   wire            bubble_buffer_write_clock,
    output  wire            load_page,
    output  wire            load_bootloader
);

wire            position_change;
wire            data_out_strobe;
wire            data_out_notice;
wire            position_latch;
wire            bootloader_select;
wire            coil_run;

wire            bubble_interface_enable;
wire    [2:0]   image_number;

wire            convert;
wire    [11:0]  bubble_position_wire;
wire    [11:0]  bubble_page_wire;


ManagementModule        ManagementModule        (.master_clock(master_clock), .power_good(power_good), .bubble_interface_enable(bubble_interface_enable), .image_number(image_number), .image_dip_switch(image_dip_switch));


TimingGenerator         TimingGenerator_0       (.master_clock(master_clock), .clock_out(clock_out),
                                                .bubble_shift_enable(bubble_shift_enable), .replicator_enable(replicator_enable), .bootloop_enable(bootloop_enable),
                                                .position_change(position_change), .data_out_strobe(data_out_strobe), .data_out_notice(data_out_notice), .position_latch(position_latch), .bootloader_select(bootloader_select), .coil_run(coil_run));

BubbleInterface         BubbleInterface_0       (.master_clock(master_clock), .bubble_interface_enable(bubble_interface_enable), /*.image_number(image_number),*/
                                                .position_change(position_change), .data_out_strobe(data_out_strobe), .data_out_notice(data_out_notice), .position_latch(position_latch), .bootloader_select(bootloader_select), .coil_run(coil_run),
                                                .convert(convert), .bubble_position_output(bubble_position_wire), /*.bubble_page_input(bubble_page_wire),*/

                                                /*.start_of_page_address(start_of_page_address),*/ .bubble_buffer_write_address(bubble_buffer_write_address), .bubble_buffer_write_data_input(bubble_buffer_write_data_input),
                                                .bubble_buffer_write_enable(bubble_buffer_write_enable), .bubble_buffer_write_clock(bubble_buffer_write_clock), .load_page(load_page), .load_bootloader(load_bootloader),

                                                .bubble_out_odd(bubble_out_odd), .bubble_out_even(bubble_out_even));

PositionPageConverter   PositionPageConverter_0 (.convert(convert), .bubble_position_input(bubble_position_wire), .current_page_output(bubble_page_wire));

endmodule
