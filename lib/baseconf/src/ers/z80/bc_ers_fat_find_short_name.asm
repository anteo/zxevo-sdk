        MODULE bc_ers_fat_find_short_name

SECTION code_clib
PUBLIC _bc_ers_fat_find_short_name
EXTERN _bc_ers_profile

; Searches the current directory for an 8.3 name and reports the entry index
; and whether it was found.
;
; Model:
;
; if (!name || !result) return INVALID_ARGUMENT; if (profile == NONE) return UNAVAILABLE;
; ERS(0x51, 0x05, HL=name); result->directory_entry = BC; result->not_found = CF;
; return OK;
;
; IX frame: name +4, result +6. Name supplies 16 readable bytes; result is
; {entry:16,not_found:8}. Stack AF temporarily to preserve CF while writing entry.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_fat_find_short_name:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld a,h
        or l
        jp z,bc_ers_fat_find_short_name_invalid
        ld e,(ix+6)
        ld d,(ix+7)
        ld a,d
        or e
        jp z,bc_ers_fat_find_short_name_invalid
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_fat_find_short_name_unavailable
        rst 08h
        defb 51h,05h
        push af
        ld e,(ix+6)
        ld d,(ix+7)
        ld a,c
        ld (de),a
        inc de
        ld a,b
        ld (de),a
        inc de
        pop af
        ld a,0
        adc a,0
        ld (de),a
        pop ix
        ld hl,0
        ret
bc_ers_fat_find_short_name_invalid:
        pop ix
        ld hl,1
        ret
bc_ers_fat_find_short_name_unavailable:
        pop ix
        ld hl,3
        ret
