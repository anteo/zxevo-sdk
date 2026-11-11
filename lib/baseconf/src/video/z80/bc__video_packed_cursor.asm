IFDEF BASECONF_VIDEO_PRIMITIVE_PACKED
        MODULE bc__video_packed_cursor
INCLUDE "video/scroll_horizontal.inc"
SECTION code_clib
PUBLIC bc__video_packed_cursor_next
PUBLIC bc__video_packed_cursor_prev

; Native packed pairs in logical order:
;   pair[4*g+0] = page0[g];          pair[4*g+1] = page1[g];
;   pair[4*g+2] = page0[0x2000+g];   pair[4*g+3] = page1[0x2000+g].
;
; Steps to the next or previous packed pair in screen order and updates the
; page and plane cursor.
;
; C model:
;
; cursor = address_of_pair(index + step); // step is +1 or -1; no memory read
;
; HL = pair address, C & 3 = pair phase. Preserve DE/B/IX/IY; clobber AF.
; CPU bases are 16 KiB aligned. XORing only their high-byte difference switches
; pages while retaining the row/column offset; bit 5 of H selects the plane.
bc__video_packed_cursor_next:
        ld a,h
        xor (ix+BC_SCROLL_PAGE_XOR)
        ld h,a
        inc c
        bit 0,c
        ret nz
        ld a,h
        xor 20h
        ld h,a
        ld a,c
        and 3
        ret nz
        inc hl
        ret

bc__video_packed_cursor_prev:
        ld a,c
        and 3
        jr nz,@same_group
        dec hl
@same_group:
        bit 0,c
        jr nz,@page
        ld a,h
        xor 20h
        ld h,a
@page:
        ld a,h
        xor (ix+BC_SCROLL_PAGE_XOR)
        ld h,a
        dec c
        ret
ENDIF
