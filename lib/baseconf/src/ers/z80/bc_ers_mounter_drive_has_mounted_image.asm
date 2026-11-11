        MODULE bc_ers_mounter_drive_has_mounted_image

SECTION code_clib
PUBLIC _bc_ers_mounter_drive_has_mounted_image
EXTERN _bc_ers_profile

; Reports whether the requested virtual drive currently has an image mounted.
;
; Model:
;
; if (drive >= 4 || !mounted) return INVALID_ARGUMENT;
; if (profile == NONE) return UNAVAILABLE;
; bits = ERS(0x53, 0x08).A; *mounted = (bits >> drive) & 1; return OK;
;
; CMP_DRIVE (53h/07h) in ERS indexes descriptors with a stride of 4 bytes
; instead of 64. Read the mounted-drive bits via 53h/08h.
; IX frame: drive +4, mounted pointer +5. A bits 0..3 map to drives A..D.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_mounter_drive_has_mounted_image:
        push ix
        ld ix,0
        add ix,sp
        ld a,(ix+4)
        cp 4
        jp nc,bc_ers_mounter_drive_has_mounted_image_invalid
        ld e,(ix+5)
        ld d,(ix+6)
        ld a,d
        or e
        jp z,bc_ers_mounter_drive_has_mounted_image_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_mounter_drive_has_mounted_image_unavailable
        rst 08h
        defb 53h,08h
        ld b,(ix+4)
        inc b
bc_ers_mounter_drive_has_mounted_image_shift:
        rrca
        djnz bc_ers_mounter_drive_has_mounted_image_shift
        ld a,0
        adc a,0
        ld e,(ix+5)
        ld d,(ix+6)
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_mounter_drive_has_mounted_image_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_mounter_drive_has_mounted_image_unavailable:
        pop ix
        ld hl,3
        ret
