; IODemo.asm
; Produces a "bouncing" animation on the LEDs.
; The LED pattern is initialized with the switch state.

ORG 0

	; Get and store the switch values
	CALL   SetupI2C    ; Configure ADXL345
	Load Pattern
	AND Zero
	OR    Opponent 
	OUT Hex0
	STORE  Pattern
	
	LOAD Player
	AND Zero
	OR	Down
	STORE Player
	OUT Hex1
	
	LOAD Score
	AND Zero
	OR Bit0
	STORE Score

BeforeZero:
	LOAD Opponent
	STORE Pattern
	
ZerothHex:
	; Slow down the loop so humans can watch it.
	CALL   Delay

	; Check if the left place is 1 and if so, switch direction
	LOAD   Pattern        ; bit mask
	;JPOS   Right        ; bit9 is 1; go right
	SHIFT 4
	STORE Pattern
	JZERO BeforeFirst
	OUT    Hex0
	CALL   ReadX
	JNEG	Negative
	JPOS	Positive
	JUMP   ZerothHex

BeforeFirst:
	LOAD Up
	STORE Pattern
FirstHex:
	CALL Delay
	LOAD  Pattern
;	CALL   ReadX
;	JNEG	Negative
;	JPOS	Positive
	
;	LOAD Pattern
	SUB Player
	
	JZERO CollisonDetected
	JUMP Escape

Escape:
	LOAD Score
	OUT LEDs
	SHIFT 1
	STORE SCORE
	LOAD Three
	OUT Hex1
	LOAD Zero
	OUT Hex0
	
	CALL Delay
	LOAD Twice
	OUT Hex1
	JUMP BeforeZero	
Three: DW &H03
Twice: DW &H11
Negative:
	LOAD TemporaryAccData
	SUB CheckUp
	JPOS PlayerUp
	JUMP ZerothHex

Positive:
	LOAD TemporaryAccData
	;SUB CheckDown
	;JPOS PlayerDown
	LOAD Down
	STORE Player
	OUT Hex1
	JUMP ZerothHex

PlayerUp:
	LOAD Up
	STORE Player
	OUT Hex1
	JUMP ZerothHex

PlayerDown:
	LOAD Down
	STORE Player
	OUT Hex1
	JUMP ZerothHex

Opponent:  DW &H0001
Player:	   DW &H02

Up:		   DW &H01
Down:	   DW &H02

CheckUp:   DW &HFFB0
CheckNeg:  DW &HF000
CheckDown: DW &H0050

TemporaryAccData: DW 0
Score:	DW &B0000000001
CheckLeftUp: DW &H10
CheckLeftDown: DW &H01

CollisonDetected:
	JUMP CollisonDetected
Right:
	; Slow down the loop so humans can watch it.
	CALL   Delay

	; Check if the right place is 1 and if so, switch direction
	LOAD   Pattern
	AND    Bit0         ; bit mask
	;JPOS   Left         ; bit0 is 1; go left
	
	LOAD   Pattern
	SHIFT  -1
	STORE  Pattern
	OUT    LEDs
	
	JUMP   Right
	
; To make things happen on a human timescale, the timer is
; used to delay for half a second.
Delay:
	OUT    Timer
WaitingLoop:
	IN     Timer
	ADDI   -5
	JNEG   WaitingLoop
	RETURN

WaitForData:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CR1Cmd    ; load command
	OUT    I2C_CMD     ; to I2C_CMD register
	LOAD   SRCAddr    ; 
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_data    ; put the data in AC
	SHIFT -7
	JZERO   WaitForData   ; bytes returned in wrong order; swap them
	RETURN
	
	
; Subroutine to configure the I2C for reading accelerometer data
; Only needs to be done once after each reset.
SetupI2C:
	LOAD   AccCfg      ; load the number of commands
	STORE  CmdCnt
	LOADI  AccCfg      ; Load list ADDRESS
	ADDI   1           ; Increment to first command
	STORE  CmdPtr
I2CCmdLoop:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CWCmd     ; load write command
	OUT    I2C_CMD     ; to I2C_CMD register
	ILOAD  CmdPtr      ; load current command
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	LOAD   CmdPtr
	ADDI   1           ; Increment to next command
	STORE  CmdPtr
	LOAD   CmdCnt
	ADDI   -1
	STORE  CmdCnt
	JPOS   I2CCmdLoop
	RETURN
CmdPtr: DW 0
CmdCnt: DW 0

ReadX:
	CALL   BlockI2C    ; wait for idle
	LOAD   I2CR2Cmd    ; load command
	OUT    I2C_CMD     ; to I2C_CMD register
	LOAD   AccXAddr    ; 
	OUT    I2C_DATA    ; to I2C_DATA register
	OUT    I2C_RDY     ; start the communication
	CALL   BlockI2C    ; wait for it to finish
	IN     I2C_data    ; put the data in AC
	CALL   SwapBytes   ; bytes returned in wrong order; swap them
	RETURN
	
; This subroutine swaps the bytes in AC
SwapBytes:
	STORE  SBT1
	SHIFT  8
	STORE  SBT2
	LOAD   SBT1
	SHIFT  -8
	AND    LoByte
	OR     SBT2
	RETURN
SBT1: DW 0
SBT2: DW 0

; Subroutine to block until I2C device is idle.
; Enters error loop if no response for ~0.1 seconds.
BlockI2C:
	LOAD   Zero
	STORE  Temp        ; Used to check for timeout
BI2CL:
	LOAD   Temp
	ADDI   1           ; this will result in ~0.1s timeout
	STORE  Temp
	JZERO  I2CError    ; Timeout occurred; error
	IN     I2C_RDY     ; Read busy signal
	JPOS   BI2CL       ; If not 0, try again
	RETURN             ; Else return
I2CError:
	LOAD   Zero
	ADDI   &H12C       ; "I2C"
	OUT    Hex0        ; display error message
	JUMP   I2CError

; I2C Constants
I2CWCmd:  DW &H203A    ; write two i2c bytes, addr 0x3A
I2CR1Cmd: DW &H113A    ; write one byte, read one byte, addr 0x3A
I2CR2Cmd: DW &H123A    ; write one byte, read two bytes, addr 0x3A
I2CR3Cmd: DW &H1130
AccXAddr: DW &H34      ; X acceleration register address.
SRCAddr:  DW &H30
AccCfg: ; List of commands to send the ADXL345 at startup
	DW 5           ; Number of commands to send
	DW &H0000      ; Meaningless write to sync communication
	DW &H3103      ; Right-justified 10-bit data, +/-2 G
	DW &H3800      ; No FIFO
	DW &H2C0A      ; 6.25 samples per second
	DW &H2D08      ; No sleep
; Variables
Pattern:   DW 0

; Useful values
Temp:      DW 0
ReadCount: DW 0
; Useful values
Zero:      DW 0
NegOne:    DW -1
One:
Bit0:      DW &B0000000001
Bit1:      DW &B0000000010
Bit2:      DW &B0000000100
Bit3:      DW &B0000001000
Bit4:      DW &B0000010000
Bit5:      DW &B0000100000
Bit6:      DW &B0001000000
Bit7:      DW &B0010000000
Bit8:      DW &B0100000000
Bit9:      DW &B1000000000
LoByte:    DW &H00FF
HiByte:    DW &HFF00


; IO address constants
Switches:  EQU 000
LEDs:      EQU 001
Timer:     EQU 002
Hex0:      EQU 004
Hex1:      EQU 005
I2C_cmd:   EQU &H090
I2C_data:  EQU &H091
I2C_rdy:   EQU &H092