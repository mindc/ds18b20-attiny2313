.cseg
fonts:
;     .db 0x4,0xa,0x4,0x0,0x0,0x0,0x0,0x0
     ;.db 0x17,0x14,0x17,0x11,0x17,0x0,0x1f,0x0

    .db 0x2,0x5,0x2,0x0,0x0,0x0,0x0,0x00 ;�    
    ;.db 0x1f,0x11,0x15,0x15,0x15,0x11,0x1f,0x1f ;0
    .db 0x1f,0x1d,0x1d,0x1d,0x1d,0x1d,0x1f,0x1f ;1
    .db 0x1f,0x11,0x1d,0x11,0x17,0x11,0x1f,0x1f ;2
    .db 0x1f,0x11,0x1d,0x11,0x1d,0x11,0x1f,0x1f ;3
    .db 0x1f,0x15,0x15,0x11,0x1d,0x1d,0x1f,0x1f ;4
    .db 0x1f,0x11,0x17,0x11,0x1d,0x11,0x1f,0x1f ;5
    .db 0x1f,0x11,0x17,0x11,0x15,0x11,0x1f,0x1f ;6
    .db 0x1f,0x11,0x1d,0x1d,0x1d,0x1d,0x1f,0x1f ;7
    .db 0x1f,0x11,0x15,0x11,0x15,0x11,0x1f,0x1f ;8
    ;.db 0x1f,0x11,0x15,0x11,0x1d,0x11,0x1f,0x1f ;9
    
ds_fraction:
    .db "0000"
    .db	"0625"
    .db "1250"
    .db "1875"
    .db "2500"
    .db "3125"
    .db "3750"
    .db "4375"
    .db "5000"
    .db "5625"
    .db "6250"
    .db "6875"
    .db "7500"
    .db "8125"
    .db "8750"
    .db "9375"

ds_fraction2:
    .db "0","1"
    .db "1","2"
    .db "3","3"
    .db "4","4"
    .db "5","6"
    .db "6","7"
    .db "7","8"
    .db "8","9"
        
_start:
    .db "[",0
_stop:
    .db "]",0x0D,0x0A,0
_crc_ok:
    .db "1",0
_crc_bad:
    .db "0",0
_ok:
    .db "OK",0,0
_error:
    .db "ER",0,0
 _nodev1:
        ;1234567890123456;helper
    .db "      error     ",0,0
_nodev2:
    .db "    no device   ",0,0

