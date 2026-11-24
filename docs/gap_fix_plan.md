# Gap fix sequence (drafted 2026-11-24, after the audit of main at afe4d41)

Holy's rulings on the audit: items 2 and 3 are needed; item 6 waits until the full app is built and every intersection exists; item 8 is approved as built; the rest are fixed as drafted below. Each batch follows the usual delivery: write files and tests, push to `ci-analyser`, fix until green, record the decision and build-log row, promote to `main`.

## Order and why

All new player-facing text lands before p6b, so the ten translations are written once.

| Order | Batch | Fixes | Needs from Holy |
| --- | --- | --- | --- |
| 1 | p6a-2 Runtime hardening | 4, 5, 7, smoke-test bout, 11, record 8 | nothing |
| 2 | p6a-3 Repo hygiene | 10, 9, 12 | nothing; the website is already live |
| 3 | p6a-4 Sound pulled forward | 13 | nothing |
| 4 | p6a-5 How to play and guided Training | 1 | approve the lesson list |
| | **Test APK 1** | first real feel test, with sound and instructions | build it, report timing feel |
| 5 | p6a-6 Rewarded ads | 2 | confirm the four rewards below |
| 6 | p6a-7 Rating prompt | 3 | App Store ID before iOS release |
| 7 | p6b, p6c | translations, integration tests | as planned |
| 8 | p6d Ad map | 6 | after p6c, when every screen and flow exists |
| 9 | after Test APK 1 | 14 calibration, only if needed | feel report |

Reason for the order: runtime fixes and hygiene change no strings and unblock everything. Sound goes before the feel test because a rhythm game cannot be judged silent. How to play goes before the test because a tester who does not know the controls produces useless timing data. Rewarded ads and rating come after the feel test so tuning feedback does not collide with new ad and prompt flows.

## p6a-2 Runtime hardening (items 4, 5, 7, 11, 8)

Item 4, fatal error fallback.
- Install `GlobalErrorHandler` in `buildRuntime` with one sink and delete `installErrorLogging`. The sink logs every error through the log service. Errors with `fatal: true` set a `FatalErrorHost` notifier.
- `GevurahApp` listens to the notifier and shows `ErrorScreen` above the Navigator. Retry clears the flag and returns to Home; Report opens the support email with the exported log, as the taxonomy says.
- Ad, billing, consent and storage failures stay degraded and never raise the fallback (taxonomy rows 2 and 3).
- Tests: a thrown error in a callback shows the screen; Retry returns Home; a failed ad load does not.

Item 5, cold-start notification tap.
- After start-up, `GevurahApp` calls `launchedFromNotification()` once; when true it opens Daily Bout over Home, so Back lands on Home (the manifest's "cold-start back stack").
- Tests with a fake notification port: cold start with the flag, warm tap, no tap.

Item 7, motion.
- Push 350 ms ease-in-out, fade plus 20 px slide (mirrored in right-to-left); pop 280 ms; Reduce Motion 0 ms with an instant opacity change. Check that the bottom sheet is 400 ms ease-out and fix it if not. Durations live in `theme/tokens.dart` as named values.
- Tests: durations, direction in both text directions, Reduce Motion.

Also in this batch: the smoke test plays one bout headless through the app (Home, Continue, Start, scripted taps, result), as the p6a manifest row requires. Decision 049 records item 8 (banners stay on every menu and result screen, never on fight, corner, ten-count, onboarding, upgrade, licenses or error) and the item 6 deferral. A row for the boot receivers (item 11) is added to the log.

## p6a-3 Repo hygiene (items 10, 9, 12)

Item 10, `pubspec.lock`. Holy has no toolchain, so a runner does it: extend `resolve_deps` to run `flutter pub get` and commit the generated `app/pubspec.lock` to `ci-analyser`; `check.yml` then fails if the lock is missing or out of step with `pubspec.yaml`. This also pins `in_app_review` for p6a-7 (resolve it in the same run).

Item 9, coverage gates. Add `tools/check_coverage.py` that reads `coverage/lcov.info` and fails below core 90, providers 80, overall 75. First run reports only; the batch measures, then sets the gate at the real number if it is below target and records the shortfall with a test-writing task, so a gate never blocks `main` on day one without a plan.

Item 12, URLs. The website is live at https://gevurah.holydunamis1.workers.dev (privacy and support pages). The app's Privacy policy and Contact support rows open those pages (`AppConfig.privacyUrl`, `supportUrl`); nothing is hidden. The support email appears only on the support page; the privacy page links to it. A release gate in the p7b workflow fails a release build if the website URL is empty. The flags URL stays empty until a flags file is published.

## p6a-4 Sound pulled forward (item 13)

Pull the synthesis part of p7a forward: `tools/audio/make_sfx.py` (fixed seed, original sounds) and `assets/audio/*.wav` for tells (one per move kind), hit, perfect, guard, slip, ten-count, defeat, tap. The menu loop stays in p7a. Wire events in `audio_service` to the fight controller and the Settings Sound toggle, add the asset folder to `pubspec.yaml`, test that every event has a file and that mute silences all. Keep the total under about 1 MB. Haptic cues are verified on the device in Test APK 1.

## p6a-5 How to play and guided Training (item 1)

New files: `screens/how_to_play_screen.dart`, `core/catalog/training_lessons.dart`, `providers/training_provider.dart`, tests, ARB strings.

- How to play screen, three cards drawn with the existing tell silhouettes and icons: Watch the tell; Answer on the beat (Guard is a tap, Slip is a sideways swipe, Take it means do nothing); Strike when the opening shows (tap; two taps on the beat is a Combo). A fourth card covers Breath, Stamina and the pause button.
- Reached three ways: once after onboarding's Play (skippable), from Settings (a row), and from the opponent card of the first career bout. It carries a banner and no ad inside a bout.
- Training becomes guided. Six short lessons, no stars, no progress change, no ads: 1 Guard (flurries), 2 Slip (heavy swings), 3 Strike after a good response, 4 Combo, 5 Breath and Stamina, 6 Read a fake. Each lesson is a fixed seeded mini-bout against a gentle struggle with a one-line goal shown above the ring, a success tick when the goal is met, and Repeat or Next. Free practice (today's picker) stays as "Practice".
- All lesson text is ARB; no scripture appears in a lesson except in its pauses.
- Tests: each lesson can be completed by a scripted bot and fails by one that does nothing; nothing in Progress changes; every screen in light, dark, right-to-left and large text.

Holy approves the six lessons before the batch starts.

## Test APK 1

Built after p6a-5. I tell Holy when it is ready; Holy starts the workflow. Feedback to report: timing windows, tell clarity, haptics, sound, rotation to landscape, reminder, banner and consent. Item 14 (calibration) is decided from that feedback: if wanted, a Settings "Calibrate timing" tap-along stores a median offset in milliseconds that the controller subtracts from touch timestamps before the core sees them, so determinism is unchanged.

## p6a-6 Rewarded ads (item 2)

Plumbing exists (`ad_service`, `ad_provider.rewardedAllowed` and `rewardedReady`). New: a small `RewardOffer` widget (button with an "Ad" label, hidden when `rewardedReady` is false, never shown while ads are loading), a `rewards` core model and the four rewards.

| Reward | Where | What it does |
| --- | --- | --- |
| Extra Breath | Opponent card, before a bout | +1 Breath charge, stored in `FightConfig` so the bout replays exactly. Not offered for the Daily Bout, which must be identical for everyone |
| Restore a missed Daily day | Daily Bout screen | Fills one missed day in the history when exactly one day was missed; at most one restore per seven days |
| One retry after a loss | Result screen, loss only | Restarts the same struggle with the same cards and a fresh seed; once per bout. Holy's call, marked needed |
| Extra Stamina in Endurance | Endurance opponent card | Starts the run with the Stamina cap raised by 20; value is a starting number for tuning |

Rules for all four: opt-in only, never required for any unlock, still offered after Remove Ads (that purchase removes banner and interstitial only), gated by consent and the remote flag, never on the fight, corner or ten-count screens, reward granted only when the player earns it, a failed or closed ad grants nothing and shows a feedback line. Tests with the fake ads port cover earned, dismissed, failed, not-ready, consent-denied and each reward's effect, including that nothing changes the Daily seed. The privacy page and data answers already cover AdMob and need no change.

## p6a-7 Rating prompt (item 3)

New capability row in section 3 (Rating prompt: `review_port` in core, `review_service` on the store's own review API, settings row; permission none; compliance: native prompt only, no incentive, no data collected).
- Package: `in_app_review`, pinned from the resolve in p6a-3.
- `core/logic/rating_policy.dart` (pure): ask only after a win worth at least two stars, never in the first session, never after a loss, never in the same pause as an interstitial (the prompt wins and the interstitial is skipped that time), at least 3 days after install and 5 won bouts, at most three asks and at least 90 days apart. State (ask dates, count) is saved in settings; unknown keys default, so no migration is needed.
- Settings gets a "Rate the game" row that opens the store listing directly (it never depends on the system prompt appearing).
- iOS needs the App Store ID; it is added to `AppConfig` when Holy has it, and the row is hidden on iOS until then.
- Tests: every policy rule, the pure policy over a calendar of cases, the interstitial interaction.

## p6d Ad map (item 6, deferred by Holy)

After p6c, when the whole app and every flow exist, map every ad moment on one page: where an interstitial may fire (result Continue, return to the Journey map after a tier is cleared), the first-session exclusion that decision 010 locks, the 10-minute gap, the rewarded offers and the rating prompt, with a test for each cell. Until then the code only waits 10 minutes from app start, so an interstitial can appear late in a first session; Test APKs use Google test ads, so this is harmless in testing and is closed before any release.

## Blueprint and log updates

Alongside the batches: update the blueprint's manifest to match what was built (`gevurah_app.dart` and `bootstrap.dart` in place of `app.dart` and `router.dart`, `check_strings.py`, the added files, the new screens and tools above, the rating capability row and the rewarded buttons), and add the decisions 049 onward to `docs/decision.md` with each batch.

## Questions for Holy (defaults used if no answer)

1. Rewards: keep all four as drafted, including the retry after a loss? Default: yes.
2. Extra Stamina: +20 starting cap in Endurance acceptable? Default: yes, tuned later.
3. Pull sound synthesis forward before Test APK 1? Default: yes.
4. Six training lessons as listed? Default: yes.
5. Rating ask rules (3 days, 5 wins, two stars, 90 days apart, three asks)? Default: yes.
