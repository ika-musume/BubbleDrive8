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
    output  reg     [14:0]  BUFWADDR,      //bubble buffer write address
    output  reg             BUFWCLK,       //bubble buffer write clk
    output  reg             BUFWDATA,      //bubble buffer write data

    //W25Q32
    output  reg             nCS = 1'b1,
    output  wire            MOSI,
    input   wire            MISO,
    output  reg             CLK = 1'b1,
    output  reg             nWP,
    output  reg             nHOLD
);

assign nWP = 1'bZ;
assign nHOLD = 1'bZ;

reg             spi_data_buffer = 1'b0;



/*
    BAD LOOP MASKING TABLE
*/

reg             map_table[4095:0];
reg             map_data_in;
reg             map_data_out;
reg    [11:0]   map_addr = 12'd0; 
reg             map_write_en = 1'b1;
reg             map_table_clk = 1'b0;


always @(posedge map_table_clk)
begin
    if(map_write_en == 1'b0)
    begin
        map_table[{map_addr[11:4], ~map_addr[3:0]}] <= map_data_in; //see bubsys85.net
    end
    map_data_out <= map_table[map_addr];
end

/*
    POSITION2PAGE CONVERTER
*/

reg             

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


reg     [5:0]   spi_counter = 6'd0;
reg     [11:0]  general_counter = 12'd0;










case(spi_counter[5:4])
    2'b00: //NOP
    2'b01: //SPI 인스트럭션

    2'b10: //부트로더
    begin
        case(spi_counter[3:0])
            4'd0:
            begin
                BUFWADDR <= 14'd0;
                general_counter <= 12'd0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd1:
            begin
                if(general_counter < 부트로더끝+1)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= spi_counter + 에러맵 로딩;
                end
            end
            4'd2:
            begin
                CLK <= 1'b0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd3: 
            begin
                CLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd4: 
            begin
                spi_data_buffer <= MISO;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd5: 
            begin
                BUFWDATA <= spi_data_buffer;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd6: 
            begin
                BUFWCLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd7:
            begin
                BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 14'd1;
                general_counter <= general_counter + 12'd1;
                spi_counter <= spi_counter - 6'd6;
            end


            4'd8: //DEFAULT
            begin
                map_addr <= 12'd0; map_write_en <= 1'b0; 
                general_counter <= 12'd0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd9:
            begin
                if(general_counter < 에러맵끝+1)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= spi_counter + 초기상태;
                end
            end
            4'd10: 
            begin
                CLK <= 1'b0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd11: 
            begin
                CLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd12: 
            begin
                spi_data_buffer <= MISO;
                spi_counter <= spi_counter + 6'd1;
            4'd13: 
            begin
                BUFWDATA <= spi_data_buffer;
                map_data_in <= spi_data_buffer;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd14: 
            begin
                BUFWCLK <= 1'b1;
                map_table_clk <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd15:
            begin
                BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 14'd1;
                map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
                general_counter <= general_counter + 12'd1;
                spi_counter <= spi_counter - 6'd6;
            end
        endcase
    end

    2'b11:
    begin
        case(spi_counter[3:0])
            4'd0:
            begin
                BUFWADDR <= 14'd0;
                map_addr <= 12'd0;
                general_counter <= 12'd0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd1:
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
            4'd2:
            begin
                map_table_clk <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd3:
            begin
                map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
                if(map_data_out == 1'b1)
                begin
                    BUFWDATA <= 1'b0;
                    general_counter <= general_counter + 12'd1;
                end
                else
                begin
                    BUFWDATA <= 1'b0;
                end
                spi_counter <= spi_counter + 6'd1;
            end
            4'd4:
            begin
                BUFWCLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd5:
            begin
                BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 14'd1;
                if(map_data_out == 1'b1)
                begin
                    spi_counter <= spi_counter - 6'd4;
                end
                else
                begin
                    spi_counter <= spi_counter - 6'd3;
                end
            end
            4'd6:
            begin
                if(general_counter < 518)
                begin
                    spi_counter <= spi_counter + 6'd1;
                end
                else
                begin
                    spi_counter <= 딴데;
                end
            end
            4'd7:
            begin
                CLK <= 1'b0;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd8:
            begin
                CLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd9:
            begin
                spi_data_buffer <= MISO;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd10:
            begin
                map_table_clk <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd11:
            begin
                map_table_clk <= 1'b0; map_addr <= map_addr + 12'd1;
                if(map_data_out == 1'b1)
                begin
                    BUFWDATA <= spi_data_buffer;
                    general_counter <= general_counter + 12'd1;
                end
                else
                begin
                    BUFWDATA <= 1'b0;
                end
                spi_counter <= spi_counter + 6'd1;
            end
            4'd12:
            begin
                BUFWCLK <= 1'b1;
                spi_counter <= spi_counter + 6'd1;
            end
            4'd13:
            begin
                BUFWCLK <= 1'b0; BUFWADDR <= BUFWADDR + 14'd1;
                if(map_data_out == 1'b1)
                begin
                    spi_counter <= spi_counter - 6'd7;
                end
                else
                begin
                    spi_counter <= spi_counter - 6'd3;
                end
            end
        endcase
    end
endcase



































































always @(posedge MCLK)
begin
    case(spi_counter[6:4])
        3'b000: //DEFAULT
        begin
            nCS <= 1'b1; CLK = 1'b1; BUFWRADDRM <= 14'd0; BUFWE <= 1'b0; map_addr <= 12'd0; map_write_en <= 1'b1; general_counter <= 12'd0; convert <= 1'b1;

            if(ACCTYPE == 3'b110 || ACCTYPE == 3'b111)
            begin
                spi_counter <= 7'b001_0000;
            end
            else
            begin
                spi_counter <= 7'b000_0000;
            end
        end

        3'b001: //INSTRUCTION SEND
        begin
            case(spi_counter[3:0])
                //페이지 변환
                4'b0000: 
                begin 
                    convert <= 1'b0; 
                    spi_counter <= spi_counter + 7'd1; 
                end
                //SPI인스트럭션 로드
                4'b0001:
                begin
                    convert <= 1'b1; 
                    spi_counter <= spi_counter + 7'd1;

                    case(ACCTYPE[0])
                        1'b0: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], 12'h805, 7'b000_0000};
                        1'b1: spi_instruction <= {1'b0, 8'b0000_0011, 2'b00, IMGNUM[2:0], bubble_page[11:0], 7'b000_0000};
                    endcase
                end
                //SPI준비
                4'b0010: 
                begin 
                    nCS <= 1'b0; 
                    spi_counter <= spi_counter + 7'd1; 
                end

                //명령 쉬프트
                4'b0100: 
                begin 
                    CLK = 1'b0; 
                    spi_instruction <= spi_instruction << 1; 
                    spi_counter <= spi_counter + 7'd1; 
                end
                //Slave in
                4'b0101: 
                begin 
                    CLK = 1'b1; 
                    general_counter <= general_counter + 12'd1; 
                    spi_counter <= spi_counter + 7'd1; 
                end
                //루프
                4'b0110:
                begin
                    case({general_counter[5], ACCTYPE[0]})
                        2'b00: spi_counter <= 7'b001_0100;
                        2'b01: spi_counter <= 7'b001_0100;
                        2'b10: //부트로더
                        2'b11: //페이지
                    endcase
                end
            endcase
        end

        3'b010:
        begin
            case(spi_counter[3:0])



            endcase
        end
    endcase
end




reg    [32:0]  spi_instruction = {1'b0, 32'h0000_0000}; //33 bit register: 1 bit MOSI + 8 bit instruction + 24 bit address
assign MOSI = spi_instruction[32];












endmodule