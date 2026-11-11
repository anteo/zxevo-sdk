        MODULE zx__clear_screen
SECTION code_clib
PUBLIC zx__clear_screen
EXTERN zx__fill_bytes

; Clear the standard 256x192 ZX bitmap and initialize all its attributes.
;
; fill(screen, 0x1800, 0);
; fill(screen + 0x1800, 0x0300, attribute);
;
; HL=base of the writable mapped screen, A=encoded ZX attribute.
; Save the attribute across the bitmap fill. AF/BC/DE/HL volatile,
; IX/IY preserved. Caller keeps the screen mapped throughout.
zx__clear_screen:
        push af
        ld bc,1800h
        xor a
        call zx__fill_bytes
        inc hl                       ; advance from the last bitmap byte
        ld bc,0300h
        pop af
        jp zx__fill_bytes
