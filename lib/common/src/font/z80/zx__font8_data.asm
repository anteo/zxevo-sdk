        MODULE zx__font8_data

PUBLIC zx__font8_data
EXTERN _font_8x8_zx_system

; Use the embedded z88dk glyphs unless the CRT supplies the font address.
defc zx__font8_data = _font_8x8_zx_system
