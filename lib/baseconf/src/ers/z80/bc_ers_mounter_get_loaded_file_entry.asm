        MODULE bc_ers_mounter_get_loaded_file_entry

SECTION code_clib
PUBLIC _bc_ers_mounter_get_loaded_file_entry
EXTERN _bc_ers_profile

; Copies the FAT directory record for the image loaded into the RAM disk.
;
; Model:
;
; if (!entry) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x06, HL=entry); /* copies a 32-byte directory record */
; return OK;
;
; Caller-clean: entry:16 at entry SP+2; pointer contents stay service-visible.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_get_loaded_file_entry:
        pop bc                      ; return address
        pop hl                      ; pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_mounter_get_loaded_file_entry_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_get_loaded_file_entry_unavailable
        push ix
        rst 08h
        defb 53h,06h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_mounter_get_loaded_file_entry_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_mounter_get_loaded_file_entry_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
