        MODULE bc__draw_atm320_address
IFDEF BASECONF_VIDEO_PRIMITIVE_ATM_320
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
SECTION code_graphics
PUBLIC bc__draw_atm320_address

; Resolves an ATM320 pixel to its packed byte address and left or right
; position.
;
; Model:
;
; address=page_base[(x>>1)&1]+y*40+(x>>3)+((x&4)?0x2000:0);
; side=x&1; return address,side;
;
; Native HL=x,DE=y -> HL=address,B=side. Requires x<320,y<200 and mapped pages;
; AF/BC/DE/HL volatile, IX/IY preserved. Saved side/page AF values are private
; stack temporaries, not fields in a shared C request.
bc__draw_atm320_address:
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        add hl,hl
        add hl,hl
        add hl,hl                     ; 8*y
        push hl
        add hl,hl
        add hl,hl                     ; 32*y
        pop de
        add hl,de                     ; 40*y
        pop bc                        ; x
        ld a,c
        and 1
        push af                       ; packed side
        ld a,c
        and 2
        push af                       ; selected physical page
        bit 2,c
        jr z,bc_circle_atm320_offset_ready
        ld de,02000h
        add hl,de
bc_circle_atm320_offset_ready:
        srl b
        rr c
        srl b
        rr c
        srl b
        rr c                         ; x/8
        ld e,c
        ld d,0
        add hl,de
        pop af
        or a
        jr nz,bc_circle_atm320_page1
        ld de,(_bc_video_page0_base)
        add hl,de
        pop af
        ld b,a
        ret
bc_circle_atm320_page1:
        ld de,(_bc_video_page1_base)
        add hl,de
        pop af
        ld b,a
        ret
ENDIF
