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

localparam CLOCK = 48'd48000000;



/*
    STATE MACHINE
*/

localparam RESET = 1'b0;
localparam RUN = 1'b1;

reg             counter_state = 1'b0;

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
            TIME_ELAPSED <= 16'd0;
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
                if(TIME_ELAPSED < 16'd65535)
                begin
                    TIME_ELAPSED <= TIME_ELAPSED + 16'd1;
                    clock_counter <= 48'd0;
                end
                else
                begin
                    TIME_ELAPSED <= TIME_ELAPSED;
                    clock_counter <= clock_counter;
                    OVFL <= 1'b1;
                end
            end
        end
    endcase
end

endmodule