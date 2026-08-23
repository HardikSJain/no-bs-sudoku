# TODOS

Deferred work with enough context to pick up cold. Effort is human-team → CC+gstack.

Accurate as of v1.1.2+8 / `feat/puzzle-import` @ `a5e19d2`. Every item below was
checked against the code, not against memory.

---

## Shipped

The teaching-engine plan (`docs/superpowers/specs/2026-08-21-teaching-engine-design.md`)
is delivered end to end, plus the mastery layer R5 was gated on and several
things the plan did not call for.

- **R0 defects** — the hint bug, silent `erase`, partial save restore, wall-clock
  timing, `undo` and `mistakeCount`, UTC daily across 7 sites, discard
  confirmation, iPad share crash
- **Stage 1** — four repositories, constructor injection, `StorageService` deleted
- **R1 engine** — `units`, `CandidateGrid`, `Deduction`, the ladder; fuzzed
  against the backtracking solver
- **R2 generation** — tier gate in the dig loop with the uniqueness oracle once on
  the accepted board. Expert p95 6.0s → 156ms. No puzzle needs a guess
- **R3 hints** — four rungs, pinned deduction, wrong-digit branch, quality v2,
  stuck detection, three coaching switches
- **R4 depth** — fish and chains tiers, floor-targeted generation, trainer drills,
  solve-path analysis, DNA fingerprint
- **R5 mastery** — per-technique levels measured from drills, technique library
  with diagrams, mastery on the stats screen
- **R6 import** — grid entry and paste, bounded solution counting on an isolate,
  four distinct verdicts
- **Accessibility** — `Tappable` everywhere, board semantics, the text-scale
  policy actually applied at the app root, hint highlighting by outline as
  well as hue
- **One theme** — dark and amoled removed along with the `isLight` branching
- **Daily archive** — the last 90 days as a calendar, any of them playable
- **Hardware keyboard** — arrows/hjkl, digits, notes, undo, hint, esc; listed
  in settings

Guards that exist so the above cannot quietly come undone: no unlabelled
`GestureDetector`, no platform calls in a cubit, no hand-rolled `mm:ss`, the
text-scale policy is wired to `MaterialApp`, one pip per drillable technique,
and the board's size does not depend on the hint panel.

---

## P2 — expand the ladder past 14 rules

**What:** Fourteen techniques ship. sudoku.coach claims 27. The obvious next
rungs are w-wing, remote pairs, and the finned fish family.

**Why:** The library and drill infrastructure scale for free — a new rule gets
a guide entry, a diagram, a drill and a mastery row with no new plumbing.

**Watch for:**
- `PuzzleDna.version` must bump, and new techniques must be **appended** to the
  `Technique` enum, never inserted — the fingerprint emits one slot per
  technique in declaration order and inserting shifts every previously shared
  fingerprint. `Technique.rank` exists so ordering stays sane despite that.
- Check crux yield before promising a drill. Jellyfish is in the enum and
  marked `isDrillable == false` because 0 of 4 attempts produced a usable
  crux at 5.5s per failure.

**Effort:** 1-2 days → 2-3h.

---

## P2 — verify the sudoku.coach 27-technique claim

Cited in the plan's competitive analysis and never checked. Verify before using
"14 vs 27" in any public copy.

---

## P2 — the copy budget the hint plan asked for

**What:** §R3 specified 40 / 60 / 140 characters per rung. The panel caps its
height and scrolls instead, which solves the layout problem the budget was
protecting against but not the writing problem it was also about.

**Why:** A rung that needs scrolling on a phone is a rung that said too much.

**Effort:** 2h → 20m, mostly editing prose in `hint_copy.dart` plus a test that
fails a rung over budget.

---

## P2 — variant strategy spec (killer, thermo, jigsaw)

Killer is the strongest candidate: it is the most-played variant and the cage
arithmetic is a genuinely different deduction domain. Jigsaw is cheapest —
`units.dart` already abstracts the box, so irregular regions are a data change
rather than an engine change.

**Watch for:** the ladder assumes box geometry in several rules. Jigsaw needs
the rules to read units from the grid rather than from `Units`.

**Effort:** 1 week → 1 day for jigsaw; killer is a new engine.

---

## P3 — considered, not scheduled

- **Camera OCR for import** — the import screen exists now, so this is a text
  source rather than a feature.
- **Home-screen widget** — daily puzzle at a glance. Real native work on both
  platforms; the only item on this list that is not mostly Dart.
- **A full daily archive rather than 90 days** — generation is deterministic
  for any date, so the window is a product choice (`dailyArchiveDays`). Going
  further back needs a launch date to anchor it and a calendar that does not
  become a scroll you get lost in.
- **Extract DESIGN.md from the code** — the palette and spacing live in one
  place and could be documented properly.
- **Monetization** — ad spend with no revenue model is not durable. Note that
  **a theme pack is no longer an option**: themes were removed deliberately, and
  reintroducing them to sell would undo that and reopen the three-palette
  maintenance problem. A tip jar violates nothing.

---

## Known limits, recorded rather than fixed

- **A viewport shorter than 519 points overflows the game column.** The board
  will not go below 225pt (25pt cells) and the chrome plus the hint panel's
  own chip and dots need the rest. No phone is that short in portrait; an
  original SE at 320x548 fits with the board reduced to 229. Pinned by
  `test/game/board_size_test.dart`.
- **`GameCubit.close()` must be called from inside a widget test's body, not
  from `tearDown`.** It awaits real database futures scheduled in the
  fake-async zone, which has stopped pumping by the time teardown runs — the
  body passes and the file hangs. Noted on `close()` itself.

---

## Owner-only — not code

- **Play staged rollout gated on the Crashlytics crash-free rate.** Schema
  migrations 9→16 are irreversible: there is no `onDowngrade`, and Play cannot
  lower a `versionCode`. A bad release cannot be rolled back, only rolled
  forward.
- **Move `dailyAlgorithmV2Cutover` if the release slips past 2026-09-12.**
  It is `2026-09-15` in `sudoku_generator.dart` and must stay at or beyond
  release + 3 days, or updated and non-updated players get different dailies.
  Once it is safely past, the legacy dig below it can be deleted. Note the
  archive already honours it per date, so past dailies stay the ones people
  actually played.
- **Read the analytics already being collected** — D1, D7, session length, hint
  usage, abandon rate, and now archive age and import verdicts. Still the
  cheapest source of information available and still unread.
