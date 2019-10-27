; Game Boy Color development (feature showcase)
; Made by Imanol Barriuso (Imanolea) for Games aside

INCLUDE "dev/gbhw.inc"		        ; File with the system addresses defined

; Constants
; System
LCDCF_DEFAULT       EQU LCDCF_BG8800|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJON|LCDCF_WIN9C00|LCDCF_WINON|LCDCF_ON 
; Routines
DMA_TRANSFER        EQU	$FF80       ; HRAM address available during the DMA Transfer
; Banks
DEFAULT_BNK			EQU	1

; Variables
; Hardware state
_CUR_BNK            EQU _RAM + 0	; Indicates the currently used memory bank
_VBLANK_F           EQU _CUR_BNK + 1; Raises to indicate that we are waiting for the VBlank interruption
;_SGB_F              EQU _VBLANK_F + 1; Raises to indicate that the hardware in which the software it is running is the Super Game Boy
; Auxiliary variables
_AUXVAR             EQU _VBLANK_F + 2;_SGB_F + 1

; Virtual OAM
_OAM                EQU _RAM + 512  ; This is the start address of the sprite memory that will be copied into the real OAM RAM during the VBlank interruption

; VBlank interruption
SECTION "vblank",ROM0[$0040]
    call    vblank
    reti

SECTION "start", ROM0[$0100]
    nop
    jp      start

    ROM_HEADER  "GBC template   ", $80, $03, ROM_MBC1, ROM_SIZE_128KBYTE, RAM_SIZE_0KBYTE

start:
    nop
    ; Base system initialization
    di
    call	display_off
    ; Sytem registers reset
    xor		a
    ld 		[rIF],	a
    ld 		[rSCX],	a
    ld 		[rSCY],	a
    ld 		[rSB],	a
    ld 		[rSC],	a
    ld 		[rTMA],	a
    ld 		[rTAC],	a
    ld 		[rBGP],	a
    ld 		[rOBP0],	a
    ld 		[rOBP1],	a
    ; We position the window out of the visible screen
    ld		hl,	rWX
    ld		[hl],	7
    ld		hl,	rWY
    ld		[hl],	144
    ; Interruptions
    ld		a,	IEF_VBLANK
    ld		[rIE],	a				; VBlank interruption enabled
    ; RAM reset
    ld		de,	_RAM
    ld		bc,	$2000
    ld		l,	$0
    call	fillmem
    ld		sp,	$E000				; Stack pointer points to the RAM end
    ; VRAM reset
    ld		de,	_VRAM
    ld		bc,	$2000
    ld		l,	$0
    call	fillmem
    ; Background state reset
    ld		de,	_SCRN0
    ld		bc,	$2000
    ld		l,	$0
    call	fillmem
    ; Loads the DMA Transfer routine. It will be in charge of updating the OAM RAM during the VBlank interruption
    ld		hl,	DMATransferRoutine
    ld		de,	DMA_TRANSFER
    ld		bc,	DMATransferRoutineEnd - DMATransferRoutine
    call	copymem
    call	sound_off
    ld		a,	LCDCF_DEFAULT
    ld		[rLCDC],	a			; LCD turn on
    ld		a,	1
    ld		[_VBLANK_F],	a		; We wait for the VBlank interruption
    ei
    halt                            ; We wait for the first VBlank interruption, it will reset the OAM RAM
    nop
    ;call	init_sgb
    ;call	init_titlescreen
    ei
main_loop:
.main_loop_0:
    ld      a,	1
    ld      [_VBLANK_F],    a       ; We wait for the VBlank interruption
.main_loop_1:
    halt
    nop
    ld		a,	[_VBLANK_F]
    and		a
    jr		nz,	.main_loop_1        ; If the VBlank interruption didn't occur, we jump
    jr      .main_loop_0

; Vblank implementation
vblank:
    push	af
    push	bc
    push	de
    push	hl
    ld      a,	[_VBLANK_F]
    and     a
    jr      z,	vblank_0    		; If we are not waiting for the interruption, we return
    call	vram_upd
    xor     a
    ld      [_VBLANK_F],    a
vblank_0:
    pop	    hl
    pop	    de
    pop	    bc
    pop	    af
    ret

; VRAM update
vram_upd:
    call	DMA_TRANSFER			; It is charge of writing in the OAM RAM the data of the sprites stored in _OAM
    ret

; Additional routines
; Basic hardware routines
INCLUDE "dev/base/utils.asm"