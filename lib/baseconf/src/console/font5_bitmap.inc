; IX points at the saved IX in the font callback. The dispatcher allocates
; the first five bytes. The ZX bitmap backend adds six more.
defc BC_FONT5_SOURCE      = -2      ; glyph[0], word
defc BC_FONT5_WIDTH       = -3
defc BC_FONT5_HEIGHT      = -4
defc BC_FONT5_BACKGROUND  = -5
defc BC_FONT5_ATTRIBUTE   = -6
defc BC_FONT5_SHIFT       = -7      ; x & 7
defc BC_FONT5_SPAN        = -8      ; shift + width
defc BC_FONT5_GLYPH_MASK  = -9      ; high width bits
defc BC_FONT5_KEEP_FIRST  = -10
defc BC_FONT5_KEEP_SECOND = -11

; The packed 5x8 backends push BC then HL from bc__font5_packed_colors.
; Two colors in each byte name the left and right pixel, respectively.
defc BC_FONT5_PAPER_PAPER = -6
defc BC_FONT5_INK_INK     = -7
defc BC_FONT5_INK_PAPER   = -8
defc BC_FONT5_PAPER_INK   = -9
