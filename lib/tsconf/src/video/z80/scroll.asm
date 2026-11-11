        MODULE ts_video_scroll
SECTION code_clib
PUBLIC _ts_video_set_scroll
PUBLIC _ts_video_set_tile0_scroll
PUBLIC _ts_video_set_tile1_scroll

; Write one plane's graphics or tile offsets, keeping nine bits per axis.
;
; out_ts(first, x & 255);
; out_ts(first + 1, (x >> 8) & 1);
; out_ts(first + 2, y & 255);
; out_ts(first + 3, (y >> 8) & 1);
;
; SDCC classic for all three entries: x at SP+2, y at SP+4. No local frame.
; Clobbers AF, BC and HL. Preserves DE, IX, IY and SP.
; Caller chooses raster timing and excludes concurrent offset writers.
_ts_video_set_tile0_scroll:
        ld a,41h
        jr write_offsets

_ts_video_set_tile1_scroll:
        ld a,45h
        jr write_offsets

_ts_video_set_scroll:
        ld a,03h
write_offsets:
        ld hl,2
        add hl,sp
        ; OUTI uses B after decrementing it. Each entry supplies first + 1.
        ld b,a
        ld c,0afh
        outi
        inc b
        ld a,(hl)
        and 1
        out (c),a
        inc hl
        inc b
        inc b
        outi
        inc b
        ld a,(hl)
        and 1
        out (c),a
        ret
