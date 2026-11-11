        MODULE bc__video_scroll_text_rows
INCLUDE "video/text_rows.inc"
SECTION code_clib
PUBLIC _bc__video_scroll_text_rows
EXTERN _bc_video_operation_depth
EXTERN bc__video_text_character_planes
EXTERN bc__video_text_attribute_planes
EXTERN bc__video_strided_copy_rows

; Scroll hardware text up one row. Model:
;
; if (!depth || !columns || !row_count) return;
; if (!select_character_planes()) return;
; scroll_plane_pair(row_count, columns);
; if (!select_attribute_planes()) return;
; scroll_plane_pair(row_count, columns);
;
; SDCC caller-clean, packed mode:8, surface:24, row_count:8, columns:8.
; IX addresses the original arguments as in text_rows.inc. The caller owns
; the lease and supplies a valid source row after the last destination row.
; Preserve IX/IY, clobber AF/BC/DE/HL. The caller clears the exposed row.
_bc__video_scroll_text_rows:
        ld a,(_bc_video_operation_depth)
        or a
        ret z
        push ix
        ld ix,4
        add ix,sp
        ld a,(ix+BC_TEXT_ROWS_COLUMNS)
        or a
        jr z,@done
        ld a,(ix+BC_TEXT_ROWS_ROW)
        or a
        jr z,@done

        call bc__video_text_character_planes
        jr nz,@done
        call @scroll_pair
        call bc__video_text_attribute_planes
        jr nz,@done
        call @scroll_pair
@done:
        pop ix
        ret

; Moves the selected even and odd text columns up one row within their
; separate planes.
;
; Model:
;
; copy_rows(even, even + 64, (columns + 1) / 2, 64, row_count);
; copy_rows(odd,  odd  + 64, columns / 2,       64, row_count);
;
; HL/DE = plane origins. Only the odd destination is saved between calls.
@scroll_pair:
        push de
        ld c,(ix+BC_TEXT_ROWS_COLUMNS)
        srl c
        jr nc,@even_count
        inc c
@even_count:
        call @scroll_plane
        pop hl
        ld c,(ix+BC_TEXT_ROWS_COLUMNS)
        srl c
@scroll_plane:
        ld d,h
        ld e,l                       ; destination
        ld a,l
        add a,64
        ld l,a
        jr nc,@source_ready
        inc h                        ; source = destination + 64
@source_ready:
        ld a,64
        sub c
        ld b,a                       ; skip after each copy = stride - length
        ld a,(ix+BC_TEXT_ROWS_ROW)
        jp bc__video_strided_copy_rows
