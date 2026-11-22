        MODULE bc__font5_bitmap_init
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
SECTION code_clib
PUBLIC bc__font5_bitmap_init

; Shared ZX256/ATM640 context, anchored at the saved-IX callback frame:
; x +4, y +6, font +8, code +10, ink +11, paper +12.
; Caller reserves eighteen bytes: -2 glyph, -3 width, -4 height, -5 background,
; -6 shift, -8 bitmap, -10 initial address (ZX) or offset (ATM),
; -12 spill delta, -13 glyph mask,
; -14/-15 clear masks, -16 width+shift, -17 rows remaining, -18 attribute.
; These helpers preserve IX/IY and do not select a video mode.

; A = mode-specific attribute. Initialize character-wide values once.
;
; Prepares the glyph attribute and records how far the glyph extends across
; the destination bytes.
;
; Model:
;
; shift=x&7; span=shift+width; context.attribute=A.
;
; Uses the eighteen-byte persistent context above. AF clobbered; BC/DE/HL and
; IX/IY retained. No bitmap access until the caller maps a page.
bc__font5_bitmap_init:
        ld (ix-18),a
        ld a,(ix+4)
        and 7
        ld (ix-6),a
        add a,(ix-3)
        ld (ix-16),a                 ; a second byte is needed when >=9
        ret
ENDIF
