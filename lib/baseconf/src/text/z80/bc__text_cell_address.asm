        MODULE bc__text_cell_address

SECTION code_clib
PUBLIC bc__text_cell_address

; IX = caller's frame after saving IX. SDCC arguments:
; surface { mode +4, page0 +5, page1 +6 }, x +7, y +8.
; Return A = character page, DE = character offset. IX/IY are preserved.
;
; Resolves a hardware text cell to the character page and byte offset for its
; mode and column parity.
;
; Model:
;
; offset=y*64+(x>>1);
; if (surface.mode==ATM_TEXT_80) { page=surface.page1; offset+=(x&1)?0x21c0:0x01c0; }
; else { page=surface.page0; offset+=(x&1)?0x11c0:0x01c0; }
;
; Caller supplies a hardware text mode and in-range cell (x<80,y<25).
; No mapping or lease acquisition here. AF/DE/HL clobbered; BC/IX/IY preserved.
; Interleaved columns use x/2 within a 64-byte row, with parity selecting a plane.
bc__text_cell_address:
        ld l,(ix+8)
        ld h,0
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl
        add hl,hl                    ; y * 64
        ld e,(ix+7)
        srl e
        ld d,0
        add hl,de                    ; y * 64 + x / 2
        ex de,hl

        ld a,(ix+4)
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        ld a,(ix+5)                  ; Evolution uses page0
        ld h,11h                     ; Evolution odd-column base: 11C0h
        jr nz,@column
        ld a,(ix+6)                  ; ATM characters use page1
        ld h,21h                     ; ATM odd-column base: 21C0h
@column:
        bit 0,(ix+7)
        jr nz,@address
        ld h,01h                     ; both even-column bases: 01C0h
@address:
        ld l,0C0h
        add hl,de
        ex de,hl
        ret
