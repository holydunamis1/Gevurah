import hashlib
import tempfile
import unittest
import wave
from pathlib import Path

import make_sfx

EXPECTED = {"tell", "tell_heavy", "tell_flurry", "hit", "perfect", "guard", "slip", "down", "defeat", "count"}


def digest(folder):
    return {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in sorted(Path(folder).glob("*.wav"))}


class MakeSfx(unittest.TestCase):
    def test_same_bytes_every_run_and_every_sound_present(self):
        with tempfile.TemporaryDirectory() as a, tempfile.TemporaryDirectory() as b:
            make_sfx.main(Path(a))
            make_sfx.main(Path(b))
            self.assertEqual(digest(a), digest(b))
            self.assertEqual({n[:-4] for n in digest(a)}, EXPECTED)

    def test_files_are_short_mono_16_bit(self):
        with tempfile.TemporaryDirectory() as a:
            make_sfx.main(Path(a))
            for p in Path(a).glob("*.wav"):
                with wave.open(str(p)) as w:
                    self.assertEqual((w.getnchannels(), w.getsampwidth()), (1, 2))
                    self.assertLess(w.getnframes() / w.getframerate(), 1.0, p.name)

    def test_committed_files_match_the_script(self):
        repo = Path(__file__).resolve().parents[2]
        with tempfile.TemporaryDirectory() as a:
            make_sfx.main(Path(a))
            self.assertEqual(digest(a), digest(repo / "app" / "assets" / "audio"))


if __name__ == "__main__":
    unittest.main()
