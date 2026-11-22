; IX-relative midpoint ellipse workspace. The error terms are 32-bit.
DEFVARS 0 {
    ZX_ELLIPSE_X0       ds.w 1
    ZX_ELLIPSE_X1       ds.w 1
    ZX_ELLIPSE_Y0       ds.w 1
    ZX_ELLIPSE_Y1       ds.w 1
    ZX_ELLIPSE_BOTTOM   ds.w 1
    ZX_ELLIPSE_DX       ds.q 1
    ZX_ELLIPSE_DY       ds.q 1
    ZX_ELLIPSE_ERR      ds.q 1
    ZX_ELLIPSE_DX_STEP  ds.q 1
    ZX_ELLIPSE_DY_STEP  ds.q 1
    ZX_ELLIPSE_E2       ds.q 1
    ZX_ELLIPSE_FRAME
}

defc ZX_ELLIPSE_CX = ZX_ELLIPSE_FRAME+6
defc ZX_ELLIPSE_CY = ZX_ELLIPSE_FRAME+8
defc ZX_ELLIPSE_RX = ZX_ELLIPSE_FRAME+10
defc ZX_ELLIPSE_RY = ZX_ELLIPSE_FRAME+12

        MACRO ZX_ELLIPSE_LOAD_DE field
        ld e,(ix+field)
        ld d,(ix+field+1)
        ENDM

        MACRO ZX_ELLIPSE_STORE_HL field
        ld (ix+field),l
        ld (ix+field+1),h
        ENDM

        MACRO ZX_ELLIPSE_STORE_DE field
        ld (ix+field),e
        ld (ix+field+1),d
        ENDM

        MACRO ZX_ELLIPSE_STORE_LONG field
        ZX_ELLIPSE_STORE_HL field
        ZX_ELLIPSE_STORE_DE field+2
        ENDM

        MACRO ZX_ELLIPSE_LOAD_HL field
        ld l,(ix+field)
        ld h,(ix+field+1)
        ENDM
