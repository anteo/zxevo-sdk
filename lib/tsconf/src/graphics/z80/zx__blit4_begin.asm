        MODULE zx__blit4_begin
INCLUDE "graphics/z80/blit4.inc"
IFDEF TSCONF_VIDEO_16C
EXTERN _zx_graphics_begin
EXTERN ts_draw_config
ENDIF
SECTION code_graphics
PUBLIC zx__blit4_begin

; Hold the selected 16C surface and reject source memory in borrowed W3.
;
; if (!selected) return NOT_INITIALIZED;
; if (mode!=16C) return UNSUPPORTED;
; if (source_end>0xc000) return UNSAFE_CONTEXT;
; return graphics_begin(),512,512;
;
; IX=validated common frame; source_end is exclusive and did not wrap.
; L=status, BC/DE=bounds. AF/BC/DE/HL volatile, IX/IY preserved.
zx__blit4_begin:
IFDEF TSCONF_VIDEO_16C
        ld a,(ts_draw_config)
        cp 0ffh
        ld l,4
        ret z
        and 3
        cp 1
        jr nz,@unsupported
        ld a,(ix+BLIT_SOURCE_END+1)
        cp 0c0h
        jr c,@resident
        jr nz,@unsafe
        ld a,(ix+BLIT_SOURCE_END)
        or a
        jr nz,@unsafe
@resident:
        call _zx_graphics_begin
        ld bc,512
        ld de,512
        ret
@unsafe:
        ld l,6
        ret
@unsupported:
ENDIF
        ld l,5
        ret
