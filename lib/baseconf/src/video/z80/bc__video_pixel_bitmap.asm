IFDEF BASECONF_VIDEO_MODE_ZX_BITMAP
defc BC_VIDEO_PIXEL_BITMAP_ENABLED = 1
ELSE
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
defc BC_VIDEO_PIXEL_BITMAP_ENABLED = 1
ENDIF
ENDIF
IFDEF BC_VIDEO_PIXEL_BITMAP_ENABLED
        MODULE bc__video_pixel_bitmap
SECTION code_clib
PUBLIC bc__video_pixel_bitmap
EXTERN bc__video_pixel_mask
EXTERN bc__video_pixel_bool_return
EXTERN zx__ink
EXTERN zx__paper
IFDEF BASECONF_VIDEO_MODE_ZX_BITMAP
EXTERN zx__encode_attribute
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
defc BC_BITMAP_BOTH_FORMATS = 1
ENDIF
ENDIF
IFDEF BASECONF_VIDEO_MODE_ENABLED_ATM_640
EXTERN bc__video_packed_pixels_regs
ENDIF

; Read, test or paint a bitmap pixel with a separate attribute byte.
;
; mask = 0x80 >> (x & 7);
; if (op == TEST) return (*bitmap & mask) != 0;
; if (op == READ) return decode(*attr, (*bitmap & mask) != 0, format);
; paper = current_paper; clear = color == paper;
; ink = clear ? current_ink : color;
; *attr = encode(ink, paper, format);
; *bitmap = clear ? *bitmap & ~mask : *bitmap | mask;
;
; HL=bitmap, DE=attribute, A=low X, B=color, C=READ/COLOR/TEST.
; CF selects independent ATM brightness when set. The active video lease
; supplies valid addresses. Index or test result in L. Preserve IX/IY.
; Save addresses across mask generation and the format flag in mixed builds.
bc__video_pixel_bitmap:
IFDEF BC_BITMAP_BOTH_FORMATS
        push af
ENDIF
        push hl
        push de
        and 7
        call bc__video_pixel_mask
        pop de
        pop hl
        bit 2,c
        jr z,@read                   ; READ=3
        bit 0,c
        jr z,@write                  ; COLOR=4, TEST=5
        and (hl)
IFDEF BC_BITMAP_BOTH_FORMATS
        pop bc
ENDIF
        jp bc__video_pixel_bool_return

@read:
        and (hl)
        ld a,(de)
IFDEF BC_BITMAP_BOTH_FORMATS
        pop bc                       ; C bit 0 is the saved format flag
ENDIF
        ld b,a
        jr z,@background
        and 7
        bit 6,b                      ; ink bright in both formats
        jr @bright
@background:
        rrca
        rrca
        rrca
        and 7
IFDEF BC_BITMAP_BOTH_FORMATS
        bit 0,c
        jr z,@shared_bright
        bit 7,b
        jr @bright
@shared_bright:
ENDIF
IFDEF BASECONF_VIDEO_MODE_ZX_BITMAP
        bit 6,b
ELSE
        bit 7,b
ENDIF
@bright:
        jr z,@return_index
        or 8
@return_index:
        ld l,a
        ret

@write:
        ld c,b                       ; requested color
        ld b,a                       ; bitmap mask
IFDEF BC_BITMAP_BOTH_FORMATS
        pop af
ENDIF
        push hl
        push de
IFDEF BC_BITMAP_BOTH_FORMATS
        push af
ENDIF
        ld e,c
        ld a,(zx__paper)
        ld d,a
        ld c,0
        cp e
        jr nz,@encode
        inc c                        ; painting current paper clears the bit
        ld a,(zx__ink)
        ld e,a
@encode:
IFDEF BC_BITMAP_BOTH_FORMATS
        pop af
        jr nc,@encode_zx
        call bc__video_packed_pixels_regs
        jr @attribute
@encode_zx:
ENDIF
IFDEF BASECONF_VIDEO_MODE_ZX_BITMAP
        call zx__encode_attribute
ELSE
        call bc__video_packed_pixels_regs
ENDIF
@attribute:
        pop hl
        ld (hl),a
        pop hl
        ld a,c
        or a
        ld a,b
        jr z,@set
        cpl
        and (hl)
        jr @store
@set:
        or (hl)
@store:
        ld (hl),a
        ret
ENDIF
