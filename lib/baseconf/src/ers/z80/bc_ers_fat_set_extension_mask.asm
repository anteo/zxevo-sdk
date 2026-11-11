        MODULE bc_ers_fat_set_extension_mask

SECTION code_clib
PUBLIC _bc_ers_fat_set_extension_mask
EXTERN _bc_ers_profile

; Updates the extension filter used by ERS file searches, clearing it when
; given a null pointer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x07, A=(extensions != NULL), HL=extensions); return OK;
;
; IX frame: extensions pointer +4; NULL clears the filter. Non-NULL buffers
; must satisfy the firmware 49-byte read contract; lengths are not checked.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_set_extension_mask:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_set_extension_mask_unavailable
        ld a,h
        or l
        jr z,bc_ers_fat_set_extension_mask_read
        ld a,1
        jr bc_ers_fat_set_extension_mask_done
bc_ers_fat_set_extension_mask_read:
        xor a
bc_ers_fat_set_extension_mask_done:
        rst 08h
        defb 51h,07h
        pop ix
        ld hl,0
        ret
bc_ers_fat_set_extension_mask_unavailable:
        pop ix
        ld hl,3
        ret
