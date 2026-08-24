# TODOS

Deferred work with enough context to pick up cold. Effort is human-team → CC+gstack.

Accurate as of v1.1.2+8 / `feat/puzzle-import` @ `2f65fe7`. Every item below was
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
- **Two save slots** — the daily and everything else, in progress at once
- **Sixteen techniques** — w-wing and the remote pair joined the chains tier

Guards that exist so the above cannot quietly come undone: every exit from a
game returns up the stack rather than replacing it, a drilled technique shows
its new record on the page you come back to, no drill hands over a cell with
one candidate in it, no unlabelled
`GestureDetector`, no platform calls in a cubit, no hand-rolled `mm:ss`, the
text-scale policy is wired to `MaterialApp`, one pip per drillable technique,
the board's size does not depend on the hint panel, no hint rung is over its
copy budget, every chain diagram's eliminations really do see both ends, and
every screen renders narrow without overflowing.

---

## P2 — expand the ladder past 16 rules

**What:** Sixteen techniques ship. sudoku.coach claims 27. The obvious next
rung is the finned fish family; after that it is diminishing returns on rules
almost nobody meets.

**Why:** The library and drill infrastructure scale for free — a new rule gets
a guide entry, a diagram, a drill and a mastery row with no new plumbing.

**Watch for:**
- `PuzzleDna.version` must bump, and new techniques must be **appended** to the
  `Technique` enum, never inserted — the fingerprint emits one slot per
  technique in declaration order and inserting shifts every previously shared
  fingerprint. `Technique.rank` exists so ordering stays sane despite that.
- **Measure the crux yield before promising a drill.** Three of the sixteen
  measure at zero and are marked `isDrillable == false`: the naked triple, the
  jellyfish and the remote pair. In every case a smaller pattern reaches the
  same elimination first, so the bigger one is available but never *required*.
  A menu item that reliably fails after seven seconds is worse than one that
  is honestly absent.

**Effort:** 1-2 days → 2-3h.

---

## P2 — verify the sudoku.coach 27-technique claim

Cited in the plan's competitive analysis and never checked. Verify before using
"16 vs 27" in any public copy.

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
- **A drill's seeded notes are all-or-nothing, and the singles get none.** Notes
  exist because the eliminations that set up a fish or a chain leave no mark on
  the board. That does not apply to the singles, whose setup is placements —
  seeding them there only restates the board and leaves cells showing one
  pencil mark, which is the answer. The rule is in `TrainerDrillBuilder._notesFor`
  and pinned by `trainer_mode_test.dart`. Seeding *only* the narrowed cells would
  be worse than seeding none: an x-wing is read across the whole grid.
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
  usage, abandon rate, and now archive age, import verdicts, whether anybody
  presses a key, and whether anybody runs two games at once. Still the
  cheapest source of information available and still unread.

  The last two are the ones this release is a bet on: `keyboard_used` says
  whether hardware-keyboard support is worth building further, and
  `two_games_in_progress` says whether the two-slot save was solving a real
  problem or an imagined one.
