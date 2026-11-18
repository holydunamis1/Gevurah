# Gevurah Boxing

**Gevurah Boxing: Faith Fight Game** is a rhythm-based boxing game for Android and iOS. The player's opponents are struggles people face in life (Fear, Worry, Anger, Doubt, Pride and others), shown as abstract shadow forms. Before each bout the player equips verse cards that change how moves behave. Fighting is stylised and bloodless, and verses appear only in pauses, never over live action.

- App ID: `com.zdmgold.gevurah`
- Audience: age 13 and over
- Stack: Flutter with Flame (Dart), no backend, static website only

## Where the plan lives

| What | Where |
| --- | --- |
| Master blueprint (design, architecture, file manifest, phases, batches) | claude.ai Project files: "Bible Boxing Game — Master Blueprint.md" |
| Live decision log, build sequence and turn-by-turn progress | `docs/decision.md` in this repo |
| Scripture sources, checksums, corrections | `docs/scripture_sources.md` (created in batch p2a) |
| Release checklist and rollback | `docs/runbook.md` (created in batch p7c) |

Every chat and every agent that works on this repo reads the blueprint first, then `docs/decision.md`, and appends to `docs/decision.md` as work lands. A change of plan is recorded there before it is built.

## Repository map

```
app/                  Flutter + Flame application (created from batch p1b onward)
website/              Static HTML/CSS site: landing, privacy, support
tools/scripture/      Extraction and packing scripts that build the bundled verse data
.github/workflows/    check.yml (every push), bootstrap_platform.yml, build_and_deploy.yml, emulator.yml (manual)
store_submission/     Store text, data-safety notes, screenshot plan
docs/                 decision.md, scripture_sources.md, runbook.md
```

## How to confirm a batch landed

1. Open the repository on github.com and switch to the `main` branch.
2. Open `docs/decision.md` and check the Build log table: the newest row names the batch and the paths it added.
3. Open the Actions tab and check that the `check` workflow is green for the newest commit on `main`.

## How batches are delivered

Each batch is pushed to the `ci-analyser` branch first. The `check` workflow runs, failures are fixed on that branch, and only a green commit is pushed to `main`. Builds and emulator runs are manual workflows and never start on a push.
