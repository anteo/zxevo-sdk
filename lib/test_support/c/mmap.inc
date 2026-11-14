INCLUDE "crt/classic/crt_section_code.inc"
INCLUDE "crt/classic/crt_section_rodata.inc"
SECTION ROMABLE_END
IF !__crt_model
    SECTION DATA
    org CRT_ORG_DATA
    INCLUDE "crt/classic/crt_section_data.inc"
ENDIF
INCLUDE "crt/classic/crt_section_bss.inc"
SECTION BSS_END
