        MODULE bc_ers_mounter_load_current_image

SECTION code_clib
PUBLIC _bc_ers_mounter_load_current_image
EXTERN _bc_ers_profile

; Loads the selected image into its firmware RAM disk or tape buffer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x05); /* load the current image into RAM */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_load_current_image:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_load_current_image_unavailable
        rst 08h
        defb 53h,05h
        ld hl,0                     ; ZX_OK
        ret

bc_ers_mounter_load_current_image_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
