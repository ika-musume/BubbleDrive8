module SIPOBuffer
(
    //master clock
    input   wire            MCLK,

    //input
    input   wire            nSIPOWREN,
    input   wire    [12:0]  SIPOWRADDR,
    input   wire            SIPOWRDATA,
    input   wire            nSIPOWRCLKEN,

    //output
    input   wire    [9:0]   SIPORDADDR,
    output  wire    [7:0]   SIPORDDATA,
    input   wire            nSIPORDCLKEN
);

reg     [9:0]   sipo_write_address;
reg     [7:0]   sipo_we_decoder; //D7 D6 D5 D4 D3 D2 D1 D0

always @(*)
begin
    case(SIPOWRADDR[2:0])
        3'b000: sipo_we_decoder <= 8'b0111_1111 | {8{nSIPOWRCLKEN}};
        3'b001: sipo_we_decoder <= 8'b1011_1111 | {8{nSIPOWRCLKEN}};
        3'b010: sipo_we_decoder <= 8'b1101_1111 | {8{nSIPOWRCLKEN}};
        3'b011: sipo_we_decoder <= 8'b1110_1111 | {8{nSIPOWRCLKEN}};
        3'b100: sipo_we_decoder <= 8'b1111_0111 | {8{nSIPOWRCLKEN}};
        3'b101: sipo_we_decoder <= 8'b1111_1011 | {8{nSIPOWRCLKEN}};
        3'b110: sipo_we_decoder <= 8'b1111_1101 | {8{nSIPOWRCLKEN}};
        3'b111: sipo_we_decoder <= 8'b1111_1110 | {8{nSIPOWRCLKEN}};
    endcase
end

RAM1k1 D7
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[7]      ),
    .nWE                (sipo_we_decoder[7] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D6
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[6]      ),
    .nWE                (sipo_we_decoder[6] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D5
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[5]      ),
    .nWE                (sipo_we_decoder[5] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D4
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[4]      ),
    .nWE                (sipo_we_decoder[4] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D3
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[3]      ),
    .nWE                (sipo_we_decoder[3] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D2
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[2]      ),
    .nWE                (sipo_we_decoder[2] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D1
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[1]      ),
    .nWE                (sipo_we_decoder[1] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);
RAM1k1 D0
(
    .MCLK               (MCLK               ),
    .RDADDR             (SIPORDADDR         ),
    .WRADDR             (SIPOWRADDR[12:3]   ),
    .DIN                (SIPOWRDATA         ),
    .DOUT               (SIPORDDATA[0]      ),
    .nWE                (sipo_we_decoder[0] ),
    .nRDCLKEN           (nSIPORDCLKEN       ),
    .nWRCLKEN           (nSIPOWRCLKEN       )
);

endmodule