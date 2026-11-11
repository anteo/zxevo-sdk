IFDEF BASECONF_VIDEO_TEXT_ATM_640
        MODULE bc__font5_draw_atm640

SECTION code_clib
PUBLIC bc__font5_draw_atm640
EXTERN bc__font5_draw_return
EXTERN bc__font5_bitmap_init
EXTERN bc__font5_bitmap_address
EXTERN bc__font5_bitmap_masks
EXTERN bc__font5_bitmap_row
EXTERN bc__font5_map_page
EXTERN bc__video_packed_pixels_regs
EXTERN _bc_video_draw_surface_state
EXTERN _bc_video_cpu_base

; Tail entry from the dispatcher: IX is the callback frame, SP=IX-5.
; Use the shared eighteen-byte bitmap context; preserve IX/IY on return.
;
; Draws the glyph across the ATM640 bitmap bytes it touches and sets the
; corresponding attributes.
;
; Model:
;
; map(page1); offset=y*40+(x>>4)+((x&8)?0x2000:0);
; for (row=0; row<height; ++row) merge_glyph_row(offset+row*40);
; if (opaque) { map(page0); write attributes for all touched bitmap bytes; }
;
; Active lease, in-bounds glyph and bitmap context from the dispatcher are
; required. AF/BC/DE/HL volatile; IX/IY restored by the shared epilogue.
; A spill from plane 0 uses +2000h; plane 1 spills to the next group at -1FFFh.
bc__font5_draw_atm640:
        ld hl,-13
        add hl,sp
        ld sp,hl
        ld e,(ix+11)
        ld d,(ix+12)
        call bc__video_packed_pixels_regs
        call bc__font5_bitmap_init
        ld a,(_bc_video_draw_surface_state+2)
        call bc__font5_map_page
        jp nz,bc__font5_draw_return
        ld l,(ix+6)
        ld h,(ix+7)
        add hl,hl
        add hl,hl
        add hl,hl
        ld e,l
        ld d,h
        add hl,hl
        add hl,hl
        add hl,de                    ; y*40
        ld c,(ix+4)
        ld b,(ix+5)
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c
        add hl,bc
        ld bc,2000h
        bit 3,(ix+4)
        jr z,@offset_ready
        add hl,bc
        ld bc,0E001h                 ; spill to plane 0, group +1
@offset_ready:
        call bc__font5_bitmap_address
        call bc__font5_bitmap_masks
        ld a,(ix-4)
        ld (ix-17),a
@row:
        call bc__font5_bitmap_row
        dec (ix-17)
        jr z,@attributes
        ld l,(ix-8)
        ld h,(ix-7)
        ld bc,40
        add hl,bc
        ld (ix-8),l
        ld (ix-7),h
        jr @row
@attributes:
        bit 0,(ix-5)
        jp nz,bc__font5_draw_return
        ld a,(_bc_video_draw_surface_state+1)
        call bc__font5_map_page
        jp nz,bc__font5_draw_return
        ld l,(ix-10)
        ld h,(ix-9)
        ld de,(_bc_video_cpu_base)
        add hl,de
        ld a,(ix-4)
        ld (ix-17),a
@attribute_row:
        ld a,(ix-18)
        ld (hl),a
        ld a,(ix-16)
        cp 9
        jr c,@attribute_next
        push hl
        ld c,(ix-12)
        ld b,(ix-11)
        add hl,bc
        ld a,(ix-18)
        ld (hl),a
        pop hl
@attribute_next:
        ld bc,40
        add hl,bc
        dec (ix-17)
        jr nz,@attribute_row
        jp bc__font5_draw_return
ENDIF
