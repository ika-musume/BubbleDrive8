module BubbleInterface
/*
    
*/

(
    //48MHz input clock
    input   wire            MCLK,

    //Emulator signal outputs
    input   wire    [2:0]   ACCTYPE,        //access type
    input   wire    [12:0]  BOUTCYCLENUM,   //bubble output cycle number
    input   wire            nBINCLKEN,
    input   wire            nBOUTCLKEN,     //bubble output asynchronous control ticks

    //Bubble out buffer interface
    input   wire            nOUTBUFWCLKEN,    //bubble outbuffer write clk
    input   wire    [14:0]  OUTBUFWADDR,      //bubble outbuffer write address
    input   wire            OUTBUFWDATA,      //bubble outbuffer write data

    //Bubble data out
    output  wire            DOUT0,
    output  wire            DOUT1,
    output  wire            DOUT2,
    output  wire            DOUT3
);

localparam BITWIDTH4 = 1'b0; //4bit mode off
assign  DOUT2 = 1'b1;
assign  DOUT3 = 1'b1;


/*
    OUTBUFFER READ ADDRESS DECODER
*/

/*
    Block RAM Buffer Address [DOUT1/DOUT0]
    1bit 0 + 13bit address + 1bit CS
    0000-1985 : 11 = filler
    1986-2050 : X0 = 65 of ZEROs on EVEN channel (or possibly 64?)
    2051      : X1 = 1 of ONE on EVEN channel
    2052      : XX
    2053-3964 : 478bytes = 3824bits bootloader
    3965-4105 : 11 = filler
    4106-7167 : 00 = empty space
    7168-7170 : 00 = 3 position shifted page data
    7171-7751 : 581bits remaining page data
    8190      : 00 = empty bubble propagation line
    8191      : 00 = empty bubble propagation line
*/

localparam BOOT = 3'b110;   //C
localparam USER = 3'b111;   //D

reg     [12:0]  outbuffer_read_address = 13'b1_1111_1111_1111;

always @(*)
begin
    case (ACCTYPE)
        BOOT:
        begin
            outbuffer_read_address <= BOUTCYCLENUM;
        end
        USER:
        begin
            outbuffer_read_address <= {3'b111, BOUTCYCLENUM[9:0]};
        end
        default:
        begin
            outbuffer_read_address <= 13'b1_1111_1111_1111;
        end
    endcase
end



/*
    OUTBUFFER WRITE ADDRESS DECODER
*/

wire    [3:0]   outbuffer_write_enable;
reg     [3:0]   outbuffer_we_decoder = 4'b1111; //D3 D2 DOUT1 DOUT0
assign          outbuffer_write_enable = outbuffer_we_decoder | {4{~ACCTYPE[1]}};
reg     [12:0]  outbuffer_write_address;

always @(*)
begin
    case(BITWIDTH4)
        1'b0: //2BITMODE
        begin
            case(OUTBUFWADDR[0])
                1'b0:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[13:1];
                    outbuffer_we_decoder <= 4'b1101;
                end
                1'b1:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[13:1];
                    outbuffer_we_decoder <= 4'b1110;
                end
            endcase
        end
        1'b1: //4BITMODE: no game released
        begin
            case(OUTBUFWADDR[1:0])
                2'b00:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_we_decoder <= 4'b0111;
                end
                2'b01:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_we_decoder <= 4'b1011;
                end
                2'b10:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_we_decoder <= 4'b1101;
                end
                2'b11:
                begin
                    outbuffer_write_address <= OUTBUFWADDR[14:2];
                    outbuffer_we_decoder <= 4'b1110;
                end
            endcase
        end
    endcase
end



/*
    OUTBUFFER
*/

//DOUT0
reg             D0_outbuffer[8191:0];
reg             D0_outbuffer_read_data;
assign          DOUT0 = ~D0_outbuffer_read_data;

always @(negedge MCLK)
begin
    if(nOUTBUFWCLKEN == 1'b0)
    begin
       if (outbuffer_write_enable[0] == 1'b0)
       begin
           D0_outbuffer[outbuffer_write_address] <= OUTBUFWDATA;
       end
    end
end

always @(negedge MCLK) //read 
begin
    if(nBOUTCLKEN == 1'b0)
    begin
        D0_outbuffer_read_data <= D0_outbuffer[outbuffer_read_address];
    end
end

//asynchronous code
/*
always @(negedge nOUTBUFWCLKEN) //write
begin
    if (outbuffer_write_enable[0] == 1'b0)
    begin
        D0_outbuffer[outbuffer_write_address] <= OUTBUFWDATA;
    end
end
*/




initial
begin
    $readmemb("D0_outbuffer.txt", D0_outbuffer);
end

//DOUT1
reg             D1_outbuffer[8191:0];
reg             D1_outbuffer_read_data;
assign          DOUT1 = ~D1_outbuffer_read_data;


always @(negedge MCLK)
begin
    if(nOUTBUFWCLKEN == 1'b0)
    begin
       if (outbuffer_write_enable[1] == 1'b0)
       begin
           D1_outbuffer[outbuffer_write_address] <= OUTBUFWDATA;
       end
    end
end

always @(negedge MCLK) //read 
begin   
    if(nBOUTCLKEN == 1'b0)
    begin
        D1_outbuffer_read_data <= D1_outbuffer[outbuffer_read_address];
    end
end

//asynchronous code
/*
always @(negedge nOUTBUFWCLKEN) //write
begin
    if (outbuffer_write_enable[1] == 1'b0)
    begin
        D1_outbuffer[outbuffer_write_address] <= OUTBUFWDATA;
    end
end
*/

initial
begin
    $readmemb("D1_outbuffer.txt", D1_outbuffer);
end

endmodule