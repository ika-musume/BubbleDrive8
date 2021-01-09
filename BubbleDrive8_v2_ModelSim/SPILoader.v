module SPILoader
(
    //Master clock
    input   wire            master_clock, //48MHz master clock

    //Data for page address generation
    input   wire    [2:0]   image_number, //management module latches them at the very initial time of total boot process
    input   wire    [11:0]  bubble_page_input, //PPPP/PPPP/PPPP

    //Command
    input   wire            load_page,
    input   wire            load_bootloader,

    //To BubbleInterface block RAM
    output  reg     [10:0]  bubble_buffer_write_address = 11'd0,
    output  reg     [1:0]   bubble_buffer_write_data_output = 2'b00,
    output  reg             bubble_buffer_write_enable = 1'b1,
    output  reg             bubble_buffer_write_clock = 1'b0,

    //W25Q32
    output  reg             CS = 1'b1,
    output  wire            MOSI,
    input   wire            MISO,
    output  reg             CLK = 1'b1
);


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

localparam STANDBY = 4'b0000;
localparam LOAD_PAGE_ADDRESS = 4'b0001;
localparam CHIP_ENABLE = 4'b0010;
localparam INSTRUCTION_SHIFT = 4'b0011;
localparam WAIT = 4'b0100;
localparam WRITE_TO_BUFFER = 4'b0101;
localparam GET_BUBBLE_D1 = 4'b0110;
localparam INCREASE_ADDRESS = 4'b0111;
localparam GET_BUBBLE_D0 = 4'b1000;
localparam QUIT = 4'b1001;
localparam LOAD_BOOTLOADER_ADDRESS = 4'b1010;

reg    [32:0]  spiInstruction = {1'b0, 32'h0000_0000}; //33 bit register: 1 bit MOSI + 8 bit instruction + 24 bit address
assign MOSI = spiInstruction[32];

reg     [12:0]  spiStateCounter = 13'b0; 

reg     [3:0]   spiState = STANDBY;

/*
13 bit counter for SPI I/O

0000 - 0061: STANDBY
0062: LOAD_PAGE_ADDRESS
0063: CHIP_ENABLE
0064 - 0127: INSTRUCTION_SHIFT(LSB = 0), WAIT(LSB = 1)

from 00128(1000_0000)
XX00: WRITE_TO_BUFFER
XX01: GET_BUBBLE_D1
XX10: INCREASE_ADDRESS
XX11: GET_BUBBLE_D0

to 7807(bootloader 480B)
7808 - 7815: for last byte writing
7816: QUIT

to 2175(page 128B)
2176 - 2183: for last byte writing
2184: QUIT
*/

always @(posedge master_clock)
begin
    case({load_bootloader, load_page})
        2'b00:
        begin
            spiStateCounter <= 13'd0;
        end
        2'b01: //bootloader
        begin
            if(spiStateCounter < 13'b1_1111_1111_1111)
            begin
                spiStateCounter <= spiStateCounter + 13'd1;
            end
            else
            begin
                spiStateCounter <= spiStateCounter;
            end
        end
        2'b10: 
        begin
            if(spiStateCounter < 13'b1_1111_1111_1111)
            begin
                spiStateCounter <= spiStateCounter + 13'd1;
            end
            else
            begin
                spiStateCounter <= spiStateCounter;
            end
        end
        2'b11: 
        begin
            spiStateCounter <= 13'b0;
        end
    endcase
end

always @(posedge master_clock)
begin
    case({load_bootloader, load_page})
        2'b00:
        begin
            spiState <= STANDBY;
        end
        2'b01: //bootloader
        begin
            if(spiStateCounter == 13'd62)
            begin
                spiState <= LOAD_BOOTLOADER_ADDRESS;
            end
            else if(spiStateCounter == 13'd63)
            begin
                spiState <= CHIP_ENABLE;
            end
            else if(spiStateCounter >= 13'd64 && spiStateCounter <= 13'd127)
            begin
                case(spiStateCounter[0])
                    1'b0: spiState <= INSTRUCTION_SHIFT;
                    1'b1: spiState <= WAIT;
                endcase
            end
            else if(spiStateCounter >= 13'd128 && spiStateCounter <= 13'd7815)
            begin
                case(spiStateCounter[1:0])
                    2'b00: spiState <= WRITE_TO_BUFFER;
                    2'b01: spiState <= GET_BUBBLE_D1;
                    2'b10: spiState <= INCREASE_ADDRESS;
                    2'b11: spiState <= GET_BUBBLE_D0;
                endcase
            end
            else if(spiStateCounter == 13'd7816)
            begin
                spiState <= QUIT;
            end
            else
            begin
                spiState <= STANDBY;
            end
        end
        2'b10: 
        begin
            if(spiStateCounter == 13'd62)
            begin
                spiState <= LOAD_PAGE_ADDRESS;
            end
            else if(spiStateCounter == 13'd63)
            begin
                spiState <= CHIP_ENABLE;
            end
            else if(spiStateCounter >= 13'd64 && spiStateCounter <= 13'd127)
            begin
                case(spiStateCounter[0])
                    1'b0: spiState <= INSTRUCTION_SHIFT;
                    1'b1: spiState <= WAIT;
                endcase
            end
            else if(spiStateCounter >= 13'd128 && spiStateCounter <= 13'd2183)
            begin
                case(spiStateCounter[1:0])
                    2'b00: spiState <= WRITE_TO_BUFFER;
                    2'b01: spiState <= GET_BUBBLE_D1;
                    2'b10: spiState <= INCREASE_ADDRESS;
                    2'b11: spiState <= GET_BUBBLE_D0;
                endcase
            end
            else if(spiStateCounter == 13'd2184)
            begin
                spiState <= QUIT;
            end
            else
            begin
                spiState <= STANDBY;
            end
        end
        2'b11: 
        begin
            spiState <= STANDBY;
        end
    endcase
end

always @(posedge master_clock) //mode 3
begin
    case (spiState)
        STANDBY: //STANDBY
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b1;
            bubble_buffer_write_clock <= 1'b0;
        end
        LOAD_PAGE_ADDRESS: //LOAD_PAGE_ADDRESS
        begin
            spiInstruction <= {1'b0, 8'b0000_0011, 2'b00, image_number[2:0], bubble_page_input[11:0], 7'b000_0000}; //1 bit buffer + 8 bit instruction + 24 bit address
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        CHIP_ENABLE: //CHIP_ENABLE
        begin
            spiInstruction <= spiInstruction;
            CS <= 1'b0;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        INSTRUCTION_SHIFT: //INSTRUCTION_SHIFT
        begin
            spiInstruction <= spiInstruction << 1;
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        WAIT: //WAIT
        begin
            spiInstruction <= spiInstruction;
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        WRITE_TO_BUFFER: //WRITE_TO_BUFFER
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output <= bubble_buffer_write_data_output;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b1;
        end
        GET_BUBBLE_D1: //GET_BUBBLE_D1
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output[1] <= MISO;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b1;
        end
        INCREASE_ADDRESS: //INCREASE_ADDRESS
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            if(bubble_buffer_write_address < 11'b111_1111_1111)
            begin
                bubble_buffer_write_address <= bubble_buffer_write_address + 11'b1;
            end
            else
            begin
                bubble_buffer_write_address <= 11'b0;
            end
            bubble_buffer_write_data_output <= bubble_buffer_write_data_output;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        GET_BUBBLE_D0: //GET_BUBBLE_D0
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output[0] <= MISO;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        QUIT: //QUIT
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b1;
            bubble_buffer_write_clock <= 1'b0;
        end
        LOAD_BOOTLOADER_ADDRESS: //LOAD_BOOTLOADER_ADDRESS
        begin
            spiInstruction <= {1'b0, 8'b0000_0011, 2'b00, image_number[2:0], 12'h805, 7'b000_0000};
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        default
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b1;
            bubble_buffer_write_clock <= 1'b0;
        end
    endcase
end
endmodule