        MODULE zx__line_run
EXTERN zx__line_init
EXTERN zx__line_start
SECTION code_graphics
PUBLIC zx__line_run

; Draw from the original endpoints using the writer in HL. The caller
; guarantees safe coordinates for that writer.
; SDCC x0 +2, y0 +4, x1 +6, y1 +8. Preserve IX/IY, clobber AF/BC/DE/HL.
zx__line_run:
        push ix
        ld ix,0
        add ix,sp
        push hl                      ; retain the writer across initialization
        call zx__line_init
        pop hl
        jp zx__line_start
