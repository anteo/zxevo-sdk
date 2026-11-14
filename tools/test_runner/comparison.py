"""Name and compare reference data and screenshots."""

import difflib
import re
import shutil
import struct
import tomllib
import zlib
from pathlib import Path

from .support import FrameworkError, TestFailure


def slug(value, limit=40):
    value = re.sub(r"[^a-z0-9]+", "-", value.lower()).strip("-")
    return (value or "out")[:limit]


def output_prefix(case_name, profile_name=None):
    return f"{case_name}."


def output_basename(case_name, profile_name, step, name, extension):
    """Expected and actual file name; expected lives next to the case."""
    tag = slug(name if name and name != "out" else "out")
    index = step + 1
    return f"{output_prefix(case_name, profile_name)}{index:02d}_{tag}{extension}"


def expected_pattern(case_name, profile_name=None):
    return re.compile(rf"^{re.escape(case_name)}\.\d+_[^/]*\.(?:png|txt|bin|toml)$")


def expected_files(directory, case_name):
    pattern = expected_pattern(case_name)
    if not directory.is_dir():
        return []
    return sorted(path for path in directory.iterdir()
                  if path.is_file() and pattern.match(path.name))


def write_expected(actual, shared_dir, specific_dir, update_shared, inherited):
    shared = shared_dir / actual.name
    specific = specific_dir / actual.name
    if update_shared and not specific.is_file() and inherited in (None, shared):
        destination = shared
    elif inherited is not None and actual.read_bytes() == inherited.read_bytes():
        specific.unlink(missing_ok=True)
        return
    else:
        destination = specific
    destination.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(actual, destination)


def format_hex(raw):
    """Canonical, reviewable hex dump used for the data channel."""
    lines = []
    for offset in range(0, len(raw), 16):
        chunk = raw[offset:offset + 16]
        lines.append(f"{offset:04X}: " + " ".join(f"{byte:02X}" for byte in chunk))
    return "\n".join(lines) + "\n"


PNG_SIGNATURE = b"\x89PNG\r\n\x1a\n"


def decode_png(path):
    data = Path(path).read_bytes()
    if not data.startswith(PNG_SIGNATURE):
        raise FrameworkError(f"not a PNG file: {path}")
    position = 8
    width = height = None
    bit_depth = color_type = interlace = None
    compressed = bytearray()
    while position < len(data):
        length = struct.unpack(">I", data[position:position + 4])[0]
        tag = data[position + 4:position + 8]
        payload = data[position + 8:position + 8 + length]
        position += 12 + length
        if tag == b"IHDR":
            width, height, bit_depth, color_type, _, _, interlace = struct.unpack(">IIBBBBB", payload)
        elif tag == b"IDAT":
            compressed.extend(payload)
        elif tag == b"IEND":
            break
    if None in (width, height, bit_depth, color_type, interlace):
        raise FrameworkError(f"PNG has no IHDR: {path}")
    if bit_depth != 8 or color_type != 2 or interlace != 0:
        raise FrameworkError(f"only 8-bit RGB non-interlaced PNG is supported: {path}")
    raw = zlib.decompress(bytes(compressed))
    stride = width * 3
    pixels = bytearray(width * height * 3)
    previous = bytearray(stride)
    offset = 0
    for row in range(height):
        filter_type = raw[offset]
        offset += 1
        line = bytearray(raw[offset:offset + stride])
        offset += stride
        if filter_type == 1:
            for index in range(3, stride):
                line[index] = (line[index] + line[index - 3]) & 0xFF
        elif filter_type == 2:
            for index in range(stride):
                line[index] = (line[index] + previous[index]) & 0xFF
        elif filter_type == 3:
            for index in range(stride):
                left = line[index - 3] if index >= 3 else 0
                line[index] = (line[index] + ((left + previous[index]) >> 1)) & 0xFF
        elif filter_type == 4:
            for index in range(stride):
                left = line[index - 3] if index >= 3 else 0
                up = previous[index]
                up_left = previous[index - 3] if index >= 3 else 0
                estimate = left + up - up_left
                pa = abs(estimate - left)
                pb = abs(estimate - up)
                pc = abs(estimate - up_left)
                predictor = left if pa <= pb and pa <= pc else (up if pb <= pc else up_left)
                line[index] = (line[index] + predictor) & 0xFF
        elif filter_type != 0:
            raise FrameworkError(f"unsupported PNG filter {filter_type} in {path}")
        pixels[row * stride:(row + 1) * stride] = line
        previous = line
    return width, height, pixels


def png_chunk(tag, payload):
    body = tag + payload
    return struct.pack(">I", len(payload)) + body + struct.pack(">I", zlib.crc32(body) & 0xFFFFFFFF)


def encode_png(path, width, height, pixels):
    raw = bytearray()
    stride = width * 3
    for row in range(height):
        raw.append(0)
        raw.extend(pixels[row * stride:(row + 1) * stride])
    header = struct.pack(">IIBBBBB", width, height, 8, 2, 0, 0, 0)
    data = (PNG_SIGNATURE + png_chunk(b"IHDR", header) +
            png_chunk(b"IDAT", zlib.compress(bytes(raw), 6)) +
            png_chunk(b"IEND", b""))
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(data)


def compare_data_files(expected_path, actual_path, diff_path):
    left = expected_path.read_bytes()
    right = actual_path.read_bytes()
    if actual_path.suffix == ".toml":
        try:
            expected = tomllib.loads(left.decode("utf-8"))
            actual = tomllib.loads(right.decode("utf-8"))
        except (UnicodeError, tomllib.TOMLDecodeError) as error:
            raise TestFailure(f"{actual_path.name}: invalid TOML: {error}") from error
        if expected == actual:
            return None
    if left == right:
        return None
    if actual_path.suffix == ".bin":
        limit = min(len(left), len(right))
        first = next((index for index in range(limit) if left[index] != right[index]), limit)
        diff_path.write_text(
            f"binary differs at offset {first} (expected {len(left)} bytes, actual {len(right)} bytes)\n"
            f"expected: {left[max(0, first - 8):first + 24].hex(' ')}\n"
            f"actual:   {right[max(0, first - 8):first + 24].hex(' ')}\n",
            encoding="utf-8")
        return (f"{actual_path.name}: binary differs at offset {first} "
                f"(expected {len(left)} bytes, actual {len(right)} bytes)")
    left_lines = left.decode("latin1").splitlines(keepends=True)
    right_lines = right.decode("latin1").splitlines(keepends=True)
    diff = list(difflib.unified_diff(left_lines, right_lines,
                                     fromfile="golden/" + expected_path.name,
                                     tofile=actual_path.name))
    diff_path.write_text("".join(diff), encoding="utf-8")
    first = next((line for line in diff
                  if line[:1] in "+-" and not line.startswith(("+++", "---"))), "")
    return f"{actual_path.name}: text differs ({first.rstrip()!r}); see {diff_path}"


def compare_screenshots(expected_path, actual_path, diff_path, region=None):
    expected = decode_png(expected_path)
    actual = decode_png(actual_path)
    if expected[0] != actual[0] or expected[1] != actual[1]:
        raise TestFailure(
            f"screenshot size differs: {expected[0]}x{expected[1]} != {actual[0]}x{actual[1]}")
    width, height, left = expected
    right = actual[2]
    x, y, region_width, region_height = region or (0, 0, width, height)
    if not (0 <= x < x + region_width <= width and 0 <= y < y + region_height <= height):
        raise TestFailure(f"screenshot comparison region is outside {width}x{height}")
    count = 0
    first = None
    diff = bytearray(len(left))
    for row in range(y, y + region_height):
        start = (row * width + x) * 3
        for index in range(start, start + region_width * 3, 3):
            if left[index:index + 3] != right[index:index + 3]:
                count += 1
                if first is None:
                    first = (index // 3 % width, row)
                diff[index:index + 3] = b"\xff\x00\xff"
            else:
                diff[index] = left[index] // 3
                diff[index + 1] = left[index + 1] // 3
                diff[index + 2] = left[index + 2] // 3
    if count:
        encode_png(diff_path, width, height, diff)
    return count, first
