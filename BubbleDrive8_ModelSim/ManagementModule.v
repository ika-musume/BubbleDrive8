
module ManagementModule
(
    //Master clock
    input   wire            master_clock, //48MHz master clock

    //Data from/to the BUBBLE SYSTEM board
    input   wire            power_good,

    //Data to BubbleInterface
    output  reg             bubble_interface_enable, //active low
    output  reg     [2:0]   image_number, //management module latches them at the very initial time of total boot process

    //On-board components
    input   wire    [2:0]   image_dip_switch
);

always @(posedge master_clock)
begin
    if(power_good == 1'b0)
    begin
        bubble_interface_enable <= 1'b0;
        image_number <= image_dip_switch;
    end
    else
    begin
        bubble_interface_enable <= 1'b1;
        image_number <= image_dip_switch;
    end
end

endmodule