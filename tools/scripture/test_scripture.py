"""Unit tests for the scripture tools. Run: python3 -m unittest discover -s tools/scripture"""
import json
import pathlib
import sys
import unittest

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))

import align  # noqa: E402
import canon  # noqa: E402
import parse  # noqa: E402

HERE = pathlib.Path(__file__).resolve().parent
ROOT = HERE.parent.parent


class CanonTest(unittest.TestCase):
    def test_sixty_six_books_in_order(self):
        self.assertEqual(len(canon.BOOKS), 66)
        self.assertEqual([b[0] for b in canon.BOOKS], list(range(1, 67)))
        self.assertEqual(canon.BOOKS[0][1], "GEN")
        self.assertEqual(canon.BOOKS[65][1], "REV")

    def test_totals_match_chapter_lists(self):
        total = 0
        for num, code, name, chapters, verses in canon.BOOKS:
            self.assertEqual(len(canon.CHAPTER_VERSES[code]), chapters, code)
            self.assertEqual(sum(canon.CHAPTER_VERSES[code]), verses, code)
            total += verses
        self.assertEqual(total, canon.TOTAL_VERSES)

    def test_book_numbers_match_the_dart_canon(self):
        names = {b[2]: b[0] for b in canon.BOOKS}
        self.assertEqual(names["Philippians"], 50)
        self.assertEqual(names["Psalms"], 19)
        self.assertEqual(names["1 Corinthians"], 46)


class ParseTest(unittest.TestCase):
    VREF = "GEN 1:1\nGEN 1:2\nTOB 1:1\nREV 22:21\n"

    def test_parse_vref_marks_non_canon_books(self):
        v = parse.parse_vref(self.VREF)
        self.assertEqual(v[0], (1, "GEN", 1, 1))
        self.assertEqual(v[2][0], None)
        self.assertEqual(v[3], (66, "REV", 22, 21))

    def test_parse_corpus_keeps_text_and_skips_empty_and_range(self):
        v = parse.parse_vref(self.VREF)
        got = parse.parse_corpus("In the beginning\n<range>\nignored\nGrace\n", v)
        self.assertEqual(got, {(1, 1, 1): "In the beginning", (66, 22, 21): "Grace"})

    def test_parse_corpus_rejects_wrong_line_count(self):
        v = parse.parse_vref(self.VREF)
        with self.assertRaises(ValueError):
            parse.parse_corpus("a\nb\n", v)

    def test_parse_ref_and_key(self):
        self.assertEqual(parse.parse_ref("PHP 4:13"), (50, 4, 13))
        self.assertEqual(parse.key(50, 4, 13), "50.4.13")


class AlignTest(unittest.TestCase):
    def test_shift_is_last_verse_difference(self):
        en = {(19, 46, v): "x" for v in range(1, 12)}
        lg = {(19, 46, v): "x" for v in range(2, 13)}
        s = align.chapter_shifts(lg, en)
        self.assertEqual(s[(19, 46)], 1)
        self.assertEqual(align.local_ref((19, 46, 1), s), (19, 46, 2))

    def test_unreviewed_shift_raises(self):
        with self.assertRaises(ValueError):
            align.local_ref((1, 1, 1), {(1, 1): 5})
        with self.assertRaises(ValueError):
            align.local_ref((1, 1, 1), {})


class BundleTest(unittest.TestCase):
    def test_bundle_matches_curated_list(self):
        curated = json.loads((ROOT / "app/assets/verses/curated.json").read_text(encoding="utf-8"))["verses"]
        keys = {f'{v["ref"]["book"]}.{v["ref"]["chapter"]}.{v["ref"]["verse"]}' for v in curated}
        sources = json.loads((HERE / "sources.json").read_text(encoding="utf-8"))["languages"]
        for lang in sources:
            bundle = json.loads((ROOT / f"app/assets/verses/{lang}.json").read_text(encoding="utf-8"))
            self.assertEqual(set(bundle["verses"]), keys, lang)
            self.assertTrue(all(t.strip() for t in bundle["verses"].values()), lang)

    def test_no_curated_verse_is_verse_one_of_a_psalm_unless_checked(self):
        cfg = json.loads((HERE / "curated_refs.json").read_text(encoding="utf-8"))
        ok = {parse.parse_ref(r) for r in cfg.get("psalm_verse1_ok", [])}
        for v in cfg["verses"]:
            b, c, vs = parse.parse_ref(v["ref"])
            if b == 19 and vs == 1:
                self.assertIn((b, c, vs), ok, v["id"])


if __name__ == "__main__":
    unittest.main()
