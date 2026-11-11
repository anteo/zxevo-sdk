        MODULE bc_ers_mounter_find_mounted_files

SECTION code_clib
PUBLIC _bc_ers_mounter_find_mounted_files
EXTERN _bc_ers_profile

; Loads the image list from IMAGE.MNT and mounts the entries it names.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x02); /* mount entries described by IMAGE.MNT */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_find_mounted_files:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_find_mounted_files_unavailable
        rst 08h
        defb 53h,02h
        ld hl,0                     ; ZX_OK
        ret

bc_ers_mounter_find_mounted_files_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
