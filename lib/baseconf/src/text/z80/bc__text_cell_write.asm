        MODULE bc__text_cell_write

SECTION code_clib
PUBLIC _bc__text_cell_write
EXTERN bc__text_cell_address
EXTERN bc__video_write_memory_regs
EXTERN _bc__text_encode_attribute

; SDCC frame: mode +4, surface { mode +5, page0 +6, page1 +7 },
; x +8, y +9, character +10. IX/IY are preserved.
;
; Writes a character and its encoded color attribute into one hardware text
; cell.
;
; Model:
;
; (page,offset)=text_cell_address(mode,surface,x,y); write_memory(page,offset,c);
; delta=(mode==ATM_TEXT_80)?((x&1)?-0x1fff:0x2000):((x&1)?0x1001:0x3000);
; write_memory(surface.page0,offset+delta,encode_attribute());
;
; Caller holds a lease, maps the selected surface and supplies x<80,y<25.
; AF/BC/DE/HL volatile; IX/IY preserved. The attribute encoder retains DE,
; so the character offset needs no stack local or duplicate coordinate multiply.
_bc__text_cell_write:
        push ix
        ld ix,0
        add ix,sp
        call bc__text_cell_address
        ld c,(ix+10)
        call bc__video_write_memory_regs

        call _bc__text_encode_attribute ; preserves the character offset in DE
        ld c,l

        ; Attribute offsets relative to the character offset:
        ; Evolution even +3000h, odd +1001h; ATM even +2000h, odd -1FFFh.
        ld a,(ix+4)
        cp 5                         ; BC_VIDEO_ATM_TEXT_80
        jr z,@atm
        ld hl,3000h
        bit 0,(ix+8)
        jr z,@attribute
        ld hl,1001h
        jr @attribute
@atm:
        ld hl,2000h
        bit 0,(ix+8)
        jr z,@attribute
        ld hl,0E001h
@attribute:
        add hl,de
        ex de,hl
        ld a,(ix+6)                  ; attributes always use surface.page0
        call bc__video_write_memory_regs
        pop ix
        ret
