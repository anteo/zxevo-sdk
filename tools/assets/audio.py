"""Convert uncompressed WAV PCM to unsigned 8-bit mono sample bytes."""
import json
import struct
import wave
from pathlib import Path

def convert_wav(path):
    try:
        with wave.open(str(path), 'rb') as source:
            channels, width = source.getnchannels(), source.getsampwidth()
            rate, frames = source.getframerate(), source.getnframes()
            if source.getcomptype() != 'NONE' or channels not in (1, 2) or width not in (1, 2):
                raise ValueError('WAV input must be uncompressed 8/16-bit PCM, mono or stereo')
            data = source.readframes(frames)
    except wave.Error as error:
        raise ValueError(f'unsupported WAV: {error}') from error
    if len(data) != frames * channels * width:
        raise ValueError('truncated WAV sample data')
    if not frames:
        raise ValueError('WAV has no samples')
    if width == 1 and channels == 1:
        output = data
    else:
        samples = [value - 128 for value in data] if width == 1 else [
            value[0] for value in struct.iter_unpack('<h', data)]
        divisor = channels * (256 if width == 2 else 1)
        output = bytes(max(0, min(255, 128 + sum(samples[i:i + channels]) // divisor))
                       for i in range(0, len(samples), channels))
    return output, dict(unpacked_size=len(output), sample_count=frames,
                        sample_rate=rate, channels=1, bits_per_sample=8, compression='none')


def register_parser(subparsers):
    parser = subparsers.add_parser("wav", help="PCM WAV to unsigned 8-bit mono .bin and JSON")
    parser.add_argument("input", type=Path)
    parser.add_argument("--output", type=Path, required=True,
                        help="output path prefix, without extension; relative to the current directory")
    parser.set_defaults(handler=run)


def run(args):
    samples, metadata = convert_wav(args.input)
    return (
        (Path(str(args.output) + ".bin"), samples),
        (Path(str(args.output) + ".json"), (json.dumps(metadata, indent=2) + "\n").encode("utf-8")),
    )
