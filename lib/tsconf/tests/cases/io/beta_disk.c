#include <tsconf/fdd.h>
#include <tsconf/input.h>
#include <zx_test.h>

int main(void) {
    const zx_fdd_system_t disk = {ZX_FDD_DRIVE_A, 0, 1, 0};
    const zx_fdd_system_t bad_disk = {ZX_FDD_DRIVE_A, 2, 1, 0};
    uint8_t byte = 0xa5;

    zx_test_init();
    ts_fdd_set_config(0);
    ZX_ASSERT(ts_joystick_read() == 0);
    zx_test_step_marker("joystick-idle");
    ZX_ASSERT(ts_joystick_read() == (TS_JOYSTICK_RIGHT | TS_JOYSTICK_FIRE));
    zx_test_step_marker("joystick-pressed");

    ZX_ASSERT(zx_fdd_reg_read((zx_fdd_reg_t)4, &byte) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(byte == 0xa5);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_TRACK, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_fdd_reg_write((zx_fdd_reg_t)4, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_fdd_status(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_fdd_system_write(0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(zx_fdd_system_write(&bad_disk) == ZX_INVALID_ARGUMENT);
    ts_fdd_set_config(TS_FDD_OPEN_PORTS | 0x70u);
    zx_test_step_marker("ports-open");

    ZX_ASSERT(zx_fdd_system_write(&disk) == ZX_OK);
    /* The emulator asserts both lines to let the ROM detect its TRD. */
    ZX_ASSERT(zx_fdd_status(&byte) == ZX_OK);
    ZX_ASSERT((byte & (ZX_FDD_DRQ | ZX_FDD_INTRQ)) == (ZX_FDD_DRQ | ZX_FDD_INTRQ));
    ZX_ASSERT(zx_fdd_reg_write(ZX_FDD_TRACK, 0x31) == ZX_OK);
    ZX_ASSERT(zx_fdd_reg_write(ZX_FDD_SECTOR, 0x17) == ZX_OK);
    ZX_ASSERT(zx_fdd_reg_write(ZX_FDD_DATA, 0x42) == ZX_OK);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_TRACK, &byte) == ZX_OK && byte == 0x31);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_SECTOR, &byte) == ZX_OK && byte == 0x17);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_DATA, &byte) == ZX_OK && byte == 0x42);
    ZX_ASSERT(zx_fdd_reg_write(ZX_FDD_COMMAND, 0xc0) == ZX_OK);
    ZX_ASSERT(zx_fdd_reg_read(ZX_FDD_DATA, &byte) == ZX_OK && byte == 0x31);
    zx_test_step_marker("vg93-registers");

    ts_fdd_set_config(0);
    ZX_ASSERT(ts_joystick_read() == (TS_JOYSTICK_RIGHT | TS_JOYSTICK_FIRE));
    zx_test_step_marker("ports-closed");
    ZX_ASSERT(ts_joystick_read() == 0);
    zx_test_finish();
    return 0;
}
