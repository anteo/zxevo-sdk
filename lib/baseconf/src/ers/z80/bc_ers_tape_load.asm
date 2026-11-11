        MODULE bc_ers_tape_load

SECTION code_clib
PUBLIC _bc_ers_tape_load
EXTERN _bc_ers_profile

; Runs one BASIC tape loader step and reports the resulting destination,
; remaining length and firmware flags.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE; if (!result) return INVALID_ARGUMENT;
; ERS(0x45, IX=destination, DE=length);
; *result = { .receiver=IX, .remaining=DE, .flags=F }; return OK;
;
; IY frame after saving IX/IY: destination +6, length +8, result +10.
; After stacking returned IX/DE/AF, recaptured IY has F +0, A +1, remaining +2,
; receiver +4, saved IY +6, saved IX +8, result +16. Caller IX/IY are restored.
; Requires live BASIC tape state; destination/length validity is the caller
; contract. The result stores raw F, including CF, rather than returned A.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_tape_load:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_tape_load_unavailable
        push ix
        push iy
        ld iy,0
        add iy,sp
        ld l,(iy+10)              ; result pointer
        ld h,(iy+11)
        ld a,h
        or l
        jp z,bc_ers_tape_load_invalid
        ld e,(iy+8)               ; requested length
        ld d,(iy+9)
        ld l,(iy+6)               ; load destination
        ld h,(iy+7)
        push hl
        pop ix
        rst 08h
        defb 45h
        push ix                    ; returned receiver
        push de                    ; remaining length
        push af                    ; returned flags
        ld iy,0
        add iy,sp
        ld l,(iy+16)              ; result pointer below saved registers
        ld h,(iy+17)
        push hl
        pop ix
        pop af
        pop de
        pop bc
        ld (ix+0),c
        ld (ix+1),b
        ld (ix+2),e
        ld (ix+3),d
        push af
        pop bc
        ld (ix+4),c
        pop iy
        pop ix
        ld hl,0
        ret
bc_ers_tape_load_invalid:
        pop iy
        pop ix
        ld hl,1
        ret
bc_ers_tape_load_unavailable:
        ld hl,3
        ret
