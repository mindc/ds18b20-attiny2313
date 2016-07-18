.equ sign = 2
data_convert:
        sbr flags,(1<<sign)
        sbrs r1,7
        rjmp plus
        cbr flags,(1<<sign)
	mov XL,r0
	mov XH,r1
        com XL
        com XH
        adiw XH:XL,1
        mov r0,XL
        mov r1,XH
plus:   rol r0
        rol r1
        rol r0
        rol r1
        rol r0
        rol r1
        rol r0
        rol r1
        ldi r16,0xF0
        and r0,r16
        swap r0
        ldi r16,48
        mov r6,r16
        mov r7,r16
        mov r16,r1
bcd_1:  subi    r16,100
        brcs	bcd_2
        inc	r7
        rjmp	bcd_1
bcd_2:  subi    r16,-100
bcd_3:  subi	r16,10
	brcs	bcd_4
	inc	r6
	rjmp	bcd_3
bcd_4:  subi    r16,-58
        mov     r5,r16
        ret
