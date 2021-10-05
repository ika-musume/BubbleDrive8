module BubbleDrive8_usb
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //FIFO/MPSSE mode select
    input   wire            nFIFOEN,
    input   wire            nMPSSEEN,

    //4bit width mode
    input   wire            BITWIDTH4,

    //FIFO buffer interface
    input   wire            nFIFOBUFWRCLKEN,
    input   wire    [12:0]  FIFOBUFWRADDR,   //13bit addr = 8k * 1bit
    input   wire            FIFOBUFWRDATA,
    input   wire            nFIFOSENDBOOT,
    input   wire            nFIFOSENDUSER,
    input   wire    [11:0]  FIFORELPAGE,

    //MPSSE input/output
    output  wire            MPSSECLK,
    output  wire            MPSSEMOSI,
    input   wire            MPSSEMISO,
    output  wire            nMPSSECS,

    //FT232HL
    inout   wire    [7:0]   ADBUS,
    inout   wire    [5:0]   ACBUS
);



/*
    FIFO / MPSSE MUX
*/

/*
       MODE----------------+
                           |
    +-------------+    +---v---+              +--------+
    |             |    |       |              |        |
    |   W25Q32    |    |       |              |        |
    |  Flash ROM  |<-->|MPSSE  |     ADBUS    |        |
    |             |    |       |<------------>|        |
    +-------------+    |       |              |        |
                       |  BUS  |              |        |
                       |       |     ACBUS    | FT232H |<------->PC
                       |  MUX  |<------------>|        |
    +-------------+    |       <--------------|        |
    |             |    |       |   /MPSSEEN   |        |
    |  FIFO DATA  |--->|FIFO   |              |        |
    | transmitter |    |       |              |        |
    |             |    |       |              |        |
    +-------------+    +-------+              +--------+
*/

//enable signals(active low)
wire            fifo_output_driver_enable = nFIFOEN;
wire            mpsse_connection_enable = nMPSSEEN;
wire            nMPSSERQ;

//declare fifo variables
reg     [7:0]   FIFO_OUTLATCH;          //ADBUS0-7
wire            nFIFORXF;               //ACBUS0
wire            nFIFOTXE;               //ACBUS1
reg             nFIFORD = 1'b1;         //ACBUS2
reg             nFIFOWR = 1'b1;         //ACBUS3
reg             nFIFOSIWU = 1'b1;       //ACBUS4

//MPSSE input / output driver
assign MPSSECLK = (mpsse_connection_enable == 1'b0) ? ADBUS[0] : 1'b1; //prevent unintended access
assign MPSSEMOSI = (mpsse_connection_enable == 1'b0) ? ADBUS[1] : 1'b0;
assign ADBUS[2] = (mpsse_connection_enable == 1'b0) ? MPSSEMISO : 1'bZ;
assign nMPSSECS = (mpsse_connection_enable == 1'b0) ? ADBUS[3] : 1'b1;

//FIFO input / output driver
assign ADBUS = (fifo_output_driver_enable == 1'b0) ? FIFO_OUTLATCH : 8'bZZZZ_ZZZZ;
assign nFIFORXF = ACBUS[0];
assign nFIFOTXE = ACBUS[1];
assign ACBUS[2] = (fifo_output_driver_enable == 1'b0) ? nFIFORD : 1'bZ; //set pull-up resistor on the pin
assign ACBUS[3] = (fifo_output_driver_enable == 1'b0) ? nFIFOWR : 1'bZ;
assign ACBUS[4] = (fifo_output_driver_enable == 1'b0) ? nFIFOSIWU : 1'bZ;
assign nMPSSERQ = ACBUS[5];




/*
    SIPO Buffer for serial to parallel conversion
*/

reg     [9:0]   sipo_buffer_addr = 10'd0;
wire    [7:0]   sipo_buffer_data;
reg             sipo_buffer_read_en = 1'b1;

SIPOBuffer SIPOBuffer_0
(
    .MCLK               (MCLK               ),

    .SIPOWRADDR         (FIFOBUFWRADDR      ),
    .SIPOWRDATA         (FIFOBUFWRDATA      ),
    .nSIPOWRCLKEN       (nFIFOBUFWRCLKEN    ),

    .SIPORDADDR         (sipo_buffer_addr   ),
    .SIPORDDATA         (sipo_buffer_data   ),
    .nSIPORDCLKEN       (sipo_buffer_read_en)
);



/*
    FIFO ASCII message memory
*/
reg             text_read_en = 1'b0;
reg     [6:0]   text_addr = 7'h0;
wire    [7:0]   text_output;

TEXTROM TEXTROM_0
(
    .MCLK               (MCLK               ),
    .nCLKEN             (text_read_en       ),
    .ADDR               (text_addr          ),
    .DATA               (text_output        )
);



/*
    FIFO transmitter
*/

reg     [23:0]  ascii_page_number = 24'h0;

reg     [11:0]  line_v_counter = 8'd0;
reg     [7:0]   line_h_counter = 8'd0; 

//declare states
localparam FIFO_IDLE_S0 = 8'b0000_0001;                  //FIFO 버스에 13(carriage return) 올리기
localparam FIFO_IDLE_S1 = 8'b0000_0010;                  //jsr, return 레지스터에 현재 state+1 넣기
localparam FIFO_IDLE_S2 = 8'b0000_0011;                  //nop

localparam FIFO_RESET = 8'b0000_0000;                    //최초 리셋

//TITLE MESSAGE
localparam FIFO_PRNTMESSAGE_S0 = 8'b0010_0000;           //루프 횟수 set, 스트링 시작 어드레스 set
localparam FIFO_PRNTMESSAGE_S1 = 8'b0010_0001;           //루프 카운터가 0 되면 S6으로 가기
localparam FIFO_PRNTMESSAGE_S2 = 8'b0010_0010;           //메시지 롬 read = 0
localparam FIFO_PRNTMESSAGE_S3 = 8'b0010_0011;           //메시지 롬 read = 1
localparam FIFO_PRNTMESSAGE_S4 = 8'b0010_0100;           //메시지 가져다가 FIFO 버스에 올리기, jsr(return 레지스터에 현재 state+1 넣기)
localparam FIFO_PRNTMESSAGE_S5 = 8'b0010_0101;           //S1으로 가기
localparam FIFO_PRNTMESSAGE_S6 = 8'b0010_0110;           //부트로더 v루프 설정하고 FIFO_PRNTDATA_S0로 가기, 페이지 v루프 설정하고 PRNTPAGENUM_S0으로 가기
 
//PRINT PAGE NUMBER 
localparam FIFO_PRNTPAGENUM_S0 = 8'b0100_0000;           //digit 2 값을 갖다가 FIFO 어드레스에 넣기, FIFO ROM read = 0
localparam FIFO_PRNTPAGENUM_S1 = 8'b0100_0001;           //digit 1 값을 갖다가 FIFO 어드레스에 넣기
localparam FIFO_PRNTPAGENUM_S2 = 8'b0100_0010;           //digit 0 값을 갖다가 FIFO 어드레스에 넣기, digit 2 변환값을 ascii_page_number에 넣기
localparam FIFO_PRNTPAGENUM_S3 = 8'b0100_0011;           //digit 1 변환값을 ascii_page_number에 넣기
localparam FIFO_PRNTPAGENUM_S4 = 8'b0100_0100;           //digit 0 변환값을 ascii_page_number에 넣기, FIFO ROM read = 1

localparam FIFO_PRNTPAGENUM_S5 = 8'b0100_0101;           //digit 2 변환값을 FIFO 버스에 올리기
localparam FIFO_PRNTPAGENUM_S6 = 8'b0100_0110;           //jsr(return 레지스터에 현재 state+1 넣기)
localparam FIFO_PRNTPAGENUM_S7 = 8'b0100_0111;           //digit 1 변환값을 FIFO 버스에 올리기
localparam FIFO_PRNTPAGENUM_S8 = 8'b0100_1000;           //jsr(return 레지스터에 현재 state+1 넣기)
localparam FIFO_PRNTPAGENUM_S9 = 8'b0100_1001;           //digit 0 변환값을 FIFO 버스에 올리기, 
localparam FIFO_PRNTPAGENUM_S10 = 8'b0100_1010;          //jsr(return 레지스터에 현재 state+1 넣기)
localparam FIFO_PRNTPAGENUM_S11 = 8'b0100_1011;          //FIFO 버스에 13(carriage return) 올리기
localparam FIFO_PRNTPAGENUM_S12 = 8'b0100_1100;          //jsr, return 레지스터에 현재 state+1 넣기

localparam FIFO_PRNTPAGENUM_S13 = 8'b0100_1101;          //FIFO_PRNTDATA_S0로 가기

//DATA BLOCK TRANSFER
localparam FIFO_PRNTDATA_S0 = 8'b0110_0000;              //스트링 시작 어드레스 set

localparam FIFO_PRNTDATA_S1 = 8'b0110_0001;              //v루프 카운터가 다 차면 FIFO_IDLE으로 가기
localparam FIFO_PRNTDATA_S2 = 8'b0110_0010;              //h루프 횟수 set

localparam FIFO_PRNTDATA_S3 = 8'b0110_0011;              //h루프 카운터가 다 차면 FIFO_PRNTDATA_S17로 가기, 
localparam FIFO_PRNTDATA_S4 = 8'b0110_0100;              //SIPO RAM read = 0
localparam FIFO_PRNTDATA_S5 = 8'b0110_0101;              //SIPO RAM read = 1

localparam FIFO_PRNTDATA_S6 = 8'b0110_0110;              //상위 4비트 값을 갖다가 FIFO 어드레스에 넣기 FIFO ROM read = 0
localparam FIFO_PRNTDATA_S7 = 8'b0110_0111;              //FIFO ROM read = 1
localparam FIFO_PRNTDATA_S8 = 8'b0110_1000;              //상위 4비트 변환값을 갖다가 FIFO 버스에 올리기
localparam FIFO_PRNTDATA_S9 = 8'b0110_1001;              //jsr, return 레지스터에 현재 state+1 넣기

localparam FIFO_PRNTDATA_S10 = 8'b0110_1010;             //하위 4비트 값을 갖다가 FIFO 어드레스에 넣기, FIFO ROM read = 0
localparam FIFO_PRNTDATA_S11 = 8'b0110_1011;             //FIFO ROM read = 1
localparam FIFO_PRNTDATA_S12 = 8'b0110_1100;             //하위 4비트 변환값을 갖다가 FIFO 버스에 올리기
localparam FIFO_PRNTDATA_S13 = 8'b0110_1101;             //jsr, return 레지스터에 현재 state+1 넣기

localparam FIFO_PRNTDATA_S14 = 8'b0110_1110;             //FIFO 버스에 20(space) 올리기
localparam FIFO_PRNTDATA_S15 = 8'b0110_1111;             //jsr, return 레지스터에 현재 state+1 넣기

localparam FIFO_PRNTDATA_S16 = 8'b0111_0000;             //SIPO RAM 어드레스 증가, h루프 카운터 감소, S3으로 되돌아가기

localparam FIFO_PRNTDATA_S17 = 8'b0111_0001;             //FIFO 버스에 13(carriage return) 올리기
localparam FIFO_PRNTDATA_S18 = 8'b0111_0010;             //jsr, return 레지스터에 현재 state+1 넣기
localparam FIFO_PRNTDATA_S19 = 8'b0111_0011;             //v루프 카운터 감소, S1로 되돌아가기

//FIFO TX
localparam FIFO_TX_S0 = 8'b1110_0000;                    //TXE가 LO인지 체크해서 LO이면 S1, 아니면 S0
localparam FIFO_TX_S1 = 8'b1110_0001;                    //FIFO WR = 0
localparam FIFO_TX_S2 = 8'b1110_0010;                    //nop
localparam FIFO_TX_S3 = 8'b1110_0011;                    //FIFO WR = 1, rts

reg     [7:0]   fifo_state = FIFO_RESET;
reg     [7:0]   return_fifo_state = FIFO_RESET;

//state flow control
always @(posedge MCLK)
begin
    case (fifo_state)
        FIFO_IDLE_S0: 
            fifo_state <= FIFO_IDLE_S1;
        FIFO_IDLE_S1: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_IDLE_S2;
        end
        FIFO_IDLE_S2: 
            if(nFIFOSENDBOOT && nFIFOSENDUSER == 1'b1)  begin fifo_state <= FIFO_RESET; end
            else                                        begin fifo_state <= FIFO_IDLE_S2; end


        FIFO_RESET: begin
            if(fifo_output_driver_enable == 1'b1)
            begin
                fifo_state <= FIFO_RESET; 
            end
            else
            begin
                return_fifo_state <= FIFO_RESET;
                if(nFIFOSENDBOOT == 1'b0)           begin fifo_state <= FIFO_PRNTMESSAGE_S0; end
                else if(nFIFOSENDUSER == 1'b0)      begin fifo_state <= FIFO_PRNTMESSAGE_S0; end
                else                                begin fifo_state <= FIFO_RESET; end
            end
        end


        FIFO_PRNTMESSAGE_S0: fifo_state <= FIFO_PRNTMESSAGE_S1;
        FIFO_PRNTMESSAGE_S1: 
            if(line_h_counter == 8'd0)          begin fifo_state <= FIFO_PRNTMESSAGE_S6; end
            else                                begin fifo_state <= FIFO_PRNTMESSAGE_S2; end
        FIFO_PRNTMESSAGE_S2: fifo_state <= FIFO_PRNTMESSAGE_S3;
        FIFO_PRNTMESSAGE_S3: fifo_state <= FIFO_PRNTMESSAGE_S4;
        FIFO_PRNTMESSAGE_S4: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTMESSAGE_S5;
        end
        FIFO_PRNTMESSAGE_S5: fifo_state <= FIFO_PRNTMESSAGE_S1;
        FIFO_PRNTMESSAGE_S6:
            if(nFIFOSENDBOOT == 1'b0)           begin fifo_state <= FIFO_PRNTDATA_S0; end
            else if(nFIFOSENDUSER == 1'b0)      begin fifo_state <= FIFO_PRNTPAGENUM_S0; end
            else                                begin fifo_state <= FIFO_RESET; end


        FIFO_PRNTPAGENUM_S0: fifo_state <= FIFO_PRNTPAGENUM_S1;
        FIFO_PRNTPAGENUM_S1: fifo_state <= FIFO_PRNTPAGENUM_S2;
        FIFO_PRNTPAGENUM_S2: fifo_state <= FIFO_PRNTPAGENUM_S3;
        FIFO_PRNTPAGENUM_S3: fifo_state <= FIFO_PRNTPAGENUM_S4;
        FIFO_PRNTPAGENUM_S4: fifo_state <= FIFO_PRNTPAGENUM_S5;
        FIFO_PRNTPAGENUM_S5: fifo_state <= FIFO_PRNTPAGENUM_S6;
        FIFO_PRNTPAGENUM_S6: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTPAGENUM_S7;
        end
        FIFO_PRNTPAGENUM_S7: fifo_state <= FIFO_PRNTPAGENUM_S8;
        FIFO_PRNTPAGENUM_S8: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTPAGENUM_S9;
        end
        FIFO_PRNTPAGENUM_S9: fifo_state <= FIFO_PRNTPAGENUM_S10;
        FIFO_PRNTPAGENUM_S10: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTPAGENUM_S11;
        end
        FIFO_PRNTPAGENUM_S11: fifo_state <= FIFO_PRNTPAGENUM_S12;
        FIFO_PRNTPAGENUM_S12: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTPAGENUM_S13;
        end
        FIFO_PRNTPAGENUM_S13: fifo_state <= FIFO_PRNTDATA_S0;


        FIFO_PRNTDATA_S0: fifo_state <= FIFO_PRNTDATA_S1;
        FIFO_PRNTDATA_S1:
            if(line_v_counter == 8'd0)          begin fifo_state <= FIFO_IDLE_S0; end
            else                                begin fifo_state <= FIFO_PRNTDATA_S2; end
        FIFO_PRNTDATA_S2: fifo_state <= FIFO_PRNTDATA_S3;

        FIFO_PRNTDATA_S3: 
            if(line_h_counter == 8'd0)          begin fifo_state <= FIFO_PRNTDATA_S17; end
            else                                begin fifo_state <= FIFO_PRNTDATA_S4; end
        FIFO_PRNTDATA_S4: fifo_state <= FIFO_PRNTDATA_S5;
        FIFO_PRNTDATA_S5: fifo_state <= FIFO_PRNTDATA_S6;

        FIFO_PRNTDATA_S6: fifo_state <= FIFO_PRNTDATA_S7;
        FIFO_PRNTDATA_S7: fifo_state <= FIFO_PRNTDATA_S8;
        FIFO_PRNTDATA_S8: fifo_state <= FIFO_PRNTDATA_S9;
        FIFO_PRNTDATA_S9: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTDATA_S10;
        end

        FIFO_PRNTDATA_S10: fifo_state <= FIFO_PRNTDATA_S11;
        FIFO_PRNTDATA_S11: fifo_state <= FIFO_PRNTDATA_S12;
        FIFO_PRNTDATA_S12: fifo_state <= FIFO_PRNTDATA_S13;
        FIFO_PRNTDATA_S13: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTDATA_S14;
        end

        FIFO_PRNTDATA_S14: fifo_state <= FIFO_PRNTDATA_S15;
        FIFO_PRNTDATA_S15: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTDATA_S16;
        end

        FIFO_PRNTDATA_S16: fifo_state <= FIFO_PRNTDATA_S3;

        FIFO_PRNTDATA_S17: fifo_state <= FIFO_PRNTDATA_S18;
        FIFO_PRNTDATA_S18: begin
            fifo_state <= FIFO_TX_S0;
            return_fifo_state <= FIFO_PRNTDATA_S19;
        end
        FIFO_PRNTDATA_S19: fifo_state <= FIFO_PRNTDATA_S1;


        FIFO_TX_S0: 
            if(nFIFOSENDBOOT && nFIFOSENDUSER == 1'b1) 
            begin 
                fifo_state <= FIFO_RESET; 
            end
            else 
            begin
                if(nFIFOTXE == 1'b1) 
                begin 
                    fifo_state <= FIFO_TX_S0;
                end
                else
                begin
                    fifo_state <= FIFO_TX_S1;
                end
            end
        FIFO_TX_S1: fifo_state <= FIFO_TX_S2;
        FIFO_TX_S2: fifo_state <= FIFO_TX_S3;
        FIFO_TX_S3: fifo_state <= return_fifo_state;

        default: fifo_state <= FIFO_RESET;
    endcase
end


//output control
always @(posedge MCLK)
begin
    case (fifo_state)
        FIFO_IDLE_S0: 
            FIFO_OUTLATCH <= 8'h13;
        FIFO_IDLE_S1: ;
        FIFO_IDLE_S2: ;


        FIFO_RESET: begin
            FIFO_OUTLATCH <= 8'h20;
            line_h_counter <= 8'd0;
            line_v_counter <= 8'd0;
            text_addr <= 7'h00;
            text_read_en <= 1'b1;
            sipo_buffer_addr <= 10'h000;
            sipo_buffer_read_en <= 1'b1;
        end


        FIFO_PRNTMESSAGE_S0: 
            if(nFIFOSENDBOOT == 1'b0)           begin line_h_counter <= 8'd51; text_addr <= 7'h10; end
            else if (nFIFOSENDUSER == 1'b0)     begin line_h_counter <= 8'd12; text_addr <= 7'h50; end
            else                                begin end
        FIFO_PRNTMESSAGE_S1: ;
        FIFO_PRNTMESSAGE_S2: 
            text_read_en <= 1'b0;
        FIFO_PRNTMESSAGE_S3: 
            text_read_en <= 1'b1;
        FIFO_PRNTMESSAGE_S4: begin 
            FIFO_OUTLATCH <= text_output;
        end
        FIFO_PRNTMESSAGE_S5: begin
            text_addr <= text_addr + 7'h1;
            line_h_counter <= line_h_counter - 8'd1;
        end
        FIFO_PRNTMESSAGE_S6:
            if(nFIFOSENDBOOT == 1'b0)           begin line_v_counter <= 8'd30; sipo_buffer_addr <= 10'h0; end
            else if (nFIFOSENDUSER == 1'b0)     begin line_v_counter <= 8'd8; sipo_buffer_addr <= 10'h0; end
            else                                begin end


        FIFO_PRNTPAGENUM_S0: begin
            text_read_en <= 1'b0;
            text_addr <= {3'b000, FIFORELPAGE[11:8]};
        end
        FIFO_PRNTPAGENUM_S1: begin
            text_addr <= {3'b000, FIFORELPAGE[7:4]};
        end
        FIFO_PRNTPAGENUM_S2: begin
            ascii_page_number[23:16] <= text_output;
            text_addr <= {3'b000, FIFORELPAGE[3:0]};
        end
        FIFO_PRNTPAGENUM_S3: begin
            ascii_page_number[15:8] <= text_output;
        end
        FIFO_PRNTPAGENUM_S4: begin
            ascii_page_number[7:0] <= text_output;
            text_read_en <= 1'b1;
        end
        FIFO_PRNTPAGENUM_S5: begin
            FIFO_OUTLATCH <= ascii_page_number[23:16];
        end
        FIFO_PRNTPAGENUM_S6: ;
        FIFO_PRNTPAGENUM_S7: begin
            FIFO_OUTLATCH <= ascii_page_number[15:8];
        end
        FIFO_PRNTPAGENUM_S8: ;
        FIFO_PRNTPAGENUM_S9: begin
            FIFO_OUTLATCH <= ascii_page_number[7:0];
        end
        FIFO_PRNTPAGENUM_S10: ;
        FIFO_PRNTPAGENUM_S11: 
            FIFO_OUTLATCH <= 8'h13;
        FIFO_PRNTPAGENUM_S12: ;
        FIFO_PRNTPAGENUM_S13: ;


        FIFO_PRNTDATA_S0:
            sipo_buffer_addr <= 10'd0;
        FIFO_PRNTDATA_S1: ;
        FIFO_PRNTDATA_S2:
            line_h_counter <= 8'd16;
        FIFO_PRNTDATA_S3: ;
        FIFO_PRNTDATA_S4:
            sipo_buffer_read_en <= 1'b0;
        FIFO_PRNTDATA_S5:
            sipo_buffer_read_en <= 1'b1;

        FIFO_PRNTDATA_S6: begin
            text_addr <= {3'b000, sipo_buffer_data[7:4]};
            text_read_en <= 1'b0;
        end
        FIFO_PRNTDATA_S7: 
            text_read_en <= 1'b1;
        FIFO_PRNTDATA_S8:
            FIFO_OUTLATCH <= text_output;   
        FIFO_PRNTDATA_S9: ;

        FIFO_PRNTDATA_S10: begin
            text_addr <= {3'b000, sipo_buffer_data[3:0]};
            text_read_en <= 1'b0;
        end
        FIFO_PRNTDATA_S11:
            text_read_en <= 1'b1;
        FIFO_PRNTDATA_S12:
            FIFO_OUTLATCH <= text_output;  
        FIFO_PRNTDATA_S13: ;

        FIFO_PRNTDATA_S14:
            FIFO_OUTLATCH <= 8'h20;
        FIFO_PRNTDATA_S15: ;

        FIFO_PRNTDATA_S16: begin
            sipo_buffer_addr <= sipo_buffer_addr + 10'd1;
            line_h_counter <= line_h_counter - 8'd1;
        end

        FIFO_PRNTDATA_S17:
            FIFO_OUTLATCH <= 8'h13;
        FIFO_PRNTDATA_S18: ;
        FIFO_PRNTDATA_S19: begin
            line_v_counter <= line_v_counter - 8'd1;
        end

        FIFO_TX_S0: ;
        FIFO_TX_S1: 
            nFIFOWR <= 1'b0;
        FIFO_TX_S2: ;
        FIFO_TX_S3:
             nFIFOWR <= 1'b1;

        default: ;
    endcase
end

endmodule