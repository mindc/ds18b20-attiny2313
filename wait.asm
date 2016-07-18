;------------------------------------------------------------------------------
; Busy-wait loops utilities module
; For F_CPU >= 4MHz
; http://avr-mcu.dxp.pl
; (c) Radoslaw Kwiecien, 2008
;------------------------------------------------------------------------------

#ifndef F_CPU
  #error "F_CPU must be defined!"
#endif

#if F_CPU < 4000000
  #warning "F_CPU too low, possible wrong delay"
#endif

#define DVUS(x) (x*F_CPU/4000000)

;------------------------------------------------------------------------------
; Input : XH:XL - number of CPU cycles to wait (divided by four)
;------------------------------------------------------------------------------
Wait4xCycles:
  sbiw   XH:XL, 1
  brne   Wait4xCycles
  ret
;------------------------------------------------------------------------------
; Input : r16 - number of miliseconds to wait
;------------------------------------------------------------------------------
WaitMiliseconds:
  push r16
WaitMsLoop:
  ldi    XH,HIGH(DVUS(500))
  ldi    XL,LOW(DVUS(500))
Wait4x1:
  sbiw   XH:XL, 1
  brne   Wait4x1
  ldi    XH,HIGH(DVUS(500))
  ldi    XL,LOW(DVUS(500))
Wait4x2:
  sbiw   XH:XL, 1
  brne   Wait4x2
  dec    r16
  brne   WaitMsLoop
  pop    r16
  ret


;------------------------------------------------------------------------------
; End of file
;------------------------------------------------------------------------------

