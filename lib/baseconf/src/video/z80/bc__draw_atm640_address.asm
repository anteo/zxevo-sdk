        MODULE bc__draw_atm640_address
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_640
EXTERN _bc_video_page1_base
EXTERN zx__masks
SECTION code_graphics
PUBLIC bc__draw_atm640_address

; Resolves an ATM640 pixel to its bitmap plane address and the bit that
; selects it.
;
; Model:
;
; address=page1_base+y*40+(x>>4)+((x&8)?0x2000:0); mask=0x80>>(x&7).
;
; HL=x,DE=y -> HL=address,A=mask. Active mapped bitmap, x<640,y<200 required.
; AF/BC/DE/HL volatile; IX/IY preserved. High X bits participate in x/16;
; the logical-byte parity x bit 3 alone selects the plane.
bc__draw_atm640_address:
        ld a,l
        and 7
        push af
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        add hl,hl
        add hl,hl
        add hl,hl                     ; 8*y
        push hl
        add hl,hl
        add hl,hl                     ; 32*y
        pop bc
        add hl,bc                     ; 40*y
        pop bc                        ; x
        bit 3,c
        jr z,bc_circle_atm640_bank_ready
        ld de,02000h
        add hl,de
bc_circle_atm640_bank_ready:
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c                         ; x/16
        ld e,c
        ld d,0
        add hl,de
        ld bc,(_bc_video_page1_base)
        add hl,bc
        push hl
        pop de
        pop af                        ; mask index
        ld c,a
        ld b,0
        ld hl,zx__masks
        add hl,bc
        ld a,(hl)
        ex de,hl
        ret
ENDIF
