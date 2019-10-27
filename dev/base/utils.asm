; Game Boy Color development (feature showcase)
; Made by Imanol Barriuso (Imanolea) for Games aside

; Basic hardware routines

; OAM RAM update by DMA Transfer
DMATransferRoutine::
	di
	ld		a,	$C2
	ld		[rDMA],	a
	ld		a,	40
.dmatransferroutine_0:
	dec		a
	jr		nz,	.dmatransferroutine_0
	ei
	ret
DMATransferRoutineEnd::

; System related routines

; Turns down the LCD
display_off:
    ld	    a,	[rLCDC]
    rlca
    ret	    nc						; If it's already off, we return
	di								; We make sure that the interruptions are disabled
.display_off_0:
    ld	    a,	[rLY]
    cp	    145
    jr	    nz, .display_off_0		; We manually wait for the VBlank interruption
    ld		a,	[rLCDC]
	res		7,	a
	ld		[rLCDC],	a			; We turn off the LCD
    ret

; Turns on the LCD
display_on:
    ld		hl,	rLCDC
    ; We configure and turn on the display
    ld		a,	LCDCF_DEFAULT
    ld		[hl],	a
    ret

; Turns off the sound
sound_off:
	xor		a
	ld		[rNR52],	a
	ret

; General routines

; Copies a specific number of bytes from one direction to another
;
; @input	HL: Source address
; @input	DE: Destination address
; @input	BC: Byte number
;
copymem:
.copymem_0:
	ld		a,	[hli]
	ld		[de],	a
	inc		de
	dec		bc
	ld		a,	c
	or		b
	jr		nz,	.copymem_0
	ret

; Fills a specific number of bytes of one direction with a certain value
;
; @input	DE: Destination address
; @input	BC: Byte number
; @input	L: Fill value
fillmem:
.fillmem_0:
    ld		a,	l
    ld		[de],	a
    dec		bc
    ld		a,	c
    or		b
    ret		z
    inc		de
    jr		.fillmem_0

; Copies a specific number of bytes from one direction to another (adapted to copy data to the visible background)
;
; @input	HL: Source address
; @input	DE: Destination address
; @input	BC: Byte number
;
loadscreen:
	ld		c,	18					; Background height
.loadscreen_0:
	ld		b,	20					; Background width
.loadscreen_1:
	ld		a,	[de]
	inc		de
	ld		[hli],	a
	dec		b
	jr		nz,	.loadscreen_1
	dec		c
	ret		z
	push	de
	ld		de,	12					; Additional background height
	add		hl,	de
	pop		de
	jr		.loadscreen_0