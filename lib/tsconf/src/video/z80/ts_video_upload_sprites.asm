        MODULE ts_video_upload_sprites
SECTION code_clib
PUBLIC _ts_video_upload_sprites
EXTERN ts__fmaps_upload

; Upload or clear a contiguous range of hardware sprite descriptors.
;
; if (window>3 || first+count>85) return INVALID_ARGUMENT;
; if (!count) return OK;
; return fmaps_upload(window,0x200+6*first,source,6*count);
;
; SDCC caller-clean: window SP+2, first SP+3, source SP+4, count SP+6.
; Status L; AF/BC/DE/HL volatile, IX/IY preserved. No local frame.
; See public header for aperture residency, writable backing RAM and ownership.
_ts_video_upload_sprites:
        ld hl,2
        add hl,sp
        ld a,(hl)
        cp 4
        jr nc,@invalid
        ld b,a                       ; window
        inc hl
        ld a,(hl)
        cp 86
        jr nc,@invalid
        ld c,a                       ; first descriptor
        inc hl
        ld e,(hl)
        inc hl
        ld d,(hl)                    ; source
        inc hl
        ld a,(hl)
        cp 86
        jr nc,@invalid
        add a,c
        cp 86
        jr nc,@invalid
        ld a,(hl)
        or a
        jr z,@ok
        push bc                      ; window/first
        push de                      ; source
        ld l,a
        ld h,0
        ld d,h
        ld e,l
        add hl,hl
        add hl,de
        add hl,hl                    ; 6*count, at most510 bytes
        ld b,h
        ld c,l
        pop hl                       ; source
        pop de                       ; D=window, E=first
        push hl
        ld a,d
        ld d,0
        ld h,d
        ld l,e
        add hl,hl
        add hl,de
        add hl,hl                    ; 6*first
        inc h
        inc h                        ; SFILE offset0x200
        ex de,hl
        pop hl
        jp ts__fmaps_upload
@invalid:
        ld l,1
        ret
@ok:
        ld l,0
        ret
