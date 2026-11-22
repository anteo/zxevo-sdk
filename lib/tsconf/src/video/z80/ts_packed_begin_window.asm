        MODULE ts_packed_begin_window
EXTERN _ts__memory_window_owner
EXTERN ts__packed_base_page
EXTERN ts__packed_depth
EXTERN ts__packed_mapped_page
EXTERN ts__packed_saved_page
SECTION code_clib
PUBLIC ts_packed_begin_window

; Claim W3 for the given canvas. Nested operations on the same canvas reuse
; the saved mapping and release it only at the outermost end.
;
; if (owner && (owner != &depth || base != page || depth == 255)) return BUSY;
; if (!owner) { owner = &depth; base = page; saved = mapped = IN(13AFh); }
; ++depth; return OK;
;
; D=base page. Return carry on failure, clear on success. W3 must be
; disposable and callers serialize access. Preserve DE/HL/IX/IY.
ts_packed_begin_window:
        push hl
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        jr z,@claim
        ld bc,ts__packed_depth
        or a
        sbc hl,bc
        jr nz,@busy
        ld a,(ts__packed_base_page)
        cp d
        jr nz,@busy
        ld a,(ts__packed_depth)
        cp 255
        jr z,@busy
        jr @nested
@claim:
        ld hl,ts__packed_depth
        ld (_ts__memory_window_owner),hl
        ld a,d
        ld (ts__packed_base_page),a
        ld bc,13afh
        in a,(c)
        ld (ts__packed_saved_page),a
        ld (ts__packed_mapped_page),a
        xor a
@nested:
        inc a
        ld (ts__packed_depth),a
        pop hl
        or a
        ret
@busy:
        pop hl
        scf
        ret
