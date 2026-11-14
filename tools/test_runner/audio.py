"""Save captured audio and check expected signal levels."""

import wave

from .comparison import output_basename


def write_audio_wav(raw_audio, wav_path):
    """Wrap ZEsarUX's 15.6 kHz unsigned mono PCM capture in a WAV container."""
    with wave.open(str(wav_path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(1)
        output.setframerate(15600)
        output.writeframes(raw_audio)


def preserve_partial_audio(raw_path, output_dir, case_name, profile_name, checkpoints,
                           active_step, active_step_name):
    """Split captured audio into completed steps and the incomplete step."""
    if not raw_path.is_file():
        return
    audio = raw_path.read_bytes()
    offset = 0
    for checkpoint in checkpoints:
        end_offset = min(max(checkpoint["end_offset"], offset), len(audio))
        if end_offset > offset:
            wav_path = output_dir / output_basename(
                case_name, profile_name, checkpoint["step"], checkpoint["name"], ".wav")
            write_audio_wav(audio[offset:end_offset], wav_path)
            print(f"      audio -> {wav_path.name}", flush=True)
        offset = end_offset
    if len(audio) > offset:
        partial_name = f"{active_step_name}-partial"
        wav_path = output_dir / output_basename(
            case_name, profile_name, active_step, partial_name, ".wav")
        write_audio_wav(audio[offset:], wav_path)
        print(f"      audio partial -> {wav_path.name}", flush=True)
    raw_path.unlink(missing_ok=True)


def check_audio_expectations(audio, expectations):
    """Check expected held levels and signal range in captured audio."""
    minimum = expectations.get("minimum_level_samples", 1)
    levels = expectations.get("levels_in_order", [])
    offset = 0
    for level in levels:
        pattern = bytes((level,)) * minimum
        position = audio.find(pattern, offset)
        if position < 0:
            return f"audio capture did not hold output level {level} for {minimum} samples"
        offset = position + minimum

    signal_range = expectations.get("range")
    minimum_peak_to_peak = expectations.get("minimum_peak_to_peak")
    if minimum_peak_to_peak is not None:
        peak_to_peak = max(audio) - min(audio) if audio else 0
        if peak_to_peak < minimum_peak_to_peak:
            return (f"audio peak-to-peak amplitude is {peak_to_peak}; "
                    f"expected at least {minimum_peak_to_peak}")
    if signal_range:
        low, high = signal_range
        if min(audio) >= low or max(audio) <= high:
            return ("audio signal stayed within the expected range "
                    f"({min(audio)}..{max(audio)}; expected below {low} and above {high})")
    level_range = expectations.get("level_range")
    if level_range:
        low, high = level_range
        if min(audio) < low or max(audio) > high:
            return ("audio levels were outside the expected range "
                    f"({min(audio)}..{max(audio)}; expected {low}..{high})")
    return None
