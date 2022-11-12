TITL "6809 CPU CONTROLLER"             ;HD6809P MICRO-CONTROLLER
CPU  "6809.TBL"                        ;CPU TABLE FOR CROSS-16
HOF  "INT8"                            ;HEX OUTPUT FILE
;0000H-1FFFH... I/O PORTS              ;MEMORY MAP
;Written by D.Boyce PCBoardRepair on YouTube email:pcboardrepair@gmail.com
;2000H-3FFFH... 8Kx8 STATIC RAM
;4000H-5FFFH... NOT USED
;6000H-7FFFH... NOT USED
;8000H-9FFFH... NOT USED
;A000H-BFFFH... NOT USED
;C000H-DFFFH... NOT USED
;E000H-EFFFH... 8KX8 MAIN EPROM
;SYSTEM SETUP
ROMADDR:   EQU   0E000H                ;ROM ADDRESS OFFSET
PORTA:     EQU   0000H                 ;PORT A
PORTB:     EQU   0001H                 ;PORT B
PORTC:     EQU   0002H                 ;PORT C
PIOCW1:    EQU   0003H                 ;8255 A CONTROL WORD
RAM:       EQU   2000H                 ;RAM ADDRESS
STACK:     EQU   3FFFH                 ;HARDWARE STACK POINTER
;GLOABAL VARIABLES
DOTS:      EQU   PORTA                 ;DOT PORT
SHIFT:     EQU   PORTB                 ;74LS164 SHIFT CHAIN

;RAM VARIABLES LIST
SYSTEMUP:  EQU   RAM                   ;SYSTEM IS UP!
DELAYA:    EQU   SYSTEMUP+1            ;DELAY TIMING
DELAYX:    EQU   DELAYA+1              ;
DISPPOS:   EQU   DELAYX+1              ;DISPLAY DECODER POSITION
DISPBUFF:  EQU   DISPPOS+1             ;DISPLAY BUFFER
DOTNUMB:   EQU   DISPBUFF+DISPSIZE     ;16BIT ADDRESS FOR DISPLAY OFFSET
DOTBUFF:   EQU   DOTNUMB+1             ;DISPLAY DOTS BUFFER
USERRAM:   EQU   DOTBUFF+DOTLENGTH     ;START OF USER RAM
DOTLENGTH: EQU   30D
DISPSIZE:  EQU   6D

ORG 1000H  ;[F000H]
PROGRAM:   EQU   $+ROMADDR             ;START OF MAIN PROGRAM AREA
           CLR   DISPBUFF
PROG00:    LDA   DISPBUFF
           STA   PORTC
           JSR   DISPLAY
           LDA   #100D
           JSR   DELAY
           INC   DISPBUFF
           BRA   PROG00
WAITHERE:  BRA   WAITHERE              ;

ORG 1800H  ;[F800H]
;SUBROUTINES
; DELAY SUBROUTINE   80H=OK
; LOAD A WITH XXX mS 1-255mS
DELAY:     EQU   $+ROMADDR
           STA   DELAYA                ;DEC
DELAY1:    LDA   #067D                 ;LOAD FULL COUNT
           STA   DELAYX                ;SAVE
DELAY2:    DEC   DELAYX                ;DEC
           NOP                         ;WASTE TIME HERE
           BNE   DELAY2                ;LOOP FOR 255 COUNT
           DEC   DELAYA                ;ADJUST mS COUNT
           BNE   DELAY1                ;LOOP AGAIN IF NOT DONE
           NOP                         ;WASTE TIME
           NOP                         ;
DELAY9:    RTS

;DISPLAY DATA IN BUFFER
;CONVERTS VALUES IN DISPBUFF INTO DOTS IN DOTBUFF
DISPLAY:   EQU   $+ROMADDR
           CLR   DISPPOS               ;START AT FIRST
DISPLAY0:  LDA   DISPPOS               ;LOAD OFFSET INTO DISPLAY
           LDB   #05D                  ;LOAD MODULO
           MUL                         ;MULTIPLY
           ADDD  #DOTBUFF
           TFR   D,Y                   ;SET Y FOR DOT BUFFER INDEX
           LDB   DISPPOS               ;LOAD OFFSET IN B
           LDX   #DISPBUFF             ;LOAD INDEX IN X
           ABX                         ;GET DATA
           LDA   ,X                    ;GET CURRENT VALUE
           LDB   #05D                  ;LOAD MODULO
           MUL                         ;MULTIPLY
           ADDD  #CHARTBL
           TFR   D,X                   ;PLACE IN REGISTER
           LDB   #5D                   ;NEED NEXT 5 BYTES IN CHAR. TABLE
DISPLAY1:  LDA   ,X+                   ;GET DOT PATTERN
           STA   ,Y+                   ;SAVE IT IN DOT BUFFER
           DEC   B                     ;ADJUST BYTE COUNT
           BNE   DISPLAY1              ;LOOP UNTIL DONE
           INC   DISPPOS               ;POSITION
           LDA   DISPPOS               ;CHECK VALUE
           CMPA  #06D
           BLO   DISPLAY0
DISPLAY9:  RTS   ;RETURN FROM SUBROUTINE

MSGTBL:    EQU   $+ROMADDR
           DFB   "Time"
           DFB   "Date"
           DFB   "MonTueWedThuFriSatSun"


ORG 1F00H  ;[FF00H]
;NON-MASKABLE INTERRUPT ROUTINE
NMI:       TST   SYSTEMUP              ;WAIT FOR SYSTEM TO BE READY
           BEQ   NMIRTI                ;
           LDA   #0D                   ;TURN OFF ROW DATA
           STA   DOTS                  ;
           LDB   DOTNUMB               ;LOAD CURRENT POSITION IN B
           LDX   #ROWTBL               ;POINT TO COLUMN DATA TABLE
           ABX                         ;ADD TOGETHER
           LDA   ,X                    ;LOOKUP COLUMN DATA
           STA   SHIFT                 ;PLACE ON PORT
           LDB   DOTNUMB               ;LOAD CURRENT POSITION IN B
           LDX   #DOTBUFF              ;POINT TO DOT BUFFER
           ABX                         ;ADD TOGETHER
           LDA   ,X                    ;LOOK UP DOT DATA
           STA   DOTS                  ;LATCH AS ROWS
           INC   DOTNUMB               ;ADJUST POSITION
           LDA   DOTNUMB
           CMPA  #05D
           BLO   NMIRTI
           CLR   DOTNUMB
NMIRTI:    RTI

ROWTBL:    EQU   $+ROMADDR
           DFB   11111110B
           DFB   11111101B
           DFB   11111011B
           DFB   11110111B
           DFB   11101111B
           DFB   11011111B
           DFB   10111111B
           DFB   01111111B

ORG 1F80H  ;[FF80H]
;START OF SYSTEM INITIALIZATION
INITIO:    LDS   #STACK                ;INITIALIZE HARDWARE STACK POINTER
           CLR   SYSTEMUP      
           LDA   #080H                 ;INITIALIZE PROGRAMMABLE I/O DEVICE
           STA   PIOCW1                ;
CLRRAM:    LDX   #RAM                  ;POINT TO MEMORY LOCATION
           LDB   #USERRAM-RAM          ;SPECIFY # OF BYTES USED
           CLR   A                     ;ZERO A
CLRRAM0:   STA   ,X+                   ;ZERO DATA AT INDEX LOCATION
           DEC   B                     ;ADJUST 
           BNE   CLRRAM0               ;LOOP UNTIL COMPLETED ALL
           LDA   #00011111B            ;INITIAL 74LS164 PORT
           STA   PORTB
           CLR   DOTNUMB
           LDA   #0FFH                 ;INDICATE THE SYSTEM IS UP AND RUNNING
           STA   SYSTEMUP
           JMP   PROGRAM               ;START MAIN ROUTINE
           
ORG 1FF0H  ;RESERVED
           DWM  00000H
ORG 1FF2H  ;SOFTWARE INTERRUPT 3   (SWI3)
           DWM  00000H
ORG 1FF4H  ;SOFTWARE INTERRUPT 2   (SWI2)
           DWM  00000H
ORG 1FF6H  ;FAST INTERRUPT REQUEST (FIRQ)
           DWM  00000H
ORG 1FF8H  ;INTERRUPT REQUEST      (IRQ)
           DWM  00000H
ORG 1FFAH  ;SOFTWARE INTERRUPT 1   (SWI1)
           DWM  00000H
ORG 1FFCH  ;NON-MASKABLE INTERRUPT (NMI)
           DWM  0FF00H
ORG 1FFEH  ;RESET VECTOR           (RESET)
           DWM  0FF80H

ORG 0000H ;[E000H]
CHARTBL:  EQU   $+ROMADDR
          DFB   3FH,3FH,3FH,3FH,3FH    ;0  -00H
          DFB   2AH,55H,2AH,55H,2AH    ;1  -01H
          DFB   01H,00H,00H,00H,00H    ;2  -02H
          DFB   02H,00H,00H,00H,00H    ;3  -03H
          DFB   04H,00H,00H,00H,00H    ;4  -04H
          DFB   08H,00H,00H,00H,00H    ;5  -05H
          DFB   10H,00H,00H,00H,00H    ;6  -06H
          DFB   20H,00H,00H,00H,00H    ;7  -07H
          DFB   40H,00H,00H,00H,00H    ;8  -08H
          DFB   00H,01H,00H,00H,00H    ;9  -09H
          DFB   00H,02H,00H,00H,00H    ;10 -0AH
          DFB   00H,04H,00H,00H,00H    ;11 -0BH
          DFB   00H,08H,00H,00H,00H    ;12 -0CH
          DFB   00H,10H,00H,00H,00H    ;13 -0DH
          DFB   00H,20H,00H,00H,00H    ;14 -0EH
          DFB   00H,40H,00H,00H,00H    ;15 -0FH
          DFB   00H,00H,01H,00H,00H    ;16 -10H
          DFB   00H,00H,02H,00H,00H    ;17 -11H
          DFB   00H,00H,04H,00H,00H    ;18 -12H
          DFB   00H,00H,08H,00H,00H    ;19 -13H
          DFB   00H,00H,10H,00H,00H    ;20 -14H
          DFB   00H,00H,20H,00H,00H    ;21 -15H
          DFB   00H,00H,40H,00H,00H    ;22 -16H
          DFB   00H,00H,00H,00H,00H    ;23 -17H
          DFB   04H,02H,7FH,02H,04H    ;24 -18H ARROW UP
          DFB   00H,00H,00H,00H,00H    ;25 -19H
          DFB   00H,00H,00H,00H,00H    ;26 -1AH
          DFB   08H,1CH,2AH,08H,08H    ;27 -1BH ARROW LEFT
          DFB   00H,00H,00H,00H,00H    ;28 -1CH
          DFB   00H,00H,00H,00H,00H    ;29 -1DH
          DFB   00H,00H,00H,00H,00H    ;30 -1EH
          DFB   00H,00H,00H,00H,00H    ;31 -1FH
          DFB   00H,00H,00H,00H,00H    ;32 -20H
          DFB   00H,00H,5FH,00H,00H    ;33 -21H !
          DFB   00H,07H,00H,07H,00H    ;34 -22H "
          DFB   14H,7FH,14H,7FH,14H    ;35 -23H #
          DFB   24H,2AH,6BH,2AH,12H    ;36 -24H $
          DFB   63H,13H,08H,64H,63H    ;37 -25H %
          DFB   36H,49H,56H,20H,50H    ;38 -26H &
          DFB   07H,07H,00H,00H,00H    ;39 -27H `
          DFB   00H,1CH,22H,41H,00H    ;40 -28H (
          DFB   00H,41H,22H,1CH,00H    ;41 -29H )
          DFB   15H,0EH,1FH,0EH,15H    ;42 -2AH *
          DFB   08H,08H,3EH,08H,08H    ;43 -2BH +
          DFB   00H,00H,58H,38H,00H    ;44 -2CH ,
          DFB   08H,08H,08H,08H,08H    ;45 -2DH -
          DFB   00H,60H,60H,00H,00H    ;46 -2EH .
          DFB   60H,10H,08H,04H,03H    ;47 -2FH /
          DFB   3EH,51H,49H,45H,3EH    ;48 -30H 0
          DFB   00H,42H,7FH,40H,00H    ;49 -31H 1
          DFB   72H,49H,49H,49H,46H    ;50 -32H 2
          DFB   22H,41H,49H,49H,36H    ;51 -33H 3
          DFB   18H,14H,12H,7FH,10H    ;52 -34H 4
          DFB   27H,45H,45H,45H,39H    ;53 -35H 5
          DFB   3CH,4AH,49H,49H,30H    ;54 -36H 6
          DFB   61H,11H,09H,05H,03H    ;55 -37H 7
          DFB   36H,49H,49H,49H,36H    ;56 -38H 8
          DFB   06H,49H,49H,29H,1EH    ;57 -39H 9
          DFB   00H,36H,36H,00H,00H    ;58 -3AH :
          DFB   00H,5BH,3BH,00H,00H    ;59 -3BH ;
          DFB   00H,08H,14H,22H,41H    ;60 -3CH <
          DFB   14H,14H,14H,14H,14H    ;61 -3DH =
          DFB   41H,22H,14H,08H,00H    ;62 -3EH >
          DFB   02H,01H,59H,06H,00H    ;63 -3FH ?
          DFB   32H,49H,79H,41H,3EH    ;64 -40H @
          DFB   7CH,12H,11H,12H,7CH    ;65 -41H A
          DFB   41H,7FH,49H,49H,36H    ;66 -42H B
          DFB   3EH,41H,41H,41H,22H    ;67 -43H C
          DFB   41H,7FH,41H,41H,3EH    ;68 -44H D
          DFB   7FH,49H,49H,41H,41H    ;69 -45H E
          DFB   7FH,09H,09H,01H,01H    ;70 -46H F
          DFB   3EH,41H,41H,49H,79H    ;71 -47H G
          DFB   7FH,08H,08H,08H,7FH    ;72 -48H H
          DFB   00H,41H,7FH,41H,00H    ;73 -49H I
          DFB   20H,41H,41H,3FH,01H    ;74 -4AH J
          DFB   7FH,08H,14H,22H,41H    ;75 -4BH K
          DFB   7FH,40H,40H,40H,40H    ;76 -4CH L
          DFB   7FH,02H,0CH,02H,7FH    ;77 -4DH M
          DFB   7FH,02H,04H,08H,7FH    ;78 -4EH N
          DFB   3EH,41H,41H,41H,3EH    ;79 -4FH O
          DFB   7FH,09H,09H,09H,06H    ;80 -50H P
          DFB   3EH,41H,51H,21H,5EH    ;81 -51H Q
          DFB   7FH,09H,19H,29H,46H    ;82 -52H R
          DFB   22H,45H,49H,51H,22H    ;83 -53H S
          DFB   01H,01H,7FH,01H,01H    ;84 -54H T
          DFB   3FH,40H,40H,40H,3FH    ;85 -55H U
          DFB   07H,18H,60H,18H,07H    ;86 -56H V
          DFB   7FH,20H,10H,20H,7FH    ;87 -57H W
          DFB   63H,14H,08H,14H,63H    ;88 -58H X
          DFB   03H,04H,78H,04H,03H    ;89 -59H Y
          DFB   61H,51H,49H,45H,43H    ;90 -5AH Z
          DFB   00H,7FH,41H,41H,00H    ;91 -5BH [
          DFB   03H,04H,08H,10H,60H    ;92 -5CH \
          DFB   00H,41H,41H,7FH,00H    ;93 -5DH ]
          DFB   00H,00H,00H,00H,00H    ;94 -5EH
          DFB   00H,00H,00H,00H,00H    ;95 -5FH
          DFB   00H,00H,00H,00H,00H    ;96 -60H
          DFB   00H,00H,00H,00H,00H    ;97 -61H
          DFB   00H,00H,00H,00H,00H    ;98 -62H
          DFB   00H,00H,00H,00H,00H    ;99 -63H
          DFB   00H,00H,00H,00H,00H    ;100-64H
          DFB   00H,00H,00H,00H,00H    ;101-65H
          DFB   00H,00H,00H,00H,00H    ;102-66H
          DFB   00H,00H,00H,00H,00H    ;103-67H
          DFB   00H,00H,00H,00H,00H    ;104-68H
          DFB   00H,00H,00H,00H,00H    ;105-69H
          DFB   00H,00H,00H,00H,00H    ;106-6AH
          DFB   00H,00H,00H,00H,00H    ;107-6BH
          DFB   00H,00H,00H,00H,00H    ;108-6CH
          DFB   00H,00H,00H,00H,00H    ;109-6DH
          DFB   00H,00H,00H,00H,00H    ;110-6EH
          DFB   00H,00H,00H,00H,00H    ;111-6FH
          DFB   00H,00H,00H,00H,00H    ;112-70H
          DFB   00H,00H,00H,00H,00H    ;113-71H
          DFB   00H,00H,00H,00H,00H    ;114-72H
          DFB   00H,00H,00H,00H,00H    ;115-73H
          DFB   00H,00H,00H,00H,00H    ;116-74H
          DFB   00H,00H,00H,00H,00H    ;117-75H
          DFB   00H,00H,00H,00H,00H    ;118-76H
          DFB   00H,00H,00H,00H,00H    ;119-77H
          DFB   00H,00H,00H,00H,00H    ;120-78H
          DFB   00H,00H,00H,00H,00H    ;121-79H
          DFB   00H,00H,00H,00H,00H    ;122-7AH
          DFB   00H,00H,00H,00H,00H    ;123-7BH
          DFB   00H,00H,00H,00H,00H    ;124-7CH
          DFB   00H,00H,00H,00H,00H    ;125-7DH
          DFB   00H,00H,00H,00H,00H    ;126-7EH
          DFB   00H,00H,00H,00H,00H    ;127-7FH
          DFB   00H,00H,00H,00H,00H    ;128-80H
          DFB   00H,00H,00H,00H,00H    ;129-81H
          DFB   00H,00H,00H,00H,00H    ;130-82H
          DFB   00H,00H,00H,00H,00H    ;131-83H
          DFB   00H,00H,00H,00H,00H    ;132-84H
          DFB   00H,00H,00H,00H,00H    ;133-85H
          DFB   00H,00H,00H,00H,00H    ;134-86H
          DFB   00H,00H,00H,00H,00H    ;135-87H
          DFB   00H,00H,00H,00H,00H    ;136-88H
          DFB   00H,00H,00H,00H,00H    ;137-89H
          DFB   00H,00H,00H,00H,00H    ;138-8AH
          DFB   00H,00H,00H,00H,00H    ;139-8BH
          DFB   00H,00H,00H,00H,00H    ;140-8CH
          DFB   00H,00H,00H,00H,00H    ;141-8DH
          DFB   00H,00H,00H,00H,00H    ;142-8EH
          DFB   00H,00H,00H,00H,00H    ;143-8FH
          DFB   00H,00H,00H,00H,00H    ;144-90H
          DFB   00H,00H,00H,00H,00H    ;145-91H
          DFB   00H,00H,00H,00H,00H    ;146-92H
          DFB   00H,00H,00H,00H,00H    ;147-93H
          DFB   00H,00H,00H,00H,00H    ;148-94H
          DFB   00H,00H,00H,00H,00H    ;149-95H
          DFB   00H,00H,00H,00H,00H    ;150-96H
          DFB   00H,00H,00H,00H,00H    ;151-97H
          DFB   00H,00H,00H,00H,00H    ;152-98H
          DFB   00H,00H,00H,00H,00H    ;153-99H
          DFB   00H,00H,00H,00H,00H    ;154-9AH
          DFB   00H,00H,00H,00H,00H    ;155-9BH
          DFB   00H,00H,00H,00H,00H    ;156-9CH
          DFB   00H,00H,00H,00H,00H    ;157-9DH
          DFB   00H,00H,00H,00H,00H    ;158-9EH
          DFB   00H,00H,00H,00H,00H    ;159-9FH
          DFB   00H,00H,00H,00H,00H    ;160-A0H
          DFB   00H,00H,00H,00H,00H    ;161-A1H
          DFB   00H,00H,00H,00H,00H    ;162-A2H
          DFB   00H,00H,00H,00H,00H    ;163-A3H
          DFB   00H,00H,00H,00H,00H    ;164-A4H
          DFB   00H,00H,00H,00H,00H    ;165-A5H
          DFB   00H,00H,00H,00H,00H    ;166-A6H
          DFB   00H,00H,00H,00H,00H    ;167-A7H
          DFB   00H,00H,00H,00H,00H    ;168-A8H
          DFB   00H,00H,00H,00H,00H    ;169-A9H
          DFB   00H,00H,00H,00H,00H    ;170-AAH
          DFB   00H,00H,00H,00H,00H    ;171-ABH
          DFB   00H,00H,00H,00H,00H    ;172-ACH
          DFB   00H,00H,00H,00H,00H    ;173-ADH
          DFB   00H,00H,00H,00H,00H    ;174-AEH
          DFB   00H,00H,00H,00H,00H    ;175-AFH
          DFB   00H,00H,00H,00H,00H    ;176-B0H
          DFB   00H,00H,00H,00H,00H    ;177-B1H
          DFB   00H,00H,00H,00H,00H    ;178-B2H
          DFB   00H,00H,00H,00H,00H    ;179-B3H
          DFB   00H,00H,00H,00H,00H    ;180-B4H
          DFB   00H,00H,00H,00H,00H    ;181-B5H
          DFB   00H,00H,00H,00H,00H    ;182-B6H
          DFB   00H,00H,00H,00H,00H    ;183-B7H
          DFB   00H,00H,00H,00H,00H    ;184-B8H
          DFB   00H,00H,00H,00H,00H    ;185-B9H
          DFB   00H,00H,00H,00H,00H    ;186-BAH
          DFB   00H,00H,00H,00H,00H    ;187-BBH
          DFB   00H,00H,00H,00H,00H    ;188-BCH
          DFB   00H,00H,00H,00H,00H    ;189-BDH
          DFB   00H,00H,00H,00H,00H    ;190-BEH
          DFB   00H,00H,00H,00H,00H    ;191-BFH
          DFB   00H,00H,00H,00H,00H    ;192-C0H
          DFB   00H,00H,00H,00H,00H    ;193-C1H
          DFB   00H,00H,00H,00H,00H    ;194-C2H
          DFB   00H,00H,00H,00H,00H    ;195-C3H
          DFB   00H,00H,00H,00H,00H    ;196-C4H
          DFB   00H,00H,00H,00H,00H    ;197-C5H
          DFB   00H,00H,00H,00H,00H    ;198-C6H
          DFB   00H,00H,00H,00H,00H    ;199-C7H
          DFB   00H,00H,00H,00H,00H    ;200-C8H
          DFB   00H,00H,00H,00H,00H    ;201-C9H
          DFB   00H,00H,00H,00H,00H    ;202-CAH
          DFB   00H,00H,00H,00H,00H    ;203-CBH
          DFB   00H,00H,00H,00H,00H    ;204-CCH
          DFB   00H,00H,00H,00H,00H    ;205-CDH
          DFB   00H,00H,00H,00H,00H    ;206-CEH
          DFB   00H,00H,00H,00H,00H    ;207-CFH
          DFB   00H,00H,00H,00H,00H    ;208-D0H
          DFB   00H,00H,00H,00H,00H    ;209-D1H
          DFB   00H,00H,00H,00H,00H    ;210-D2H
          DFB   00H,00H,00H,00H,00H    ;211-D3H
          DFB   00H,00H,00H,00H,00H    ;212-D4H
          DFB   00H,00H,00H,00H,00H    ;213-D5H
          DFB   00H,00H,00H,00H,00H    ;214-D6H
          DFB   00H,00H,00H,00H,00H    ;215-D7H
          DFB   00H,00H,00H,00H,00H    ;216-D8H
          DFB   00H,00H,00H,00H,00H    ;217-D9H
          DFB   00H,00H,00H,00H,00H    ;218-DAH
          DFB   00H,00H,00H,00H,00H    ;219-DBH
          DFB   00H,00H,00H,00H,00H    ;220-DCH
          DFB   00H,00H,00H,00H,00H    ;221-DDH
          DFB   00H,00H,00H,00H,00H    ;222-DEH
          DFB   00H,00H,00H,00H,00H    ;223-DFH
          DFB   00H,00H,00H,00H,00H    ;224-E0H
          DFB   00H,00H,00H,00H,00H    ;225-E1H
          DFB   00H,00H,00H,00H,00H    ;226-E2H
          DFB   00H,00H,00H,00H,00H    ;227-E3H
          DFB   00H,00H,00H,00H,00H    ;228-E4H
          DFB   00H,00H,00H,00H,00H    ;229-E5H
          DFB   00H,00H,00H,00H,00H    ;230-E6H
          DFB   00H,00H,00H,00H,00H    ;231-E7H
          DFB   00H,00H,00H,00H,00H    ;232-E8H
          DFB   00H,00H,00H,00H,00H    ;233-E9H
          DFB   00H,00H,00H,00H,00H    ;234-EAH
          DFB   00H,00H,00H,00H,00H    ;235-EBH
          DFB   00H,00H,00H,00H,00H    ;236-ECH
          DFB   00H,00H,00H,00H,00H    ;237-EDH
          DFB   00H,00H,00H,00H,00H    ;238-EEH
          DFB   00H,00H,00H,00H,00H    ;239-EFH
          DFB   00H,00H,00H,00H,00H    ;240-F0H
          DFB   00H,00H,00H,00H,00H    ;241-F1H
          DFB   00H,00H,00H,00H,00H    ;242-F2H
          DFB   00H,00H,00H,00H,00H    ;243-F3H
          DFB   00H,00H,00H,00H,00H    ;244-F4H
          DFB   00H,00H,00H,00H,00H    ;245-F5H
          DFB   00H,00H,00H,00H,00H    ;246-F6H
          DFB   00H,00H,00H,00H,00H    ;247-F7H
          DFB   00H,00H,00H,00H,00H    ;248-F8H
          DFB   00H,00H,00H,00H,00H    ;249-F9H
          DFB   00H,00H,00H,00H,00H    ;250-FAH
          DFB   00H,00H,00H,00H,00H    ;251-FBH
          DFB   00H,00H,00H,00H,00H    ;252-FCH
          DFB   00H,00H,00H,00H,00H    ;253-FDH
          DFB   00H,00H,00H,00H,00H    ;254-FEH
          DFB   00H,00H,00H,00H,00H    ;255-FFH
END                                      
