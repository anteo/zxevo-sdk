; Mark descriptors whose renderer needs a built-in BaseConf text backend.
; Omit the marker when the archive contains every bitmap text backend.
defc BC_FONT_TEXT_BACKEND_BIT = 7
IFDEF BASECONF_VIDEO_TEXT_PARTIAL_GRAPHICS
defc BC_FONT_TEXT_BACKEND = 80h
; Cache the active font's marker together with the current mode's availability.
defc BC_FONT_BACKEND_MISSING_BIT = 0
defc BC_FONT_BACKEND_MISSING = 1
defc BC_FONT_UNSUPPORTED = BC_FONT_TEXT_BACKEND + BC_FONT_BACKEND_MISSING
ELSE
defc BC_FONT_TEXT_BACKEND = 0
ENDIF
