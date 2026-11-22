#include <zx/basic48.h>
#include "internal.h"

bc__basic48_video_t bc__basic48_video;

/* In 128K mode bit 5 locks 7FFD. Clear it once with INT masked and return
 * immediately to the original addressing, including W3 bank substitution.
 * The saved 7FFD byte reinstates the lock when the session ends. */
static zx_status_t unlock_display(uint8_t paging, uint8_t eff7) {
    zx_status_t status;
    if (!(eff7 & 4u) || !BC_PAGING_IS_LOCKED_128K(paging)) return ZX_OK;
    status = bc__mem_write_eff7(eff7 & (uint8_t)~4u);
    if (status != ZX_OK) {
        if (bc_readback_register(0x0b) != eff7) bc__mem_write_eff7(eff7);
        return status;
    }
    z80_outp(0x7ffd, paging & (uint8_t)~0x20u);
    status = bc__mem_write_eff7(eff7);
    if (status != ZX_OK || bc_readback_register(0x0a) != (paging & (uint8_t)~0x20u)) {
        z80_outp(0x7ffd, paging);
        bc__mem_write_eff7(eff7);
        return ZX_UNSAFE_CONTEXT;
    }
    return ZX_OK;
}

zx_status_t bc_basic48_video_begin(bc_video_mode_t mode) {
    bc__basic48_video_t *s = &bc__basic48_video;
    const bc_window_config_t *windows;
    uint16_t mode_and_eff7;
    uint8_t paging, eff7, irq, split;
    zx_ram_page_t page, w3_page;
    zx_status_t status;

    if ((uint16_t)mode > BC_VIDEO_EVO_TEXT_80) return ZX_INVALID_ARGUMENT;
    if (!bc_mem_initialized) return ZX_NOT_INITIALIZED;
    if (s->phase || bc_video_operation_depth || bc_mem_active_window_lease) return ZX_BUSY;
#ifndef BASECONF_VIDEO_ALL_MODES
    if (!bc__video_mode_enabled(mode) || !bc__video_mode_enabled(BC_VIDEO_ZX_256))
        return ZX_UNSUPPORTED;
#endif
    irq = zx_interrupt_save_disable();
    paging = bc_readback_register(0x0a);
    mode_and_eff7 = bc__video_read_mode_and_eff7();
    eff7 = mode_and_eff7 >> 8;
    windows = bc_mem_window_cache[bc_mem_active_map];
    page = bc__video_first_screen_pages[mode] + 2;
    split = mode >= BC_VIDEO_PENTAGON_256 && mode <= BC_VIDEO_ATM_TEXT_80;
    w3_page = windows[3].physical_page;
    if (windows[3].substitute_from_7ffd_or_dos)
        w3_page = (eff7 & 4u) ? (w3_page & 0xf8u) | BC_PAGING_RAM_PAGE_128K(paging)
                              : (w3_page & 0xc0u) | BC_PAGING_RAM_PAGE_1024K(paging);
    if ((uint8_t)mode_and_eff7 != ZX_VIDEO_ZX_256 || BC_PAGING_SCREEN(paging) != ZX_SCREEN_0 ||
        BC_PAGING_ACTIVE_MAP(paging) != bc_mem_active_map || windows[1].kind != BC_RAM ||
        windows[1].physical_page != 5 || windows[1].substitute_from_7ffd_or_dos ||
        windows[1].write_protected || windows[2].kind != BC_RAM ||
        windows[2].substitute_from_7ffd_or_dos || windows[2].physical_page == page ||
        (split && windows[2].physical_page == 7) ||
        (windows[3].kind == BC_RAM && (w3_page == page || (split && w3_page == 7))) ||
        ZX__WINDOW_BASE(zx__mem_read_sp()) != ZX_WINDOW_2 ||
        (bc_mem_pinned_window_mask & (ZX_WINDOW_MASK(ZX_WINDOW_1) | ZX_WINDOW_MASK(ZX_WINDOW_3)))) {
        zx_interrupt_restore(irq);
        return ZX_UNSAFE_CONTEXT;
    }

    s->w1 = windows[1];
    s->w3 = windows[3];
    s->irq = irq;
    s->border = zx_basic48_get_border_color();
    s->mode = mode;
    s->page = page;
    s->split = split;
    s->paging = paging;
    status = unlock_display(paging, eff7);
    if (status != ZX_OK) {
        zx_interrupt_restore(irq);
        return status;
    }

    status = split ? zx_set_split_draw_buffer(mode, page, ZX_WINDOW_1, 7, ZX_WINDOW_3)
                   : zx_set_draw_buffer(mode, page, ZX_WINDOW_3);
    if (status != ZX_OK) {
        /* Buffer preparation validates both mappings before changing either. */
        z80_outp(0x7ffd, paging);
        zx_interrupt_restore(irq);
        return status;
    }
    s->phase = BC_BASIC48_DRAWING;
    return ZX_OK;
}
