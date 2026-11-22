        MODULE ts__graphics_begin_writer
IFDEF TSCONF_VIDEO_BITMAP
EXTERN ts_draw_config
IFDEF TSCONF_VIDEO_PACKED
EXTERN ts__packed_operation
EXTERN ts_draw_page
EXTERN ts_packed_begin
EXTERN ts_packed_write
EXTERN zx__ink
EXTERN zx__paper
ENDIF
IFDEF TSCONF_VIDEO_ZX
EXTERN _ts__draw_window_leased
EXTERN ts_draw_base
EXTERN zx__clear
EXTERN zx__set_clipped
EXTERN zx__xor
ENDIF
SECTION code_graphics
PUBLIC ts__graphics_begin_writer

; Select the native clipped pixel writer and hold its packed mapping.
;
; if (op > XOR || !bitmap_selected) return failure;
; if (packed) {
;     begin(page, mode, op == CLEAR ? paper : ink);
;     packed_operation = op;
;     return (packed_writer, 512, 512);
; }
; if (draw_window_leased) return failure;
; return (zx_writer(op), 256, 192);
;
; A=operation. Carry on failure. On success HL=writer and
; BC/DE=width/height. Each success must be paired with end_writer.
; The writer takes HL=x, DE=y and preserves IX/IY.
ts__graphics_begin_writer:
        cp 3
        ccf
        ret c                        ; invalid operation
        ld c,a
        ld a,(ts_draw_config)
        and 3
        cp 3
        jp z,writer_invalid
IFDEF TSCONF_VIDEO_PACKED
IFDEF TSCONF_VIDEO_ZX
        or a
        jr z,@zx
ENDIF
        ld a,c
        cp 1
        ld hl,zx__ink
        jr nz,@packed_color
        ld hl,zx__paper
@packed_color:
        ld e,(hl)
        push bc                      ; preserve the operation while claiming W3
        ld a,(ts_draw_config)
        and 3
        ld hl,ts_draw_page
        ld d,(hl)
        call ts_packed_begin
        pop bc
        ret c
        ld a,c
        ld (ts__packed_operation),a
        ld hl,ts_packed_write
        ld bc,512
        ld de,512
        or a
        ret
ENDIF
IFDEF TSCONF_VIDEO_ZX
@zx:
        ld a,(_ts__draw_window_leased)
        or a
        jr nz,writer_invalid
        ld a,c
        ld hl,write_zx_set
        or a
        jr z,@zx_ready
        ld hl,write_zx_xor
        cp 2
        jr z,@zx_ready
        ld hl,write_zx_clear
@zx_ready:
        ld bc,256
        ld de,192
        or a
        ret

write_zx_set:
        ld a,(ts_draw_base)
        jp zx__set_clipped
write_zx_clear:
        call zx_inside
        ret nc
        jp zx__clear
write_zx_xor:
        call zx_inside
        ret nc
        jp zx__xor

; Return carry and A=window base high byte for a visible ZX pixel.
zx_inside:
        ld a,h
        or d
        ret nz
        ld a,e
        cp 192
        ld a,(ts_draw_base)
        ret
ENDIF
writer_invalid:
        scf
        ret
ENDIF
