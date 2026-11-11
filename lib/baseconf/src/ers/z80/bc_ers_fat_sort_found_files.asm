        MODULE bc_ers_fat_sort_found_files

SECTION code_clib
PUBLIC _bc_ers_fat_sort_found_files
EXTERN _bc_ers_profile

; Sorts the file list already collected by ERS.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x52); /* sort the current internal list */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_sort_found_files:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_sort_found_files_unavailable
        rst 08h
        defb 52h
        ld hl,0                     ; ZX_OK
        ret

bc_ers_fat_sort_found_files_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
