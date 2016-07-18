;------------------------------------------------------------------------------
;
;------------------------------------------------------------------------------
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

;------------------------------------------------------------------------------
; based on C++ code http://gandalf.arubi.uni-kl.de/avr_projects/tempsensor/index.html
;--------------------------------------------------
#define OW_ROMCODE_SIZE 8
#define MAXSENSORS 12 				// limited by RAM size
#define OW_SEARCH_FIRST 0xFF        // start new search
#define OW_LAST_DEVICE  0x00        // last device found

.equ scratchpad = 0
.equ id = 1
.def ds_crc8 = r8
.def crc8 = r9

.dseg
    rom_codes: .byte 8*MAXSENSORS
.cseg

.def rChar		= r11
.def rBitCount	= r18

.def device_counter = r10
.def j = r19
.def i = r20
.def diff = r21
.def next_diff = r22
.def flags = r23
.equ A = 0
.equ crc_ok = 1
.equ sign = 2

.macro calc_crc8
    ldi counter,@1
    ldi XL,low(@0)
    ldi XH,high(@0)
    rcall ow_crc8
.endmacro        

ow_search_rom:
    clr flags
    clr device_counter
    ldi YL,low(rom_codes)
    ldi YH,high(rom_codes)
    ldi diff,OW_SEARCH_FIRST
ow_next_search:
    ldi ZL,low(id)
    ldi ZH,high(id)
    cpi diff,OW_LAST_DEVICE
    breq ow_stop_search
    rcall OWReset
    brts ow_stop_search
    ldi r16,OW_SEARCH_ROM
    rcall OWWriteByte
    ldi next_diff,OW_LAST_DEVICE
    ldi i,OW_ROMCODE_SIZE*8            
ow_next_i:
    ldi j,8
ow_next_bit:
    rcall OWReadBit
    sbr flags,(1<<A)
    brcs ow_read_comp
    cbr flags,(1<<A)
ow_read_comp:
    rcall OWReadBit
    brcc ow_bX0         ;0bX0
    sbrs flags,A        ;0bX1
    rjmp ow_write       ;0b01
    rjmp ow_stop_search ;0b11
ow_bX0: 
    sbrc flags,A
    rjmp ow_write       ;0b10
    cp i,diff           ;0b00
    brlo ow_set
    breq ow_write
    ld r16,Z
    sbrc r16,0
    rjmp ow_set
    rjmp ow_write
ow_set:
    sbr flags,(1<<A)
    mov next_diff,i
ow_write:
    clc
    sbrc flags,A
    sec
    rcall OWWriteBit
    ld r16,Z
    lsr r16
    sbrc flags,A
    ori r16,0x80
    st Z,r16
    dec i
    dec j
    brne ow_next_bit
    adiw ZH:ZL,1
    tst i
    brne ow_next_i
ow_next:
    calc_crc8 id,7
    cpse ds_crc8,crc8   ; compare CRC values
    rjmp ow_bad_crc
    ldi ZL,low(id)      ; load ROM to SRAM if CRC ok
    ldi ZH,high(id)
    ldi j,8
ow_copy_next:
    ld r16,Z+
    st Y+,r16
    dec j
    brne ow_copy_next
    inc device_counter
    mov r16,device_counter
    cpi r16,MAXSENSORS
    breq ow_stop_search
ow_bad_crc:
    mov diff,next_diff        
    rjmp ow_next_search
ow_stop_search:	
    ret


;---------------------------------------
;http://www.farbaresearch.com/examples/crc8.htm
ow_crc8:
    clr	crc8            ;start with a zero CRC-8
	                        ;begin loop to do each byte in the string
ow_crc8byte:
    ld	rChar,X+	;fetch next string byte and bump pointer
    ldi	rBitCount,8	;load the bit-counter for this byte
	                        ;begin loop to do each bit in the byte
ow_crc8bit:
    mov	j,rChar		;get a temporary copy of current data
    eor	j,crc8		;XOR the data byte with the current CRC
    lsr	crc8		;position to the new CRC
    lsr	rChar		;position to next bit of this byte	
    lsr	j		;get low bit of old result into c-bit
    brcc ow_crc8na		;br if low bit was clear (no adjustment)
    ldi	j,0x8C		;magical value needed for CRC-8s
    eor	crc8,j		;fold in the magic CRC8 value
ow_crc8na:	
    dec	rBitCount	;count the previous bit done
    brne	ow_crc8bit	;br if not done all bits in this byte
	                        ;end loop to do each bit in the byte
    dec	counter		;count this byte done
    brne	ow_crc8byte	;br if not done all bytes in the string
	                        ;end loop to do each byte in the string
    ret			;return to caller

