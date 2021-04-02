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

    //
    output  reg     [14:0]  BUFWADDR = 14'd0,      //bubble buffer write address
    output  reg             BUFWCLK = 1'b0,       //bubble buffer write clk
    output  reg             BUFWDATA = 1'b0,      //bubble buffer write data

    //W25Q32
    output  reg             nCS = 1'b1,
    output  wire            MOSI,
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
reg    [11:0]   map_addr = 12'd0; 
reg             map_write_enable = 1'b1;
reg             map_table_clk = 1'b0;


always @(posedge map_table_clk)
begin
    if(map_write_enable == 1'b0)
    begin
        map_table[{map_addr[11:4], ~map_addr[3:0]}] <= map_data_in; //see bubsys85.net
    end
    map_data_out <= map_table[map_addr];
end



/*
    POSITION2PAGE CONVERTER
*/

wire    [11:0]  current_position;
assign          current_position = ABSPOS + 12'd1;
wire    [11:0]  bubble_page;
reg             convert = 1'b1;

PositionPageConverter Main (.nCONV(convert), .ABSPOS(current_position), .PAGE(bubble_page));



/*
    SPI LOADER
*/

/*
    HI [00II/IPPP/PPPP/PPPP/PAAA/AAAA] LO
    00II/IXXX = 3 bits of image number
    XPPP/PPPP/PPPP/PXXX = 12 bits of page number
    XAAA/AAAA = 7 bits of address of a page(128 bytes)
    0x000 - page
    0x001 - page
    ...
    0x804 - page
    0x805 - bootloader
    0x806 - bootloader
    0x807 - bootloader
    0x808 - bootloader
*/

reg    [32:0]  spi_instruction = {1'b0, 32'h0000_0000}; //33 bit register: 1 bit MOSI + 8 bit instruction + 24 bit address
assign MOSI = spi_instruction[32];

reg     [5:0]   spi_counter = 6'd0;
reg     [11:0]  general_counter = 12'd0;


/*
    ORIGINAL CODE(CONSUMES MORE LE)
*/

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
                    BUFWADDR <= {1'b0, 13'd0, 1'b0}; BUFWCLK <= 1'b0;
                    map_addr <= 12'd0; map_write_enable <= 1'b1; map_table_clk <= 1'b0;
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
                4'd0: //convert negedge 페이지 변환(ACCTYPE가 페이지 카운트되기전에 바뀌므로 ABSPOS+1)
                begin 
                    convert <= 1'b0; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd1: //SPI인스트럭션 버퍼에 로드
                begin
                    convert <= 1'b1; 
                    spi_counter <= spi_counter + 6'd1;

                    case(ACCTYPE[0])
                        1'b0: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], 12'h805, 7'b000_0000};
                        1'b1: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], bubble_page[11:0], 7'b000_0000};
                    endcase
                end
                4'd2: //SPI준비
                begin 
                    nCS <= 1'b0; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd3: //루프
                begin
                    case({general_counter[5], ACCTYPE[0]})
                        2'b00: spi_counter <= spi_counter + 6'd1;
                        2'b01: spi_counter <= spi_counter + 6'd1;
                        2'b10: spi_counter <= 6'b10_0000;
                        2'b11: spi_counter <= 6'b11_0000;
                    endcase
                end
                4'd4: //negedge 마스터가 명령 쉬프트
                begin 
                    CLK = 1'b0; 
                    spi_instruction <= spi_instruction << 1; 
                    general_counter <= general_counter + 12'd1; 
                    spi_counter <= spi_counter + 6'd1; 
                end
                4'd5: //posedge 슬레이브에 입력
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
                    BUFWADDR <= {1'b0, 13'd2053, 1'b0}; //부트로더 시작 주소로 변경
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
                    BUFWDATA <= MISO;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd4: //버퍼에 부트로더 쓰기 
                begin
                    BUFWCLK <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd5: //클럭 원위치, 어드레스랑 카운터 증가 후 되돌아가기
                begin
                    BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
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
                    if(general_counter < 12'd1168)
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
                    BUFWDATA <= MISO;
                    map_data_in <= MISO;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd10: //버퍼와 에러맵테이블에 데이터 쓰기
                begin
                    BUFWCLK <= 1'b1;
                    map_table_clk <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd11: //클럭 원위치, 어드레스랑 카운터 증가 후 되돌아가기
                begin
                    BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
                    map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
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
                    BUFWADDR <= {1'b0, 13'd7168, 1'b0}; //페이지 데이터 시작시점
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
                    map_table_clk <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd3: //불량/정상시 동작 구분, 에러맵 어드레스 증가
                begin
                    map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
                    case(map_data_out)
                        1'b0: BUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                        1'b1: BUFWDATA <= 1'b1; //정상 루프면 데이터 1쓰기 준비, 카운터 증가
                    endcase
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd4: //버퍼에 데이터 쓰기
                begin
                    BUFWCLK <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd5: //버퍼 어드레스 증가 및 돌아가기
                begin
                    BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
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
                    map_table_clk <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd9: //에러맵 어드레스 증가, 뭐 쓸지 결정
                begin
                    map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
                    case(map_data_out)
                        1'b0: BUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                        1'b1: BUFWDATA <= MISO; //정상 루프면 데이터 그대로 쓰기 준비
                    endcase
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd10: //버퍼에 쓰기
                begin
                    BUFWCLK <= 1'b1;
                    spi_counter <= spi_counter + 6'd1;
                end
                4'd11: //버퍼 어드레스 증가, 불량루프였을 경우 뭐 할지 결정
                begin
                    BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1; 
                    case(map_data_out)
                        1'b0: begin spi_counter <= spi_counter - 6'd3; end //불량 루프면 다음 에러맵 읽기
                        1'b1: begin spi_counter <= spi_counter - 6'd5; general_counter <= general_counter + 12'd1; end//정상 루프면 데이터 그대로 쓰기 준비
                    endcase
                end
            endcase
        end
    endcase
end

/*
    WEIRD CODE
*/

/*
localparam RESET        = 6'b00_0000;

localparam PGCONV       = 6'b01_0000;
localparam INSTLD       = 6'b01_0001;
localparam SPICS        = 6'b01_0010;
localparam INSTSHIFT0   = 6'b01_0011;
localparam INSTSHIFT1   = 6'b01_0100;
localparam INSTBRA      = 6'b01_0101;

localparam BOOTSET      = 6'b10_0000;
localparam BOOTBRA      = 6'b10_0001;
localparam BOOTSHIFT    = 6'b10_0010;
localparam BOOTLD       = 6'b10_0011;
localparam BOOTW        = 6'b10_0100;
localparam BOOTINC      = 6'b10_0101;

localparam MAPSET       = 6'b10_0110;
localparam MAPBRA       = 6'b10_0111;
localparam MAPSHIFT     = 6'b10_1000;
localparam MAPLD        = 6'b10_1001;
localparam MAPW         = 6'b10_1010;
localparam MAPINC       = 6'b10_1011;

localparam PGHEADSET    = 6'b11_0000;
localparam PGHEADBRA    = 6'b11_0001;
localparam PGHEADMAPLD  = 6'b11_0010;
localparam PGHEADLD     = 6'b11_0011;
localparam PGHEADW      = 6'b11_0100;
localparam PGHEADINC    = 6'b11_0101;

localparam PGBRA        = 6'b11_0110;
localparam PGSHIFT      = 6'b11_0111;
localparam PGMAPLD      = 6'b11_1000;
localparam PGLD         = 6'b11_1001;
localparam PGW          = 6'b11_1010; 
localparam PGINCBRA     = 6'b11_1011; //TO PGMAPLD OR TO PGBRA

//branch control
always @(posedge MCLK)
begin
    case(spi_counter[5:4])
        2'b00: //NOP
        begin
            if(spi_counter[3:0] == 4'd0)
            begin
                case(ACCTYPE[1])
                    1'b0: spi_counter <= 6'b00_0000;
                    1'b1: spi_counter <= 6'b01_0000;
                endcase
            end
            else
            begin
                spi_counter <= 6'b00_0000;
            end
        end

        2'b01: //SPI 인스트럭션 송신
        begin
            if(spi_counter[3:0] == 4'd5)
            begin
                case({general_counter[5], ACCTYPE[0]})
                    2'b00: spi_counter <= spi_counter - 6'd2;
                    2'b01: spi_counter <= spi_counter - 6'd2;
                    2'b10: spi_counter <= 6'b10_0000;
                    2'b11: spi_counter <= 6'b11_0000;
                endcase
            end
            else
            begin
                spi_counter <= spi_counter + 6'd1; 
            end
        end

        2'b10: //부트로더
        begin
            if(spi_counter[3:0] == 4'd1)
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
            else if(spi_counter[3:0] == 4'd5)
            begin
                spi_counter <= spi_counter - 6'd4;
            end
            else if(spi_counter[3:0] == 4'd7)
            begin
                if(general_counter < 12'd1168)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= 6'b00_0000;
                end
            end
            else if(spi_counter[3:0] == 4'd11)
            begin
                spi_counter <= spi_counter - 6'd4;
            end
            else
            begin
                spi_counter <= spi_counter + 6'd1;
            end
        end

        2'b11: //페이지
        begin
            if(spi_counter[3:0] == 4'd1)
            begin
                if(general_counter < 6)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= spi_counter + 6'd5;
                end
            end
            else if(spi_counter[3:0] == 4'd5)
            begin
                case(map_data_out)
                    1'b0: spi_counter <= spi_counter - 6'd3; //불량 루프면 다음 에러맵 읽기
                    1'b1: spi_counter <= spi_counter - 6'd4; //정상 루프면 되돌아가기,
                endcase
            end
            else if(spi_counter[3:0] == 4'd6)
            begin
                if(general_counter < 518)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= 6'b00_0000;
                end
            end
            else if(spi_counter[3:0] == 4'd11)
            begin
                case(map_data_out)
                    1'b0: spi_counter <= spi_counter - 6'd3; //불량 루프면 다음 에러맵 읽기
                    1'b1: spi_counter <= spi_counter - 6'd5;//정상 루프면 데이터 그대로 쓰기 준비
                endcase
            end
            else
            begin
                spi_counter <= spi_counter + 6'd1;
            end
        end
    endcase
end

//instruction execution
always @(posedge MCLK)
begin
    case(spi_counter)
        //기본
        RESET:
        begin
            nCS <= 1'b1; CLK = 1'b1; 
            BUFWADDR <= {1'b0, 13'd0, 1'b0}; BUFWCLK <= 1'b0;
            map_addr <= 12'd0; map_write_enable <= 1'b1; map_table_clk <= 1'b0;
            general_counter <= 12'd0; 
            convert <= 1'b1;
        end

        //SPI인스트럭션 송신
        PGCONV: 
        begin 
            convert <= 1'b0;
        end
        INSTLD:
        begin
            convert <= 1'b1; 
            case(ACCTYPE[0])
                1'b0: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], 12'h805, 7'b000_0000};
                1'b1: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], bubble_page[11:0], 7'b000_0000};
            endcase
        end
        SPICS:
        begin
            nCS <= 1'b0; 
        end
        INSTSHIFT0:
        begin
            CLK = 1'b0; 
            spi_instruction <= spi_instruction << 1; 
        end
        INSTSHIFT1:
        begin
            CLK = 1'b1; 
            general_counter <= general_counter + 12'd1; 
        end
        INSTBRA:
        begin
            
        end

        //부트로더 불러오기
        BOOTSET:
        begin
            BUFWADDR <= {1'b0, 13'd2053, 1'b0}; //부트로더 시작 주소로 변경
            general_counter <= 12'd0;
        end
        BOOTBRA:
        begin
            
        end
        BOOTSHIFT:
        begin
            CLK <= 1'b0;
        end
        BOOTLD:
        begin
            CLK <= 1'b1;
            BUFWDATA <= MISO;
        end
        BOOTW:
        begin
            BUFWCLK <= 1'b1;
        end
        BOOTINC:
        begin
            BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
            general_counter <= general_counter + 12'd1;
        end

        MAPSET:
        begin
            map_write_enable <= 1'b0; //에러맵 테이블 쓰기 허용
            general_counter <= 12'd0;
        end
        MAPBRA:
        begin
            
        end
        MAPSHIFT:
        begin
            CLK <= 1'b0;
        end
        MAPLD:
        begin
            CLK <= 1'b1;
            BUFWDATA <= MISO;
            map_data_in <= MISO;
        end
        MAPW:
        begin
            BUFWCLK <= 1'b1;
            map_table_clk <= 1'b1;
        end
        MAPINC:
        begin
            BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
            map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
            general_counter <= general_counter + 12'd1;
        end

        //페이지 로딩
        PGHEADSET:
        begin
            BUFWADDR <= {1'b0, 13'd7168, 1'b0}; //페이지 데이터 시작시점
            general_counter <= 12'd0;
        end
        PGHEADBRA:
        begin
            
        end
        PGHEADMAPLD:
        begin
            map_table_clk <= 1'b1;
        end
        PGHEADLD:
        begin
            map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
            case(map_data_out)
                1'b0: BUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                1'b1: BUFWDATA <= 1'b1; //정상 루프면 데이터 1쓰기 준비, 카운터 증가
            endcase
        end
        PGHEADW:
        begin
            BUFWCLK <= 1'b1;
        end
        PGHEADINC:
        begin
            BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1;
            case(map_data_out)
                1'b0: ;//불량 루프면 다음 에러맵 읽기
                1'b1: general_counter <= general_counter + 12'd1; //정상 루프면 되돌아가기, 카운터 증가
            endcase
        end

        PGBRA:
        begin
            
        end
        PGSHIFT:
        begin
            CLK <= 1'b0;
        end
        PGMAPLD:
        begin
            CLK <= 1'b1;
            map_table_clk <= 1'b1;
        end
        PGLD:
        begin
            map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
            case(map_data_out)
                1'b0: BUFWDATA <= 1'b0; //불량 루프면 데이터 0쓰기 준비
                1'b1: BUFWDATA <= MISO; //정상 루프면 데이터 그대로 쓰기 준비
            endcase
        end
        PGW:
        begin
            BUFWCLK <= 1'b1;
        end
        PGINCBRA:
        begin
            BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 15'd1; 
            case(map_data_out)
                1'b0: ;//불량 루프면 다음 에러맵 읽기
                1'b1: general_counter <= general_counter + 12'd1; //정상 루프면 데이터 그대로 쓰기 준비
            endcase
        end
    endcase
end
*/

endmodule