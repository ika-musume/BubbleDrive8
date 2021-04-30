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
    or.w d2, d3                                         ;save test result in d3[0]
     
    move.w #1, -(sp)                                    ;character RAM test
    move.l #$30000, -(sp)                
    move.l #$10000, -(sp)                   
    jsr RAMTEST                  
    lsl.w #1, d2                 
    or.w d2, d3                                         ;save test result in d3[1]
     
    move.w #0, -(sp)                                    ;scroll RAM test
    move.l #$50000, -(sp)                
    move.l #$1000, -(sp)                   
    jsr RAMTEST                  
    lsl.w #2, d2             
    or.w d2, d3                                         ;save test result in d3[2]

    move.w #1, -(sp)                                    ;tilemap RAM test
    move.l #$52000, -(sp)                
    move.l #$2000, -(sp)                   
    jsr RAMTEST                  
    lsl.w #3, d2             
    or.w d2, d3                                         ;save test result in d3[3]

    move.w #0, -(sp)                                    ;tile color RAM test
    move.l #$52000, -(sp)                
    move.l #$2000, -(sp)                   
    jsr RAMTEST                  
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




    lea $52900, a0
    lea $54901, a1
    move.w #$F000, d0
    move.b #$00, d1

    move.w #11, d3
    YDRAW:
        move.w #11, d4
        XDRAW:
            move.w d0, (a0)
            move.b d1, (a1)
            add.w #1, d0
            add.l #2, a0
            add.l #2, a1
            dbf d4, XDRAW
        sub.l #24, a0
        sub.l #24, a1
        add.l #128, a0
        add.l #128, a1
        dbf d3, YDRAW

    

    END:
    move.w #$20, d6
    READWAIT0:
        move.b #1, $5E008                                   ;kick the watchdog
        move.b #0, $5E008
        move.w #$8000, d7
        READWAIT1:
            nop
            dbf d7, READWAIT1                        ;loop
        dbf d6, READWAIT0                  ;loop
    jmp END     
    

    
    RAMTEST:                                            ;bit width flag,start address/test length/return address
        movea.l (sp)+, a2                               ;pop return address
        move.l (sp)+, d1                                ;pop test length
        movea.l (sp)+, a1                               ;pop start address
        move.w (sp)+, d2                                ;pop bit width fla  

        lsr.l #1, d1                                    ;divide by 2
        subi.l #1, d1                                   ;test length - 1       
        btst.l #$0, d2                                  ;1 = WORDTEST 0 = BYTETEST
        bne.w WORDTEST                                  ;Z = 1 then goto BYTETEST if not then goto WORDTEST

            WORDTEST:            
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILLFFFF:                  
                    move.w #$FFFF, (a0)                 ;write $FFFF
                    cmpi.w #$FFFF, (a0)+                ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILLFFFF                    ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILL5555:            
                    move.w #$5555, (a0)                 ;write $5555
                    cmpi.w #$5555, (a0)+                ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILL5555                    ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILLAAAA:            
                    move.w #$AAAA, (a0)                 ;write $AAAA
                    cmpi.w #$AAAA, (a0)+                ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILLAAAA                    ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILL0000:            
                    move.w #$0000, (a0)                 ;write $0000
                    cmpi.w #$0000, (a0)+                ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILL0000                    ;loo          
                move.l a2, -(sp)                        ;push return address
                rts       

            BYTETEST:            
                add.l #1, a1                            ;addr+         
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILLFF:                    
                    move.b #$FF, (a0)                   ;write $FF
                    cmpi.b #$FF, (a0)+                  ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILLFF                      ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILL55:                    
                    move.b #$55, (a0)                   ;write $55
                    cmpi.b #$55, (a0)+                  ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILL55                      ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILLAA:                    
                    move.b #$AA, (a0)                   ;write $AA
                    cmpi.b #$AA, (a0)+                  ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILLAA                      ;loop          
                move.l d1, d0                           ;move loop counter to d0
                movea.l a1, a0                          ;move start address to a0
                FILL00:                    
                    move.b #$00, (a0)                   ;write $00
                    cmpi.b #$00, (a0)+                  ;read and compare
                    bne.w ERROR                         ;if not matches, goto ERROR
                    dbf d0, FILL00                      ;loop          
                move.l a2, -(sp)                        ;push return address
                rts

            ERROR:               
                move.w #1, d2                           ;set error flag
                move.l a2, -(sp)                        ;push return address
                rts        





    LOADBUBBLE:                                         ;start page/consecutive page length/destination address
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

    SIMHALT             ; halt simulator

* Put variables and constants here

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
