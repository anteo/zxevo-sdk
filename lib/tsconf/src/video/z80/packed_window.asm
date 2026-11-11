        MODULE ts_packed_window
SECTION code_clib
PUBLIC ts_packed_begin
PUBLIC ts_packed_begin_window
PUBLIC ts_packed_end
PUBLIC ts_packed_map_relative
PUBLIC ts__packed_check_window
EXTERN _ts__memory_window_owner

; Begin a packed-surface operation. A=mode, D=base page, E=pixel color.
; Carry indicates a conflicting lease or exhausted nesting depth.
; Preserve DE/HL/IX/IY, clobber AF/BC.
ts_packed_begin:
        push af
        call ts_packed_begin_window
        jr c,@failed
        pop af
        ld (ts_packed_mode),a
        ld a,e
        ld (ts_packed_color),a
        or a
        ret
@failed:
        pop af
        scf
        ret

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
        ld bc,depth
        or a
        sbc hl,bc
        jr nz,@busy
        ld a,(base_page)
        cp d
        jr nz,@busy
        ld a,(depth)
        cp 255
        jr z,@busy
        jr @nested
@claim:
        ld hl,depth
        ld (_ts__memory_window_owner),hl
        ld a,d
        ld (base_page),a
        ld bc,13afh
        in a,(c)
        ld (saved_page),a
        ld (mapped_page),a
        xor a
@nested:
        inc a
        ld (depth),a
        pop hl
        or a
        ret
@busy:
        pop hl
        scf
        ret

; Check whether a glyph can acquire W3 without changing the mapping.
; D=base page, carry means busy. Clobber AF/BC/HL.
ts__packed_check_window:
        ld hl,(_ts__memory_window_owner)
        ld a,h
        or l
        ret z
        ld bc,depth
        sbc hl,bc
        jr nz,@conflict
        ld a,(base_page)
        cp d
        jr nz,@conflict
        ld a,(depth)
        cp 255
        ccf
        ret
@conflict:
        scf
        ret

; End one successful begin, restoring Page3 at the outermost level.
; Preserve DE/HL/IX/IY.
ts_packed_end:
        ld a,(depth)
        dec a
        ld (depth),a
        ret nz
        ld a,(saved_page)
        call map_page
        ld bc,0
        ld (_ts__memory_window_owner),bc
        ret

; Resolve a packed pixel to its containing CPU byte and map the page in W3.
;
; offset = 16c ? 256*y + (x>>1) : 512*y + x;
; map_relative(offset >> 14); return 0xc000 + (offset & 0x3fff);
;
; HL=x, DE=y, both below 512. Return HL=CPU byte. Caller owns W3 and
; has begun an operation. AF/BC volatile, DE/IX/IY preserved.
IFDEF TSCONF_VIDEO_16C
PUBLIC ts_packed_address16
ts_packed_address16:
        srl h
        rr l
        ld a,e
        and 3fh                      ; 64 scanlines per page
        or 0c0h
        ld h,a
        ld a,e
        rlca
        rlca
        and 3
        ld b,a
        ld a,d
        add a,a
        add a,a
        or b
        jr ts_packed_map_relative
ENDIF

IFDEF TSCONF_VIDEO_256C
PUBLIC ts_packed_address256
ts_packed_address256:
        ld a,e
        and 31                       ; 32 scanlines per page
        add a,a
        or h                         ; X bit 8 selects the second 256 bytes
        or 0c0h
        ld h,a
        ld a,e
        rlca
        rlca
        rlca
        and 7
        ld b,a
        ld a,d
        add a,a
        add a,a
        add a,a
        or b
ENDIF

; A=relative page. Switch only when needed. Preserve HL/DE/IX/IY.
ts_packed_map_relative:
        ld c,a
        ld a,(base_page)
        add a,c
map_page:
        ld c,a
        ld a,(mapped_page)
        cp c
        ret z
        ld a,c
        ld (mapped_page),a
        ld bc,13afh
        out (c),a
        ret

SECTION bss_clib
PUBLIC ts_packed_mode
PUBLIC ts_packed_color
ts_packed_mode:  defb 0
ts_packed_color: defb 0
base_page:       defb 0
saved_page:      defb 0
mapped_page:     defb 0
depth:           defb 0
