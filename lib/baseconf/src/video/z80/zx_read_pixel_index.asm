        MODULE zx_read_pixel_index
SECTION code_clib
PUBLIC _zx_read_pixel_index
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
EXTERN _bc_video_draw_surface_state
EXTERN _bc__video_width
EXTERN _bc__video_height
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN bc__video_pixel_regs
IFNDEF BASECONF_VIDEO_PRIMITIVE_ALL
EXTERN bc__video_primitive_mode_enabled_regs
ENDIF
ENDIF

; Read the palette index at a pixel of the selected draw surface. The caller's
; output byte is written only when the video operation completes successfully.
; Model:
;
; if (!index) return ZX_INVALID_ARGUMENT;
; if (!primitive_mode_enabled(mode)) return ZX_UNSUPPORTED;
; if (x >= width() || y >= height()) return ZX_INVALID_ARGUMENT;
; status = begin(); if (status != ZX_OK) return status;
; value = pixel(x, y, READ, 0);
; status = end(); if (status == ZX_OK) *index = value;
; return status;
;
; SDCC x:16 at SP+2, y:16 at SP+4, index:16 at SP+6. Status in L.
; Preserve IX/IY, clobber AF/BC/DE/HL. After saving IX, x/y/index are at
; IX+4/+6/+8. Pass coordinates and READ in registers and save the result
; word across end(). No static scratch.
_zx_read_pixel_index:
        ld hl,6
        add hl,sp
        ld a,(hl)
        inc hl
        or (hl)
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret z
IFDEF BASECONF_VIDEO_PRIMITIVE_GRAPHICS
        ld a,(_bc_video_draw_surface_state)
IFDEF BASECONF_VIDEO_PRIMITIVE_ALL
        cp 5                         ; modes 0..4 are pixel modes
        ld l,5                       ; ZX_UNSUPPORTED
        ret nc
ELSE
        call bc__video_primitive_mode_enabled_regs
        ld a,l
        or a
        ld l,5                       ; ZX_UNSUPPORTED
        ret z
ENDIF

        push ix
        ld ix,0
        add ix,sp
        call _bc__video_width
        ld e,(ix+4)
        ld d,(ix+5)
        scf                          ; borrow in width - x - 1 iff x >= width
        sbc hl,de
        jr c,@invalid
        call _bc__video_height
        ld e,(ix+6)
        ld d,(ix+7)
        scf
        sbc hl,de
        jr c,@invalid
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@done

        ld bc,3                      ; READ, color unused
        ld e,(ix+6)
        ld d,(ix+7)
        ld l,(ix+4)
        ld h,(ix+5)
        call bc__video_pixel_regs
        push hl                      ; color index in L
        call _bc__video_end
        pop bc                       ; color index in C, status still in L
        ld a,l
        or a
        jr nz,@done
        ld e,(ix+8)
        ld d,(ix+9)
        ld a,c
        ld (de),a
@done:
        pop ix
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        jr @done
ELSE
        ld l,5                       ; ZX_UNSUPPORTED
        ret
ENDIF
