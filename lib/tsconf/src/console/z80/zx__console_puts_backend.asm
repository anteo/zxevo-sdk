        MODULE zx__console_puts_backend
PUBLIC zx__console_puts_backend
EXTERN zx__console_puts_chars

; TSConf uses the common string loop with its regular console writer.
defc zx__console_puts_backend = zx__console_puts_chars
