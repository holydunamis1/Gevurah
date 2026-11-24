#!/usr/bin/env python3
"""Synthesizes the game's sound effects. Original sounds, no licensing, and a
fixed seed so the same script always writes the same bytes.

Usage: make_sfx.py [output_dir]   (default app/assets/audio)
The menu loop is made in a later batch.
"""
import math
import random
import struct
import sys
import wave
from pathlib import Path

RATE = 22050
SEED = 20261124


def tone(freq, ms, vol=0.6, decay=6.0, end_freq=None):
    n = int(RATE * ms / 1000)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        f = freq + ((end_freq - freq) * t if end_freq else 0)
        phase += 2 * math.pi * f / RATE
        env = math.exp(-decay * t) * min(1.0, i / (RATE * 0.004))
        out.append(vol * env * math.sin(phase))
    return out


def noise(ms, rng, vol=0.5, decay=8.0, smooth=0.0):
    n = int(RATE * ms / 1000)
    out, prev = [], 0.0
    for i in range(n):
        t = i / n
        x = rng.uniform(-1, 1)
        prev = smooth * prev + (1 - smooth) * x
        out.append(vol * math.exp(-decay * t) * prev)
    return out


def mix(*parts):
    n = max(len(p) for p in parts)
    return [sum(p[i] for p in parts if i < len(p)) for i in range(n)]


def delay(samples, ms):
    return [0.0] * int(RATE * ms / 1000) + samples


def build(rng):
    s = {}
    s["tell"] = mix(tone(880, 170, 0.45, 5), delay(tone(1175, 150, 0.4, 6), 70))
    s["tell_heavy"] = mix(tone(110, 340, 0.7, 3, 85), tone(55, 340, 0.5, 3), noise(340, rng, 0.08, 4, 0.9))
    s["tell_flurry"] = mix(*(delay(tone(1000 + 80 * k, 60, 0.4, 9), 75 * k) for k in range(3)))
    s["hit"] = mix(tone(140, 150, 0.8, 9, 70), noise(130, rng, 0.5, 11, 0.55))
    s["perfect"] = mix(tone(1320, 260, 0.4, 5), delay(tone(1760, 240, 0.35, 5), 40))
    s["guard"] = mix(tone(330, 110, 0.6, 12, 260), noise(30, rng, 0.35, 14, 0.2))
    s["slip"] = [x * (math.sin(math.pi * i / 3300)) for i, x in enumerate(noise(150, rng, 0.45, 0.5, 0.82))]
    s["down"] = mix(tone(230, 380, 0.65, 3.5, 110), tone(115, 380, 0.4, 3.5, 55))
    s["defeat"] = mix(*(delay(tone(f, 380, 0.3, 3.5), 110 * k) for k, f in enumerate((523, 659, 784, 988, 1175))))
    s["count"] = mix(tone(620, 70, 0.55, 14), noise(18, rng, 0.2, 14, 0.3))
    return s


def write(path, samples):
    peak = max(1e-9, max(abs(x) for x in samples))
    gain = 0.8 / peak  # every effect peaks at the same level
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(b"".join(struct.pack("<h", int(max(-1, min(1, x * gain)) * 32767)) for x in samples))


def main(out):
    out.mkdir(parents=True, exist_ok=True)
    for name, samples in build(random.Random(SEED)).items():
        write(out / f"{name}.wav", samples)
    print("wrote", len(list(out.glob("*.wav"))), "files to", out)


if __name__ == "__main__":
    main(Path(sys.argv[1]) if len(sys.argv) > 1 else Path("app/assets/audio"))
