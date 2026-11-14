#!/bin/sh
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
src_dir=${Z88DK_SRC:-}
if [ -z "$src_dir" ]; then
    echo "Set Z88DK_SRC to the z88dk src directory" >&2
    exit 2
fi
src_dir=$(CDPATH= cd -- "$src_dir" && pwd)

for required in appmake/appmake.h appmake/Makefile common/dirname.c common/dirname.h config.h; do
    if [ ! -f "$src_dir/$required" ]; then
        echo "Missing z88dk source file: $src_dir/$required" >&2
        exit 2
    fi
done

build_dir="$script_dir/build"
mkdir -p "$build_dir"
stage_dir=$(mktemp -d "$build_dir/source.XXXXXX")
trap 'rm -rf "$stage_dir"' EXIT HUP INT TERM
cp -R "$src_dir/appmake" "$stage_dir/"
mkdir -p "$stage_dir/common"
cp "$src_dir/common/dirname.c" "$src_dir/common/dirname.h" "$stage_dir/common/"
cp "$src_dir/config.h" "$stage_dir/"
cp "$script_dir/zxevo.c" "$stage_dir/appmake/zxevo.c"

patch -d "$stage_dir/appmake" -p1 < "$script_dir/patches/zxevo-registration.patch"

gmp_cflags=$(pkg-config --cflags gmp 2>/dev/null || true)
gmp_libs=$(pkg-config --libs gmp 2>/dev/null || true)
if [ -z "$gmp_libs" ]; then gmp_libs=-lgmp; fi
cflags=${CFLAGS:--O2 -Wall -std=gnu11 -MMD -pedantic -I../common}
if [ -n "$gmp_cflags" ]; then cflags="$cflags $gmp_cflags"; fi

make -C "$stage_dir/appmake" \
    CC="${CC:-cc}" \
    CFLAGS="$cflags" \
    LDFLAGS="$gmp_libs"

make -C "$script_dir/../mhmt" CC="${CC:-cc}"
mv "$stage_dir/appmake/z88dk-appmake" "$build_dir/z88dk-appmake"
echo "Built $build_dir/z88dk-appmake using z88dk source version $(sed -n 's/^#define Z88DK_VERSION \(.*\)$/\1/p' "$stage_dir/config.h")"
