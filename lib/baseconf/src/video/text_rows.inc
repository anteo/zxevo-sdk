; Packed SDCC argument block addressed by IX after saving the caller's IX.
; surface.mode at +1 is redundant with the explicit mode argument at +0.
defc BC_TEXT_ROWS_MODE = 0
defc BC_TEXT_ROWS_PAGE0 = 2
defc BC_TEXT_ROWS_PAGE1 = 3
defc BC_TEXT_ROWS_ROW = 4       ; row index for clear, row count for scroll
defc BC_TEXT_ROWS_COLUMNS = 5
defc BC_TEXT_ROWS_ATTRIBUTE = 6 ; present only for clear
