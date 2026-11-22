        MODULE bc__font5_bitmap_address
IFDEF BASECONF_VIDEO_TEXT_ZX_BITMAP
defc BC_FONT5_BITMAP = 1
ELSE
IFDEF BASECONF_VIDEO_TEXT_ATM_640
defc BC_FONT5_BITMAP = 1
ENDIF
ENDIF
IFDEF BC_FONT5_BITMAP
EXTERN _bc_video_cpu_base
SECTION code_clib
PUBLIC bc__font5_bitmap_address

; HL = initial raster offset, BC = delta to a spill byte.
; Retain the offset for the ATM attribute plane and cache the bitmap address.
;
; Records the starting bitmap address and the displacement to a second byte
; when the glyph straddles a boundary.
;
; Model:
;
; initial_offset=HL; spill_delta=BC; bitmap=cpu_base+HL.
;
; Keep offset separately so attributes can be addressed after another page map.
; DE/HL/flags volatile; BC and IX/IY preserved; writes only the named locals.
bc__font5_bitmap_address:
        ld (ix-10),l
        ld (ix-9),h
        ld (ix-12),c
        ld (ix-11),b
        ld de,(_bc_video_cpu_base)
        add hl,de
        ld (ix-8),l
        ld (ix-7),h
        ret
ENDIF
