        MODULE bc_ers_mounter_get_virtual_drive_bits

SECTION code_clib
PUBLIC _bc_ers_mounter_get_virtual_drive_bits
EXTERN _bc_ers_profile

; Reads the firmware bit fields that describe virtual drive assignments.
;
; Model:
;
; if (!bits) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x08); *bits = A; return OK;
;
; IX frame: bits pointer +4. The returned bit fields are copied verbatim.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_get_virtual_drive_bits:
        push ix
        ld ix,0
        add ix,sp
        ld e,(ix+4)
        ld d,(ix+5)
        ld a,d
        or e
        jp z,bc_ers_mounter_get_virtual_drive_bits_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_get_virtual_drive_bits_unavailable
        rst 08h
        defb 53h,08h
        ld e,(ix+4)
        ld d,(ix+5)
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_mounter_get_virtual_drive_bits_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_mounter_get_virtual_drive_bits_unavailable:
        pop ix
        ld hl,3
        ret
