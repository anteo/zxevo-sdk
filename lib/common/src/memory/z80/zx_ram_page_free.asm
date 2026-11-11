        MODULE zx_ram_page_free
SECTION code_clib
PUBLIC _zx_ram_page_free

; Release an allowed page that is currently claimed in this pool.
;
; if (!pool || !pool->page_mask) return ZX_INVALID_ARGUMENT;
; i = page >> 3;
; bit = 1 << (page & 7);
; if (!(pool->page_mask[i] & pool->allocated[i] & bit)) return ZX_INVALID_ARGUMENT;
; pool->allocated[i] &= ~bit;
; return ZX_OK;
;
; SDCC pool pointer at SP+2, page byte at SP+4, status in L. Save the bit
; index on the stack while computing both byte addresses. Preserve IX/IY,
; clobber AF/BC/DE/HL.
_zx_ram_page_free:
        ld hl,2
        add hl,sp
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld c,(hl)
        ld a,d
        or e
        jr z,@invalid
        ex de,hl
        ld e,(hl)
        inc hl
        ld d,(hl)
        inc hl
        ld a,d
        or e
        jr z,@invalid

        ld a,c
        and 7
        push af
        ld a,c
        rrca
        rrca
        rrca
        and 1fh                      ; page >> 3, in 0..31
        ld c,a
        ld b,0
        add hl,bc
        ex de,hl
        add hl,bc
        pop af
        inc a
        ld b,a
        xor a
        scf                          ; shift a single set bit in from carry
@mask:
        rla
        djnz @mask
        and (hl)                     ; allowed
        jr z,@invalid
        ex de,hl
        ld b,a
        and (hl)                     ; allocated
        jr z,@invalid
        ld a,b
        cpl
        and (hl)
        ld (hl),a
        ld l,0                       ; ZX_OK
        ret
@invalid:
        ld l,1                       ; ZX_INVALID_ARGUMENT
        ret
