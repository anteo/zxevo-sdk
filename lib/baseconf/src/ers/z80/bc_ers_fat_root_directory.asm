        MODULE bc_ers_fat_root_directory

SECTION code_clib
PUBLIC _bc_ers_fat_root_directory
EXTERN _bc_ers_profile

; Selects the root directory of the active FAT partition.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x0c); /* select root directory */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_root_directory:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_root_directory_unavailable
        rst 08h
        defb 51h,0ch
        ld hl,0                     ; ZX_OK
        ret

bc_ers_fat_root_directory_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
