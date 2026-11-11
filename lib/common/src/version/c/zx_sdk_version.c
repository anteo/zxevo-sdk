#include <zx/version.h>

#define STRINGIFY_VALUE(value) #value
#define STRINGIFY(value) STRINGIFY_VALUE(value)

const char *zx_sdk_version(void) {
    return STRINGIFY(ZXEVO_SDK_VERSION_MAJOR) "." STRINGIFY(ZXEVO_SDK_VERSION_MINOR) "." STRINGIFY(
        ZXEVO_SDK_VERSION_PATCH);
}
