        MODULE zx_display_page
EXTERN ts__video_display_page_e
SECTION code_clib
PUBLIC _zx_display_page

; Load the physical page from SP+2 and pass it in E to the page selector.
_zx_display_page:
        ld hl,2
        add hl,sp
        ld e,(hl)
        jp ts__video_display_page_e
