module TempLoader
/*

*/

(
    //input clock
    input   wire            MCLK,

    //time(sec)
    output  reg     [13:0]  TEMPDATA,

    //control
    input   wire            nLOAD,
    output  reg             nCOMPLETE,

    output  reg             nCS = 1'b1,
    inout   wire            SIO,
    output  reg             CLK = 1'b1
);



/*
    TC77 DATA LOADER
*/

//TC77 fmax = 7MHz, 48MHz / 8 = 6MHz
localparam TEMP_RESET = 4'b1111;    //리셋
localparam TEMP_RD_S0 = 4'b0000;    //CS내리기
localparam TEMP_RD_S1 = 4'b0001;    //CLK 0
localparam TEMP_RD_S2 = 4'b0010;    //nop
localparam TEMP_RD_S3 = 4'b0011;    //nop
localparam TEMP_RD_S4 = 4'b0100;    //nop
localparam TEMP_RD_S5 = 4'b0101;    //nop
localparam TEMP_RD_S6 = 4'b0110;    //nop
localparam TEMP_RD_S7 = 4'b0111;    //CLK 1, 데이터 샘플링
localparam TEMP_RD_S8 = 4'b1000;    //nop
localparam TEMP_RD_S9 = 4'b1001;    //nop
localparam TEMP_RD_S10 = 4'b1010;   //nop
localparam TEMP_RD_S11 = 4'b1011;   //nop
localparam TEMP_RD_S12 = 4'b1100;   //nop, S1로 branch할건지 S13으로 갈건지 결정
localparam TEMP_RD_S13 = 4'b1110;   //CS올리기

reg     [3:0]   spi_state = TEMP_RESET;
reg     [3:0]   spi_counter = 4'd0;

//branch control
always @(posedge MCLK) 
begin
    case(spi_state)
        TEMP_RESET:
            case(nLOAD)
                1'b0: spi_state <= TEMP_RD_S0;
                1'b1: spi_state <= TEMP_RESET;
            endcase
        TEMP_RD_S0: spi_state <= TEMP_RD_S1;
        TEMP_RD_S1: spi_state <= TEMP_RD_S2;
        TEMP_RD_S2: spi_state <= TEMP_RD_S3;
        TEMP_RD_S3: spi_state <= TEMP_RD_S4;
        TEMP_RD_S4: spi_state <= TEMP_RD_S5;
        TEMP_RD_S5: spi_state <= TEMP_RD_S6;
        TEMP_RD_S6: spi_state <= TEMP_RD_S7;
        TEMP_RD_S7: spi_state <= TEMP_RD_S8;
        TEMP_RD_S8: spi_state <= TEMP_RD_S9;
        TEMP_RD_S9: spi_state <= TEMP_RD_S10;
        TEMP_RD_S10: spi_state <= TEMP_RD_S11;
        TEMP_RD_S11: spi_state <= TEMP_RD_S12;
        TEMP_RD_S12:
            if(spi_counter < 4'd14)
            begin
                spi_state <= TEMP_RD_S1;
            end
            else
            begin
                spi_state <= TEMP_RD_S13;
            end
        TEMP_RD_S13: spi_state <= TEMP_RESET;

        default: spi_state <= TEMP_RESET;
    endcase
end

//output control
always @(posedge MCLK)
begin
    case(spi_state)
        TEMP_RESET: begin nCOMPLETE <= 1'b1; nCS <= 1'b1; CLK <= 1'b1; spi_counter <= 4'd0; end
        TEMP_RD_S0: begin nCS <= 1'b0; CLK <= 1'b1; end
        TEMP_RD_S1: begin CLK <= 1'b0; end
        TEMP_RD_S2: begin end //nop
        TEMP_RD_S3: begin end //nop
        TEMP_RD_S4: begin end //nop
        TEMP_RD_S5: begin end //nop
        TEMP_RD_S6: begin end //nop
        TEMP_RD_S7: begin CLK <= 1'b1; spi_counter <= spi_counter + 4'd1; TEMPDATA[13:1] <= TEMPDATA[12:0]; TEMPDATA[0] <= SIO; end
        TEMP_RD_S8: begin end //nop
        TEMP_RD_S9: begin end //nop
        TEMP_RD_S10: begin end //nop
        TEMP_RD_S11: begin end //nop
        TEMP_RD_S12: begin end //nop
        TEMP_RD_S13: begin nCOMPLETE <= 1'b0; nCS <= 1'b1; end

        default: begin nCOMPLETE <= 1'b1; nCS <= 1'b1; CLK <= 1'b1; spi_counter <= 4'd0; end
    endcase
end

endmodule