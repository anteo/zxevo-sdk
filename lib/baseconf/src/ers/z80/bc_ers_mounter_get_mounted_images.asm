        MODULE bc_ers_mounter_get_mounted_images

SECTION code_clib
PUBLIC _bc_ers_mounter_get_mounted_images
EXTERN _bc_ers_profile

; Copies the four firmware descriptors for mounted drive images.
;
; Model:
;
; if (!images) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x53, 0x03, HL=images); /* four opaque 64-byte records */
; return OK;
;
; Caller-clean: images:16 at entry SP+2; pointer contents stay service-visible.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_get_mounted_images:
        pop bc                      ; return address
        pop hl                      ; pointer
        push hl
        push bc
        ld a,h
        or l
        jp z,bc_ers_mounter_get_mounted_images_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_get_mounted_images_unavailable
        push ix
        rst 08h
        defb 53h,03h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_mounter_get_mounted_images_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret

bc_ers_mounter_get_mounted_images_invalid:
        ld hl,1                     ; ZX_INVALID_ARGUMENT
        ret
