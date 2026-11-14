# Shared ZX Evolution code

[![English](https://img.shields.io/badge/lang-en-blue.svg)](README.en.md)
[![Русский](https://img.shields.io/badge/lang-ru-green.svg)](README.ru.md)

The ASM sources under `src/<subsystem>/z80` implement the mapped ZX bitmap layout, glyph and pixel
writes, clipped Bresenham lines, ellipse traversal, rectangle clipping, byte fills, plane scrolling,
bitmap fonts and console cursor movement. Both archives build these sources. Each platform supplies
its own surface selection, paging and mode-specific writers. The cursor helpers work on registers
supplied by the caller. The line walker requires serialized calls.

Public functions use the `zx_` prefix and internal entry points and state use `zx__`. Both libraries
use the ink and paper state exposed through the setters in `include/zx/color.h`.
`zx_set_colors(border, ink, paper)` sets all three together. `COLOR_BLACK` through `COLOR_WHITE` are
unshifted indices, with `COLOR_BRIGHT` available for bright palette indices. `zx_set_border_color()`
sets a 16-color border through the linked platform library. TSConf uses its default ZX palette bank
F. [Colors](include/zx/color.h)

Both libraries expose the built-in bitmap fonts as `zx_font8` and `zx_font5`. `zx/font.h` also
defines the descriptor and exposes the narrow glyph table as `zx_font5_data`.

The SDK CRT calls `zx_init()` before `main()` and `zx_shutdown()` on exit. To manage both calls
explicitly, build with `-pragma-define:CRT_ENABLE_ZX_LIFECYCLE=0`. Select the draw screen with
`zx_select_draw_screen()` and the displayed screen with `zx_show_screen()` when using the standard
ZX bitmap layout. The console API uses the same cell coordinates and `zx_status_t` results on both
machines. Use `zx_console_putc()` and `zx_console_puts()` to write at the cursor, or
`zx_console_draw()` to draw at a cell without moving the cursor. A positioned run stops at the right
edge or the first byte below 32. [Initialization](include/zx/init.h) · [Video](include/zx/video.h) ·
[Console](include/zx/console.h)

`zx_console_set_text_bg()` sets the background for character, string, formatted and positioned
console output. The initial mode is `ZX_TEXT_OPAQUE`. Use `zx_console_draw_op()` to override the
background for one positioned run. Transparent output retains unmarked pixels and existing bitmap
attributes. Native text modes reject transparency. The `zx_font_t` draw callback receives the
background mode as its last argument.

`zx/graphics.h` provides pixels, lines, circles, ellipses and rectangle fills, as well as graphics
groups, pixel readback and surface dimensions. The `_op` functions take a `zx_draw_op_t` value
(`ZX_DRAW_SET`, `ZX_DRAW_CLEAR` or `ZX_DRAW_XOR`). Packed drawing uses the current ink and paper.
Each library supplies the code that accesses its surfaces. [Graphics](include/zx/graphics.h)

`zx_blit4()` and `zx_blit4_key()` copy linear packed 4bpp images to BaseConf ATM320 or TSConf 16C
surfaces. The CPU backends support clipping, odd pixel edges and any transparent index 0..15. Keep
the source, code and stack resident; BaseConf needs both writable destination pages already mapped,
while TSConf borrows W3 and requires the source outside it. Calls preserve the palette, drawing
colors and displayed screen. [Shared blit API](include/zx/blit.h)

Both archives expose PT3, AYFX and Covox in `zx/audio.h`, Kempston mouse in `zx/input.h`, PS/2
modifiers and scancode logging in `zx/ps2.h`, and Z80 interrupt control, HALT and frame-counter
waiting in `zx/interrupt.h`. `zx/ide.h` provides Nemo IDE PIO on BaseConf and TSConf with `IDE_HDD`.
`zx/sd.h` provides direct SD SPI access with platform-specific chip selection. `zx/fdd.h` defines
the common VG93 and Beta Disk interface. `zx/rtc.h` provides clock, NVRAM, EEPROM and AVR version
access. Both platforms use the same calendar sampler and AVR version decoder. The Kondratyev UART
API is in `zx/uart.h`. `zx/timing.h` provides CPU clock control and `zx_frame_period()`. BaseConf
reads the current raster from AVR, and TSConf uses its build timing. For formatted console output
without CRT stdio, use `zx_console_printf()` from `zx/printf.h`. Each platform archive provides its
own writer object, which the linker extracts when resolving the formatter. If an application links
both archives, the linker selects one writer and one border implementation for that executable.

Both archives provide the RAM page pool and banked heap in `include/zx/memory.h`. Choose the paging
backend with `bc_ram_heap_init` or `ts_ram_heap_init`, then use the shared `zx_ram_heap_*`
operations. Allocation and free return `zx_status_t`. After either operation, call
`zx_ram_heap_unmap()` to ensure the window has been restored. The page pool works independently of
the heap and paging backend. [Common test scenarios](tests/README.en.md)

`zx_acquire_ram(window, page, &lease)` temporarily maps a physical RAM page; use
`zx_acquired_ram_set_page(&lease, next_page)` to advance within the same window and
`zx_release_ram(&lease)` to restore its original mapping. TSConf leases W2/W3; BaseConf leases any
unpinned window. `zx_pcm8_play_banked` uses this contract for consecutive pages and takes the window
and resident lease from the caller. The caller selects and restores CPU speed and cache.
[Memory](include/zx/memory.h) · [Audio](include/zx/audio.h)

`zx_ay_select_chip(ZX_AY_CHIP_0)` selects the first TurboSound AY; `ZX_AY_CHIP_1` selects the
second. Subsequent register accesses and PT3/AYFX output use that chip until it is changed.
Selection does not mute/reset chips, detect hardware, create separate player states or alter IFF.
Serialize selection together with the following AY operations against interrupt handlers. Invalid
chip numbers return `ZX_INVALID_ARGUMENT` without writing ports.

For AYFX effects, initialize a resident AFB bank with `zx_ayfx_init()`, schedule effects with
`zx_ayfx_play(index, volume_adjustment)`, and call `zx_ayfx_frame()` at the intended frame rate.
Serialize initialization and stop with the frame ISR; `zx_ayfx_play` protects its channel update
internally. On a shared AY, tick PT3 before AYFX; on TurboSound, select the required chip before
each player. `zx_ayfx_stop()` silences the selected chip. [Audio contracts](include/zx/audio.h)

## BASIC 48 startup profile

BaseConf and TSConf share the `-subtype=basic48` zcc profile and CRT. Use
`$(BASECONF_BASIC48_FLAGS) -create-app` or `$(TSCONF_BASIC48_FLAGS) -create-app` in an application
Makefile. Include the corresponding library's Make fragment to set the target, ABI and archive
paths. For direct zcc calls, export `ZX_COMMON_ROOT` as the absolute path to this directory and
supply the target's include and library paths and ABI flags
(`-clib=classic -compiler=sdcc --reserve-regs-iy`). BaseConf also needs `BASECONF_ROOT`. Both
targets use the SDK appmake, which you can build with `make appmake` before a direct zcc call.

```sh
make examples
```

This builds the examples in `lib/baseconf/build/examples/` and `lib/tsconf/build/examples/`. The
files use the standard ZX TAP layout. The BASIC loader executes `CLEAR 32767`, loads the flat CODE
block at `8000h` and calls `RANDOMIZE USR 32768`.

The CRT clears BSS and uses the stack supplied by BASIC below `8000h`. Initialized DATA is part of
the CODE block. BASIC supplies the paging and interrupt setup. Keep the linked image accessible, and
restore the BASIC ROM, workspace, stack mapping and interrupt state before returning if the program
changes them. The CRT restores SP, IX and IY, and returns the exit code in BC. An initialization
error skips `main()` and becomes the exit code. If the application exits with code zero, a shutdown
error becomes the exit code. Finish any graphics groups and release leased windows before exiting.

The default Z80 and BASIC 48 CRTs both leave stdio off by default. Enable standard streams with
`-pragma-define:CRT_ENABLE_STDIO=1`.

The standard 8x8 font uses the BASIC ROM glyphs at `3D00h`. Keep the ROM mapped in W0 while using
the font. To use the embedded glyphs instead, build with `-pragma-define:CRT_USE_ROM_FONT=0`.

For BaseConf in ZEsarUX, press `I` in the ERS menu to start BASIC 48. For TSConf, choose `ROM #00`
and `Basic 48` in TS-BIOS Setup, then reset. Insert the TAP for your configuration and enter
`LOAD ""`. In both configurations, `hello.tap` prints a greeting on the ZX screen and returns to
BASIC. [BaseConf examples](../baseconf/README.en.md#tests-and-examples) ·
[TSConf examples](../tsconf/README.en.md#basic-48-startup-profile)
