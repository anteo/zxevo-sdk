#include <tsconf/memory.h>
#include <tsconf/spi.h>
#include <tsconf/zifi32.h>
#include <zx_test.h>

typedef struct {
    uint8_t header[5];
    uint8_t header_length;
    const uint8_t *data;
    uint16_t length;
    uint8_t read;
} spi_frame_t;

static const spi_frame_t *frame;
static uint8_t frames_left;
static uint8_t selected;
static uint8_t header_bytes;
static uint16_t payload_bytes;
static uint8_t received;

static void expect_frames(const spi_frame_t *frames, uint8_t count) {
    ZX_ASSERT(!selected && !frames_left);
    frame = frames;
    frames_left = count;
}

void ts_spi_select(uint8_t selection) __z88dk_fastcall {
    ZX_ASSERT(frames_left != 0);
    if (!frames_left) return;
    if (selection == TS_SPI_ESP32) {
        ZX_ASSERT(!selected);
        selected = 1;
        header_bytes = 0;
        payload_bytes = 0;
        received = 0xff;
    } else {
        ZX_ASSERT(selection == TS_SPI_RELEASE && selected);
        ZX_ASSERT(header_bytes == frame->header_length);
        ZX_ASSERT(payload_bytes == frame->length);
        selected = 0;
        --frames_left;
        ++frame;
    }
}

static uint8_t payload_byte(uint16_t index) {
    return frame->data ? frame->data[index] : (uint8_t)(index ^ (index >> 8));
}

void ts_spi_write(uint8_t value) __z88dk_fastcall {
    ZX_ASSERT(selected && frames_left);
    if (!selected || !frames_left) return;
    if (header_bytes < frame->header_length) {
        ZX_ASSERT(value == frame->header[header_bytes]);
        ++header_bytes;
    } else {
        ZX_ASSERT(!frame->read && payload_bytes < frame->length);
        if (!frame->read && payload_bytes < frame->length) {
            ZX_ASSERT(value == payload_byte(payload_bytes));
            ++payload_bytes;
        }
    }
    received = 0xff;
}

uint8_t ts_spi_read_previous(void) {
    uint8_t previous = received;

    received = 0xff;
    if (selected && frames_left) {
        ZX_ASSERT(frame->read && header_bytes == frame->header_length);
        ZX_ASSERT(payload_bytes < frame->length);
        if (frame->read && payload_bytes < frame->length) {
            received = payload_byte(payload_bytes);
            ++payload_bytes;
        }
    }
    return previous;
}

static void check_registers(void) {
    static const uint8_t last[] = {0xa7};
    static const spi_frame_t frames[] = {{{0x02, 0x00, 0x00}, 3, 0, 64, 1},
                                         {{0x02, 0x3f, 0x00}, 3, last, 1, 1},
                                         {{0x01, 0x3f, 0x00}, 3, last, 1, 0},
                                         {{0x01, 0x00, 0x00}, 3, 0, 64, 0}};
    uint8_t buffer[64];
    uint8_t i;

    ZX_ASSERT(ts_zifi32_read_registers(0, buffer, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_registers(64, buffer, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_registers(63, buffer, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_registers(0, 0, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_registers(0, buffer, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_registers(64, buffer, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_registers(63, buffer, 2) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_registers(0, 0, 1) == ZX_INVALID_ARGUMENT);

    expect_frames(frames, 4);
    ZX_ASSERT(ts_zifi32_read_registers(0, buffer, sizeof(buffer)) == ZX_OK);
    for (i = 0; i < sizeof(buffer); ++i) {
        ZX_ASSERT(buffer[i] == i);
    }
    ZX_ASSERT(ts_zifi32_read_registers(63, buffer + 63, 1) == ZX_OK);
    ZX_ASSERT(buffer[63] == 0xa7);
    ZX_ASSERT(ts_zifi32_write_registers(63, buffer + 63, 1) == ZX_OK);
    buffer[63] = 63;
    ZX_ASSERT(ts_zifi32_write_registers(0, buffer, sizeof(buffer)) == ZX_OK);
    ZX_ASSERT(!frames_left && !selected);
    zx_test_step_marker("register-frames-and-bounds");
}

static void check_commands(void) {
    static const uint8_t args[] = {0x26, 0x43, 0x59};
    static const uint8_t idle[] = {0x00};
    static const uint8_t busy[] = {0x02};
    static const uint8_t ready[] = {0x01};
    static const uint8_t data_m2s[] = {0x03};
    static const uint8_t data_s2m[] = {0x04};
    static const uint8_t reset[] = {0x7e};
    static const uint8_t version_reply[] = {1, 0x34, 0x12, 0, 6, 4};
    static const spi_frame_t frames[] = {
        {{0x01, 0x00, 0x00, 0x13, 0x00}, 5, 0, 62, 0},
        {{0x01, 0x00, 0x00, 0xe1, 0x00}, 5, args, sizeof(args), 0},
        {{0x02, 0x01, 0x00}, 3, ready, 1, 1},
        {{0x02, 0x01, 0x00}, 3, data_m2s, 1, 1},
        {{0x02, 0x01, 0x00}, 3, data_s2m, 1, 1},
        {{0x02, 0x01, 0x00}, 3, reset, 1, 1},
        {{0x01, 0x00, 0x00, 0x02, 0x00}, 5, 0, 0, 0},
        {{0x02, 0x01, 0x00}, 3, idle, 1, 1},
        {{0x02, 0x01, 0x00}, 3, busy, 1, 1},
        {{0x02, 0x01, 0x00}, 3, ready, 1, 1},
        {{0x02, 0x02, 0x00}, 3, version_reply, sizeof(version_reply), 1}};
    ts_zifi32_version_t version;
    uint8_t max_args[62];
    uint8_t i;
    uint8_t status;

    ZX_ASSERT(ts_zifi32_issue(0, 0, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_issue(0xe1, args, 63) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_issue(0xe1, 0, 1) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_get_version(0, 3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_get_version(&version, 0) == ZX_INVALID_ARGUMENT);

    for (i = 0; i < sizeof(max_args); ++i) {
        max_args[i] = i;
    }
    expect_frames(frames, 11);
    ZX_ASSERT(ts_zifi32_issue(0x13, max_args, sizeof(max_args)) == ZX_OK);
    ZX_ASSERT(ts_zifi32_issue(0xe1, args, sizeof(args)) == ZX_OK);
    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_DATA_M2S, 2, &status) == ZX_OK);
    ZX_ASSERT(status == TS_ZIFI32_DATA_M2S);
    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_DATA_S2M, 1, 0) == ZX_OK);
    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_RESET, 1, 0) == ZX_OK);
    ZX_ASSERT(ts_zifi32_get_version(&version, 3) == ZX_OK);
    ZX_ASSERT(version.api == 1 && version.feature == 0x1234u);
    ZX_ASSERT(version.major == 0 && version.minor == 6 && version.patch == 4);
    ZX_ASSERT(!frames_left && !selected);
    zx_test_step_marker("issue-wait-and-version");
}

static void check_wait_errors(void) {
    static const uint8_t busy[] = {0x02};
    static const uint8_t error[] = {0x84};
    static const uint8_t absent[] = {0xff};
    static const spi_frame_t frames[] = {{{0x02, 0x01, 0x00}, 3, busy, 1, 1},
                                         {{0x02, 0x01, 0x00}, 3, busy, 1, 1},
                                         {{0x02, 0x01, 0x00}, 3, error, 1, 1},
                                         {{0x01, 0x00, 0x00, 0x02, 0x00}, 5, 0, 0, 0},
                                         {{0x02, 0x01, 0x00}, 3, absent, 1, 1}};
    ts_zifi32_version_t version = {7, 3, 8, 9, 10};
    uint8_t status = 0x55;

    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_READY, 0, &status) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_wait_status(0xff, 1, &status) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(status == 0x55);

    expect_frames(frames, 5);
    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_READY, 2, &status) == ZX_TIMEOUT);
    ZX_ASSERT(status == TS_ZIFI32_BUSY);
    ZX_ASSERT(ts_zifi32_wait_status(TS_ZIFI32_READY, 7, &status) == ZX_IO_ERROR);
    ZX_ASSERT(status == 0x84);
    ZX_ASSERT(ts_zifi32_get_version(&version, 7) == ZX_UNAVAILABLE);
    ZX_ASSERT(version.api == 7 && version.feature == 3);
    ZX_ASSERT(version.major == 8 && version.minor == 9 && version.patch == 10);
    ZX_ASSERT(!frames_left && !selected);
    zx_test_step_marker("timeout-firmware-error-and-absence");
}

static void check_data(void) {
    static const spi_frame_t frames[] = {{{0x04, 0x00, 0x00}, 3, 0, TS_ZIFI32_MAX_DATA, 1},
                                         {{0x08}, 1, 0, 0, 0},
                                         {{0x03, 0x00, 0x00}, 3, 0, 4, 0},
                                         {{0x07, 0x00}, 2, 0, 0, 0},
                                         {{0x03, 0x00, 0x00}, 3, 0, TS_ZIFI32_MAX_DATA, 0},
                                         {{0x07, 0x00}, 2, 0, 0, 0}};
    uint8_t *buffer = (uint8_t *)0xc001;
    uint16_t i;

    ZX_ASSERT(ts_zifi32_read_data(0, 4) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_data(buffer, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_data(buffer, 3) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_read_data(buffer, 4004) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_data(0, 4) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_data(buffer, 0) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_data(buffer, 5) == ZX_INVALID_ARGUMENT);
    ZX_ASSERT(ts_zifi32_write_data(buffer, 4004) == ZX_INVALID_ARGUMENT);

    ts_memory_set_page3(0x30);
    buffer[-1] = 0xa5;
    buffer[TS_ZIFI32_MAX_DATA] = 0x5a;
    expect_frames(frames, 6);
    ZX_ASSERT(ts_zifi32_read_data(buffer, TS_ZIFI32_MAX_DATA) == ZX_OK);
    for (i = 0; i < TS_ZIFI32_MAX_DATA; ++i) {
        ZX_ASSERT(buffer[i] == (uint8_t)(i ^ (i >> 8)));
    }
    ZX_ASSERT(buffer[-1] == 0xa5 && buffer[TS_ZIFI32_MAX_DATA] == 0x5a);
    ZX_ASSERT(ts_zifi32_write_data(buffer, 4) == ZX_OK);
    ZX_ASSERT(ts_zifi32_write_data(buffer, TS_ZIFI32_MAX_DATA) == ZX_OK);
    ZX_ASSERT(!frames_left && !selected);
    zx_test_step_marker("bulk-length-and-end-frames");
}

int main(void) {
    zx_test_init();
    check_registers();
    check_commands();
    check_wait_errors();
    check_data();
    zx_test_finish();
    return 0;
}
