*-----------------------------------------------------------
* Title      : BubbleDrive8_testprogram
* Written by : Raki
* Date       : 
* Description:
*-----------------------------------------------------------

    ORG     $0
VECTORS dc.l $00001000                                      ;reset initial SP
        dc.l $00000008                                      ;reset initial PC

    ORG     $8
    BOOTLOADER:
        move.w #4191, d0                                    ;repeat 4192 times
        BOOTLOADER_WaitForController:
            nop                                             ;I don't know the internal program the BMC executes
            dbf d0, BOOTLOADER_WaitForController            ;Konami engineer added 4112 nop loops at that time

        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008                                   ;what circuitry acts as watchdog? idk

        lea $14C, a0                                        ;bubble memory error map start address in the BOOTLOADER area
        lea $d00, a1                                        ;target address, does the BMC uses this data using DMA? not verified
        move.w #75, d0                                      ;repeat 76 times
        BOOTLOADER_CopyErrormap:                            ;8*4*76=2432bits, FBM54DB needs 584bits of error map
            move.l (a0)+, (a1)+                             ;2432/4=608, 14 or 15bits of CRC(???) data should be supplied(by observation)
            dbf d0, BOOTLOADER_CopyErrormap                 ;without this valid data, the BMC ignores 1st, 2nd, 3rd page access request

        move.w $78000, d0                                   ;expansion port diagnostic ROM base address
        cmpi.w #$5555, d0                                   ;check for 0x5555
        beq.w BOOTLOADER_Jump2ExpROM

        lea $40000, a0
        move.w #$0, $4(a0)                                  ;write 0 to 0x40004: bubble buffer DMA pointer initialization(???)
        move.w $6(a0), d0                                   ;copy data of 0x40006: controller status
        cmpi.w #$240, d0                                    ;compare
        bne.w BOOTLOADER

        move.w #$1, $0(a0)                                  ;load page 0x001
        nop                                                 ;BMC is quite slow, works at 4MHz. MC6801(??)
        move.w #$1, $2(a0)                                  ;READ
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$1, $0(a0)                                  ;load page 0x001
        nop
        move.w #$1, $2(a0)                                  ;READ
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$801, $0(a0)                                ;write to page 0x801
        nop
        move.w #$1, $2(a0)                                  ;WRITE
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #0, $4(a0)                                   ;initialize controller
        move.w #$1, d1                                      ;set page 0x001 in D1
        lea $A00, a1                                        ;copy pages from A00
        move.w #5, d0                                       ;consecutive 6 pages
        BOOTLOADER_LoadRAMTest:
            move.w #0, $4(a0)                               ;initialize controller
            move.w d1, $0(a0)                               ;set page
            nop
            move.w #1, $2(a0)                               ;READ
            move.b #1, $5E008                               ;kick the Z80 watchdog
            move.b #0, $5E008
            bsr.w BOOTLOADER_funcBubbleWait_loop

            move.w $0(a0), d2                               ;copy last 6 bits
            move.w d2, $F80                                 ;place last 5 bits on F80
            lea $F00, a2                                    ;set source address
            move.w #65, d3                                  ;repeat 66 times
            BOOTLOADER_LoadRAMTest_ShiftPage:
                move.l (a2), d2                             ;start shifting: same as the original Konami code
                lsl.l #6, d2
                swap d2
                move.w d2, (a2)+
                dbf d3, BOOTLOADER_LoadRAMTest_ShiftPage

            lea $F00, a2
            move.w #31, d3
            BOOTLOADER_LoadRAMTest_CopyPage:
                move.l (a2)+, (a1)+
                dbf d3, BOOTLOADER_LoadRAMTest_CopyPage
        
        addq.w #1, d1

        dbf d0, BOOTLOADER_LoadRAMTest

        move.w #0, $4(a0)                                   ;initialize controller
        jmp $A00

        BOOTLOADER_Jump2ExpROM:
            jmp $78002

        BOOTLOADER_funcBubbleWait:
            move.w #$8000, d4                               ;signed -32768
            BOOTLOADER_funcBubbleWait_loop:
                nop
                dbf d4, BOOTLOADER_funcBubbleWait_loop
            rts




    ORG     $A00
    INITIALIZATION:                                         ;initial RAM test routines
        lea $1000, sp                 
        
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        nop

        move.b #1, $5C001                                   ;morning music code latch
        nop

        move.w #$8000, d0
        INITIALIZATION_DelayLoop:
            nop
            dbf d0, INITIALIZATION_DelayLoop                ;initial delay

        move.b #0, $5E004                                   ;Z80 interrupt
        nop
        nop
        move.b #1, $5E004

        move.l #$0, d0                                      ;initialize d0
        move.l #$0, d1                                      ;initialize d1
        move.l #$0, d2                                      ;initialize d2
        move.l #$0, d3                                      ;initialize d3
        move.l #$0, d4                                      ;initialize d4
        move.l #$0, d7                                      ;initialize d7

        ;bit 0: WORK RAM
        ;bit 1: Z80 RAM
        ;bit 2: Palette RAM
        ;bit 3: Expansion RAM
        ;bit 4: Scroll RAM
        ;bit 5: TM Code RAM
        ;bit 6: TM Color RAM
        ;bit 7: OBJ List RAM
        ;bit 8: Character RAM

        move.w #1, -(sp)                                    ;Palette RAM test
        move.l #$5A000, -(sp)
        move.l #$1000, -(sp)
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #2, d2
        or.w d2, d7                                         ;save test result in d7[2]

        move.w #1, -(sp)                                    ;Work RAM test
        move.l #$10000, -(sp)
        move.l #$10000, -(sp)
        bsr.w funcRamTest
        move.w (sp)+, d2   
        or.w d2, d7                                         ;save test result in d7[0]

        move.w #0, -(sp)                                    ;Z80 RAM test
        move.l #$20000, -(sp)                
        move.l #$8000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #1, d2           
        or.w d2, d7                                         ;save test result in d7[1]

        move.w #1, -(sp)                                    ;expansion RAM
        move.l #$70000, -(sp)                
        move.l #$4000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #3, d2           
        or.w d2, d7                                         ;save test result in d7[3]


        move.w #0, -(sp)                                    ;scroll RAM test
        move.l #$50000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #4, d2           
        or.w d2, d7                                         ;save test result in d7[4]

        move.w #1, -(sp)                                    ;tilemap RAM test
        move.l #$52000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #5, d2         
        or.w d2, d7                                         ;save test result in d7[5]

        move.w #0, -(sp)                                    ;tile color RAM test
        move.l #$54000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #6, d2           
        or.w d2, d7                                         ;save test result in d7[6]

        move.w #0, -(sp)                                    ;sprite RAM test
        move.l #$56000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #7, d2           
        or.w d2, d7                                         ;save test result in d7[7]

        move.w #1, -(sp)                                    ;Character RAM test
        move.l #$30000, -(sp)                
        move.l #$10000, -(sp)                   
        bsr.w funcRamTest                  
        move.w (sp)+, d2
        lsl.w #8, d2                
        or.w d2, d7                                         ;save test result in d7[8]

        move.w d7, $800                                     ;save RAM test result to 0x800

        move.l #$10000, -(sp)
        move.w #64, -(sp)
        move.w #7, -(sp)                                    ;from 0x380
        bsr.w funcLoadBubble

        jmp $10000                                          ;goto work ram


        ;FUNCTION RAMTEST
        funcRamTest:                                        ;bit width flag -> start address -> test length -> return address
            movea.l (sp)+, a2                               ;pop return address
            move.l (sp)+, d1                                ;pop test length
            movea.l (sp)+, a1                               ;pop start address
        
            lsr.l #1, d1                                    ;divide by 2
            subi.l #1, d1                                   ;test length - 1

            move.w (sp)+, d2                                ;pop bit width flag(0 = 8bit, 1 = 16bit)
            btst.l #$0, d2                                  ;1 = WORDTEST 0 = BYTETEST
            beq.s BYTETEST                                  ;if 0(Z=1), go to BYTETEST if 1(Z=0) go to WORDTEST

            move.w #0, d2                                   ;initialize d2

                WORDTEST:       
                    move.w #$FFFF, d3
                    bsr.w FILLWORD
                    move.w #$5555, d3
                    bsr.w FILLWORD
                    move.w #$AAAA, d3
                    bsr.w FILLWORD
                    move.w #$0000, d3
                    bsr.w FILLWORD

                    move.w d2, -(sp)                        ;set ok/failed flag
                    move.l a2, -(sp)                        ;push return address
                    rts  

                    FILLWORD:
                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        WORDRWTEST:
                            move.w d3, (a0)                 ;write $FFFF, 5555, AAAA, 0000
                            cmp.w (a0)+, d3                 ;read and compare
                            bne.s WORDERROR                 ;if not matches, goto ERROR
                            dbf d0, WORDRWTEST              ;loop
                        rts

                        WORDERROR:
                            bsr.s ERROR
                            dbf d0, WORDRWTEST      

                BYTETEST:
                    addq.l #1, a1                            ;start addr +1(BYTE ACCESS)   

                    move.w #$FF, d3
                    bsr.w FILLBYTE
                    move.w #$55, d3
                    bsr.w FILLBYTE
                    move.w #$AA, d3
                    bsr.w FILLBYTE
                    move.w #$00, d3
                    bsr.w FILLBYTE

                    move.w d2, -(sp)                        ;set ok/failed flag
                    move.l a2, -(sp)                        ;push return address
                    rts

                    FILLBYTE:
                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        BYTERWTEST:                    
                            move.b d3, (a0)                 ;write $FF, 55, AA, 00
                            cmp.b (a0), d3                  ;read and compare
                            addq.l #2, a0                   ;+2 increment
                            bne.s BYTEERROR                 ;if not matches, goto ERROR
                            dbf d0, BYTERWTEST              ;loop
                        rts

                        BYTEERROR:
                            bsr.s ERROR
                            dbf d0, BYTERWTEST

                ERROR:         
                    move.w #1, d2                           ;set error flag
                    rts        


        ;
        ;           FUNCTION LOADBUBBLE
        ;
        ;ARGS: START PAGE ADDRESS
        ;      CONSECUTIVE PAGE LENGTH
        ;      DESTINATION MEMORY ADDRESS   
        ;JSR:  RETURN ADDRESS 
        funcLoadBubble:                                     ;start page -> consecutive page length - > destination address -> return address
            movea.l (sp)+, a3                               ;pop return address
            move.w (sp)+, d0                                ;pop start page
            move.w (sp)+, d1                                ;pop consecutive page length
            movea.l (sp)+, a2                               ;pop destination address

            lea $40000, a1                                  ;bubble memory controller register
            subi.l #1, d1                                   ;consecutive page length - 1 

            READ:
                move.w #0, $4(a1)                           ;initialize controller
                move.w d0, (a1)                             ;set page
                nop
                move.w #1, $2(a1)                           ;read page

                move.b #1, $5E008                           ;kick the watchdog
                move.b #0, $5E008

                move.w #$8000, d7
                WAIT:
                    nop
                    dbf d7, WAIT                            ;loop

                move.w (a1), d2                             ;move last byte to d2
                move.w d2, $F80                             ;move last byte to F80

                lea $F00, a0                                ;first address of the page
                move.w #65, d7
                SHIFT:
                    move.l (a0), d2                         ;get raw data
                    lsl.l #6, d2                            ;shift 6 bits left
                    swap d2                                 ;high 16 low 16 swap
                    move.w d2, (a0)+                        ;write shifted data
                    dbf d7, SHIFT                           ;loop 66 times

                lea $F00, a0                                ;first address of the page
                move.w #31, d7
                COPY:
                    move.l (a0)+, (a2)+
                    dbf d7, COPY                            ;loop 32 times

                addq.w #1, d0                               ;start page +1
                dbf d1, READ

            move.l a3, -(sp)                                ;push return address
            rts 




    ORG    $10000
    MAINTEST:   
        move.l #$30000, -(sp) ;copy tiles
        move.w #91, -(sp)
        move.w #1024, -(sp)
        jsr funcLoadBubble

        move.l #$5A000, -(sp) ;copy palette
        move.w #1, -(sp)
        move.w #1023, -(sp)
        jsr funcLoadBubble


        TITLEPROGRAM:
            move.w #12, -(sp)
            move.w #12, -(sp)
            move.w #$F060, -(sp)
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            move.w #18, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            move.w #$F05F, -(sp)
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w FILLTILEMAP      

            move.w #0, d7
            move.w #7, d6
            DRAWUPPERTITLEBANNER:
                move.w #8, -(sp)
                move.w #2, -(sp)
                move.w #$F0F0, -(sp)
                move.w #$0001, -(sp)
                move.w d7, -(sp)
                move.w #3, -(sp)
                move.w #1, -(sp)
                bsr.w DRAWTILEMAP
                addi.w #8, d7
                dbf d6, DRAWUPPERTITLEBANNER

            move.w #0, d7
            move.w #7, d6
            DRAWLOWERTITLEBANNER:
                move.w #8, -(sp)
                move.w #2, -(sp)
                move.w #$F0F0, -(sp)
                move.w #$0001, -(sp)
                move.w d7, -(sp)
                move.w #27, -(sp)
                move.w #1, -(sp)
                bsr.w DRAWTILEMAP
                addi.w #8, d7
                dbf d6, DRAWLOWERTITLEBANNER

            BBDLOGO:
                move.w #18, -(sp)
                move.w #6, -(sp)
                move.w #$F100, -(sp)
                move.w #$0000, -(sp)
                move.w #7, -(sp)
                move.w #8, -(sp)
                move.w #0, -(sp)
                bsr.w DRAWTILEMAP

            lea TITLEMESSAGE2, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #7, -(sp)
            move.w #16, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea TITLEMESSAGE1, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #16, -(sp)
            move.w #23, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea TITLEMESSAGE3, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #15, -(sp)
            move.w #24, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            TITLEKEYINWAIT:
                move.b #1, $5E008                               ;kick the watchdog
                move.b #0, $5E008

                move.w $5CC00, d0
                btst.l #$3, d0
                beq.s TESTMENU

                move.w #$8000, d7
                BANNERSCROLLDELAY:
                    nop
                    dbf d7, BANNERSCROLLDELAY                   ;loop

                lea $50431, a0                                  ;TILEMAP-B
                lea $505B1, a1                                  ;TILEMAP-B
                move.w #15, d0
                BANNERSCROLL:
                    move.b (a0), d1
                    cmpi.b #$FF, d1
                    beq.s BANNERSCROLLLOOP
                    addq.b #1, d1
                    bra.s BANNERSCROLLINC
                    BANNERSCROLLLOOP:
                        move.b #$00, d1
                    BANNERSCROLLINC:
                        move.b d1, (a0)
                        move.b d1, d2
                        eori.b #$FF, d2                         ;reversed scroll direction
                        move.b d2, (a1)
                        add.l #2, a0
                        add.l #2, a1
                    dbf d0, BANNERSCROLLINC
                bra.s TITLEKEYINWAIT

TITLEMESSAGE1   dc.w 'BubbleDrive8', $0000
TITLEMESSAGE2   dc.w 'System Test Program', $0000
TITLEMESSAGE3   dc.w '2020-2021 Raki', $0000

        TESTMENU:
            move.w #$F000, -(sp)                            ;erase tilemap A
            move.w #$0001, -(sp)
            move.w #0, -(sp)
            bsr.w FILLTILEMAP 

            move.w #$F05F, -(sp)                            ;erase tilemap B
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w FILLTILEMAP  

            move.w #7, d6                                   ;print test menu items: 8 lines
            move.w #8, d7                                   ;YPOS of first line
            lea TESTMENUITEM1, a4
            TESTMENU_PrintList:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #4, -(sp)
                move.w d7, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d7
                add.l #28, a4                               ;get a new string from addr+28

                dbf  d6, TESTMENU_PrintList

            move.w #$FFFF, -(sp)                            ;initialize previous key input comparison register to FFFF
            move.w #$FFFF, -(sp)                            ;initialize previous key input comparison register to FFFF

            move.w #1, d6                                   ;menu item indicator register
            move.w #8, d5                                   ;initialize cursor position

            move.w #1, -(sp)                                ;draw cursor on 1st position
            move.w #1, -(sp)
            move.w #$F01E, -(sp)
            move.w #$0000, -(sp)
            move.w #3, -(sp)
            move.w d5, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            TESTMENUKEYINWAIT:
                move.w (sp)+, d0                            ;restore key in data
                move.w (sp)+, d1

                move.w $5CC02, d4                           ;get P1 button register
                btst.l #$4, d4                              ;check for power-up(gradius)
                beq TESTMENUSWITCHER

                move.w d1, d0                               ;move current value to old value register
                move.w $5CC02, d1                           ;get P1 button register
                not.w d0                                    ;invert previous key input data
                or.w d1, d0                                 ;negedge = ~previous || current

                move.w d1, -(sp)                            ;store key in data
                move.w d0, -(sp)

                btst.l #$3, d0                              ;check for DOWN
                beq TESTMENUINCREASE
                btst.l #$2, d0                              ;check for UP
                beq TESTMENUDECREASE
                bra.s TESTMENUKEYINDELAY
                

                TESTMENUINCREASE:
                    cmpi #8, d6                             ;if 8
                    beq TESTMENUMOVECURSOR
                    addq.w #1, d6
                    bra.s TESTMENUMOVECURSOR
                TESTMENUDECREASE:
                    cmpi #1, d6                             ;if 1
                    beq TESTMENUMOVECURSOR
                    subq.w #1, d6

                TESTMENUMOVECURSOR:
                    move.w #1, -(sp)                        ;clear previous cursor
                    move.w #1, -(sp)
                    move.w #$F000, -(sp)
                    move.w #$0000, -(sp)
                    move.w #3, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w DRAWTILEMAP

                    move.w d6, d5                           ;update cursor position
                    addi.w #7, d5

                    move.w #1, -(sp)                        ;redraw cursor on new position
                    move.w #1, -(sp)
                    move.w #$F01E, -(sp)
                    move.w #$0000, -(sp)
                    move.w #3, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w DRAWTILEMAP
                TESTMENUKEYINDELAY:
                    jsr funcFixedDelay
                    bra.w TESTMENUKEYINWAIT  

TESTMENUITEM1   dc.w '1.Show RAM test result   ', $0000
TESTMENUITEM2   dc.w '2.Screen test            ', $0000
TESTMENUITEM3   dc.w '3.Button/DIPSW input test', $0000
TESTMENUITEM4   dc.w '4.RF2 IO board test      ', $0000
TESTMENUITEM5   dc.w '5.Jump to 0x78002        ', $0000
TESTMENUITEM6   dc.w '6.Show CHARRAM data      ', $0000
TESTMENUITEM7   dc.w '7.Return to title screen ', $0000
TESTMENUITEM8   dc.w '8.Contributors           ', $0000

                TESTMENUSWITCHER:
                    cmpi #1, d6
                    beq TESTROUTINE_RAM
                    cmpi #2, d6
                    beq TESTROUTINE_Screen
                    cmpi #3, d6
                    beq TESTROUTINE_Input
                    cmpi #4, d6
                    beq TESTROUTINE_RF2IO
                    cmpi #5, d6
                    beq TESTROUTINE_JMP
                    cmpi #6, d6
                    beq TESTROUTINE_CHARRAM
                    cmpi #7, d6
                    beq TESTROUTINE_Return
                    cmpi #8, d6
                    beq TESTROUTINE_Contributors
                    bra.w TESTMENUKEYINWAIT

        TESTROUTINE_RAM:
            move.w #$F000, -(sp)                        ;clear tilemap A
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            bsr.w FILLTILEMAP

            move.w #$F05F, -(sp)                        ;clear tilemap B
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w FILLTILEMAP 

            lea RAMTESTMESSAGE1, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #11, -(sp)
            move.w #4, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea RAMTESTMESSAGE2, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #42, -(sp)
            move.w #4, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            move.w #1, d6                               ;repeat 2 times
            move.w #1, d4                               ;xpos
            move.w #7, d5                               ;ypos
            lea RAM1A, a4
            TESTROUTINE_RAM_PrintCPUAddrList:
                move.w #4, d7
                TESTROUTINE_RAM_PrintCPUAddrList_left:
                    move.l a4, -(sp)
                    move.w #1, -(sp)
                    move.w d4, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT

                    addq.w #3, d5
                    add.l #32, a4

                    dbf  d7, TESTROUTINE_RAM_PrintCPUAddrList_left

                    move.w #7, d5                       ;reset ypos to draw right side
                    addi.w #32, d4
                dbf d6, TESTROUTINE_RAM_PrintCPUAddrList

            move.w #1, d6                               ;repeat 2 times
            move.w #4, d4                               ;xpos
            move.w #8, d5                               ;ypos
            lea RAM1B, a4
            TESTROUTINE_RAM_PrintCPUChipList:
                move.w #4, d7
                TESTROUTINE_RAM_PrintCPUChipList_left:
                    move.l a4, -(sp)
                    move.w #1, -(sp)
                    move.w d4, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT

                    addq.w #3, d5
                    add.l #14, a4

                    dbf  d7, TESTROUTINE_RAM_PrintCPUChipList_left

                    move.w #8, d5                       ;reset ypos to draw right side
                    addi.w #32, d4
                dbf d6, TESTROUTINE_RAM_PrintCPUChipList

            TESTROUTINE_RAM_KeyInDelay:
                jsr funcFixedDelay
            bra.w TESTROUTINE_RAM_KeyInDelay




RAMTESTMESSAGE1 dc.w 'CPU BOARD'
RAMTESTMESSAGE2 dc.w 'VIDEO BOARD'

RAM1A           dc.w '0x00000-0x00FFF Shared RAM   ', $0000
RAM2A           dc.w '0x10000-0x1FFFF Work RAM     ', $0000
RAM3A           dc.w '0x20000-0x27FFF Z80 RAM      ', $0000
RAM4A           dc.w '0x5A000-0x5AFFF Palette RAM  ', $0000
RAM5A           dc.w '0x70000-0x73FFF Expansion RAM', $0000
RAM6A           dc.w '0x50000-0x50FFF TM Scroll RAM', $0000
RAM7A           dc.w '0x52000-0x53FFF TM Code RAM  ', $0000
RAM8A           dc.w '0x54000-0x55FFF TM Color RAM ', $0000
RAM9A           dc.w '0x56000-0x56FFF OBJ List RAM ', $0000
RAM10A          dc.w '0x30000-0x3FFFF Character RAM', $0000

RAM1B           dc.w '      6116*2', $0000
RAM2B           dc.w '      4416*8', $0000
RAM3B           dc.w '      4416*2', $0000
RAM4B           dc.w '      6116*2', $0000
RAM5B           dc.w '      6264*2', $0000
RAM6B           dc.w '  22D 6116*1', $0000
RAM7B           dc.w ' 15BC 6264*2', $0000
RAM8B           dc.w '  15D 6264*1', $0000
RAM9B           dc.w '  25D 6116*1', $0000
RAM10B          dc.w '2-7AB 4416*8', $0000

RAMTESTUNTESTED dc.w 'UNTESTED'
RAMTESTPASSED   dc.w 'PASSED'
RAMTESTFAILED   dc.w 'FAILED'

        TESTROUTINE_Screen:
        TESTROUTINE_Input:
        TESTROUTINE_RF2IO:
        TESTROUTINE_JMP:
        TESTROUTINE_CHARRAM:
        TESTROUTINE_Return:
        TESTROUTINE_Contributors:
            move.w #$F000, -(sp)                        ;clear tilemap A
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            bsr.w FILLTILEMAP

            move.w #$F05F, -(sp)                        ;clear tilemap B
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w FILLTILEMAP 

            bra.w TITLEPROGRAM                          ;return to title screen

        
        ;
        ;           DRAWTILEMAP
        ;
        ;ARGS: GRAPHIC WIDTH
        ;      GRAPHIC HEIGHT
        ;      VRAM: PR(4), FLIP(1), CHARRAM ADDRESS(11)
        ;      COLORRAM: FLIP(1), PALETTE CODE(7)
        ;      GRAPHIC X POSITION
        ;      GRAPHIC Y POSITION
        ;      TILEMAP A=0/B=1
        ;JSR:  RETURN ADDRESS 
        DRAWTILEMAP:                                        
                                                            ;Width -> Height -> VRAM priority/flip/CHARRAMADDR
                                                            ;color RAM flip/palette -> Xpos -> Ypos -> tilemap A/B -> return address

            move.l #0, d0                                   ;initialize
            move.l #0, d1
            move.l #0, d2
            move.l #0, d3
            move.l #0, d4

            movea.l (sp)+, a2                               ;pop return address

            move.w (sp)+, d0                                ;pop tilemap A/B(0 = A, 1 = B)
            btst.l #$0, d0                                  ;1 = TILEMAP-B 0 = TILEMAP-A
            beq.s SETTMADRAWADDR                            ;if 0(Z=1), go to SETTMA if 1(Z=0) go to SETTMB

            SETTMBDRAWADDR:
                lea $53000, a0                              ;ADDR offset + VRAM 2 base address
                lea $55000, a1                              ;ADDR offset + COLOR RAM 2 base address
                bra SETPOSOFFSET

            SETTMADRAWADDR:
                lea $52000, a0                              ;ADDR offset + VRAM 1 base address
                lea $54000, a1                              ;ADDR offset + COLOR RAM 1 base address

            SETPOSOFFSET:
                move.w (sp)+, d0                            ;pop Ypos
                mulu.w #64, d0                              ;d0 = Ypos * 64
                add.w (sp)+, d0                             ;pop Xpos and d0 = d0 + Xpos
                lsl.l #1, d0                                ;offset * 2
                add.l d0, a0                                ;a0 = VRAM, a1 = COLOR RAM
                add.l d0, a1
            
            SETPROPERTIES:
                move.w (sp)+, d1                            ;pop color RAM flip/palette number
                move.w (sp)+, d0                            ;pop VRAM priority/flip/CHARRAMADDR

            
            move.w (sp)+, d2                                ;pop height
            subi #1, d2                                     ;set loop counter

            move.l #64, d4                                  ;set full horizontal tile length(max 64 tiles)
            sub.w (sp), d4                                  ;copy width
            lsl.l #1, d4                                    ;width * 2
            YDRAW:
                move.w (sp), d3                             ;copy width
                subi.w #1, d3                               ;set loop counter
                XDRAW:
                    move.w d0, (a0)+                        ;write tile property to VRAM
                    move.w d1, (a1)+                        ;write tile color to COLORRAM
                    add.w #1, d0                            ;increase CHAR RAM pointer
                    dbf d3, XDRAW
                add.l d4, a0                                ;set next line start address
                add.l d4, a1
                dbf d2, YDRAW

            addq.l #2, sp                                   ;move stack pointer
            move.l a2, -(sp)                                ;push return address
            rts 


        ;
        ;           FILLTILEMAP
        ;
        ;ARGS: VRAM: PR(4), FLIP(1), CHARRAM ADDRESS(11)
        ;      COLORRAM: FLIP(1), PALETTE CODE(7)
        ;      TILEMAP A=0/B=1
        ;JSR:  RETURN ADDRESS 
        FILLTILEMAP:                                        
                                                            ;VRAM priority/flip/CHARRAMADDR
                                                            ;color RAM flip/palette -> tilemap A/B
            movea.l (sp)+, a2                               ;pop return address

            move.w (sp)+, d0                                ;pop tilemap A/B(0 = A, 1 = B)
            btst.l #$0, d0                                  ;1 = TILEMAP-B 0 = TILEMAP-A
            beq.s SETTMAFILLADDR                            ;if 0(Z=1), go to SETTMA if 1(Z=0) go to SETTMB

            SETTMBFILLADDR:
                lea $53000, a0                              ;ADDR offset + VRAM 2 base address
                lea $55000, a1                              ;ADDR offset + COLOR RAM 2 base address
                bra FILLTILES

            SETTMAFILLADDR:
                lea $52000, a0                              ;ADDR offset + VRAM 1 base address
                lea $54000, a1                              ;ADDR offset + COLOR RAM 1 base address

            FILLTILES:
            move.w (sp)+, d1                                ;pop VRAM properties
            move.w (sp)+, d0                                ;pop color RAM properties

            move.w #$7FF, d2                                ;set RAM length(byte 000-FFF)
            FILLLOOP:
                move.w d0, (a0)+                            ;write tile property to VRAM
                move.w d1, (a1)+                            ;write tile color to COLORRAM
                dbf d2, FILLLOOP

            move.l a2, -(sp)                                ;push return address
            rts 


        ;
        ;           PRINTTEXT
        ;
        ;ARGS: STRING POINTER
        ;      PALETTE CODE(7)
        ;      XPOS
        ;      YPOS
        ;      TILEMAP A=0/B=1
        ;JSR:  RETURN ADDRESS
        PRINTTEXT:
            movea.l (sp)+, a3                               ;pop return address

            move.w (sp)+, d0                                ;pop tilemap A/B
            btst.l #$0, d0                                  ;1 = TILEMAP-B 0 = TILEMAP-A
            beq.s SETTMATEXTADDR

            SETTMBTEXTADDR:
                lea $53000, a0                              ;ADDR offset + VRAM 2 base address
                lea $55000, a1                              ;ADDR offset + COLOR RAM 2 base address
                bra SETTEXTPOSOFFSET

            SETTMATEXTADDR:
                lea $52000, a0                              ;ADDR offset + VRAM 1 base address
                lea $54000, a1                              ;ADDR offset + COLOR RAM 1 base address

            SETTEXTPOSOFFSET:
                move.w (sp)+, d0                            ;pop Ypos
                mulu.w #64, d0                              ;d0 = Ypos * 64
                add.w (sp)+, d0                             ;pop Xpos and d0 = d0 + Xpos
                lsl.l #1, d0                                ;offset * 2
                add.l d0, a0                                ;a0 = VRAM, a1 = COLOR RAM
                add.l d0, a1
            
            move.w (sp)+, d2                                ;pop color RAM flip/palette number
            andi.w #$007F, d2                               ;delete flip value

            movea.l (sp)+, a2                               ;pop string pointer

            TYPELOOP:
                ;letter 1
                move.w (a2)+, d0                            ;get two letters
                
                ror.w #$8, d0                               ;8bit right rotation
                cmpi.b #$00, d0                             ;if the ASCII code is $00
                beq TYPEQUIT                                ;goto TYPEQUIT

                subi #32, d0                                ;subtract 8'd32 to make the ASCII code to CHARRAM address
                move.w #$F000, d1                           ;initialize d1
                or.b d0, d1                                 ;write CHARRAM code

                move.w d1, (a0)+
                move.w d2, (a1)+

                ;letter2 
                lsr.w #$8, d0
                cmpi.b #$00, d0
                beq TYPEQUIT

                subi #32, d0                                ;subtract 8'd32 to make the ASCII code to CHARRAM address
                move.w #$F000, d1                           ;initialize d1
                or.b d0, d1                                 ;write CHARRAM code

                move.w d1, (a0)+
                move.w d2, (a1)+

                bra TYPELOOP

                TYPEQUIT:
                    move.l a3, -(sp)                                ;push return address
                    rts


        ;
        ;           funcFixedDelay
        ;
        funcFixedDelay:
            move.b #1, $5E008                           ;kick the watchdog
            move.b #0, $5E008
            move.w #$8000, d7
            funcFixedDelay_delayloop:
                nop
                dbf d7, funcFixedDelay_delayloop        ;loop
            rts


    SIMHALT             ; halt simulator



* Put variables and constants here

    END    BOOTLOADER        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
{"mode":"full","isActive":false}