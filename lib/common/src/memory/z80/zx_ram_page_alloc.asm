        MODULE zx_ram_page_alloc
SECTION code_clib
PUBLIC _zx_ram_page_alloc

; Claim the lowest available RAM page and write its number on success.
;
; if (!pool || !page || !pool->page_mask) return ZX_INVALID_ARGUMENT;
; for (i = 0; i < 32; ++i) {
;     available = pool->page_mask[i] & ~pool->allocated[i];
;     if (available) {
;         bit = first_set_bit(available);
;         pool->allocated[i] |= 1 << bit;
;         *page = 8*i + bit;
;         return ZX_OK;
;     }
; }
; return ZX_UNAVAILABLE;
;
; SDCC pool pointer at SP+2, page pointer at SP+4, status in L.
; In the scan HL points to allocated, DE to allowed, C holds the page
; number and B counts bytes. The output pointer is saved on the stack.
; Preserve IX/IY, clobber AF/BC/DE/HL.
_zx_ram_page_alloc:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        inc hl
        ld b,(hl)
        ld a,d
        or e
        jr z,@invalid
        ld a,b
        or c
        jr z,@invalid
        ex de,hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        or e
        jr z,@invalid
        push bc
        ld bc,2000h                  ; 32 bitmap bytes, starting at page 0
@scan:
        ld a,(hl)
        cpl
        ex de,hl
        and (hl)
        ex de,hl
        jr nz,@found
        inc hl
        inc de
        ld a,c
        add a,8
        ld c,a
        djnz @scan
        pop bc
        ld l,3                       ; ZX_UNAVAILABLE
        ret
@found:
        ld b,1
@bit:
        rrca
        jr c,@claim
        sla b
        inc c
        jr @bit
@claim:
        ld a,(hl)
        or b
        ld (hl),a
        ld a,c
        pop hl
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
