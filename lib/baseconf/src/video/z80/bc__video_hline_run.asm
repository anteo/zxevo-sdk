        MODULE bc__video_hline_run
SECTION code_clib
PUBLIC bc__video_hline_run
EXTERN bc__video_line_partial_paint

; HL = first CPU byte, DE = last (inclusive); return without writing if empty.
; IX locals: first bit mask -1, last bit mask -2, full AND -3, full XOR -4.
; One native-byte loop serves ZX/ATM640 bitmaps and Pentagon/ATM320 pairs.
; No static scratch, callback tables, pixel decoding or per-byte op dispatch.
;
; Paints an inclusive span of video bytes, masking the edges to keep
; neighboring pixels intact.
;
; Model:
;
; if (first>last) return;
; if (first==last) paint(first,first_mask&last_mask);
; else { paint(first,first_mask); paint_full_bytes(first+1,last-1); paint(last,last_mask); }
;
; Active mapped span and persistent mask/paint locals above are required.
; No clipping or mapping here. AF/BC/HL volatile, DE retained by the edge helper;
; IX/IY preserved. Zero masks skip memory access; full bytes share one native loop.
bc__video_hline_run:
        ld b,(ix-3)
        ld c,(ix-4)
        ld a,h
        cp d
        jr c,@multi
        ret nz
        ld a,l
        cp e
        jr z,@single
        ret nc
@multi:
        ld a,(ix-1)
        call @edge
        inc hl
@interior:
        ld a,h
        cp d
        jr nz,@full
        ld a,l
        cp e
        jr z,@last
@full:
        ld a,(hl)
        and b
        xor c
        ld (hl),a
        inc hl
        jr @interior
@last:
        ld a,(ix-2)
        jp @edge
@single:
        ld a,(ix-1)
        and (ix-2)
@edge:
        or a
        ret z
        push de
        call bc__video_line_partial_paint
        ld a,(hl)
        and d
        xor e
        ld (hl),a
        pop de
        ret
