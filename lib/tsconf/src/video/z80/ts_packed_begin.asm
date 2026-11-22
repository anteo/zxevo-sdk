        MODULE ts_packed_begin
EXTERN ts_packed_begin_window
EXTERN ts_packed_color
EXTERN ts_packed_mode
SECTION code_clib
PUBLIC ts_packed_begin

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
