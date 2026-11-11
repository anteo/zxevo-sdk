        MODULE bc_ers_cmos_read

SECTION code_clib
PUBLIC _bc_ers_cmos_read
EXTERN _bc_ers_profile

; Reads the CMOS byte at the supplied index through ERS and stores it in the
; caller's output.
;
; Model:
;
; if (!value) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x55, 0x01, H=index); *value = L; return OK;
;
; IX frame: index at +4, value pointer at +5. The byte argument and pointer
; are packed with no padding. Save the output pointer on the stack across RST
; because the firmware does not promise to preserve IX.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_cmos_read:
        push ix
        ld ix,0
        add ix,sp
        ld e,(ix+5)
        ld d,(ix+6)
        ld a,d
        or e
        jp z,bc_ers_cmos_read_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_cmos_read_unavailable
        ld h,(ix+4)                ; RTC index
        push de                    ; keep output pointer independent of IX
        rst 08h
        defb 55h,01h
        pop de
        ld a,l
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_cmos_read_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_cmos_read_unavailable:
        pop ix
        ld hl,3
        ret
