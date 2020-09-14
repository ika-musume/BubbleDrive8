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
    output  reg             WP = 1'bZ,
    output  reg             HOLD = 1'bZ,
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

localparam Standby = 4'b0000;
localparam LoadPageAddress = 4'b0001;
localparam ChipEnable = 4'b0010;
localparam InstructionShift = 4'b0011;
localparam Wait = 4'b0100;
localparam BufferWrite = 4'b0101;
localparam BubbleOddIn = 4'b0110;
localparam AddressIncrement = 4'b0111;
localparam BubbleEvenIn = 4'b1000;
localparam Quit = 4'b1001;
localparam LoadBootloaderAddress = 4'b1010;

reg    [32:0]  spiInstruction = {1'b0, 32'h0000_0000}; //33 bit register: 1 bit MOSI + 8 bit instruction + 24 bit address
assign MOSI = spiInstruction[32];

reg     [12:0]  spiStateCounter = 13'b0; 

reg     [3:0]   spiState = Standby;

/*
13 bit counter for SPI I/O

0000 - 0061: Standby
0062: LoadPageAddress
0063: ChipEnable
0064 - 0127: InstructionShift(LSB = 0), Wait(LSB = 1)

from 00128(1000_0000)
XX00: BufferWrite
XX01: BubbleOddIn
XX10: AddressIncrement
XX11: BubbleEvenIn

to 7807(bootloader 480B)
7808 - 7815: for last byte writing
7816: Quit

to 2175(page 128B)
2176 - 2183: for last byte writing
2184: Quit
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
            spiState <= Standby;
        end
        2'b01: //bootloader
        begin
            if(spiStateCounter == 13'd62)
            begin
                spiState <= LoadBootloaderAddress;
            end
            else if(spiStateCounter == 13'd63)
            begin
                spiState <= ChipEnable;
            end
            else if(spiStateCounter >= 13'd64 && spiStateCounter <= 13'd127)
            begin
                case(spiStateCounter[0])
                    1'b0: spiState <= InstructionShift;
                    1'b1: spiState <= Wait;
                endcase
            end
            else if(spiStateCounter >= 13'd128 && spiStateCounter <= 13'd7815)
            begin
                case(spiStateCounter[1:0])
                    2'b00: spiState <= BufferWrite;
                    2'b01: spiState <= BubbleOddIn;
                    2'b10: spiState <= AddressIncrement;
                    2'b11: spiState <= BubbleEvenIn;
                endcase
            end
            else if(spiStateCounter == 13'd7816)
            begin
                spiState <= Quit;
            end
            else
            begin
                spiState <= Standby;
            end
        end
        2'b10: 
        begin
            if(spiStateCounter == 13'd62)
            begin
                spiState <= LoadPageAddress;
            end
            else if(spiStateCounter == 13'd63)
            begin
                spiState <= ChipEnable;
            end
            else if(spiStateCounter >= 13'd64 && spiStateCounter <= 13'd127)
            begin
                case(spiStateCounter[0])
                    1'b0: spiState <= InstructionShift;
                    1'b1: spiState <= Wait;
                endcase
            end
            else if(spiStateCounter >= 13'd128 && spiStateCounter <= 13'd2183)
            begin
                case(spiStateCounter[1:0])
                    2'b00: spiState <= BufferWrite;
                    2'b01: spiState <= BubbleOddIn;
                    2'b10: spiState <= AddressIncrement;
                    2'b11: spiState <= BubbleEvenIn;
                endcase
            end
            else if(spiStateCounter == 13'd2184)
            begin
                spiState <= Quit;
            end
            else
            begin
                spiState <= Standby;
            end
        end
        2'b11: 
        begin
            spiState <= Standby;
        end
    endcase
end

always @(posedge master_clock) //mode 3
begin
    case (spiState)
        Standby: //Standby
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b1;
            bubble_buffer_write_clock <= 1'b0;
        end
        LoadPageAddress: //LoadPageAddress
        begin
            spiInstruction <= {1'b0, 8'b0000_0011, 2'b00, image_number[2:0], bubble_page_input[11:0], 7'b000_0000}; //1 bit buffer + 8 bit instruction + 24 bit address
            CS <= 1'b1;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        ChipEnable: //ChipEnable
        begin
            spiInstruction <= spiInstruction;
            CS <= 1'b0;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        InstructionShift: //InstructionShift
        begin
            spiInstruction <= spiInstruction << 1;
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        Wait: //Wait
        begin
            spiInstruction <= spiInstruction;
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        BufferWrite: //BufferWrite
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output <= bubble_buffer_write_data_output;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b1;
        end
        BubbleOddIn: //BubbleOddIn
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output[1] <= MISO;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b1;
        end
        AddressIncrement: //AddressIncrement
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
        BubbleEvenIn: //BubbleEvenIn
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= ~CLK;

            bubble_buffer_write_address <= bubble_buffer_write_address;
            bubble_buffer_write_data_output[0] <= MISO;
            bubble_buffer_write_enable <= 1'b0;
            bubble_buffer_write_clock <= 1'b0;
        end
        Quit: //Quit
        begin
            spiInstruction <= {1'b0, 32'h0000_0000};
            CS <= 1'b0;
            CLK <= 1'b1;

            bubble_buffer_write_address <= 11'b111_1111_1111;
            bubble_buffer_write_data_output <= 2'b00;
            bubble_buffer_write_enable <= 1'b1;
            bubble_buffer_write_clock <= 1'b0;
        end
        LoadBootloaderAddress: //LoadBootloaderAddress
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