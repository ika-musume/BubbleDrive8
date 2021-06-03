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
    output  reg             nOUTBUFWCLKEN = 1'b1,       //bubble buffer write clken
    output  reg     [14:0]  OUTBUFWADDR = 14'd0,      //bubble buffer write address
    output  reg             OUTBUFWDATA = 1'b1,       //bubble buffer write data

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
always @(posedge map_write_clken)
begin
    if(map_write_enable == 1'b0)
    begin
        map_table[{map_addr[11:4], ~map_addr[3:0]}] <= map_data_in; //see bubsys85.net
    end    
end

always @(negedge MCLK)
begin
    map_data_out <= map_table[map_addr];
end
*/



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

reg    [31:0]  spi_instruction = 32'h0000_0000; //33 bit: 1 bit MOSI + 8 bit instruction + 24 bit address

//reg     [5:0]   spi_counter = 6'd0;
reg     [11:0]  general_counter = 12'd0;


// Declare states
localparam IDLE_S0 = 8'b1110_0000;              //데이터 출력 다 끝난 후 버블 데이터 다 보낼때까지 대기시간
localparam IDLE_S1 = 8'b1110_0001;              //버블 출력 종료 후 기본 리셋상태

localparam SPI_RDCMD_2B_S0 = 8'b0000_0000;
localparam SPI_RDCMD_2B_S1 = 8'b0000_0001;
localparam SPI_RDCMD_2B_S2 = 8'b0000_0010;
localparam SPI_RDCMD_2B_S3 = 8'b0000_0011;
localparam SPI_RDCMD_2B_S4 = 8'b0000_0100;
localparam SPI_RDCMD_2B_S5 = 8'b0000_0101;
localparam SPI_RDCMD_2B_S6 = 8'b0000_0110;

localparam SPI_RDCMD_4B_S0 = 8'b0000_1000;

localparam BOOT_2B_S0 = 8'b0010_0000;
localparam BOOT_2B_S1 = 8'b0010_0001;
localparam BOOT_2B_S2 = 8'b0010_0010;
localparam BOOT_2B_S3 = 8'b0010_0011;
localparam BOOT_2B_S4 = 8'b0010_0100;
localparam BOOT_2B_S5 = 8'b0010_0101;
localparam BOOT_2B_S6 = 8'b0010_0110;
localparam BOOT_2B_S7 = 8'b0010_0111;
localparam BOOT_2B_S8 = 8'b0010_1000;
localparam BOOT_2B_S9 = 8'b0010_1001;
localparam BOOT_2B_S10 = 8'b0010_1010;
localparam BOOT_2B_S11 = 8'b0010_1011;

localparam BOOT_4B_S0 = 8'b0010_1100;

localparam PGRD_2B_S0 = 8'b0100_0000;
localparam PGRD_2B_S1 = 8'b0100_0001;
localparam PGRD_2B_S2 = 8'b0100_0010;
localparam PGRD_2B_S3 = 8'b0100_0011;
localparam PGRD_2B_S4 = 8'b0100_0100;
localparam PGRD_2B_S5 = 8'b0100_0101;
localparam PGRD_2B_S6 = 8'b0100_0110;
localparam PGRD_2B_S7 = 8'b0100_0111;
localparam PGRD_2B_S8 = 8'b0100_1000;
localparam PGRD_2B_S9 = 8'b0100_1001;
localparam PGRD_2B_S10 = 8'b0100_1010;
localparam PGRD_2B_S11 = 8'b0100_1011;

localparam PGRD_4B_S0 = 8'b0100_1100;

localparam PGWR_2B_S0 = 8'b0110_0000;

localparam PGWR_4B_S0 = 8'b1110_0000;

//spi state
reg     [7:0]   spi_state = IDLE_S1;

//state flow control
always @(posedge MCLK)
begin
    case (spi_state)
        //아이들 상태
        IDLE_S0:
            case(ACCTYPE[1])
                1'b0: spi_state <= IDLE_S1;
                1'b1: spi_state <= IDLE_S0;
            endcase
        IDLE_S1:
            case(ACCTYPE[1])
                1'b0: spi_state <= IDLE_S1;
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
                spi_state <= IDLE_S0;
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
                spi_state <= IDLE_S0;
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

        default: spi_state <= IDLE_S1;
    endcase
end

//determine the output
always @(posedge MCLK)
begin
    case (spi_state)
        IDLE_S0:
        begin
           nCS <= 1'b1; CLK <= 1'b1; 
        end
        IDLE_S1:
        begin
            nCS <= 1'b1; CLK <= 1'b1; 
            OUTBUFWADDR <= {1'b0, 13'd0, 1'b0}; nOUTBUFWCLKEN <= 1'b1;
            map_addr <= 12'd0; map_write_enable <= 1'b1; map_write_clken <= 1'b1; map_read_clken <= 1'b1;
            general_counter <= 12'd0; 
            convert <= 1'b1;
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
            OUTBUFWADDR <= {1'b0, 13'd2053, 1'b0}; //부트로더 시작 주소로 변경
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
            OUTBUFWDATA <= MISO;
        end
        BOOT_2B_S4:
        begin
            nOUTBUFWCLKEN <= 1'b0;
        end
        BOOT_2B_S5:
        begin
            nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
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
            OUTBUFWDATA <= MISO;
            map_data_in <= MISO;
        end
        BOOT_2B_S10:
        begin
            nOUTBUFWCLKEN <= 1'b0;
            map_write_clken <= 1'b0;
        end
        BOOT_2B_S11:
        begin
            nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
            map_write_clken <= 1'b1; map_addr <= map_addr + 12'd1;
            general_counter <= general_counter + 12'd1;
        end

        PGRD_2B_S0:
        begin
            OUTBUFWADDR <= {1'b0, 13'd7168, 1'b0}; //페이지 데이터 시작시점
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
                1'b0: OUTBUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                1'b1: OUTBUFWDATA <= 1'b1; //정상 루프면 데이터 1쓰기 준비, 카운터 증가
            endcase
        end
        PGRD_2B_S4:
        begin
            nOUTBUFWCLKEN <= 1'b0;
        end
        PGRD_2B_S5:
        begin
            nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
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
                1'b0: OUTBUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                1'b1: OUTBUFWDATA <= MISO; //정상 루프면 데이터 그대로 쓰기 준비
            endcase
        end
        PGRD_2B_S10:
        begin
            nOUTBUFWCLKEN <= 1'b0;
        end
        PGRD_2B_S11:
        begin
            nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1; 
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


/*
    ORIGINAL CODE(CONSUMES MORE LE)
*/

/*
always @(posedge MCLK)
begin
    case(spi_counter[5:4])
        2'b00: //NOP
        begin
            case(spi_counter[3:0])
                4'd0:
                begin
                    nCS <= 1'b1; CLK = 1'b1;
                    case(ACCTYPE[1])
                        1'b0: spi_counter <= spi_counter + 6'd1;
                        1'b1: spi_counter <= spi_counter;
                    endcase
                end
                4'd1:
                begin
                    nCS <= 1'b1; CLK = 1'b1; 
                    OUTBUFWADDR <= {1'b0, 13'd0, 1'b0}; nOUTBUFWCLKEN <= 1'b1;
                    map_addr <= 12'd0; map_write_enable <= 1'b1; map_write_clken <= 1'b1; map_read_clken <= 1'b1;
                    general_counter <= 12'd0; 
                    convert <= 1'b1;

                    case(ACCTYPE[1])
                        1'b0: spi_counter <= spi_counter;
                        1'b1: spi_counter <= 6'b01_0000;
                    endcase
                end
                default: spi_counter <= 6'b00_0000;
            endcase
        end

        2'b01: //SPI 인스트럭션 송신
        begin
            case(spi_counter[3:0])
                4'd0: 
                begin
                    target_position <= ABSPOS + 12'd1; //ACCTYPE가 페이지 카운트되기전에 바뀌므로 ABSPOS+1
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd1: //convert negedge 페이지 변환
                begin 
                    convert <= 1'b0; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd2: //SPI인스트럭션 버퍼에 로드
                begin
                    convert <= 1'b1; 
                    spi_counter <= spi_counter + 6'd1;

                    case(ACCTYPE[0])
                        1'b0: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], 12'h805, 7'b000_0000};
                        1'b1: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], bubble_page[11:0], 7'b000_0000};
                    endcase
                end
                4'd3: //SPI준비
                begin 
                    nCS <= 1'b0; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd4: //루프
                begin
                    case({general_counter[5], ACCTYPE[0]})
                        2'b00: spi_counter <= spi_counter + 6'd1;
                        2'b01: spi_counter <= spi_counter + 6'd1;
                        2'b10: spi_counter <= 6'b10_0000;
                        2'b11: spi_counter <= 6'b11_0000;
                    endcase
                end
                4'd5: //negedge 마스터가 명령 쉬프트
                begin 
                    CLK = 1'b0; 
                    spi_instruction <= spi_instruction << 1; 
                    general_counter <= general_counter + 12'd1; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd6: //posedge 슬레이브에 입력
                begin 
                    CLK = 1'b1; 
                    spi_counter <= spi_counter - 6'd2; 
                end
            endcase
        end

        2'b10: //부트로더
        begin
            case(spi_counter[3:0])
                4'b0: //셋업
                begin
                    OUTBUFWADDR <= {1'b0, 13'd2053, 1'b0}; //부트로더 시작 주소로 변경
                    general_counter <= 12'd0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd1: //부트로더 로딩이 끝났는지 체크
                begin
                    if(general_counter < 12'd2656)
                    begin
                        spi_counter <= spi_counter + 6'd1;
                    end
                    else
                    begin
                        spi_counter <= spi_counter + 6'd5;
                    end
                end
                4'd2: //SPI MISO
                begin
                    CLK <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd3: //SPI 데이터 샘플링
                begin
                    CLK <= 1'b1;
                    OUTBUFWDATA <= MISO;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd4: //버퍼에 부트로더 쓰기 
                begin
                    nOUTBUFWCLKEN <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd5: //클럭 원위치, 어드레스랑 카운터 증가 후 되돌아가기
                begin
                    nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
                    general_counter <= general_counter + 12'd1;
                    spi_counter <= spi_counter - 6'd4;
                end


                4'd6: //에러맵 로딩
                begin
                    map_write_enable <= 1'b0; //에러맵 테이블 쓰기 허용
                    general_counter <= 12'd0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd7: //에러맵 로딩이 끝났는지 체크
                begin
                    if(general_counter < 12'd1168 + 12'd32) //쓸데없는 32비트 데이터
                    begin
                        spi_counter <= spi_counter + 6'd1;
                    end
                    else
                    begin
                        spi_counter <= 6'b00_0000;
                    end
                end
                4'd8: //SPI MISO
                begin
                    CLK <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd9: //데이터 샘플링
                begin
                    CLK <= 1'b1;
                    OUTBUFWDATA <= MISO;
                    map_data_in <= MISO;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd10: //버퍼와 에러맵테이블에 데이터 쓰기
                begin
                    nOUTBUFWCLKEN <= 1'b0;
                    map_write_clken <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd11: //클럭 원위치, 어드레스랑 카운터 증가 후 되돌아가기
                begin
                    nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
                    map_write_clken <= 1'b1; map_addr <= map_addr + 12'd1;
                    general_counter <= general_counter + 12'd1;
                    spi_counter <= spi_counter - 6'd4;
                end
            endcase
        end

        2'b11: //페이지
        begin
            case(spi_counter[3:0])
                4'd0: //셋업
                begin
                    OUTBUFWADDR <= {1'b0, 13'd7168, 1'b0}; //페이지 데이터 시작시점
                    general_counter <= 12'd0;
                    spi_counter <= spi_counter + 6'd1;
                end

                //6비트 쉬프트 로딩
                4'd1: //초반 6비트 쉬프트를 했나 안했나 체크
                begin
                    if(general_counter < 12'd6)
                    begin
                        spi_counter <= spi_counter + 6'd1;
                    end
                    else
                    begin
                        spi_counter <= spi_counter + 6'd5;
                    end
                end
                4'd2: //에러맵 테이블 읽기
                begin
                    map_read_clken <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd3: //불량/정상시 동작 구분, 에러맵 어드레스 증가
                begin
                    map_read_clken <= 1'b1; map_addr <= map_addr + 12'd1;
                    case(map_data_out)
                        1'b0: OUTBUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                        1'b1: OUTBUFWDATA <= 1'b1; //정상 루프면 데이터 1쓰기 준비, 카운터 증가
                    endcase
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd4: //버퍼에 데이터 쓰기
                begin
                    nOUTBUFWCLKEN <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd5: //버퍼 어드레스 증가 및 돌아가기
                begin
                    nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1;
                    case(map_data_out)
                        1'b0: begin spi_counter <= spi_counter - 6'd3; end //불량 루프면 다음 에러맵 읽기
                        1'b1: begin spi_counter <= spi_counter - 6'd4; general_counter <= general_counter + 12'd1; end //정상 루프면 되돌아가기, 카운터 증가
                    endcase
                end

                //페이지 로딩
                4'd6: //페이지 다 로딩했나 체크
                begin
                    if(general_counter < 12'd1030)
                    begin
                        spi_counter <= spi_counter + 6'd1;
                    end
                    else
                    begin
                        spi_counter <= 6'b00_0000;
                    end
                end
                4'd7: //SPI MISO
                begin
                    CLK <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd8: //SPI 클럭 올리기와 에러맵 읽기
                begin
                    CLK <= 1'b1;
                    map_read_clken <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd9: //에러맵 어드레스 증가, 뭐 쓸지 결정
                begin
                    map_read_clken <= 1'b1; map_addr <= map_addr + 12'd1;
                    case(map_data_out)
                        1'b0: OUTBUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                        1'b1: OUTBUFWDATA <= MISO; //정상 루프면 데이터 그대로 쓰기 준비
                    endcase
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd10: //버퍼에 쓰기
                begin
                    nOUTBUFWCLKEN <= 1'b0;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd11: //버퍼 어드레스 증가, 불량루프였을 경우 뭐 할지 결정
                begin
                    nOUTBUFWCLKEN <= 1'b1; OUTBUFWADDR <= OUTBUFWADDR + 15'd1; 
                    case(map_data_out)
                        1'b0: begin spi_counter <= spi_counter - 6'd3; end //불량 루프면 다음 에러맵 읽기
                        1'b1: begin spi_counter <= spi_counter - 6'd5; general_counter <= general_counter + 12'd1; end//정상 루프면 데이터 그대로 쓰기 준비
                    endcase
                end
            endcase
        end
    endcase
end

*/

endmodule