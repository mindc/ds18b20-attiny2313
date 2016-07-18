.equ	OW_PORT	= PORTD
.equ	OW_PIN	= PIND
.equ	OW_DDR	= DDRD
.equ	OW_DQ	= PD6

.def	counter = r17

;commands
#define	OW_SEARCH_ROM	0xF0
#define	OW_READ_ROM		0x33
#define	OW_MATCH_ROM	0x55
#define	OW_SKIP_ROM		0xCC
#define	OW_ALARM_SEARCH	0xEC
;functions
#define	OW_CONVERT_T	0x44
#define	OW_WRITE_SCRATCHPAD	0x4E
#define	OW_READ_SCRATCHPAD	0xBE
#define	OW_COPY_SCRATCHPAD	0x48
#define	OW_RECALL_EE		0xB8
#define	OW_READ_POWER_SUPPLY	0xB4
;ds18b20
#define OW_CONFIG9		0x1F
#define OW_CONFIG10		0x3F
#define OW_CONFIG11		0x5F
#define OW_CONFIG12		0x7F


;------------------------------------------------------------------------------
;http://avr-mcu.dxp.pl/ with custom delays
;------------------------------------------------------------------------------
.cseg
;------------------------------------------------------------------------------
; Output : T - presence bit
;------------------------------------------------------------------------------
OWReset:
	cbi	OW_PORT,OW_DQ
	sbi	OW_DDR,OW_DQ

	ldi	XH, HIGH(DVUS(480))
	ldi	XL, LOW(DVUS(480))
	rcall	Wait4xCycles
	
	cbi	OW_DDR,OW_DQ

	ldi	XH, HIGH(DVUS(70))
	ldi	XL, LOW(DVUS(70))
	rcall	Wait4xCycles

	set
	sbis	OW_PIN,OW_DQ
	clt

	ldi	XH, HIGH(DVUS(410))
	ldi	XL, LOW(DVUS(410))
	rcall	Wait4xCycles

	ret
;------------------------------------------------------------------------------
; Input : C - bit to write
;------------------------------------------------------------------------------
OWWriteBit:
	brcc	OWWriteZero
	ldi	XH, HIGH(DVUS(6))
	ldi	XL, LOW(DVUS(6))
	rjmp	OWWriteOne
OWWriteZero:	
	ldi	XH, HIGH(DVUS(60))
	ldi	XL, LOW(DVUS(60))
	sbi	OW_DDR, OW_DQ
	rcall	Wait4xCycles
	cbi	OW_DDR, OW_DQ
    ldi	XH, HIGH(DVUS(10))
	ldi	XL, LOW(DVUS(10))
	rcall	Wait4xCycles
    ret	
OWWriteOne:
	sbi	OW_DDR, OW_DQ
	rcall	Wait4xCycles
	cbi	OW_DDR, OW_DQ
    ldi	XH, HIGH(DVUS(64))
	ldi	XL, LOW(DVUS(64))
	rcall	Wait4xCycles
    ret
;------------------------------------------------------------------------------
; Input : r16 - byte to write
;------------------------------------------------------------------------------
OWWriteByte:
	push	counter
	ldi	counter,8
OWWriteLoop:	
	ror	r16
	rcall	OWWriteBit	
	dec	counter
	brne	OWWriteLoop
	pop	counter		
	ret
;------------------------------------------------------------------------------
; Output : C - bit from slave
;------------------------------------------------------------------------------
OWReadBit:
	ldi	XH, HIGH(DVUS(6))
	ldi	XL, LOW(DVUS(6))
	
        sbi	OW_DDR, OW_DQ
	rcall	Wait4xCycles
	cbi	OW_DDR, OW_DQ
	
        ldi	XH, HIGH(DVUS(9))
	ldi	XL, LOW(DVUS(9))
	rcall	Wait4xCycles
	
        clt
	sbic	OW_PIN,OW_DQ
	set
	
        ldi	XH, HIGH(DVUS(55))
	ldi	XL, LOW(DVUS(55))
	rcall	Wait4xCycles
	
        sec
	brts	OWReadBitEnd
	clc
OWReadBitEnd:
	ret
;------------------------------------------------------------------------------
; Output : r16 - byte from slave
;------------------------------------------------------------------------------
OWReadByte:
	push	counter
	ldi	counter,8
OWReadLoop:
	rcall	OWReadBit
	ror	r16
	dec	counter
    	brne	OWReadLoop
	pop	counter
	ret

