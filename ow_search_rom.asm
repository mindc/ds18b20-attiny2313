;------------------------------------------------------------------------------
; code by null@mindc.net
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
