onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /BubbleDrive8_top_tb/Main/PWRSTAT
add wave -noupdate /BubbleDrive8_top_tb/Main/MRST
add wave -noupdate /BubbleDrive8_top_tb/Main/emucore_en
add wave -noupdate /BubbleDrive8_top_tb/Main/tempsense_en
add wave -noupdate /BubbleDrive8_top_tb/temperature_low
add wave -noupdate /BubbleDrive8_top_tb/Main/nLED_DELAYING
add wave -noupdate /BubbleDrive8_top_tb/Main/nLED_STANDBY
add wave -noupdate /BubbleDrive8_top_tb/Main/nLED_PWROK
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/MCLK
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/TC77_0/LISTCOUNTER
add wave -noupdate /BubbleDrive8_top_tb/TC77_0/SERIALREG
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/nTEMPCS
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/TEMPCLK
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/TEMPSIO
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/TC_time
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/FIFOTEMP
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/FIFODLYTIME
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_tempsense_0/nDELAYING
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/counter12
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/SWAP
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/CLKOUT
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nBOOTEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nBSS
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nBSEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nBSEN_intl
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nREPEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nREPEN_intl
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/ACCTYPE
add wave -noupdate -radix decimal /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/ABSPAGE
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/Main/RELPAGE
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/__REF_CLK12M
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/MCLK_counter
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/bout_bootloop_cycle_counter
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/bout_propagation_delay_counter
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/bout_page_cycle_counter
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/BOUTCYCLENUM
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/__REF_nBOUTCLKEN_ORIG
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/TimingGenerator_0/nBOUTCLKEN
add wave -noupdate /BubbleDrive8_top_tb/Main/DOUT3
add wave -noupdate /BubbleDrive8_top_tb/Main/DOUT2
add wave -noupdate /BubbleDrive8_top_tb/Main/DOUT1
add wave -noupdate /BubbleDrive8_top_tb/Main/DOUT0
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/spi_state
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_table
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_addr
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_write_enable
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_write_clken
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_data_in
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_read_clken
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/map_data_out
add wave -noupdate /BubbleDrive8_top_tb/Main/USERROM_FLASH_nCS
add wave -noupdate /BubbleDrive8_top_tb/Main/USERROM_CLK
add wave -noupdate /BubbleDrive8_top_tb/Main/USERROM_MOSI
add wave -noupdate /BubbleDrive8_top_tb/Main/USERROM_MISO
add wave -noupdate /BubbleDrive8_top_tb/Main/CONFIGROM_nCS
add wave -noupdate /BubbleDrive8_top_tb/Main/CONFIGROM_CLK
add wave -noupdate /BubbleDrive8_top_tb/Main/CONFIGROM_MOSI
add wave -noupdate /BubbleDrive8_top_tb/Main/CONFIGROM_MISO
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/OUTBUFWRADDR
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/nOUTBUFWRCLKEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/OUTBUFWRDATA
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/FIFOBUFWRADDR
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/nFIFOBUFWRCLKEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/FIFOBUFWRDATA
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/spi_instruction
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/general_counter
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/spi_state
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/SIPOBuffer_0/SIPOWRADDR
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/SIPOBuffer_0/D7/nWRCLKEN
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/nFIFOSENDBOOT
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_emucore_0/SPIDriver_0/nFIFOSENDUSER
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/nFIFOSENDTEMP
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/return_fifo_state
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/fifo_state
add wave -noupdate -radix ascii /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/FIFO_OUTLATCH
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/nFIFOWR
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/sipo_buffer_addr
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/sipo_buffer_read_en
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/sipo_buffer_data
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/FIFOTEMP
add wave -noupdate -radix binary /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/FIFODLYTIME
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/dd_shift_counter
add wave -noupdate -radix binary /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/temp_unsigned
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/temp_int_bin
add wave -noupdate -radix binary /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/temp_int_bcd
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/temp_frac_bcd
add wave -noupdate -radix binary /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/time_bin
add wave -noupdate -radix binary /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/time_bcd
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/text_addr
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/text_read_en
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/line_v_counter
add wave -noupdate -radix unsigned /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/line_h_counter
add wave -noupdate -radix hexadecimal /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/ascii_page_number
add wave -noupdate -radix ascii /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/ADBUS
add wave -noupdate /BubbleDrive8_top_tb/Main/BubbleDrive8_usb_0/ACBUS
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {3503418 ns} 0} {{Cursor 3} {79513600 ns} 1}
quietly wave cursor active 1
configure wave -namecolwidth 251
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {3503693 ns} {3503881 ns}
