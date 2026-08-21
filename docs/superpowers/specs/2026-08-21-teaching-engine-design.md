# teaching engine — design

date: 2026-08-21
status: approved, pending implementation plan
supersedes: nothing
followed by: a separate spec for the compete/share layer

---

## 1. context

The app has product-market fit: paid acquisition converted, people play it daily.
The next move is depth, not breadth. This spec turns the hint feature — currently an
answer-reveal with a broken tap target — into a deduction engine that explains sudoku,
and makes difficulty mean something honest.

### the reported bug

`GameCubit.useHint()` (`lib/features/game/game_cubit.dart:510`) has three silent
`return` paths:

```dart
if (!state.hasSelection) return;      // :512  the reported bug
if (state.isGiven(row, col)) return;  // :518
if (previous == correctValue) return; // :522
```

`GameToolbar` (`lib/features/game/widgets/game_toolbar.dart:59`) sets
`enabled: state.hintsRemaining > 0` — it has no knowledge of whether a hint is
actually usable. `Haptics.hint()` fires *before* `cubit.useHint()`, so the tap
buzzes to confirm receipt and then nothing happens. That is the most confusing
possible feedback: the app says it heard you, then ignores you.

### the root cause

`useHint()` reads `state.solution` and writes the digit in. It teaches nothing, and
it cannot: `SudokuSolver` implements exactly three techniques — `nakedSingle`,
`hiddenSingle`, `backtracking`. There is no vocabulary for explaining a deduction, so
"hint" could only ever mean "here is the answer".

### the structural blocker

`SudokuBoard.candidates(r, c)` recomputes from placed digits on every call. It is the
only notion of candidate in the codebase (`sudoku_solver.dart:92`, `:203`, `:254`, and
`GameCubit.autoFillNotes`). It **cannot represent an elimination** — there is no way to
express "7 is out of this cell because of a pointing pair in box 3".

Every technique above singles works by eliminating candidates until a single falls out.
No elimination state means no techniques above singles, which means no explanations and
no honest grading. A mutable candidate grid with elimination support is therefore the
foundational new type; the technique ladder, generation grading, hints, stuck detection
and mastery attribution are all consumers of it.

### difficulty is currently a clue count

`SudokuGenerator.generate()` selects difficulty purely by target clue count via
`Difficulty.clueRange`. `SudokuSolver.rateDifficulty()` is technique-aware but is never
used to gate generation — techniques are computed post-hoc only for the complete screen.
Two "hard" puzzles can differ enormously. Digging to a clue count while checking only
*uniqueness* guarantees a unique solution, **not a logical path**, so expert puzzles
very likely require guessing.

### two shipped bugs found during analysis

`GameCubit.fromSaved()` (`:800`) does not restore `history`, and `saveCurrentGame()`
does not persist it. Consequences today:

1. Backgrounding the app destroys the undo stack.
2. `_cellPlacementDeltas`, `_mistakeCells`, `_undoCount`, `_notesEverUsed` and
   `_longestPause` are instance fields that reset on resume — so **quality score and
   velocity analysis are silently wrong for every resumed puzzle**.

Accurate technique attribution requires complete history, so this is repaired as part
of the foundation rather than deferred.

---

## 2. decisions

Each was explicitly chosen by the product owner during design.

| # | decision | rationale |
|---|---|---|
| 1 | Teaching is the spine; compete/share is a later, separate spec | Ranking players across incomparable puzzles is meaningless until difficulty is technique-honest |
| 2 | Hints are unlimited, free, escalating | Rationing teaching is a dark pattern, and the brand is explicitly no-bs. Depth taken is recorded so quality score stays meaningful |
| 3 | Generation guarantees a logical path; difficulty is technique-graded | No hint ever degrades into a bare reveal, and the failure mode is removed from the hardest puzzles where it hurt most |
| 4 | Unprompted help is limited to stuck detection | Post-solve debrief and wrong-turn warning were both declined; "stays out of your way" is preserved |
| 5 | Instant wrong-digit oracle stays the default; opt-in no-oracle mode added | Protects recently acquired users; the mode is recorded per puzzle so the future compete layer can rank like against like |
| 6 | Engine-first, phased delivery, with an immediate stopgap for the hint bug | Nothing gets built twice, and shipped users stop tapping a dead control right away |
| 7 | Hints may teach eliminations, with one-tap apply-to-notes | Pruning is most of the actual skill; placement-only hints teach where answers are, not how to find them |
| 8 | One coaching level with presets, plus granular overrides | One decision for the majority, full control for experts; avoids a wall of interacting switches nobody can reason about |
| 9 | Technique-defined tiers, familiar labels with honest subtitles | Preserves continuity for existing users while being truthful about what each tier requires |
| 10 | Resume state is fixed properly (history + all counters) | Required for accurate attribution, and repairs intelligence data already being collected and acted on |

Backend note: if the compete layer needs a backend, it uses Firebase only.
`firebase_core`, `analytics`, `crashlytics` and `messaging` are already dependencies,
so Auth + Firestore is an incremental add. Out of scope for this spec.

---

## 3. architecture — engine layer

New package, pure Dart, no Flutter imports, fully unit-testable:

```
lib/engine/deduction/
  units.dart                 precomputed unit + peer index tables
  candidate_grid.dart        CandidateGrid
  deduction.dart             Deduction, DeductionKind, Technique, TechniqueTier
  deduction_engine.dart      DeductionEngine, SolvePath
  techniques/
    naked_single.dart
    hidden_single.dart
    naked_subset.dart        pair and triple, parameterized by size
    hidden_subset.dart       pair and triple, parameterized by size
    intersection.dart        pointing pair, box-line reduction
    fish.dart                x-wing and swordfish, parameterized by size
    xy_wing.dart
    simple_coloring.dart
```

### 3.1 units.dart

Static const index tables computed once: for each of 81 cells, its row unit id, column
unit id, box unit id, and its 20 peers; plus the 27 units as cell-index lists. The
ladder runs millions of times during pool generation — recomputing row/col/box per
query does not hold up. This is the single largest performance lever.

### 3.2 CandidateGrid

Mutable. 81 cells of 9-bit mask stored in a `Uint16List` (bit `n-1` set means digit `n`
is still possible), plus a parallel `Uint8List` of placed digits.

```dart
class CandidateGrid {
  factory CandidateGrid.fromBoard(SudokuBoard board);
  int  candidateMask(int idx);
  Iterable<int> candidatesOf(int idx);
  int  candidateCount(int idx);
  int  placed(int idx);
  bool eliminate(int idx, int digit);   // returns true if it changed anything
  void place(int idx, int digit);       // sets digit and eliminates from peers
  bool get isSolved;
  bool get isBroken;                    // a cell with no candidates and no digit
  CandidateGrid clone();
}
```

It stays deliberately **separate** from `SudokuBoard`. The board is a value type with
equality and flat-string persistence; candidate state is solver-internal and mutable.
Board = truth about placed digits. Grid = derived state plus eliminations. Conflating
them would put mutable solver state into the type used for storage and undo.

`SudokuBoard.candidates()` is left in place — `autoFillNotes` and the backtracking
uniqueness check still use it, and it is correct for its purpose.

### 3.3 Deduction

The explanation payload, and deliberately **not** prose:

```dart
enum DeductionKind { placement, elimination }

class Deduction {
  final Technique technique;
  final DeductionKind kind;
  final List<(int cellIdx, int digit)> targets;   // to place, or to remove
  final List<int> witnesses;                       // cells that prove it — highlighted
  final UnitRef? unit;                             // for the R1 "look here" nudge
}
```

The engine returns structure; copy is generated in the presentation layer. This keeps
the lowercase-dry voice rule out of the engine and makes the whole ladder testable
without string matching.

### 3.4 Technique and the ladder

```dart
abstract interface class TechniqueRule {
  Technique get technique;
  TechniqueTier get tier;
  Deduction? find(CandidateGrid grid);
}
```

The ladder is an ordered `List<TechniqueRule>`, easiest first, and doubles as the
difficulty scale:

| tier | techniques |
|---|---|
| `singles` | naked single, hidden single |
| `pairs` | naked pair, hidden pair, naked triple, hidden triple |
| `intersections` | pointing pair, box-line reduction |
| `fish` | x-wing, swordfish |
| `chains` | xy-wing, simple coloring |

### 3.5 DeductionEngine

Two methods; every feature is a consumer of one of them.

```dart
class DeductionEngine {
  Deduction? nextStep(CandidateGrid grid, {TechniqueTier maxTier});
  List<Deduction> allStepsAt(CandidateGrid grid, {TechniqueTier maxTier});
  SolvePath solve(CandidateGrid grid, {TechniqueTier maxTier});
}

class SolvePath {
  final List<Deduction> steps;
  final bool complete;                 // reached a full board with no guessing
  final Technique? hardestTechnique;
}
```

- `nextStep` — first hit down the ladder. Powers hints and stuck detection.
- `allStepsAt` — every technique that currently applies. Powers mastery attribution.
- `solve` — repeatedly applies `nextStep` until solved or stuck. Powers generation
  grading and attribution replay.

`SudokuSolver` retains its backtracking uniqueness check unchanged. `solveWithTechniques`
and `rateDifficulty` are **deleted** — leaving them would create two disagreeing sources
of difficulty truth. `SolveTechnique` enum is removed; `CompleteScreen` consumes
`Technique` instead.

---

## 4. generation and the puzzle pool

### 4.1 the second gate

`_digHoles` keeps its existing uniqueness check and gains a second one: after a
candidate removal, `engine.solve(grid, maxTier: targetTier)` must return
`complete == true`. If it does not, the removal is reverted. Difficulty is then
**the hardest technique in the accepted path**, not a clue count. Clue count stops
being a target and becomes an observed output.

### 4.2 the pool

Technique-verified digging is substantially slower, so puzzles are pre-generated.

New drift table `PuzzlePool`: `tier`, `clues`, `puzzleCells`, `solutionCells`,
`hardestTechnique`, `pathLength`, `generatedAt`, `consumed`. Indexed on
`(tier, consumed)`.

- Top-up runs in the background via `workmanager` (already a dependency) targeting a
  small buffer per tier.
- Play start draws from the pool and marks the row consumed — instant.
- Pool miss falls back to on-demand `Isolate.run` generation, which is the current
  behavior and already has a loader UI (`GridLoader`, with its 1500ms minimum delay).
- If a tier cannot be generated within a bounded attempt budget, generation falls back
  to the nearest easier tier and **labels the puzzle at the tier it actually is**.
  Never silently mislabel.

### 4.3 daily puzzle determinism

`generateDaily` seeds off the date, so changing the algorithm retroactively changes what
a past date "was". Determinism across devices still holds — `Random(seed)` plus a pure
verification function is reproducible — but a past daily would no longer match what
people actually played.

Rule: a `dailyAlgorithmV2Cutover` date constant lives in
`lib/engine/sudoku_generator.dart`. Dates before it use the v1 algorithm, preserved
verbatim; dates on or after it use v2. The constant is set to the release date at ship
time and **must never be moved backward once shipped**. Both algorithms are retained
permanently. A test pins v1 output for a set of fixed historical dates.

The daily is generated on demand from its seed rather than drawn from the pool, since
it must be globally identical.

### 4.4 tier rotation

Seven days, five tiers, ramping to a peak on Sunday:

| day | tier |
|---|---|
| mon | easy |
| tue | medium |
| wed | medium |
| thu | hard |
| fri | hard |
| sat | expert |
| sun | master |

A beginner cannot solve Sunday unaided — and that is the strongest argument for this
system, because unlimited teaching hints let them get through it *and understand how*.

---

## 5. hint system

### 5.1 selection awareness

Board-scoped, but selection-aware. This turns the reported bug into a teaching moment:

- **nothing selected** → the next provable step anywhere on the board.
- **cell selected and provable now** → explain that cell. Respects intent.
- **cell selected but not yet provable** → say so plainly (`nothing provable there
  yet.`), then offer the board-wide step. Beginners do not know that not every empty
  cell is solvable yet; this teaches it instead of silently doing nothing.
- **cell selected is a given, or already correct** → falls through to the board-wide
  step. No silent return.

The hint control is never disabled. There is always a next nudge.

### 5.2 escalation rungs

Each tap advances one rung on the same deduction:

| rung | content |
|---|---|
| R1 locate | the unit only — `there's something in box 4.` |
| R2 narrow | highlights the target cell. no digit, no technique name |
| R3 explain | names the technique, highlights the **witness** cells doing the eliminating, one dry sentence |
| R4 apply | places the digit, or writes the eliminations into notes |

### 5.3 hint stability

The active `Deduction` is **pinned in `GameState`**, not recomputed per tap. If tap 1
says box 4 and tap 2 jumps to box 7, the feature reads as broken.

```dart
final Deduction? activeHint;
final int hintRung;          // 0 = none, 1..4
```

Invalidation — `activeHint` clears and `hintRung` resets to 0 when:
- all of its `targets` have been satisfied (by the player or by R4), or
- the board changed such that `technique.find()` no longer reproduces it.

Undo of a hint restores the prior `activeHint` and `hintRung` (carried on the action).

### 5.4 elimination lessons

When the next step is an elimination, R4 has a prerequisite: if the affected cells have
no pencil marks, "remove 4 and 7" is meaningless. So R4 for an elimination:

1. fills basic candidates for cells in the affected unit that currently have no notes,
2. then applies the eliminations to the player's notes.

Both steps are one undoable action. At `minimal` and `standard` coaching levels,
elimination deductions are applied silently inside the engine and the hint escalates to
the next placement instead, so those players only ever see placements.

### 5.5 copy

`lib/features/game/hint_copy.dart` maps `(Deduction, rung, coachingLevel)` to a string.
All copy lives here — lowercase, dry, calm, no exclamation points, per the project voice
rule. Kept out of the engine so voice changes never touch logic.

### 5.6 accounting

`hintsRemaining` is retired from `GameState`, replaced by `hintsUsed` and
`hintDepthTotal` (the sum of rungs taken). Quality score consumes depth rather than a
raw count, so an R1 nudge costs far less than a full R4 reveal. This changes the formula,
so `QualityScore` bumps `formulaVersion` to 2 and the stats screen only compares within
a version — the schema already carries `formulaVersion` as precedent.

---

## 6. coaching levels

Hints are unlimited and free at every level. The level changes *scaffolding*, never
access.

| | minimal | standard | **coach** (default) | tutor |
|---|---|---|---|---|
| hint starts at rung | R3 | R2 | R1 | R1, concrete phrasing |
| elimination lessons | placements only | placements only | yes | yes, fills notes first |
| technique names | bare | bare | bare | + one-line definition, first time only |
| stuck detection | off | off | on | on, more sensitive |
| instant wrong-digit oracle | off | on | on | on |
| mastery tracking | on | on | on | on |

`minimal` gives an expert *fewer taps to the answer*, not fewer features — which is why
it is not called "off".

### 6.1 overrides

Each row is individually overridable under an advanced section. Stored as nullable
columns; effective value is `override ?? presetDefault(level)`. Nullable means "follow
the preset", so changing preset continues to move any setting the user never touched.

### 6.2 onboarding

Asks about behavior, not self-assessment, because people misjudge their own level:

- `still learning the rules` → tutor
- `i solve them, want to get better` → coach
- `i know what an x-wing is` → minimal

### 6.3 existing users

Default to `standard`, which is bit-for-bit today's behavior. A single non-modal card
on the home screen offers the upgrade once, dismissible permanently. Nothing changes
under recently acquired users uninvited.

---

## 7. difficulty tiers

Technique-defined, with familiar words as the primary label and the honest requirement
as the subtitle:

| tier | subtitle |
|---|---|
| easy | singles only |
| medium | pairs and triples |
| hard | intersections |
| expert | x-wing, swordfish |
| master | chains |

`Difficulty` gains a `master` value. `clueRange` is removed (clue count is no longer an
input). `parSeconds` gains a value for `master` and existing values are retained.

### 7.1 old records

Old "expert" (22–28 clues, guessing permitted) is genuinely not new "expert". A
`tierVersion` column marks records: `1` = legacy clue-count grading, `2` =
technique-graded. Stats compares only within a version, and per-difficulty breakdowns
label legacy rows as such. Records are never retroactively relabeled — the puzzles they
describe really were the old kind.

---

## 8. mastery profile

### 8.1 what it shows

A new section on the stats screen. Per technique: times seen, times spotted unaided,
times assisted. Copy stays dry — `pointing pair — seen 34. spotted unaided 3.` — plus
one derived line naming the weakest link, e.g. `you brute-force past intersections.
that's the next thing worth learning.`

Lives on the stats screen specifically because that screen is passive and visited on
purpose. Nothing about mastery ever appears unbidden.

### 8.2 attribution algorithm

`lib/core/intelligence/technique_attribution.dart` — a pure function
`(puzzle, solution, history) -> AttributionResult`.

Replay `history` in order against a `CandidateGrid`. At each step, before applying the
player's action, compute `allStepsAt(grid)`. On a **correct placement** at cell X:

- a returned deduction places a digit at X → credit the **easiest** such technique. The
  player most plausibly took the simplest route available.
- no returned deduction targets X → **ahead of the ladder**. They used a technique not
  implemented, or guessed. Counted separately in a single profile-level counter and
  never penalized.
- the placement came from a `UseHint` action → credited as **assisted** for that
  technique, at the rung taken.

Wrong placements are skipped; they are already tracked as mistakes. Note actions and
`AutoFillNotes` advance the replay without attribution.

Ambiguity is resolved deterministically by ladder order (easiest wins). This is a
documented heuristic, not a claim about what the player actually thought.

### 8.3 execution

Runs on an isolate after the complete screen loads, so it never blocks the solve
animation. Only the aggregate persists — new `TechniqueStats` table — keeping the stats
screen a trivial query.

---

## 9. stuck detection

Fires when **all** of the following hold:

- the effective `stuckDetection` flag is on — per section 6 it is off at `minimal` and
  `standard`, **and**
- time since the last placement exceeds the player's personal p90 pause for this tier,
  **and**
- that pause exceeds a 45-second floor, **and**
- `nextStep()` returns a deduction (there is genuinely something to find), **and**
- fewer than 3 nudges have fired this puzzle, **and**
- at least one placement has occurred since the last nudge.

The personal p90 is computed by pooling every inter-placement delta from
`PuzzleRecords.solveTimes` across that player's records at the same tier, then taking the
90th percentile. With fewer than 3 records at that tier, a flat 90-second threshold is
used instead.

Presentation: one dismissible line near the grid — `there's something in row 7.` Never a
modal, never blocking, never repeated for the same cell. Evaluated on the existing timer
tick; `GameState` gains `stuckNudge`. The existing `AppLifecycleListener` already pauses
the timer, so being away from the app does not count as being stuck.

`buildWhen` on the header and grid must exclude `stuckNudge` changes from triggering
full grid rebuilds, consistent with the existing timer-tick discipline.

---

## 10. data model

Each wave that touches storage bumps `schemaVersion` independently, because every wave is
separately shippable. All changes are additive; no column is ever dropped.

| wave | schema | changes |
|---|---|---|
| W0 | 8 → 9 | `SavedGames` resume columns |
| W2 | 9 → 10 | `PuzzlePool` table, `PuzzleRecords.tierVersion` + `hardestTechnique` |
| W3 | 10 → 11 | `GamePreferencesTable` coaching columns, `PuzzleRecords.hintDepthTotal` + `coachingLevel` + `oracleEnabled` |
| W5 | 11 → 12 | `TechniqueStats` table, `PuzzleRecords.aheadOfLadderCount`, `PlayerProfiles.aheadOfLadderTotal` |

`SavedGames.hintsRemaining` survives as an unused column once hints go unlimited in W3.
Drift makes dropping a column expensive and the row is transient anyway, so new writes
simply leave it at its default.

### new tables

**`PuzzlePool`** — `id`, `tier`, `clues`, `puzzleCells`, `solutionCells`,
`hardestTechnique`, `pathLength`, `generatedAt`, `consumed`. Index `(tier, consumed)`.

**`TechniqueStats`** — `technique` (primary key), `seenCount`, `unaidedCount`,
`assistedCount`, `lastSeenAt`.

### `SavedGames` additions — the resume fix

`history` (text, JSON), `placementDeltas` (csv), `mistakeCells` (csv), `undoCount`,
`usedNotes`, `longestPauseSeconds`, `hintsUsed`, `hintDepthTotal`, `activeHintJson`
(nullable), `hintRung`.

`saveCurrentGame` writes all of them; `fromSaved` restores all of them into both
`GameState` and the cubit's instance fields. This repairs the undo-stack loss and the
corrupted velocity/quality data for resumed puzzles.

`GameAction` becomes JSON-serializable: each variant of the sealed union gains
`toJson()` and a `type` discriminator, with a `GameAction.fromJson` factory. A
round-trip test covers every variant.

### `PuzzleRecords` additions

`tierVersion` (default 1), `hintDepthTotal` (default 0), `hardestTechnique` (nullable),
`coachingLevel` (default `standard`), `oracleEnabled` (default true),
`aheadOfLadderCount` (default 0).

### `GamePreferencesTable` additions

`coachingLevel` (text, default `standard`), plus nullable overrides:
`hintStartRung`, `eliminationLessons`, `stuckDetection`, `instantOracle`,
`techniqueDefinitions`.

Existing users land on `standard` by default, preserving current behavior exactly.

### `PlayerProfiles` additions

`aheadOfLadderTotal` (default 0).

### migration

One `from < N` block per wave, following the existing `onUpgrade` pattern in
`app_database.dart`. Existing rows keep `tierVersion = 1` and `coachingLevel = 'standard'`
by column default. Nothing is backfilled or recomputed — old records describe puzzles that
really were the old kind.

---

## 11. immediate stopgap

Ships ahead of the engine, decoupled, superseded cleanly later. Hints stay capped at 3
here — the unlimited escalating economy arrives with the engine in W3. W0 fixes only the
broken control, nothing about the economy. Three changes:

1. `useHint()` no longer requires a selection. With nothing selected it picks the empty
   cell with the fewest candidates — a genuine "easiest next" heuristic — selects it,
   and reveals it.
2. The given-cell and already-correct branches fall through to that same choice instead
   of returning silently.
3. `Haptics.hint()` moves to *after* a successful hint, so the buzz stops lying.

Regression test: calling `useHint()` with no selection reveals a cell and decrements the
count.

---

## 12. testing

**Engine (pure Dart, fastest and most valuable)**
- one golden test per technique: a hand-built grid where that technique is the only
  applicable step, asserting exact `targets` and `witnesses`.
- negative tests: each technique returns `null` on a grid where it does not apply.
- property test: for a corpus of generated puzzles, `solve()` never places a digit that
  contradicts the stored solution, and never reports `complete` on an unsolved grid.
- `CandidateGrid` invariants: `place` eliminates from exactly the 20 peers; `eliminate`
  returns true only on actual change; `isBroken` detects an empty cell.

**Generation**
- every puzzle produced for tier T is solvable by `solve(maxTier: T)` with
  `complete == true`.
- no puzzle produced for tier T is solvable within tier T-1 (the tier is tight, not just
  an upper bound).
- v1 daily output is pinned for fixed historical dates; v2 output is deterministic for
  the same seed across runs.

**Attribution**
- fixture puzzle plus a scripted history producing known technique counts.
- a history containing a hint credits assisted, not unaided.
- a placement with no available deduction increments ahead-of-ladder, not a technique.

**Coaching levels**
- matrix test: each preset resolves to the expected effective flags.
- an override survives a preset change; an untouched setting follows it.

**Cubit and widget**
- the reported bug: hint with no selection produces a nudge (not a no-op).
- tapping hint four times yields the same deduction at rungs 1→4.
- hint invalidation: placing the hinted digit manually clears `activeHint`.
- resume round-trip: save mid-game, restore, undo still unwinds the full stack.
- stuck detection does not fire while a deduction is absent, or twice without an
  intervening placement.

---

## 13. delivery waves

Each wave is independently shippable and lands on the final architecture.

| wave | contents |
|---|---|
| **W0** | stopgap hint fix; resume-state fix (history + counters persisted, `GameAction` serialization) |
| **W1** | engine: `units`, `CandidateGrid`, `Deduction`, ladder, `DeductionEngine`, full test suite. No UI, no user-visible change |
| **W2** | generation second gate, `PuzzlePool` + background top-up, `master` tier, `tierVersion`, delete `solveWithTechniques`/`rateDifficulty`, tier labels and rotation |
| **W3** | hint system: pinned deduction, four rungs, elimination lessons, `hint_copy`, coaching presets + overrides, onboarding question, existing-user card |
| **W4** | stuck detection |
| **W5** | attribution, `TechniqueStats`, mastery section on the stats screen |

---

## 14. out of scope

- compete/share layer — its own spec, after this one. Firebase only when it lands.
- post-solve technique debrief — declined.
- wrong-turn warning before committing a digit — declined.
- sound design, new themes, puzzle variants (killer, jigsaw, thermo), accessibility
  overhaul.
- `CLAUDE.md` describes the palette as dark `#0A0A0A` with lime accent, but the shipped
  default is the `paper` sticker theme. Noted as stale documentation; correcting it is a
  separate housekeeping task.

---

## 15. risks

| risk | mitigation |
|---|---|
| `master` tier generation may be slow or occasionally fail | Bounded attempt budget, pool buffering, and honest fallback to the nearest easier tier with correct labeling |
| `simple_coloring` is the most complex rule and could slip | The `chains` tier can ship with `xy_wing` only; coloring is additive and does not change the tier's meaning |
| Attribution "easiest technique wins" may misread intent | Documented as a heuristic. The profile reports what was *available*, never a claim about thought process |
| Quality score formula change makes new scores incomparable to old | `formulaVersion` 2; stats compares only within a version |
| Daily algorithm cutover mishandled | Both algorithms retained permanently; cutover constant never moves backward; v1 output pinned by test |
| Pool table grows unbounded | Consumed rows pruned on top-up, keeping a small retention window for crash recovery |
