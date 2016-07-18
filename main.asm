#include "tn2313def.inc"

	rjmp RESET ; Reset Handler
	reti;	rjmp INT0 ; External Interrupt0 Handler
	reti;rjmp int_INT1 ; External Interrupt1 Handler
	reti;	rjmp TIM1_CAPT ; Timer1 Capture Handler
	reti;	rjmp TIM1_COMPA ; Timer1 CompareA Handler
	reti;	rjmp TIM1_OVF ; Timer1 Overflow Handler
	reti;	rjmp TIM0_OVF ; Timer0 Overflow Handler
	rjmp USART0_RXC ; USART0 RX Complete Handler
	reti;	rjmp USART0_DRE ; USART0,UDR Empty Handler
	reti;	rjmp USART0_TXC ; USART0 TX Complete Handler
	reti;	rjmp ANA_COMP ; Analog Comparator Handler
	reti;	rjmp PCINT ; Pin Change Interrupt
	reti;	rjmp TIMER1_COMPB ; Timer1 Compare B Handler
	reti;	rjmp TIMER0_COMPA ; Timer0 Compare A Handler
	reti;	rjmp TIMER0_COMPB ; Timer0 Compare B Handler
	reti;	rjmp USI_START ; USI Start Handler
	reti;	rjmp USI_OVERFLOW ; USI Overflow Handler
	reti;	rjmp EE_READY ; EEPROM Ready Handler
	reti;	rjmp WDT_OVERFLOW ; Watchdog Overflow Handler
;

#define F_CPU 11059200

#define LED 2

#include "wait.asm"
#include "ow.asm"
#include "bin2bcd.asm"
#include "usart.asm"
#include "hd44780.asm"


;-------------------------------------------        
RESET:
        ldi r16, low(RAMEND)
        out SPL,r16; Set Stack Pointer to top of RAM

;        ldi r16,0
        ldi r16,(1<<SREG_I)
        out SREG,r16
;        ldi r16,(1<<INT1)
;        out GIMSK,r16

        

;LED ON
	cbi		PORTD,LED
	sbi		DDRD,LED
;-------------------------------------------------
        rcall usart_init
;--------------------------------------------------
        rcall LCD_Init
;------------------------------------------------------
; load fonts
        ldi r17,8
        clr r19
        ldi ZL,low(fonts<<1)
        ldi ZH,high(fonts<<1)
        ldi r16,0
        rcall LCD_SetAddressCG
lcd_next_font:
        ldi r18,8
lcd_next_font_byte:
        lpm r16,Z+
        rcall LCD_WriteData
        dec r18
        brne lcd_next_font_byte
        inc r19
        dec r17
        brne lcd_next_font
;-----------------------------------------------
        
;        ldi r16,0
;        rcall LCD_SetAddressDD
/*
next_f:
        mov r16,r17
        rcall LCD_WriteData
        inc r17
        cpi r17,8
        brne next_f
loop:
        rjmp loop
*/
;-----------------------------------------------
 
rjmp sleep_run        
;----------------------------------------------
next_run:

		usart_put 'n'


        rcall ow_search_rom
        mov r24,device_counter  
        
        mov r16,device_counter
        cpi r16,0
        brne normal_run
        

        ldi r16,0
        rcall LCD_SetAddressDD
        lcd_write _nodev1
        ldi r16,0x40
        rcall LCD_SetAddressDD
        lcd_write _nodev2
		usart_put '['
		usart_put ']'
		usart_put 0x0D
		usart_put 0x0A
		reti
		

sleep_run:
		;usart_put 'S'	
		sbi PORTD,LED
		rjmp sleep_run


USART0_RXC:

rjmp next_run

/*
rcall usart_rx
cpi r16,'.'
breq next_run
rcall usart_tx
*/

reti

		

normal_run:
        		usart_put 'r'
        	

;--------------------------------------------
; run temp convert on all devices
    rcall OWReset

    ldi r16,OW_SKIP_ROM
    rcall OWWriteByte

    ldi r16,OW_CONVERT_T
    rcall OWWriteByte
; strong pullup
        sbi     OW_PORT, OW_DQ
        sbi	OW_DDR, OW_DQ
;-----------------------
;--------------------------------------------
; wait 750ms
        sei
    ldi r16,250
    rcall WaitMiliseconds
    rcall WaitMiliseconds
    rcall WaitMiliseconds
    cli
   ; rcall WaitMiliseconds
; end strong pullup
     ;   cbi     OW_DDR, OW_DQ
      ;  cbi     OW_PORT, OW_DQ
;-----------------------
    mov counter,device_counter

    usart_write(_start)   
    

    ldi ZL,low(rom_codes)
    ldi ZH,high(rom_codes)
    
;-------------------------------------------
; read scratchpad from each devices
next_device:

		
	
	
		usart_put '['

        ldi r16,0
        rcall LCD_SetAddressDD
    push counter
cbi PORTD,LED
    rcall OWReset
sbi PORTD,LED
;-----------------------------------------
    ldi r16,OW_MATCH_ROM
    rcall OWWriteByte
;----------------------------------------
; write romcode
    ldi r18,8
	usart_put '"'
write_next_byte:
    ld r16,Z
    rcall OWWriteByte
    ld r16,Z+
    rcall usart_tx_hex

    cpi r18,8
    brne fam1
;    usart_put ','
fam1:
    cpi r18,2
    brne fam2
;    usart_put ',' 

fam2:
    dec r18
    brne write_next_byte
usart_put '"'
    
    
;--------------------------------------    
    ldi r16,OW_READ_SCRATCHPAD
    rcall OWWriteByte
;-----------------------------------------    
; read scratchpad
    ldi YL,low(scratchpad)
    ldi YH,high(scratchpad)
    ldi r18,9
read_next_byte:
    rcall OWReadByte
;    push r16
;    rcall usart_tx_hex
;    pop r16
    st Y+,r16
    dec r18
    brne read_next_byte 

;----------------------------------
; calculate crc8   
    calc_crc8 scratchpad,8
    sbr flags,(1<<crc_ok)
    cpse ds_crc8,crc8
    cbr flags,(1<<crc_ok)
                           
;-----------------------------------
; prepare data
    rcall data_convert
    rcall usart_send
    pop counter
    push counter
    cli
    cp counter,r24
    brne skip_lcd
    rcall lcd_send
skip_lcd:
    
;    rcall usart_br
;-----------------------------------
        sei
    pop counter  

	usart_put ']'


	cpi counter,2
	brlo last_device	
		usart_put ','
last_device:
   
    dec counter
    brne next_device




    sbi PORTD,LED
    usart_write(_stop)
	;usart_put 0x0D
	;usart_put 0x0A

    dec r24
    brne nc
    mov r24,device_counter

nc:


    rjmp sleep_run
;----------------------------------------------------------------------


lcd_send:
        push ZL
        push ZH
        push counter
        ldi r16,0
        rcall LCD_SetAddressDD

        mov r16,device_counter
        inc r16
        sub r16,counter
        rcall LCD_WriteHex8

        ldi r16,'/'
        rcall LCD_WriteData

        mov r16,device_counter
        rcall LCD_WriteHex8

        ldi r16,' '
        rcall LCD_WriteData

        mov r16,r7
        cpi r16,0x30
        breq skip_r7
        rjmp r7_ok
skip_r7:
        mov r16,r6
        cpi r16,0x30
        breq skip_r6
        rjmp r6_okc
skip_r6:
        ldi r16,' '
        rcall LCD_WriteData
        ldi r16,' '
        sbrs flags,sign
        ldi r16,'-'
        rcall LCD_WriteData
        rjmp r5_ok
r6_okc:
        ldi r16,' '
        sbrs flags,sign
        ldi r16,'-'
        rcall LCD_WriteData
        rjmp r6_ok
r7_ok: 
        mov r16,r7
        rcall LCD_WriteData
r6_ok:
        mov r16,r6
        rcall LCD_WriteData
r5_ok:
        mov r16,r5
        rcall LCD_WriteData
        ldi r16,'.'
        rcall LCD_WriteData

	ldi ZL,low(ds_fraction2 << 1)
	ldi ZH,high(ds_fraction2 << 1)
	
	clr r16
	add ZL,r0
	adc ZH,r16

        lpm r16,Z+
        rcall LCD_WriteData        


        ldi r16,0
        rcall LCD_WriteData  
        ldi r16,'C'
        rcall LCD_WriteData  
              

          
        ldi r16,' '
        rcall LCD_WriteData           
        sbrs flags,crc_ok
        rjmp crc_check_bad1
        lcd_write _ok
        rjmp crc_check_ok1
crc_check_bad1:
        lcd_write _error
crc_check_ok1:
        ldi r16,0x40
        rcall LCD_SetAddressDD

        pop counter
        pop ZH
        pop ZL

        subi ZL,8
        sbci ZH,0

        push counter
        ldi counter,8
lcd_next_rom:
        ld r16,Z+
        push counter
        rcall LCD_WriteHex8
        pop counter
        dec counter
        brne lcd_next_rom
        pop counter
        ret

;----------------------------------------------------------------------



usart_send:
        push ZL
        push ZH
        push r0
        usart_put ','
        ldi r16,'-'
        sbrs flags,sign
        rcall usart_tx
        mov r16,r7
		;cpi r16,'0'
		;breq skip_zero
        rcall usart_tx
skip_zero:
        mov r16,r6
        rcall usart_tx
        mov r16,r5
        rcall usart_tx
        ldi r16,'.'
        rcall usart_tx

	ldi ZL,low(ds_fraction << 1)
	ldi ZH,high(ds_fraction << 1)

	lsl r0
	lsl r0
	
	clr r16
	add ZL,r0
	adc ZH,r16

        lpm r16,Z+
        rcall usart_tx        
        lpm r16,Z+
        rcall usart_tx        
        lpm r16,Z+
        rcall usart_tx        
        lpm r16,Z+
        rcall usart_tx        
    usart_put ','
        sbrs flags,crc_ok
        rjmp crc_check_bad2
        usart_write(_crc_ok)
        rjmp crc_check_ok2
crc_check_bad2:
        usart_write(_crc_bad)
crc_check_ok2:
        pop r0
        pop ZH
        pop ZL
 
        ret

#include "db.asm"


