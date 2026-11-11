        MODULE bc_ers_device_check_sd

SECTION code_clib
PUBLIC _bc_ers_device_check_sd
EXTERN _bc_ers_profile

; Queries ERS for the availability of the built-in and NeoGS SD interfaces.
;
; Model:
;
; if (!availability) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x06); *availability = A; return OK;
;
; IX frame: availability pointer at +4. Service may display card-change UI.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_check_sd:
        push ix
        ld ix,0
        add ix,sp
        ld e,(ix+4)
        ld d,(ix+5)
        ld a,d
        or e
        jp z,bc_ers_device_check_sd_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_check_sd_unavailable
        rst 08h
        defb 50h,06h
        ld e,(ix+4)
        ld d,(ix+5)
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_device_check_sd_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_device_check_sd_unavailable:
        pop ix
        ld hl,3
        ret
