"""Align each translation's verse numbers to the English numbering.

The eBible corpus is laid out on the Original (Hebrew) verse list, but its
translations keep their own numbering. In many Psalms the Original numbering
counts the heading as verse 1 or 2, so the same verse sits one or two lines
later than in English. The curated references are English references. For each
chapter this finds the shift s, the language's last verse number minus
English's, so English verse n is found at verse n + s in the language file.

Only shifts of 0, 1 and 2 are accepted. Anything else raises an error so a
person reviews it; nothing is guessed.
"""

MAX_SHIFT = 2


def last_verses(verses):
    """Return {(book, chapter): last verse number that has text}."""
    last = {}
    for (book, chapter, verse) in verses:
        k = (book, chapter)
        if verse > last.get(k, 0):
            last[k] = verse
    return last


def chapter_shifts(lang_verses, english_verses):
    """Return {(book, chapter): shift} for every chapter present in both."""
    en_last = last_verses(english_verses)
    lg_last = last_verses(lang_verses)
    shifts = {}
    for k, e in en_last.items():
        if k in lg_last:
            shifts[k] = lg_last[k] - e
    return shifts


def local_ref(ref, shifts):
    """Map an English (book, chapter, verse) to the language's numbering."""
    book, chapter, verse = ref
    s = shifts.get((book, chapter))
    if s is None:
        raise ValueError(f"no alignment for chapter {book}.{chapter}")
    if s < 0 or s > MAX_SHIFT:
        raise ValueError(f"shift {s} for chapter {book}.{chapter} needs review")
    return (book, chapter, verse + s)
