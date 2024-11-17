
ORG 0
;LOAD ALLON
;OUT LEDs
;Delay:
;	OUT    Timer
;WaitingLoop:
;	IN     Timer
;	ADDI   -100
;	JNEG   WaitingLoop


LOADI 3      ; we want to access page 3
OUT EXTMEM_INDEX_EN
LOADI 10    ; we want offset 10 in page 3
OUT EXTMEM_OFFSET_EN
LOADI 5
OUT EXTMEM_DATA_EN       ; write into page 3 offset 10

LOADI 0
IN EXTMEM_DATA_EN
OUT LEDs

;LOADI 3      ; we want to access page 3
;OUT EXTMEM_INDEX_EN
;LOADI 0
;IN EXTMEM_INDEX_EN
;OUT LEDs


HERE:
	JUMP HERE
; IO address constants
EXTMEM_INDEX_EN:  EQU &H70
EXTMEM_OFFSET_EN:  EQU &H71
EXTMEM_PERMISSION_EN:  EQU &H72
EXTMEM_DATA_EN:  EQU &H73
LEDs:      EQU 001
Timer:     EQU 002
ALLON: DW 1023