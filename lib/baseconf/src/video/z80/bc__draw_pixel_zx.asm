        MODULE bc_draw_pixel_zx
SECTION code_graphics
PUBLIC _bc__draw_zx_set
PUBLIC _bc__draw_zx_clear
PUBLIC _bc__draw_zx_xor
PUBLIC _bc__draw_zx_set_clipped
PUBLIC _bc__draw_zx_clear_clipped
PUBLIC _bc__draw_zx_xor_clipped
EXTERN _bc__draw_clip_point
EXTERN _bc_video_page0_base
EXTERN zx__set, zx__clear, zx__xor

; Sets the ZX bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) set_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_zx_set_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_zx_set

; Clears the ZX bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) clear_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_zx_clear_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_zx_clear

; Toggles the ZX bitmap pixel only when the point is inside the surface.
;
; Model:
;
; if (clip_point(x,y)) xor_pixel(x,y);
;
; Native callback, HL=x,DE=y; no C stack arguments or result. Caller owns
; the prepared lease and mapped bases. AF/BC/DE/HL volatile; IX/IY preserved.
; The unchecked entry requires in-range coordinates; the clipped entry rejects
; outside pixels before any bitmap access. Attributes and paging remain unchanged.
; clip_point returns CF=inside, the opposite of the axis clipper's CF=empty.
_bc__draw_zx_xor_clipped:
        call _bc__draw_clip_point
        ret nc
        jp _bc__draw_zx_xor

; Set a ZX bit in the active lease's mapped screen.
; HL=x, DE=y in bounds. Clobbers AF/BC/DE/HL, preserves IX/IY.
_bc__draw_zx_set:
        ld a,(_bc_video_page0_base+1)
        jp zx__set

; Clear a ZX bit in the active lease's mapped screen.
; HL=x, DE=y in bounds. Clobbers AF/BC/DE/HL, preserves IX/IY.
_bc__draw_zx_clear:
        ld a,(_bc_video_page0_base+1)
        jp zx__clear

; Xor a ZX bit in the active lease's mapped screen.
; HL=x, DE=y in bounds. Clobbers AF/BC/DE/HL, preserves IX/IY.
_bc__draw_zx_xor:
        ld a,(_bc_video_page0_base+1)
        jp zx__xor
