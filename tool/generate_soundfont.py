"""Generates the small built-in soundfont used on iOS.

iOS has no system General MIDI sounds, so the plugin bundles this file and
loads it when loadSoundfont('') is called. Every sound here is synthesized
by this script, so the file has no third-party licence.

Run from the repo root:
    python tool/generate_soundfont.py
Writes ios/Resources/flutter_midi_engine_basic.sf2
"""

import math
import os
import struct

SAMPLE_RATE = 32000
LOOP_LEN = 3200  # 0.1 s. Each sample frequency is a multiple of 10 Hz so the loop is seamless.
LOOP_REPEATS = 2  # sample = 1 loop of attack + this many loops
OUT = os.path.join(os.path.dirname(__file__), "..", "ios", "Resources", "flutter_midi_engine_basic.sf2")

# (low key, high key, root key) for each zone
ZONES = [(0, 59, 48), (60, 83, 72), (84, 127, 96)]


def timecents(seconds):
    return int(round(1200 * math.log2(seconds)))


def saw(n):
    return [1.0 / h for h in range(1, n + 1)]


def square(n):
    return [1.0 / h if h % 2 else 0.0 for h in range(1, n + 1)]


# name, GM program, harmonic amplitudes, envelope (attack, decay, sustain cB, release),
# attenuation cB, vibrato (cents) or 0
INSTRUMENTS = [
    ("Piano", 0, [1, .5, .3, .2, .12, .08, .05, .03], (0.002, 3.0, 1000, 0.4), 0, 0),
    ("Electric Piano", 4, [1, .25, .1, .05], (0.002, 2.5, 1000, 0.5), 0, 0),
    ("Church Organ", 19, [1, .7, .5, 0, .4, 0, 0, .3], (0.01, 0.01, 0, 0.15), 30, 0),
    ("Acoustic Guitar", 24, [1, .6, .4, .3, .2, .15, .1, .07, .05], (0.002, 1.5, 1000, 0.2), 0, 0),
    ("Electric Guitar", 27, [1, .8, .5, .4, .3, .25, .2, .1], (0.002, 4.0, 1000, 0.3), 0, 0),
    ("Violin", 40, saw(16), (0.08, 0.01, 0, 0.3), 40, 15),
    ("Trumpet", 56, [1, .9, .8, .6, .5, .4, .3, .2, .15, .1], (0.03, 0.01, 0, 0.1), 40, 0),
    ("Flute", 73, [1, .12, .05], (0.06, 0.01, 0, 0.15), 0, 8),
    ("Synth Lead", 80, square(21), (0.005, 0.01, 0, 0.1), 60, 0),
]

# SF2 generator ids
G_VIB_LFO_TO_PITCH = 6
G_DELAY_VIB_LFO = 23
G_FREQ_VIB_LFO = 24
G_ATTACK = 34
G_HOLD = 35
G_DECAY = 36
G_SUSTAIN = 37
G_RELEASE = 38
G_INSTRUMENT = 41
G_KEY_RANGE = 43
G_ATTENUATION = 48
G_SAMPLE_ID = 53
G_SAMPLE_MODES = 54


def make_sample(harmonics, root_key):
    """Returns (pcm, original_pitch, pitch_correction_cents)."""
    target = 440.0 * 2 ** ((root_key - 69) / 12)
    cycles = round(target * LOOP_LEN / SAMPLE_RATE)
    freq = cycles * SAMPLE_RATE / LOOP_LEN
    correction = int(round(1200 * math.log2(target / freq)))

    # drop harmonics above ~10 kHz to avoid aliasing
    partials = [(h, a) for h, a in enumerate(harmonics, 1) if a and h * freq < 10000]

    length = LOOP_LEN * (1 + LOOP_REPEATS) + 32  # spec wants spare points after the loop end
    raw = []
    for i in range(length):
        t = i / SAMPLE_RATE
        raw.append(sum(a * math.sin(2 * math.pi * h * freq * t) for h, a in partials))
    peak = max(abs(v) for v in raw) or 1.0
    pcm = [int(v / peak * 0.8 * 32767) for v in raw]
    return pcm, root_key, correction


def name20(s):
    return s.encode("ascii")[:19].ljust(20, b"\0")


def chunk(cid, data):
    if len(data) % 2:
        data += b"\0"
    return cid + struct.pack("<I", len(data)) + data


def list_chunk(kind, *chunks):
    body = kind + b"".join(chunks)
    return b"LIST" + struct.pack("<I", len(body)) + body


def gen(oper, amount):
    return struct.pack("<Hh", oper, amount)


def gen_range(lo, hi):
    return struct.pack("<HBB", G_KEY_RANGE, lo, hi)


def build():
    smpl = bytearray()
    shdr = bytearray()
    inst = bytearray()
    ibag = bytearray()
    igen = bytearray()
    phdr = bytearray()
    pbag = bytearray()
    pgen = bytearray()
    sample_id = 0
    igen_count = 0
    ibag_count = 0
    pgen_count = 0

    for inst_id, (name, program, harmonics, env, atten, vibrato) in enumerate(INSTRUMENTS):
        attack, decay, sustain, release = env
        inst += name20(name) + struct.pack("<H", ibag_count)

        for lo, hi, root in ZONES:
            pcm, pitch, corr = make_sample(harmonics, root)
            start = len(smpl) // 2
            smpl += struct.pack("<%dh" % len(pcm), *pcm)
            smpl += b"\0" * 92  # 46 zero samples after each sample (SF2 spec)
            end = start + len(pcm)
            loop_end = start + LOOP_LEN * (1 + LOOP_REPEATS)
            shdr += name20("%s %d" % (name[:14], root)) + struct.pack(
                "<IIIIIBbHH", start, end, start + LOOP_LEN, loop_end, SAMPLE_RATE, pitch, corr, 0, 1)

            zone = [gen_range(lo, hi),
                    gen(G_ATTACK, timecents(attack)),
                    gen(G_DECAY, timecents(decay)),
                    gen(G_SUSTAIN, sustain),
                    gen(G_RELEASE, timecents(release)),
                    gen(G_ATTENUATION, atten)]
            if vibrato:
                zone += [gen(G_FREQ_VIB_LFO, int(round(1200 * math.log2(5.5 / 8.176)))),
                         gen(G_DELAY_VIB_LFO, timecents(0.3)),
                         gen(G_VIB_LFO_TO_PITCH, vibrato)]
            zone += [gen(G_SAMPLE_MODES, 1), gen(G_SAMPLE_ID, sample_id)]

            ibag += struct.pack("<HH", igen_count, 0)
            ibag_count += 1
            igen += b"".join(zone)
            igen_count += len(zone)
            sample_id += 1

        phdr += name20(name) + struct.pack("<HHHIII", program, 0, inst_id, 0, 0, 0)
        pbag += struct.pack("<HH", pgen_count, 0)
        pgen += gen(G_INSTRUMENT, inst_id)
        pgen_count += 1

    # terminal records
    phdr += name20("EOP") + struct.pack("<HHHIII", 0, 0, len(INSTRUMENTS), 0, 0, 0)
    pbag += struct.pack("<HH", pgen_count, 0)
    pgen += gen(0, 0)
    inst += name20("EOI") + struct.pack("<H", ibag_count)
    ibag += struct.pack("<HH", igen_count, 0)
    igen += gen(0, 0)
    shdr += name20("EOS") + b"\0" * 26
    empty_mod = b"\0" * 10

    info = list_chunk(b"INFO",
                      chunk(b"ifil", struct.pack("<HH", 2, 1)),
                      chunk(b"isng", b"EMU8000\0"),
                      chunk(b"INAM", b"flutter_midi_engine basic\0"),
                      chunk(b"ICOP", b"MIT License, generated by tool/generate_soundfont.py\0"))
    sdta = list_chunk(b"sdta", chunk(b"smpl", bytes(smpl)))
    pdta = list_chunk(b"pdta",
                      chunk(b"phdr", bytes(phdr)), chunk(b"pbag", bytes(pbag)),
                      chunk(b"pmod", empty_mod), chunk(b"pgen", bytes(pgen)),
                      chunk(b"inst", bytes(inst)), chunk(b"ibag", bytes(ibag)),
                      chunk(b"imod", empty_mod), chunk(b"igen", bytes(igen)),
                      chunk(b"shdr", bytes(shdr)))
    body = b"sfbk" + info + sdta + pdta
    return b"RIFF" + struct.pack("<I", len(body)) + body


if __name__ == "__main__":
    data = build()
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "wb") as f:
        f.write(data)
    print("Wrote %s (%d KB)" % (os.path.normpath(OUT), len(data) // 1024))
