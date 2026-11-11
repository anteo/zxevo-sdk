#include <tsconf/ft812.h>
#include <tsconf/spi.h>
#include <tsconf/video.h>
#include <zx_test.h>

/* Script exact FT812 transactions behind the SPI API. The emulator has no
 * VDAC2 device. The mock models the delayed SPI receive byte as well as CS. */
typedef struct {
    uint8_t tx[15];
    uint8_t tx_size;
    uint8_t rx[3];
    uint8_t rx_size;
} exchange_t;

#define READ_BYTE(low, value) {{0x30, 0x20, low, 0}, 4, {value}, 1}
#define WRITE_BYTE(low, value) {{0xb0, 0x20, low, value}, 4, {0}, 0}
#define WRITE_WORD(low, value)                                                                     \
    {{0xb0, 0x20, low, (uint8_t)(value), (uint8_t)((value) >> 8)}, 5, {0}, 0}

static const exchange_t *script;
static uint8_t frame_count;
static uint8_t frame_index;
static uint8_t selected;
static uint8_t tx_index;
static uint8_t rx_index;
static uint8_t received;
static uint8_t video_config;
static uint8_t video_writes;

static void expect(const exchange_t *frames, uint8_t count) {
    ZX_ASSERT(!selected && frame_index == frame_count);
    script = frames;
    frame_count = count;
    frame_index = 0;
}

static void complete(void) {
    ZX_ASSERT(!selected && frame_index == frame_count);
}

void ts_spi_select(uint8_t selection) __z88dk_fastcall {
    if (selection == TS_SPI_FT812) {
        ZX_ASSERT(!selected && frame_index < frame_count);
        selected = 1;
        tx_index = 0;
        rx_index = 0;
        received = 0xff;
        return;
    }

    ZX_ASSERT(selection == TS_SPI_RELEASE && selected && frame_index < frame_count);
    if (selected && frame_index < frame_count) {
        ZX_ASSERT(tx_index == script[frame_index].tx_size);
        ZX_ASSERT(rx_index == script[frame_index].rx_size);
        ++frame_index;
    }
    selected = 0;
}

void ts_spi_write(uint8_t value) __z88dk_fastcall {
    ZX_ASSERT(selected && frame_index < frame_count);
    if (!selected || frame_index >= frame_count) return;
    ZX_ASSERT(tx_index < script[frame_index].tx_size);
    if (tx_index < script[frame_index].tx_size) {
        ZX_ASSERT(value == script[frame_index].tx[tx_index]);
        ++tx_index;
    }
    received = 0xff;
}

uint8_t ts_spi_read_previous(void) {
    uint8_t previous = received;

    received = 0xff;
    if (selected && frame_index < frame_count) {
        ZX_ASSERT(tx_index == script[frame_index].tx_size);
        ZX_ASSERT(rx_index < script[frame_index].rx_size);
        if (rx_index < script[frame_index].rx_size) received = script[frame_index].rx[rx_index++];
    }
    return previous;
}

void ts_video_set_config(uint8_t config) __z88dk_fastcall {
    video_config = config;
    ++video_writes;
}

static void check_protocol(void) {
    static const exchange_t frames[] = {{{0x61, 0x45, 0x00}, 3, {0}, 0},
                                        {{0x00, 0x00, 0x00}, 3, {0}, 0},
                                        {{0x3f, 0xff, 0xfe, 0x00}, 4, {0xd3, 0x80}, 2},
                                        {{0xbf, 0xff, 0xfe, 0xd3, 0x80}, 5, {0}, 0}};
    uint8_t buffer[3] = {0, 0, 0x25};

    expect(0, 0);
    ZX_ASSERT(ts_ft812_host_command(0x80, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_host_command(TS_FT812_CMD_ACTIVE, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_read(0, 0, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_write(0, 0, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_read(0x3ffffful, buffer, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_write(0x400000ul, buffer, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_write(0xfffffffful, 0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_read(0x400000ul, 0, 0) == ZX_OK);
    ZX_ASSERT(ts_ft812_write(0, 0, 0) == ZX_OK);
    ZX_ASSERT(buffer[0] == 0 && buffer[1] == 0 && buffer[2] == 0x25);

    expect(frames, sizeof(frames) / sizeof(*frames));
    ZX_ASSERT(ts_ft812_host_command(TS_FT812_CMD_CLKSEL, TS_FT812_CLK_60_MHZ) == ZX_OK);
    ZX_ASSERT(ts_ft812_host_command(TS_FT812_CMD_ACTIVE, 0) == ZX_OK);
    ZX_ASSERT(ts_ft812_read(0x3ffffeul, buffer, 2) == ZX_OK);
    ZX_ASSERT(buffer[0] == 0xd3 && buffer[1] == 0x80 && buffer[2] == 0x25);
    ZX_ASSERT(ts_ft812_write(0x3ffffeul, buffer, 2) == ZX_OK);
    complete();
    zx_test_step_marker("spi-framing");
}

static void check_ready(void) {
    static const exchange_t frames[] = {
        READ_BYTE(0x00, 0xff), READ_BYTE(0x00, 0x7c), READ_BYTE(0x20, 1),   READ_BYTE(0x00, 0x7c),
        READ_BYTE(0x20, 0),    READ_BYTE(0x00, 0xff), READ_BYTE(0x00, 0xff)};

    expect(0, 0);
    ZX_ASSERT(ts_ft812_wait_ready(0) == ZX_TIMEOUT);
    expect(frames, sizeof(frames) / sizeof(*frames));
    ZX_ASSERT(ts_ft812_wait_ready(5) == ZX_OK);
    ZX_ASSERT(frame_index == 5);
    ZX_ASSERT(ts_ft812_wait_ready(2) == ZX_TIMEOUT);
    complete();
    zx_test_step_marker("bounded-probe");
}

static void check_display(void) {
    static const exchange_t frames[] = {
        WRITE_BYTE(0x70, 0),   WRITE_WORD(0x2c, 800), WRITE_WORD(0x30, 144), WRITE_WORD(0x34, 640),
        WRITE_WORD(0x38, 0),   WRITE_WORD(0x3c, 96),  WRITE_WORD(0x40, 525), WRITE_WORD(0x44, 35),
        WRITE_WORD(0x48, 480), WRITE_WORD(0x4c, 0),   WRITE_WORD(0x50, 2),   WRITE_BYTE(0x60, 1),
        WRITE_BYTE(0x64, 13),  WRITE_BYTE(0x68, 0),   WRITE_BYTE(0x6c, 1),   WRITE_BYTE(0x70, 2)};
    ts_ft812_timing_t timing = {{800, 144, 640, 0, 96}, {525, 35, 480, 0, 2}, 1, 13, 0, 1};

    expect(0, 0);
    ZX_ASSERT(ts_ft812_configure_display(0) == ZX_INVALID_ARGUMENT);
    timing.horizontal.offset = 161;
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_INVALID_ARGUMENT);
    timing.horizontal.offset = 144;
    timing.vertical.sync_end = 0;
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_INVALID_ARGUMENT);
    timing.vertical.sync_end = 2;
    timing.vertical.cycle = 4096;
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_INVALID_ARGUMENT);
    timing.vertical.cycle = 2500;
    timing.vertical.size = 2048;
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_INVALID_ARGUMENT);
    timing.vertical.cycle = 525;
    timing.vertical.size = 480;
    timing.swizzle = 16;
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_INVALID_ARGUMENT);
    timing.swizzle = 13;

    expect(frames, sizeof(frames) / sizeof(*frames));
    ZX_ASSERT(ts_ft812_configure_display(&timing) == ZX_OK);
    ts_ft812_set_pclk(2);
    complete();
    ts_ft812_route_video(0xb9, 0x80);
    ZX_ASSERT(video_writes == 1 && video_config == 0xbd);
    ts_ft812_route_video(0xbd, 0);
    ZX_ASSERT(video_writes == 2 && video_config == 0xb9);
    zx_test_step_marker("raster-and-routing");
}

static void check_display_list(void) {
    static const uint32_t list[] = {TS_FT812_DL_CLEAR_COLOR_RGB(0x9a, 0xbc, 0xde),
                                    TS_FT812_DL_CLEAR(1, 0, 1), TS_FT812_DL_DISPLAY};
    static const exchange_t frames[] = {
        READ_BYTE(0x54, 0xff),
        READ_BYTE(0x54, 2),
        READ_BYTE(0x54, 0),
        {{0xb0, 0x00, 0x00, 0xde, 0xbc, 0x9a, 0x02, 5, 0, 0, 0x26, 0, 0, 0, 0}, 15, {0}, 0},
        WRITE_BYTE(0x54, 2),
        READ_BYTE(0x54, 2),
        READ_BYTE(0x54, 2),
        READ_BYTE(0x54, 0),
        READ_BYTE(0x54, 0xff)};

    expect(0, 0);
    ZX_ASSERT(ts_ft812_submit_display_list(0, 3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_submit_display_list(list, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_submit_display_list(list, TS_FT812_DL_WORDS + 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_submit_display_list(list, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_ft812_wait_display_list(0) == ZX_TIMEOUT);

    expect(frames, sizeof(frames) / sizeof(*frames));
    ZX_ASSERT(ts_ft812_submit_display_list(list, 3) == ZX_UNAVAILABLE);
    ZX_ASSERT(ts_ft812_submit_display_list(list, 3) == ZX_BUSY);
    ZX_ASSERT(ts_ft812_submit_display_list(list, 3) == ZX_OK);
    ZX_ASSERT(ts_ft812_wait_display_list(1) == ZX_TIMEOUT);
    ZX_ASSERT(ts_ft812_wait_display_list(2) == ZX_OK);
    ZX_ASSERT(ts_ft812_wait_display_list(2) == ZX_UNAVAILABLE);
    complete();
    zx_test_step_marker("display-list-swap");
}

int main(void) {
    zx_test_init();
    check_protocol();
    check_ready();
    check_display();
    check_display_list();
    zx_test_finish();
    return 0;
}
