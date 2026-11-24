import tempfile
import unittest
from pathlib import Path

import check_strings


class CheckStrings(unittest.TestCase):
    def run_on(self, source):
        with tempfile.TemporaryDirectory() as d:
            f = Path(d) / "x.dart"
            f.write_text(source, encoding="utf-8")
            return list(check_strings.violations(f))

    def test_flags_text_literal(self):
        self.assertTrue(self.run_on("child: Text('Hello there'),"))

    def test_flags_label_literal(self):
        self.assertTrue(self.run_on("AppRow(label: \"Settings\"),"))

    def test_allows_localized_and_interpolated(self):
        self.assertFalse(self.run_on("Text(l.title), semanticLabel: '$name. ${l.x}. $detail',"))

    def test_allows_marked(self):
        self.assertFalse(self.run_on("Text('Hello') // allow-literal"))


if __name__ == "__main__":
    unittest.main()
