module TimeCounter
/*
    
*/

(
    //input clock
    input   wire            MCLK,

    //time(sec)
    output  reg     [15:0]  TIMEELAPSED,     //16bit unsigned time

    //controlreset
    input   wire            nRESET,           //reset
    input   wire            nSTART,           //start
    output  reg             OVFL              //overflow
);

localparam CLOCK = 48'd8192; //00000;



/*
    STATE MACHINE
*/

localparam RESET = 1'b0;
localparam RUN = 1'b1;

reg             counter_state = RESET;

always @(posedge MCLK)
begin
    case(counter_state)
        RESET:
        begin
            if(nSTART == 1'b0)
            begin
                counter_state <= RUN;
            end
        end
        RUN:
        begin
            if(nRESET == 1'b0)
            begin
                counter_state <= RESET;
            end
        end
    endcase
end



/*
    COUNTER
*/

reg     [47:0]  clock_counter = 48'd0;

always @(posedge MCLK)
begin
    case(counter_state)
        RESET:
        begin
            TIMEELAPSED <= 16'd0;
            clock_counter <= 18'd0;
            OVFL <= 1'b0;
        end
        RUN:
        begin
            if(clock_counter < CLOCK)
            begin
                clock_counter <= clock_counter + 48'd1;
            end
            else
            begin
                if(TIMEELAPSED < 16'd65535)
                begin
                    TIMEELAPSED <= TIMEELAPSED + 16'd1;
                    clock_counter <= 48'd0;
                end
                else
                begin
                    TIMEELAPSED <= TIMEELAPSED;
                    clock_counter <= clock_counter;
                    OVFL <= 1'b1;
                end
            end
        end
    endcase
end

endmodule