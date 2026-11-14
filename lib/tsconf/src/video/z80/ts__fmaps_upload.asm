        MODULE ts__fmaps_upload
SECTION code_clib
PUBLIC ts__fmaps_upload

; Map FMAPS at the start of a CPU window, transfer bytes, then unmap it.
; The typed entry points have already checked window and destination bounds.
;
; destination=(window<<14)+offset;
; saved_iff=IFF2; DI(); OUT(0x15af,0x10|(window<<2));
; if (source) copy_bytes_low_first(destination,source,count);
; else fill_bytes(destination,0,count);
; OUT(0x15af,0); restore_iff(saved_iff); return OK;
;
; A=window0..3, DE=even offset, HL=source or NULL, BC=nonzero even byte count.
; Result L=ZX_OK; AF/BC/DE/HL volatile, IX/IY/SP preserved. Saved IFF flags
; occupy two stack bytes throughout the transfer; temporary BC preserves count
; across the FMAddr port write. Source/code/stack stay outside the 4KiB aperture.
; Caller owns disabled FMAPS, writable disposable backing RAM and excludes DMA
; or NMI writers. Does not remap RAM or touch the cache; paging stays caller-owned.
; Low byte precedes high byte: each odd-address store commits its internal word.
ts__fmaps_upload:
        rrca
        rrca                         ; window<<6, CPU address high byte
        or d
        ld d,a
        ld a,i
        di
        push af                      ; parity flag retains prior IFF2
        ld a,d
        and 0c0h
        rrca
        rrca
        rrca
        rrca                         ; window<<2
        or 10h
        push bc
        ld bc,15afh
        out (c),a
        pop bc
        ld a,h
        or l
        jr z,@clear
        ldir
        jr @finish
@clear:
        xor a
        ld (de),a
        inc de
        dec bc
        ld a,b
        or c
        jr nz,@clear
@finish:
        xor a
        ld bc,15afh
        out (c),a
        ld l,0
        pop af
        ret po
        ei
        ret
