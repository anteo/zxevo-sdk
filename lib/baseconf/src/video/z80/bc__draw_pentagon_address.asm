        MODULE bc__draw_pentagon_address
IFDEF BASECONF_VIDEO_PRIMITIVE_PENTAGON_256
EXTERN _bc_video_page0_base
EXTERN _bc_video_page1_base
SECTION code_graphics
PUBLIC bc__draw_pentagon_address

; Return HL=byte address and B=x&1 for the packed byte's left/right pixel.
; Resolves a Pentagon pixel to its packed byte address and left or right
; position.
;
; Model:
;
; address=page_base[(x>>1)&1]+zx__offset(y,x>>3)+((x&4)?0x2000:0);
; side=x&1; return address,side;
;
; Native HL=x,DE=y -> HL=address,B=side. Requires x<256,y<192 and mapped pages;
; AF/BC/DE/HL volatile, IX/IY preserved. X bits select pair/page/plane separately.
bc__draw_pentagon_address:
        push hl                       ; x
        ld h,d
        ld l,e                       ; y
        ld a,e
        and 038h
        rlca
        rlca
        ld l,a
        ld a,e
        and 0c0h
        rrca
        rrca
        rrca
        ld h,a
        ld a,e
        and 7
        or h
        ld h,a
        pop bc                        ; x
        ld a,c
        and 1
        ld b,a                        ; packed side
        ld a,c
        srl a
        srl a
        srl a
        ld e,a
        ld d,0
        add hl,de                     ; x/8 byte within the ZX bitmap row
        bit 2,c
        jr z,bc_circle_pentagon_offset_ready
        ld de,02000h
        add hl,de
bc_circle_pentagon_offset_ready:
        bit 1,c
        jr nz,bc_circle_pentagon_page1
        ld de,(_bc_video_page0_base)
        add hl,de
        ret
bc_circle_pentagon_page1:
        ld de,(_bc_video_page1_base)
        add hl,de
        ret
ENDIF
