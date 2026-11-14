        MODULE ts_video_upload_palette
SECTION code_clib
PUBLIC _ts_video_upload_palette
EXTERN ts__fmaps_upload

; Upload or clear a contiguous range of CRAM colors.
;
; if (window>3 || count>256 || first+count>256) return INVALID_ARGUMENT;
; if (!count) return OK;
; return fmaps_upload(window,2*first,source,2*count);
;
; SDCC caller-clean: window SP+2, first SP+3, source SP+4, count SP+6.
; Status L; AF/BC/DE/HL volatile, IX/IY preserved. No persistent frame.
; See public header for aperture residency, writable backing RAM and ownership.
_ts_video_upload_palette:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 4
        jr nc,@invalid
        ld b,a                       ; window
        inc hl
        ld c,(hl)                    ; first color
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)                    ; source
        inc hl
        ld a,(hl)
        inc hl
        ld h,(hl)
        ld l,a                       ; count
        ld a,h
        cp 2
        jr nc,@invalid
        or a
        jr z,@count_valid
        ld a,l
        or a
        jr nz,@invalid               ; count>256
@count_valid:
        ld a,l
        add a,c
        ld a,h
        adc a,0
        cp 2
        jr nc,@invalid
        or a
        jr z,@range_valid
        ld a,l
        add a,c
        or a
        jr nz,@invalid               ; only sum==256 allowed with high byte1
@range_valid:
        ld a,h
        or l
        jr z,@ok
        ld a,b                       ; window
        push bc                      ; first color
        add hl,hl
        ld b,h
        ld c,l                       ; byte count
        ex de,hl                     ; source
        pop de
        ld d,0
        sla e
        rl d                         ; CRAM byte offset
        jp ts__fmaps_upload
@invalid:
        ld l,1
        ret
@ok:
        ld l,0
        ret
