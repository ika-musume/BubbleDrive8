module SPILoader
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //image select
    input   wire    [2:0]   IMGNUM,

    //Emulator signal outputs
    input   wire    [2:0]   ACCTYPE,        //access type
    input   wire    [11:0]  ABSPOS,         //absolute position number
    output  wire    [11:0]  CURRPAGE,

    //Bubble out buffer interface
    output  reg             nOUTBUFWRCLKEN = 1'b1,       //bubble buffer write clken
    output  reg     [14:0]  OUTBUFWRADDR = 14'd0,      //bubble buffer write address
    output  reg             OUTBUFWRDATA = 1'b1,       //bubble buffer write data

    //FIFO buffer interface
    output  reg             nFIFOEN = 1'b1,
    output  reg             nFIFOBUFWCLKEN = 1'b1,
    output  reg     [12:0]  FIFOBUFWADDR = 13'd0,   //13bit addr = 8k * 1bit
    output  reg             FIFOBUFWDATA = 1'b1,

    //W25Q32
    output  reg             nCS = 1'b1,
    output  reg             MOSI = 1'b0,
    input   wire            MISO,
    output  reg             CLK = 1'b1,
    output  wire            nWP,
    output  wire            nHOLD
);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;

/*
    BAD LOOP MASKING TABLE
*/

reg             map_table[4095:0];
reg             map_data_in;
reg             map_data_out;
reg     [11:0]  map_addr = 12'd0; 
reg             map_write_enable = 1'b1;
reg             map_write_clken = 1'b1;
reg             map_read_clken = 1'b1;

always @(negedge MCLK)
begin
    if(map_write_clken == 1'b0)
    begin
        if(map_write_enable == 1'b0)
          begin
              map_table[{map_addr[11:4], ~map_addr[3:0]}] <= map_data_in; //see bubsys85.net
          end
     end
end

always @(negedge MCLK)
begin
    if(map_read_clken == 1'b0)
    begin
        map_data_out <= map_table[map_addr];
    end
end



/*
    POSITION2PAGE CONVERTER
*/

reg     [11:0]  target_position = 12'd0;
wire    [11:0]  bubble_page;
assign          CURRPAGE = bubble_page;
reg             convert = 1'b1;

PositionPageConverter Main (.MCLK(MCLK), .nCONV(convert), .ABSPOS(target_position), .PAGE(bubble_page));



/*
    SPI LOADER
*/

/*
    HI [00II/IPPP/PPPP/PPPP/PAAA/AAAA] LO
    00II/IXXX = 3 bits of image number
    XPPP/PPPP/PPPP/PXXX = 12 bits of page number
    XAAA/AAAA = 7 bitaddress of a page(128 bytes)
    0x000 - page
    0x001 - page
    ...
    0x804 - page
    0x805 - bootloader
    0x806 - bootloader
    0x807 - bootloader
    0x808 - bootloader
*/

reg     [31:0]  spi_instruction = 32'h0000_0000; //33 bit: 1 bit MOSI + 8 bit instruction + 24 bit address

reg     [11:0]  general_counter = 12'd0;

//declare states
localparam RESET = 12'b0000_0000_0000;              //버블 출력 종료 후 기본 리셋상태

localparam SPI_RDCMD_2B_S0 = 12'b0001_0000_0000;    //ACCTYPE가 페이지가 카운트 되기 전에 바뀌므로 ABSPOS+1을 집어넣는다
localparam SPI_RDCMD_2B_S1 = 12'b0001_0000_0001;    //페이지 변환하기
localparam SPI_RDCMD_2B_S2 = 12'b0001_0000_0010;    //SPI인스트럭션을 버퍼에 로드한다, 부트로더와 페이지가 달라짐
localparam SPI_RDCMD_2B_S3 = 12'b0001_0000_0011;    //SPI CS내려서 준비한다
localparam SPI_RDCMD_2B_S4 = 12'b0001_0000_0100;    //branch state; 전송 안 했으면 다음 state, 만약 다 전송했으면 액세스 타입에 따라 분기한다
localparam SPI_RDCMD_2B_S5 = 12'b0001_0000_0101;    //negedge에서 마스터가 SPI명령 쉬프트
localparam SPI_RDCMD_2B_S6 = 12'b0001_0000_0110;    //posedge에서 슬레이브가 명령 받게 CLK = 1, branch state로 돌아가기

//bootloader load
localparam BOOT_2B_S0 = 12'b0011_0010_0000;         //OUTBUFFER주소를 부트로더 시작 주소로 변경한다
localparam BOOT_2B_S1 = 12'b0011_0010_0001;         //branch state; general counter를 보고 부트로더 로딩이 끝났는지 체크하고, 로딩완료면 S6으로
localparam BOOT_2B_S2 = 12'b0011_0010_0010;         //negedge에서 슬레이브가 SPI데이터 보냄
localparam BOOT_2B_S3 = 12'b0011_0010_0011;         //posedge에서 마스터가 데이터를 샘플링한다
localparam BOOT_2B_S4 = 12'b0011_0010_0100;         //OUTBUFFER에 이 데이터를 쓴다(OUTBUFFERCLKEN = 0)
localparam BOOT_2B_S5 = 12'b0011_0010_0101;         //모두 정리하고(OUTBUFFERCLKEN = 1) 제네럴/어드레스 카운터 증가 후 branch로 되돌아간다
//error map load
localparam BOOT_2B_S6 = 12'b0011_0010_0110;         //에러맵 테이블 WE = 0, general counter 리셋
localparam BOOT_2B_S7 = 12'b0011_0010_0111;         //branch state; 에러맵 로딩이 끝났는지 체크하고, 끝났으면 RDIDLE로 간다
localparam BOOT_2B_S8 = 12'b0011_0010_1000;         //negedge에서 슬레이브가 SPI데이터 보냄
localparam BOOT_2B_S9 = 12'b0011_0010_1001;         //posedge에서 마스터가 데이터를 샘플링한다
localparam BOOT_2B_S10 = 12'b0011_0010_1010;        //OUTBUFFER와 error map 테이블 둘 다에 데이터를 쓴다(OUTBUFFERCLKEN = 0)
localparam BOOT_2B_S11 = 12'b0011_0010_1011;        //모두 정리하고(clken = 1) 제네럴/어드레스 카운터 증가 후 branch로 되돌하간다

//page head 6bit
localparam PGRD_2B_S0 = 12'b0100_0000_0000;         //OUTBUFFER주소를 페이지 시작 주소로 변경한다
localparam PGRD_2B_S1 = 12'b0100_0000_0001;         //branch state; 초반 6비트 쉬프트를 했나 안 했나 체크(주의: 0x000, 0x804등은 컨트롤러가 자체적으로 쉬프트시키는듯함)
localparam PGRD_2B_S2 = 12'b0100_0000_0010;         //에러맵 테이블 clken = 0으로 읽기
localparam PGRD_2B_S3 = 12'b0100_0000_0011;         //테이블 어드레스 증가, 불량루프(0)이면 데이터 0 쓰기 준비, 정상루프면 1 쓰기 준비
localparam PGRD_2B_S4 = 12'b0100_0000_0100;         //버퍼에 데이터 쓰기
localparam PGRD_2B_S5 = 12'b0100_0000_0101;         //버퍼 어드레스 증가, branch로 돌가가기
//page data load
localparam PGRD_2B_S6 = 12'b0100_0000_0110;         //branch state; 페이지 다 로딩했나 체크한다, 로딩했으면 SPIIDLE
localparam PGRD_2B_S7 = 12'b0100_0000_0111;         //negedge에서 슬레이브가 SPI데이터 보냄
localparam PGRD_2B_S8 = 12'b0100_0000_1000;         //posedge에서 데이터를 샘플링하고, 에러맵 테이블 clken = 0으로 읽기
localparam PGRD_2B_S9 = 12'b0100_0000_1001;         //테이블 어드레스 증가, 불량루프(0)이면 데이터 0 쓰기 준비, 정상루프면 SPI데이터 쓰기 준비
localparam PGRD_2B_S10 = 12'b0100_0000_1010;        //버퍼에 데이터를 쓴다
localparam PGRD_2B_S11 = 12'b0100_0000_1011;        //branch state; 버퍼 어드레스 증가, 정상루프면 g.c증가시키고 S6으로 돌아가기, 불량루프면 g.c는 그대로 S8로 가서 에러맵 읽기

localparam SPI_RDIDLE_S0 = 12'b0000_0001_0000;      //SPI CS = 1; 데이터 출력 다 끝난 후 버블 데이터 다 보낼때까지 대기시간

localparam PGWR_2B_S0 = 12'b1000_0000_0000;

localparam SPI_RDCMD_4B_S0 = 12'b0001_1000_0000;
localparam BOOT_4B_S0 = 12'b0011_1000_0000;
localparam PGRD_4B_S0 = 12'b0100_1000_0000;
localparam PGWR_4B_S0 = 12'b1100_0000_0000;

//spi state
reg     [11:0]   spi_state = RESET;

//state flow control
always @(posedge MCLK)
begin
    case (spi_state)
        //아이들 상태
        SPI_RDIDLE_S0:
            case(ACCTYPE[1])
                1'b0: spi_state <= RESET;
                1'b1: spi_state <= SPI_RDIDLE_S0;
            endcase
        RESET:
            case(ACCTYPE[1])
                1'b0: spi_state <= RESET;
                1'b1: spi_state <= SPI_RDCMD_2B_S0;
            endcase

        //2비트 모드 SPI 로드
        SPI_RDCMD_2B_S0: spi_state <= SPI_RDCMD_2B_S1;
        SPI_RDCMD_2B_S1: spi_state <= SPI_RDCMD_2B_S2;
        SPI_RDCMD_2B_S2: spi_state <= SPI_RDCMD_2B_S3;
        SPI_RDCMD_2B_S3: spi_state <= SPI_RDCMD_2B_S4;
        SPI_RDCMD_2B_S4:
            case({general_counter[5], ACCTYPE[0]})
                2'b00: spi_state <= SPI_RDCMD_2B_S5;
                2'b01: spi_state <= SPI_RDCMD_2B_S5;
                2'b10: spi_state <= BOOT_2B_S0;
                2'b11: spi_state <= PGRD_2B_S0;
            endcase
        SPI_RDCMD_2B_S5: spi_state <= SPI_RDCMD_2B_S6;
        SPI_RDCMD_2B_S6: spi_state <= SPI_RDCMD_2B_S4;

        //2비트 모드 부트로더 읽기
        BOOT_2B_S0: spi_state <= BOOT_2B_S1;
        BOOT_2B_S1:
            if(general_counter < 12'd2656)
            begin
                spi_state <= BOOT_2B_S2;
            end
            else
            begin
                spi_state <= BOOT_2B_S6;
            end
        BOOT_2B_S2: spi_state <= BOOT_2B_S3;
        BOOT_2B_S3: spi_state <= BOOT_2B_S4;
        BOOT_2B_S4: spi_state <= BOOT_2B_S5;
        BOOT_2B_S5: spi_state <= BOOT_2B_S1;

        BOOT_2B_S6: spi_state <= BOOT_2B_S7;
        BOOT_2B_S7:
            if(general_counter < 12'd1168 + 12'd32) //굉장히 수상한 32비트 데이터
            begin
                spi_state <= BOOT_2B_S8;
            end
            else
            begin
                spi_state <= SPI_RDIDLE_S0;
            end
        BOOT_2B_S8: spi_state <= BOOT_2B_S9;
        BOOT_2B_S9: spi_state <= BOOT_2B_S10;
        BOOT_2B_S10: spi_state <= BOOT_2B_S11;
        BOOT_2B_S11: spi_state <= BOOT_2B_S7;

        //2비트 모드 페이지 읽기
        PGRD_2B_S0: spi_state <= PGRD_2B_S1;
        PGRD_2B_S1:
            if(general_counter < 12'd6)
            begin
                spi_state <= PGRD_2B_S2;
            end
            else
            begin
                spi_state <= PGRD_2B_S6;
            end
        PGRD_2B_S2: spi_state <= PGRD_2B_S3;
        PGRD_2B_S3: spi_state <= PGRD_2B_S4;
        PGRD_2B_S4: spi_state <= PGRD_2B_S5;
        PGRD_2B_S5:
            case(map_data_out)
                1'b0: spi_state <= PGRD_2B_S2; //불량 루프면 다음 에러맵 읽기
                1'b1: spi_state <= PGRD_2B_S1; //정상 루프면 되돌아가기, 카운터 증가
            endcase

        PGRD_2B_S6:
            if(general_counter < 12'd1030)
            begin
                spi_state <= PGRD_2B_S7;
            end
            else
            begin
                spi_state <= SPI_RDIDLE_S0;
            end
        PGRD_2B_S7: spi_state <= PGRD_2B_S8;
        PGRD_2B_S8: spi_state <= PGRD_2B_S9;
        PGRD_2B_S9: spi_state <= PGRD_2B_S10;
        PGRD_2B_S10: spi_state <= PGRD_2B_S11;
        PGRD_2B_S11:
            case(map_data_out)
                1'b0: spi_state <= PGRD_2B_S8; //불량 루프면 다음 에러맵 읽기
                1'b1: spi_state <= PGRD_2B_S6; //정상 루프면 데이터 그대로 쓰기 준비
            endcase

        default: spi_state <= RESET;
    endcase
end

//determine the output
always @(posedge MCLK)
begin
    case (spi_state)
        SPI_RDIDLE_S0:
        begin
           nCS <= 1'b1; CLK <= 1'b1; 
        end
        RESET:
        begin
            nCS <= 1'b1; CLK <= 1'b1; 
            OUTBUFWRADDR <= {1'b0, 13'd0, 1'b0}; nOUTBUFWRCLKEN <= 1'b1;
            map_addr <= 12'd0; map_write_enable <= 1'b1; map_write_clken <= 1'b1; map_read_clken <= 1'b1;
            nFIFOEN <= 1'b1; FIFOBUFWADDR <= 13'd0; nFIFOBUFWCLKEN <= 1'b1;
            convert <= 1'b1;
            general_counter <= 12'd0; 
        end

        SPI_RDCMD_2B_S0:
        begin
            target_position <= ABSPOS + 12'd1;
        end
        SPI_RDCMD_2B_S1:
        begin
            convert <= 1'b0;
        end 
        SPI_RDCMD_2B_S2:
        begin
            convert <= 1'b1;
            case(ACCTYPE[0])
                1'b0: spi_instruction <= {8'b0000_0011, 2'b00, IMGNUM[2:0], 12'h805, 7'b000_0000};
                1'b1: spi_instruction <= {8'b0000_0011, 2'b00, IMGNUM[2:0], bubble_page[11:0], 7'b000_0000};
            endcase
        end
        SPI_RDCMD_2B_S3:
        begin
            nCS <= 1'b0; 
        end
        SPI_RDCMD_2B_S4:
        begin
            
        end
        SPI_RDCMD_2B_S5:
        begin
            CLK <= 1'b0;
            MOSI <= spi_instruction[31];
            spi_instruction[31:1] <= spi_instruction[30:0]; 
            general_counter <= general_counter + 12'd1; 
        end
        SPI_RDCMD_2B_S6:
        begin
            CLK <= 1'b1;
        end

        BOOT_2B_S0:
        begin
            OUTBUFWRADDR <= {1'b0, 13'd2053, 1'b0}; //부트로더 시작 주소로 변경
            FIFOBUFWADDR <= 13'd0;

            general_counter <= 12'd0;
        end
        BOOT_2B_S1:
        begin
            
        end
        BOOT_2B_S2:
        begin
            CLK <= 1'b0;
        end
        BOOT_2B_S3:
        begin
            CLK <= 1'b1;
            OUTBUFWRDATA <= MISO;
            FIFOBUFWDATA <= MISO;
        end
        BOOT_2B_S4:
        begin
            nOUTBUFWRCLKEN <= 1'b0;
            nFIFOBUFWCLKEN <= 1'b0;
        end
        BOOT_2B_S5:
        begin
            nOUTBUFWRCLKEN <= 1'b1; OUTBUFWRADDR <= OUTBUFWRADDR + 15'd1;
            nFIFOBUFWCLKEN <= 1'b1; FIFOBUFWADDR <= FIFOBUFWADDR + 13'd1;
            general_counter <= general_counter + 12'd1;
        end
        BOOT_2B_S6:
        begin
            map_write_enable <= 1'b0; //에러맵 테이블 쓰기 허용
            general_counter <= 12'd0;
        end
        BOOT_2B_S7:
        begin
            
        end
        BOOT_2B_S8:
        begin
            CLK <= 1'b0;
        end
        BOOT_2B_S9:
        begin
            CLK <= 1'b1;
            OUTBUFWRDATA <= MISO;
            map_data_in <= MISO;
            FIFOBUFWDATA <= MISO;
        end
        BOOT_2B_S10:
        begin
            nOUTBUFWRCLKEN <= 1'b0;
            map_write_clken <= 1'b0;
            nFIFOBUFWCLKEN <= 1'b0;
        end
        BOOT_2B_S11:
        begin
            nOUTBUFWRCLKEN <= 1'b1; OUTBUFWRADDR <= OUTBUFWRADDR + 15'd1;
            map_write_clken <= 1'b1; map_addr <= map_addr + 12'd1;
            nFIFOBUFWCLKEN <= 1'b1; FIFOBUFWADDR <= FIFOBUFWADDR + 13'd1;
            general_counter <= general_counter + 12'd1;
        end

        PGRD_2B_S0:
        begin
            OUTBUFWRADDR <= {1'b0, 13'd7168, 1'b0}; //페이지 데이터 시작시점
            FIFOBUFWADDR <= 13'd0;
            general_counter <= 12'd0;
        end
        PGRD_2B_S1:
        begin
            
        end
        PGRD_2B_S2:
        begin
            map_read_clken <= 1'b0;
        end
        PGRD_2B_S3:
        begin
            map_read_clken <= 1'b1; map_addr <= map_addr + 12'd1;
            case(map_data_out)
                1'b0: OUTBUFWRDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                1'b1: OUTBUFWRDATA <= 1'b1; //정상 루프면 데이터 1쓰기 준비, 카운터 증가
            endcase
        end
        PGRD_2B_S4:
        begin
            nOUTBUFWRCLKEN <= 1'b0;
        end
        PGRD_2B_S5:
        begin
            nOUTBUFWRCLKEN <= 1'b1; OUTBUFWRADDR <= OUTBUFWRADDR + 15'd1;
            case(map_data_out)
                1'b0: begin end //불량 루프면 다음 에러맵 읽기
                1'b1: begin general_counter <= general_counter + 12'd1; end //정상 루프면 되돌아가기, 카운터 증가
            endcase
        end
        PGRD_2B_S6:
        begin
            
        end
        PGRD_2B_S7:
        begin
            CLK <= 1'b0;
        end
        PGRD_2B_S8:
        begin
            CLK <= 1'b1;
            map_read_clken <= 1'b0;
        end
        PGRD_2B_S9:
        begin
            map_read_clken <= 1'b1; map_addr <= map_addr + 12'd1;
            case(map_data_out)
                1'b0: begin OUTBUFWRDATA <= 1'b0; end //불량 루프면 데이터 0쓰기 준비
                1'b1: begin OUTBUFWRDATA <= MISO; FIFOBUFWDATA <= MISO; end //정상 루프면 데이터 그대로 쓰기 준비
            endcase
        end
        PGRD_2B_S10:
        begin
            nOUTBUFWRCLKEN <= 1'b0;
            nFIFOBUFWCLKEN <= 1'b0;
        end
        PGRD_2B_S11:
        begin
            nOUTBUFWRCLKEN <= 1'b1; OUTBUFWRADDR <= OUTBUFWRADDR + 15'd1; 
            nFIFOBUFWCLKEN <= 1'b1; FIFOBUFWADDR <= FIFOBUFWADDR + 13'd1;
            case(map_data_out)
                1'b0: begin end //불량 루프면 다음 에러맵 읽기
                1'b1: begin general_counter <= general_counter + 12'd1; end//정상 루프면 데이터 그대로 쓰기 준비
            endcase
        end

        default:
        begin
            
        end
    endcase
end

endmodule