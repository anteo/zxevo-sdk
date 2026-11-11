        MODULE bc_ers_printer_write_screen

SECTION code_clib
PUBLIC _bc_ers_printer_write_screen
EXTERN _bc_ers_profile

; Sends the BASIC screen to the AY printer.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x43); /* print the BASIC screen */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_printer_write_screen:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_printer_write_screen_unavailable
        push ix
        rst 08h
        defb 43h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_printer_write_screen_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
