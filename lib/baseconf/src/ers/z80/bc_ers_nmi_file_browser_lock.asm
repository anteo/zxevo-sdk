        MODULE bc_ers_nmi_file_browser_lock

SECTION code_clib
PUBLIC _bc_ers_nmi_file_browser_lock
EXTERN _bc_ers_profile

; Enables or disables entry to the ERS file browser through NMI.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x4f, A=(locked != 0));
; return OK;
;
; Caller-clean: locked is read from the low byte of the entry SP+2 slot.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_nmi_file_browser_lock:
        pop bc                      ; return address
        pop hl                      ; argument
        push hl
        push bc
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_nmi_file_browser_lock_unavailable
        ld a,l
        or a
        jr z,bc_ers_nmi_file_browser_lock_call
        ld a,1
bc_ers_nmi_file_browser_lock_call:
        push ix
        rst 08h
        defb 4fh
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_nmi_file_browser_lock_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
