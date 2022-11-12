;KNIGHT-RIDER LIGHTS
CPU  "6805.TBL"   ;CPU TABLE FOR CROSS-16
HOF  "INT8"       ;HEX OUTPUT FILE
;                         ................                
;               Vss.....I-1              40-I....Reset    
;               Int.....I-2  MC68705P3   39-I......PA7    LAMP 13
;               Vcc.....I-3              38-I......PA6    LAMP 12
;               Extal...I-4              37-I......PA5    LAMP 11
;               Xtal....I-5              36-I......PA4    LAMP 10
;               Vpp.....I-6              35-I......PA3    LAMP 09
;               Timer...I-7              34-I......PA2    LAMP 08
;               PC0.....I-8              33-I......PA1    LAMP 07
;               PC1.....I-9              32-I......PA0    LAMP 06
;               PC2.....I-10             31-I......PB7    LAMP 05
;               PC3.....I-11             30-I......PB6    LAMP 04
;               PB0.....I-12             29-I......PB5    LAMP 03
;               PB1.....I-13             28-I......PB4    LAMP 02
;               PB2.....I-14.............27-I......PB3    LAMP 01
;
;MC68705P3 GLOBAL PARAMETERS
PORTA:     EQU  00H                    ;PORT A DATA REGISTER
PORTB:     EQU  01H                    ;PORT B DATA REGISTER
PORTC:     EQU  02H                    ;PORT C DATA REGISTER
PADDR:     EQU  04H                    ;PORT A DATA DIRECTION REGISTER
PBDDR:     EQU  05H                    ;PORT B DATA DIRECTION REGISTER
PCDDR:     EQU  06H                    ;PORT C DATA DIRECTION REGISTER
TDR:       EQU  08H                    ;TIMER DATA REGISTER
TCR:       EQU  09H                    ;TIMER CONTROL DATA REGISTER
RAM:       EQU  10H                    ;START OF ON CHIP RAM
STACK:     EQU  7FH                    ;STACK AREA (31 BYTES)

;CONFIGURATION SETUP        
PADEF:     EQU  11111111B              ; 1's are Outputs
PBDEF:     EQU  11111000B              ; 0's are Inputs
PCDEF:     EQU  00000000B              ; Only Bits 0-3 Used
RELOAD:    EQU  015D                   ; Timer Interrupt Reload Value 4D

;GLOBAL DEFINITIONS
OUTSIDE:   EQU  PORTB
LAMPSL:    EQU  PORTB
LAMPSR:    EQU  PORTA
LAMP1:     EQU  03D
LAMP2:     EQU  04D
LAMP3:     EQU  05D
LAMP4:     EQU  06D
LAMP5:     EQU  07D
LAMP6:     EQU  00D
LAMP7:     EQU  01D
LAMP8:     EQU  02D
LAMP9:     EQU  03D
LAMP10:    EQU  04D
LAMP11:    EQU  05D
LAMP12:    EQU  06D
LAMP13:    EQU  07D

;  RAM VARIABLES LIST
DELAYA:    EQU  RAM                    ;TIMING REFERENCE
DELAYX:    EQU  DELAYA+1               ;
TACH:      EQU  DELAYX+1               ;TACH SPEED
SPEED:     EQU  TACH+1
LAMPSEQ:   EQU  SPEED+1
LAMPOFF:   EQU  LAMPSEQ+1
LAMPNUMB:  EQU  LAMPOFF+1
BRIGHT01:  EQU  LAMPNUMB+1             ;LAMP INTENSITY VALUE BUFFER
BRIGHT02:  EQU  BRIGHT01+1
BRIGHT03:  EQU  BRIGHT02+1
BRIGHT04:  EQU  BRIGHT03+1
BRIGHT05:  EQU  BRIGHT04+1
BRIGHT06:  EQU  BRIGHT05+1
BRIGHT07:  EQU  BRIGHT06+1
BRIGHT08:  EQU  BRIGHT07+1
BRIGHT09:  EQU  BRIGHT08+1
BRIGHT10:  EQU  BRIGHT09+1
BRIGHT11:  EQU  BRIGHT10+1
BRIGHT12:  EQU  BRIGHT11+1
BRIGHT13:  EQU  BRIGHT12+1
CYCLE:     EQU  BRIGHT13+13            ;DUTY CYCLE PERCENTAGE
USERRAM:   EQU  CYCLE+1                ;START OF USER RAM
LAMPBUFF:  EQU  BRIGHT01

;SUBROUTINE VECTOR
ORG  0080H
DELAY:     JMP  DELAYS                 ;DELAY SUBROUTINE
TIMING:    JMP  TIMINGS

;SUBROUTINES
; DELAY SUBROUTINE     
; LOAD A WITH XXX mS 1-255 mS
DELAYS:    EQU  $
           STA  DELAYA                 ;SAVE A
DELAY1:    LDA  #080D                  ;LOAD FULL COUNT
           STA  DELAYX                 ;SAVE
DELAY2:    DEC  DELAYX                 ;DEC
           NOP                         ;WASTE TIME HERE
           BNE  DELAY2                 ;LOOP FOR 255 COUNT
           DEC  DELAYA                 ;ADJUST mS COUNT
           BNE  DELAY1                 ;LOOP AGAIN IF NOT DONE
           NOP                         ;WASTE TIME
           NOP                         ;
DELAY9:    RTS

;SECOND DELAY
TIMINGS:   CLR  TACH
TIMING0:   LDA  TACH
           CMP  #025D
           BLS  TIMING0
TIMING9:   RTS  ;RETURN

;MAIN PROGRAM
ORG  0100H        
PROGRAM:   CLR  TACH
           CLR  X
PROG00:    LDA  SEQTBL,X
           AND  #00001111B
           STA  LAMPBUFF,X
           INC  X
           TXA
           CMP  #13D
           BLO  PROG00
           JSR  TIMING
           CLR  X
PROG01:    LDA  SEQTBL+13,X
           AND  #00001111B
           STA  LAMPBUFF,X
           INC  X
           TXA
           CMP  #13D
           BLO  PROG01
           JSR  TIMING
PROG02:    LDA  #1D
           STA  LAMPSEQ
PROG03:    LDX  LAMPSEQ
           CLR  A
           DEC  X
           BEQ  PROG05
PROG04:    ADD  #13D
           DEC  X
           BNE  PROG04
PROG05:    STA  LAMPOFF
           CLR  LAMPNUMB
PROG06:    LDX  LAMPOFF
           LDA  LEFTSEQ,X
           AND  #00001111B
           LDX  LAMPNUMB
           STA  LAMPBUFF,X
           INC  LAMPOFF
           INC  LAMPNUMB
           LDA  LAMPNUMB
           CMP  #14D
           BLO  PROG06
           JSR  TIMING
           INC  LAMPSEQ
           LDA  LAMPSEQ
           CMP  #12D
           BLO  PROG03
PROG07:    LDA  #1D
           STA  LAMPSEQ
PROG08:    LDX  LAMPSEQ
           CLR  A
           DEC  X
           BEQ  PROG10
PROG09:    ADD  #13D
           DEC  X
           BNE  PROG09
PROG10:    STA  LAMPOFF
           CLR  LAMPNUMB
PROG11:    LDX  LAMPOFF
           LDA  RIGHTSEQ,X
           AND  #00001111B
           LDX  LAMPNUMB
           STA  LAMPBUFF,X
           INC  LAMPOFF
           INC  LAMPNUMB
           LDA  LAMPNUMB
           CMP  #14D
           BLO  PROG11
           JSR  TIMING
           INC  LAMPSEQ
           LDA  LAMPSEQ
           CMP  #12D
           BLO  PROG08
           JSR  TIMING
           BRA  PROG02

ORG 01E0H
SEQTBL:    DFB  "0000009000000"        ;START SEQUENCE
           DFB  "0000096000000"
ORG 0200H
LEFTSEQ:   DFB  "0000952000000"        ;RE-ENTRY
           DFB  "0009520000000"
           DFB  "0095200000000"
           DFB  "0952000000000"
           DFB  "9520000000000"
           DFB  "5900000000000"
           DFB  "2590000000000"
           DFB  "0259000000000"
           DFB  "0025900000000"
           DFB  "0002580000000"
           DFB  "0000258000000"
           DFB  "0000025800000"
ORG 0300H  
RIGHTSEQ:  DFB  "0000002590000"
           DFB  "0000000259000"
           DFB  "0000000025900"
           DFB  "0000000002590"
           DFB  "0000000000259"
           DFB  "0000000000095"
           DFB  "0000000000952"
           DFB  "0000000009520"
           DFB  "0000000095200"
           DFB  "0000000852000"
           DFB  "0000008520000"
           DFB  "0000085200000"

; INTERRUPT - TACHOMETER TIMING
ORG        0500H
EXTINT00:  LDA  TACH
           CMP  #255D
           BHS  EXTINT99
           INC  TACH
EXTINT99:  CLI
           RTI  ;RETURN FROM INTERRUPT
           
;TIMER INTERRUPT - DISPLAY DRIVER 
; AT 2.0MHZ   Prescale=128 (15625.0 HZ/64uS)
; TDR #RELOAD=60D   TCR = 00000111B
; CLOCK COUNTS TO 100
ORG        0600H
TMRINTS:   BCLR  7,TCR                 ;CLEAR INT REQUEST
           LDA   #RELOAD               ;RELOAD
           STA   TDR
           INC   CYCLE                 ;BUMP CYCLE COUNTER
           LDA   CYCLE
           CMP   #10D 
           BLS   TMRINT00
           CLR   CYCLE
           INC   CYCLE
TMRINT00:  LDA   CYCLE
           CMP   BRIGHT01              ;START @ TOP OF LAMP BUFFER
           BLS   TMRINT01
           BCLR  LAMP1,LAMPSL
           BRA   TMRINT02
TMRINT01:  BSET  LAMP1,LAMPSL
TMRINT02:  CMP   BRIGHT02
           BLS   TMRINT03
           BCLR  LAMP2,LAMPSL
           BRA   TMRINT04
TMRINT03:  BSET  LAMP2,LAMPSL
TMRINT04:  CMP   BRIGHT03
           BLS   TMRINT05
           BCLR  LAMP3,LAMPSL
           BRA   TMRINT06
TMRINT05:  BSET  LAMP3,LAMPSL
TMRINT06:  CMP   BRIGHT04
           BLS   TMRINT07
           BCLR  LAMP4,LAMPSL
           BRA   TMRINT08
TMRINT07:  BSET  LAMP4,LAMPSL
TMRINT08:  CMP   BRIGHT05
           BLS   TMRINT09
           BCLR  LAMP5,LAMPSL
           BRA   TMRINT10
TMRINT09:  BSET  LAMP5,LAMPSL
TMRINT10:  CMP   BRIGHT06
           BLS   TMRINT11
           BCLR  LAMP6,LAMPSR
           BRA   TMRINT12
TMRINT11:  BSET  LAMP6,LAMPSR
TMRINT12:  CMP   BRIGHT07
           BLS   TMRINT13
           BCLR  LAMP7,LAMPSR
           BRA   TMRINT14
TMRINT13:  BSET  LAMP7,LAMPSR
TMRINT14:  CMP   BRIGHT08
           BLS   TMRINT15
           BCLR  LAMP8,LAMPSR
           BRA   TMRINT16
TMRINT15:  BSET  LAMP8,LAMPSR
TMRINT16:  CMP   BRIGHT09
           BLS   TMRINT17
           BCLR  LAMP9,LAMPSR
           BRA   TMRINT18
TMRINT17:  BSET  LAMP9,LAMPSR
TMRINT18:  CMP   BRIGHT10
           BLS   TMRINT19
           BCLR  LAMP10,LAMPSR
           BRA   TMRINT20
TMRINT19:  BSET  LAMP10,LAMPSR
TMRINT20:  CMP   BRIGHT11
           BLS   TMRINT21
           BCLR  LAMP11,LAMPSR
           BRA   TMRINT22
TMRINT21:  BSET  LAMP11,LAMPSR
TMRINT22:  CMP   BRIGHT12
           BLS   TMRINT23
           BCLR  LAMP12,LAMPSR
           BRA   TMRINT24
TMRINT23:  BSET  LAMP12,LAMPSR
TMRINT24:  CMP   BRIGHT13
           BLS   TMRINT25
           BCLR  LAMP13,LAMPSR
           BRA   TMRINT99
TMRINT25:  BSET  LAMP13,LAMPSR
TMRINT99:  CLI
           RTI  ;RETURN FROM INTERRUPT
           
;SYSTEM INITIALIZATION ROUTINE
ORG        0700H        
INITSYS:   RSP                         ;RESET STACK POINTER
INIT0:     CLR  PORTA                  ;CLEAR ALL PORT DATA
           CLR  PORTB                  ;
           CLR  PORTC                  ;
           LDA  #PADEF                 ;DEFINE PORT A
           STA  PADDR                  ;
           LDA  #PBDEF                 ;DEFINE PORT B
           STA  PBDDR                  ; 
           LDA  #PCDEF                 ;DEFINE PORT C
           STA  PCDDR                  ;
           LDX  #USERRAM-RAM           ;LOAD # OF BYTES
XFER:      CLR  RAM,X                  ;CLEAR ADDRESS
           DECX                        ;BUMP INDEX
           BNE  XFER                   ;LOOP TIL DONE
           LDA   #00000111B            ;SETUP TCR
           STA   TCR
           LDA   #RELOAD               ;RELOAD COUNT
           STA   TDR
           CLI
           JMP  PROGRAM

;  MASK OPTION REGISTER
MOR:       ORG  0784H        
           DFB  07H                    ;EPROM DATA

;INTERRUPT VECTOR BYTES
TIRQVEC:   ORG  07F8H
           DWM  0600H                  ;
EIRQVEC:   ORG  07FAH
           DWM  0500H                  ;
SWIRQVEC:  ORG  07FCH
           DWM  0700H                  ;
RESETVEC:  ORG  07FEH
           DWM  0700H                  ;
END

