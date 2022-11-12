TIT "E-Z80A MicroController BIOS
CPU "Z80.TBL"
HOF "INT8"
;Written by D.Boyce PCBoardRepair on YouTube email:pcboardrepair@gmail.com
;**********************************************************
; Z80A PLUS MICRO CONTROLLER PCB
; 8K OF PROGRAM ROM     LOCATED AT 0000H TO 1FFFH
; 16K OF USER DATA               - 2000H TO 3FFFH AND 4000H TO 5FFFH
; 8K OF CMOS STATIC RAM          - 6000H TO 7FFFH
; 32 KEY KEYBOARD
; LCD OUT COMPATIABLE WITH 
; 48 I/O DATA LINES     6 PLUGS  8Bit WIDE
;  8 ANALOG INPUTS      8 BIT RESOLUTION
;  8 LOCATION EXPANSION I/O SOCKET
;
;**********************************************************
;EQUATES
;SYSTEM DEFINITIONS
STACK:    EQU   8000H                  ;LOCATION OF STACK POINTER AT TOP OF RAM
RAM:      EQU   6000H                  ;START OF RAM   8K TOTAL  
RAMTEST:  EQU   617FH                  ;RAM TEST LOCATION
BEEPTIME: EQU   30D                    ;BEEP ON TIME
;PIO 8255A #1 KEY PAD / DISPLAY PORTS
KEYIN:    EQU   00H                    ;KEY INPUT
LCDDATA:  EQU   01H                    ;LCD DATA OUTPUTS
LCDCHIP:  EQU   02H                    ;LCD CHIP CONTROL LINES
SCAN:     EQU   02H                    ;KEY SCAN OUTPUTS
PIO1CW:   EQU   03H                    ;PIO 8255A #1 CONTROL WORD
CW1:      EQU   90H                    ;SETUP VALUE
;PIO 8255A #2 PORT PLUG #1 TO #3
PLUG1:    EQU   08H                    ;PIO 8255A #2 PORT A
PLUG2:    EQU   0AH                    ;PIO 8255A #2 PORT C
PLUG3:    EQU   09H                    ;PIO 8255A #2 PORT B
PIO2CW:   EQU   0BH                    ;PIO 8255A #2 CONTROL WORD
CW2:      EQU   80H                    ;SETUP VALUE
;PIO 8255A #3 PORT PLUG #4 TO #6
PLUG4:    EQU   10H                    ;PIO 8255A #3 PORT A
PLUG5:    EQU   12H                    ;PIO 8255A #3 PORT C
PLUG6:    EQU   11H                    ;PIO 8255A #3 PORT B
PIO3CW:   EQU   13H                    ;PIO 8255A #3 CONTROL WORD
CW3:      EQU   80H                    ;SETUP VALUE
;A/D CONVERTOR   8 CHANNELS
ADCADDR:  EQU   18H                    ;8 BIT A/D CH. 1-8  WR/START RD/DATA
;EXPANSION SOCKET / DIAGNOSTICS
EXPAND:   EQU   20H                    ;EXPANSION   0-7 RD/WR 8BIT PORT
;
;RAM BREAKDOWN
CLOCK:    EQU   RAM                    ;CLOCK TICK
BINARY:   EQU   CLOCK+1                ;BINARY DATA
BCDDATA:  EQU   BINARY+1               ;BCD DATA BYTES  (3)
ASCDATA:  EQU   BCDDATA+3              ;ASCII DATA BYTES (3)
LCDSCAN:  EQU   ASCDATA+3              ;LCD KEY SCAN 0-3 LCD  4-7 LCD
KEYDATA:  EQU   LCDSCAN+1              ;KEYDATA ON EXIT OF KEYSCAN
DIGNUM:   EQU   KEYDATA+1              ;LCD DIGIT NUMBER
LCDBUFF:  EQU   DIGNUM+1               ;LCD BUFFER 40 BYTES
USERRAM:  EQU   LCDBUFF+40             ;USER RAM START
;EPROM 0000H -RESET VECTOR LOCATION
          ORG   0000H                  ;START OF EPROM 0
          JP    RESET                  ;RESET VECTOR
;SUBROUTINE VECTOR
DELAY:    JP    DELAYS
BINBCD:   JP    BINBCDS
BCDASC:   JP    BCDASCS
KEYSCAN:  JP    KEYSCANS
LCDINIT:  JP    LCDINITS
LCDCTRL:  JP    LCDCTRLS
LCDCHAR:  JP    LCDCHARS
LCDHOME:  JP    LCDHOMES    
BEEP:     JP    BEEPS
DISPLAY:  JP    DISPLAYS
MESSAGE:  JP    DISPMESS
          RET

          ORG   0038H 
;EPROM 003H -RESTART LOCATION
          RET

;EPROM 0066H -NMI VECTOR LOCATION
          ORG   0066H
          JP    NMIHAND                ;GO PROCESS NMI

;
;INITIALIZE ALL SYSTEM COMPONENTS
;INITIALIZE STACK
          ORG   0100H                  ;
RESET:    LD    SP,#STACK
INTOFF:   DI                           ;DISABLE INTERRUPT
TESTRAM:  LD    HL,#RAMTEST            ;LOAD LOCATION FOR RAM TEST
          LD    A,#01010101B           ;LOAD #55H
          LD    (HL),A                 ;WRITE TO LOCATION
          NOP                          ;WAIT
          NOP                          ;
          LD    A,(HL)                 ;LOAD DATA FROM LOCATION
          CP    #01010101B             ;TEST FOR CORRECT DATA
          JP    NZ,RAMFAIL             ;RAM TEST HAS FAILED
          LD    A,#10101010B           ;LOAD #AAH
          LD    (HL),A                 ;WRITE TO LOCATION
          NOP                          ;WAIT
          NOP                          ;
          LD    A,(HL)                 ;LOAD DATA FROM LOCATION
          CP    #10101010B             ;TEST FOR CORRECT DATA
          JP    NZ,RAMFAIL             ;RAM TEST HAS FAILED
          JP    LOADRAM                ;CONTINUE TEST PASSED
RAMFAIL:  HALT                         ;HALT
          JP    RAMFAIL                ;LOOP HERE
;LOAD RAM DEFAULTS
LOADRAM:  EQU   $
          LD    HL,#DEFAULTS           ;LOAD ROM START
          LD    DE,#RAM                ;RAM VARIABLES
          LD    BC,#DEFNUM             ;LOAD SIZE FOR DEFAULT DATA
          LDIR                         ;TRANSFER
;INIT I/O DEVICES
INITPIO:  LD    A,#CW1                 ;LOAD CONTROL WORD FOR 8255
          OUT   (PIO1CW),A             ;SET UP IO
          LD    A,#CW2                 ;LOAD CONTROL WORD FOR 8255
          OUT   (PIO2CW),A             ;SET UP IO
          LD    A,#CW3                 ;LOAD CONTROL WORD FOR 8255
          OUT   (PIO3CW),A             ;SET UP IO
          XOR   A                      ;CLEAR A
          OUT   (PLUG1),A              ;ZERO ALL LINES
          OUT   (PLUG2),A              ;
          OUT   (PLUG3),A              ;
          OUT   (PLUG4),A              ;
          OUT   (PLUG5),A              ;
          OUT   (PLUG6),A              ;
;EXERCISE ADC
ADCTEST:  OUT   (ADCADDR),A            ;START CONVERSION
          NOP                          ;WAIT
          NOP                          ;
          IN    A,(ADCADDR)            ;GET RESULT
;EXIT TO REAL WORLD FUNCTIONS
          CALL  BEEP                   ;BEEP ONCE
          CALL  LCDINIT                ;INITIALIZE LCD DISPLAY
          LD    A,#01H                 ;DISPLAY OPENING MESSAGE #1
          CALL  MESSAGE                ;
          LD    HL,#5000D              ;DELAY 1 SEC.
          CALL  DELAY                  ;
          JP    START                  ;GO FOR PROGRAM
;
;EPROM DEFAULT VALUES FOR RAM INITIZATION
          ORG   0180H
DEFAULTS: EQU   $                      ;EXPLAIN DEFAULT REFERENCES HERE
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
          DFB   00H                    ;
DEFNUM:   EQU   $-DEFAULTS
          ORG   0200H                  ;PROGRAM LOCATION 0200H-02FFH
;
START:    EQU   $
          LD    A,#2D                  ;DISPLAY MESSAGE 2
          CALL  MESSAGE                ;
PROG00:   CALL  KEYSCAN
          LD    A,(KEYDATA)
          OUT   (PLUG1),A
          LD    A,(KEYDATA)
          OR    A
          JR    Z,PROG01 
          CALL  MESSAGE   
          LD    A,(KEYDATA)
          CALL  BINBCD
          CALL  BCDASC
          LD    HL,#ASCDATA
          LD    DE,#LCDBUFF+36
          LD    BC,#3D
          LDIR
          LD    A,(KEYDATA)
          LD    (LCDBUFF+20),A
          CALL  DISPLAY
PROG01:   LD    HL,#500D 
          CALL  DELAY
          JR    PROG00


;NMI INTERRUPT HANDLER
          ORG   0300H                  ;NMI PROGRAM LOCATION 0300H-03FFH
;
NMIHAND:  EQU   $
          RETI
;
;SUBROUTINES
          ORG   0400H
;*
; DELAY
;LOAD HL WITH # OF MILLISECONDS DELAY
;CALL DELAY
DELAYS:   EQU   $
          LD    DE,#-1D                ;DECREMENT VALUE
DEL05:    LD    B,#04AH                ;FINAGLE FACTOR
          ADD   HL,DE                  ;DEC HL COUNT
          RET   NC                     ;RETURN IF DONE
DEL10:    DJNZ  DEL10                  ;INNER DELAY LOOP
          DEC   IY                     ;WASTE TIME
          JP    DEL05                  ;RETURN TO OUTER LOOP
; 
; BINARY TO BCD DATA CONVERT
; LOAD A WITH BINARY DATA  THEN CALL  
;
BINBCDS:  EQU   $
          LD    (BINARY),A             ;SAVE
          LD    H,#00H                 ;SET UP POINTER
          LD    L,A                    ;
          LD    IX,#BCDDATA            ;BCD DATA BUFFER
          LD    IY,#BTABL              ;TABLE OF CONSTANTS
BIN05:    LD    B,#0FFH                ;INIT BCD DIGIT
          LD    E,(IY+0)               ;GET POWER OF TEN
          LD    D,(IY+1)               ;MS BYTE
          BIT   7,D                    ;TEST SIGN BIT
          RET   NZ                     ;RETURN IF DONE
BIN10:    INC   B                      ;BUMP BYTE COUNT
          OR    A                      ;CLEAR CARRY
          SBC   HL,DE                  ;SUBTRACT POWER
          JR    NC,BIN10               ;CONTINUE IF POSITIVE
          ADD   HL,DE                  ;RESTORE RESIDUE
          LD    (IX+0),B               ;STORE DIGIT
          INC   IX                     ;BUMP POINTERS
          INC   IY                     ;
          INC   IY                     ;
          JR    BIN05                  ;CONTINUE
BTABL:    DWL   100D                   ;TABLE OF POWERS
          DWL   10D                    ;
          DWL   1D                     ;
          DWL   -1D                    ;END OF TABLE
; 
; BCD DATA TO ASCII CHAR CONVERT
; CONVERTS WHAT IN BCDDATA BUFFER TO ASCDATA BUFFER
;
BCDASCS:  EQU   $
          LD    HL,#BCDDATA           ;POINT TO BCD
          LD    DE,#ASCDATA           ;POINT TO ASCII
          LD    A,(HL)                ;LOAD FIRST BYTE
          AND   #00001111B            ;
          OR    #00110000B            ;
          LD    (DE),A                ;SAVE
          INC   HL                    ;ADJUST POINTERS
          INC   DE                    ;
          LD    A,(HL)                ;LOAD FIRST BYTE
          AND   #00001111B            ;
          OR    #00110000B            ;
          LD    (DE),A                ;SAVE
          INC   HL                    ;ADJUST POINTERS
          INC   DE                    ;
          LD    A,(HL)                ;LOAD FIRST BYTE
          AND   #00001111B            ;
          OR    #00110000B            ;
          LD    (DE),A                ;SAVE
          RET
;*
;KEYPAD TEST
;
KEYSCANS: EQU   $
          LD    B,#00010000B           ;LOAD SCAN BIT MASK BYTE
          LD    A,#00D                 ;ZERO A
          LD    (KEYDATA),A            ;
          LD    C,A                    ;CLEAR KEY COUNT TO ZERO
KEYSCAN0: LD    A,(LCDSCAN)            ;GET PORT DATA
          AND   #00001111B             ;MASK IN ZERO'S
          OR    B                      ;ADD IN SCAN BYTE
          LD    (LCDSCAN),A            ;SAVE COPY
          OUT   (SCAN),A               ;SEND SCAN TO PIO DEVICE
          NOP                          ;WAIT
          NOP                          ;
          IN    A,(KEYIN)              ;READ KEY INPUTS
          OR    A                      ;TEST
          JP    NZ,KEYSCAN3            ;JUMP IF KEY DOWN
KEYSCAN1: LD    A,C                    ;ADJUST COUNT
          ADD   A,#08D                 ;+8
          LD    C,A                    ;SAVE NEW COUNT
          SLA   B                      ;SHIFT SCAN BYTE MASK
          JP    NZ,KEYSCAN0            ;LOOP IF NOT DONE YET
KEYSCAN2: XOR   A                      ;CLEAR A
          LD    (KEYDATA),A            ;SAVE NO KEY
          JP    KEYSCAN9               ;
KEYSCAN3: INC   C                      ;BUMP COUNT
          SRL   A                      ;SHIFT KEY INPUT RIGHT
          JR    NZ,KEYSCAN3            ;LOOP UNTIL ZERO
          LD    A,C                    ;GET KEY COUNT
          LD    (KEYDATA),A            ;SAVE 
          CALL  BEEP                   ;BEEP
KEYSCAN9: LD    A,(LCDSCAN)            ;GET PORT DATA
          AND   #00001111B             ;MASK IN ZERO'S
          LD    (LCDSCAN),A            ;SAVE COPY
          OUT   (SCAN),A            ;SEND SCAN TO PIO DEVICE
          RET   
;
; LCD INITIALIZATION ROUTINE
;
LCDINITS: EQU   $
          LD    HL,#50D                ;DELAY 15 MS
          CALL  DELAY
          LD    A,#CLEAR               ;CLEAR DISPLAY
          CALL  LCDCTRL                ;
          LD    A,#HOME                ;HOME CURSOR
          CALL  LCDCTRL                ;
          LD    A,#FUNC                ;SETUP LCD FUNCTIONS
          CALL  LCDCTRL                ;
          LD    A,#SHIFT               ;SHIFT DISPLAY
          CALL  LCDCTRL                ;
          LD    A,#NORMAL              ;DISPLAY ON
          CALL  LCDCTRL                ;
          RET
;
;CONTROL WORDS FOR LCD CONTROLLER 44780
CLEAR:    EQU   01H                    ;LCD CLEAR DISPLAY
HOME:     EQU   02H                    ;LCD HOME
FUNC:     EQU   00110011B              ;8 BIT/1 LINE/5X7
SHIFT:    EQU   00000110B              ;CURSOR SHIFT
NORMAL:   EQU   00001110B              ;DISPLAY ON/WITH CURSOR/NO BLINK
;
; LCD CONTROL WORD WRITE
; SET UP A WITH CONTROL WORD
LCDCTRLS: EQU   $
          OUT   (LCDDATA),A            ;SEND WORD TO DATA BUS
          LD    A,(LCDSCAN)            ;GET CURRENT DATA
          AND   #11110001B             ;ENABLE ON
          OR    #00000010B             ;
          LD    (LCDSCAN),A            ;SAVE
          OUT   (LCDCHIP),A            ;SEND TO PORT
          AND   #11110001B             ;ENABLE OFF
          LD    (LCDSCAN),A            ;SAVE
          OUT   (LCDCHIP),A            ;SEND TO PORT
          LD    HL,#2D                 ;DELAY 2MS
          CALL  DELAY                  ;
          XOR   A                      ;ZERO DATA BUS
          OUT   (LCDDATA),A            ;
          RET
;
; LCD DISPLAY DATA WRITE
; SET UP A WITH DATA WORD
LCDCHARS: EQU   $
          OUT   (LCDDATA),A            ;SEND WORD TO DATA BUS
          LD    A,(LCDSCAN)            ;GET CURRENT DATA
          AND   #11110001B             ;ENABLE ON
          OR    #00001000B             ;
          LD    (LCDSCAN),A            ;SAVE
          OUT   (LCDCHIP),A            ;SEND TO PORT
          OR    #00000010B             ;
          LD    (LCDSCAN),A            ;SAVE
          OUT   (LCDCHIP),A            ;SEND TO PORT
          AND   #11110001B             ;ENABLE OFF
          LD    (LCDSCAN),A            ;SAVE
          OUT   (LCDCHIP),A            ;SEND TO PORT
          LD    HL,#2D                 ;DELAY 2MS
          CALL  DELAY                  ;
          XOR   A                      ;ZERO DATA BUS
          OUT   (LCDDATA),A            ;
          RET
;
; LCD HOME CURSOR ROUTINE
;
LCDHOMES: EQU   $
          LD    A,#HOME                ;HOME CURSOR
          CALL  LCDCTRL                ;
          RET
;
;BEEP GENERATION
;
BEEPS:    EQU   $
          LD    A,(LCDSCAN)            ;GET PORT DATA
          AND   #11111110B             ;MASK IN ZERO'S
          OR    #00000001B             ;TURN ON BEEP
          LD    (LCDSCAN),A            ;SAVE COPY
          OUT   (SCAN),A               ;SEND SCAN TO PIO DEVICE
          LD    HL,#BEEPTIME           ;LOAD DELAY
          CALL  DELAY                  ;
          LD    A,(LCDSCAN)            ;GET PORT DATA
          AND   #11111110B             ;MASK IN ZERO'S
          LD    (LCDSCAN),A            ;SAVE COPY
          OUT   (SCAN),A               ;SEND SCAN TO PIO DEVICE
          RET
;
;DISPLAY INFORMATION IN LCD BUFFER
;
DISPLAYS: EQU   $
          CALL  LCDHOME                ;
;SEND LCD BUFFER TO LCDDATA PORT BY CALLING LCDCHAR
          LD    A,#40D                 ;LOAD BYTE COUNT
          LD    (DIGNUM),A             ;
          LD    HL,#LCDBUFF            ;POINT TO BUFFER
DISP0:    LD    A,(HL)                 ;GET DATA
          PUSH  HL
          PUSH  DE 
          CALL  LCDCHAR                ;SEND OUT OT DISPLAY
          POP   DE
          POP   HL
          INC   HL                     ;BUMP BUFFER POINTER
          LD    A,(DIGNUM)             ;ADJUST COUNT
          DEC   A                      ;
          LD    (DIGNUM),A             ;SAVE NEW COUNT
          OR    A
          JR    NZ,DISP0               ;LOOP UNTIL DONE
          RET                          ;RETURN
;
;DISPLAY MESS FROM MESSAGE TABLE IN FROM ROM0
;LOAD A WITH MESSAGE #
DISPMESS: EQU   $
          LD    B,A                    ;GET MESSNUM IN B
          LD    HL,#MESSTBL            ;SET UP POINTER
          LD    DE,#040D               ;LOAD OFFSET
          DEC   B                      ;ADJUST COUNT SO 1=0
          JR    Z,MOVECHR              ;IF ZERO ALREADY JUMP OVER ADD
ADJUST:   ADD   HL,DE                  ;ADD OFFSET IN DE
          DEC   B                      ;
          JR    NZ,ADJUST              ;
MOVECHR:  LD    DE,#LCDBUFF            ;SET POINTER TO DESTINATION
          LD    BC,#40D                ;LOAD BYTE COUNT
          LDIR                         ;TRANSFER
          CALL  DISPLAY                ;
          RET                          ;RETURN
;
MESSTBL:  DFB   " E-Z80A MicroController with User BIOS  "
          DFB   " Designed and Built by David Carl Boyce "
          DFB   " Diagnostic Screen 1                    "
          DFB   "Start Execution @ Address 0000H (Y/N)?  "
          DFB   "Edit Data @ Address 0000H=FFH [FFH]     "
          DFB   "Show Data @ Address 0000H=FFH           "
          DFB   "Set Address Counter [0000H] FFFFH       "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "                                        "
          DFB   "This BIOS Version is 1.01HB     12/05/94"
END
