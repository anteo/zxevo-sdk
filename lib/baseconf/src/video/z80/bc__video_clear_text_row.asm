        MODULE bc__video_clear_text_row
INCLUDE "video/text_rows.inc"
SECTION code_clib
PUBLIC _bc__video_clear_text_row
EXTERN _bc_video_operation_depth
EXTERN bc__video_text_character_planes
EXTERN bc__video_text_attribute_planes
EXTERN zx__fill_bytes

; Clear the specified cells of one hardware text row. Model:
;
; if (!depth || !columns) return;
; if (select_character_planes()) fill_row_pair(row, columns, ' ');
; if (select_attribute_planes()) fill_row_pair(row, columns, attribute);
;
; SDCC caller-clean, packed mode:8, surface:24, row:8, columns:8, attribute:8.
; IX points to the original arguments as described in text_rows.inc. The
; caller owns the lease and supplies valid row/column geometry. Preserve
; IX/IY, clobber AF/BC/DE/HL. Each page pair can be filled independently.
_bc__video_clear_text_row:
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        push ix
        ld ix,4
        add ix,sp
        ld a,(ix+BC_TEXT_ROWS_COLUMNS)
        or a
        jr z,@done

        call bc__video_text_character_planes
        jr nz,@attributes
        ld a,' '
        call @fill_pair
@attributes:
        call bc__video_text_attribute_planes
        jr nz,@done
        ld a,(ix+BC_TEXT_ROWS_ATTRIBUTE)
        call @fill_pair
@done:
        pop ix
        ret

; Fills the even and odd column planes for one text row, touching only the
; requested number of cells.
;
; Model:
;
; fill(even + row * 64, (columns + 1) / 2, value);
; fill(odd  + row * 64, columns / 2, value);
;
; HL/DE = plane origins, A = value. Save the value and odd destination
; across the first fill. The fill helper treats a zero odd length as a no-op.
@fill_pair:
        ld b,(ix+BC_TEXT_ROWS_ROW)
        ld c,0
        srl b
        rr c
        srl b
        rr c                         ; BC = row * 64
        add hl,bc
        ex de,hl
        add hl,bc
        ex de,hl

        push af
        push de
        ld c,(ix+BC_TEXT_ROWS_COLUMNS)
        srl c
        jr nc,@even_count
        inc c
@even_count:
        ld b,0
        call zx__fill_bytes
        pop hl
        pop af
        ld c,(ix+BC_TEXT_ROWS_COLUMNS)
        srl c
        ld b,0
        jp zx__fill_bytes
