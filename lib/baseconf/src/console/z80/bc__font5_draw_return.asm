        MODULE bc__font5_draw_return
SECTION code_clib
PUBLIC bc__font5_draw_return

; Tail target for all backends; discard their context/outgoing arguments too.
; Shared epilogue: discard all backend locals/outgoing arguments, restore IX,
; and return to the original callback caller. No C result; AF/BC/DE/HL volatile.
bc__font5_draw_return:
IFDEF BASECONF_VIDEO_TEXT_GRAPHICS
        ld sp,ix
        pop ix
ENDIF
        ret
