# TODOS

Deferred work with enough context to pick up cold. Effort is human-team → CC+gstack.

Accurate as of v1.1.2+8 / main @ `9c12d3a`. Every item below was checked against
the code, not against memory.

---

## Shipped

The teaching-engine plan (`docs/superpowers/specs/2026-08-21-teaching-engine-design.md`)
is delivered through R4, plus the mastery layer R5 was gated on.

- **R0 defects** — the hint bug, silent `erase`, partial save restore, wall-clock
  timing, `undo` and `mistakeCount`, UTC daily across 7 sites, discard
  confirmation, iPad share crash
- **Stage 1** — four repositories, constructor injection, `StorageService` deleted
- **R1 engine** — `units`, `CandidateGrid`, `Deduction`, 12 techniques, ladder;
  fuzzed against the backtracking solver
- **R2 generation** — tier gate in the dig loop with the uniqueness oracle once on
  the accepted board. Expert p95 6.0s → 156ms. No puzzle needs a guess
- **R3 hints** — four rungs, pinned deduction, wrong-digit branch, quality v2,
  stuck detection, three coaching switches
- **R4 depth** — fish and chains tiers, floor-targeted generation, trainer drills,
  solve-path analysis, DNA fingerprint
- **R5 mastery** — per-technique levels measured from drills, technique library
  with diagrams
- **Accessibility primitives** — `Tappable`, board semantics, text-scale policy
- **One theme** — dark and amoled removed along with the `isLight` branching

---

## P1 — the accessibility sweep is half done

**What:** The primitives exist (`lib/core/a11y/tappable.dart`) and the board is
labelled. Every other screen still uses bare `GestureDetector`, which assistive
technology cannot see: no role, no name, nothing to activate.

Remaining, by count of unlabelled tap targets:

| file | targets |
|---|---|
| `home_screen.dart` | 7 |
| `settings_screen.dart` | 5 |
| `learn_screen.dart` | 3 |
| `complete_screen.dart`, `tier_detail_screen.dart`, `game_screen.dart`, `hint_panel.dart` | 2 each |
| `stats_strip.dart`, `daily_puzzle_card.dart`, `technique_detail_screen.dart`, `solve_replay.dart`, `onboarding_screen.dart` | 1 each |

**Why:** A screen reader user can currently reach the board and nothing else.
This is the single largest gap between the app and "best out there".

**Effort:** 1 day → 1-2h. Mostly mechanical: swap `GestureDetector` for
`Tappable` and write the label. The judgement is in the labels, not the wiring.

**Watch for:** `excludeSemantics` is on by default in `Tappable`, so a card whose
inner text should be read needs it turned off rather than a label duplicating
the content.

---

## P1 — R6 puzzle import

**What:** Manual grid entry and paste-a-string, per §4.6 of the spec. The only
whole wave of the plan not built.

**Why:** It is the last thing a serious solver expects and cannot do here. It
also reuses the solve-path analysis view, so most of the output side exists.

**Effort:** 3-4 days → 3-4h.

**Watch for:** §4.1's shortcut does **not** transfer. "A complete `SolvePath`
proves uniqueness" holds for a puzzle we generated; for a grid somebody typed,
a stalled ladder proves nothing. Import needs real solution counting on an
isolate with a bounded budget, and four distinct failure messages — invalid,
unsolvable, multiple solutions, budget exhausted. Imported puzzles must never
touch records, streaks or stats: they have no `Difficulty`, so no par, so no
quality score.

---

## P2 — geometry still duplicated in three places

**What:** `units.dart` has the box maths. Three sites still compute it inline:
`sudoku_board.dart:35` (`box()`), `sudoku_grid.dart:170`, `game_cubit.dart:1182`.

**Why:** Not a bug today, but four copies of `(row ~/ 3) * 3` is how the fifth
one gets it wrong.

**Effort:** 1h → 15m. Structural only, no behaviour change.

---

## P2 — three R3 polish items the plan called for and did not get

- **Highlight by outline, not hue.** The plan specified dashed outline for
  witnesses and solid for the target. Shipped as background tints instead,
  which works but leans on colour alone — an accessibility concern as well as
  a visual one.
- **Copy budget per rung** (40 / 60 / 140 chars) with internal scroll. The hint
  panel currently grows to fit, which can push the toolbar on a short screen.
- **Confirm before the apply rung**, only when escalating. Right now the fourth
  tap fills the digit with no chance to stop.

**Effort:** half a day → 45m for all three.

---

## P2 — expand the ladder past 12 rules

**What:** sudoku.coach ships 27. The obvious next rungs are jellyfish,
xyz-wing, w-wing, remote pairs, and the finned fish family.

**Why:** The library and drill infrastructure now scale for free — a new rule
gets a guide entry, a diagram, a drill and a mastery row with no new plumbing.

**Watch for:** `PuzzleDna.version` must bump, and new techniques must be
**appended** to the `Technique` enum, never inserted — the fingerprint emits one
slot per technique in declaration order and inserting shifts every previously
shared fingerprint.

**Effort:** 1-2 days → 2-3h.

---

## P2 — verify the sudoku.coach 27-technique claim

Cited in the plan's competitive analysis and never checked. Verify before using
"12 vs 27" in any public copy.

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

- **Camera OCR for import** — depends on R6 landing first.
- **External keyboard support** — deferred in the plan; matters mainly on iPad.
- **Home-screen widget** — daily puzzle at a glance.
- **Daily archive** — needs the algorithm version pinned per date before it can
  exist, since generation changed at the cutover.
- **Extract DESIGN.md from the code** — the palette and spacing now live in one
  place and could be documented properly.
- **Monetization** — ad spend with no revenue model is not durable. Note that
  **a theme pack is no longer an option**: themes were removed deliberately, and
  reintroducing them to sell would undo that and reopen the three-palette
  maintenance problem. A tip jar violates nothing.

---

## Owner-only — not code

- **Play staged rollout gated on the Crashlytics crash-free rate.** Schema
  migrations 9→16 are irreversible: there is no `onDowngrade`, and Play cannot
  lower a `versionCode`. A bad release cannot be rolled back, only rolled
  forward.
- **Move `dailyAlgorithmV2Cutover` if the release slips past 2026-09-12.**
  It is `2026-09-15` in `sudoku_generator.dart` and must stay at or beyond
  release + 3 days, or updated and non-updated players get different dailies.
  Once it is safely past, the legacy dig below it can be deleted.
- **Read the analytics already being collected** — D1, D7, session length, hint
  usage, abandon rate. Still the cheapest source of information available and
  still unread.
