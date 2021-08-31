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
        lea $40000, a5
        lea $74000, a6
        move.w #4191, d0                                    ;repeat 4192 times
        BOOTLOADER_WaitForController:
            move.w $6(a5), (a6)+
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

        move.w #$0, $4(a5)                                  ;write 0 to 0x40004: bubble buffer DMA pointer initialization(???)
        move.w $6(a5), d0                                   ;copy data of 0x40006: controller status
        cmpi.w #$240, d0                                    ;compare
        bne.w BOOTLOADER

        move.w #$1, $0(a5)                                  ;load page 0x001
        nop                                                 ;BMC is quite slow, works at 4MHz. MC6801(??)
        move.w #$1, $2(a5)                                  ;READ
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$1, $0(a5)                                  ;load page 0x001
        nop
        move.w #$1, $2(a5)                                  ;READ
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$801, $0(a5)                                ;write to page 0x801
        nop
        move.w #$1, $2(a5)                                  ;WRITE
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #0, $4(a5)                                   ;initialize controller
        move.w #$1, d1                                      ;set page 0x001 in D1
        lea $A00, a1                                        ;copy pages from A00
        move.w #5, d0                                       ;consecutive 6 pages
        BOOTLOADER_LoadRAMTest:
            move.w #0, $4(a5)                               ;initialize controller
            move.w d1, $0(a5)                               ;set page
            nop
            move.w #1, $2(a5)                               ;READ
            move.b #1, $5E008                               ;kick the Z80 watchdog
            move.b #0, $5E008
            bsr.w BOOTLOADER_funcBubbleWait_loop

            move.w $0(a5), d2                               ;copy last 6 bits
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

        move.w #0, $4(a5)                                   ;initialize controller
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
        bset.l #$0, d7                                      ;set bit 0 flag
        
        ;bit 0: shared RAM
        ;bit 1: WORK RAM
        ;bit 2: Z80 RAM
        ;bit 3: Palette RAM
        ;bit 4: Expansion RAM
        ;bit 5: Scroll RAM
        ;bit 6: TM Code RAM
        ;bit 7: TM Color RAM
        ;bit 8: OBJ List RAM
        ;bit 9: Character RAM

        move.w #1, -(sp)                                    ;Palette RAM test
        move.l #$5A000, -(sp)
        move.l #$1000, -(sp)
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #3, d2
        or.w d2, d7                                         ;save test result in d7[3]

        move.w #1, -(sp)                                    ;Work RAM test
        move.l #$10000, -(sp)
        move.l #$10000, -(sp)
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #1, d2
        or.w d2, d7                                         ;save test result in d7[1]

        move.w #1, -(sp)                                    ;expansion RAM
        move.l #$70000, -(sp)                
        move.l #$4000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #4, d2           
        or.w d2, d7                                         ;save test result in d7[4]

        move.w #0, -(sp)                                    ;scroll RAM test
        move.l #$50000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #5, d2           
        or.w d2, d7                                         ;save test result in d7[5]

        move.w #1, -(sp)                                    ;tilemap RAM test
        move.l #$52000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #6, d2         
        or.w d2, d7                                         ;save test result in d7[6]

        move.w #0, -(sp)                                    ;tile color RAM test
        move.l #$54000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #7, d2           
        or.w d2, d7                                         ;save test result in d7[7]

        move.w #0, -(sp)                                    ;sprite RAM test
        move.l #$56000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #8, d2           
        or.w d2, d7                                         ;save test result in d7[8]

        move.w #1, -(sp)                                    ;Character RAM test
        move.l #$30000, -(sp)                
        move.l #$10000, -(sp)                   
        bsr.w funcRamTest                  
        move.w (sp)+, d2
        lsl.w #8, d2
        lsl.w #1, d2                
        or.w d2, d7                                         ;save test result in d7[9]
        
        move.w #0, -(sp)                                    ;Z80 RAM test
        move.l #$20000, -(sp)                
        move.l #$8000, -(sp)                   
        bsr.w funcRamTest
        move.w (sp)+, d2
        lsl.w #2, d2           
        or.w d2, d7                                         ;save test result in d7[2]

        move.l d7, $800                                     ;save RAM test result to 0x800

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
        move.l #$5A000, -(sp) ;copy palette
        move.w #3, -(sp)
        move.w #1021, -(sp)
        jsr funcLoadBubble

        move.l #$30000, -(sp) ;copy tiles
        move.w #128, -(sp)
        move.w #1024, -(sp)
        jsr funcLoadBubble

        move.w #$FFFF, $810                             ;initialize current key input comparison register to FFFF
        move.w #$FFFF, $812                             ;initialize previous key input comparison register to FFFF


        *--------------------------------------------------------
        *
        *       TITLE SCREEN
        *
        *--------------------------------------------------------

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
            bsr.w funcFillTilemap      

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

            lea VERSION, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #0, -(sp)
            move.w #2, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            TITLEKEYINWAIT:
                move.b #1, $5E008                               ;kick the watchdog
                move.b #0, $5E008

                bsr.w funcCheckInput                        ;check P1 button input
                move.w (sp)+, d0                             ;get latest input 
                btst.l #$4, d0                              ;check for power-up(gradius) or fire(twinbee)
                beq TESTMENU

                move.w #$8000, d7
                BANNERSCROLLDELAY:
                    nop
                    dbf d7, BANNERSCROLLDELAY                   ;loop

                lea $50431, a0                                  ;TILEMAP-B upper banner
                lea $505B1, a1                                  ;TILEMAP-B lower banner
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
VERSION         dc.w 'B85:K:A:A:202108312B', $0000


        *--------------------------------------------------------
        *
        *       TESTMENU list page
        *
        *--------------------------------------------------------

        TESTMENU:
            jsr funcClearTilemap

            lea $50000, a0
            move.w #1023, d0                                ;vloop 512 times * 2
            TESTMENU_scrollreset:
                move.w #$0000, (a0)+                        ;move scroll value
                dbf d0, TESTMENU_scrollreset

            lea $56000, a0
            move.w #23, d0
            TESTMENU_objreset:
                move.w #$0000, (a0)+
                dbf d0, TESTMENU_objreset

            move.w #9, d6                                   ;print test menu items: 10 lines
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
                bsr.w funcCheckInput                        ;check P1 button input
                move.w (sp)+, d0                             ;get latest input 
                btst.l #$4, d0                              ;check for power-up(gradius) or fire(twinbee)
                beq TESTMENUSWITCHER
                btst.l #$3, d0                              ;check for DOWN
                beq TESTMENUINCREASE
                btst.l #$2, d0                              ;check for UP
                beq TESTMENUDECREASE
                bra.s TESTMENUKEYINDELAY
                

                TESTMENUINCREASE:
                    cmpi #10, d6                             ;if 10
                    beq TESTMENUKEYINDELAY
                    addq.w #1, d6
                    bra.s TESTMENUMOVECURSOR
                TESTMENUDECREASE:
                    cmpi #1, d6                             ;if 1
                    beq TESTMENUKEYINDELAY
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
TESTMENUITEM7   dc.w '7.Priority test          ', $0000
TESTMENUITEM8   dc.w '8.BMC debug program      ', $0000
TESTMENUITEM9   dc.w '9.Contributors           ', $0000
TESTMENUITEM10  dc.w '10.Return to title screen', $0000




        *--------------------------------------------------------
        *
        *       TESTMENUSWITCHER
        *
        *--------------------------------------------------------

                TESTMENUSWITCHER:
                    cmpi #1, d6
                    beq TSTRTNE_RAM
                    cmpi #2, d6
                    beq TSTRTNE_Screen
                    cmpi #3, d6
                    beq TSTRTNE_Input
                    cmpi #4, d6
                    beq TSTRTNE_RF2IO
                    cmpi #5, d6
                    beq TSTRTNE_JMP
                    cmpi #6, d6
                    beq TSTRTNE_CHARRAM
                    cmpi #7, d6
                    beq TSTRTNE_Pr
                    cmpi #8, d6
                    beq TSTRTNE_BMC
                    cmpi #9, d6
                    beq TSTRTNE_Contributors
                    cmpi #10, d6
                    beq TSTRTNE_Return
                    bra.w TESTMENUKEYINWAIT








        *--------------------------------------------------------
        *
        *       TESTMENU_RAM test subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_RAM:
            jsr funcClearTilemap

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

            ;
            ;   displays RAM address list
            ;
            move.w #1, d6                               ;repeat 2 times
            move.w #1, d4                               ;xpos
            move.w #7, d5                               ;ypos
            lea RAM1A, a4
            TSTRTNE_RAM_PrintCPUAddrList:
                move.w #4, d7
                TSTRTNE_RAM_PrintCPUAddrList_left:
                    move.l a4, -(sp)
                    move.w #1, -(sp)
                    move.w d4, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT

                    addq.w #3, d5
                    add.l #32, a4

                    dbf  d7, TSTRTNE_RAM_PrintCPUAddrList_left

                move.w #7, d5                           ;reset ypos to draw right side
                addi.w #32, d4

                dbf d6, TSTRTNE_RAM_PrintCPUAddrList

            ;
            ;   displays RAM chip list
            ;
            move.w #1, d6                               ;repeat 2 times
            move.w #4, d4                               ;xpos
            move.w #8, d5                               ;ypos
            lea RAM1B, a4
            TSTRTNE_RAM_PrintCPUChipList:
                move.w #4, d7
                TSTRTNE_RAM_PrintCPUChipList_left:
                    move.l a4, -(sp)
                    move.w #1, -(sp)
                    move.w d4, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT

                    addq.w #3, d5
                    add.l #14, a4

                    dbf  d7, TSTRTNE_RAM_PrintCPUChipList_left

                move.w #8, d5                           ;reset ypos to draw right side
                addi.w #32, d4

                dbf d6, TSTRTNE_RAM_PrintCPUChipList
            
            ;
            ;   displays RAM test result
            ;
            move.w #1, d6                               ;repeat 2 times
            move.w #17, d4                              ;xpos
            move.w #8, d5                               ;ypos
            move.w #0, d3                               ;initialize bit select reg
            TSTRTNE_RAM_PrintTestResult:
                move.w #4, d7
                TSTRTNE_RAM_PrintTestResult_left:
                    move.l $800, d0                     ;get test result
                    tst.w d3                            ;check shared RAM
                    beq TSTRTNE_RAM_PrintTestResult_exception

                    btst.l d3, d0
                    bne TSTRTNE_RAM_PrintTestResult_setfailed           ;set failed/passed branch

                    lea RAMTESTPASSED, a0                                   ;set passed flag
                    move.w #3, d0
                    bra.s TSTRTNE_RAM_PrintTestResult_print

                    TSTRTNE_RAM_PrintTestResult_setfailed:              ;set failed flag
                    lea RAMTESTFAILED, a0
                    move.w #4, d0
                    bra.s TSTRTNE_RAM_PrintTestResult_print

                    TSTRTNE_RAM_PrintTestResult_exception:              ;set untested flag: only for shared RAM
                    lea RAMTESTUNTESTED, a0
                    move.w #5, d0

                    TSTRTNE_RAM_PrintTestResult_print:
                        move.l a0, -(sp)
                        move.w d0, -(sp)                                    ;palette
                        move.w d4, -(sp)                                    ;xpos
                        move.w d5, -(sp)                                    ;ypos
                        move.w #0, -(sp)
                        bsr.w PRINTTEXT

                    addq.w #3, d5
                    addq.w #1, d3

                    dbf  d7, TSTRTNE_RAM_PrintTestResult_left

                move.w #8, d5                           ;reset ypos to draw right side
                addi.w #32, d4

                dbf d6, TSTRTNE_RAM_PrintTestResult
            
            TSTRTNE_RAM_KeyInDelay_a:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.s TSTRTNE_RAM_SwitchScrn
                jsr funcFixedDelay
                bra.s TSTRTNE_RAM_KeyInDelay_a

            TSTRTNE_RAM_SwitchScrn:
                move.w #0, d0                           ;initialize scroll value register
                move.w #255, d2                         ;hloop 256 times
                TSTRTNE_RAM_SwitchScrn_hloop:
                    lea $50001, a0
                    move.w #255, d1                     ;vloop 256 times
                    TSTRTNE_RAM_SwitchScrn_vloop:
                        move.b d0, (a0)                 ;move scroll value
                        add.l #2, a0                    ;addr+2
                        dbf d1, TSTRTNE_RAM_SwitchScrn_vloop
                    addq #1, d0
                    move.b #1, $5E008                                       ;kick the watchdog
                    move.b #0, $5E008
                    move.w #$800, d7
                    TSTRTNE_RAM_SwitchScrn_scrolldelay:
                        nop
                        dbf d7, TSTRTNE_RAM_SwitchScrn_scrolldelay      ;loop
                    dbf d2, TSTRTNE_RAM_SwitchScrn_hloop
            
            TSTRTNE_RAM_KeyInDelay_b:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.s TSTRTNE_RAM_KeyInDelay_b

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

RAMTESTUNTESTED dc.w 'UNTESTED', $0000
RAMTESTPASSED   dc.w 'PASSED', $0000
RAMTESTFAILED   dc.w 'FAILED', $0000







        *--------------------------------------------------------
        *
        *       TESTMENU_Screen subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Screen:
            jsr funcClearTilemap

            move.w $820, d0
            cmpi.w #$573, d0                    ;konami 573
            beq TSTRTNE_Screen_0                ;check DATA LOADED flag

            lea NOWLOADING, a0                  ;print nowloading
            move.l a0, -(sp)
            move.w #5, -(sp)
            move.w #9, -(sp)
            move.w #15, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            move.l #$34000, -(sp)               ;copy tiles
            move.w #256, -(sp)
            move.w #1152, -(sp)
            jsr funcLoadBubble

            move.w #$573, $820                  ;set DATA LOADED flag on $820

            TSTRTNE_Screen_0:
                move.w #$E000, -(sp)            ;clear tilemap B with black(transparent) tiles
                move.w #$0006, -(sp)
                move.w #1, -(sp)
                bsr.w funcFillTilemap

                move.w #32, -(sp)
                move.w #28, -(sp)
                move.w #$F200, -(sp)            ;test screen
                move.w #$0006, -(sp)
                move.w #0, -(sp)
                move.w #2, -(sp)
                move.w #0, -(sp)
                bsr.w DRAWTILEMAP

                move.w #$0007, d7               ;palette
                move.w #11, d6                  ;ypos
                move.w #3, d5                   ;loop counter
                TSTRTNE_Screen_0_loop:
                    move.w #14, -(sp)
                    move.w #2, -(sp)
                    move.w #$F580, -(sp)        ;test screen
                    move.w d7, -(sp)
                    move.w #9, -(sp)
                    move.w d6, -(sp)
                    move.w #0, -(sp)
                    bsr.w DRAWTILEMAP

                    addq.w #1, d7
                    addq.w #2, d6
                    dbf d5, TSTRTNE_Screen_0_loop

            TSTRTNE_Screen_KeyInDelay_a:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.s TSTRTNE_Screen_1
                jsr funcFixedDelay
                bra.s TSTRTNE_Screen_KeyInDelay_a

            TSTRTNE_Screen_1:
                move.w #$E000, -(sp)
                move.w #$0006, -(sp)
                move.w #1, -(sp)
                bsr.w funcFillTilemap

                move.w #13, d7                          ;28 tile vlines
                TSTRTNE_Screen_1_red_loopv:
                    move.w #15, d6                      ;32 tile hlines

                    TSTRTNE_Screen_1_red_looph:
                        move.w d7, d0                   ;copy vloop counter to d0
                        lsl.w #1, d0                    ;double the value(16*16 tiles)
                        addq.w #2, d0                   ;move 16 pixels down(invisible area)

                        move.w d6, d1                   ;copy hloop counter to d1
                        lsl.w #1, d1                    ;double the value(16*16 tiles)

                        move.w #2, -(sp)
                        move.w #2, -(sp)
                        move.w #$F1E0, -(sp)            ;hatched pattern
                        move.w #$0008, -(sp)            ;red
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #0, -(sp)
                        bsr.w DRAWTILEMAP

                        dbf d6, TSTRTNE_Screen_1_red_looph

                    dbf d7, TSTRTNE_Screen_1_red_loopv

                move.w #11, d7                          ;24 tile vlines
                TSTRTNE_Screen_1_white_loopv:
                    move.w #13, d6                      ;28 tile hlines

                    TSTRTNE_Screen_1_white_looph:
                        move.w d7, d0                   ;copy vloop counter to d0
                        lsl.w #1, d0                    ;double the value(16*16 tiles)
                        addq.w #4, d0                   ;move 32 pixels down(invisible area 16px+red pattern area 16px)

                        move.w d6, d1                   ;copy hloop counter to d1
                        lsl.w #1, d1                    ;double the value(16*16 tiles)
                        addq.w #2, d1                   ;move 16 pixels right(red pattern area 16px)

                        move.w #2, -(sp)
                        move.w #2, -(sp)
                        move.w #$F1E0, -(sp)            ;hatched pattern
                        move.w #$0002, -(sp)            ;white
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #0, -(sp)
                        bsr.w DRAWTILEMAP

                        dbf d6, TSTRTNE_Screen_1_white_looph

                    dbf d7, TSTRTNE_Screen_1_white_loopv

            TSTRTNE_Screen_KeyInDelay_b:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.s TSTRTNE_Screen_KeyInDelay_b

NOWLOADING      dc.w 'WAIT A MOMENT', $0000



        *--------------------------------------------------------
        *
        *       TESTMENU_INPUT subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Input:
            jsr funcClearTilemap

            move.w #2, d6                               ;repeat 3 times
            move.w #8, d4                               ;xpos
            move.w #19, d5                              ;ypos
            lea DIPSW0, a4
            TSTRTNE_Input_PrintSWList_loop:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w d4, -(sp)
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d5
                add.l #8, a4

                dbf d6, TSTRTNE_Input_PrintSWList_loop

            move.w #9, d6                                   ;repeat 10 times
            move.w #3, d4                                   ;xpos
            move.w #6, d5                                   ;ypos
            lea BTNLEFT, a4
            TSTRTNE_Input_PrintBtnList_loop:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w d4, -(sp)
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d5
                add.l #8, a4

                dbf d6, TSTRTNE_Input_PrintBtnList_loop

            lea PLAYERLIST, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #11, -(sp)
            move.w #5, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea $50051, a0
            move.w #7, d1                                   ;PLAYER LIST shift, shift 8 lines
            TSTRTNE_Input_PlayerList_shift:
                move.b #4, (a0)                             ;move scroll value
                add.l #2, a0                                ;addr+2
                dbf d1, TSTRTNE_Input_PlayerList_shift

            lea EXITMESSAGE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #4, -(sp)
            move.w #26, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            TSTRTNE_Input_ChkAll:
                move.w #3, d7                               ;button set x4
                move.w #10, d4                              ;xpos
                move.w #12, d5                              ;ypos
                lea $5CC02, a5                              ;1P bank
                TSTRTNE_Input_ChkAll_btn:
                    move.w #6, d6                           ;check 7 buttons
                    TSTRTNE_Input_ChkAll_btn_bt:
                        move.w (a5), d0
                        btst.l d6, d0
                        bne.s TSTRTNE_Input_ChkAll_btn_bt_off

                        lea BTNON, a4                                       ;button on
                        move.w #4, d1                                       ;red text
                        bra.s TSTRTNE_Input_ChkAll_btn_bt_prntbt

                        TSTRTNE_Input_ChkAll_btn_bt_off:
                        lea BTNOFF, a4                                      ;button off
                        move.w #6, d1                                       ;grey text

                        TSTRTNE_Input_ChkAll_btn_bt_prntbt:
                            move.l a4, -(sp)
                            move.w d1, -(sp)
                            move.w d4, -(sp)
                            move.w d5, -(sp)
                            move.w #0, -(sp)
                            bsr.w PRINTTEXT

                        subq.w #1, d5
                        dbf d6, TSTRTNE_Input_ChkAll_btn_bt

                    move.w #12, d5                                          ;reset ypos
                    addq.w #5, d4                                           ;next xpos
                    add.l #2, a5                                            ;next dip switch addr

                    dbf d7, TSTRTNE_Input_ChkAll_btn


                move.w #2, d7                               ;dipsw x3
                move.w #23, d4                              ;xpos
                move.w #19, d5                              ;ypos
                lea $5C402, a5                              ;DIPSW0
                TSTRTNE_Input_ChkAll_sw:
                    move.w #7, d6                           ;check 8 switches
                    TSTRTNE_Input_ChkAll_sw_bt:
                        move.w (a5), d0
                        btst.l d6, d0
                        bne.s TSTRTNE_Input_ChkAll_sw_bt_lo

                        lea DIPSWH, a4                                      ;dip sw high
                        bra.s TSTRTNE_Input_ChkAll_sw_bt_prntbt

                        TSTRTNE_Input_ChkAll_sw_bt_lo:
                        lea DIPSWL, a4                                      ;dip sw low

                        TSTRTNE_Input_ChkAll_sw_bt_prntbt:
                            move.l a4, -(sp)
                            move.w #1, -(sp)
                            move.w d4, -(sp)
                            move.w d5, -(sp)
                            move.w #0, -(sp)
                            bsr.w PRINTTEXT

                        subq.w #1, d4
                        dbf d6, TSTRTNE_Input_ChkAll_sw_bt

                    move.w #23, d4                                          ;reset xpos
                    addq.w #1, d5                                           ;ypos + 1
                    add.l #2, a5                                            ;next dip switch addr

                    dbf d7, TSTRTNE_Input_ChkAll_sw

                move.w #3, d7                               ;start button x4
                move.w #25, d4                              ;xpos
                TSTRTNE_Input_ChkAll_st:
                    move.w d7, d0                           ;get loop counter
                    addq.w #3, d0                           ;P1(d3), P2(d4), P3(d5??)...
                    move.w $5CC00, d1
                    btst.l d0, d1
                    bne.s TSTRTNE_Input_ChkAll_st_off

                    lea BTNON, a0                           ;START button ON(pressed)
                    move.w #4, d0
                    bra.s TSTRTNE_Input_ChkAll_st_prntbt

                    TSTRTNE_Input_ChkAll_st_off:
                        lea BTNOFF, a0                      ;START button OFF
                        move.w #6, d0

                    TSTRTNE_Input_ChkAll_st_prntbt:
                        move.l a0, -(sp)
                        move.w d0, -(sp)
                        move.w d4, -(sp)
                        move.w #13, -(sp)
                        move.w #0, -(sp)
                        bsr.w PRINTTEXT

                    subq.w #5, d4                                           ;xpos - 5
                    dbf d7, TSTRTNE_Input_ChkAll_st

                move.w #1, d7                               ;coin slot x2
                move.w #15, d4                              ;xpos
                TSTRTNE_Input_ChkAll_coin:
                    move.w d7, d0                           ;get loop counter
                    move.w $5CC00, d1
                    btst.l d0, d1
                    bne.s TSTRTNE_Input_ChkAll_coin_off

                    lea BTNON, a0                           ;START button ON(pressed)
                    move.w #4, d0
                    bra.s TSTRTNE_Input_ChkAll_coin_prntbt

                    TSTRTNE_Input_ChkAll_coin_off:
                        lea BTNOFF, a0                      ;START button OFF
                        move.w #6, d0

                    TSTRTNE_Input_ChkAll_coin_prntbt:
                        move.l a0, -(sp)
                        move.w d0, -(sp)
                        move.w d4, -(sp)
                        move.w #14, -(sp)
                        move.w #0, -(sp)
                        bsr.w PRINTTEXT

                    subq.w #5, d4                                           ;xpos - 5
                    dbf d7, TSTRTNE_Input_ChkAll_coin

                move.w $5CC00, d0
                btst.l #2, d0
                bne.s TSTRTNE_Input_ChkAll_svc_off

                lea BTNON, a0                           ;START button ON(pressed)
                move.w #4, d0
                bra.s TSTRTNE_Input_ChkAll_svc_prntbt

                TSTRTNE_Input_ChkAll_svc_off:
                    lea BTNOFF, a0                      ;START button OFF
                    move.w #6, d0

                TSTRTNE_Input_ChkAll_svc_prntbt:
                    move.l a0, -(sp)
                    move.w d0, -(sp)
                    move.w #10, -(sp)
                    move.w #15, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT

            jsr funcScrExitMessage

            TSTRTNE_Input_KeyInDelay:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_Input_ChkAll

DIPSW0          dc.w 'DIPSW1', $0000
DIPSW1          dc.w 'DIPSW2', $0000
DIPSW2          dc.w 'DIPSW3', $0000
DIPSWH          dc.w 'U', $0000
DIPSWL          dc.w 'D', $0000 
PLAYERLIST      dc.w '1P   2P   3P   4P', $0000
BTNLEFT         dc.w ' LEFT', $0000
BTNRIGHT        dc.w 'RIGHT', $0000
BTNUP           dc.w '   UP', $0000
BTNDOWN         dc.w ' DOWN', $0000
BTNA            dc.w '    A', $0000
BTNB            dc.w '    B', $0000
BTNC            dc.w '    C', $0000
BTNSTART        dc.w 'START', $0000
BTNCOIN         dc.w ' COIN', $0000
BTNSERVICE      dc.w '  SVC', $0000
BTNOFF          dc.w 'OFF', $0000
BTNON           dc.w 'ON ', $0000








        *--------------------------------------------------------
        *
        *       TESTMENU_RF2IO subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_RF2IO:
            jsr funcClearTilemap

            move.w #16, -(sp)
            move.w #2, -(sp)
            move.w #$F170, -(sp)                            ;steering wheel
            move.w #$0005, -(sp)
            move.w #8, -(sp)
            move.w #8, -(sp)
            move.w #1, -(sp)
            bsr.w DRAWTILEMAP

            move.w #16, -(sp)
            move.w #2, -(sp)
            move.w #$F1B0, -(sp)                            ;brake
            move.w #$0006, -(sp)
            move.w #8, -(sp)
            move.w #14, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            move.w #16, -(sp)
            move.w #2, -(sp)
            move.w #$F190, -(sp)                            ;accel
            move.w #$0006, -(sp)
            move.w #8, -(sp)
            move.w #20, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            lea RF2NEEDLE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #31, -(sp)
            move.w #8, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea $50081, a0
            move.w #7, d1                                   ;steering needle shift
            TSTRTNE_RF2IO_Needle_set:
                move.b #124, (a0)                           ;move scroll value(center)
                add.l #2, a0                                ;addr+2
                dbf d1, TSTRTNE_RF2IO_Needle_set

            move.w #2, d6                                   ;repeat 3 times
            move.w #6, d5                                   ;ypos
            lea RF2STEERING, a4
            TSTRTNE_RF2IO_PrntInList_loop:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #7, -(sp)                            ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #6, d5
                add.l #14, a4

                dbf d6, TSTRTNE_RF2IO_PrntInList_loop

            TSTRTNE_RF2IO_ChkAll:
                *   Steering wheel
                *
                move.w $70000,d6                            ;get IO board data
                move.w d6, d5             
                not.w d5                                    ;invert the value(left:0x00 center:0x40 right:0x7F)
                andi.w #$007F, d5                           ;get D[6:0]
                bsr.w TSTRTNE_RF2IO_Needle_max
                addi.w #61, d5                              ;add 61 to get scroll value(~0x40 + 0x3D = 0x7C)

                lea $50081, a0                              ;set scorll register base address
                move.w #7, d1                               ;steering needle shift: 8 times
                TSTRTNE_RF2IO_Needle_shift:
                    move.b d5, (a0)                         ;move scroll value(center)
                    add.l #2, a0                            ;addr+2
                    dbf d1, TSTRTNE_RF2IO_Needle_shift

                *   Brake pedal
                *      
                move.w d6, d5                               ;copy data to d5
                andi.w #$0300, d5                           ;get D[9:8]
                lsr.w #6, d5                                ;move to D[3:2]
                or.w #$0003, d5                             ;write 1 on D[1:0]

                move.w #15, d7                              ;repeat 16 times
                TSTRTNE_RF2IO_ChkAll_brk:
                    move.w #8, d0                           ;set x pos
                    add.w d7, d0                            ;add loop value(write from the right)
                    cmp.w d5, d7                            ;d7(loop value) - d5
                    beq.s TSTRTNE_RF2IO_ChkAll_brk_full
                    bpl.s TSTRTNE_RF2IO_ChkAll_brk_empty    ;draw empty tile
                    
                    TSTRTNE_RF2IO_ChkAll_brk_full:
                    move.w #4, d1                           ;full tile
                    bra.s TSTRTNE_RF2IO_ChkAll_brk_draw

                    TSTRTNE_RF2IO_ChkAll_brk_empty:
                        move.w #2, d1                           ;empty tile

                    TSTRTNE_RF2IO_ChkAll_brk_draw:
                        move.w #1, -(sp)
                        move.w #1, -(sp)
                        move.w #$F05F, -(sp)                    ;empty tile
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #14, -(sp)
                        move.w #1, -(sp)
                        bsr.w DRAWTILEMAP

                    dbf d7, TSTRTNE_RF2IO_ChkAll_brk


                *   Accel pedal
                *      
                move.w d6, d5                               ;copy data to d5
                andi.w #$E000, d5                           ;get D[15:13]
                lsr.w #8, d5                                ;move to D[7:5]
                lsr.w #4, d5                                ;move to D[3:1]
                or.w #$0001, d5                             ;write 1 on D[0]

                move.w #15, d7                              ;repeat 16 times
                TSTRTNE_RF2IO_ChkAll_accel:
                    move.w #8, d0                           ;set x pos
                    add.w d7, d0                            ;add loop value(write from the right)
                    cmp.w d5, d7                            ;d7(loop value) - d5
                    beq.s TSTRTNE_RF2IO_ChkAll_accel_full
                    bpl.s TSTRTNE_RF2IO_ChkAll_accel_empty    ;draw empty tile
                    
                    TSTRTNE_RF2IO_ChkAll_accel_full:
                    move.w #3, d1                           ;full tile
                    bra.s TSTRTNE_RF2IO_ChkAll_accel_draw

                    TSTRTNE_RF2IO_ChkAll_accel_empty:
                        move.w #2, d1                           ;empty tile

                    TSTRTNE_RF2IO_ChkAll_accel_draw:
                        move.w #1, -(sp)
                        move.w #1, -(sp)
                        move.w #$F05F, -(sp)                    ;empty tile
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #20, -(sp)
                        move.w #1, -(sp)
                        bsr.w DRAWTILEMAP

                    dbf d7, TSTRTNE_RF2IO_ChkAll_accel

            TSTRTNE_RF2IO_KeyInDelay:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_RF2IO_ChkAll

            TSTRTNE_RF2IO_Needle_max:
                    cmpi.w #$0000, d5
                    beq.s TSTRTNE_RF2IO_Needle_max_draw
                    cmpi.w #$007F, d5
                    beq.s TSTRTNE_RF2IO_Needle_max_draw

                    lea RF2STEERINGNOM, a0
                    move.l a0, -(sp)
                    move.w #4, -(sp)
                    move.w #21, -(sp)
                    move.w #6, -(sp)
                    move.w #0, -(sp)
                    bsr.w PRINTTEXT
                    rts

                    TSTRTNE_RF2IO_Needle_max_draw:
                        lea RF2STEERINGMAX, a0
                        move.l a0, -(sp)
                        move.w #4, -(sp)
                        move.w #21, -(sp)
                        move.w #6, -(sp)
                        move.w #0, -(sp)
                        bsr.w PRINTTEXT
                        rts

RF2STEERING     dc.w 'Steering   ', $0000
RF2BRAKE        dc.w 'Brake      ', $0000
RF2ACC          dc.w 'Accelerator', $0000
RF2STEERINGMAX  dc.w 'MAX', $0000
RF2STEERINGNOM  dc.w '   ', $0000
RF2NEEDLE       dc.w '|', $0000








        *--------------------------------------------------------
        *
        *       TESTMENU_JMP subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_JMP:
            lea JMPGOODBYE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #20, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            jmp $78002

JMPGOODBYE      dc.w 'Good bye!', $0000





        *--------------------------------------------------------
        *
        *       TESTMENU_CHARRAM subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_CHARRAM:
            move.w #$E000, -(sp)            ;clear tilemap B with black(transparent) tiles
            move.w #$0006, -(sp)
            move.w #1, -(sp)
            bsr.w funcFillTilemap

            move.w #0, d7                   ;tile code
            move.w #0, d6                   ;palette code

            TSTRTNE_CHARRAM_ChkVal:                             ;check key input
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input 
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_CHARRAM_tileinc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_CHARRAM_tiledec
                btst.l #$1, d0                                  ;check for RIGHT
                beq.s TSTRTNE_CHARRAM_palinc
                btst.l #$0, d0                                  ;check for LEFT
                beq.s TSTRTNE_CHARRAM_paldec

                bra.s TSTRTNE_CHARRAM_Draw                      ;nothing changes

            TSTRTNE_CHARRAM_tiledec:
                cmpi.w #$0, d7                                  ;test 0x0
                bne.s TSTRTNE_CHARRAM_tiledec_sub
                
                TSTRTNE_CHARRAM_tiledec_hold:                   ;hold
                bra.s TSTRTNE_CHARRAM_Draw

                TSTRTNE_CHARRAM_tiledec_sub:
                subi.w #$20, d7                                 ;tilecode - 0x20
                bra.s TSTRTNE_CHARRAM_tiledec_hold              ;goto hold

            TSTRTNE_CHARRAM_tileinc:
                cmpi.w #$480, d7                                ;test 0x480
                bne.s TSTRTNE_CHARRAM_tileinc_sub
                
                TSTRTNE_CHARRAM_tileinc_hold:                   ;hold
                bra.s TSTRTNE_CHARRAM_Draw

                TSTRTNE_CHARRAM_tileinc_sub:
                addi.w #$20, d7                                 ;tilecode + 0x20
                bra.s TSTRTNE_CHARRAM_tileinc_hold              ;goto hold

            TSTRTNE_CHARRAM_paldec:
                cmpi.w #$0, d6                                  ;test 0x0
                bne.s TSTRTNE_CHARRAM_paldec_sub
                
                TSTRTNE_CHARRAM_paldec_hold:                    ;hold
                bra.s TSTRTNE_CHARRAM_Draw

                TSTRTNE_CHARRAM_paldec_sub:
                subq.w #$1, d6                                  ;palette code - 0x1
                bra.s TSTRTNE_CHARRAM_paldec_hold               ;goto hold

            TSTRTNE_CHARRAM_palinc:
                cmpi.w #$F, d6                                  ;test 0xF
                bne.s TSTRTNE_CHARRAM_palinc_add
                
                TSTRTNE_CHARRAM_palinc_hold:                    ;hold
                bra.s TSTRTNE_CHARRAM_Draw

                TSTRTNE_CHARRAM_palinc_add:
                addq.w #$1, d6                                  ;palette code - 0x1
                bra.s TSTRTNE_CHARRAM_palinc_hold               ;goto hold

            TSTRTNE_CHARRAM_Draw:                               ;apply change on tilemaps
                move.w #$F000, d0                               ;initialize PR+tile code
                move.w #$0000, d1                               ;initialize palette code
                or.w d7, d0
                or.w d6, d1

                move.w #32, -(sp)
                move.w #28, -(sp)
                move.w d0, -(sp)                                ;hatched pattern
                move.w d1, -(sp)                                ;white
                move.w #0, -(sp)
                move.w #2, -(sp)
                move.w #0, -(sp)
                bsr.w DRAWTILEMAP

            TSTRTNE_CHARRAM_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_CHARRAM_ChkVal









        *--------------------------------------------------------
        *
        *       TESTMENU_Pr subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Pr:
            move.w #0, d6                                       ;initialize PR bit number reg
            move.w #$00FF, d7                                   ;initialize PR bit reg
                                                                ; MSB <- BBBB/BBBB -> LSB (TM-B, TM-A)

            jsr funcClearTilemap

            lea EXITMESSAGE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #4, -(sp)
            move.w #26, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea PRTILEMAPA, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #6, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            lea PRTILEMAPB, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #17, -(sp)
            move.w #6, -(sp)
            move.w #0, -(sp)
            bsr.w PRINTTEXT

            move.w #3, d6                                       ;repeat 4 times
            move.w #16, d5                                      ;ypos
            lea PRMESSAGE0, a4
            TSTRTNE_Pr_PrntMsg_loop:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #4, -(sp)                                ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d5
                add.l #26, a4

                dbf d6, TSTRTNE_Pr_PrntMsg_loop

            move.w #2, -(sp)
            move.w #2, -(sp)
            move.w #$F1D0, -(sp)                                ;vertical tile
            move.w #$0004, -(sp)                                ;red
            move.w #15, -(sp)
            move.w #10, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            move.w #2, -(sp)
            move.w #2, -(sp)
            move.w #$F1D4, -(sp)                                ;horizontal tile
            move.w #$0003, -(sp)                                ;green
            move.w #15, -(sp)
            move.w #10, -(sp)
            move.w #1, -(sp)
            bsr.w DRAWTILEMAP

            lea $56000, a0                                      ;sprite RAM

            ;SPRITE 1
            move.w #$00EF, (a0)+                                ;0: reletive priority
            move.w #$0020, (a0)+                                ;2: 8*8 = size 3'b100
            move.w #$0080, (a0)+                                ;4: no zoom
            move.w #$00EC, (a0)+                                ;6: 8*8 filled block
            move.w #$000A, (a0)+                                ;8: xpos MSB
            move.w #$0078, (a0)+                                ;A: 120px
            move.w #$0050, (a0)+                                ;C: 80px
            move.w #$0000, (a0)+                                ;E: not used
            
            ;SPRITE 2
            move.w #$00AF, (a0)+                                ;0: reletive priority
            move.w #$0020, (a0)+                                ;2: 8*8 = size 3'b100
            move.w #$0080, (a0)+                                ;4: no zoom
            move.w #$00EC, (a0)+                                ;6: 8*8 filled block
            move.w #$000A, (a0)+                                ;8: xpos MSB
            move.w #$0078, (a0)+                                ;A: 120px
            move.w #$0058, (a0)+                                ;C: 88px
            move.w #$0000, (a0)+                                ;E: not used

            TSTRTNE_Pr_ChkVal:                                  ;check key input
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                 ;get latest input 
                btst.l #$4, d0                                  ;check for power-up(gradius) or fire(twinbee)
                beq.s TSTRTNE_Pr_Apply
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_Pr_bitvalzero
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_Pr_bitvalone
                btst.l #$1, d0                                  ;check for RIGHT
                beq.s TSTRTNE_Pr_bitnumdec
                btst.l #$0, d0                                  ;check for LEFT
                beq.s TSTRTNE_Pr_bitnuminc

                bra.s TSTRTNE_Pr_PrntVal                        ;nothing changes

            TSTRTNE_Pr_bitvalzero:
                bclr.l d6, d7                                   ;clear bit
                bra.s TSTRTNE_Pr_PrntVal

            TSTRTNE_Pr_bitvalone:
                bset.l d6, d7                                   ;set bit
                bra.s TSTRTNE_Pr_PrntVal

            TSTRTNE_Pr_bitnumdec:
                cmpi.w #0, d6                                   ;test 0
                bne.s TSTRTNE_Pr_bitnumdec_sub
                
                TSTRTNE_Pr_bitnumdec_hold:                      ;hold
                bra.s TSTRTNE_Pr_PrntVal

                TSTRTNE_Pr_bitnumdec_sub:
                subq.w #1, d6                                   ;bitnum - 1
                bra.s TSTRTNE_Pr_bitnumdec_hold                 ;goto hold

            TSTRTNE_Pr_bitnuminc:
                cmpi.w #7, d6                                   ;test 0
                bne.s TSTRTNE_Pr_bitnuminc_add
                
                TSTRTNE_Pr_bitnuminc_hold:                      ;hold
                bra.s TSTRTNE_Pr_PrntVal

                TSTRTNE_Pr_bitnuminc_add:
                addq.w #1, d6                                   ;bitnum - 1
                bra.s TSTRTNE_Pr_bitnuminc_hold                 ;goto hold

            TSTRTNE_Pr_Apply:                                   ;apply change on tilemaps
                move.w d7, d0                                   ;copy PR bits data
                andi.w #$00F0, d0                               ;get TM-A data(0x00F0)
                lsl.w #8, d0                                    ;shift left 8 bits
                move.w #$1D0, d1                                ;load 0x1D0(TM-A test pattern)
                or.w d0, d1                                     ;merge d0 and d1

                move.w #2, -(sp)
                move.w #2, -(sp)
                move.w d1, -(sp)                                ;empty tile
                move.w #$0004, -(sp)                            ;red
                move.w #15, -(sp)
                move.w #10, -(sp)
                move.w #0, -(sp)
                bsr.w DRAWTILEMAP

                move.w d7, d0                                   ;copy PR bits data
                andi.w #$000F, d0                               ;get TM-B data(0x000F)
                lsl.w #8, d0                                    ;shift left 8 bits
                lsl.w #4, d0                                    ;shift left 4 bits
                move.w #$1D4, d1                                ;load 0x1D4(TM-B test pattern)
                or.w d0, d1                                     ;merge d0 and d1

                move.w #2, -(sp)
                move.w #2, -(sp)
                move.w d1, -(sp)                                ;empty tile
                move.w #$0003, -(sp)                            ;green
                move.w #15, -(sp)
                move.w #10, -(sp)
                move.w #1, -(sp)
                bsr.w DRAWTILEMAP

            TSTRTNE_Pr_PrntVal:
                move.w #7, d5                                   ;repeat 8 times
                move.w #11, d4                                  ;set xpos
                TSTRTNE_Pr_PrntVal_prntloop:
                    cmp.w d5, d6                                ;check that the value of the loop counter is equal to the currently selected bit
                    beq.s TSTRTNE_Pr_PrntVal_prntloop_redtxt    ;if same, use red

                    move.w #1, d0                               ;if not, use light blue
                    bra.s TSTRTNE_Pr_PrntVal_prntloop_chkbt

                    TSTRTNE_Pr_PrntVal_prntloop_redtxt:
                        move.w #4, d0

                    TSTRTNE_Pr_PrntVal_prntloop_chkbt:
                        btst.l d5, d7                               ;check bit value
                        bne.s TSTRTNE_Pr_PrntVal_prntloop_one
                        lea PRBITZERO, a0
                        bra.s TSTRTNE_Pr_PrntVal_prntloop_prnt

                        TSTRTNE_Pr_PrntVal_prntloop_one:
                            lea PRBITONE, a0

                        TSTRTNE_Pr_PrntVal_prntloop_prnt:
                            move.l a0, -(sp)
                            move.w d0, -(sp)
                            move.w d4, -(sp)
                            move.w #7, -(sp)
                            move.w #0, -(sp)
                            bsr.w PRINTTEXT

                        cmpi.w #4, d5                               ;if loop counter is 4
                        bne.s TSTRTNE_Pr_PrntVal_prntloop_incpos
                        addq.w #3, d4                               ;add 3 to xpos
                        dbf d5, TSTRTNE_Pr_PrntVal_prntloop         ;loop

                        TSTRTNE_Pr_PrntVal_prntloop_incpos:
                        addq.w #1, d4                               ;add 1 to xpos
                        dbf d5, TSTRTNE_Pr_PrntVal_prntloop         ;loop

            jsr funcScrExitMessage

            TSTRTNE_Pr_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_Pr_ChkVal


PRTILEMAPA      dc.w 'TM-A', $0000
PRTILEMAPB      dc.w 'TM-B', $0000
PRBITZERO       dc.w '0', $0000
PRBITONE        dc.w '1', $0000
PRMESSAGE0      dc.w ' Scarlet V-block   TM-A ', $0000
PRMESSAGE1      dc.w '  Green H-block    TM-B ', $0000
PRMESSAGE2      dc.w ' Saffron V-block   OBJ  ', $0000
PRMESSAGE3      dc.w 'Press A to apply changes', $0000








        *--------------------------------------------------------
        *
        *       TESTMENU_BMC subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_BMC:
            move.l #$3C000, -(sp)               ;copy tiles
            move.w #8, -(sp)
            move.w #1408, -(sp)
            jsr funcLoadBubble

            TSTRTNE_BMC_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_BMC_KeyInDelay







        *--------------------------------------------------------
        *
        *       TESTMENU_Contributors subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Contributors:
            jsr funcClearTilemap

            lea LINE0, a4
            move.w #4, d5
            move.w #10, d6
            TSTRTNE_Contributors_credits_1:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #0, -(sp)                            ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d5
                add.l #34, a4

                dbf d6, TSTRTNE_Contributors_credits_1

            lea LINE11, a4
            move.w #22, d5
            move.w #4, d6
            TSTRTNE_Contributors_credits_2:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #0, -(sp)                            ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w PRINTTEXT

                addq.w #1, d5
                add.l #34, a4

                dbf d6, TSTRTNE_Contributors_credits_2

            TSTRTNE_Contributors_KeyInDelay:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelay
                bra.w TSTRTNE_Contributors_KeyInDelay

LINE0           dc.w '      --------------------      ', $0000
LINE1           dc.w '       BubbleDrive8 is a        ', $0000
LINE2           dc.w '         bubble memory          ', $0000
LINE3           dc.w '       cartridge emulator       ', $0000
LINE4           dc.w '         developed for          ', $0000
LINE5           dc.w '                                ', $0000
LINE6           dc.w '     "Konami Bubble System"     ', $0000
LINE7           dc.w '                                ', $0000
LINE8           dc.w '  - Copyright 2019-2021 Raki -  ', $0000
LINE9           dc.w '          bubsys85.net          ', $0000
LINE10          dc.w '      --------------------      ', $0000

LINE11          dc.w '        Special thanks to       ', $0000
LINE12          dc.w '              ----              ', $0000
LINE13          dc.w '      v9938          MAKI       ', $0000
LINE14          dc.w '     Kudouta        akamig      ', $0000
LINE15          dc.w '         CSG@Akatronics         ', $0000

            




        *--------------------------------------------------------
        *
        *       TESTMENU_Return subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Return:
            jsr funcClearTilemap
            bra.w TITLEPROGRAM                          ;return to title screen

























        
        *--------------------------------------------------------
        *
        *       function: DrawTilemap
        *
        *--------------------------------------------------------

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


        *--------------------------------------------------------
        *
        *       function: FillTilemap
        *
        *--------------------------------------------------------

        ;ARGS: VRAM: PR(4), FLIP(1), CHARRAM ADDRESS(11)
        ;      COLORRAM: FLIP(1), PALETTE CODE(7)
        ;      TILEMAP A=0/B=1
        ;JSR:  RETURN ADDRESS 
        funcFillTilemap:                                        
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


        *--------------------------------------------------------
        *
        *       function: PrintText
        *
        *--------------------------------------------------------

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


        *--------------------------------------------------------
        *
        *       function: FixedDelay
        *
        *--------------------------------------------------------

        funcFixedDelay:
            move.b #1, $5E008                           ;kick the watchdog
            move.b #0, $5E008
            move.w #$8000, d0
            funcFixedDelay_delayloop:
                nop
                dbf d0, funcFixedDelay_delayloop        ;loop
            rts

        *--------------------------------------------------------
        *
        *       function: CheckInput
        *
        *--------------------------------------------------------

        funcCheckInput:
            move.l (sp)+, a0                            ;pop return address
            move.w $812, d0                             ;restore key in data
            move.w $810, d1

            move.w d1, d0                               ;move current value to old value register
            move.w $5CC02, d1                           ;get P1 button register
            not.w d0                                    ;invert previous key input data
            or.w d1, d0                                 ;negedge = ~previous || current

            move.w d1, $810                             ;store key in data
            move.w d0, $812
            move.w d0, -(sp)
            move.l a0, -(sp)                            ;push return address

            rts

        *--------------------------------------------------------
        *
        *       function: ClearTilemap
        *
        *--------------------------------------------------------

        funcClearTilemap:
            move.w #$3000, -(sp)                        ;clear tilemap A
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            bsr.w funcFillTilemap

            move.w #$E05F, -(sp)                        ;clear tilemap B
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w funcFillTilemap 

            rts


        *--------------------------------------------------------
        *
        *       function: ScrExitMessage
        *
        *--------------------------------------------------------

        funcScrExitMessage:
            move.w #0, d0                           ;initialize registers
            move.w #0, d1
            lea $501A1, a0                          ;scroll value LSBs
            lea $503A1, a1                          ;scroll value MSB

            move.b (a1), d1                         ;get MSB
            lsl.w #8, d1                            ;place MSB bit in correct place
            move.b (a0), d0                         ;get LSBs
            or.w d1, d0                             ;merge

            cmpi.w #$1FF, d0                        ;full shift
            beq.s funcScrExitMessage_MsgShift_rst

            cmpi.w #$FF, d0                         ;toggle MSB
            beq.s funcScrExitMessage_MsgShift_msb

            move.w #7, d1
            funcScrExitMessage_MsgShift_inc_loop:
                move.b (a0), d0
                addq.b #1, d0
                move.b d0, (a0)
                add.l #2, a0
                dbf d1, funcScrExitMessage_MsgShift_inc_loop
                rts

            funcScrExitMessage_MsgShift_rst:
                move.w #7, d1
                funcScrExitMessage_MsgShift_rst_loop:
                    move.b #0, (a1)
                    move.b #0, (a0)
                    add.l #2, a1
                    add.l #2, a0
                    dbf d1, funcScrExitMessage_MsgShift_rst_loop
                    rts

            funcScrExitMessage_MsgShift_msb:
                move.w #7, d1
                funcScrExitMessage_MsgShift_msb_loop:
                    move.b #1, (a1)
                    move.b #0, (a0)
                    add.l #2, a1
                    add.l #2, a0
                    dbf d1, funcScrExitMessage_MsgShift_msb_loop
                    rts

EXITMESSAGE   dc.w 'Press A+LEFT(1P) to exit back to menu screen', $0000



    SIMHALT             ; halt simulator

*RF2 steering: 0x22E00
*RF2 acc: 0x23200(+400)
*RF2 brake: 0x23600(+400)
*TM-A test pattern: 0x23A00
*TM-B test pattern: 0x23A80

* Put variables and constants here

    END    BOOTLOADER        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
{"mode":"full","isActive":false}