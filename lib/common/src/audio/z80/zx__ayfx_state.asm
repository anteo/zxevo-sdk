; Resident state shared by AYFX entry points. Keep separate from PT3 so
; linking either player does not pull the other into the application.
SECTION bss_clib
PUBLIC zx__ayfx_table
PUBLIC zx__ayfx_count
PUBLIC zx__ayfx_channels
INCLUDE "audio/z80/ayfx.inc"
zx__ayfx_table: defs 2
zx__ayfx_count: defs 1
zx__ayfx_channels: defs AFX_CHANNEL_BYTES
