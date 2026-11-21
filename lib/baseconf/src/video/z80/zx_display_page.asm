        MODULE zx_display_page
SECTION code_clib
PUBLIC _zx_display_page
EXTERN _bc_mem_initialized
EXTERN _bc_video_operation_depth
EXTERN _bc__video_first_screen_pages
EXTERN bc__video_read_mode_regs
EXTERN bc__mem_readback_register_regs
IFNDEF BASECONF_VIDEO_ALL_MODES
EXTERN bc__video_mode_enabled_regs
ENDIF

; Display one of the two hardware screens for the live video mode.
;
; if (!initialized) return ZX_NOT_INITIALIZED;
; if (video_depth) return ZX_BUSY;
; mode, eff7 = read_video_mode();
; if (mode == ZX_VIDEO_UNKNOWN) return ZX_UNAVAILABLE;
; if (!enabled(mode)) return ZX_UNSUPPORTED;
; delta = page - first_screen_pages[mode];
; if (delta != 0 && delta != 2) return ZX_INVALID_ARGUMENT;
; paging = readback(0x0a);
; if ((paging & 8) == (delta << 2)) return ZX_OK;
; if ((paging & 0x20) && (eff7 & 4)) return ZX_BUSY;
; out(0x7ffd, paging ^ 8);
; return ZX_OK;
;
; SDCC page byte at SP+2. Status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL.
; Save the requested page on the stack during readback. Use the same EFF7
; sample for layout decoding and checking the 7FFD lock.
_zx_display_page:
        ld hl,2
        add hl,sp
        ld d,(hl)
        ld a,(_bc_mem_initialized)
        or a
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        ld a,(_bc_video_operation_depth)
        or a
        ld l,2                       ; ZX_BUSY
        ret nz

        push de
        call bc__video_read_mode_regs
        pop de                       ; D = requested page
        ld a,l
        cp 0FFh
        jr z,@unavailable
        ld c,b                       ; sampled EFF7
        ld e,a                       ; mode index
IFNDEF BASECONF_VIDEO_ALL_MODES
        call bc__video_mode_enabled_regs
        ld a,l
        or a
        jr z,@unsupported
ENDIF
        ld a,d
        ld d,0
        ld hl,_bc__video_first_screen_pages
        add hl,de
        sub (hl)
        jr z,@screen_bit
        cp 2
        jr nz,@invalid
@screen_bit:
        add a,a
        add a,a                      ; page delta 0/2 -> 7FFD bit 3 clear/set
        ld e,a
        ld d,c                       ; retain EFF7 across the 7FFD readback
        ld b,0Ah
        call bc__mem_readback_register_regs
        ld a,l
        xor e
        and 8
        jr z,@ok
        bit 5,l
        jr z,@flip
        bit 2,d
        jr nz,@busy
@flip:
        ld a,l
        xor 8                        ; screen differs, so only bit 3 changes
        ld bc,7FFDh
        out (c),a
@ok:
        ld l,0                       ; ZX_OK
        ret

@busy:
        ld l,2                       ; ZX_BUSY while locked in 128K mode
        ret
@unavailable:
        ld l,3                       ; ZX_UNAVAILABLE
        ret
IFNDEF BASECONF_VIDEO_ALL_MODES
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret

