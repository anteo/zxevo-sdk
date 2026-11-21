        MODULE ts_video_upload_palette
SECTION code_clib
PUBLIC _ts_video_upload_palette
EXTERN ts__fmaps_upload

; Upload or clear a contiguous range of CRAM colors.
;
; if (!aligned(window) || count>256 || first+count>256) return INVALID_ARGUMENT;
; if (!count) return OK;
; return fmaps_upload(window>>8,2*first,source,2*count);
;
; SDCC caller-clean: window address SP+2, first SP+4, source SP+5, count SP+7.
; Status L; AF/BC/DE/HL volatile, IX/IY preserved. No persistent frame.
; See public header for aperture residency, writable backing RAM and ownership.
_ts_video_upload_palette:
        ld hl,2
        add hl,sp
        ld a,(hl)
        or a
        jr nz,@invalid
        inc hl
        ld b,(hl)
        ld a,b
        and 3fh
        jr nz,@invalid
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
        ld a,b                       ; window address high byte
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
