defc ZX_ELLIPSE_X0 = 0
defc ZX_ELLIPSE_X1 = 2
defc ZX_ELLIPSE_Y0 = 4
defc ZX_ELLIPSE_Y1 = 6
defc ZX_ELLIPSE_BOTTOM = 8
defc ZX_ELLIPSE_DX = 10
defc ZX_ELLIPSE_DY = 14
defc ZX_ELLIPSE_ERR = 18
defc ZX_ELLIPSE_DX_STEP = 22
defc ZX_ELLIPSE_DY_STEP = 26
defc ZX_ELLIPSE_E2 = 30
defc ZX_ELLIPSE_FRAME = 34

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
