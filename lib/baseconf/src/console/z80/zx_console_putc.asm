        MODULE zx_console_putc
SECTION code_clib
PUBLIC _zx_console_putc
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
EXTERN _bc_video_draw_surface_state
EXTERN bc__text_putc
ENDIF
EXTERN _bc_console_active_font
EXTERN zx__ink
EXTERN zx__paper
EXTERN bc__console_control
EXTERN bc__console_advance
EXTERN zx__font_position
EXTERN zx__font_call
EXTERN _zx__console_text_bg
EXTERN _bc__video_begin
EXTERN _bc__video_end
EXTERN __console_x
EXTERN __console_y
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
INCLUDE "console/font_flags.inc"
EXTERN bc__console_font_backend_state
ENDIF

; SDCC character:8. Hardware-text output tail-calls its independent API.
; Graphics use the nine-byte draw context documented in zx__font_call.
; Tabs iterate over spaces, keeping the per-character begin/end/error semantics.
;
; Handles one character or cursor control for the active console and advances
; the cursor after drawing a cell.
;
; Model:
;
; if (hardware_text_mode) return text_putc(c); if (!font) return NOT_INITIALIZED;
; if (c<32 && c!=TAB) return console_control(c);
; if (cached_font_backend_state == FONT_UNSUPPORTED) return UNSUPPORTED;
; do { begin(); draw(c==TAB?' ':c); status=end(); advance_cursor(); }
; while (c==TAB && status==OK && (cursor_x&7)); return status;
;
; The function owns one graphics lease per drawn cell. Persistent draw state
; is IX-9..-1; outgoing callback arguments are separate. Return status in L;
; AF/BC/DE/HL volatile, IX/IY preserved. Newline clamps instead of scrolling.
; Surface and font selection maintain the console grid.
_zx_console_putc:
IFDEF BASECONF_VIDEO_TEXT_HARDWARE
        ld a,(_bc_video_draw_surface_state)
        sub 5
        cp 2
        jp c,bc__text_putc
ENDIF
        ld hl,(_bc_console_active_font)
        ld a,h
        or l
        ld l,4                       ; ZX_NOT_INITIALIZED
        ret z
        push ix
        ld ix,0
        add ix,sp
        ld hl,-9
        add hl,sp
        ld sp,hl
        ld a,(ix+4)
        cp 32
        jr nc,@check_font
        cp 9
        jr z,@check_font
        call bc__console_control
        jr @return
@check_font:
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
        ld a,(bc__console_font_backend_state)
        cp BC_FONT_UNSUPPORTED
        jr z,@unsupported
ENDIF
@draw:
        call _bc__video_begin
        ld a,l
        or a
        jr nz,@return
        ld hl,(_bc_console_active_font)
        ld a,(__console_y)
        ld c,a
        ld a,(__console_x)
        call zx__font_position
        ld a,(zx__ink)
        ld (ix-8),a
        ld a,(zx__paper)
        ld (ix-7),a
        ld a,(ix+4)
        cp 9
        jr nz,@character
        ld a,' '
@character:
        ld (ix-9),a
        ld a,(_zx__console_text_bg)
        call zx__font_call
        call _bc__video_end
        call bc__console_advance      ; preserves the returned status in L
        ld a,(ix+4)
        cp 9
        jr nz,@return
        ld a,l
        or a
        jr nz,@return
        ld a,(__console_x)
        and 7
        jr nz,@draw
@return:
        ld sp,ix
        pop ix
        ret
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
@unsupported:
        ld l,5                       ; ZX_UNSUPPORTED
        jr @return
ENDIF
