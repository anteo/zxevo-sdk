        MODULE bc__graphics_circle_select
EXTERN bc__graphics_circle_select_regs
SECTION code_graphics
PUBLIC bc__graphics_circle_select

; Load center and radius from the IX frame and select a circle writer.
bc__graphics_circle_select:
        ld l,(ix+4)
        ld h,(ix+5)
        ld e,(ix+6)
        ld d,(ix+7)
        ld c,(ix+8)
        ld b,(ix+9)
        jp bc__graphics_circle_select_regs
