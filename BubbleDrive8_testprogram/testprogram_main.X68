*-----------------------------------------------------------
* Title      : BubbleDrive8_testprogram
* Written by : Raki
* Date       : 2021-10-26
* Description: BubbleDrive8 Test Program
*              B85:K:A:C:2021102602
*-----------------------------------------------------------

;MEMORY STRUCTURE
;0x00000: bootloader
;~0x00600: program stack
;~0x00700: register backup stack
;0x00700: sprite properties(max 16)
;0x00800: RAM test result(long), menu indicator(word)
;0x00810: single input detector reg
;0x00818: long input detector reg
;0x00820: data loaded flags
;0x00830: 
;0x00880: user RAM
;0x00900: initializer program
;0x00D00; MBM error map
;0x00F00: BMC page data


    ORG     $0
VECTORS dc.l $00000600                                      ;reset initial SP
        dc.l $00000008                                      ;reset initial PC

    ORG     $8
    BOOTLOADER:
        move.w #4111, d0                                    ;repeat 4112 times
        BOOTLOADER_WaitForController:
            nop
            dbf d0, BOOTLOADER_WaitForController            ;Konami engineer added 4112 nop loops at that time

        lea $5E008, a6 
        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)                                     ;what circuitry acts as watchdog? idk

        lea $14C, a0                                        ;bubble memory error map start address in the BOOTLOADER area
        lea $D00, a1                                        ;target address, does the BMC uses this data using DMA? not verified
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
        bne.w BOOTLOADER_Restart


        move.w #$1, $0(a0)                                  ;load page 0x001
        move.w #$1, $2(a0)                                  ;READ
        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$1, $0(a0)                                  ;load page 0x001
        move.w #$1, $2(a0)                                  ;READ
        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #$801, $0(a0)                                ;load page 0x001
        move.w #$2, $2(a0)                                  ;WRITE
        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)
        bsr.w BOOTLOADER_funcBubbleWait

        move.w #0, $4(a0)                                   ;initialize controller
        move.w #$1, d1                                      ;set page 0x001 in D1
        move.w #7, d0                                       ;consecutive 8 pages
        lea $900, a1                                        ;copy pages from 900
        BOOTLOADER_LoadRAMTest:
            move.w #0, $4(a0)                               ;initialize controller
            move.w d1, $0(a0)                               ;set page
            nop
            move.w #$1, $2(a0)                              ;READ
            addq.w #1, d1                                   ;d1 + 1
            move.b #1, (a6)                                 ;kick the Z80 watchdog
            move.b #0, (a6)

            bsr.w BOOTLOADER_funcBubbleWait                 ;wait until completion

            move.w $0(a0), d2                               ;copy last 6 bits
            move.w d2, $F80                                 ;place last 5 bits on F80
            lea $F00, a3                                    ;set source address
            move.w #65, d3                                  ;repeat 66 times
            BOOTLOADER_LoadRAMTest_ShiftPage:
                move.l (a3), d2                             ;start shifting: same as the original Konami code
                lsl.l #6, d2
                swap d2
                move.w d2, (a3)+
                dbf d3, BOOTLOADER_LoadRAMTest_ShiftPage

            lea $F00, a3
            move.w #31, d7
            BOOTLOADER_LoadRAMTest_CopyPage:
                move.l (a3)+, (a1)+
                dbf d7, BOOTLOADER_LoadRAMTest_CopyPage

            dbf d0, BOOTLOADER_LoadRAMTest                  ;repeat 6 times

        move.w #0, $4(a0)                                   ;initialize controller
        jmp $900

        BOOTLOADER_funcBubbleWait:
            move.w #$8000, d7                               ;signed -32768
            BOOTLOADER_funcBubbleWait_loop:
                nop
                dbf d4, BOOTLOADER_funcBubbleWait_loop
            rts

        BOOTLOADER_Jump2ExpROM:
            jmp $78002

        BOOTLOADER_Restart:
            bra.w BOOTLOADER


    ORG     $900
    INITIALIZATION:                                         ;initial RAM test routines        
        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)

        move.b #1, $5C001                                   ;morning music code latch

        move.w #$8000, d0
        INITIALIZATION_DelayLoop:
            nop
            dbf d0, INITIALIZATION_DelayLoop                ;initial delay

        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)

        move.l #$0, d7                                      ;initialize d7
        
        ;bit 0: shared RAM
        ;bit 1: WORK RAM
        ;bit 2: Z80 RAM
        ;bit 3: Palette RAM
        ;bit 4: Expansion RAM
        ;bit 5: Scroll RAM
        ;bit 6: TM Code RAM
        ;bit 7: TM Color RAM
        ;bit 8: OBJ List RAM
        ;bit 9: Character RAMd

        move.w #1, -(sp)                                    ;Palette RAM test
        move.l #$5A000, -(sp)
        move.l #$1000, -(sp)
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #3, d2
        or.w d2, d7                                         ;save test result in d7[3]

        move.w #1, -(sp)                                    ;Work RAM test
        move.l #$10000, -(sp)
        move.l #$10000, -(sp)
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #1, d2
        or.w d2, d7                                         ;save test result in d7[1]

        move.w #0, -(sp)                                    ;scroll RAM test
        move.l #$50000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #5, d2           
        or.w d2, d7                                         ;save test result in d7[5]

        move.w #1, -(sp)                                    ;tilemap RAM test
        move.l #$52000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #6, d2         
        or.w d2, d7                                         ;save test result in d7[6]

        move.w #0, -(sp)                                    ;tile color RAM test
        move.l #$54000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #7, d2           
        or.w d2, d7                                         ;save test result in d7[7]

        move.w #0, -(sp)                                    ;sprite RAM test
        move.l #$56000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #8, d2           
        or.w d2, d7                                         ;save test result in d7[8]

        move.w #1, -(sp)                                    ;Character RAM test
        move.l #$30000, -(sp)                
        move.l #$10000, -(sp)                   
        bsr.w volatileRamTestInit                  
        move.w (sp)+, d2
        lsl.w #8, d2
        lsl.w #1, d2                
        or.w d2, d7                                         ;save test result in d7[9]

        move.w #1, -(sp)                                    ;expansion RAM
        move.l #$70000, -(sp)                
        move.l #$4000, -(sp)                   
        jsr volatileRamTestInit
        move.w (sp)+, d2
        lsl.w #4, d2           
        or.w d2, d7                                         ;save test result in d7[4]

        move.l d7, $800                                     ;save RAM test result to 0x800

        move.b #0, $5E004                                   ;Z80 interrupt
        nop
        nop
        move.b #1, $5E004

        lea $56000, a0                                      ;sprite RAM
        move.w #$FF, d0                                     ;sprite priority
        move.w #$FF, d2                                     ;sprite RAM loop (56000-56FFF)
        INITIALIZATION_ObjRAMInit_vloop:
            move.w d0, (a0)+                                ;write priority
            move.w #$00E0, (a0)+                            ;minimize sprite drawing time(E0)
            
            move.w #4, d1                                   ;inner loop
            INITIALIZATION_ObjRAMInit_hloop:
                move.w #$FF, (a0)+
                dbf d1, INITIALIZATION_ObjRAMInit_hloop     ;repeat 6 times

            move.w #$00, (a0)+

            subq.w #1, d0                                   ;decrease priority

            dbf d2, INITIALIZATION_ObjRAMInit_vloop

        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)

        lea $30BE0, a0
        move.l #15, d0
        INITIALIZATION_drawblock:
            move.w #$1111, (a0)+
            dbf d0, INITIALIZATION_drawblock
        move.w #$7F76, $5A022                               ;light blue

        move.l #$10000, -(sp)
        move.w #128, -(sp)                                  ;96 pages
        move.w #9, -(sp)                                    ;from 0x480
        move.w #1, -(sp)                                    ;display progress bar
        bsr.w funcLoadBubble

        move.b #1, (a6)                                     ;kick the Z80 watchdog
        move.b #0, (a6)

        jmp $10000                                          ;goto work ram



        *--------------------------------------------------------
        *
        *       system: SaveReg
        *
        *--------------------------------------------------------
        sysSaveReg:
            move.b #1, $5E008                                   ;kick the watchdog
            move.b #0, $5E008

            move.l a7, $6FC                                     ;save current SP address
            lea $6FC, a7                                        ;change stack pointer

            move.l a6, -(sp)
            move.l a5, -(sp)
            move.l a4, -(sp)
            move.l a3, -(sp)
            move.l a2, -(sp)
            move.l a1, -(sp)
            move.l a0, -(sp)

            move.l d7, -(sp)
            move.l d6, -(sp)
            move.l d5, -(sp)
            move.l d4, -(sp)
            move.l d3, -(sp)
            move.l d2, -(sp)
            move.l d1, -(sp)
            move.l d0, -(sp)

            move.l #0, d0
            move.l #0, d1
            move.l #0, d2
            move.l #0, d3
            move.l #0, d4
            move.l #0, d5
            move.l #0, d6
            move.l #0, d7

            movea.l d0, a0
            movea.l d0, a1
            movea.l d0, a2
            movea.l d0, a3
            movea.l d0, a4
            movea.l d0, a5
            movea.l d0, a6

            move.l $6FC, a7                                     ;restore SP

            rts

        *--------------------------------------------------------
        *
        *       system: LoadReg
        *
        *--------------------------------------------------------
        sysLoadReg:
            move.b #1, $5E008                                   ;kick the watchdog
            move.b #0, $5E008

            move.l a7, $6FC                                     ;save current SP address
            lea $6C0, a7                                        ;change stack pointer

            move.l #0, d0
            move.l #0, d1
            move.l #0, d2
            move.l #0, d3
            move.l #0, d4
            move.l #0, d5
            move.l #0, d6
            move.l #0, d7

            movea.l d0, a0
            movea.l d0, a1
            movea.l d0, a2
            movea.l d0, a3
            movea.l d0, a4
            movea.l d0, a5
            movea.l d0, a6

            move.l (sp)+, d0
            move.l (sp)+, d1
            move.l (sp)+, d2
            move.l (sp)+, d3
            move.l (sp)+, d4
            move.l (sp)+, d5
            move.l (sp)+, d6
            move.l (sp)+, d7

            move.l (sp)+, a0
            move.l (sp)+, a1
            move.l (sp)+, a2
            move.l (sp)+, a3
            move.l (sp)+, a4
            move.l (sp)+, a5
            move.l (sp)+, a6
            
            move.l $6FC, a7                                     ;restore SP

            rts



        *--------------------------------------------------------
        *
        *       volatile: RamTestInit
        *
        *--------------------------------------------------------

        volatileRamTestInit:                                ;bit width flag -> start address -> test length -> return address
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

                    move.b #1, (a6)                         ;kick the Z80 watchdog
                    move.b #0, (a6)

                    move.w d2, -(sp)                        ;set ok/failed flag
                    move.l a2, -(sp)                        ;push return address
                    rts  

                    FILLWORD:
                        move.b #1, (a6)                     ;kick the Z80 watchdog
                        move.b #0, (a6)

                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        WORDRWTEST:
                            move.w d3, (a0)                 ;write $FFFF, 5555, AAAA, 0000
                            nop
                            nop
                            nop
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

                    move.b #1, (a6)                         ;kick the Z80 watchdog
                    move.b #0, (a6)

                    move.w d2, -(sp)                        ;set ok/failed flag
                    move.l a2, -(sp)                        ;push return address
                    rts

                    FILLBYTE:
                        move.b #1, (a6)                         ;kick the Z80 watchdog
                        move.b #0, (a6)

                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        BYTERWTEST:                    
                            move.b d3, (a0)                 ;write $FF, 55, AA, 00
                            nop
                            cmp.b (a0), d3                  ;read and compare
                            bne.s BYTEERROR                 ;if not matches, goto ERROR
                            addq.l #2, a0                   ;+2 increment
                            dbf d0, BYTERWTEST              ;loop
                        
                        rts

                        BYTEERROR:
                            addq.l #2, a0                   ;+2 increment
                            bsr.s ERROR
                            dbf d0, BYTERWTEST

                ERROR:         
                    move.w #1, d2                           ;set error flag
                    rts        


        *--------------------------------------------------------
        *
        *       function: funcLoadBubble
        *
        *--------------------------------------------------------

        ;ARGS: DESTINATION MEMORY ADDRESS 
        ;      CONSECUTIVE PAGE LENGTH
        ;      START PAGE ADDRESS
        ;      LOADING BAR SWITCH
        ;JSR:  RETURN ADDRESS 
        funcLoadBubble:                                         ;start page -> consecutive page length - > destination address -> return address
            jsr sysSaveReg
            
            lea $5E008, a6
            lea $40000, a1     

            movea.l (sp)+, a5                                   ;pop return address
            move.w (sp)+, d7                                    ;pop loading bar switch
            tst.w d7
            beq.w funcLoadBubble_Init
            lea $850, a4

            move.w (sp)+, d5                                    ;pop start page
            move.w (sp)+, d6                                    ;pop consecutive page length
            ;funcLoadBubble_GenTbl
                cmpi.w #15, d6
                bgt.s funcLoadBubble_GenTbl_over15
                ;funcLoadBubble_GenTbl_15:
                    move.w #0, d0                               ;clear accumulator
                    move.w #15, d1                              ;set loop counter
                    funcLoadBubble_GenTbl_15_gen:
                        move.w d0, -(a4)                        ;write acc value
                        addq.w #1, d0
                        dbf d1, funcLoadBubble_GenTbl_15_gen
                    bra.w funcLoadBubble_GenTbl_loadinit

                funcLoadBubble_GenTbl_over15:
                    move.w d6, d0
                    btst.l #3, d0                               ;test bit[3]
                    bne.s funcLoadBubble_GenTbl_over15_ru
                    ;funcLoadBubble_GenTbl_over15_rd:           ;rounding down
                        andi.w #$FFF0, d0
                        bra.s funcLoadBubble_GenTbl_over15_div

                    funcLoadBubble_GenTbl_over15_ru:            ;rounding up
                        andi.w #$FFF0, d0
                        addi.w #$0010, d0

                    funcLoadBubble_GenTbl_over15_div:
                        lsr.w #4, d0                            ;/16

                    move.w #0, d1                               ;clear d1

                    move.w #15, d2
                    funcLoadBubble_GenTbl_over15_gen:
                        cmp.w d6, d1                            ;compare d1 with original pange length
                        ble.s funcLoadBubble_GenTbl_over15_wr   ;less or equal, write ahead
                        move.w d6, d1                           ;overflow

                        funcLoadBubble_GenTbl_over15_wr:
                            move.w d1, -(a4)

                        add.w d0, d1                            ;accumulate quotient

                        dbf d2, funcLoadBubble_GenTbl_over15_gen

                funcLoadBubble_GenTbl_loadinit:
                    move.w d5, d0                               ;move start page
                    move.w d6, d1                               ;move page length
                    subi.w #1, d1                               ;consecutive page length - 1
                    movea.l (sp)+, a2                           ;pop destination address

                    ;lea $830, a4                               ;progress bar table
                    lea $52890, a3                              ;progress bar address

                    bra.s funcLoadBubble_Read


            funcLoadBubble_Init:
                move.w (sp)+, d0                                ;pop start page
                move.w (sp)+, d1                                ;pop consecutive page length
                subi.w #1, d1                                   ;consecutive page length - 1 
                movea.l (sp)+, a2                               ;pop destination address

            
            funcLoadBubble_Read:
                move.w #0, $4(a1)                           ;initialize controller
                move.w d0, (a1)                             ;set page
                nop
                move.w #1, $2(a1)                           ;read page

                move.b #1, (a6)                             ;kick the Z80 watchdog
                move.b #0, (a6)

                move.w #$8000, d3
                funcLoadBubble_Read_wait:
                    nop
                    dbf d3, funcLoadBubble_Read_wait        ;loop

                move.w (a1), d2                             ;move last byte to d2
                move.w d2, $F80                             ;move last byte to F80

                lea $F00, a0                                ;first address of the page
                move.w #65, d3
                funcLoadBubble_Read_shift:
                    move.l (a0), d2                         ;get raw data
                    lsl.l #6, d2                            ;shift 6 bits left
                    swap d2                                 ;high 16 low 16 swap
                    move.w d2, (a0)+                        ;write shifted data
                    dbf d3, funcLoadBubble_Read_shift       ;loop 66 times

                lea $F00, a0                                ;first address of the page
                move.w #31, d3
                funcLoadBubble_Read_copy:
                    move.l (a0)+, (a2)+
                    dbf d3, funcLoadBubble_Read_copy        ;loop 32 times

                addq.w #1, d0                               ;start page +1

                tst.w d7
                bne.s funcLoadBubble_Read_updtldbar
                dbf d1, funcLoadBubble_Read
                bra.w funcLoadBubble_Exit

                funcLoadBubble_Read_updtldbar:
                    move.w (a4), d6                         ;get table value
                    cmp.w d6, d1                            ;compare loop counter with table
                    ble.w funcLoadBubble_Read_updtldbar_inc
                    dbf d1, funcLoadBubble_Read
                    
                    funcLoadBubble_Read_updtldbar_inc:
                        move.w #$0001, $2000(a3) 
                        move.w #$F05F, (a3)+
                        adda.l #$2, a4
                    
                    dbf d1, funcLoadBubble_Read

                    move.l #15, d0
                    funcLoadBubble_Read_updtldbar_del:
                        move.w #$E000, -(a3)
                        dbf d0, funcLoadBubble_Read_updtldbar_del

            funcLoadBubble_Exit:
                move.l a5, -(sp)                                ;push return address

                jsr sysLoadReg
                rts 


    ORG    $10000
    MAINTEST:
        move.w #71, d0
        lea IVT, a0
        lea $00000000, a1
        MAINTEST_ivtcopy:
            move.l (a0)+, (a1)+
            dbf d0, MAINTEST_ivtcopy

        move.l #$5A000, -(sp) ;copy palette
        move.w #4, -(sp)
        move.w #1020, -(sp)
        move.w #0, -(sp)
        jsr funcLoadBubble

        move.l #$30400, -(sp) ;copy tiles
        move.w #8, -(sp)
        move.w #1032, -(sp)
        move.w #1, -(sp)
        jsr funcLoadBubble

        move.w #$E000, -(sp)                            ;clear tilemap A with black(transparent) tiles
        move.w #$0002, -(sp)
        move.w #0, -(sp)
        bsr.w funcFillTilemap

        lea NOWLOADING, a0                              ;print nowloading
        move.l a0, -(sp)
        move.w #2, -(sp)
        move.w #9, -(sp)
        move.w #15, -(sp)
        move.w #0, -(sp)
        bsr.w funcPrintText

        move.l #$30000, -(sp) ;copy tiles
        move.w #128, -(sp)
        move.w #1024, -(sp)
        move.w #1, -(sp)
        jsr funcLoadBubble

        move.w #1, $804                                 ;initialize menu item indicator register
        move.w #$FFFF, $810                             ;initialize current key input comparison register to FFFF
        move.w #$FFFF, $812                             ;initialize previous key input comparison register to FFFF
        move.w #$FFFF, $818                             ;initialize long input previous value
        move.w #0, $81A                                 ;initialize long input trigger counter
        move.w #0, $81C                                 ;initialize long input pulse counter


        *--------------------------------------------------------
        *
        *       TITLE SCREEN
        *
        *--------------------------------------------------------

        move.b #$00, $20001                                 ;write 00 to Z80 $4000
        move.b #$00, $20003                                 ;write 00 to Z80 $4001

        TITLEPROGRAM:
            jsr funcClearTilemap

            move.w #12, -(sp)
            move.w #12, -(sp)
            move.w #$F060, -(sp)
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            move.w #18, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap

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
                bsr.w funcDrawTilemap
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
                bsr.w funcDrawTilemap
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
                bsr.w funcDrawTilemap

            lea TITLEMESSAGE2, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #7, -(sp)
            move.w #16, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea TITLEMESSAGE1, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #16, -(sp)
            move.w #23, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea TITLEMESSAGE3, a0
            move.l a0, -(sp)
            move.w #1, -(sp)
            move.w #13, -(sp)
            move.w #24, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea VERSION, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #0, -(sp)
            move.w #2, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

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
TITLEMESSAGE3   dc.w '(C) 2020-2021 Raki', $0000
VERSION         dc.w 'B85:K:A:D:2021110802', $0000


        *--------------------------------------------------------
        *
        *       TESTMENU list page
        *
        *--------------------------------------------------------

        TESTMENU:
            move.b #$FF, $27FF9                                 ;initialize Z80 status(halt escape??) register

            jsr funcClearTilemap

            lea $50000, a0
            move.w #$7FF, d0
            TESTMENU_scrollreset:
                move.w #0, (a0)+                                ;set scroll value
                dbf d0, TESTMENU_scrollreset
            
            lea $56000, a0                                      ;sprite RAM
            move.w #$FF, d0                                     ;sprite priority
            move.w #$FF, d2                                     ;sprite RAM loop (56000-56FFF)
            TESTMENU_ObjRAMInit_vloop:
                move.w d0, (a0)+                                ;write priority
                move.w #$00E0, (a0)+                            ;minimize sprite drawing time(E0)
                
                move.w #4, d1                                   ;inner loop
                TESTMENU_ObjRAMInit_hloop:
                    move.w #$FF, (a0)+
                    dbf d1, TESTMENU_ObjRAMInit_hloop           ;repeat 6 times

                move.w #$00, (a0)+

                subq.w #1, d0                                   ;decrease priority

                dbf d2, TESTMENU_ObjRAMInit_vloop

            move.w #14, d6                                      ;print test menu items: 15 lines
            move.w #8, d7                                       ;YPOS of first line
            lea TESTMENUITEM1, a4
            TESTMENU_PrintList:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #4, -(sp)
                move.w d7, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d7
                add.l #28, a4                               ;get a new string from addr+28

                dbf  d6, TESTMENU_PrintList

            move.w $804, d6                                 ;menu item indicator register
            move.w d6, d5                                   ;
            addi.w #7, d5                                   ;cursor position

            move.w #1, -(sp)                                ;draw cursor on 1st position
            move.w #1, -(sp)
            move.w #$F01E, -(sp)
            move.w #$0000, -(sp)
            move.w #3, -(sp)
            move.w d5, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap

            TESTMENUKEYINWAIT:
                bsr.w funcCheckInput                        ;check P1 button input
                move.w (sp)+, d0                            ;get latest input
                bsr.w funcCheckLongInput
                move.w (sp)+, d1                            ;get long input trigger
                ori.w #$FFF0, d1                            ;mask button A B C inputs
                and.w d1, d0
                
                btst.l #$4, d0                              ;check for power-up(gradius) or fire(twinbee)
                beq TESTMENUSWITCHER
                btst.l #$3, d0                              ;check for DOWN
                beq TESTMENUINCREASE
                btst.l #$2, d0                              ;check for UP
                beq TESTMENUDECREASE
                bra.s TESTMENUKEYINDELAY
                

                TESTMENUINCREASE:
                    addq.w #1, d6                           ;add 1 anyway
                    cmpi.w #16, d6                          ;if not 16
                    beq.s TESTMENUINCREASE_LOOP
                    cmpi.w #14, d6
                    bne.s TESTMENUMOVECURSOR
                    addq.w #1, d6
                    bra.s TESTMENUMOVECURSOR
                    TESTMENUINCREASE_LOOP:
                        move.w #1, d6
                        bra.s TESTMENUMOVECURSOR

                TESTMENUDECREASE:
                    subq.w #1, d6                           ;subtract 1 anyway
                    cmpi.w #0, d6                           ;if 0
                    beq.s TESTMENUDECREASE_LOOP
                    cmpi.w #14, d6                          ;if not 14
                    bne.s TESTMENUMOVECURSOR
                    subq.w #1, d6
                    bra.s TESTMENUMOVECURSOR
                    TESTMENUDECREASE_LOOP:
                        move.w #12, d6
                        ;bra.s TESTMENUMOVECURSOR

                TESTMENUMOVECURSOR:
                    move.w #1, -(sp)                        ;clear previous cursor
                    move.w #1, -(sp)
                    move.w #$F000, -(sp)
                    move.w #$0000, -(sp)
                    move.w #3, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcDrawTilemap

                    move.w d6, $804                         ;save item indicator value
                    move.w d6, d5                           ;update cursor position
                    addq.w #7, d5

                    move.w #1, -(sp)                        ;redraw cursor on new position
                    move.w #1, -(sp)
                    move.w #$F01E, -(sp)
                    move.w #$0000, -(sp)
                    move.w #3, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcDrawTilemap

                TESTMENUKEYINDELAY:
                    jsr funcFixedDelayFast
                    bra.w TESTMENUKEYINWAIT  

TESTMENUITEM1   dc.w '1.RAM test result        ', $0000
TESTMENUITEM2   dc.w '2.Screen test            ', $0000
TESTMENUITEM3   dc.w '3.Scroll test            ', $0000
TESTMENUITEM4   dc.w '4.Sprite test            ', $0000
TESTMENUITEM5   dc.w '5.User input test        ', $0000
TESTMENUITEM6   dc.w '6.RF2 IO board test      ', $0000
TESTMENUITEM7   dc.w '7.Show CHARRAM data      ', $0000
TESTMENUITEM8   dc.w '8.Priority test          ', $0000
TESTMENUITEM9   dc.w '9.System IO test         ', $0000
TESTMENUITEM10  dc.w '10.BMC debug program     ', $0000
TESTMENUITEM11  dc.w '11.Contributors          ', $0000
TESTMENUITEM12  dc.w '12.Return to title screen', $0000
TESTMENUITEM13  dc.w '13.Jump to 0x78002       ', $0000
TESTMENUITEM14  dc.w '                         ', $0000
TESTMENUITEM15  dc.w ' About this BubbleDrive8 ', $0000




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
                    beq TSTRTNE_Scroll
                    cmpi #4, d6
                    beq TSTRTNE_OBJ
                    cmpi #5, d6
                    beq TSTRTNE_Input
                    cmpi #6, d6
                    beq TSTRTNE_RF2IO
                    cmpi #7, d6
                    beq TSTRTNE_CHARRAM
                    cmpi #8, d6
                    beq TSTRTNE_Pr
                    cmpi #9, d6
                    beq TSTRTNE_SysIO
                    cmpi #10, d6
                    beq TSTRTNE_BMC
                    cmpi #11, d6
                    beq TSTRTNE_Contributors
                    cmpi #12, d6
                    beq TSTRTNE_Return
                    cmpi #13, d6
                    beq TSTRTNE_JMP
                    cmpi #15, d6
                    beq TSTRTNE_About
                    bra.w TESTMENUKEYINWAIT








        *--------------------------------------------------------
        *
        *       TESTMENU_RAM test subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_RAM:
            move.b #$01, $20003                         ;excute Z80 checksum calculation routine

            jsr TSTRTNE_RAM_additionaltest

            move.b #$04, $27FF9                         ;always wrong checksum, nop loop escape command
            move.b #$00, $20003                         ;disable cheksum execute flag

            move.b #0, $5E004                           ;Z80 interrupt
            nop
            nop
            move.b #1, $5E004

            ;I just wanted to execute RAM test routine maintaining original data while Z80 calculates checksum of 0x4000-0x7DFF.
            ;The code worked well on MAME, but the real machine spits Z80 RAM error. Its behavior is quite different from MAME's.
            ;I thought there was no way, so I decided to simply initialize all the data and request a Z80 interrupt.

            lea RAMTESTMESSAGE1, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #4, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea RAMTESTMESSAGE2, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #42, -(sp)
            move.w #4, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

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
                    bsr.w funcPrintText

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
                    move.w #0, -(sp)
                    move.w d4, -(sp)
                    move.w d5, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

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

                    btst.l d3, d0
                    bne.s TSTRTNE_RAM_PrintTestResult_setfailed             ;set failed/passed branch

                    lea RAMTESTPASSED, a0                                   ;set passed flag
                    move.w #3, d0
                    bra.s TSTRTNE_RAM_PrintTestResult_print

                    TSTRTNE_RAM_PrintTestResult_setfailed:                  ;set failed flag
                    lea RAMTESTFAILED, a0
                    move.w #4, d0
                    ;bra.s TSTRTNE_RAM_PrintTestResult_print

                    TSTRTNE_RAM_PrintTestResult_print:
                        move.l a0, -(sp)
                        move.w d0, -(sp)                                    ;palette
                        move.w d4, -(sp)                                    ;xpos
                        move.w d5, -(sp)                                    ;ypos
                        move.w #0, -(sp)
                        bsr.w funcPrintText

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
                jsr funcFixedDelaySlow
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
                    move.b #1, $5E008                   ;kick the watchdog
                    move.b #0, $5E008
                    move.w #$800, d7
                    TSTRTNE_RAM_SwitchScrn_scrolldelay:
                        nop
                        dbf d7, TSTRTNE_RAM_SwitchScrn_scrolldelay      ;loop
                    dbf d2, TSTRTNE_RAM_SwitchScrn_hloop
            
            TSTRTNE_RAM_KeyInDelay_b:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.s TSTRTNE_RAM_KeyInDelay_b

            TSTRTNE_RAM_additionaltest:
                jsr funcClearTilemap

                lea RAMTESTWAIT, a0                                 ;print nowloading
                move.l a0, -(sp)
                move.w #5, -(sp)
                move.w #10, -(sp)
                move.w #15, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                move.l $800, d7                                     ;load RAM test result from 0x800

                ;bit 0: shared RAM
                ;bit 2: Z80 RAM

                bclr.l #0, d7
                bclr.l #2, d7

                move.w #1, -(sp)                                    ;Shared RAM
                move.l #$00000, -(sp)                
                move.l #$1000, -(sp)                   
                jsr funcRamTestHoldVal
                move.w (sp)+, d2   
                or.w d2, d7                                         ;save test result in d7[0]

                 move.w #0, -(sp)                                    ;Z80 RAM test
                move.l #$20004, -(sp)                
                move.l #$1FFC, -(sp)                   
                jsr volatileRamTestInit
                move.w (sp)+, d2
                lsl.w #2, d2
                or.w d2, d7                                         ;save test result in d7[2]

                move.w #0, -(sp)                                    ;Z80 RAM test
                move.l #$22000, -(sp)                
                move.l #$2000, -(sp)                   
                jsr volatileRamTestInit
                move.w (sp)+, d2
                lsl.w #2, d2
                or.w d2, d7                                         ;save test result in d7[2]

                move.w #0, -(sp)                                    ;Z80 RAM test
                move.l #$24000, -(sp)                
                move.l #$2000, -(sp)                   
                jsr volatileRamTestInit
                move.w (sp)+, d2
                lsl.w #2, d2
                or.w d2, d7                                         ;save test result in d7[2]

                move.w #0, -(sp)                                    ;Z80 RAM test
                move.l #$26000, -(sp)                
                move.l #$2000, -(sp)                   
                jsr volatileRamTestInit
                move.w (sp)+, d2
                lsl.w #2, d2
                or.w d2, d7                                         ;save test result in d7[2]

                

                move.l d7, $800                                     ;load RAM test result from 0x800

                jsr funcClearTilemap

                rts


            ;
            ;           FUNCTION RAMTEST WITH VALUE HOLDING
            ;
            funcRamTestHoldVal:                         ;bit width flag -> start address -> test length -> return address
                movea.l (sp)+, a2                       ;pop return address
                move.l (sp)+, d1                        ;pop test length
                movea.l (sp)+, a1                       ;pop start address

                lea $5E008, a6                          ;load watchdog address
            
                lsr.l #1, d1                            ;divide by 2
                subi.l #1, d1                           ;test length - 1

                move.w (sp)+, d2                        ;pop bit width flag(0 = 8bit, 1 = 16bit)
                btst.l #$0, d2                          ;1 = WORDTEST 0 = BYTETEST
                beq.s HoldVal_ByteTest                  ;if 0(Z=1), go to BYTETEST if 1(Z=0) go to WORDTEST

                move.w #0, d2                           ;initialize d2

                    HoldVal_WordTest:
                        move.w #$FFFF, d3
                        bsr.w HoldVal_WordTest_FillWord
                        move.w #$5555, d3
                        bsr.w HoldVal_WordTest_FillWord
                        move.w #$AAAA, d3
                        bsr.w HoldVal_WordTest_FillWord
                        move.w #$0000, d3
                        bsr.w HoldVal_WordTest_FillWord

                        move.b #1, (a6)                         ;kick the Z80 watchdog
                        move.b #0, (a6)

                        move.w d2, -(sp)                        ;set ok/failed flag
                        move.l a2, -(sp)                        ;push return address

                        rts  

                        HoldVal_WordTest_FillWord:
                            move.b #1, (a6)                     ;kick the Z80 watchdog
                            move.b #0, (a6)

                            move.l d1, d0                       ;move loop counter to d0
                            movea.l a1, a0                      ;move start address to a0
                            HoldVal_WordTest_FillWord_rw:
                                move.w (a0), d4                 ;backup the value
                                move.w d3, (a0)                 ;write $FFFF, 5555, AAAA, 0000
                                cmp.w (a0), d3                  ;read and compare
                                bne.s HoldVal_ByteTest_FillWord_err     ;if not matches, goto ERROR
                                move.w d4, (a0)+                ;rewrite
                                dbf d0, HoldVal_WordTest_FillWord_rw    ;loop
                            
                            rts

                            HoldVal_ByteTest_FillWord_err:
                                move.w d4, (a0)+                ;rewrite
                                bsr.s HoldVal_Error
                                dbf d0, HoldVal_WordTest_FillWord_rw      

                    HoldVal_ByteTest:
                        addq.l #1, a1                            ;start addr +1(BYTE ACCESS)

                        move.w #$FF, d3
                        bsr.w HoldVal_ByteTest_FillByte
                        move.w #$55, d3
                        bsr.w HoldVal_ByteTest_FillByte
                        move.w #$AA, d3
                        bsr.w HoldVal_ByteTest_FillByte
                        move.w #$00, d3
                        bsr.w HoldVal_ByteTest_FillByte

                        move.b #1, (a6)                         ;kick the Z80 watchdog
                        move.b #0, (a6)

                        move.w d2, -(sp)                        ;set ok/failed flag
                        move.l a2, -(sp)                        ;push return address
                        rts

                        HoldVal_ByteTest_FillByte:
                            move.b #1, (a6)                         ;kick the Z80 watchdog
                            move.b #0, (a6)

                            move.l d1, d0                       ;move loop counter to d0
                            movea.l a1, a0                      ;move start address to a0
                            HoldVal_ByteTest_FillByte_rw:
                                move.b (a0), d4
                                move.b d3, (a0)                 ;write $FF, 55, AA, 00
                                cmp.b (a0), d3                  ;read and compare
                                bne.s HoldVal_ByteTest_FillByte_err     ;if not matches, goto ERROR
                                move.b d4, (a0)                 ;rewrite
                                addq.l #2, a0                   ;+2 increment
                                dbf d0, HoldVal_ByteTest_FillByte_rw    ;loop
                            rts

                            HoldVal_ByteTest_FillByte_err:
                                move.b d4, (a0)                 ;rewrite
                                addq.l #2, a0                   ;+2 increment
                                bsr.s HoldVal_Error
                                dbf d0, HoldVal_ByteTest_FillByte_rw

                    HoldVal_Error:
                        move.w #1, d2                           ;set error flag
                        rts        


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

RAMTESTWAIT     dc.w 'WAIT A MOMENT', $0000
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
            move.w #0, -(sp)
            move.w #9, -(sp)
            move.w #15, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.l #$34000, -(sp)               ;copy tiles
            move.w #256, -(sp)
            move.w #1152, -(sp)
            move.w #1, -(sp)
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
                bsr.w funcDrawTilemap

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
                    bsr.w funcDrawTilemap

                    addq.w #1, d7
                    addq.w #2, d6
                    dbf d5, TSTRTNE_Screen_0_loop

            TSTRTNE_Screen_KeyInDelay_a:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.s TSTRTNE_Screen_1
                jsr funcFixedDelaySlow
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
                        move.w #$F1DC, -(sp)            ;hatched pattern
                        move.w #$0008, -(sp)            ;red
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcDrawTilemap

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
                        move.w #$F1DC, -(sp)            ;hatched pattern
                        move.w #$0002, -(sp)            ;white
                        move.w d1, -(sp)
                        move.w d0, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcDrawTilemap

                        dbf d6, TSTRTNE_Screen_1_white_looph

                    dbf d7, TSTRTNE_Screen_1_white_loopv

            TSTRTNE_Screen_KeyInDelay_b:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.s TSTRTNE_Screen_KeyInDelay_b





        *--------------------------------------------------------
        *
        *       TESTMENU_Scroll subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Scroll:
            lea $880, a6                                ;load register address
            move.w #2, (a6)                             ;tilemap mode/code
            move.w #0, $2(a6)                           ;Xscroll binary
            move.w #0, $4(a6)                           ;Yscroll binary
            move.w #$0000, $6(a6)                       ;Xscroll BCD
            move.w #$0000, $8(a6)                       ;Yscroll BCD

            ;0x700 sprite list
            lea SCROBJ0, a0
            lea $700, a5
            move.w #10, d0                              ;11 sprites
            TSTRTNE_Scroll_copyobj_list:
                move.w #7, d1                           ;8 properties
                TSTRTNE_Scroll_copyobj_push:
                    move.w (a0), (a5)+
                    move.w (a0)+, -(sp)
                    dbf d1, TSTRTNE_Scroll_copyobj_push
                bsr.w funcDrawSprite
                dbf d0, TSTRTNE_Scroll_copyobj_list

            TSTRTNE_Scroll_DrawTM:
                eori.b #02, $1(a6)                      ;flip value

                btst.b #1, $1(a6)
                bne.w TSTRTNE_Scroll_DrawTM_fullbg

                ;TSTRTNE_Scroll_DrawTM_pattern
                    lea $52000, a0
                    lea $53000, a1
                    move.w #$7FF, d0
                    TSTRTNE_Scroll_DrawTM_pattern_clr:
                        move.w #$0002, $2000(a0)                    ;TM-A color 0002
                        move.w #$E000, (a0)+                        ;TM-A code E000

                        move.w #$0002, $2000(a1)                    ;TM-B color 0002
                        move.w #$0000, (a1)+                        ;TM-B code 0000

                        dbf d0, TSTRTNE_Scroll_DrawTM_pattern_clr

                    ;18*6 square 
                    ;64*32 screen
                    ;(2) 2 22 42
                    ;(10) 3 23 43
                    ;(18) 4 24 44
                    ;(24) 5 25 45

                    move.w #5, d0                                   ;offset reg
                    move.w #3, d1                                   ;Y reg
                    TSTRTNE_Scroll_DrawTM_pattern_yloop:
                        move.w #2, d2                               ;X reg
                        TSTRTNE_Scroll_DrawTM_pattern_xloop:
                            move.w d2, d3                           ;get xloop counter
                            mulu.w #20, d3                          ;20*xloop counter
                            add.w d0, d3                            ;d3+offset
                            
                            move.w d1, d4                           ;get yloop counter
                            lsl.w #3, d4                            ;8*yloop counter
                            addq.w #2, d4                           ;d4+2

                            move.w #18, -(sp)
                            move.w #6, -(sp)
                            move.w #$E100, -(sp)
                            move.w #$0006, -(sp)
                            move.w d3, -(sp)
                            move.w d4, -(sp)
                            move.w #0, -(sp)
                            bsr.w funcDrawTilemap

                            dbf d2, TSTRTNE_Scroll_DrawTM_pattern_xloop

                        subq.w #1, d0                               ;offset - 1

                        dbf d1, TSTRTNE_Scroll_DrawTM_pattern_yloop


                    lea TOPLEFT, a0
                    move.l a0, -(sp)
                    move.w #5, -(sp)
                    move.w #0, -(sp)
                    move.w #0, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    lea BOTTOMRIGHT, a0
                    move.l a0, -(sp)
                    move.w #5, -(sp)
                    move.w #56, -(sp)
                    move.w #31, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_Scroll_InEval

                TSTRTNE_Scroll_DrawTM_fullbg:
                    bra.w TSTRTNE_Scroll_InEval


            TSTRTNE_Scroll_InEval:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                        ;get latest input 

                btst.l #$5, d0
                beq.w TSTRTNE_Scroll_DrawTM

                btst.b #1, $1(a6)                       ;check (a6+1)[1]
                bne.s TSTRTNE_Scroll_MoveTM

                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TSTRTNE_Scroll_TMSwap

            TSTRTNE_Scroll_MoveTM:
                bsr.w funcCheckLongInput
                move.w (sp)+, d1                        ;get long input trigger
                and.w d1, d0

                ;TSTRTNE_Scroll_MoveTM_yinc
                    btst.l #$3, d0                                  ;check for DOWN
                    bne.s TSTRTNE_Scroll_MoveTM_ydec
                    addq.w #1, $4(a6)
                TSTRTNE_Scroll_MoveTM_ydec:
                    btst.l #$2, d0                                  ;check for UP
                    bne.s TSTRTNE_Scroll_MoveTM_xinc
                    subq.w #1, $4(a6)
                TSTRTNE_Scroll_MoveTM_xinc:
                    btst.l #$1, d0                                  ;check for RIGHT
                    bne.s TSTRTNE_Scroll_MoveTM_xdec
                    addq.w #1, $2(a6)
                TSTRTNE_Scroll_MoveTM_xdec:
                    btst.l #$0, d0                                  ;check for LEFT
                    bne.w TSTRTNE_Scroll_BCD
                    subq.w #1, $2(a6)
                bra.w TSTRTNE_Scroll_BCD

            ;            TM-B TM-A
            ;OBJ over A: XX00 1110
            ;OBJ over B: XX10 0000
    
            TSTRTNE_Scroll_TMSwap:                                  ;0=A 1=B
                eori.b #$01, $1(a6)                                 ;flip value

                cmpi.b #$00, $1(a6)                                 ;if TM-B
                bne.w TSTRTNE_Scroll_TMSwap_a2b

                ;TSTRTNE_Scroll_TMSwap_b2a                          ;B -> A
                    lea $50400, a0
                    lea $50000, a1
                    move.w #$200, d0
                    bsr.w TSTRTNE_Scroll_blockcopy                  ;Xscroll copy 

                    lea $50F00, a0
                    lea $50F80, a1
                    move.w #$40, d0
                    bsr.w TSTRTNE_Scroll_blockcopy                  ;Yscroll copy

                    lea $53000, a0
                    lea $52000, a1
                    move.w #$7FF, d0
                    TSTRTNE_Scroll_TMSwap_b2a_movetilemap:
                        move.w (a0), d1                             ;fetch code
                        move.w $2000(a0), d2                        ;fetch palette

                        andi.w #$0FFF, d1
                        ori.w #$E000, d1                            ;change PR code to E

                        move.w d2, $2000(a1)                        ;copy palette to target
                        move.w d1, (a1)+                            ;copy code to target

                        move.w #$0002, $2000(a0)                    ;change source address color
                        move.w #$0000, (a0)+                        ;change source address code

                        dbf d0, TSTRTNE_Scroll_TMSwap_b2a_movetilemap

                    lea $50400, a0
                    move.w #$200, d0                                ;50400-507FF
                    move.w #0, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50F00, a0
                    move.w #$40, d0                                 ;50F00-50F7F
                    move.w #0, d1
                    bsr.w TSTRTNE_Scroll_set

                    bra.w TSTRTNE_Scroll_BCD

                TSTRTNE_Scroll_TMSwap_a2b:                          ;A -> B
                    lea $50000, a0
                    lea $50400, a1
                    move.w #$200, d0
                    bsr.w TSTRTNE_Scroll_blockcopy                  ;Xscroll copy 

                    lea $50F80, a0
                    lea $50F00, a1
                    move.w #$40, d0
                    bsr.w TSTRTNE_Scroll_blockcopy                  ;Yscroll copy

                    lea $52000, a0
                    lea $53000, a1
                    move.w #$7FF, d0
                    TSTRTNE_Scroll_TMSwap_a2b_movetilemap:
                        move.w (a0), d1                             ;fetch code
                        move.w $2000(a0), d2                        ;fetch palette

                        andi.w #$0FFF, d1
                        ori.w #$2000, d1                            ;change PR code to 2

                        move.w d2, $2000(a1)                        ;copy palette to target
                        move.w d1, (a1)+                            ;copy code to target

                        move.w #$0002, $2000(a0)                    ;change source address color
                        move.w #$0000, (a0)+                        ;change source address code

                        dbf d0, TSTRTNE_Scroll_TMSwap_a2b_movetilemap

                    lea $50000, a0
                    move.w #$200, d0                                ;50000-503FF
                    move.w #0, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50F80, a0
                    move.w #$40, d0                                 ;50F80-50FFF
                    move.w #0, d1
                    bsr.w TSTRTNE_Scroll_set

                    bra.w TSTRTNE_Scroll_BCD

                

            TSTRTNE_Scroll_BCD:
                move.l #$882, -(sp)
                move.l #$886, -(sp)
                move.w #9, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv

                move.l #$884, -(sp)
                move.l #$888, -(sp)
                move.w #8, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv

            TSTRTNE_Scroll_UpdateVal:
                cmpi.b #$00, $1(a6)                                 ;if TM-B
                bne.w TSTRTNE_Scroll_UpdateVal_b

                ;TSTRTNE_Scroll_UpdateVal_a
                    lea $50000, a0
                    move.w #$100, d0                                ;50000-501FF(SCROLL[7:0])
                    move.w $2(a6), d1
                    andi.w #$00FF, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50200, a0
                    move.w #$100, d0                                ;50000-501FF(SCROLL[8])
                    move.w $2(a6), d1
                    lsr.w #8, d1
                    andi.w #$0001, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50F80, a0
                    move.w #$40, d0                                 ;50F80-50FFF
                    move.w $4(a6), d1
                    bsr.w TSTRTNE_Scroll_set

                    bra.s TSTRTNE_Scroll_PrintVal

                TSTRTNE_Scroll_UpdateVal_b:
                    lea $50400, a0
                    move.w #$100, d0                                ;50400-505FF(SCROLL[7:0])
                    move.w $2(a6), d1
                    andi.w #$00FF, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50600, a0
                    move.w #$100, d0                                ;50600-507FF(SCROLL[8])
                    move.w $2(a6), d1
                    lsr.w #8, d1
                    andi.w #$0001, d1
                    bsr.w TSTRTNE_Scroll_set

                    lea $50F00, a0
                    move.w #$40, d0                                 ;50F00-50F7F
                    move.w $4(a6), d1
                    bsr.w TSTRTNE_Scroll_set

            TSTRTNE_Scroll_PrintVal:
                ;update CODE
                lea $700, a0
                move.w $2(a6), d0
                andi.w #$01FF, d0

                cmpi.w #10, d0                                      ;less than 10
                blt.s TSTRTNE_Scroll_PrintVal_xval10
                cmpi.w #100, d0                                     ;less than 100
                blt.s TSTRTNE_Scroll_PrintVal_xval100

                ;TSTRTNE_Scroll_PrintVal_xval1000:
                    move.w #$00FB, $8(a0)
                    move.w #2, d0
                    add.l #$10, a0                                  ;draws decimal value only
                    bra.s TSTRTNE_Scroll_PrintVal_xval_updt

                TSTRTNE_Scroll_PrintVal_xval100:
                    move.w #$00FD, $8(a0)
                    move.w #$00FB, $18(a0)
                    move.w #1, d0
                    add.l #$20, a0
                    bra.s TSTRTNE_Scroll_PrintVal_xval_updt

                TSTRTNE_Scroll_PrintVal_xval10:
                    move.w #$00FD, $8(a0)
                    move.w #$00FD, $18(a0)
                    move.w #$00FB, $28(a0)
                    move.w #0, d0
                    add.l #$30, a0
                    
                TSTRTNE_Scroll_PrintVal_xval_updt:
                    move.w d0, d2                                   ;get loop counter
                    mulu.w #4, d2
                    
                    move.w $6(a6), d1
                    lsr.w d2, d1

                    andi.w #$000F, d1
                    addi.w #$00F0, d1

                    move.w d1, $8(a0)
                    add.l #$10, a0

                    dbf d0, TSTRTNE_Scroll_PrintVal_xval_updt


                ;update CODE
                lea $740, a0
                move.w $4(a6), d0
                andi.w #$00FF, d0

                cmpi.w #10, d0                                      ;less than 10
                blt.s TSTRTNE_Scroll_PrintVal_yval10
                cmpi.w #100, d0                                     ;less than 100
                blt.s TSTRTNE_Scroll_PrintVal_yval100

                ;TSTRTNE_Scroll_PrintVal_yval1000:
                    move.w #$00FB, $8(a0)
                    move.w #2, d0
                    add.l #$10, a0
                    bra.s TSTRTNE_Scroll_PrintVal_yval_updt

                TSTRTNE_Scroll_PrintVal_yval100:
                    move.w #$00FD, $8(a0)
                    move.w #$00FB, $18(a0)
                    move.w #1, d0
                    add.l #$20, a0
                    bra.s TSTRTNE_Scroll_PrintVal_yval_updt

                TSTRTNE_Scroll_PrintVal_yval10:
                    move.w #$00FD, $8(a0)
                    move.w #$00FD, $18(a0)
                    move.w #$00FB, $28(a0)
                    move.w #0, d0
                    add.l #$30, a0

                TSTRTNE_Scroll_PrintVal_yval_updt:
                    move.w d0, d2                                   ;get loop counter
                    mulu.w #4, d2
                    
                    move.w $8(a6), d1
                    lsr.w d2, d1

                    andi.w #$000F, d1
                    addi.w #$00F0, d1

                    move.w d1, $8(a0)
                    add.l #$10, a0

                    dbf d0, TSTRTNE_Scroll_PrintVal_yval_updt

                ;draw
                lea $700, a0
                move.w #7, d0
                TSTRTNE_Scroll_PrintVal_draw:
                    move.w #7, d1
                    TSTRTNE_Scroll_PrintVal_draw_push:
                        move.w (a0)+, -(sp)
                        dbf d1, TSTRTNE_Scroll_PrintVal_draw_push
                    bsr.w funcDrawSprite
                    dbf d0, TSTRTNE_Scroll_PrintVal_draw

            TSTRTNE_Scroll_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelayFast
                bra.w TSTRTNE_Scroll_InEval

            TSTRTNE_Scroll_blockcopy:
                subq.w #1, d0
                TSTRTNE_Scroll_blockcopy_loop:
                    move.w (a0)+, (a1)+                         ;copy
                    dbf d0, TSTRTNE_Scroll_blockcopy_loop
                rts

            TSTRTNE_Scroll_set:
                subq.w #1, d0
                TSTRTNE_Scroll_set_loop:
                    move.w d1, (a0)+                            ;set scroll value
                    dbf d0, TSTRTNE_Scroll_set_loop
                rts

TOPLEFT         dc.w '+(0,0)', $0000
BOTTOMRIGHT     dc.w '(63,31)+' $0000
SCROBJ0         dc.w $0004, $0080, $000C, $00E4, $00FD, $0004, $0000, $0011 ;+
SCROBJ1         dc.w $0004, $0080, $0014, $00E4, $00FD, $0004, $0000, $0012 ;digit2
SCROBJ2         dc.w $0004, $0080, $001C, $00E4, $00FB, $0004, $0000, $0013 ;digit1
SCROBJ3         dc.w $0004, $0080, $0024, $00E4, $00F0, $0004, $0000, $0014 ;digit0
SCROBJ4         dc.w $0004, $0080, $0034, $00E4, $00FD, $0004, $0000, $0016 ;+
SCROBJ5         dc.w $0004, $0080, $003C, $00E4, $00FD, $0004, $0000, $0017 ;digit2
SCROBJ6         dc.w $0004, $0080, $0044, $00E4, $00FB, $0004, $0000, $0018 ;digit1
SCROBJ7         dc.w $0004, $0080, $004C, $00E4, $00F0, $0004, $0000, $0019 ;digit0
SCROBJ8         dc.w $0004, $0080, $0004, $00E4, $00FA, $0004, $0000, $0010 ;(
SCROBJ9         dc.w $0004, $0080, $002C, $00E4, $00FC, $0004, $0000, $0015 ;,
SCROBJA         dc.w $0004, $0080, $0054, $00E4, $00FA, $0004, $0001, $001A ;)
        ;23C80~
        ;mask = FD




        *--------------------------------------------------------
        *
        *       TESTMENU_OBJ subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_OBJ:
            move.w #$F000, -(sp)                            ;clear tilemap A
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            bsr.w funcFillTilemap

            move.w #$205F, -(sp)                            ;clear tilemap B
            move.w #$0002, -(sp)
            move.w #1, -(sp)
            bsr.w funcFillTilemap

            move.w $822, d0
            cmpi.w #$573, d0                            ;konami 573
            beq.s TSTRTNE_OBJ_Init                      ;check DATA LOADED flag

            lea NOWLOADING, a0                          ;print nowloading
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #9, -(sp)
            move.w #15, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.l #$3D400, -(sp)                       ;copy tiles(2D800 +2C00 on ROM)
            move.w #88, -(sp)
            move.w #1448, -(sp)
            move.w #1, -(sp)
            jsr funcLoadBubble

            move.w #$573, $822

            TSTRTNE_OBJ_Init:
                lea $700, a6                                ;load sprite register addr
                move.w #63, d0
                TSTRTNE_OBJ_OBJListClr:
                    move.l #0, (a6)+
                    dbf d0, TSTRTNE_OBJ_OBJListClr

                lea OBJTSTOBJ, a5
                lea $700, a6
                move.w #7, d0
                TSTRTNE_OBJ_OBJListCopy:
                    move.w (a5), (a6)+
                    move.w (a5)+, -(sp)
                    dbf d0, TSTRTNE_OBJ_OBJListCopy
                bsr.w funcDrawSprite

                lea $880, a6                                ;load register address
                move.w #0, (a6)                             ;initialize sprite edit menu code
                move.w #0, $2(a6)                           ;initialize UNDER MODIFICATION flag
                move.w #$0080, $4(a6)                       ;initialize ZOOM binary value: 00_1.000_0000
                move.l #$10000000, $6(a6)                   ;initialize ZOOM BCD: 1.0000000
                move.w #4, $A(a6)                           ;initialize SIZE binary
                move.w #0, $C(a6)                           ;initialize FLIP binary
                move.w #0, $E(a6)                           ;initialize Xpos binary
                move.w #16, $10(a6)                         ;initialize Ypos binary
                move.w #$0000, $12(a6)                      ;initialize Xpos BCD
                move.w #$0000, $14(a6)                      ;initialize Ypos BCD
                move.w #8, $16(a6)                          ;initialize Xwidth binary
                move.w #8, $18(a6)                          ;initialize Ywidth binary
                move.w #$8, $1A(a6)                         ;initialize Xwidth BCD
                move.w #$8, $1C(a6)                         ;initialize Ywidth BCD
                move.w #0, $1E(a6)                          ;initialize error flag

            ;[USER INTERFACE]
            ;XPOS:(read only) YPOS:(read only)
            ;OBJ TYPE:A(32*16)...(selectable) (0)
            ;ZOOM: 0x080 = 1.0000000(adjustable)
            ;HFLIP:0  VFLIP:0 (1, 2)
            ;EDIT SPRITE (3)

            ;[SPRITE TYPE LIST]
            ;0=32*32 1=16*32 2=32*16 3=64*64  4=8*8 5=16*8 6=8*16 7=16*16
            ;8=32*64 9=16*64 A=32*32 B=64*128 C=8*8 D=16*8 E=8*16 F=16*16
            ;=16+8+8+64+2+2+2+4+32+16+16+128 + (2+2+2+4) = 298+10
            ;32 tiles per tileline = 11 tilelines
            ;32*11=352 tiles, 88 pages

            ;[SPRITE CODE LIST]
            ;                CODE
            ;TYPE0/A = 6A0 = 350
            ;TYPE1   = 6B0 = 358
            ;TYPE2   = 6B8 = 35C
            ;TYPE3   = 6C0 = 360
            ;TYPE4/C = 700 = 380
            ;TYPE5/D = 702 = 381
            ;TYPE6/E = 704 = 382
            ;TYPE7/F = 708 = 384
            ;TYPE8   = 710 = 388
            ;TYPE9   = 730 = 398
            ;TYPEB   = 780 = 3C0

            move.w #5, d0                                   ;repeat 5 times
            move.w #5, d1                                   ;ypos
            lea OBJTSTMSG0, a0
            TSTRTNE_OBJ_PrntMenu_loop1:
                move.l a0, -(sp)
                move.w #0, -(sp)
                move.w #8, -(sp)                            ;xpos fixed
                move.w d1, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #2, d1
                add.l #18, a0

                dbf d0, TSTRTNE_OBJ_PrntMenu_loop1
            
            addq.w #1, d1
            move.w #1, d0                                   ;repeat 2 times
            TSTRTNE_OBJ_PrntMenu_loop2:
                move.l a0, -(sp)
                move.w #0, -(sp)
                move.w #8, -(sp)                            ;xpos fixed
                move.w d1, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #3, d1
                add.l #18, a0

                dbf d0, TSTRTNE_OBJ_PrntMenu_loop2

            bra.w TSTRTNE_OBJ_Draw
            
            TSTRTNE_OBJ_ModeEval:
                move.w (a6), d0                                 ;get menu number
                
                cmpi.w #0, d0
                beq.w TSTRTNE_OBJ_TypeSel
                cmpi.w #1, d0
                beq.w TSTRTNE_OBJ_HFlip
                cmpi.w #2, d0
                beq.w TSTRTNE_OBJ_VFlip
                cmpi.w #3, d0
                beq.w TSTRTNE_OBJ_ObjEdit
                bra.w TSTRTNE_OBJ_KeyInDelay


            TSTRTNE_OBJ_TypeSel:
                cmpi.w #0, $2(a6)                                   ;edit mode
                bne.w TSTRTNE_OBJ_TypeSel_mod

                ;TSTRTNE_OBJ_TypeSel_menu
                    bsr.w funcCheckInput                            ;check P1 button input
                    move.w (sp)+, d0                                ;get latest input

                    btst.l #$3, d0                                  ;check for DOWN
                    beq.s TSTRTNE_OBJ_TypeSel_menu_inc
                    btst.l #$1, d0                                  ;check for RIGHT
                    beq.s TSTRTNE_OBJ_TypeSel_menu_enter
                    btst.l #$0, d0                                  ;check for LEFT
                    beq.s TSTRTNE_OBJ_TypeSel_menu_enter
                    bra.w TSTRTNE_OBJ_Draw
                    
                    TSTRTNE_OBJ_TypeSel_menu_inc:
                        addi.w #1, (a6)
                        bra.w TSTRTNE_OBJ_Draw

                    TSTRTNE_OBJ_TypeSel_menu_enter:
                        move.w #1, $2(a6)
                        bra.w TSTRTNE_OBJ_Draw

                TSTRTNE_OBJ_TypeSel_mod:
                    bsr.w funcCheckInput                            ;check P1 button input
                    move.w (sp)+, d0                                ;get latest input

                    btst.l #$4, d0                                  ;check for A
                    beq.s TSTRTNE_OBJ_TypeSel_mod_unknown
                    btst.l #$3, d0                                  ;check for DOWN
                    beq.s TSTRTNE_OBJ_TypeSel_mod_dec
                    btst.l #$2, d0                                  ;check for UP
                    beq.s TSTRTNE_OBJ_TypeSel_mod_inc
                    btst.l #$1, d0                                  ;check for RIGHT
                    beq.s TSTRTNE_OBJ_TypeSel_mod_exit
                    btst.l #$0, d0                                  ;check for LEFT
                    beq.s TSTRTNE_OBJ_TypeSel_mod_exit
                    bra.w TSTRTNE_OBJ_Draw

                    TSTRTNE_OBJ_TypeSel_mod_unknown:
                        cmpi.w #8, $A(a6)                           ;if <8
                        blt.w TSTRTNE_OBJ_TypeSel_mod_unknown_en    ;unknow bit enable
                        subq.w #8, $A(a6)
                        bra.w TSTRTNE_OBJ_UpdateVal
                        TSTRTNE_OBJ_TypeSel_mod_unknown_en:
                            addq.w #8, $A(a6)
                            bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_TypeSel_mod_inc:
                        cmpi.w #$7, $A(a6)                          ;if 7
                        beq.w TSTRTNE_OBJ_Draw                      ;do not increase
                        cmpi.w #$F, $A(a6)                          ;if F
                        beq.w TSTRTNE_OBJ_Draw                      ;do not increase
                        addi.w #1, $A(a6)
                        bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_TypeSel_mod_dec:
                        cmpi.w #$0, $A(a6)                          ;if 0
                        beq.w TSTRTNE_OBJ_Draw                      ;do not decrease
                        cmpi.w #$8, $A(a6)                          ;if 8
                        beq.w TSTRTNE_OBJ_Draw                      ;do not decrease
                        subi.w #1, $A(a6)
                        bra.w TSTRTNE_OBJ_UpdateVal

                   TSTRTNE_OBJ_TypeSel_mod_exit:
                        move.w #0, $2(a6)
                        bra.w TSTRTNE_OBJ_Draw


            TSTRTNE_OBJ_HFlip:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_OBJ_HFlip_flip
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_OBJ_HFlip_inc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_OBJ_HFlip_dec
                bra.w TSTRTNE_OBJ_Draw
                
                TSTRTNE_OBJ_HFlip_flip:
                    eori.w #$0001, $C(a6)
                    bra.w TSTRTNE_OBJ_UpdateVal

                TSTRTNE_OBJ_HFlip_inc:
                    addi.w #1, (a6)
                    bra.w TSTRTNE_OBJ_Draw

                TSTRTNE_OBJ_HFlip_dec:
                    subi.w #1, (a6)
                    bra.w TSTRTNE_OBJ_Draw


            TSTRTNE_OBJ_VFlip:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_OBJ_VFlip_flip
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_OBJ_VFlip_inc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_OBJ_VFlip_dec
                bra.w TSTRTNE_OBJ_Draw
                
                TSTRTNE_OBJ_VFlip_flip:
                    eori.w #$0002, $C(a6)
                    bra.w TSTRTNE_OBJ_UpdateVal

                TSTRTNE_OBJ_VFlip_inc:
                    addi.w #1, (a6)
                    bra.w TSTRTNE_OBJ_Draw

                TSTRTNE_OBJ_VFlip_dec:
                    subi.w #1, (a6)
                    bra.w TSTRTNE_OBJ_Draw


            TSTRTNE_OBJ_ObjEdit:
                cmpi.w #0, $2(a6)                                   ;edit mode
                bne.w TSTRTNE_OBJ_ObjEdit_mod
                
                ;TSTRTNE_OBJ_ObjEdit_menu
                    bsr.w funcCheckInput                            ;check P1 button input
                    move.w (sp)+, d0                                ;get latest input

                    btst.l #$4, d0                                  ;check for A
                    beq.s TSTRTNE_OBJ_ObjEdit_menu_enter
                    btst.l #$2, d0                                  ;check for UP
                    beq.s TSTRTNE_OBJ_ObjEdit_menu_dec
                    bra.w TSTRTNE_OBJ_Draw

                    TSTRTNE_OBJ_ObjEdit_menu_enter:
                        move.w #1, $2(a6)
                        bra.w TSTRTNE_OBJ_Draw
                    
                    TSTRTNE_OBJ_ObjEdit_menu_dec:
                        subi.w #1, (a6)
                        bra.w TSTRTNE_OBJ_Draw


                TSTRTNE_OBJ_ObjEdit_mod:
                    bsr.w funcCheckInput                            ;check P1 button input
                    move.w (sp)+, d0                                ;get latest input
                    btst.l #$4, d0                                  ;check for A
                    beq.w TSTRTNE_OBJ_ObjEdit_mod_exit
                    btst.l #$5, d0                                  ;check for B
                    beq.w TSTRTNE_OBJ_ObjEdit_mod_rst
                    
                    move.w $5CC02, d1
                    btst.l #$6, d1                                  ;check for C
                    beq.s TSTRTNE_OBJ_ObjEdit_mod_zoom

                    bsr.w funcCheckLongInput
                    move.w (sp)+, d1                                ;get latest input
                    and.w d1, d0                                    ;AND long andd short inputs
                    bra.w  TSTRTNE_OBJ_ObjEdit_mod_mov


                    TSTRTNE_OBJ_ObjEdit_mod_zoom:
                        bsr.w funcCheckLongInput
                        move.w (sp)+, d1                            ;get latest input
                        cmpi.b #$BB, d1                             ;ZOOM+ (C+up)
                        beq.w TSTRTNE_OBJ_ObjEdit_mod_zoominc
                        cmpi.b #$B7, d1                             ;ZOOM- (C+down)
                        beq.w TSTRTNE_OBJ_ObjEdit_mod_zoomdec
                        btst.l #$3, d0                              ;check for DOWN
                        beq.w TSTRTNE_OBJ_ObjEdit_mod_zoomdec
                        btst.l #$2, d0                              ;check for UP
                        beq.s TSTRTNE_OBJ_ObjEdit_mod_zoominc
                        bra.w TSTRTNE_OBJ_Draw


                    TSTRTNE_OBJ_ObjEdit_mod_exit:
                        movea.l a6, a0                              ;get reg start addr
                        move.w $C(a6), d1                           ;backup flip
                        move.w $A(a6), d2                           ;backup size
                        add.l #2, a0                                ;start from $882
                        move.w #13, d0                              ;ends at $89D
                        TSTRTNE_OBJ_ObjEdit_mod_exit_loop:
                            move.w #0, (a0)+
                            dbf d0, TSTRTNE_OBJ_ObjEdit_mod_exit_loop
                        move.w #$0080, $4(a6)                       ;initialize ZOOM binary value: 00_1.000_0000
                        move.w d1, $C(a6)                           ;restore FLIP binary
                        move.w d2, $A(a6)                           ;restore size
                        move.w #16, $10(a6)                         ;ypos = 16
                        bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_ObjEdit_mod_rst:
                        move.w #$0080, $4(a6)                       ;initialize ZOOM binary
                        move.w #0, $C(a6)                           ;initialize FLIP binary
                        move.w #0, $E(a6)                           ;initialize Xpos binary
                        move.w #16, $10(a6)                         ;initialize Ypos binary
                        bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_ObjEdit_mod_zoominc:
                        cmpi.w #$03FF, $4(a6)                       ;if =3FF
                        beq.w TSTRTNE_OBJ_Draw
                        addq.w #1, $4(a6)
                        bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_ObjEdit_mod_zoomdec:
                        cmpi.w #$0000, $4(a6)                       ;if =000(DIV/0!)
                        beq.w TSTRTNE_OBJ_Draw
                        subq.w #1, $4(a6)
                        bra.w TSTRTNE_OBJ_UpdateVal

                    TSTRTNE_OBJ_ObjEdit_mod_mov:
                        ;TSTRTNE_OBJ_ObjEdit_mod_mov_dn
                            btst.l #$3, d0                                  ;check for DOWN
                            bne.w TSTRTNE_OBJ_ObjEdit_mod_mov_up
                            addq.w #1, $10(a6)
                        TSTRTNE_OBJ_ObjEdit_mod_mov_up:
                            btst.l #$2, d0                                  ;check for UP
                            bne.w TSTRTNE_OBJ_ObjEdit_mod_mov_r
                            subq.w #1, $10(a6)
                        TSTRTNE_OBJ_ObjEdit_mod_mov_r:
                            btst.l #$1, d0                                  ;check for RIGHT
                            bne.w TSTRTNE_OBJ_ObjEdit_mod_mov_l
                            addq.w #1, $E(a6)
                        TSTRTNE_OBJ_ObjEdit_mod_mov_l:
                            btst.l #$0, d0                                  ;check for LEFT
                            bne.w TSTRTNE_OBJ_UpdateVal
                            subq.w #1, $E(a6)

            TSTRTNE_OBJ_UpdateVal:
                lea $700, a5
                move.w $4(a6), $2(a5)                               ;update zoom value

                lea OBJTSTTYPE, a0                                  ;get object type start address
                move.l #0, d0                                       ;initialize d0 
                move.l #0, d1                                       ;initialize d1   

                move.w $A(a6), d0                                   ;get size value
                move.w d0, (a5)                                     ;update size value
                lsl.w #1, d0                                        ;size value * 2
                add.l d0, a0                                        ;type list addr + d0
                move.w (a0), $8(a5)                                 ;update sprite code
                add.l #$20, a0                                      ;current type list addr + $20
                move.w (a0), d0                                     ;copy width
                move.w d0, d1                                       ;copy width
                lsr.w #8, d0                                        ;Xwidth
                andi.w #$00FF, d1                                   ;Ywidth
                move.w $C(a6), $C(a5)                               ;update flip
                move.w $E(a6), $4(a5)                               ;update Xpos
                move.w $10(a6), $6(a5)                              ;update Ypos

                move.b #1, $5E008                                   ;kick the watchdog
                move.b #0, $5E008

                tst.w $4(a6)                                        ;if ZOOM = 0
                beq.s TSTRTNE_OBJ_BCD                               ;DIV/0!!

                ;TSTRTNE_OBJ_UpdateVal_expected_x
                    lsl.w #7, d0                                        ;shift 7 bits left(3+7 FP)
                    divu.w $4(a6), d0                                   ;Xwidth/zoom
                    move.w d0, $16(a6)                                  ;write expected Xwidth
                    swap d0
                    tst.w d0                                            ;if remainder is 0        
                    beq.s TSTRTNE_OBJ_UpdateVal_expected_y              ;calculate y
                    addq.w #1, $16(a6)                                  ;if not, add 1

                TSTRTNE_OBJ_UpdateVal_expected_y:
                    lsl.w #7, d1                                        ;shift 7 bits left(3+7 FP)
                    divu.w $4(a6), d1                                   ;Ywidth/zoom
                    move.w d1, $18(a6)                                  ;write expected Ywidth
                    swap d1
                    tst.w d1                                            ;if remainder is 0        
                    beq.s TSTRTNE_OBJ_BCD                               ;BCD conversion
                    addq.w #1, $18(a6)                                  ;if not, add 1

            TSTRTNE_OBJ_BCD:
                ;ZOOM BCD FORMAT
                ; 0XXX.XXXX_XXXX_XXXX_XXXX_XXXX_XXXX_XXXX
                ;    7.   0    0    7    8    1    2    5
                move.l #$884, -(sp)
                move.l #$886, -(sp)
                move.w #7, -(sp)
                move.w #1, -(sp)
                bsr.w funcBcdConv

                move.w $4(a6), d0                                   ;get zoom binary value
                swap d0                                             ;move zoom word value to high byte
                lsl.l #5, d0                                        ;shift left 5 bits
                andi.l #$70000000, d0                               ;mask fractional part
                or.l d0, $6(a6)                                     ;write

                ;Xpos
                move.l #$88E, -(sp)
                move.l #$892, -(sp)
                move.w #9, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv

                ;Ypos
                move.l #$890, -(sp)
                move.l #$894, -(sp)
                move.w #8, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv

                ;Expected Xwidth
                move.l #$896, -(sp)
                move.l #$89A, -(sp)
                move.w #12, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv

                ;Expected Ywidth
                move.l #$898, -(sp)
                move.l #$89C, -(sp)
                move.w #12, -(sp)
                move.w #0, -(sp)
                bsr.w funcBcdConv
            
            TSTRTNE_OBJ_Draw:
                lea $700, a5

                TSTRTNE_OBJ_Draw_attr:
                    move.w #2, d0                                   ;repeat 3 times
                    move.w #9, d1                                   ;ypos
                    move.w #2, d2                                   ;
                    move.w (a6), d3                                 ;2 - selected menu(2)
                    sub.w d3, d2
                    lea OBJTSTMSG2, a0
                    TSTRTNE_OBJ_Draw_attr_loop:
                        move.w #0, d3                               ;navy
                        cmp.w d0, d2
                        bne.s TSTRTNE_OBJ_Draw_attr_loop_prnt
                        move.w #4, d3                               ;red

                        TSTRTNE_OBJ_Draw_attr_loop_prnt:
                            move.l a0, -(sp)
                            move.w d3, -(sp)
                            move.w #8, -(sp)                        ;xpos fixed
                            move.w d1, -(sp)
                            move.w #0, -(sp)
                            bsr.w funcPrintText

                        addq.w #2, d1
                        add.l #18, a0

                        dbf d0, TSTRTNE_OBJ_Draw_attr_loop

                    lea OBJTSTMSG7, a0
                    move.w #0, d0                                   ;navy
                    cmpi.w #3, (a6)
                    bne.s TSTRTNE_OBJ_Draw_attr_test
                    move.w #4, d0
                    TSTRTNE_OBJ_Draw_attr_test:
                        move.l a0, -(sp)
                        move.w d0, -(sp)
                        move.w #8, -(sp)                            ;xpos fixed
                        move.w #21, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                move.l #0, d0                                       ;initialize
                move.w $12(a6), d0                                  
                bsr.w TSTRTNE_OBJ_Draw_bcd2ascii
                move.l d0, $20(a5)

                move.l #0, d0                                       ;initialize
                move.w $14(a6), d0                                  
                bsr.w TSTRTNE_OBJ_Draw_bcd2ascii
                move.l d0, $30(a5)

                move.w #0, $1E(a6)
                tst.w $4(a6)                                        ;if 0
                beq.s TSTRTNE_OBJ_Draw_div0
                cmpi.w #512, $16(a6)                                ;Xmax 512 pixels
                bgt.s TSTRTNE_OBJ_Draw_ovfl
                cmpi.w #256, $18(a6)                                ;Ymax 256 pixels
                bgt.s TSTRTNE_OBJ_Draw_ovfl

                move.l #0, d0                                       ;initialize
                move.w $1A(a6), d0                                  
                bsr.s TSTRTNE_OBJ_Draw_bcd2ascii
                ori.l #$0000002A, d0                                ;add *
                move.l d0, $40(a5)

                move.l #0, d0                                       ;initialize
                move.w $1C(a6), d0                                  
                bsr.s TSTRTNE_OBJ_Draw_bcd2ascii
                move.l d0, $44(a5)
                bra.s TSTRTNE_OBJ_Draw_zoom2ascii

                TSTRTNE_OBJ_Draw_bcd2ascii:
                                                                    ;0000_0BCD
                    ror.l #4, d0                                    ;D000_00BC
                    lsl.w #4, d0                                    ;D000_0BC0
                    lsr.b #4, d0                                    ;D000_0B0C
                    swap d0                                         ;0B0C_D000
                    lsr.w #4, d0                                    ;0B0C_0D00
                    ori.l #$30303000, d0
                    rts

                TSTRTNE_OBJ_Draw_ovfl:
                    move.w #1, $1E(a6)                              ;set error flag
                    move.l #$4255464F, $40(a5)                      ;text BUFO
                    move.l #$56464C00, $44(a5)                      ;text VFL 
                    bra.s TSTRTNE_OBJ_Draw_zoom2ascii

                TSTRTNE_OBJ_Draw_div0:
                    move.w #1, $1E(a6)                              ;set error flag
                    move.l #$4449562F, $40(a5)                      ;text DIV/
                    move.l #$30212100, $44(a5)                      ;text 0!!

                TSTRTNE_OBJ_Draw_zoom2ascii:
                    move.l #0, d0                                   ;initialize
                    move.w $6(a6), d0                               ;0000_ABCD
                    lsl.l #4, d0                                    ;000A_BCD0
                    lsr.w #4, d0                                    ;000A_0BCD
                    lsr.b #4, d0                                    ;000A_0B0C
                    swap d0                                         ;0B0C_000A
                    lsl.w #8, d0                                    ;0B0C_0A00
                    swap d0                                         ;0A00_0B0C
                    ori.l #$302E3030, d0                            ;3A2E_3B3C
                    move.l d0, $10(a5)

                    move.l $6(a6), d0                               ;ABCD_EFGH
                    lsl.l #4, d0                                    ;BCDE_FGH0
                    swap d0                                         ;FGH0_BCDE
                    lsl.w #4, d0                                    ;FGH0_CDE0
                    lsr.b #4, d0                                    ;FGH0_CD0E
                    andi.w #$0F0F, d0                               ;FGH0_0D0E
                    swap d0                                         ;0D0E_FGH0
                    lsr.w #4, d0                                    ;0D0E_0FGH
                    lsr.b #4, d0                                    ;0D0E_0F0G
                    ori.l #$30303030, d0                            ;3D3E_3F3G
                    move.l d0, $14(a5)

                    move.w $8(a6), d0                               ;XXXX_EFGH
                    lsl.w #8, d0                                    ;XXXX_GH00
                    swap d0                                         ;GH00_XXXX
                    andi.l #$0F000000, d0                           ;0H00_0000
                    ori.l #$30000000, d0                            ;3H00_0000
                    move.l d0, $18(a5)

                ;ZOOM
                lea $710, a0
                move.w #5, d0
                move.l a0, -(sp)
                move.w #1, -(sp)
                move.w #11, -(sp)                            ;xpos fixed
                move.w #16, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                ;XY
                add.l #$10, a0
                move.w #5, d0
                move.w #1, d1
                TSTRTNE_OBJ_Draw_xypos:
                    move.l a0, -(sp)
                    move.w #1, -(sp)
                    move.w #20, -(sp)                            ;xpos fixed
                    move.w d0, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    addq.w #2, d0
                    add.l #$10, a0
                    dbf d1, TSTRTNE_OBJ_Draw_xypos
                
                ;EXPECTED SIZE
                move.w #1, d0
                tst.w $1E(a6)
                bne.w TSTRTNE_OBJ_Draw_expsize_err
                bra.s TSTRTNE_OBJ_Draw_expsize

                TSTRTNE_OBJ_Draw_expsize_err:
                    move.w #4, d0
                
                TSTRTNE_OBJ_Draw_expsize:
                    move.l a0, -(sp)
                    move.w d0, -(sp)
                    move.w #12, -(sp)                               ;xpos fixed
                    move.w #19, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                ;ORIGINAL SIZE
                lea OBJTSTSIZE0, a0
                move.w #0, d0                                       ;initialize
                move.w $A(a6), d0                                   ;get size code
                lsl.w #3, d0
                add.l d0, a0                                        ;get text address

                move.w #1, d0
                cmpi.w #0, (a6)
                bne.s TSTRTNE_OBJ_Draw_orgsize
                tst.w $2(a6)                                        ;check UNDER MODIFICATION flag
                beq.s TSTRTNE_OBJ_Draw_orgsize
                move.w #3, d0
                TSTRTNE_OBJ_Draw_orgsize:
                    move.l a0, -(sp)
                    move.w d0, -(sp)
                    move.w #16, -(sp)                                   ;xpos
                    move.w #9, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                ;FLIP
                lea OBJTSTHFLIP, a0
                move.w $C(a6), d0
                btst.l #0, d0
                bne.s TSTRTNE_OBJ_Draw_hflip                        ;flipped
                add.l #16, a0                                       ;normal
                TSTRTNE_OBJ_Draw_hflip:
                    move.l a0, -(sp)
                    move.w #4, -(sp)
                    move.w #18, -(sp)                               ;xpos
                    move.w #28, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                lea OBJTSTVFLIP, a0
                move.w $C(a6), d0
                btst.l #1, d0
                bne.s TSTRTNE_OBJ_Draw_vflip                        ;flipped
                add.l #8, a0                                        ;normal
                TSTRTNE_OBJ_Draw_vflip:
                    move.l a0, -(sp)
                    move.w #4, -(sp)
                    move.w #25, -(sp)                               ;xpos
                    move.w #28, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText
                
                lea OBJTSTNORM, a0
                move.w (a6), d0                                     ;cursor pos
                add.w $2(a6), d0                                    ;+ flag
                cmpi.w #4, d0
                bne.s TSTRTNE_OBJ_Draw_editmode
                add.l #8, a0                                        ;select OBJTSTEDIT
                TSTRTNE_OBJ_Draw_editmode:
                    move.l a0, -(sp)
                    move.w #3, -(sp)
                    move.w #2, -(sp)                                ;xpos
                    move.w #28, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                move.w #7, d0                                       ;8 properties
                TSTRTNE_OBJ_Draw_obj_push:
                    move.w (a5)+, -(sp)
                    dbf d0, TSTRTNE_OBJ_Draw_obj_push
                bsr.w funcDrawSprite

            TSTRTNE_OBJ_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelayFast
                bra.w TSTRTNE_OBJ_ModeEval

OBJTSTTYPE  dc.w $0350, $0358, $035C, $0360, $0380, $0381, $0382, $0384, $0388, $0398, $0350, $03C0, $0380, $0381, $0382, $0384 
OBJTSTSIZE  dc.w $2020, $1020, $2010, $4040, $0808, $1008, $0810, $1010, $2040, $1040, $2020, $4080, $0808, $1008, $0810, $1010
OBJTSTOBJ   dc.w $0004, $0080, $0000, $0010, $0380, $000B, $0000, $0000
OBJTSTMSG0  dc.w 'X Position:     ', $0000
OBJTSTMSG1  dc.w 'Y Position:     ', $0000
OBJTSTMSG2  dc.w '   Size ', $0000, $0000, $0000, $0000, $0000
OBJTSTMSG3  dc.w '     H FLIP     ', $0000
OBJTSTMSG4  dc.w '     V FLIP     ', $0000
OBJTSTMSG5  dc.w 'Zoom Denominator', $0000
OBJTSTMSG6  dc.w ' Expected Size  ', $0000
OBJTSTMSG7  dc.w '      TEST      ', $0000
OBJTSTSIZE0 dc.w '32*32 ', $0000
OBJTSTSIZE1 dc.w '16*32 ', $0000
OBJTSTSIZE2 dc.w '32*16 ', $0000
OBJTSTSIZE3 dc.w '64*64 ', $0000
OBJTSTSIZE4 dc.w ' 8*8  ', $0000
OBJTSTSIZE5 dc.w '16*8  ', $0000
OBJTSTSIZE6 dc.w ' 8*16 ', $0000
OBJTSTSIZE7 dc.w '16*16 ', $0000
OBJTSTSIZE8 dc.w '32*64 ', $0000
OBJTSTSIZE9 dc.w '16*64 ', $0000
OBJTSTSIZEA dc.w '32*32 ', $0000
OBJTSTSIZEB dc.w '64*128', $0000
OBJTSTSIZEC dc.w ' 8*8  ', $0000
OBJTSTSIZED dc.w '16*8  ', $0000
OBJTSTSIZEE dc.w ' 8*16 ', $0000
OBJTSTSIZEF dc.w '16*16 ', $0000
OBJTSTHFLIP dc.w 'HFLIP', $0000
OBJTSTVFLIP dc.w 'VFLIP', $0000
OBJTSTNORM  dc.w '     ', $0000
OBJTSTMODE  dc.w 'EDIT', $0000



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
                move.w #0, -(sp)
                move.w d4, -(sp)
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5
                add.l #8, a4

                dbf d6, TSTRTNE_Input_PrintSWList_loop

            move.w #9, d6                                   ;repeat 10 times
            move.w #3, d4                                   ;xpos
            move.w #6, d5                                   ;ypos
            lea BTNLEFT, a4
            TSTRTNE_Input_PrintBtnList_loop:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w d4, -(sp)
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5
                add.l #8, a4

                dbf d6, TSTRTNE_Input_PrintBtnList_loop

            lea PLAYERLIST, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #5, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

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
            bsr.w funcPrintText

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
                            bsr.w funcPrintText

                        subq.w #1, d5
                        dbf d6, TSTRTNE_Input_ChkAll_btn_bt

                    move.w #12, d5                                          ;reset ypos
                    addq.w #5, d4                                           ;next xpos

                    cmp.l #$5CC06, a5
                    beq.s TSTRTNE_Input_ChkAll_btn_ldp4                     ;set P4 addr(5C400)
                    cmp.l #$5C400, a5
                    beq.s TSTRTNE_Input_ChkAll_btn_ldp4

                    add.l #2, a5                                            ;next dip switch addr
                    dbf d7, TSTRTNE_Input_ChkAll_btn

                    TSTRTNE_Input_ChkAll_btn_ldp4:
                        lea $5C400, a5
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
                            bsr.w funcPrintText

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
                        bsr.w funcPrintText

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
                        bsr.w funcPrintText

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
                    bsr.w funcPrintText

            jsr funcScrExitMessage

            TSTRTNE_Input_KeyInDelay:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelaySlow
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
            bsr.w funcDrawTilemap

            move.w #16, -(sp)
            move.w #2, -(sp)
            move.w #$F1B0, -(sp)                            ;brake
            move.w #$0006, -(sp)
            move.w #8, -(sp)
            move.w #14, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap

            move.w #16, -(sp)
            move.w #2, -(sp)
            move.w #$F190, -(sp)                            ;accel
            move.w #$0006, -(sp)
            move.w #8, -(sp)
            move.w #20, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap

            lea RF2NEEDLE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #31, -(sp)
            move.w #8, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

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
                bsr.w funcPrintText

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
                        bsr.w funcDrawTilemap

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
                        bsr.w funcDrawTilemap

                    dbf d7, TSTRTNE_RF2IO_ChkAll_accel

            TSTRTNE_RF2IO_KeyInDelay:
                bsr.w funcCheckInput                    ;check P1 button input
                move.w (sp)+, d0                         ;get latest input 
                btst.l #$4, d0                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelaySlow
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
                    bsr.w funcPrintText
                    rts

                    TSTRTNE_RF2IO_Needle_max_draw:
                        lea RF2STEERINGMAX, a0
                        move.l a0, -(sp)
                        move.w #4, -(sp)
                        move.w #21, -(sp)
                        move.w #6, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText
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
            move.w #24, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.b #1, $5E008                                       ;kick the watchdog
            move.b #0, $5E008

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

            TSTRTNE_CHARRAM_InEval:                             ;evaluate key input
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input 
                bsr.w funcCheckLongInput
                move.w (sp)+, d1                                ;get latest input
                and.w d1, d0                                    ;AND long andd short inputs
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
                bsr.w funcDrawTilemap

            TSTRTNE_CHARRAM_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_CHARRAM_InEval









        *--------------------------------------------------------
        *
        *       TESTMENU_Pr subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Pr:
            lea $880, a6
            move.w #0, $0(a6)                                   ;initialize PR digit number reg
            move.w #$00FF, $2(a6)                               ;initialize PR bit reg
                                                                ; MSB <- BBBB/BBBB -> LSB (TM-B, TM-A)
            move.w #0, $4(a6)                                   ;reset timer reg

            jsr funcClearTilemap

            lea EXITMESSAGE, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #4, -(sp)
            move.w #26, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea PRTILEMAPA, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #17, -(sp)
            move.w #6, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea PRTILEMAPB, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #6, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.w #3, d6                                       ;repeat 4 times
            move.w #16, d5                                      ;ypos
            lea PRMESSAGE0, a4
            TSTRTNE_Pr_PrntMsg_loop:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #4, -(sp)                                ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5
                add.l #26, a4

                dbf d6, TSTRTNE_Pr_PrntMsg_loop

            move.w #2, -(sp)
            move.w #2, -(sp)
            move.w #$F1D0, -(sp)                                ;vertical tile
            move.w #$000C, -(sp)                                ;red/green
            move.w #15, -(sp)
            move.w #10, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap

            move.w #2, -(sp)
            move.w #2, -(sp)
            move.w #$F1D4, -(sp)                                ;horizontal tile
            move.w #$000E, -(sp)                                ;cyan/magenta
            move.w #15, -(sp)
            move.w #10, -(sp)
            move.w #1, -(sp)
            bsr.w funcDrawTilemap
            
            ;SPRITE 1 
            move.w #7, -(sp)
            move.w #$0080, -(sp)
            move.w #120, -(sp)
            move.w #80, -(sp)
            move.w #$00EC, -(sp)
            move.w #5, -(sp)
            move.w #0, -(sp)
            move.w #$EF, -(sp)
            bsr.w funcDrawSprite


            TSTRTNE_Pr_InEval:                                  ;evaluate key input
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input 

                btst.l #$4, d0                                  ;check for power-up(gradius) or fire(twinbee)
                beq.s TSTRTNE_Pr_Apply

                btst.l #$1, d0                                  ;check for RIGHT
                beq.s TSTRTNE_Pr_bitnumdec
                btst.l #$0, d0                                  ;check for LEFT
                beq.s TSTRTNE_Pr_bitnuminc

                cmpi.w #8, $0(a6)                               ;test 8
                beq.w TSTRTNE_Pr_Autoinc                        ;PR bits auto increase

                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_Pr_bitvalzero
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_Pr_bitvalone

                bra.w TSTRTNE_Pr_PrntVal                        ;nothing changes

            TSTRTNE_Pr_bitvalzero:
                move.w $0(a6), d0                               ;get digit
                move.w $2(a6), d1                               ;get PR bits    
                bclr.l d0, d1                                   ;clear bit
                move.w d1, $2(a6)                               ;writeback
                bra.w TSTRTNE_Pr_PrntVal

            TSTRTNE_Pr_bitvalone:
                move.w $0(a6), d0                               ;get digit
                move.w $2(a6), d1                               ;get PR bits   
                bset.l d0, d1                                   ;set bit
                move.w d1, $2(a6)                               ;writeback
                bra.w TSTRTNE_Pr_PrntVal

            TSTRTNE_Pr_bitnumdec:
                cmpi.w #0, $0(a6)                               ;test 0
                bne.s TSTRTNE_Pr_bitnumdec_sub
                
                TSTRTNE_Pr_bitnumdec_hold:                      ;hold
                bra.w TSTRTNE_Pr_PrntVal

                TSTRTNE_Pr_bitnumdec_sub:
                subq.w #1, $0(a6)                               ;bitnum - 1
                bra.s TSTRTNE_Pr_bitnumdec_hold                 ;goto hold

            TSTRTNE_Pr_bitnuminc:
                cmpi.w #8, $0(a6)                               ;test 8
                bne.s TSTRTNE_Pr_bitnuminc_add
                
                TSTRTNE_Pr_bitnuminc_hold:                      ;hold
                bra.w TSTRTNE_Pr_PrntVal

                TSTRTNE_Pr_bitnuminc_add:
                addq.w #1, $0(a6)                               ;bitnum - 1
                bra.s TSTRTNE_Pr_bitnuminc_hold                 ;goto hold

            TSTRTNE_Pr_Apply:                                   ;apply change on tilemaps
                move.w $2(a6), d0                               ;copy PR bits data
                andi.w #$000F, d0                               ;get TM-A data(0x000F)
                lsl.w #8, d0                                    ;shift left 8 bits
                lsl.w #4, d0                                    ;shift left 4 bits
                move.w #$1D0, d1                                ;load 0x1D0(TM-A test pattern)
                or.w d0, d1                                     ;merge d0 and d1

                move.w #2, -(sp)
                move.w #2, -(sp)
                move.w d1, -(sp)                                ;empty tile
                move.w #$000C, -(sp)                            ;red/green
                move.w #15, -(sp)
                move.w #10, -(sp)
                move.w #0, -(sp)
                bsr.w funcDrawTilemap

                move.w $2(a6), d0                               ;copy PR bits data
                andi.w #$00F0, d0                               ;get TM-B data(0x00F0)
                lsl.w #8, d0                                    ;shift left 8 bits
                move.w #$1D4, d1                                ;load 0x1D4(TM-B test pattern)
                or.w d0, d1                                     ;merge d0 and d1

                move.w #2, -(sp)
                move.w #2, -(sp)
                move.w d1, -(sp)                                ;empty tile
                move.w #$000E, -(sp)                            ;cyan/magenta
                move.w #15, -(sp)
                move.w #10, -(sp)
                move.w #1, -(sp)
                bsr.w funcDrawTilemap

                bra.s TSTRTNE_Pr_PrntVal

            
            TSTRTNE_Pr_Autoinc:
                cmpi.w #7, $4(a6)                               ;check 7
                beq.w TSTRTNE_Pr_Autoinc_princ

                ;TSTRTNE_Pr_Autoinc_cntrinc:
                    addq.w #1, $4(a6)                           ;increase counter
                    bra.s TSTRTNE_Pr_Apply

                TSTRTNE_Pr_Autoinc_princ:
                    move.w #0, $4(a6)

                    cmpi.w #$FF, $2(a6)                         ;check PR FF
                    beq.w TSTRTNE_Pr_Autoinc_princ_loop
                    addq.w #$01, $2(a6)
                    bra.w TSTRTNE_Pr_Apply

                    TSTRTNE_Pr_Autoinc_princ_loop:
                        move.w #$00, $2(a6)                     ;reset PR
                        bra.w TSTRTNE_Pr_Apply


            TSTRTNE_Pr_PrntVal:
                move.w #7, d5                                   ;repeat 8 times
                move.w #11, d4                                  ;set xpos
                TSTRTNE_Pr_PrntVal_prntloop:
                    move.w $0(a6), d1                           ;get digit number
                    cmp.w d5, d1                                ;check that the value of the loop counter is equal to the currently selected bit
                    beq.s TSTRTNE_Pr_PrntVal_prntloop_redtxt    ;if same, use red

                    move.w #1, d0                               ;if not, use light blue
                    bra.s TSTRTNE_Pr_PrntVal_prntloop_chkbt

                    TSTRTNE_Pr_PrntVal_prntloop_redtxt:
                        move.w #4, d0

                    TSTRTNE_Pr_PrntVal_prntloop_chkbt:
                        move.w $2(a6), d1                       ;get PR bits
                        btst.l d5, d1                           ;check bit value
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
                            bsr.w funcPrintText

                        cmpi.w #4, d5                               ;if loop counter is 4
                        bne.s TSTRTNE_Pr_PrntVal_prntloop_incpos
                        addq.w #3, d4                               ;add 3 to xpos
                        dbf d5, TSTRTNE_Pr_PrntVal_prntloop         ;loop

                        TSTRTNE_Pr_PrntVal_prntloop_incpos:
                        addq.w #1, d4                               ;add 1 to xpos
                        dbf d5, TSTRTNE_Pr_PrntVal_prntloop         ;loop

                jsr funcScrExitMessage

                cmpi.w #8, $0(a6)                               ;digitnum 8
                bne.s TSTRTNE_PR_PrntVal_delautoinc

                cmpi.w #3, $4(a6)                               ;timer 3
                beq.s TSTRTNE_PR_PrntVal_prntautoinc

                cmpi.w #7, $4(a6)                               ;timer 7
                beq.s TSTRTNE_PR_PrntVal_delautoinc

                bra.s TSTRTNE_Pr_KeyInDelay

                TSTRTNE_PR_PrntVal_delautoinc:
                    lea PRAUTOINC, a0
                    move.l a0, -(sp)
                    move.w #6, -(sp)
                    move.w #9, -(sp)
                    move.w #4, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.s TSTRTNE_Pr_KeyInDelay

                TSTRTNE_PR_PrntVal_prntautoinc:
                    lea PRAUTOINC, a0
                    move.l a0, -(sp)
                    move.w #4, -(sp)
                    move.w #9, -(sp)
                    move.w #4, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText


            TSTRTNE_Pr_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_Pr_InEval


PRTILEMAPA      dc.w 'TM-A', $0000
PRTILEMAPB      dc.w 'TM-B', $0000
PRBITZERO       dc.w '0', $0000
PRBITONE        dc.w '1', $0000
PRMESSAGE0      dc.w 'Red+Green Hblock    TM-A', $0000
PRMESSAGE1      dc.w 'Cyan+Magenta Vblock TM-B', $0000
PRMESSAGE2      dc.w 'Grey+Black Vblock   OBJ ', $0000
PRMESSAGE3      dc.w 'Press A to apply changes', $0000
PRAUTOINC       dc.w 'Auto increment', $0000



        *--------------------------------------------------------
        *
        *       TSTRTNE_SysIO
        *
        *--------------------------------------------------------

        TSTRTNE_SysIO:
            lea $880, a6
            lea $5E000, a5
            move.w #0, (a6)                                         ;initialize menu num reg
            move.w #$FF00, $2(a6)                                   ;initialize FF/IRQ response reg
            move.w #0, $4(a6)                                       ;initialize misc outlatch reg

            jsr funcClearTilemap

            lea SYSIOMESSAGE0, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #8, -(sp)
            move.w #26, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea INTERRUPTS0, a0
            move.w #1, d0                                           ;repeat 2 times
            move.w #4, d1                                           ;ypos 4
            TSTRTNE_SysIO_initirq:
                move.w d0, d2                                       ;get loop counter
                bchg.l #0, d2                                       ;l.c.1 -> palette 0, l.c.0 -> palette 1

                move.l a0, -(sp)
                move.w d2, -(sp)
                move.w #5, -(sp)
                move.w d1, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d1                                       ;ypos+1
                add.l #24, a0

                dbf d0, TSTRTNE_SysIO_initirq

            lea INTERRUPTS3, a1
            move.w #6, d0                               ;first ?? start xpos
            move.w #3, d1
            TSTRTNE_SysIO_initmollu:
                move.l a1, -(sp)
                move.w #5, -(sp)
                move.w d0, -(sp)
                move.w #6, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #6, d0                           ;OK xpos + 6
                dbf d1, TSTRTNE_SysIO_initmollu

            lea COINCOUNTER0, a0
            move.w #1, d0                                           ;repeat 2 times
            move.w #9, d1                                           ;ypos 9
            TSTRTNE_SysIO_initcoin:
                move.w d0, d2                                       ;get loop counter
                bchg.l #0, d2                                       ;l.c.1 -> palette 0, l.c.0 -> palette 1

                move.l a0, -(sp)
                move.w d2, -(sp)
                move.w #5, -(sp)
                move.w d1, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d1                                       ;ypos+1
                add.l #24, a0

                dbf d0, TSTRTNE_SysIO_initcoin

            lea SYSTEMIO0, a0
            move.w #1, d0                                           ;repeat 2 times
            move.w #7, d2                                           ;xpos 7
            TSTRTNE_SysIO_initmisc_loop_out:
                move.w #1, d1                                       ;repeat 2 times
                move.w #14, d3                                      ;ypos 14
                TSTRTNE_SysIO_initmisc_loop_in:
                    move.l a0, -(sp)
                    move.w #0, -(sp)
                    move.w d2, -(sp)
                    move.w d3, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    addq.w #3, d3                                   ;ypos+3
                    add.l #8, a0

                    dbf d1, TSTRTNE_SysIO_initmisc_loop_in
                
                addi.w #12, d2                                      ;xpos+12

                dbf d0, TSTRTNE_SysIO_initmisc_loop_out

            lea $52000, a0
            move.w #$E010, $592(a0)                                 ;ASCII 0
            move.w #$0005, $2592(a0)                                ;green
            move.w #$E010, $5AA(a0)                                 ;ASCII 0
            move.w #$0005, $25AA(a0)                                ;green

            TSTRTNE_SysIO_ModeEval:
                move.w (a6), d0                                     ;get menu number
                
                cmpi.w #0, d0
                beq.w TSTRTNE_SysIO_IRQ
                cmpi.w #1, d0
                beq.w TSTRTNE_SysIO_Coin
                cmpi.w #2, d0
                beq.w TSTRTNE_SysIO_HFlip
                cmpi.w #3, d0
                beq.w TSTRTNE_SysIO_VFlip
                cmpi.w #4, d0
                beq.w TSTRTNE_SysIO_288
                cmpi.w #5, d0
                beq.w TSTRTNE_SysIO_480i
                bra.w TSTRTNE_SysIO_Draw

            TSTRTNE_SysIO_IRQ:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_IRQ_test
                btst.l #$3, d0                                  ;check for DOWN
                beq.w TSTRTNE_SysIO_IRQ_inc
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_IRQ_test:
                    lea $40000, a0
                    move.w #$FF00, $2(a6)

                    lea INTERRUPTS3, a1
                    move.w #6, d0                               ;first ?? xpos
                    move.w #3, d1
                    TSTRTNE_SysIO_IRQ_test_prntmollu:
                        move.l a1, -(sp)
                        move.w #5, -(sp)
                        move.w d0, -(sp)
                        move.w #6, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                        addq.w #6, d0                           ;OK xpos + 6
                        dbf d1, TSTRTNE_SysIO_IRQ_test_prntmollu

                    lea INTERRUPTS2, a1
                    move.w #6, d1                               ;first OK start xpos

                    bsr.w funcFixedDelaySlow

                    move.w #0, d0                               ;reset timeout register
                    andi.w #$FCFF, SR                           ;IRQ MASK 100, accepts IRQ LEVEL >4, BMC = LV5
                    move.w #$1, $0(a0)                          ;load page 0x001
                    move.w #$1, $2(a0)                          ;READ
                    TSTRTNE_SysIO_IRQ_test_eval5:
                        addq.w #1, d0
                        bsr.w funcFixedDelaySlow
                        cmpi.w #$8, d0                          ;timeout check
                        bgt.s TSTRTNE_SysIO_IRQ_test_eval5_tmout
                        btst.b #5, $3(a6)                       ;loop
                        beq.s TSTRTNE_SysIO_IRQ_test_eval5

                        bsr.w TSTRTNE_SysIO_IRQ_test_prntok

                    TSTRTNE_SysIO_IRQ_test_eval5_tmout:
                        ori.w #$0700, SR                        ;IRQ MASK 111
                        addq.w #6, d1                           ;OK xpos + 6

                    move.w #0, d0                               ;reset timeout register
                    andi.w #$FBFF, SR                           ;IRQ MASK 011, accepts LEVEL >3, counter = LV4
                    move.b #1, $E(a5)                           ;enable 72 scanline counter IRQ
                    TSTRTNE_SysIO_IRQ_test_eval4:
                        addq.w #1, d0
                        bsr.w funcFixedDelaySlow
                        cmpi.w #$8, d0                          ;timeout check
                        bgt.s TSTRTNE_SysIO_IRQ_test_eval4_tmout
                        btst.b #4, $3(a6)
                        beq.s TSTRTNE_SysIO_IRQ_test_eval4

                        bsr.w TSTRTNE_SysIO_IRQ_test_prntok

                    TSTRTNE_SysIO_IRQ_test_eval4_tmout:
                        move.b #1, $E(a5)
                        move.b #0, $E(a5)
                        ori.w #$0700, SR                        ;IRQ MASK 111
                        addq.w #6, d1                           ;OK xpos + 6
                        

                    move.w #0, d0                               ;reset timeout register
                    andi.w #$F9FF, SR                           ;IRQ MASK 001, accepts LEVEL >1, VBLANK = LV2
                    move.b #1, $1(a5)                           ;enable VBLANK IRQ
                    TSTRTNE_SysIO_IRQ_test_eval2:
                        addq.w #1, d0
                        bsr.w funcFixedDelaySlow
                        cmpi.w #8, d0                           ;timeout check
                        bgt.s TSTRTNE_SysIO_IRQ_test_eval2_tmout
                        btst.b #2, $3(a6)
                        beq.s TSTRTNE_SysIO_IRQ_test_eval2

                        bsr.w TSTRTNE_SysIO_IRQ_test_prntok

                    TSTRTNE_SysIO_IRQ_test_eval2_tmout:
                        move.b #0, $1(a5)                           ;disable IRQ
                        ori.w #$0700, SR                            ;IRQ MASK 111
                        addq.w #6, d1                           ;OK xpos + 6

                    move.w #0, d0                               ;reset timeout register
                    andi.w #$F8FF, SR                           ;IRQ MASK 000, accepts LEVEL >0, 256V = LV1
                    move.b #1, $3(a5)                           ;enable 256V IRQ
                    TSTRTNE_SysIO_IRQ_test_eval1:
                        addq.w #1, d0
                        bsr.w funcFixedDelaySlow
                        cmpi.w #8, d0                              ;timeout check
                        bgt.s TSTRTNE_SysIO_IRQ_test_eval1_tmout
                        btst.b #1, $3(a6)
                        beq.s TSTRTNE_SysIO_IRQ_test_eval1

                        bsr.w TSTRTNE_SysIO_IRQ_test_prntok
                        
                    TSTRTNE_SysIO_IRQ_test_eval1_tmout:
                        move.b #0, $3(a5)                           ;disable 256V IRQ
                        ori.w #$0700, SR                            ;IRQ MASK 111
                        
                    lea $600, a7

                    bra.w TSTRTNE_SysIO_Draw

                    TSTRTNE_SysIO_IRQ_test_prntok:
                        move.l a1, -(sp)
                        move.w #3, -(sp)
                        move.w d1, -(sp)
                        move.w #6, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText
                        rts


                TSTRTNE_SysIO_IRQ_inc:
                    addq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

            TSTRTNE_SysIO_COIN:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_COIN_test
                btst.l #$3, d0                                  ;check for DOWN
                beq.w TSTRTNE_SysIO_COIN_inc
                btst.l #$2, d0                                  ;check for UP
                beq.w TSTRTNE_SysIO_COIN_dec
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_Coin_test:
                    lea $52000, a0

                    ;0x52592
                    move.w #$E010, $592(a0)
                    move.w #$0003, $2592(a0)                    ;green
                    move.w #4, d0
                    TSTRTNE_SysIO_Coin_test_coin1:
                        move.w #3, d1
                        TSTRTNE_SysIO_Coin_test_coin1_delay:
                            bsr.w funcFixedDelaySlow
                            dbf d1, TSTRTNE_SysIO_Coin_test_coin1_delay

                        move.b #1, (a5)
                        bsr.w funcFixedDelaySlow
                        bsr.w funcFixedDelaySlow
                        move.b #0, (a5)
                        addq.w #1, $592(a0)                     ;increase pulse number

                        dbf d0, TSTRTNE_SysIO_Coin_test_coin1
                    move.w #$0005, $2592(a0)                    ;yellow

                    ;0x525AA
                    move.w #$E010, $5AA(a0)
                    move.w #$0003, $25AA(a0)                    ;green
                    move.w #4, d0
                    TSTRTNE_SysIO_Coin_test_coin2:
                        move.w #3, d1
                        TSTRTNE_SysIO_Coin_test_coin2_delay:
                            bsr.w funcFixedDelaySlow
                            dbf d1, TSTRTNE_SysIO_Coin_test_coin2_delay

                        move.b #1, $2(a5)
                        bsr.w funcFixedDelaySlow
                        bsr.w funcFixedDelaySlow
                        move.b #0, $2(a5)
                        addq.w #1, $5AA(a0)

                        dbf d0, TSTRTNE_SysIO_Coin_test_coin2
                    move.w #$0005, $25AA(a0)                    ;yellow

                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_Coin_inc:
                    addq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_Coin_dec:
                    subq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw


            TSTRTNE_SysIO_HFlip:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_HFlip_test
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_SysIO_HFlip_inc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_SysIO_HFlip_dec
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_HFlip_test:
                    eori.w #0008, $4(a6)                        ;flip bit3
                    move.w $4(a6), d0
                    lsr.w #3, d0
                    andi.w #$0001, d0
                    move.b d0, $5(a5)                           ;write flip bit

                    lea $50200, a0
                    move.w #$00, d1
                    move.w #$1FF, d2
                    tst.w d0
                    beq.s TSTRTNE_SysIO_HFlip_test_chgscrl
                    move.w #$01, d1
                    TSTRTNE_SysIO_HFlip_test_chgscrl:
                        move.w d1, (a0)+                                ;set scroll value
                        dbf d2, TSTRTNE_SysIO_HFlip_test_chgscrl

                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_HFlip_inc:
                    addq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_HFlip_dec:
                    subq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw


            TSTRTNE_SysIO_VFlip:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_VFlip_test
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_SysIO_VFlip_inc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_SysIO_VFlip_dec
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_VFlip_test:
                    eori.w #0004, $4(a6)                        ;flip bit2
                    move.w $4(a6), d0
                    lsr.w #2, d0
                    andi.w #$0001, d0
                    move.b d0, $7(a5)                           ;write flip bit

                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_VFlip_inc:
                    addq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_VFlip_dec:
                    subq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

            TSTRTNE_SysIO_288:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_288_test
                btst.l #$3, d0                                  ;check for DOWN
                beq.s TSTRTNE_SysIO_288_inc
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_SysIO_288_dec
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_288_test:
                    eori.w #0002, $4(a6)                        ;flip bit1
                    move.w $4(a6), d0
                    lsr.w #1, d0
                    andi.w #$0001, d0
                    move.b d0, $9(a5)                           ;write scanline bit

                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_288_inc:
                    addq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_288_dec:
                    subq.w #1, (a6)
                    bra.w TSTRTNE_SysIO_Draw

            TSTRTNE_SysIO_480i:
                bsr.w funcCheckInput                            ;check P1 button input
                move.w (sp)+, d0                                ;get latest input

                btst.l #$5, d0                                  ;button B
                beq.w TSTRTNE_SysIO_Exit
                btst.l #$4, d0                                  ;check for A
                beq.s TSTRTNE_SysIO_480i_test
                btst.l #$2, d0                                  ;check for UP
                beq.s TSTRTNE_SysIO_480i_dec
                bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_480i_test:
                    eori.w #0001, $4(a6)                        ;flip bit0
                    move.w $4(a6), d0
                    andi.w #$0001, d0
                    move.b d0, $B(a5)                           ;write 480i mode bit

                    bra.w TSTRTNE_SysIO_Draw

                TSTRTNE_SysIO_480i_dec:
                    subq.w #1, (a6)
                    ;bra.w TSTRTNE_SysIO_Draw

            TSTRTNE_SysIO_Draw:
                move.w #4, d0                                   ;red
                cmpi.w #0, (a6)
                beq.s TSTRTNE_SysIO_Draw_irq
                move.w #0, d0                                   ;navy
                TSTRTNE_SysIO_Draw_irq:
                    lea INTERRUPTS0, a0
                    move.l a0, -(sp)
                    move.w d0, -(sp)
                    move.w #5, -(sp)
                    move.w #4, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                move.w #4, d0                                   ;red
                cmpi.w #1, (a6)
                beq.s TSTRTNE_SysIO_Draw_coin
                move.w #0, d0                                   ;navy
                TSTRTNE_SysIO_Draw_coin:
                    lea COINCOUNTER0, a0
                    move.l a0, -(sp)
                    move.w d0, -(sp)
                    move.w #5, -(sp)
                    move.w #9, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                TSTRTNE_SysIO_Draw_misc:
                    lea SYSTEMIO0, a0
                    move.w #1, d7                                           ;repeat 2 times
                    move.w #7, d6                                           ;xpos 7
                    TSTRTNE_SysIO_Draw_misc_loop_out:
                        move.w #1, d5                                       ;repeat 2 times
                        move.w #14, d4                                      ;ypos 14
                        TSTRTNE_SysIO_Draw_misc_loop_in:
                            move.w #0, d2                                   ;palette 0(dark blue)

                            move.w d7, d1                                   ;get outer loop counter
                            lsl.w #1, d1                                    ;outer loop counter*2
                            add.w d5, d1                                    ;outer loop counter*2 + inner loop counter

                            ;TSTRTNE_SysIO_Draw_misc_loop_in_green:
                            move.w $4(a6), d0                               ;get misc bits
                            btst.l d1, d0                                   ;evaluate bit 0
                            beq.s TSTRTNE_SysIO_Draw_misc_loop_in_red
                            move.w #3, d2                                   ;palette 3(green)

                            TSTRTNE_SysIO_Draw_misc_loop_in_red:
                                move.w #5, d0
                                sub.w d1, d0                                ;5 - (outer loop counter*2 + inner loop counter)

                                move.w $0(a6), d1                           ;get menu number
                                cmp.w d0, d1                                ;if value == 1-loop counter
                                bne.s TSTRTNE_SysIO_Draw_misc_prnt
                                move.w #4, d2                               ;palette 4(red)

                            TSTRTNE_SysIO_Draw_misc_prnt: 
                                move.l a0, -(sp)
                                move.w d2, -(sp)
                                move.w d6, -(sp)
                                move.w d4, -(sp)
                                move.w #0, -(sp)
                                bsr.w funcPrintText

                            addq.w #3, d4                                   ;ypos+3
                            add.l #8, a0

                            dbf d5, TSTRTNE_SysIO_Draw_misc_loop_in
                        
                        addi.w #12, d6                                      ;xpos+12

                        dbf d7, TSTRTNE_SysIO_Draw_misc_loop_out


            TSTRTNE_SysIO_KeyInDelay:
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_SysIO_ModeEval

            TSTRTNE_SysIO_Exit:
                move.b #0, $5(a5)                       ;HFLIP
                move.b #0, $7(a5)                       ;VFLIP
                move.b #0, $9(a5)                       ;288LN
                move.b #0, $B(a5)                       ;480i

                bra.w TESTMENU

            TSTRTNE_SysIO_EXCEPTION_BMCDONE:
                nop
                nop
                nop
                nop
                bset.b #5, $883
                nop
                nop
                rte

            TSTRTNE_SysIO_EXCEPTION_COUNTER:
                nop
                nop
                bset.b #4, $883
                move.b #1, $5E00E
                move.b #0, $5E00E
                nop
                nop
                rte

            TSTRTNE_SysIO_EXCEPTION_VBLANK:
                bset.b #2, $883
                rte
                
            TSTRTNE_SysIO_EXCEPTION_PARITY:
                bset.b #1, $883
                rte

INTERRUPTS0     dc.w '      INTERRUPTS      ', $0000
INTERRUPTS1     dc.w 'LV.5  LV.4  LV.2  LV.1', $0000
INTERRUPTS2     dc.w 'OK', $0000
INTERRUPTS3     dc.w '??', $0000

COINCOUNTER0    dc.w '    COIN COUNTERS     ', $0000
COINCOUNTER1    dc.w '  COIN1       COIN2   ', $0000

SYSTEMIO0       dc.w 'HFLIP', $0000
SYSTEMIO1       dc.w 'VFLIP', $0000
SYSTEMIO2       dc.w '288LN', $0000
SYSTEMIO3       dc.w '480i', $0000

SYSIOMESSAGE0   dc.w 'Press B to exit', $0000






        *--------------------------------------------------------
        *
        *       TESTMENU_BMC subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_BMC:
            jsr funcClearTilemap

            lea NOWLOADING, a0                  ;print nowloading
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #9, -(sp)
            move.w #15, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.l #$3C400, -(sp)                                   ;copy tiles(2C400 on ROM)
            move.w #16, -(sp)
            move.w #1416, -(sp)
            move.w #1, -(sp)
            jsr funcLoadBubble

            move.w #32, -(sp)
            move.w #1, -(sp)
            move.w #$F620, -(sp)                                    ;ram viewer index
            move.w #$0006, -(sp)
            move.w #0, -(sp)
            move.w #13, -(sp)
            move.w #1, -(sp)
            bsr.w funcDrawTilemap

            move.w #15, d5                                          ;repeat 16 times
            TSTRTNE_BMC_RamViewer_bgloop:
                move.w d5, d0
                addi.w #14, d0

                move.w #32, -(sp)
                move.w #1, -(sp)
                move.w #$E640, -(sp)                                ;ram viewer stripe
                move.w #$0006, -(sp)
                move.w #0, -(sp)
                move.w d0, -(sp)
                move.w #1, -(sp)
                bsr.w funcDrawTilemap

                dbf d5, TSTRTNE_BMC_RamViewer_bgloop

            lea BMCMESSAGE0, a4
            move.w #1, d6                                           ;repeat 2 times
            move.w #3, d5                                           ;ypos 3
            TSTRTNE_BMC_PrntAddrData_loop:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #4, -(sp)                                    ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5                                       ;ypos+1
                add.l #16, a4

                dbf d6, TSTRTNE_BMC_PrntAddrData_loop

            lea RAMAREA, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #6, -(sp)
            move.w #12, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea HEXDATAPREFIX, a4
            move.l a4, -(sp)
            move.w #1, -(sp)
            move.w #18, -(sp)                                       ;xpos fixed
            move.w #3, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.l a4, -(sp)
            move.w #1, -(sp)
            move.w #22, -(sp)                                       ;xpos fixed
            move.w #4, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            move.l a4, -(sp)
            move.w #1, -(sp)
            move.w #15, -(sp)                                       ;xpos fixed
            move.w #12, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText

            lea BMCMESSAGE2, a4
            move.w #1, d7                                           ;repeat 2 times
            move.w #8, d6                                           ;xpos 8
            TSTRTNE_BMC_PrntOptn_loop_out:
                move.w #1, d5                                       ;repeat 2 times
                move.w #6, d4                                       ;ypos 6
                TSTRTNE_BMC_PrntOptn_loop_in:
                    move.l a4, -(sp)
                    move.w #0, -(sp)
                    move.w d6, -(sp)
                    move.w d4, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    addq.w #1, d4                                   ;ypos+1
                    add.l #8, a4

                    dbf d5, TSTRTNE_BMC_PrntOptn_loop_in
                
                addi.w #10, d6                                      ;xpos+16

                dbf d7, TSTRTNE_BMC_PrntOptn_loop_out

            lea RWSTATUS, a0
            move.l a0, -(sp)
            move.w #0, -(sp)
            move.w #11, -(sp)
            move.w #9, -(sp)
            move.w #0, -(sp)
            bsr.w funcPrintText


            lea $880, a6
            move.w #$0000, $0(a6)                                   ;initialize menu number
            move.l #$00040000, $2(a6)                               ;initialize address data
            move.w #8, $6(a6)                                       ;initialize address digit
            move.w #$0000, $8(a6)                                   ;initialize data
            move.w #4, $A(a6)                                       ;initialize data digit
            move.b #0, $D(a6)                                       ;initialize UNDER MODIFICATION flag
            move.l #$00000F00, $10(a6)                              ;initialize RAM area address data
            move.w #8, $14(a6)                                      ;initialize RAM area address digit

            TSTRTNE_BMC_InEval:                                     ;evaluate key input
                bsr.w funcCheckInput                                ;check P1 button input
                move.w (sp)+, d0                                    ;get latest input 
                btst.l #$3, d0                                      ;check for DOWN
                beq.w TSTRTNE_BMC_down
                btst.l #$2, d0                                      ;check for UP
                beq.w TSTRTNE_BMC_up
                btst.l #$1, d0                                      ;check for RIGHT
                beq.w TSTRTNE_BMC_right
                btst.l #$0, d0                                      ;check for LEFT
                beq.w TSTRTNE_BMC_left
                btst.l #$4, d0                                      ;check for power-up(gradius) or fire(twinbee)
                beq.w TSTRTNE_BMC_Execute
                btst.l #$5, d0                                      ;button B
                beq.w TSTRTNE_BMC_Read
                btst.l #$6, d0                                      ;button C
                beq.w TSTRTNE_BMC_Write

                bra.w TSTRTNE_BMC_Draw                          ;nothing changes


            ;
            ;   UP INPUT 
            ;
            TSTRTNE_BMC_up:
                btst.b #$0, $D(a6)                                  ;check the flag
                bne.w TSTRTNE_BMC_up_edit                           ;if 1, goto edit mode

                move.w $0(a6), d0                                   ;get menu number

                cmpi.w #0, d0                                       ;if 1-6
                bne.w TSTRTNE_BMC_up_menudec                        ;decrease number

                bra.w TSTRTNE_BMC_Draw                          ;if not, do not decrease

                TSTRTNE_BMC_up_menudec:
                    subq.w #1, d0
                    move.w d0, $0(a6)
                    bra.w TSTRTNE_BMC_Draw


                TSTRTNE_BMC_up_edit:
                    move.w $0(a6), d0                               ;get menu number

                    cmpi.w #0, d0                                   ;if 0
                    beq.w TSTRTNE_BMC_up_edit_addrinc               ;edit address

                    cmpi.w #1, d0                                   ;if 1
                    beq.w TSTRTNE_BMC_up_edit_datainc               ;edit data

                    cmpi.w #6, d0                                   ;if 6
                    beq.w TSTRTNE_BMC_up_edit_ramviewinc            ;edit ram viewer address

                    bra.w TSTRTNE_BMC_Draw                      ;does not happens

                    TSTRTNE_BMC_up_edit_addrinc:
                        move.w $6(a6), d0                           ;get address digit
                        lsl.w #2, d0                                ;address digit*4
                        move.l $2(a6), d1                           ;get address data(long word)
                        move.l d1, d2

                        lsr.l d0, d2                                ;shift right D2
                        addq.l #1, d2                               ;D2 + 1 (ignore under/overflow)
                        
                        move.l #$0000000F, d3                       ;load 0x0000000F
                        and.l d3, d2                                ;get D2[3:0]
                        lsl.l d0, d2                                ;shift left D2
                        lsl.l d0, d3                                ;shift left D3
                        not.l d3                                    ;invert D3 e.g. 0xFF0FFFFF
                        and.l d3, d1                                ;insert 0x0 on corresponding digit
                        or.l d2, d1                                 ;insert modified digit number(D2)

                        move.l d1, $2(a6)                           ;write modified address
                        
                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_up_edit_datainc:
                        move.w $A(a6), d0                           ;get data digit
                        lsl.w #2, d0                                ;data digit*4
                        move.w $8(a6), d1                           ;get data(word)
                        move.w d1, d2

                        lsr.w d0, d2                                ;shift right D2
                        addq.w #1, d2                               ;D2 + 1 (ignore under/overflow)
                        
                        move.w #$000F, d3                           ;load 0x000F
                        and.w d3, d2                                ;get D2[3:0]
                        lsl.w d0, d2                                ;shift left D2
                        lsl.w d0, d3                                ;shift left D3
                        not.w d3                                    ;invert D3 e.g. 0xF0FF
                        and.w d3, d1                                ;insert 0x0 on corresponding digit
                        or.w d2, d1                                 ;insert modified digit number(D2)

                        move.w d1, $8(a6)                           ;write modified data
                        
                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_up_edit_ramviewinc:
                        move.w $14(a6), d0                          ;get ram viewer address digit
                        lsl.w #2, d0                                ;ram viewer address digit*4
                        move.l $10(a6), d1                          ;get ram viewer address data(long word)
                        move.l d1, d2

                        lsr.l d0, d2                                ;shift right D2
                        addq.l #1, d2                               ;D2 + 1 (ignore under/overflow)
                        
                        move.l #$0000000F, d3                       ;load 0x0000000F
                        and.l d3, d2                                ;get D2[3:0]
                        lsl.l d0, d2                                ;shift left D2
                        lsl.l d0, d3                                ;shift left D3
                        not.l d3                                    ;invert D3 e.g. 0xFF0FFFFF
                        and.l d3, d1                                ;insert 0x0 on corresponding digit
                        or.l d2, d1                                 ;insert modified digit number(D2)

                        move.l d1, $10(a6)                          ;write modified ram viewer address
                        
                        bra.w TSTRTNE_BMC_Draw
                    

            ;
            ;   DOWN INPUT
            ;
            TSTRTNE_BMC_down:
                btst.b #$0, $D(a6)                                  ;check the flag
                bne.w TSTRTNE_BMC_down_edit                         ;if 1, goto edit mode

                move.w $0(a6), d0                                   ;check menu number

                cmpi.w #6, d0                                       ;if 0-5
                bne.w TSTRTNE_BMC_down_menuinc                      ;increase number

                bra.w TSTRTNE_BMC_Draw                          ;if not, do not increase

                TSTRTNE_BMC_down_menuinc:
                    addq.w #1, d0
                    move.w d0, $0(a6)
                    bra.w TSTRTNE_BMC_Draw


                TSTRTNE_BMC_down_edit:
                    move.w $0(a6), d0                               ;get menu number

                    cmpi.w #0, d0                                   ;if 0
                    beq.w TSTRTNE_BMC_down_edit_addrdec             ;edit address

                    cmpi.w #1, d0                                   ;if 1
                    beq.w TSTRTNE_BMC_down_edit_datadec             ;edit data

                    cmpi.w #6, d0                                   ;if 6
                    beq.w TSTRTNE_BMC_down_edit_ramviewdec          ;edit ram viewer address

                    bra.w TSTRTNE_BMC_Draw                      ;does not happens


                    TSTRTNE_BMC_down_edit_addrdec:
                        move.w $6(a6), d0                           ;get address digit
                        lsl.w #2, d0                                ;address digit*4
                        move.l $2(a6), d1                           ;get address data(long word)
                        move.l d1, d2

                        lsr.l d0, d2                                ;shift right D2
                        subq.l #1, d2                               ;D2 - 1 (ignore under/overflow)
                        
                        move.l #$0000000F, d3                       ;load 0x0000000F
                        and.l d3, d2                                ;get D2[3:0]
                        lsl.l d0, d2                                ;shift left D2
                        lsl.l d0, d3                                ;shift left D3
                        not.l d3                                    ;invert D3 e.g. 0xFF0FFFFF
                        and.l d3, d1                                ;insert 0x0 on corresponding digit
                        or.l d2, d1                                 ;insert modified digit number(D2)

                        move.l d1, $2(a6)                           ;write modified address
                        
                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_down_edit_datadec:
                        move.w $A(a6), d0                           ;get data digit
                        lsl.w #2, d0                                ;data digit*4
                        move.w $8(a6), d1                           ;get data(word)
                        move.w d1, d2

                        lsr.w d0, d2                                ;shift right D2
                        subq.w #1, d2                               ;D2 - 1 (ignore under/overflow)
                        
                        move.w #$000F, d3                           ;load 0x000F
                        and.w d3, d2                                ;get D2[3:0]
                        lsl.w d0, d2                                ;shift left D2
                        lsl.w d0, d3                                ;shift left D3
                        not.w d3                                    ;invert D3 e.g. 0xF0FF
                        and.w d3, d1                                ;insert 0x0 on corresponding digit
                        or.w d2, d1                                 ;insert modified digit number(D2)

                        move.w d1, $8(a6)                           ;write modified data
                        
                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_down_edit_ramviewdec:
                        move.w $14(a6), d0                          ;get aram viewer ddress digit
                        lsl.w #2, d0                                ;ram viewer address digit*4
                        move.l $10(a6), d1                          ;get ram viewer address data(long word)
                        move.l d1, d2

                        lsr.l d0, d2                                ;shift right D2
                        subq.l #1, d2                               ;D2 - 1 (ignore under/overflow)
                        
                        move.l #$0000000F, d3                       ;load 0x0000000F
                        and.l d3, d2                                ;get D2[3:0]
                        lsl.l d0, d2                                ;shift left D2
                        lsl.l d0, d3                                ;shift left D3
                        not.l d3                                    ;invert D3 e.g. 0xFF0FFFFF
                        and.l d3, d1                                ;insert 0x0 on corresponding digit
                        or.l d2, d1                                 ;insert modified digit number(D2)

                        move.l d1, $10(a6)                           ;write modified ram viewer address
                        
                        bra.w TSTRTNE_BMC_Draw


            ;
            ;   RIGHT INPUT
            ;
            TSTRTNE_BMC_right:
                move.w $0(a6), d0                                   ;check menu number

                cmpi.w #0, d0                                       ;if 0
                beq.w TSTRTNE_BMC_right_enteraddredit               ;enter address edit mode or modify digit number

                cmpi.w #1, d0                                       ;if 1
                beq.w TSTRTNE_BMC_right_enterdataedit               ;enter data edit mode or modify digit number

                cmpi.w #6, d0                                       ;if 6
                beq.w TSTRTNE_BMC_right_enterramviewedit            ;enter ram viewer mode or modify digit number

                bra.w TSTRTNE_BMC_Draw                          ;if not, do nothing

                TSTRTNE_BMC_right_enteraddredit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_right_addredit                ;if 1, goto address edit mode

                    move.w #7, $6(a6)                               ;set address digit as 7
                    move.b #1, $D(a6)                               ;set edit mode flag

                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_right_addredit:
                    move.w $6(a6), d0                               ;get address digit

                    cmpi.w #0, d0                                   ;if >0
                    bgt.w TSTRTNE_BMC_right_addredit_decdig         ;decrease digit
                    move.w #8, $6(a6)                               ;if not, write 8(loop)
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_right_addredit_decdig:
                    subq.w #1, d0                                   ;address digit - 1
                    move.w d0, $6(a6)                               ;write modified address digit
                    bra.w TSTRTNE_BMC_Draw



                TSTRTNE_BMC_right_enterdataedit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_right_dataedit                ;if 1, goto data edit mode

                    move.w #3, $A(a6)                               ;set data digit as 3
                    move.b #1, $D(a6)                               ;set edit mode flag

                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_right_dataedit:
                    move.w $A(a6), d0                               ;get data digit

                    cmpi.w #0, d0                                   ;if >0
                    bgt.w TSTRTNE_BMC_right_dataedit_decdig         ;decrease digit
                    move.w #4, $A(a6)                               ;if not, write 4(loop)
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_right_dataedit_decdig:
                    subq.w #1, d0                                   ;data digit - 1
                    move.w d0, $A(a6)                               ;write modified data digit
                    bra.w TSTRTNE_BMC_Draw



                TSTRTNE_BMC_right_enterramviewedit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_right_ramviewedit             ;if 1, goto ram viewer address edit mode

                    move.w #7, $14(a6)                              ;set ram viewer address digit as 7
                    move.b #1, $D(a6)                               ;set edit mode flag

                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_right_ramviewedit:
                    move.w $14(a6), d0                              ;get ram viewer address digit

                    cmpi.w #1, d0                                   ;if >1
                    bgt.w TSTRTNE_BMC_right_ramviewedit_decdig      ;decrease digit
                    move.w #8, $14(a6)                              ;if not, write 8(loop)
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_right_ramviewedit_decdig:
                    subq.w #1, d0                                   ;ram viewer address digit - 1
                    move.w d0, $14(a6)                              ;write modified ram viewer address digit
                    bra.w TSTRTNE_BMC_Draw


            ;
            ;   LEFT INPUT
            ;
            TSTRTNE_BMC_left:
                move.w $0(a6), d0                                   ;check menu number

                cmpi.w #0, d0                                       ;if 0
                beq.w TSTRTNE_BMC_left_exitaddredit                 ;exit address edit mode or modify digit number

                cmpi.w #1, d0                                       ;if 1
                beq.w TSTRTNE_BMC_left_exitdataedit                 ;exit data edit mode or modify digit number

                cmpi.w #6, d0                                       ;if 6
                beq.w TSTRTNE_BMC_left_exitramviewedit              ;exit ram viewer mode or modify digit number

                bra.w TSTRTNE_BMC_Draw                          ;if not, do nothing

                TSTRTNE_BMC_left_exitaddredit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_left_addredit                 ;if 1, goto address edit mode

                    move.w #0, $6(a6)                               ;if 0, write address digit 0
                    move.b #1, $D(a6)                               ;set edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_left_addredit:
                    move.w $6(a6), d0                               ;get address digit

                    cmpi.w #7, d0                                   ;if <7
                    blt.w TSTRTNE_BMC_left_addredit_incdig          ;increase digit

                    move.w #8, $6(a6)                               ;if not, set address digit as 8
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_left_addredit_incdig:
                    addq.w #1, d0                                   ;address digit + 1
                    move.w d0, $6(a6)                               ;write modified address digit
                    bra.w TSTRTNE_BMC_Draw



                TSTRTNE_BMC_left_exitdataedit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_left_dataedit                 ;if 1, goto data edit mode

                    move.w #0, $A(a6)                               ;if 0, write address digit 0
                    move.b #1, $D(a6)                               ;set edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_left_dataedit:
                    move.w $A(a6), d0                               ;get data digit

                    cmpi.w #3, d0                                   ;if <3
                    blt.w TSTRTNE_BMC_left_dataedit_incdig          ;increase digit

                    move.w #4, $A(a6)                               ;if not, set data digit as 4
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_left_dataedit_incdig:
                    addq.w #1, d0                                   ;data digit + 1
                    move.w d0, $A(a6)                               ;write modified data digit
                    bra.w TSTRTNE_BMC_Draw



                TSTRTNE_BMC_left_exitramviewedit:
                    btst.b #$0, $D(a6)                              ;check the flag
                    bne.w TSTRTNE_BMC_left_ramviewedit              ;if 1, goto ram viewer address edit mode

                    move.w #1, $14(a6)                              ;if 0, write address digit 2
                    move.b #1, $D(a6)                               ;set edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_left_ramviewedit:
                    move.w $14(a6), d0                              ;get ram viewer address digit

                    cmpi.w #7, d0                                   ;if <7
                    blt.w TSTRTNE_BMC_left_ramviewedit_incdig       ;increase digit

                    move.w #8, $14(a6)                              ;if not, set ram viewer address digit as 8
                    move.b #0, $D(a6)                               ;clear edit mode flag
                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_left_ramviewedit_incdig:
                    addq.w #1, d0                                   ;data digit + 1
                    move.w d0, $14(a6)                              ;write modified ram viewer address digit
                    bra.w TSTRTNE_BMC_Draw


            ;
            ;   BUTTON A INPUT
            ;
            TSTRTNE_BMC_Execute:
                move.w $0(a6), d0                                   ;get latest input 
                cmpi #$2, d0                                        ;READ
                beq.w TSTRTNE_BMC_Read
                cmpi #$3, d0                                        ;WRITE
                beq.w TSTRTNE_BMC_Write
                cmpi #$4, d0                                        ;COPY
                beq.w TSTRTNE_BMC_Execute_copy
                cmpi #$5, d0                                        ;SHIFT
                beq.w TSTRTNE_BMC_Execute_shift

                bra.w TSTRTNE_BMC_Draw                          ;else


                TSTRTNE_BMC_Execute_copy:
                    move.l $2(a6), d0                               ;get source address
                    move.l $10(a6), d1                              ;get target address

                    btst.l #0, d0                                   ;if D0[0] = 1
                    bne.s TSTRTNE_BMC_Execute_copy_illegaladdr      ;goto illegal access
                    btst.l #0, d1                                   ;if D1[0] = 1
                    bne.s TSTRTNE_BMC_Execute_copy_illegaladdr      ;goto illegal access
                    move.w $8(a6), d2                               ;get loop count
                    cmpi.w #0, d2                                   ;if 0
                    beq.s TSTRTNE_BMC_Execute_copy_zerolength
                    subi.w #1, d2                                   ;loop count - 1
                    btst.l #15, d2                                  ;if D0[15] = 1
                    bne.w TSTRTNE_BMC_Execute_copy_overlength

                    movea.l d0, a0                                  ;load source addr
                    movea.l d1, a1                                  ;load target addr

                    move.b #1, $5E008                               ;kick the watchdog
                    move.b #0, $5E008

                    TSTRTNE_BMC_Execute_copy_loop:
                        move.w (a0)+, (a1)+                         ;copy
                        dbf d2, TSTRTNE_BMC_Execute_copy_loop

                    lea COPYCOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    move.l #0, d0                                   ;initialize d0, d1
                    move.l #0, d1

                    bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_Execute_copy_illegaladdr:
                        lea COPYILLEGAL, a0
                        move.l a0, -(sp)
                        move.w #4, -(sp)                            ;palette 4 (red)
                        move.w #6, -(sp)                            ;xpos fixed
                        move.w #10, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_Execute_copy_zerolength:
                        lea COPYZEROLENGTH, a0
                        move.l a0, -(sp)
                        move.w #4, -(sp)                            ;palette 4 (red)
                        move.w #6, -(sp)                            ;xpos fixed
                        move.w #10, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                        bra.w TSTRTNE_BMC_Draw

                    TSTRTNE_BMC_Execute_copy_overlength:
                        lea COPYTOOLONG, a0
                        move.l a0, -(sp)
                        move.w #4, -(sp)                            ;palette 4 (red)
                        move.w #6, -(sp)                            ;xpos fixed
                        move.w #10, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                        bra.w TSTRTNE_BMC_Draw



                
                TSTRTNE_BMC_Execute_shift:
                    move.w $40000, d0                               ;move last byte to d2
                    move.w d0, $F80                                 ;move last byte to F80

                    lea $F00, a0                                    ;first address of the page
                    move.w #65, d1
                    
                    TSTRTNE_BMC_Execute_shift_loop:
                        move.l (a0), d0                             ;get raw data
                        lsl.l #6, d0                                ;shift 6 bits left
                        swap d0                                     ;high 16 low 16 swap
                        move.w d0, (a0)+                            ;write shifted data
                        dbf d1, TSTRTNE_BMC_Execute_shift_loop      ;loop 66 times
                    
                    lea SHIFTCOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_BMC_Draw



            ;
            ;   BUTTON B INPUT
            ;
            TSTRTNE_BMC_Read:
                move.w $0(a6), d0                                   ;get menu number
                cmpi.w #2, d0                                       ;if >2
                bgt.w TSTRTNE_BMC_Draw                          ;do nothing
                                                                    ;menu num 0, 1, and 2

                move.l $2(a6), d0                                   ;get address
                btst.l #$0, d0                                      ;test bit0 of address
                bne.w TSTRTNE_BMC_Read_byte
                ;TSTRTNE_BMC_Read_word:
                    movea.l $2(a6), a0                              ;get address
                    move.w (a0), $8(a6)                             ;read and write data
                    addi.l #2, $2(a6)                               ;auto increment
                    
                    lea WREADCOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_Read_byte:
                    movea.l $2(a6), a0                              ;get address
                    move.b (a0), $9(a6)                             ;read and write data
                    addi.l #2, $2(a6)                               ;auto increment
                    
                    lea BREADCOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_BMC_Draw

            ;
            ;   BUTTON C INPUT
            ;
            TSTRTNE_BMC_Write:
                move.w $0(a6), d0                                   ;get menu number
                cmpi.w #3, d0                                       ;if >3
                bgt.w TSTRTNE_BMC_Draw                          ;do nothing
                cmpi.w #2, d0                                       ;if 2
                beq.w TSTRTNE_BMC_Draw                          ;do nothing
                                                                    ;menu num 0, 1, and 3

                move.l $2(a6), d0                                   ;get address
                btst.l #$0, d0                                      ;test bit0 of address
                bne.w TSTRTNE_BMC_Write_byte
                ;TSTRTNE_BMC_Write_word:
                    movea.l $2(a6), a0                              ;get address
                    move.w $8(a6), (a0)                             ;read and write data
                    addi.l #2, $2(a6)                               ;auto increment
                    
                    lea WWRITECOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_BMC_Draw

                TSTRTNE_BMC_Write_byte:
                    movea.l $2(a6), a0                              ;get address
                    move.b $9(a6), (a0)                             ;read and write data
                    addi.l #2, $2(a6)                               ;auto increment
                    
                    lea BWRITECOMPLETE, a0
                    move.l a0, -(sp)
                    move.w #3, -(sp)                                ;palette 3 (green)
                    move.w #6, -(sp)                                ;xpos fixed
                    move.w #10, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    bra.w TSTRTNE_BMC_Draw








            TSTRTNE_BMC_Draw:
                move.w $0(a6), d0                                       ;get menu number
                cmpi.w #4, d0                                           ;if COPY
                beq.s TSTRTNE_BMC_Draw_CopyMode

                ;   ADDRESS/DATA
                lea BMCMESSAGE0, a4
                move.w #1, d6                                           ;repeat 2 times
                move.w #3, d5                                           ;ypos 3
                TSTRTNE_BMC_Draw_AddrData_loop:
                    move.w #0, d2                                       ;palette 0(dark blue)
                    move.w #1, d0                                       ;load 1
                    sub.w d6, d0                                        ;1 - loop counter

                    move.w $0(a6), d1                                   ;get menu number
                    cmp.w d0, d1                                        ;if value == 1-loop counter
                    bne TSTRTNE_BMC_Draw_AddrData_prnt
                    move.w #4, d2                                       ;palette 4(red)

                    TSTRTNE_BMC_Draw_AddrData_prnt:
                        move.l a4, -(sp)
                        move.w d2, -(sp)
                        move.w #4, -(sp)                                ;xpos fixed
                        move.w d5, -(sp)
                        move.w #0, -(sp)
                        bsr.w funcPrintText

                    addq.w #1, d5                                       ;ypos+1
                    add.l #16, a4

                    dbf d6, TSTRTNE_BMC_Draw_AddrData_loop

                ;   RAM AREA
                move.w $0(a6), d0                                       ;get menu number
                move.w #0, d1                                           ;palette 0(dark blue)
                cmpi.w #6, d0
                bne.s TSTRTNE_BMC_Draw_Ramarea
                move.w #4, d1                                           ;palette 4(red)

                TSTRTNE_BMC_Draw_Ramarea:
                    lea RAMAREA, a0
                    move.l a0, -(sp)
                    move.w d1, -(sp)
                    move.w #6, -(sp)
                    move.w #12, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                bra.s TSTRTNE_BMC_Draw_Options

                TSTRTNE_BMC_Draw_CopyMode:
                    lea DATACOPYSOURCE, a0
                    move.l a0, -(sp)
                    move.w #5, -(sp)                                        ;palette 3 (saffron)
                    move.w #4, -(sp)                                        ;xpos fixed
                    move.w #3, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    lea DATACOPYLENGTH, a0
                    move.l a0, -(sp)
                    move.w #5, -(sp)                                        ;palette 3 (saffron)
                    move.w #4, -(sp)                                        ;xpos fixed
                    move.w #4, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                    lea DATACOPYTARGET, a0
                    move.l a0, -(sp)
                    move.w #5, -(sp)                                        ;palette 3 (saffron)
                    move.w #6, -(sp)                                        ;xpos fixed
                    move.w #12, -(sp)
                    move.w #0, -(sp)
                    bsr.w funcPrintText

                TSTRTNE_BMC_Draw_Options:
                    lea BMCMESSAGE2, a4
                    move.w #1, d7                                           ;repeat 2 times
                    move.w #8, d6                                           ;xpos 8
                    TSTRTNE_BMC_Draw_Optn_loop_out:
                        move.w #1, d5                                       ;repeat 2 times
                        move.w #6, d4                                       ;ypos 6
                        TSTRTNE_BMC_Draw_Optn_loop_in:
                            move.w #0, d2                                   ;palette 0(dark blue)
                            move.w #5, d0                                   ;load 5

                            move.w d7, d1                                   ;get outer loop counter
                            lsl.w #1, d1                                    ;outer loop counter*2
                            add.w d5, d1                                    ;outer loop counter*2 + inner loop counter
                            sub.w d1, d0                                    ;5 - (outer loop counter*2 + inner loop counter)

                            move.w $0(a6), d1                               ;get menu number
                            cmp.w d0, d1                                    ;if value == 1-loop counter
                            bne.s TSTRTNE_BMC_Draw_Optn_prnt
                            move.w #4, d2                                   ;palette 4(red)

                            TSTRTNE_BMC_Draw_Optn_prnt: 
                                move.l a4, -(sp)
                                move.w d2, -(sp)
                                move.w d6, -(sp)
                                move.w d4, -(sp)
                                move.w #0, -(sp)
                                bsr.w funcPrintText

                            addq.w #1, d4                                   ;ypos+1
                            add.l #8, a4

                            dbf d5, TSTRTNE_BMC_Draw_Optn_loop_in
                        
                        addi.w #10, d6                                      ;xpos+16

                        dbf d7, TSTRTNE_BMC_Draw_Optn_loop_out

                


                ;ADDRESS HEX VALUE starts from 0x521A8... 8 A C E 0 2 4 6
                ;DATA HEX VALUE starts from 0x52230...            0 2 4 6
                ;RAM VIEWER ADDRESS HEX VALUE starts from 0x52622...    2 4 6 8 A C E 0
                ;RAM CONTENTS starts from 0x52680
                ;HEX digit 0 to F is on every odd code of CHARRAM 1E0-1FF 
                ;PR bits are 0xF

                move.w #7, d7                                           ;repeat 8 times
                lea $521B6, a4                                          ;last digit of address on VRAM1
                move.l $2(a6), d6                                       ;get addr data
                move.w $6(a6), d5                                       ;get addr digit
                TSTRTNE_BMC_Draw_Addr:
                    move.w #$0001, d1                                   ;palette 1 (light blue)
                    move.w d7, d0                                       ;get loop counter
                    eori.w #$0007, d0                                   ;invert loop counter

                    cmp.w d0, d5                                        ;if current digit != loop digit
                    bne.s TSTRTNE_BMC_Draw_Addr_prnt                ;print hex value
                    move.w #$0004, d1                                   ;if not, set palette as 4 (red)

                    TSTRTNE_BMC_Draw_Addr_prnt:
                        move.l d6, d0                                   ;copy addr data
                        andi.l #$0000000F, d0                           ;get D0[3:0]
                        lsl.w #1, d0                                    ;* 2
                        addq.w #1, d0                                   ;+ 1
                        ori.w #$F1E0, d0                                ;insert 0xF1EX
                        move.b d1, $2001(a4)                            ;write to VRAM2
                        move.w d0, (a4)                                 ;write to VRAM1
                        sub.l #2, a4                                    ;decrease A4
                        lsr.l #4, d6                                    ;shift right addr data

                    dbf d7, TSTRTNE_BMC_Draw_Addr

                move.w #3, d7                                           ;repeat 4 times
                lea $52236, a4                                          ;last digit of address on VRAM1
                move.w $8(a6), d6                                       ;get data
                move.w $A(a6), d5                                       ;get digit
                TSTRTNE_BMC_Draw_Data:
                    move.w #$0001, d1                                   ;palette 1 (light blue)
                    move.w d7, d0                                       ;get loop counter
                    eori.w #$0003, d0                                   ;invert loop counter

                    cmp.w d0, d5                                        ;if current digit != loop digit
                    bne.s TSTRTNE_BMC_Draw_Data_prnt                ;print hex value
                    move.w #$0004, d1                                   ;if not, set palette as 4 (red)

                    TSTRTNE_BMC_Draw_Data_prnt:
                        move.w d6, d0                                   ;copy data
                        andi.w #$000F, d0                               ;get D0[3:0]
                        lsl.w #1, d0                                    ;* 2
                        addq.w #1, d0                                   ;+ 1
                        ori.w #$F1E0, d0                                ;insert 0xF1EX
                        move.b d1, $2001(a4)                            ;write to VRAM2
                        move.w d0, (a4)                                 ;write to VRAM1
                        sub.l #2, a4                                    ;decrease A4
                        lsr.l #4, d6                                    ;shift right data

                    dbf d7, TSTRTNE_BMC_Draw_Data

                move.w #7, d7                                           ;repeat 8 times
                lea $52630, a4                                          ;last digit of address on VRAM1
                move.l $10(a6), d6                                      ;get ram viewer addr data
                move.w $14(a6), d5                                      ;get addr digit
                TSTRTNE_BMC_Draw_Ramview:
                    move.w #$0001, d1                                   ;palette 1 (light blue)
                    move.w d7, d0                                       ;get loop counter
                    eori.w #$0007, d0                                   ;invert loop counter

                    cmp.w d0, d5                                        ;if current digit != loop digit
                    bne.s TSTRTNE_BMC_Draw_Ramview_prnt             ;print hex value
                    move.w #$0004, d1                                   ;if not, set palette as 4 (red)

                    TSTRTNE_BMC_Draw_Ramview_prnt:
                        move.l d6, d0                                   ;copy ram viewer addr data
                        andi.l #$0000000F, d0                           ;get D0[3:0]
                        lsl.w #1, d0                                    ;* 2
                        addq.w #1, d0                                   ;+ 1
                        ori.w #$F1E0, d0                                ;insert 0xF1EX
                        move.b d1, $2001(a4)                            ;write to VRAM2
                        move.w d0, (a4)                                 ;write to VRAM1
                        sub.l #2, a4                                    ;decrease A4
                        lsr.l #4, d6                                    ;shift right ram viewer addr data

                    dbf d7, TSTRTNE_BMC_Draw_Ramview


                movea.l $10(a6), a0                                     ;get ram viewer addr data
                lea $5270E, a1                                          ;RAM contents start address in VRAM1

                move.w #15, d7                                          ;repeat 16 times
                TSTRTNE_BMC_Draw_Ramdata_vloop:
                    move.w #3, d6                                       ;repeat 4 times
                    TSTRTNE_BMC_Draw_Ramdata_hloop:
                        move.l (a0)+, d1                                ;get ram contents
                        move.w #7, d5                                   ;repeat 8 times
                        TSTRTNE_BMC_Draw_Ramdata_4B:
                            move.l d1, d0                               ;copy ram contents
                            andi.l #$0000000F, d0                       ;get D0[3:0]
                            lsl.w #1, d0                                ;* 2
                            addq.w #1, d0                               ;+ 1
                            ori.w #$F1E0, d0                            ;insert 0xF1EX
                            move.b #$0000, $2001(a1)                    ;write to VRAM2
                            move.w d0, (a1)                             ;write to VRAM1
                            sub.l #2, a1                                ;decrease A1
                            lsr.l #4, d1                                ;shift right ram viewer addr data

                            dbf d5, TSTRTNE_BMC_Draw_Ramdata_4B
                        
                        add.l #$20, a1                                  ;next 4 bytes(VRAM1)
                        dbf d6, TSTRTNE_BMC_Draw_Ramdata_hloop
                    
                    add.l #$40, a1                                      ;next line(VRAM1)
                    dbf d7, TSTRTNE_BMC_Draw_Ramdata_vloop



            TSTRTNE_BMC_KeyInDelay:
                move.w $5CC02, d0
                cmpi.b #$EE, d0
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_BMC_InEval

BMCMESSAGE0     dc.w 'RD/WR Address', $0000
BMCMESSAGE1     dc.w 'RD/WR    Data', $0000
BMCMESSAGE2     dc.w 'Read  ', $0000
BMCMESSAGE3     dc.w 'Write ', $0000
BMCMESSAGE4     dc.w 'Copy  ', $0000
BMCMESSAGE5     dc.w 'Shift ', $0000
RWSTATUS        dc.w 'RW status', $0000
BREADCOMPLETE   dc.w 'Byte read completed ', $0000
BWRITECOMPLETE  dc.w 'Byte write completed', $0000
WREADCOMPLETE   dc.w 'Word read completed ', $0000
WWRITECOMPLETE  dc.w 'Word write completed', $0000
SHIFTCOMPLETE   dc.w 'Bubble page shifted ', $0000
COPYCOMPLETE    dc.w 'Block copy completed', $0000
COPYILLEGAL     dc.w 'Illegal copy address', $0000
COPYZEROLENGTH  dc.w '  Copy length is 0  ', $0000
COPYTOOLONG     dc.w 'Length is over 8000 ', $0000 
RAMAREA         dc.w 'RAM area', $0000
HEXDATAPREFIX   dc.w '0x', $0000
DATACOPYSOURCE  dc.w '       Source', $0000
DATACOPYLENGTH  dc.w '  Word length', $0000
DATACOPYTARGET  dc.w '  Target', $0000




        *--------------------------------------------------------
        *
        *       TESTMENU_Contributors subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_Contributors:
            move.l #$3CC00, -(sp)                                       ;copy tiles(2CC00 on ROM)
            move.w #16, -(sp)
            move.w #1432, -(sp)
            move.w #0, -(sp)
            jsr funcLoadBubble


            jsr funcClearTilemap

            move.w #16, -(sp)
            move.w #4, -(sp)
            move.w #$F660, -(sp)                                        ;bubbledrive Korean logo
            move.w #$000B, -(sp)
            move.w #8, -(sp)
            move.w #16, -(sp)
            move.w #0, -(sp)
            bsr.w funcDrawTilemap


            lea CONTLINE0, a4
            move.w #4, d5
            move.w #10, d6
            TSTRTNE_Contributors_credits_1:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #0, -(sp)                                        ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5
                add.l #34, a4

                dbf d6, TSTRTNE_Contributors_credits_1

            lea CONTLINE11, a4
            move.w #22, d5
            move.w #6, d6
            TSTRTNE_Contributors_credits_2:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #0, -(sp)                                        ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #1, d5
                add.l #34, a4

                dbf d6, TSTRTNE_Contributors_credits_2

            TSTRTNE_Contributors_KeyInDelay:
                bsr.w funcCheckInput                                    ;check P1 button input
                move.w (sp)+, d0                                        ;get latest input 
                btst.l #$4, d0                                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_Contributors_KeyInDelay

CONTLINE0       dc.w '      --------------------      ', $0000
CONTLINE1       dc.w '       BubbleDrive8 is a        ', $0000
CONTLINE2       dc.w '         bubble memory          ', $0000
CONTLINE3       dc.w '       cartridge emulator       ', $0000
CONTLINE4       dc.w '         developed for          ', $0000
CONTLINE5       dc.w '                                ', $0000
CONTLINE6       dc.w '     "Konami Bubble System"     ', $0000
CONTLINE7       dc.w '                                ', $0000
CONTLINE8       dc.w '  - Copyright 2020-2021 Raki -  ', $0000
CONTLINE9       dc.w '          bubsys85.net          ', $0000
CONTLINE10      dc.w '      --------------------      ', $0000

CONTLINE11      dc.w '       Special thanks to        ', $0000
CONTLINE12      dc.w '              ----              ', $0000
CONTLINE13      dc.w '      v9938          MAKI       ', $0000
CONTLINE14      dc.w '   CSG Akatian      akamig      ', $0000
CONTLINE15      dc.w '      Artworks by Tsuruki       ', $0000
CONTLINE16      dc.w '              MAME              ', $0000
CONTLINE17      dc.w '  EXCELLENT Easy68k ASSEMBLER   ', $0000

            


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
        *       TESTMENU_About subroutine
        *
        *--------------------------------------------------------

        TSTRTNE_About:
            jsr funcClearTilemap

            lea INFOLINE0, a4
            move.w #7, d5
            move.w #5, d6
            TSTRTNE_About_credits_1:
                move.l a4, -(sp)
                move.w #0, -(sp)
                move.w #0, -(sp)                                        ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #3, d5
                add.l #68, a4

                dbf d6, TSTRTNE_About_credits_1

            lea INFOLINE1, a4
            move.w #8, d5
            move.w #5, d6
            TSTRTNE_About_credits_2:
                move.l a4, -(sp)
                move.w #1, -(sp)
                move.w #0, -(sp)                                        ;xpos fixed
                move.w d5, -(sp)
                move.w #0, -(sp)
                bsr.w funcPrintText

                addq.w #3, d5
                add.l #68, a4

                dbf d6, TSTRTNE_About_credits_2

            TSTRTNE_About_KeyInDelay:
                bsr.w funcCheckInput                                    ;check P1 button input
                move.w (sp)+, d0                                        ;get latest input 
                btst.l #$4, d0                                          ;power-up(gradius) or fire(twinbee)
                beq.w TESTMENU
                jsr funcFixedDelaySlow
                bra.w TSTRTNE_About_KeyInDelay

INFOLINE0       dc.w '         Serial number          ', $0000
INFOLINE1       dc.w '         [BDXXXXXXXXX]          ', $0000
INFOLINE3       dc.w '       Manufacturing Date       ', $0000
INFOLINE4       dc.w '           2022-XX-XX           ', $0000
INFOLINE6       dc.w '            User  ID            ', $0000
INFOLINE7       dc.w '             XXXXXX             ', $0000
INFOLINE9       dc.w '     FPGA bitstream version     ', $0000
INFOLINE10      dc.w '              v1.7              ', $0000
INFOLINE12      dc.w '       Test program build       ', $0000
INFOLINE13      dc.w '      B85:K:A:D:2021110802      ', $0000
INFOLINE15      dc.w '        Hardware version        ', $0000
INFOLINE16      dc.w '              v3.1              ', $0000


        
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
        funcDrawTilemap:                                        
                                                            ;Width -> Height -> VRAM priority/flip/CHARRAMADDR
                                                            ;color RAM flip/palette -> Xpos -> Ypos -> tilemap A/B -> return address

            jsr sysSaveReg

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

            jsr sysLoadReg
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
        funcPrintText:
            jsr sysSaveReg

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

                subi #32, d0                                ;subtract 8'd32 to convert an ASCII code to the corresponding CHARRAM address
                move.w (a0), d1
                andi.w #$F000, d1                           ;get VRAM PR code
                or.b d0, d1                                 ;write CHARRAM code

                move.w d1, (a0)+
                move.w d2, (a1)+

                ;letter2 
                lsr.w #$8, d0
                cmpi.b #$00, d0
                beq TYPEQUIT

                subi #32, d0                                ;subtract 8'd32 to convert an ASCII code to the corresponding CHARRAM address
                move.w (a0), d1
                andi.w #$F000, d1                           ;get VRAM PR code
                or.b d0, d1                                 ;write CHARRAM code

                move.w d1, (a0)+
                move.w d2, (a1)+

                bra TYPELOOP

            TYPEQUIT:
                move.l a3, -(sp)                                ;push return address

                jsr sysLoadReg
                rts

        *--------------------------------------------------------
        *
        *       function: DrawSprite
        *
        *--------------------------------------------------------

        ;ARGS: OBJ SIZE[3:0] 0=32*32 1=16*32 2=32*16 3=64*64 4=8*8 5=16*8 6=8*16 7*16*16
        ;                    8=32*64 9=16*64 A=32*32 B=64*128 C=8*8 D=16*8 E=8*16 F=16*16
        ;      OBJ ZOOM[9:0] DENOMINATOR
        ;      OBJ XPOS[8:0]
        ;      OBJ YPOS[7:0]
        ;      OBJ CODE[9:0] 
        ;      OBJ COLOR[3:0]
        ;      OBJ VFLIP[1], HFLIP[0]
        ;      OBJ PRIORITY[7:0]
        ;      Note that all args are words
        ;JSR:  RETURN ADDRESS 
        funcDrawSprite:                                        
            jsr sysSaveReg
            move.l (sp)+, a5                                    ;pop return address

            ;set priority
            move.l #0, d0                                       ;initialize d0
            move.w (sp)+, d0                                    ;pop priority
            eori.w #$00FF, d0                                   ;invert[7:0]
            lsl.w #4, d0
            lea $56000, a0                                      ;load OBJRAM address
            add.l d0, a0                                        ;get OBJRAM address

            ;set OBJLATCH_D
            move.l #0, d0                                       ;initialize d0
            move.l #0, d1                                       ;initialize d1

            move.w (sp)+, d7                                    ;pop FLIP bits
            move.w (sp)+, d0                                    ;pop COLOR
            lsl.w #1, d0

            move.w (sp)+, d6                                    ;pop CODE
            move.w d6, d1                                       ;copy CODE
            lsr.w #2, d1
            andi.w #$00C0, d1                                   ;mask [5:0]
            or.w d1, d0

                ;set OBJLATCH_F
                move.w (sp)+, $C(a0)                            ;pop YPOS

            move.w (sp)+, d5                                    ;pop XPOS
            move.w d5, d1
            lsr.w #8, d1
            or.w d1, d0

            move.w d7, d1                                       ;copy FLIP bits
            lsl.w #4, d1                                        ;VFLIP
            andi.w #$0020, d1
            or.w d1, d0

            move.w d0, $8(a0)

            ;set OBJLATCH_E
            andi.w #$00FF, d5
            move.w d5, $A(a0)

            ;set OBJLATCH_C
            andi.w #$00FF, d6
            move.w d6, $6(a0)

            ;set OBJLATCH_B
            move.w (sp)+, d1                                    ;pop ZOOM
            move.w d1, d0
            andi.w #$00FF, d0
            move.w d0, $4(a0)

            ;set OBJLATCH_A
            lsr.w #2, d1
            andi.w #$00C0, d1
            move.w d1, d0
            move.w (sp)+, d1                                    ;pop SIZE
            move.w d1, d2
            andi.w #$0007, d1                                   ;pick size[2:0]
            lsl.w #3, d1
            or.w d1, d0
            lsr.w #2, d2
            andi.w #0002, d2                                    ;double height mode
            or.w d2, d0
            andi.w #0001, d7
            or.w d7, d0
            andi.w #$00F9, d0
            move.w d0, $2(a0)

            move.l a5, -(sp)                                    ;push return address

            jsr sysLoadReg
            rts 


        *--------------------------------------------------------
        *
        *       function: FixedDelaySlow
        *
        *--------------------------------------------------------

        funcFixedDelaySlow:
            jsr sysSaveReg

            move.b #1, $5E008                           ;kick the watchdog
            move.b #0, $5E008
            move.w #$8000, d0
            funcFixedDelaySlow_delayloop:
                nop
                dbf d0, funcFixedDelaySlow_delayloop    ;loop

            jsr sysLoadReg
            rts


        *--------------------------------------------------------
        *
        *       function: FixedDelaySlow
        *
        *--------------------------------------------------------

        funcFixedDelayFast:
            jsr sysSaveReg

            move.b #1, $5E008                           ;kick the watchdog
            move.b #0, $5E008
            move.w #$4000, d0
            funcFixedDelayFast_delayloop:
                nop
                dbf d0, funcFixedDelayFast_delayloop    ;loop

            jsr sysLoadReg
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
        *       function: CheckLongInput
        *
        *--------------------------------------------------------

        funcCheckLongInput:
            jsr sysSaveReg

            move.l (sp)+, a0                                    ;pop return address
            
            lea $818, a1                                        ;load register start address
            move.w $5CC02, d0                                   ;get P1 button register
            ori.w #$FF00, d0                                    ;padding data
            move.w $2(a1), d1                                   ;get trigger counter value
            move.w $4(a1), d2                                   ;get long input pulse counter value

            cmpi.w #$FFFF, d0                                   ;no input
            beq.s funcCheckLongInput_rstcntr

            cmp.w (a1), d0                                      ;compare with previous input
            bne.s funcCheckLongInput_rstcntr
            ;funcCheckLongInput_inccntr
                addq.w #1, d1                                   ;increase trigger counter

                cmpi.w #14, d1                                  ;if d1 > 14
                bgt.s funcCheckLongInput_trig                   ;long input triggered
                move.w #$FFFF, -(sp)                            ;no triggered input
                bra.s funcCheckLongInput_exit                   ;if not, goto exit

            funcCheckLongInput_trig:
                subq.w #1, d1                                   ;decrease trigger counter(hold previous value)

                addq.w #1, d2                                   ;increase pulse counter
                cmpi.w #0, d2                                   ;if d2 > 0
                bgt.s funcCheckLongInput_trig_setflag
                move.w #$FFFF, -(sp)                            ;no triggered input
                bra.s funcCheckLongInput_exit

                funcCheckLongInput_trig_setflag:
                    move.w #0, d2                               ;reset trigger counter
                    move.w d0, -(sp)                            ;push input value
                    bra.s funcCheckLongInput_exit         

            funcCheckLongInput_rstcntr:
                move.w #0, d1                                   ;reset trigger counter
                move.w #0, d2                                   ;reset pulse counter
                move.w #$FFFF, -(sp)                            ;no triggered input

            funcCheckLongInput_exit:
                move.w d0, (a1)                                 ;write current input
                move.w d1, $2(a1)                               ;write trigger counter value
                move.w d2, $4(a1)                               ;write pulse counter value

            move.l a0, -(sp)                                    ;push return address

            jsr sysLoadReg
            rts

        *--------------------------------------------------------
        *
        *       function: ClearTilemap
        *
        *--------------------------------------------------------

        funcClearTilemap:
            move.w #$E000, -(sp)                        ;clear tilemap A
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            bsr.w funcFillTilemap

            move.w #$205F, -(sp)                        ;clear tilemap B
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
            jsr sysSaveReg

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

                jsr sysLoadReg
                rts

            funcScrExitMessage_MsgShift_rst:
                move.w #7, d1
                funcScrExitMessage_MsgShift_rst_loop:
                    move.b #0, (a1)
                    move.b #0, (a0)
                    add.l #2, a1
                    add.l #2, a0
                    dbf d1, funcScrExitMessage_MsgShift_rst_loop

                    jsr sysLoadReg
                    rts

            funcScrExitMessage_MsgShift_msb:
                move.w #7, d1
                funcScrExitMessage_MsgShift_msb_loop:
                    move.b #1, (a1)
                    move.b #0, (a0)
                    add.l #2, a1
                    add.l #2, a0
                    dbf d1, funcScrExitMessage_MsgShift_msb_loop

                    jsr sysLoadReg
                    rts

EXITMESSAGE   dc.w 'Press A+LEFT(1P) to exit back to menu screen', $0000

        *--------------------------------------------------------
        *
        *       function: BcdConv
        *
        *--------------------------------------------------------

        ;ARGS: 
        ;      BINARY SOURCE
        ;      BCD TARGET
        ;      DIGITS
        ;      FRACTIONAL PART = 1/INTEGER PART = 0
        ;JSR:  RETURN ADDRESS 
        funcBcdConv:
            jsr sysSaveReg
            
            movea.l (sp)+, a6                                       ;pop return address
            move.l #0, d3                                           ;initialize d3
            move.w (sp)+, d3                                        ;pop switch
            lsl.w #1, d3                                            ;shift left (2/0)
            addq.w #2, d3                                           ;add 2 (4/2)

            cmpi.w #2, d3
            bne.w funcBcdConv_frac

            ;funcBcdConv_int
                move.w (sp)+, d0                                    ;pop binary digit number
                move.l #14, d1
                sub.w d0, d1                                        ;14 - d0
                lsl.w #1, d1                                        ;(14 - d0) * 2

                lea INTCONST, a0                                    ;set integer constant start addr
                add.l d1, a0                                        ;start addr + d1

                move.l (sp)+, a2                                    ;pop target address
                move.w #0, (a2)
                add.l #2, a2                                        ;target address + 2

                move.l (sp)+, a1                                    ;pop binary source address
                move.w (a1), d1

                bra.s funcBcdConv_conv

            funcBcdConv_frac:
                move.w (sp)+, d0                                    ;pop binary digit number
                move.l #8, d1
                sub.w d0, d1                                        ;8 - d0
                lsl.w #2, d1                                        ;(10 - d0) * 4

                lea FRACCONST, a0
                add.l d1, a0

                move.l (sp)+, a2                                    ;pop target address
                move.l #0, (a2)
                add.l #4, a2

                move.l (sp)+, a1                                    ;pop binary source address
                move.w (a1), d1

            funcBcdConv_conv:
                subq.w #1, d0                                       ;digit number - 1
                funcBcdConv_conv_loop:
                    btst.l d0, d1                                   ;test bit from 8 to 0
                    beq.s funcBcdConv_conv_loop_skip

                    movea.l a2, a1                                  ;re-set target bcd reg

                    andi.b #$EF, CCR                                ;clear X bit

                    move.w d3, d2                                   ;copy d3(4/2)
                    subq.w #1, d2                                   ;set loop counter
                    funcBcdConv_conv_loop_addconst:
                        abcd -(a0), -(a1)                           ;Add BCD, byte instruction
                                                                    ;-(a0)+-(a1)+Xbit=-(a1)
                        dbf d2, funcBcdConv_conv_loop_addconst
                    add.l d3, a0                                    ;restore address

                    funcBcdConv_conv_loop_skip:
                        add.l d3, a0                                ;next constant
                    
                    dbf d0, funcBcdConv_conv_loop

            move.l a6, -(sp)                                        ;restore return address

            jsr sysLoadReg
            rts

FRACCONST       dc.l $05000000, $02500000, $01250000, $00625000, $00312500, $00156250, $00078125
INTCONST        dc.w $4096, $2048, $1024, $0512, $0256, $0128, $0064, $0032, $0016, $0008, $0004, $0002, $0001
NOWLOADING      dc.w 'NOW LOADING...', $0000

IVT:
                dc.l $00000600                                  ;Initial SP
                dc.l $00000008                                  ;Initial PC
                dc.l $00000900                                  ;Bus error
                dc.l $00000900                                  ;Address error
                dc.l $00010000                                  ;Illegal Instruction
                dc.l $00010000                                  ;Divide by 0
                dc.l $00010000                                  ;CHK Instruction
                dc.l $00010000                                  ;TRAPV Instruction
                dc.l $00010000                                  ;Privilege Violation
                dc.l $00010000                                  ;Trace
                dc.l $00000900, $00000900                       ;Emu
                dc.l $00000900, $00000900, $00010000            ;Reserved
                dc.l $00010000                                  ;Uninit. Int. Vector.
                dc.l $00010000,$00010000,$00010000,$00010000    ;Reserved
                dc.l $00010000,$00010000,$00010000,$00010000    ;Reserved
                dc.l $00010000                                  ;Spurious Interrupt
                dc.l TSTRTNE_SysIO_EXCEPTION_PARITY             ;Level 1
                dc.l TSTRTNE_SysIO_EXCEPTION_VBLANK             ;Level 2
                dc.l $00010000                                  ;Level 3
                dc.l TSTRTNE_SysIO_EXCEPTION_COUNTER            ;Level 4
                dc.l TSTRTNE_SysIO_EXCEPTION_BMCDONE            ;Level 5
                dc.l $00010000                                  ;Level 6
                dc.l $00010000                                  ;Level 7
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF    ;Traps
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF    ;dummy
                dc.l $FFFFFFFF,$FFFFFFFF,$FFFFFFFF,$FFFFFFFF
                                                                ;32+40

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