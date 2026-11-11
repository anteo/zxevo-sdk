        MODULE zx_set_border_color

SECTION code_clib
PUBLIC _zx_set_border_color
;
; Sets the hardware border to one of the sixteen BaseConf border colors.
;
; Model:
;
; OUT((index&8)?0x80f6:0x80fc,index&7);
;
; Fastcall L = index. Only the low four bits matter. Clobbers AF and BC.
; The chosen full port addresses avoid accidentally decoding 7FFD paging;
; no video lease or initialization is required.
_zx_set_border_color:
        ld a,l
        ld bc,80FCh
        bit 3,a
        jr z,@out
        ld c,0F6h
@out:
        and 7
        out (c),a
        ret
