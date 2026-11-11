        MODULE bc_ers_device_get_current_volume

SECTION code_clib
PUBLIC _bc_ers_device_get_current_volume
EXTERN _bc_ers_profile

; Returns the active ERS partition number, partition count, filesystem type
; and presence flag.
;
; Model:
;
; if (!info) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x50, 0x02); *info = {D, E, A, !CF}; return OK;
;
; IX frame: info pointer +4; IX then becomes the four-byte output record.
; The service must preserve that output IX; saved caller IX remains on the stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_device_get_current_volume:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_device_get_current_volume_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_device_get_current_volume_unavailable
        push hl
        pop ix
        rst 08h
        defb 50h,02h
        ld (ix+0),d
        ld (ix+1),e
        ld (ix+2),a
        ld a,0
        adc a,0
        xor 1
        ld (ix+3),a
        pop ix
        ld hl,0
        ret
bc_ers_device_get_current_volume_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_device_get_current_volume_unavailable:
        pop ix
        ld hl,3
        ret
