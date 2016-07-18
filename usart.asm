;.set UART_BAUDRATE = 115200
.set UART_BAUDRATE = 57600
.set BAUD_PRESCALE = (((F_CPU / (UART_BAUDRATE * 16))) - 1)

usart_init:
	ldi r17,high(BAUD_PRESCALE)
	ldi r16,low(BAUD_PRESCALE)
	; Set baud rate
	out UBRRH, r17
	out UBRRL, r16
	; Enable receiver and transmitter
	ldi r16, (1<<RXCIE)|(1<<RXEN)|(1<<TXEN)
;	ldi r16, (1<<TXEN)
	out UCSRB,r16
	; Set frame format: 8data, 1stop bit
	ldi r16, (0<<USBS)|(1<<UCSZ0)|(1<<UCSZ1)
	out UCSRC,r16
	ret
usart_tx:
	sbis UCSRA,UDRE
	rjmp usart_tx
	out UDR,r16
	ret
usart_rx:
	sbis UCSRA, RXC
	rjmp usart_rx
	in r16, UDR
	ret

usart_write_string:
	lpm		r16, Z+
	cpi		r16, 0
	breq	usart_string_exit
	rcall	usart_tx
	rjmp usart_write_string	
usart_string_exit:
	ret


.macro  usart_write
     ldi ZL,low(@0<<1)
     ldi ZH,high(@0<<1)
     rcall usart_write_string
.endmacro

.macro usart_put
     ldi r16,@0
     rcall usart_tx
.endmacro

usart_tx_hex:
        push    r16
	swap	r16
	andi	r16,0x0F
	rcall	usart_hex
	pop	r16
	andi	r16,0x0F
	rcall	usart_hex
        ret

usart_hex:
	cpi		r16,10
	brlo	usart_num
	ldi		r17,'7'
	add		r16,r17
	rcall	usart_tx
	ret
usart_num:
	ldi		r17,'0'
	add		r16,r17
	rcall	usart_tx
	ret

usart_br:
        ldi r16,0x0A
        rcall usart_tx
        ldi r16,0x0D
        rcall usart_tx
        ret
