        MODULE bc__video_fill_two_planes

SECTION code_clib
PUBLIC bc__video_fill_two_planes
EXTERN zx__fill_bytes

; Fill the same byte span in both planes of a mapped ATM or Pentagon page.
;
; fill(base + offset, length, value);
; fill(base + 0x2000 + offset, length, value);
;
; HL = first plane's CPU address, BC = length, A = value. The aligned page
; is writable and the span fits in one 8 KiB plane. Bit 5 of H selects the
; second plane. AF/BC/DE/HL volatile, IX/IY preserved. No mapping changes.
bc__video_fill_two_planes:
        push hl
        push af
        push bc
        call zx__fill_bytes
        pop bc
        pop af
        pop hl
        set 5,h
        jp zx__fill_bytes
