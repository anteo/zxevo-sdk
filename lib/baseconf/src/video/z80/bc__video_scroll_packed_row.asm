IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_scroll_packed_row
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_scroll_packed_row
EXTERN bc__video_packed_cursor_next
EXTERN bc__video_packed_cursor_prev
EXTERN bc__video_packed_join

; Shifts one packed scanline in screen order across its interleaved pages and
; planes, filling exposed pixels with paper color.
;
; C model (pair[] is the native interleaved memory view, N=width/2):
;
;   q = pixels / 2;
;   for (i = right ? N-1 : 0; in_row(i); i += right ? -1 : 1) {
;       j = right ? i-q : i+q;
;       if (!(pixels & 1)) pair[i] = read_or_paper(j);
;       else if (right) pair[i] = join(read_or_paper(j-1), read_or_paper(j));
;       else            pair[i] = join(read_or_paper(j), read_or_paper(j+1));
;   }
;
; An odd shift saves one source pair before writing, including pixels==1 where
; source and destination overlap. Even shifts copy native bytes directly.
; HL = page0/plane0 row origin. IX is the shared seven-byte packed frame.
; Preserve IX/IY; clobber AF/BC/DE/HL. No access outside the valid source range:
; reads after SOURCE_LEFT reaches zero return the encoded paper pair instead.
bc__video_scroll_packed_row:
        ld a,(ix+BC_SCROLL_PIXELS)
        srl a
        ld b,a                       ; q, at most four native pairs
        ld a,(ix+BC_SCROLL_PAIR_COUNT)
        sub b
        ld (ix+BC_SCROLL_SOURCE_LEFT),a
        ld a,(ix+BC_SCROLL_RIGHT)
        or a
        jp nz,@right

        ld d,h
        ld e,l                       ; DE = destination pair zero
        ld c,0                       ; HL = source, initially pair zero
        ld a,b
        or a
        jr z,@left_ready
@skip_left:
        call bc__video_packed_cursor_next
        djnz @skip_left
@left_ready:
        xor a
        ld (ix+BC_SCROLL_DEST_PHASE),a
        ld b,(ix+BC_SCROLL_PAIR_COUNT)
        bit 0,(ix+BC_SCROLL_PIXELS)
        jr nz,@left_odd
@left_even:
        call @read_left
        ld (de),a
        call @dest_left
        djnz @left_even
        ret
@left_odd:
        call @read_left
        ld (ix+BC_SCROLL_CARRY),a
@left_pair:
        call @read_left
        push bc
        push de
        ld e,a                       ; second = next source pair
        ld a,(ix+BC_SCROLL_CARRY)     ; first = saved source pair
        ld (ix+BC_SCROLL_CARRY),e
        call bc__video_packed_join
        pop de
        pop bc
        ld (de),a
        call @dest_left
        djnz @left_pair
        ret

@right:
        push bc                      ; retain q while positioning the last pair
        ld a,(ix+BC_SCROLL_PAIR_COUNT)
        srl a
        srl a
        dec a
        ld e,a
        ld d,0
        add hl,de                    ; last group in this row (31 or 39)
        ld a,h
        xor (ix+BC_SCROLL_PAGE_XOR)
        or 20h                       ; last pair belongs to page1, plane1
        ld h,a
        pop bc
        ld d,h
        ld e,l                       ; DE = last destination pair
        ld c,3
        ld a,b
        or a
        jr z,@right_ready
@skip_right:
        call bc__video_packed_cursor_prev
        djnz @skip_right
@right_ready:
        ld a,3
        ld (ix+BC_SCROLL_DEST_PHASE),a
        ld b,(ix+BC_SCROLL_PAIR_COUNT)
        bit 0,(ix+BC_SCROLL_PIXELS)
        jr nz,@right_odd
@right_even:
        call @read_right
        ld (de),a
        call @dest_right
        djnz @right_even
        ret
@right_odd:
        call @read_right
        ld (ix+BC_SCROLL_CARRY),a
@right_pair:
        call @read_right
        push bc
        push de
        ld e,(ix+BC_SCROLL_CARRY)     ; second = saved right-hand source pair
        ld (ix+BC_SCROLL_CARRY),a     ; first = next left-hand source pair
        call bc__video_packed_join
        pop de
        pop bc
        ld (de),a
        call @dest_right
        djnz @right_pair
        ret

; Streaming source readers: preserve DE/B; advance HL/C only for valid pairs.
@read_left:
        ld a,(ix+BC_SCROLL_SOURCE_LEFT)
        or a
        jr z,@paper
        dec (ix+BC_SCROLL_SOURCE_LEFT)
        ld a,(hl)
        push af
        call bc__video_packed_cursor_next
        pop af
        ret
@read_right:
        ld a,(ix+BC_SCROLL_SOURCE_LEFT)
        or a
        jr z,@paper
        dec (ix+BC_SCROLL_SOURCE_LEFT)
        ld a,(hl)
        push af
        call bc__video_packed_cursor_prev
        pop af
        ret
@paper:
        ld a,(ix+BC_SCROLL_BLANK)
        ret

; Advance DE independently while preserving the source cursor and row counter.
@dest_left:
        ex de,hl
        push bc
        ld c,(ix+BC_SCROLL_DEST_PHASE)
        call bc__video_packed_cursor_next
        ld (ix+BC_SCROLL_DEST_PHASE),c
        pop bc
        ex de,hl
        ret
@dest_right:
        ex de,hl
        push bc
        ld c,(ix+BC_SCROLL_DEST_PHASE)
        call bc__video_packed_cursor_prev
        ld (ix+BC_SCROLL_DEST_PHASE),c
        pop bc
        ex de,hl
        ret
ENDIF
