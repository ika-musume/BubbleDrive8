*-----------------------------------------------------------
* Title      : BubbleDrive8_testprogram
* Written by : Raki
* Date       : 
* Description:
*-----------------------------------------------------------
    ORG    $10000
                                                    
    START:                                              ;first instruction of program
    lea $1000, sp                 
    move.l #$0, d3                                      ;initialize d3

    move.b #1, $5E008                                   ;kick the Z80 watchdog
    nop
    move.b #0, $5E008
    nop

    move.b #1, $5C001                                   ;morning music code latch
    nop

    move.w #$8000, d7
    LOOP:
        nop
        dbf d7, LOOP                                    ;initial delay

    move.b #0, $5E004                                   ;Z80 interrupt
    nop
    nop
    move.b #1, $5E004

                 
    move.w #1, -(sp)                                    ;palette RAM test
    move.l #$5A000, -(sp)
    move.l #$1000, -(sp)
    jsr RAMTEST
    move.w (sp)+, d2
    lsl.w #0, d2
    or.w d2, d3                                         ;save test result in d3[0]
     
    move.w #1, -(sp)                                    ;character RAM test
    move.l #$30000, -(sp)                
    move.l #$10000, -(sp)                   
    jsr RAMTEST                  
    move.w (sp)+, d2
    lsl.w #1, d2                
    or.w d2, d3                                         ;save test result in d3[1]
     
    move.w #0, -(sp)                                    ;scroll RAM test
    move.l #$50000, -(sp)                
    move.l #$1000, -(sp)                   
    jsr RAMTEST                  
    move.w (sp)+, d2
    lsl.w #2, d2           
    or.w d2, d3                                         ;save test result in d3[2]

    move.w #1, -(sp)                                    ;tilemap RAM test
    move.l #$52000, -(sp)                
    move.l #$2000, -(sp)                   
    jsr RAMTEST
    move.w (sp)+, d2
    lsl.w #3, d2         
    or.w d2, d3                                         ;save test result in d3[3]

    move.w #0, -(sp)                                    ;tile color RAM test
    move.l #$52000, -(sp)                
    move.l #$2000, -(sp)                   
    jsr RAMTEST                  
    move.w (sp)+, d2
    lsl.w #4, d2           
    or.w d2, d3                                         ;save test result in d3[4]

    
    move.l #$30000, -(sp)
    move.w #36, -(sp)
    move.w #0, -(sp)
    jsr LOADBUBBLE

    move.l #$5A000, -(sp)
    move.w #1, -(sp)
    move.w #36, -(sp)
    jsr LOADBUBBLE


    END:
    move.w #$20, d6
    READWAIT0:
        move.b #1, $5E008                               ;kick the watchdog
        move.b #0, $5E008
        move.w #$8000, d7
        READWAIT1:
            nop
            dbf d7, READWAIT1                           ;loop
        dbf d6, READWAIT0                               ;loop
    jmp END     
    

    
    RAMTEST:                                            ;bit width flag -> start address -> test length -> return address
        movea.l (sp)+, a2                               ;pop return address
        move.l (sp)+, d1                                ;pop test length
        movea.l (sp)+, a1                               ;pop start address
    
        lsr.l #1, d1                                    ;divide by 2
        subi.l #1, d1                                   ;test length - 1

        move.w (sp)+, d2                                ;pop bit width flag(0 = 8bit, 1 = 16bit)
        btst.w #$0, d2                                  ;1 = WORDTEST 0 = BYTETEST
        beq.w BYTETEST                                  ;if 0(Z=1), go to BYTETEST if 1(Z=0) go to WORDTEST

            WORDTEST:       
                move.w #$FFFF, d3
                jsr FILLWORD
                move.w #$5555, d3
                jsr FILLWORD
                move.w #$AAAA, d3
                jsr FILLWORD
                move.w #$0000, d3
                jsr FILLWORD
                move.l a2, -(sp)                        ;push return address
                rts  

                FILLWORD:
                    move.l d1, d0                       ;move loop counter to d0
                    movea.l a1, a0                      ;move start address to a0
                    WORDRWTEST:
                        move.w d3, (a0)                 ;write $FFFF
                        cmpi.w d3, (a0)+                ;read and compare
                        bne.w ERROR                     ;if not matches, goto ERROR
                        dbf d0, WORDRWTEST              ;loop  
                    rts        

            BYTETEST:
                add.l #1, a1                            ;addr+   

                move.w #$FF, d3
                jsr FILLBYTE
                move.w #$55, d3
                jsr FILLBYTE
                move.w #$AA, d3
                jsr FILLBYTE
                move.w #$00, d3
                jsr FILLBYTE

                move.l a2, -(sp)                        ;push return address
                rts

                FILLBYTE:
                    move.l d1, d0                       ;move loop counter to d0
                    movea.l a1, a0                      ;move start address to a0
                    BYTERWTEST:                    
                        move.b d3, (a0)                 ;write $FF
                        cmpi.b d3, (a0)                 ;read and compare
                        addi #2, a0                     ;increment
                        bne.w ERROR                     ;if not matches, goto ERROR
                        dbf d0, BYTERWTEST              ;loop
                    rts  

            ERROR:               
                move.w #1, -(sp)                        ;set error flag
                move.l a2, -(sp)                        ;push return address
                rts        


    LOADBUBBLE:                                         ;start page -> consecutive page length - > destination address -> return address
        movea.l (sp)+, a3                               ;pop return address
        move.w (sp)+, d0                                ;pop start page
        move.w (sp)+, d1                                ;pop consecutive page length
        movea.l (sp)+, a2                               ;pop destination address

        lea $40000, a1                                  ;bubble memory controller register
        subi.l #1, d1                                   ;consecutive page length - 1 

        READPAGE:
            move.w #0, $4(a1)                           ;initialize controller
            move.w d0, (a1)                             ;set page
            nop
            move.w #1, $2(a1)                           ;read page

            move.b #1, $5E008                           ;kick the watchdog
            move.b #0, $5E008

            move.w #$8000, d7
            READWAIT:
                nop
                dbf d7, READWAIT                        ;loop

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

            addi #1, d0                                 ;start page +1
            dbf d1, READPAGE

        move.l a3, -(sp)                                ;push return address
        rts 


    DRAWTILEMAP:                                        
                                                        ;Width -> Height -> VRAM priority/flip/CHARRAMADDR
                                                        ;color RAM flip/palette -> Xpos -> Ypos -> tilemap A/B -> return address
        movea.l (sp)+, a2                               ;pop return address

        move.w (sp)+, d0                                ;pop tilemap A/B(0 = A, 1 = B)
        btst.l #$0, d0                                  ;1 = TILEMAP-B 0 = TILEMAP-A
        beq.s SETTMAADDR                                ;if 0(Z=1), go to SETTMA if 1(Z=0) go to SETTMB

        SETTMBADDR:
            lea #$53000, a0                             ;ADDR offset + VRAM 2 base address
            lea #$55000, a1                             ;ADDR offset + COLOR RAM 2 base address
            bra SETPOSOFFSET

        SETTMAADDR:
            lea #$52000, a0                             ;ADDR offset + VRAM 1 base address
            lea #$54000, a1                             ;ADDR offset + COLOR RAM 1 base address

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

        
        move.w (sp)+, d3                                ;pop height
        subi #1, d3                                     ;set loop counter

        move.l #64, d5                                  ;
        sub.w (sp), d5                                  ;copy width
        lsl.l #1, d5                                    ;width * 2
        YDRAW:
            move.w (sp), d4                             ;copy width
            subi.w #1, d4                               ;set loop counter
            XDRAW:
                move.w d0, (a0)+                        ;write tile property to VRAM
                move.w d1, (a1)+                        ;write tile color to COLORRAM
                add.w #1, d0                            ;increase CHAR RAM pointer
                dbf d4, XDRAW
            add.l d5, a0                                ;set next line start address
            add.l d5, a1
            dbf d3, YDRAW

        add.l #2, sp                                    ;move stack pointer
        move.l a3, -(sp)                                ;push return address
        rts 


    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source