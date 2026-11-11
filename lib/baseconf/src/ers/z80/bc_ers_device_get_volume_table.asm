        MODULE bc_ers_device_get_volume_table

SECTION code_clib
PUBLIC _bc_ers_device_get_volume_table
EXTERN _bc_ers_profile

; Copies the ERS partition table into a 256-byte caller buffer.
;
; Model:
;
; if (!table) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x03, HL=table); /* writes 256 bytes */
; return OK;
;
; Caller-clean: table:16 at entry SP+2; pointer contents stay service-visible.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_get_volume_table:
        pop bc                      ; return address
        pop hl                      ; pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_device_get_volume_table_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_get_volume_table_unavailable
        push ix
        rst 08h
        defb 50h,03h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_device_get_volume_table_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_device_get_volume_table_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
