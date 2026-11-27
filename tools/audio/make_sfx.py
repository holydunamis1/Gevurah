#!/usr/bin/env python3
"""Synthesizes the game's sound effects. Original sounds, no licensing, and a
fixed seed so the same script always writes the same bytes.

Usage: make_sfx.py [output_dir]   (default app/assets/audio)
The fight music is a synthesized loop made here too.
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


def voice(freq, ms, vol=0.5, decay=5.0, harm=(1.0, 0.5, 0.25), end_freq=None):
    """A tone with overtones: carries on a phone speaker, unlike a bare sine."""
    n = int(RATE * ms / 1000)
    out, phase = [], 0.0
    for i in range(n):
        t = i / n
        f = freq + ((end_freq - freq) * t if end_freq else 0)
        phase += 2 * math.pi * f / RATE
        env = math.exp(-decay * t) * min(1.0, i / (RATE * 0.003))
        out.append(vol * env * sum(h * math.sin(phase * (k + 1)) for k, h in enumerate(harm)) / sum(harm))
    return out


def build(rng):
    s = {}
    s["tell"] = mix(voice(880, 170, 0.5, 5), delay(voice(1175, 150, 0.5, 6), 70))
    s["tell_heavy"] = mix(voice(220, 340, 0.7, 3, end_freq=150), voice(110, 340, 0.5, 3), noise(340, rng, 0.12, 4, 0.8))
    s["tell_flurry"] = mix(*(delay(voice(1000 + 80 * k, 70, 0.5, 8), 75 * k) for k in range(3)))
    s["hit"] = mix(voice(320, 170, 0.9, 8, end_freq=110), noise(140, rng, 0.7, 10, 0.3), voice(1500, 60, 0.4, 20))
    s["perfect"] = mix(voice(1047, 120, 0.5, 5), delay(voice(1319, 120, 0.5, 5), 90), delay(voice(1568, 260, 0.55, 4), 180))
    s["guard"] = mix(voice(700, 130, 0.7, 11, end_freq=520), voice(1400, 90, 0.4, 14), noise(40, rng, 0.4, 14, 0.1))
    s["slip"] = [x * math.sin(math.pi * i / 4400) for i, x in enumerate(noise(200, rng, 0.9, 0.3, 0.7))]
    s["down"] = mix(voice(300, 420, 0.7, 3, end_freq=120), noise(120, rng, 0.5, 9, 0.5))
    s["defeat"] = mix(*(delay(voice(f, 300, 0.5, 3.5), 90 * k) for k, f in enumerate((523, 659, 784, 988, 1175))))
    s["count"] = mix(voice(700, 80, 0.7, 12), noise(18, rng, 0.2, 14, 0.3))
    s["bell"] = mix(voice(1200, 700, 0.6, 3.5, harm=(1.0, 0.7, 0.5)), voice(1800, 500, 0.3, 5))
    s["win"] = mix(*(delay(voice(f, 260 if k < 3 else 700, 0.55, 3.0 if k < 3 else 2.0), 130 * k) for k, f in enumerate((523, 659, 784, 1047))))
    s["lose"] = mix(*(delay(voice(f, 380, 0.5, 3.0), 200 * k) for k, f in enumerate((440, 392, 349, 262))))
    s["music"] = music()
    return s


def music():
    """A bright, bouncy 8-bar loop in C major: melody, bass and a light beat."""
    bpm = 132
    beat = 60.0 / bpm
    bars = 8
    total = int(RATE * beat * 4 * bars)
    out = [0.0] * total
    freqs = {"C": 261.63, "D": 293.66, "E": 329.63, "F": 349.23, "G": 392.0, "A": 440.0, "B": 493.88}

    def put(start_beat, samples):
        o = int(RATE * beat * start_beat)
        for i, x in enumerate(samples):
            if o + i < total:
                out[o + i] += x

    def hz(name):
        return freqs[name[0]] * (2 if name.endswith("^") else 1)

    melody = [
        "E G A G", "E G C^ G", "A A G E", "D E D .",
        "E G A G", "E G C^ G", "A G E D", "C . C .",
    ]
    bass = ["C", "C", "F", "G", "C", "C", "F", "G"]
    for bar in range(bars):
        for k, note in enumerate(melody[bar].split()):
            if note != ".":
                put(bar * 4 + k, voice(hz(note), beat * 900, 0.32, 3.0, harm=(1.0, 0.0, 0.33, 0.0, 0.2)))
        root = freqs[bass[bar]] / 2
        for k in range(4):
            put(bar * 4 + k, voice(root if k % 2 == 0 else root * 1.5, beat * 800, 0.30, 4.0, harm=(1.0, 0.4)))
            kick = voice(140, 110, 0.5, 9, end_freq=60) if k % 2 == 0 else noise(70, random.Random(bar * 4 + k), 0.18, 14, 0.2)
            put(bar * 4 + k, kick)
    return out


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
