        MODULE bc_upload_font_to

SECTION code_clib
PUBLIC _bc_upload_font_to
EXTERN bc__font_upload_validate
EXTERN bc__font_upload_copy

; SDCC caller-clean ABI: font and destination are two 16-bit pointers.
; Return zx_status_t in HL. IX/IY are untouched.
;
; Uploads a 2 KiB font through a disposable RAM area, which is overwritten by
; the copy.
;
; Model:
;
; if (invalid_ranges_or_overlap(font,destination)) return INVALID_ARGUMENT;
; save_IFF(); DI(); if (BF&4) { restore_IFF(); return BUSY; }
; upload_2048(font,destination); restore_IFF(); return OK;
;
; Caller supplies disposable writable destination RAM, stable mappings and
; no physical alias/code/stack/live-data overlap, and excludes NMI.
; AF/BC/DE/HL volatile; IX/IY preserved. Only original IFF AF and the shared
; copy helper BF AF are saved; no C request object or paging snapshot is needed.
_bc_upload_font_to:
        pop bc
        pop hl                       ; font
        pop de                       ; destination
        push de
        push hl
        push bc
        call bc__font_upload_validate
        jr nc,@begin
        ld hl,1                      ; ZX_INVALID_ARGUMENT
        ret

@begin:
        ld a,i
        di
        push af                      ; original IFF2 in P/V
        ld bc,00BFh
        in a,(c)
        bit 2,a
        jr nz,@busy
        call bc__font_upload_copy
        ld hl,0                      ; ZX_OK
@restore_iff:
        pop af
        jp po,@return
        ei
@return:
        ret
@busy:
        ld hl,2                      ; ZX_BUSY
        jr @restore_iff
