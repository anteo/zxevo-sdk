        MODULE bc_ers_device_set_sector_number

SECTION code_clib
PUBLIC _bc_ers_device_set_sector_number
EXTERN _bc_ers_profile

; Sets the 48-bit sector number used by the ERS driver for subsequent
; transfers.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x09, HL=high, BC=middle, DE=low); return OK;
;
; IX frame: high +4, middle +6, low +8; each word is two bytes.
; The 48-bit sector is high:middle:low; no data transfer occurs.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_set_sector_number:
        push ix
        ld ix,0
        add ix,sp
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_set_sector_number_unavailable
        ld l,(ix+4)
        ld h,(ix+5)
        ld c,(ix+6)
        ld b,(ix+7)
        ld e,(ix+8)
        ld d,(ix+9)
        rst 08h
        defb 50h,09h
        pop ix
        ld hl,0
        ret
bc_ers_device_set_sector_number_unavailable:
        pop ix
        ld hl,3
        ret
