        MODULE bc__mem_detect_readback
SECTION code_clib
PUBLIC _bc__mem_detect_readback
EXTERN _bc__mem_readback_is_unsafe
EXTERN _bc_mem_readback_port

; Choose the first responding readback port. Keep the previous port if both
; probes fail, so a failed reinitialization leaves the cached selection intact.
;
; if (!probe_failed(BD)) readback_port = 0xbd;
; else if (!probe_failed(BE)) readback_port = 0xbe;
; else return 0;
; return 1;
;
; SDCC: no arguments, L = success. Clobbers AF/BC/HL, preserves DE/IX/IY.
_bc__mem_detect_readback:
        ld l,0                       ; BC_READBACK_BD
        call _bc__mem_readback_is_unsafe
        ld a,l
        or a
        ld a,0bdh
        jr z,@selected
        ld l,1                       ; BC_READBACK_BE
        call _bc__mem_readback_is_unsafe
        ld a,l
        or a
        ld l,0
        ret nz
        ld a,0beh
@selected:
        ld (_bc_mem_readback_port),a
        ld l,1
        ret
