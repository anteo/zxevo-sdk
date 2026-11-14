        MODULE zx_ay_select_chip
SECTION code_sound_ay
PUBLIC _zx_ay_select_chip

; Select an AY chip using the TurboSound commands at the AY address port.
;
; if (chip>1) return INVALID_ARGUMENT;
; OUT(0xfffd,0xff-chip); return OK;
;
; Fastcall L=chip (0=first,1=second), result L=zx_status_t.
; AF/BC/L volatile; DE/H/IX/IY/SP and IFF preserved. Selection persists.
; Caller owns selection and subsequent AY writes across IRQ/NMI callbacks.
; No hardware detection, register reset or independent player state is implied.
_zx_ay_select_chip:
        ld a,l
        cp 2
        jr nc,@invalid
        cpl                          ; CHIP_0 -> FFh, CHIP_1 -> FEh
        ld bc,0fffdh
        out (c),a
        ld l,0
        ret
@invalid:
        ld l,1
        ret
