"""Parse an eBible corpus file into {(book, chapter, verse): text} using the vref list.

A corpus file has exactly one line per vref line. An empty line, or a line that
is only "<range>", means the verse has no text of its own in that translation.
Text is kept exactly as in the file, minus the line ending.
"""
import canon


def parse_vref(vref_text):
    """Return a list of (book_number, usfm_code, chapter, verse) in file order."""
    out = []
    for raw in vref_text.splitlines():
        if not raw.strip():
            continue
        ref, cv = raw.split()
        chapter, verse = cv.split(":")
        if ref not in canon.BY_CODE:
            out.append((None, ref, int(chapter), int(verse)))
        else:
            out.append((canon.BY_CODE[ref][0], ref, int(chapter), int(verse)))
    return out


def parse_corpus(corpus_text, vref):
    """Return {(book, chapter, verse): text} for the 66 canon books only.

    Raises ValueError if the line count does not match the vref list.
    """
    lines = corpus_text.split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    if len(lines) != len(vref):
        raise ValueError(f"corpus has {len(lines)} lines, vref has {len(vref)}")
    verses = {}
    for line, (book, _code, chapter, verse) in zip(lines, vref):
        if book is None:
            continue
        text = line.rstrip("\r")
        if text.strip() == "" or text.strip() == "<range>":
            continue
        verses[(book, chapter, verse)] = text
    return verses


def key(book, chapter, verse):
    return f"{book}.{chapter}.{verse}"


def parse_ref(text):
    """Parse a reference like "PHP 4:13" into (book, chapter, verse)."""
    code, cv = text.split()
    chapter, verse = cv.split(":")
    return canon.BY_CODE[code][0], int(chapter), int(verse)


def parse_scrollmapper(json_text):
    """Parse a scrollmapper bible_databases JSON file into {(book, chapter, verse): text}.

    The file lists the 66 books in canonical order, each with chapters and verses
    that carry explicit numbers. Raises ValueError if the shape is not as expected.
    """
    import json

    data = json.loads(json_text)
    books = data["books"]
    if len(books) != len(canon.BOOKS):
        raise ValueError(f"expected {len(canon.BOOKS)} books, got {len(books)}")
    verses = {}
    for book_index, book in enumerate(books):
        for chapter in book["chapters"]:
            for verse in chapter["verses"]:
                text = verse["text"]
                if text.strip() == "":
                    continue
                verses[(book_index + 1, int(chapter["chapter"]), int(verse["verse"]))] = text
    return verses


def load_language(src, cache_dir, vref):
    """Load one language's verses according to its source format."""
    import pathlib

    path = pathlib.Path(cache_dir) / pathlib.Path(src["path"]).name
    text = path.read_text(encoding="utf-8")
    if src.get("format") == "scrollmapper-json":
        return parse_scrollmapper(text)
    return parse_corpus(text, vref)
