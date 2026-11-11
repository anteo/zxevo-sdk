        MODULE bc_ers_fat_open_file

SECTION code_clib
PUBLIC _bc_ers_fat_open_file
EXTERN _bc_ers_profile

; Opens the currently selected ERS file for sequential reads.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x08); /* open the selected file */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_open_file:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_open_file_unavailable
        rst 08h
        defb 51h,08h
        ld hl,0                     ; ZX_OK
        ret

bc_ers_fat_open_file_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
