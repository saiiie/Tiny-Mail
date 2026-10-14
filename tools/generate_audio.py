"""Generate original Tiny Post PCM WAVs using only Python's standard library.
Run: python tools/generate_audio.py (overwrites only the three named WAVs).
No samples, downloads, packages, or existing songs are used.
"""
from array import array
import math
from pathlib import Path
import random
import sys
import wave

RATE = 22050
ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"


def tone(samples, start, duration, midi, gain):
    frequency = 440.0 * 2 ** ((midi - 69) / 12)
    count = int(duration * RATE)
    offset = int(start * RATE)
    for index in range(count):
        t = index / RATE
        # Short attack and smooth release avoid clicks, including loop edges.
        envelope = min(t / 0.025, 1.0) * min((duration - t) / 0.12, 1.0)
        phase = 2 * math.pi * frequency * t
        value = (math.sin(phase) + 0.12 * math.sin(2 * phase)) / 1.12
        if offset + index < len(samples):
            samples[offset + index] += gain * envelope * value


def save(relative, samples):
    peak = max(abs(value) for value in samples)
    assert peak < 1.0, "Clipping: reduce synthesis gain"
    pcm = array("h", (round(value * 32767) for value in samples))
    if sys.byteorder != "little":
        pcm.byteswap()
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path), "wb") as output:
        output.setnchannels(1)
        output.setsampwidth(2)
        output.setframerate(RATE)
        output.writeframes(pcm.tobytes())
    print(f"{relative}: {len(samples) / RATE:.2f}s, peak {peak:.3f}")


def main():
    music = [0.0] * (RATE * 12)
    # A short original C-major phrase, sixteen gentle beats at 80 BPM.
    melody = [72, 76, 74, 79, 76, 72, 74, 67, 69, 72, 77, 76, 74, 71, 67, 72]
    for beat, note in enumerate(melody):
        tone(music, beat * 0.75, 0.68, note, 0.34)
    for bar, bass in enumerate([48, 53, 57, 55]):
        tone(music, bar * 3, 2.85, bass, 0.13)
        tone(music, bar * 3, 2.85, bass + 7, 0.07)
    save("music/tiny_post_theme.wav", music)

    chime = [0.0] * int(RATE * 0.7)
    for index, note in enumerate([76, 79, 84]):
        tone(chime, index * 0.14, 0.36, note, 0.38)
    save("sfx/delivery_chime.wav", chime)

    splash = [0.0] * int(RATE * 0.28)
    noise = random.Random(5)
    smooth = 0.0
    for index in range(len(splash)):
        t = index / RATE
        smooth = 0.7 * smooth + 0.3 * noise.uniform(-1, 1)
        envelope = min(t / 0.008, 1.0) * (1 - t / 0.28) ** 2
        splash[index] = envelope * (0.38 * smooth + 0.12 * math.sin(2 * math.pi * (210 * t - 200 * t * t)))
    save("sfx/puddle_splash.wav", splash)


if __name__ == "__main__":
    main()
