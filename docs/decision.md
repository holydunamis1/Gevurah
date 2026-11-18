# Decision log and build sequence

This file is the shared memory for every chat and every agent that works on Gevurah Boxing. The master blueprint lives in the claude.ai Project files ("Bible Boxing Game — Master Blueprint.md"); this file holds what was decided and built after it. Read the blueprint, then this file, before touching anything. Add a row to the Build log and, when a plan changes, a new numbered decision here before building.

## Decisions

| # | Decision | Status | Recorded |
| --- | --- | --- | --- |
| 001 | Product: Gevurah Boxing, store title "Gevurah Boxing: Faith Fight Game". App ID `com.zdmgold.gevurah`. Support email stmakarios@gmail.com. Signing alias `Gevurah` (proposed, to confirm). Audience 13 and over | Locked (alias proposed) | 2026-11-18 |
| 002 | Fight style: rhythm and timing exchanges (telegraph, response window, opening). Opponents are life struggles shown as abstract shadow forms, never a person, group, demon or nation. 16 career struggles in four tiers plus 10 extras as a second track. Grief is not an opponent | Locked | 2026-11-18 |
| 003 | Final bout is "Still Standing" (Ephesians 6:13); the final opponent is "Giving Up" | Locked | 2026-11-18 |
| 004 | Verse cards are equipped gameplay modifiers; verses appear only in pauses (opponent card, corner, ten-count, result, card picker, daily bout), never over live action | Locked | 2026-11-18 |
| 005 | A knockdown defeats the struggle; the player only staggers. Stylised, bloodless. God, Jesus and angels are never depicted | Locked | 2026-11-18 |
| 006 | The support screen is left out of the build (no screen, no phone line, no help-line list). The website support page carries the support email | Locked | 2026-11-18 |
| 007 | Engine and layering: Flutter with Flame, Dart. `lib/core` is pure Dart with no plugin or `dart:io` imports; `platform` implements ports declared in core; providers are ValueNotifier; screens use the shared components. No Material or Cupertino chrome (WidgetsApp) | Locked | 2026-11-18 |
| 008 | Determinism: a bout outcome is a pure function of beat offset, move, equipped cards and a seed. The core never sees frame time | Locked | 2026-11-18 |
| 009 | Scripture: curated verses are bundled and extracted by script, never retyped; byte-for-byte verification against source files. Languages and translations are the template's list recorded in the blueprint. Full-Bible reader is a later update after store approval, behind the verse-source interface | Locked | 2026-11-18 |
| 010 | Ads and money: AdMob with UMP consent gating every request; one-time Remove Ads purchase; banner on menu screens, interstitial at natural breaks with a 10-minute gap and no cap, never in the first session; opt-in rewarded ads. Google test IDs until production IDs are supplied | Locked | 2026-11-18 |
| 011 | Fonts: Inter for headers and interface chrome, Source Sans 3 for scripture and body text; other scripts use system fonts | Locked | 2026-11-18 |
| 012 | CI/CD: `check.yml` on every push; build, emulator and bootstrap workflows are manual only. Each batch goes to `ci-analyser`, is fixed until green, then pushed to `main`. Signing secrets are set at the release batch and never written into the repository or this file | Locked | 2026-11-18 |
| 013 | Flutter pinned to 3.50.0 (stable, Dart 3.14.0, engine revision 371f77202a, released 2026-11-09), read from the first bootstrap run and set in `check.yml` and `bootstrap_platform.yml`. Every later workflow uses the same pin. Changing it needs a new decision row | Locked | 2026-11-18 |
| 014 | Decision log file name is `docs/decision.md` (singular), as in the blueprint | Locked | 2026-11-18 |
| 015 | Android manifest declares only permissions traced to the capability matrix: INTERNET, ACCESS_NETWORK_STATE, AD_ID, POST_NOTIFICATIONS, VIBRATE. Boot receivers for rescheduling the daily reminder are added in batch p2d with the notification service, with their own decision row | Locked | 2026-11-18 |
| 016 | AdMob uses Google's published sample app IDs (Android `ca-app-pub-3940256099942544~3347511713`, iOS `ca-app-pub-3940256099942544~1458002511`) until Ak supplies production IDs | Locked | 2026-11-18 |

## Build log

Newest row first. One row per batch or notable turn.

| Date | Batch | What landed | Paths | Check result |
| --- | --- | --- | --- | --- |
| 2026-11-18 | p1b | Android and iOS project folders from Flutter 3.50.0 (`com.zdmgold.gevurah`); manifest permissions and sample AdMob IDs; release signing reads `key.properties` when present; iOS display name, ad and tracking keys, privacy manifest added to the Runner target | `app/android/**`, `app/ios/**` | Pending |
| 2026-11-18 | p1a | Repo files, decision log, light check workflow, bootstrap workflow | `.gitignore`, `README.md`, `docs/decision.md`, `.github/workflows/check.yml`, `.github/workflows/bootstrap_platform.yml` | Green on `ci-analyser` and `main` |

## Open items

- Confirm signing alias `Gevurah`.
- iOS `SKAdNetworkItems` holds only Google's own identifier (`cstr6suwn9.skadnetwork`). The full list Google recommends could not be fetched from this environment; paste it from AdMob's "SKAdNetwork" documentation or confirm it before the iOS release batch p7b.
- Re-verify `PrivacyInfo.xcprivacy` (tracking flag, collected data types, required-reason codes) against the actual plugin set once pubspec dependencies are resolved in p1d, and again at p7b.
- Orientation is left at the Flutter default (portrait and landscape); decide on portrait-only before p5a.
- Supply AdMob production IDs, the Apple team ID and the App Store Connect key when the release batches are reached.
