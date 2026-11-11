#ifndef ZX_VERSION_H
#define ZX_VERSION_H

#define ZXEVO_SDK_VERSION_MAJOR 0
#define ZXEVO_SDK_VERSION_MINOR 1
#define ZXEVO_SDK_VERSION_PATCH 0

/* Return the version of the linked SDK as a static MAJOR.MINOR.PATCH string. */
const char *zx_sdk_version(void);

#endif
