        MODULE bc_ers_cmos_write

SECTION code_clib
PUBLIC _bc_ers_cmos_write
EXTERN _bc_ers_profile

; Writes one CMOS setting through ERS, which also updates the settings
; checksum.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x55, 0x02, H=index, L=value); return OK; /* ERS also updates its CMOS CRC */
;
; IX frame: index at +4, value at +5; byte arguments are packed without
; padding. No persistent locals.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_cmos_write:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_cmos_write_unavailable
        ld h,(ix+4)                ; RTC index
        ld l,(ix+5)                ; value
        rst 08h
        defb 55h,02h
        pop ix
        ld hl,0
        ret
bc_ers_cmos_write_unavailable:
        pop ix
        ld hl,3
        ret
