# Play-first redesign plan (decision 058)

Holy's verdict after playing Test APK 7: the game feels like an exam app. It must open straight onto the play field, be instantly playable by anyone including a two-year-old, look and sound like a normal game, and have no hurdles before play. The characters were unclear and ugly.

## Decisions (answered 2026-11-26)
1. Controls: one tap. The opponent winds up with a big flash and sound; tap when it lands to block, and the counter fires by itself. Slip, Combo, Breath, the timing lessons and the Stamina meter leave the player's view.
2. Flow: the icon opens straight into a fight against the next opponent. No onboarding, no How to play, no lessons, no settings before play. Menus sit behind one small icon and after a bout.
3. Art: a friendly cartoon boxer for the player and a distinct, bright, bloodless character per struggle. This replaces the blueprint rule that struggles are only abstract shadows and the player is never a person. God, Jesus and angels are still never depicted.

## Paused until the redesign lands
p6a-7 rating prompt, p6b translations, p6c integration tests, p6d ad map. Every string and screen changes, so translating or testing now would be done twice. p7a to p7c stay in the plan after them.

## Batches
- R1 Play-first shell: cold start goes to the fight; remove onboarding, How to play and the lesson path; auto-pick the next opponent; a one-line on-screen cue instead of instructions. Find out why no sound played on the phone and fix it.
- R2 One-tap fight: simplify the rules and the UI to tap-to-block with an automatic counter, a very forgiving window, two simple health bars, no Stamina. Keep determinism and the Daily Bout.
- R3 Art: the cartoon boxer and 16 distinct opponent characters drawn in code, bright colours per struggle, big readable wind-ups, hit and defeat animation.
- R4 Game feel: menu and fight music, richer effects, haptics, screen shake, win and lose moments with the verse after the bout.
- R5 Menus behind the game: Next fight is the default after a result. One header on every screen: wordmark on the left; on the right four icons, Map, Daily Bout, Sound and Settings. Language, theme, haptics, privacy, Remove Ads and licences live inside Settings (language and theme follow the device by default). ads and rewards moved to the new moments.
- Test APK after R1 to R3 so the look and feel can be judged early; then R4, R5, a second APK, and the paused batches resume.

## Open questions
Which tuning from the old rules survives; whether verse cards stay as an optional extra; how the Journey map shows progress without a hurdle feel.
