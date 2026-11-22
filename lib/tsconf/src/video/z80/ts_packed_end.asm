        MODULE ts_packed_end
EXTERN _ts__memory_window_owner
EXTERN ts__packed_depth
EXTERN ts__packed_map_page
EXTERN ts__packed_saved_page
SECTION code_clib
PUBLIC ts_packed_end

; End one successful begin, restoring Page3 at the outermost level.
; Preserve DE/HL/IX/IY.
ts_packed_end:
        ld a,(ts__packed_depth)
        dec a
        ld (ts__packed_depth),a
        ret nz
        ld a,(ts__packed_saved_page)
        call ts__packed_map_page
        ld bc,0
        ld (_ts__memory_window_owner),bc
        ret
