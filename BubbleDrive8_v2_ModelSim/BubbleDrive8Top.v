module BubbleDrive8Top
(
    //clock related
    input   wire            master_clock,
    output  wire            clock_out,
    
    //control signal
    input   wire            bubble_shift_enable,
    input   wire            replicator_enable,
    input   wire            bootloop_enable,

    //signals from motherboard
    input   wire            power_good,
    output  wire            temperature_low,

    //onboard components
    input   wire    [2:0]   image_dip_switch,

    //bubble data output
    output  wire            bubble_out_odd,
    output  wire            bubble_out_even,

    //W25Q32
    output  wire            CS,
    output  wire            MOSI,
    input   wire            MISO,
    output  wire            WP,
    output  wire            HOLD,
    output  wire            CLK
);

//To BubbleInterface
wire            position_change;
wire            data_out_strobe;
wire            position_latch;
wire            page_select;
wire            coil_enable;
wire            bubble_module_enable;

//To PositionPageConverter
wire            convert;
wire    [11:0]  bubble_position_wire;
wire    [11:0]  bubble_page_wire;

//To SPILoader
wire    [2:0]   image_number;
wire            load_page;
wire            load_bootloader;

//SPILoader buffer
wire    [1:0]   bubble_buffer_write_data_wire;
wire    [10:0]  bubble_buffer_write_address;
wire            bubble_buffer_write_enable;
wire            bubble_buffer_write_clock;


//test
wire            bubble_data_out_clock;


ManagementModule        ManagementModule        (.master_clock(master_clock), .power_good(power_good), .temperature_low(temperature_low), .bubble_module_enable(bubble_module_enable), .image_number(image_number), .image_dip_switch(image_dip_switch));


TimingGenerator         TimingGenerator_0       (.master_clock(master_clock), .clock_out(clock_out), .bubble_module_enable(bubble_module_enable),
                                                .bubble_shift_enable(bubble_shift_enable), .replicator_enable(replicator_enable), .bootloop_enable(bootloop_enable),
                                                .position_change(position_change), .data_out_strobe(data_out_strobe), .position_latch(position_latch), .page_select(page_select), .coil_enable(coil_enable),
                                                
                                                .bubble_data_out_clock(bubble_data_out_clock)); //test

BubbleInterface         BubbleInterface_0       (.master_clock(master_clock), .bubble_module_enable(bubble_module_enable),
                                                .position_change(position_change), .data_out_strobe(data_out_strobe), .position_latch(position_latch), .page_select(page_select), .coil_enable(coil_enable),
                                                .convert(convert), .bubble_position_output(bubble_position_wire),

                                                .bubble_buffer_write_address(bubble_buffer_write_address), .bubble_buffer_write_data_input(bubble_buffer_write_data_wire),
                                                .bubble_buffer_write_enable(bubble_buffer_write_enable), .bubble_buffer_write_clock(bubble_buffer_write_clock), .load_page(load_page), .load_bootloader(load_bootloader),

                                                .bubble_out_odd(bubble_out_odd), .bubble_out_even(bubble_out_even),
                                                
                                                .bubble_data_out_clock(bubble_data_out_clock)); //test

PositionPageConverter   PositionPageConverter_0 (.convert(convert), .bubble_position_input(bubble_position_wire), .current_page_output(bubble_page_wire));

SPILoader               SPILoader_0             (.master_clock(master_clock), .image_number(image_number), .bubble_page_input(bubble_page_wire), .load_page(load_page), .load_bootloader(load_bootloader),

                                                .bubble_buffer_write_address(bubble_buffer_write_address), .bubble_buffer_write_data_output(bubble_buffer_write_data_wire), 
                                                .bubble_buffer_write_enable(bubble_buffer_write_enable), .bubble_buffer_write_clock(bubble_buffer_write_clock),

                                                .CS(CS), .MOSI(MOSI), .MISO(MISO), .WP(WP), .HOLD(HOLD), .CLK(CLK));

W25Q32JVxxIM            W25Q32JVxxIM            (.CSn(CS), .CLK(CLK), .DO(MISO), .DIO(MOSI), .WPn(WP), .HOLDn(HOLD), .RESETn(HOLD));

endmodule