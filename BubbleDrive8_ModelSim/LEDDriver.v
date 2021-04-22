module LEDDriver
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //Emulator signal outputs
    input   wire            nWAIT,
    input   wire    [2:0]   ACCTYPE,
    input   wire    [11:0]  CURRPAGE,
   
    //Bubble data out
    output  wire            nACCLED,
    output  wire            nWAITLED,
    output  wire            nREADLED,
    output  wire            nWRITELED,

    output  wire    [7:0]   nFND, //a b c d e f g dp
    output  wire    [2:0]   nANODE
);

assign          nACCLED = ~ACCTYPE[2];
assign          nWAITLED = nWAIT;
assign          nREADLED = ~ACCTYPE[1];
assign          nWRITELED = ~(ACCTYPE[2] & ~ACCTYPE[1] & ACCTYPE[0]);



/*
    ANODE COUNTER & WAITING LOOP COUNTER
*/

reg     [23:0]  MCLK_counter = 24'h00_0000;
reg     [3:0]   waiting_loop_counter = 4'd0;
reg     [11:0]  waiting_display = 12'd0;
reg     [2:0]   anode_shifter = 3'b011;
assign          nANODE = anode_shifter;

always @(posedge MCLK)
begin
    if(MCLK_counter == 24'hFF_FFFF)
    begin
        MCLK_counter <= 24'h0;
    end
    else
    begin
        MCLK_counter <= MCLK_counter + 24'h1;
    end
end

always @(posedge MCLK)
begin
    if(MCLK_counter[9:0] == 10'd1023)
    begin
        anode_shifter[1:0] <= anode_shifter[2:1];
        anode_shifter[2] <= anode_shifter[0];
    end
    
    if(MCLK_counter == 24'hFF_FFFF)
    begin
        if(waiting_loop_counter < 4'd10)
        begin
            waiting_loop_counter <= waiting_loop_counter + 4'd1;
        end
        else
        begin
            waiting_loop_counter <= 4'd0;
        end
    end
end

always @(posedge MCLK)
begin
    case(waiting_loop_counter)
        4'd0: waiting_display <= {4'h0, 4'h7, 4'h7};

        4'd1: waiting_display <= {4'h6, 4'h0, 4'h7};
        4'd2: waiting_display <= {4'h6, 4'h7, 4'h0};
        4'd3: waiting_display <= {4'h6, 4'h7, 4'h1};

        4'd4: waiting_display <= {4'h7, 4'h6, 4'h2};
        4'd5: waiting_display <= {4'h7, 4'h6, 4'h3};

        4'd6: waiting_display <= {4'h7, 4'h3, 4'h6};
        4'd7: waiting_display <= {4'h3, 4'h7, 4'h6};
        4'd8: waiting_display <= {4'h4, 4'h7, 4'h6};
        4'd9: waiting_display <= {4'h5, 4'h7, 4'h6};

        default: waiting_display <= {4'h7, 4'h7, 4'h7};
    endcase
end



/*
     MULTIPLEXTER & FND DECODER
*/

wire    [11:0]  value_in;
assign          value_in = (nWAIT == 1'b0) ? waiting_display : CURRPAGE;
wire    [4:0]   decoder_in;
assign          decoder_in[4] = (nWAIT == 1'b0) ? 1'b1 : 1'b0;
assign          decoder_in[3:0] = (anode_shifter == 3'b011) ? value_in[11:8] : 
                                  (anode_shifter == 3'b101) ? value_in[7:4] :
                                  (anode_shifter == 3'b110) ? value_in[3:0] : 4'h17;

/*
    00h : 0
    01h : 1
    02h : 2 
    ...
    0Fh : F
    10h : FND LED A
    11h : FND LED B
    ...
    16h : FND LED G
    17h - 1Eh : blank
    1Fh : decimal point
*/

always @(*)
begin
    case(decoder_in)
        5'b00000: nFND <= 8'b00000011;
        5'b00001: nFND <= 8'b10011111;
        5'b00010: nFND <= 8'b00100101;
        5'b00011: nFND <= 8'b00001101;
        5'b00100: nFND <= 8'b10011001;
        5'b00101: nFND <= 8'b01001001;
        5'b00110: nFND <= 8'b01000001;
        5'b00111: nFND <= 8'b00011011;
        5'b01000: nFND <= 8'b00000001;
        5'b01001: nFND <= 8'b00001001;
        5'b01010: nFND <= 8'b00010001;
        5'b01011: nFND <= 8'b11000001;
        5'b01100: nFND <= 8'b11100101;
        5'b01101: nFND <= 8'b10000101;
        5'b01110: nFND <= 8'b01100001;
        5'b01111: nFND <= 8'b01110001;
        5'b10000: nFND <= 8'b01111111;
        5'b10001: nFND <= 8'b10111111;
        5'b10010: nFND <= 8'b11011111;
        5'b10011: nFND <= 8'b11101111;
        5'b10100: nFND <= 8'b11110111;
        5'b10101: nFND <= 8'b11111011;
        5'b10110: nFND <= 8'b11111101;
        5'b10111: nFND <= 8'b11111111;
        5'b11000: nFND <= 8'b11111111;
        5'b11001: nFND <= 8'b11111111;
        5'b11010: nFND <= 8'b11111111;
        5'b11011: nFND <= 8'b11111111;
        5'b11100: nFND <= 8'b11111111;
        5'b11101: nFND <= 8'b11111111;
        5'b11110: nFND <= 8'b11111111;
        5'b11111: nFND <= 8'b11111110;
    endcase
end


/*
//A
assign nFND[7] = (~decoder_in[3] & ~decoder_in[2] & ~decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & ~decoder_in[1]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[2] & decoder_in[1]) | 
                 (~decoder_in[4] & ~decoder_in[2] & ~decoder_in[0]);

//B
assign nFND[6] = (~decoder_in[3] & ~decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & ~decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[2] & ~decoder_in[0]);

//C
assign nFND[5] = (decoder_in[4] & ~decoder_in[3] & ~decoder_in[2] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & decoder_in[1]) | 
                 (~decoder_in[4] & ~decoder_in[2] & ~decoder_in[1]);

//D
assign nFND[4] = (~decoder_in[3] & ~decoder_in[2] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[2] & ~decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[2] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[2] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[1]);

//E
assign nFND[3] = (decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[2] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & decoder_in[1]) | 
                 (~decoder_in[4] & decoder_in[3] & decoder_in[2]) | 
                 (~decoder_in[4] & ~decoder_in[2] & ~decoder_in[0]);

//F
assign nFND[2] = (~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & ~decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & ~decoder_in[1]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & decoder_in[1]) | 
                 (~decoder_in[4] & decoder_in[2] & decoder_in[1]);

//G
assign nFND[1] = (~decoder_in[3] & decoder_in[2] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[2] & decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[1] & decoder_in[0]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[2] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & ~decoder_in[1]) | 
                 (~decoder_in[4] & ~decoder_in[3] & decoder_in[1] & ~decoder_in[0]) | 
                 (~decoder_in[4] & decoder_in[3] & ~decoder_in[2] & decoder_in[1]) | 
                 (~decoder_in[4] & decoder_in[3] & decoder_in[2]);

//decimal point
assign nFND[0] = (decoder_in[4] & decoder_in[3] & decoder_in[2] & decoder_in[1] & decoder_in[0]);
*/

endmodule