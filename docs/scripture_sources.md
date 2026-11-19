# Scripture sources

Every bundled verse is extracted by script from a pinned source file and checked against it byte for byte. Nothing is retyped. This file is the audit trail; `tools/scripture/` holds the scripts.

## Source

All nine languages come from the eBible.org corpus as published in the GitHub repository `BibleNLP/ebible`, pinned to commit `2bde52b4c2cfd7056cf4ed07c48969647df79744`. Each file has one verse per line, in the order of `metadata/vref.txt`. Licences below are from that repository's `metadata/licences.tsv` and each translation's `copr.htm` at the same commit.

| Language | Translation (eBible id) | Licence | Source file sha256 |
| --- | --- | --- | --- |
| English | Berean Standard Bible (`engbsb`) | Public Domain | `27feb880…bde7bca9545` |
| Spanish | Santa Biblia, Reina Valera 1909 (`spaRV1909`) | Public Domain | `2c4f2515…fb2e1` |
| French | Louis Segond 1910 (`fraLSG`) | Public Domain | `238a9d14…4af271` |
| German | Luther Bibel 1912 (`deu1912`) | Public Domain | `c3304d76…0bd2` |
| Portuguese (Brazil) | Bíblia Livre (`porbr2018`) | CC BY 3.0 BR, attribution required | `a9a1449b…62fd` |
| Arabic | Smith and Van Dyck (`arb_vd`) | Public Domain | `e2086900…3ca8` |
| Hindi | Indian Revised Version (`hin2017`) | CC BY-SA 4.0, attribution and share-alike | `981c71c6…d09d` |
| Simplified Chinese | Chinese Union Version, simplified (`cmn_cu89s`) | Public Domain | `277840ae…5608` |
| Hebrew | Modern Hebrew Bible (`heb`) | Public Domain | `a55cd973…f9bf` |

The full checksums are in `tools/scripture/sources.json`; `fetch_sources.py` refuses any file that differs.

## Not yet sourced

| Language | State |
| --- | --- |
| Japanese | The eBible corpus has only Shinkaiyaku 1965, New Testament only, not the Kougo-yaku named in the blueprint. A full source with a clear licence is still being looked for. |
| Korean | No source found yet. |

Until a source is added and checked, these two languages are not shipped, and no stand-in text is used.

## Notes that matter

- **Verse numbering.** The corpus keeps each translation's own numbering. In Arabic, Chinese and French many Psalms count the heading as verse 1 or 2, so English verse n sits at n + 1 or n + 2. `tools/scripture/align.py` finds the shift per chapter from the last verse number and `build_curated.py` records the chapters it applied it to in `tools/scripture/alignment.json`. A shift outside 0 to 2 stops the build.
- **Psalm headings.** Spanish, German and Hebrew put the heading inside verse 1 of titled Psalms. The curated list therefore never uses verse 1 of a Psalm unless it was checked (only Psalm 107:1).
- **Hindi share-alike.** The Hindi text is CC BY-SA 4.0. The licence screen shows the attribution line and that verses are unchanged. Anyone reusing the Hindi verse file must keep the same licence.
- **Portuguese licence.** The blueprint listed CC BY 4.0; the source's own notice says CC BY 3.0 Brasil, so the notice follows the source.
- **Hebrew provenance.** eBible labels the file "Modern Hebrew Bible", Public Domain. This is a different file from the Westminster Leningrad Codex and Modern Hebrew Bible pair in the blueprint; it carries a single notice. It is recorded as eBible's statement, not independently confirmed.
- **Missing copyright pages.** eBible has no `copr.htm` for `engbsb`, `arb_vd` or `cmn_cu89s` at this commit; their licence is taken from `licences.tsv` only.
- **Corrections.** None. `tools/scripture/corrections.json` is empty, so every bundled verse equals its source text.

## Rebuilding

```
python3 tools/scripture/fetch_sources.py        # download and check the sources
python3 tools/scripture/build_curated.py        # write app/assets/verses and app/assets/licenses
python3 tools/scripture/verify_curated.py       # the data gate, also run by check.yml
python3 tools/scripture/verse_maps.py           # per-language list of verses with no text
```
