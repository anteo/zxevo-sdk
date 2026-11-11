        MODULE bc_upload_font_preserving

SECTION code_clib
PUBLIC _bc_upload_font_preserving
EXTERN bc__font_upload_validate
EXTERN bc__font_upload_range
EXTERN bc__font_upload_overlap
EXTERN bc__font_upload_copy

; SDCC caller-clean ABI after saving IX:
; font +4, destination +6, backup +8. Return zx_status_t in HL.
;
; Uploads a font and restores the original destination RAM from a separate
; backup buffer.
;
; Model:
;
; if (invalid_ranges_or_overlap(font,destination,backup)) return INVALID_ARGUMENT;
; save_IFF(); DI(); if (BF&4) { restore_IFF(); return BUSY; }
; copy_2048(destination,backup); upload_2048(font,destination);
; copy_2048(backup,destination); restore_IFF(); return OK;
;
; Caller keeps mappings stable, excludes NMI, supplies readable font and
; writable buffers without physical aliases/code/stack/live-data overlap.
; AF/BC/DE/HL volatile; IX/IY preserved. The validation font push and saved
; IFF AF are separate temporary stack values, not an allocated request frame.
; INT stays disabled through backup, font upload and RAM restoration.
_bc_upload_font_preserving:
        push ix
        ld ix,0
        add ix,sp
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        call bc__font_upload_validate
        jr c,@invalid
        push hl                      ; font while checking backup
        ld l,(ix+8)
        ld h,(ix+9)
        call bc__font_upload_range
        jr c,@invalid_pop_font
        call bc__font_upload_overlap  ; backup versus destination
        pop de                       ; font; POP preserves carry
        jr c,@invalid
        call bc__font_upload_overlap  ; backup versus font
        jr nc,@begin
@invalid:
        ld hl,1                      ; ZX_INVALID_ARGUMENT
        pop ix
        ret
@invalid_pop_font:
        pop de
        jr @invalid

@begin:
        ld a,i
        di
        push af                      ; INT stays masked through all three copies
        ld bc,00BFh
        in a,(c)
        bit 2,a
        jr nz,@busy

        ld l,(ix+6)                  ; destination -> backup, BF.2 still clear
        ld h,(ix+7)
        ld e,(ix+8)
        ld d,(ix+9)
        ld bc,0800h
        ldir                         ; preserves A = original BF

        ld l,(ix+4)                  ; font -> destination and font RAM
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        call bc__font_upload_copy

        ld l,(ix+8)                  ; backup -> destination, BF.2 clear again
        ld h,(ix+9)
        ld e,(ix+6)
        ld d,(ix+7)
        ld bc,0800h
        ldir
        ld hl,0                      ; ZX_OK
@restore_iff:
        pop af
        pop ix
        jp po,@return
        ei
@return:
        ret
@busy:
        ld hl,2                      ; ZX_BUSY
        jr @restore_iff
