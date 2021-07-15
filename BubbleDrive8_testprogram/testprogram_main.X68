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
        WAITFORCONTROLLER:
            nop                                             ;I don't know the internal program the BMC executes
            dbf d0, WAITFORCONTROLLER                       ;Konami engineer added 4112 nop loops at that time

        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008                                   ;what circuitry acts as watchdog? idk

        lea $14C, a0                                        ;bubble memory error map start address in the bootloader area
        lea $d00, a1                                        ;target address, does the BMC uses this data using DMA? not verified
        move.w #75, d0                                      ;repeat 76 times
        COPYERRORMAP:                                       ;8*4*76=2432bits, FBM54DB needs 584bits of error map
            move.l (a0)+, (a1)+                             ;2432/4=608, 14 or 15bits of CRC(???) data should be supplied(by observation)
            dbf d0, COPYERRORMAP                            ;without this valid data, the BMC ignores 1st, 2nd, 3rd page access request

        move.w $78000, d0                                   ;expansion port diagnostic ROM base address
        cmpi.w #$5555, d0                                   ;check for 0x5555
        beq.w JUMPTOEXTROM

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
        bsr.w BOOTLOADERBUBBLEWAIT

        move.w #$1, $0(a0)                                  ;load page 0x001
        nop
        move.w #$1, $2(a0)                                  ;READ
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADERBUBBLEWAIT

        move.w #$801, $0(a0)                                ;write to page 0x801
        nop
        move.w #$1, $2(a0)                                  ;WRITE
        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        bsr.w BOOTLOADERBUBBLEWAIT

        move.w #0, $4(a0)                                   ;initialize controller
        move.w #$1, d1                                      ;set page 0x001 in D1
        lea $A00, a1                                        ;copy pages from A00
        move.w #5, d0                                       ;consecutive 6 pages
        LOADRAMTEST:
            move.w #0, $4(a0)                               ;initialize controller
            move.w d1, $0(a0)                               ;set page
            nop
            move.w #1, $2(a0)                               ;READ
            move.b #1, $5E008                               ;kick the Z80 watchdog
            move.b #0, $5E008
            bsr.w BOOTLOADERBUBBLEWAIT

            move.w $0(a0), d2                               ;copy last 6 bits
            move.w d2, $F80                                 ;place last 5 bits on F80
            lea $F00, a2                                    ;set source address
            move.w #65, d3                                  ;repeat 66 times
            BOOTLOADERSHIFTPAGE:
                move.l (a2), d2                             ;start shifting
                lsl.l #6, d2
                swap d2
                move.w d2, (a2)+
                dbf d3, BOOTLOADERSHIFTPAGE

            lea $F00, a2
            move.w #31, d3
            BOOTLOADERCOPYPAGE:
                move.l (a2)+, (a1)+
                dbf d3, BOOTLOADERCOPYPAGE
        
        addq.w #1, d1

        dbf d0, LOADRAMTEST

        move.w #0, $4(a0)                                   ;initialize controller
        jmp $A00

        JUMPTOEXTROM:
            jmp $78002

        BOOTLOADERBUBBLEWAIT:
            move.w #$8000, d7                               ;signed -32768
            BOOTLOADERWAITLOOP:
                nop
                dbf d7, BOOTLOADERWAITLOOP
            rts




    ORG     $A00
    INITIALTEST:                                            ;initial RAM test routines
        lea $1000, sp                 
        move.l #$0, d3                                      ;initialize d3
        move.l #$0, d4                                      ;initialize d4

        move.b #1, $5E008                                   ;kick the Z80 watchdog
        move.b #0, $5E008
        nop

        move.b #1, $5C001                                   ;morning music code latch
        nop

        move.w #$8000, d7
        DELAYLOOP:
            nop
            dbf d7, DELAYLOOP                               ;initial delay

        move.b #0, $5E004                                   ;Z80 interrupt
        nop
        nop
        move.b #1, $5E004

        move.l #$0, d7                                      ;initialize d7

        move.w #1, -(sp)                                    ;palette RAM test
        move.l #$5A000, -(sp)
        move.l #$1000, -(sp)
        bsr.w RAMTEST
        move.w (sp)+, d2
        or.w d2, d7                                         ;save test result in d7[0]
        
        move.w #1, -(sp)                                    ;character RAM test
        move.l #$30000, -(sp)                
        move.l #$10000, -(sp)                   
        bsr.w RAMTEST                  
        move.w (sp)+, d2
        lsl.w #1, d2                
        or.w d2, d7                                         ;save test result in d7[1]
        
        move.w #0, -(sp)                                    ;scroll RAM test
        move.l #$50000, -(sp)                
        move.l #$1000, -(sp)                   
        bsr.w RAMTEST                  
        move.w (sp)+, d2
        lsl.w #2, d2           
        or.w d2, d7                                         ;save test result in d7[2]

        move.w #1, -(sp)                                    ;tilemap RAM test
        move.l #$52000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w RAMTEST
        move.w (sp)+, d2
        lsl.w #3, d2         
        or.w d2, d7                                         ;save test result in d7[3]

        move.w #0, -(sp)                                    ;tile color RAM test
        move.l #$52000, -(sp)                
        move.l #$2000, -(sp)                   
        bsr.w RAMTEST                  
        move.w (sp)+, d2
        lsl.w #4, d2           
        or.w d2, d7                                         ;save test result in d7[4]

        move.w #0, -(sp)                                    ;Z80 RAM test
        move.l #$20000, -(sp)                
        move.l #$8000, -(sp)                   
        bsr.w RAMTEST                  
        move.w (sp)+, d2
        lsl.w #5, d2           
        or.w d2, d7                                         ;save test result in d7[5]

        move.w #1, -(sp)                                    ;expansion RAM
        move.l #$70000, -(sp)                
        move.l #$4000, -(sp)                   
        bsr.w RAMTEST                  
        move.w (sp)+, d2
        lsl.w #6, d2           
        or.w d2, d7                                         ;save test result in d7[6]

        move.l #$10000, -(sp)
        move.w #32, -(sp)
        move.w #7, -(sp)                                    ;from 0x380
        bsr.w LOADBUBBLE

        jmp $10000                                          ;goto work ram


        ;FUNCTION RAMTEST
        RAMTEST:                                            ;bit width flag -> start address -> test length -> return address
            movea.l (sp)+, a2                               ;pop return address
            move.l (sp)+, d1                                ;pop test length
            movea.l (sp)+, a1                               ;pop start address
        
            lsr.l #1, d1                                    ;divide by 2
            subi.l #1, d1                                   ;test length - 1

            move.w (sp)+, d2                                ;pop bit width flag(0 = 8bit, 1 = 16bit)
            btst.l #$0, d2                                  ;1 = WORDTEST 0 = BYTETEST
            beq.s BYTETEST                                  ;if 0(Z=1), go to BYTETEST if 1(Z=0) go to WORDTEST

                WORDTEST:       
                    move.w #$FFFF, d3
                    bsr.w FILLWORD
                    move.w #$5555, d3
                    bsr.w FILLWORD
                    move.w #$AAAA, d3
                    bsr.w FILLWORD
                    move.w #$0000, d3
                    bsr.w FILLWORD

                    move.w #0, -(sp)                        ;set ok flag
                    move.l a2, -(sp)                        ;push return address
                    rts  

                    FILLWORD:
                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        WORDRWTEST:
                            move.w d3, (a0)                 ;write $FFFF, 5555, AAAA, 0000
                            cmp.w (a0)+, d3                 ;read and compare
                            bne.w ERROR                     ;if not matches, goto ERROR
                            dbf d0, WORDRWTEST              ;loop  
                        rts        

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

                    move.w #0, -(sp)                        ;set ok flag
                    move.l a2, -(sp)                        ;push return address
                    rts

                    FILLBYTE:
                        move.l d1, d0                       ;move loop counter to d0
                        movea.l a1, a0                      ;move start address to a0
                        BYTERWTEST:                    
                            move.b d3, (a0)                 ;write $FF, 55, AA, 00
                            cmp.b (a0), d3                  ;read and compare
                            addq.l #2, a0                    ;+2 increment
                            bne.w ERROR                     ;if not matches, goto ERROR
                            dbf d0, BYTERWTEST              ;loop
                        rts  

                ERROR:   
                    addq.l #4, sp                            ;ignore "FILL" bsr.w address(4 bytes)            
                    move.w #1, -(sp)                        ;set error flag
                    move.l a2, -(sp)                        ;push return address
                    rts        


        ;
        ;           FUNCTION LOADBUBBLE
        ;
        ;ARGS: START PAGE ADDRESS
        ;      CONSECUTIVE PAGE LENGTH
        ;      DESTINATION MEMORY ADDRESS   
        ;JSR:  RETURN ADDRESS 
        LOADBUBBLE:                                         ;start page -> consecutive page length - > destination address -> return address
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
        move.w #52, -(sp)
        move.w #1024, -(sp)
        jsr LOADBUBBLE

        move.l #$5A000, -(sp) ;copy palette
        move.w #1, -(sp)
        move.w #1023, -(sp)
        jsr LOADBUBBLE


        TITLEPROGRAM:
            move.w #12, -(sp)
            move.w #12, -(sp)
            move.w #$F000, -(sp)
            move.w #$0000, -(sp)
            move.w #0, -(sp)
            move.w #18, -(sp)
            move.w #0, -(sp)
            bsr.w DRAWTILEMAP

            move.w #$F01F, -(sp)
            move.w #$0001, -(sp)
            move.w #1, -(sp)
            bsr.w FILLTILEMAP      


            move.w #0, d7
            move.w #7, d6
            DRAWMAINBANNER:
                move.w #8, -(sp)
                move.w #2, -(sp)
                move.w #$F090, -(sp)
                move.w #$0001, -(sp)
                move.w d7, -(sp)
                move.w #3, -(sp)
                move.w #1, -(sp)
                bsr.w DRAWTILEMAP
                addi.w #8, d7
                dbf d6, DRAWMAINBANNER

            END:
            move.w #$20, d6
            READWAIT0:
                move.b #1, $5E008                               ;kick the watchdog
                move.b #0, $5E008
                move.w #$8000, d7
                READWAIT1:
                    nop
                    dbf d7, READWAIT1                           ;loop

                lea $50431, a0
                move.w #15, d0
                SCROLL:
                    move.b (a0), d1
                    cmpi.b #$FF, d1
                    beq.s SCROLLLOOP
                    addq.b #1, d1
                    bra.s SCROLLEND
                    SCROLLLOOP:
                        move.b #$00, d1
                    SCROLLEND:
                        move.b d1, (a0)
                        add.l #2, a0
                    dbf d0, SCROLL
                dbf d6, READWAIT0                               ;loop
            jmp END   

        SHOWTESTRESULT:  
        
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
            move.l #0, d5

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



    SIMHALT             ; halt simulator



* Put variables and constants here

    END    BOOTLOADER        ; last line of source

*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
{"mode":"full","isActive":false}