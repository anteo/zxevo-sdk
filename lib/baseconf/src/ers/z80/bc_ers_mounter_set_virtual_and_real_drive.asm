        MODULE bc_ers_mounter_set_virtual_and_real_drive

SECTION code_clib
PUBLIC _bc_ers_mounter_set_virtual_and_real_drive
EXTERN _bc_ers_profile

; Assigns the same drive number to both the real and virtual drive
; selections.
;
; Model:
;
; if (drive >= 4) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x09, A=drive);
; return OK;
;
; Caller-clean: drive is read from the low byte of the entry SP+2 slot.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_set_virtual_and_real_drive:
        pop bc                      ; return address
        pop hl                      ; argument
        push hl
        push bc
        ld a,l
        cp 4
        jp nc,bc_ers_mounter_set_virtual_and_real_drive_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_set_virtual_and_real_drive_unavailable
        ld a,l
        push ix
        rst 08h
        defb 53h,09h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_mounter_set_virtual_and_real_drive_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_mounter_set_virtual_and_real_drive_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
