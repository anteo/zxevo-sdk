        MODULE bc_ers_device_set_volume

SECTION code_clib
PUBLIC _bc_ers_device_set_volume
EXTERN _bc_ers_profile

; Selects a FAT partition by index and reports when ERS rejects it.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x01, A=index);
; if (CF) return INVALID_ARGUMENT;
; return OK;
;
; Caller-clean: index is read from the low byte of the entry SP+2 slot.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_set_volume:
        pop bc                      ; return address
        pop hl                      ; argument
        push hl
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_set_volume_unavailable
        ld a,l
        push ix
        rst 08h
        defb 50h,01h
        pop ix
        jp c,bc_ers_device_set_volume_invalid
        ld hl,0                     ; ZX_OK
        ret

bc_ers_device_set_volume_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_device_set_volume_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
