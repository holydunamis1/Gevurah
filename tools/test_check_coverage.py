import tempfile
import unittest
from pathlib import Path

import check_coverage


class Coverage(unittest.TestCase):
    def test_parse_and_gate(self):
        lcov = "SF:lib/core/a.dart\nLF:10\nLH:9\nend_of_record\nSF:lib/providers/b.dart\nLF:10\nLH:5\nend_of_record\n"
        files = check_coverage.parse(lcov)
        self.assertEqual(files["lib/core/a.dart"], [10, 9])

    def test_unimported_file_counts_as_uncovered(self):
        with tempfile.TemporaryDirectory() as d:
            app = Path(d) / "app"
            (app / "coverage").mkdir(parents=True)
            (app / "lib" / "core").mkdir(parents=True)
            (app / "coverage" / "lcov.info").write_text("SF:lib/core/a.dart\nLF:10\nLH:10\nend_of_record\n")
            (app / "lib" / "core" / "a.dart").write_text("x\n" * 10)
            (app / "lib" / "core" / "b.dart").write_text("final a = 1;\nfinal b = 2;\n// c\n")
            result, _ = check_coverage.measure(app)
            pct, lf, lh = result["core"]
            self.assertEqual((lf, lh), (12, 10))


if __name__ == "__main__":
    unittest.main()
