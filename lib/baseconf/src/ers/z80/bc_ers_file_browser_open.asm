        MODULE bc_ers_file_browser_open

SECTION code_clib
PUBLIC _bc_ers_file_browser_open
EXTERN _bc_ers_profile

; Opens the interactive ERS file browser and waits for it to return.
;
; Model:
;
; if (profile == NONE) return UNAVAILABLE;
; ERS(0x4e, 0x00); /* interactive, blocks until the browser returns */
; return OK; /* firmware flags are not converted to status */
;
; No arguments; caller-clean stack.
; Requires the selected ERS ROM/BASIC context and service-accessible buffers.
; Caller-clean C entry; HL = zx_status_t. AF/BC/DE and flags are volatile;
; IX is restored where saved below, other preservation follows the ERS ABI.
_bc_ers_file_browser_open:
        ld a,(_bc_ers_profile)
        or a
        jp z,bc_ers_file_browser_open_unavailable
        push ix
        rst 08h
        defb 4eh,00h
        pop ix
        ld hl,0                     ; ZX_OK
        ret

bc_ers_file_browser_open_unavailable:
        ld hl,3                     ; ZX_UNAVAILABLE
        ret
