        MODULE ts_video_write_tile
SECTION code_clib
PUBLIC _ts_video_write_tile

; Write one little-endian descriptor into the mapped TSU tile map.
;
; offset = 256 * (row & 63) + 128 * (layer & 1) + 2 * (column & 63);
; store_le16(map + offset, entry);
;
; SDCC classic: map at SP+2, layer at SP+4, column at SP+5, row at SP+6,
; entry at SP+7. No local frame. Clobbers AF, BC, DE and HL.
; Preserves IX, IY and SP. Map must be the base of a writable 16 KiB window
; with TMPage mapped. The caller synchronizes writes to a visible map.
_ts_video_write_tile:
        ld hl,3
        add hl,sp
        ; A window base contributes only bits 15:14, so the row fits in D.
        ld d,(hl)
        inc hl
        ld a,(hl)
        rrca
        and 80h
        ld e,a
        inc hl
        ; Each 256-byte row has 128 bytes per layer, two per descriptor.
        ld a,(hl)
        add a,a
        and 7eh
        or e
        ld e,a
        inc hl
        ld a,(hl)
        and 3fh
        or d
        ld d,a
        inc hl
        ldi
        ldi
        ret
