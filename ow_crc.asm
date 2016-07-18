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
