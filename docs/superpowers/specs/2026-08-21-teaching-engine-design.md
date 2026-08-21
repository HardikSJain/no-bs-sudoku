# teaching engine — design

date: 2026-08-21
revision: 2 (rewritten after benchmarked engineering review + product review)
status: approved, pending implementation plan
followed by: a separate spec for the compete/share layer

---

## 0. what changed in revision 2

Revision 1 was reviewed by two independent passes — one adversarial engineering review
that **benchmarked the generator** rather than reasoning about it, and one product review
against the actual install base. Both changed the plan materially. Recorded here because
the reasoning matters more than the conclusion.

| v1 claim | what the review found | v2 |
|---|---|---|
| "Technique-verified digging is substantially slower, so puzzles are pre-generated" | Backwards. The tier gate costs ~0; `hasUniqueSolution` is essentially all of generation time. The gate also makes that check **logically redundant** | `PuzzlePool`, `workmanager` top-up, pruning, retention window — **all deleted** |
| `Difficulty.clueRange` is removed; clue count is no longer an input | `_digHoles` is driven end-to-end by clue targets. Deleting them leaves no stopping rule; maximal digging saturates every tier to 23–27 clues, making "easy" a 40-minute beginner scan | Clue ranges **stay** as guard rails. Tier is a ceiling; rejection sampling targets it |
| Five technique-defined tiers, `master` added | Every tier's meaning moves at once while the home screen displays old personal bests beside new puzzles. Home screen hardcodes exactly four cards | **Four existing labels kept**, meaning preserved. No `master`. Gate applied underneath |
| Mastery: `pointing pair — seen 34. spotted unaided 3.` | Unobservable. Elimination hints write notes; attribution only fires on placements. The example copy cannot be produced by the algorithm | Mastery deferred behind an instrumentation gate, and reduced to what is observable |
| Four coaching presets + per-row overrides | Escalation is already self-adjusting: an expert taps once, a beginner taps four times | **Three plain switches**, no presets, no onboarding question, no upgrade card |
| "The schema already carries `formulaVersion` as precedent" | It has zero writers and zero readers. One reference in `lib/` and `test/`: the column definition | Treated as net-new work, with read paths enumerated |
| Resume drops `history` and five counters | Correct, and incomplete — `_techniques` is a sixth, placement timing uses wall clock, and `undo()` corrupts `mistakeCount` | R0 expanded to the full inventory |

The net effect: **less engineering, more defect repair, and a gate before the speculative
half.** R0 became the headline rather than the warm-up.

---

## 1. context

The app has product-market fit — paid acquisition converted and people play daily. The
next move is depth, not breadth.

### 1.1 the reported bug

`GameCubit.useHint()` (`lib/features/game/game_cubit.dart:510`) has three silent returns:

```dart
if (!state.hasSelection) return;      // :512  the reported bug
if (state.isGiven(row, col)) return;  // :518
if (previous == correctValue) return; // :522
```

`GameToolbar` (`widgets/game_toolbar.dart:59`) gates on `hintsRemaining > 0` alone — it
cannot know whether a hint is usable — and `Haptics.hint()` fires at `:64` *before*
`cubit.useHint()`. So the tap buzzes to confirm receipt and then nothing happens: the app
says it heard you, then ignores you.

The root cause is that `useHint` is **cell-scoped** — it asks "what goes here?" A teaching
hint is **board-scoped**: "what is provable anywhere on this grid?" Framed that way the
bug dissolves rather than getting patched.

### 1.2 the structural blocker

`SudokuBoard.candidates(r, c)` recomputes from placed digits on every call and
**cannot represent an elimination** — there is no way to express "7 is out of this cell
because of a pointing pair in box 3". Every technique above singles works by eliminating
candidates until a single falls out, so no elimination state means no techniques above
singles, no explanations, and no honest grading.

Note the codebase already has **two** candidate notions, and v1 of this spec got this
wrong: `autoFillNotes` does *not* use `SudokuBoard.candidates()` — it has its own
`_isValidCandidate` (`game_cubit.dart:290-303`). `CandidateGrid` would be a third. §3.6
addresses consolidation.

### 1.3 difficulty is a clue count, and the top two tiers are the same puzzle

`generate()` selects by target clue count via `Difficulty.clueRange`.
`SudokuSolver.rateDifficulty()` is technique-aware but never gates generation.

Measured over 12 seeds: `hard` → 26–28 clues, `expert` → 24–28 clues. Because
`Difficulty.expert.clueRange` is `(22, 28)`, `generate()` exits on the first attempt at
≤ 28 clues (`sudoku_generator.dart:27`). **The two hardest tiers are effectively the same
puzzle today.** Worse, digging checks only *uniqueness*, never a logical path, and
`rateDifficulty` explicitly returns `expert` when backtracking was required — so the app
ships puzzles to its most engaged users that cannot be solved by logic at all.

### 1.4 the data-integrity inventory

Six independent defects, all verified, all silent. `IntelligenceEngine` **acts** on this
data — difficulty recommendation and daily insights — so the app is making decisions about
players from partly-garbage input.

| # | defect | evidence |
|---|---|---|
| 1 | `fromSaved` restores no `history` → backgrounding destroys the undo stack | `game_cubit.dart:801-849` |
| 2 | `_cellPlacementDeltas`, `_mistakeCells`, `_undoCount`, `_notesEverUsed`, `_longestPause` all reset on resume → quality score and velocity wrong for every resumed puzzle | `saveCurrentGame` `:768-794` persists none of them |
| 3 | `_techniques` not restored → resumed puzzles show an empty `puzzleDna` on the complete screen | `:33`, `:720`, consumed at `game_screen.dart:94` |
| 4 | **Placement timing uses wall clock, not elapsed.** Background overnight, place one digit → a `28800` delta enters `solveTimes` and `longestPauseSeconds` | `_recordPlacementTiming` uses `DateTime.now()` |
| 5 | `undo()` never decrements `mistakeCount` nor pops `_mistakeCells` | `:556-633` |
| 6 | **The daily puzzle is not the same for everyone.** It seeds off device-local `DateTime.now()`, so timezones diverge. README:46 claims "same for everyone" | `game_screen.dart:385`, seed at `sudoku_generator.dart:59` |

Plus three UX defects of the same class as the hint bug — controls that do something other
than what the screen implies:

| # | defect | evidence |
|---|---|---|
| 7 | **Starting any game silently destroys the in-progress puzzle.** The resume bar renders directly above the difficulty cards that delete it | `home_screen.dart:308`, `:316`; bar at `:112`, cards at `:262-299` |
| 8 | `erase()` has the same silent-return-on-no-selection bug as `useHint` | `game_cubit.dart:475-481` |
| 9 | `longPressLabel: 'auto-fill'` is declared, assigned, passed — and **never referenced in `build()`**. The affordance meant to reveal auto-fill-notes was never rendered, making the feature undiscoverable | `game_toolbar.dart:53`, `:85`, `:97` |
| 10 | A mandatory 1500 ms loader floor on every new game, even when generation is instant | `game_screen.dart:377` |

---

## 2. decisions

| # | decision | rationale |
|---|---|---|
| 1 | Teaching is the spine; compete/share is a later, separate spec | Ranking across incomparable puzzles is meaningless until difficulty is honest |
| 2 | Hints are unlimited, free, escalating | Rationing teaching is a dark pattern in a no-bs app. Depth taken is recorded so quality score stays meaningful |
| 3 | Generation guarantees a logical path, applied **under the existing four labels** | Removes guess-only puzzles without redefining a label users have personal records attached to |
| 4 | Unprompted help is limited to stuck detection | Post-solve debrief and wrong-turn warning declined |
| 5 | Instant wrong-digit oracle stays default; opt-in no-oracle mode added | Protects recently acquired users; mode recorded per puzzle |
| 6 | Data integrity first, then engine, then hints, then a measurement gate | The defect inventory is larger and more certain in value than the speculative half |
| 7 | Hints may teach eliminations, with one-tap apply-to-notes | Pruning is most of the actual skill |
| 8 | Three plain switches, no presets | Escalation self-adjusts; presets were machinery around a problem interaction design solves free |
| 9 | Four difficulty labels retained, honest technique subtitle added | Never silently redefine a label with a personal best attached |
| 10 | The upper ladder and mastery profile are gated on measured rung usage | Both reviews independently judged them speculative; the measurement costs one analytics field |

Backend note: if the compete layer needs a backend it uses Firebase only —
`firebase_core`, `analytics`, `crashlytics`, `messaging` are already dependencies. Out of
scope here.

---

## 3. engine layer

New package, pure Dart, no Flutter imports:

```
lib/engine/deduction/
  units.dart                 precomputed unit + peer index tables
  candidate_grid.dart        CandidateGrid
  deduction.dart             Deduction, DeductionKind, Technique, TechniqueTier, UnitRef
  deduction_engine.dart      DeductionEngine, SolvePath
  techniques/
    naked_single.dart
    hidden_single.dart
    naked_pair.dart
    hidden_pair.dart
    pointing_pair.dart
    box_line_reduction.dart
```

**Six rules, not twelve.** Naked/hidden single plus pairs plus intersections cover the
overwhelming majority of teaching value. Swordfish, xy-wing, simple coloring and hidden
triples serve puzzles casual players never open, for players who already know those
techniques. They are gated behind R4's measurement (§9).

### 3.1 units.dart

Static const tables computed once: per cell, its row/column/box unit ids and its 20
peers; plus the 27 units as cell-index lists. The ladder runs thousands of times per
generated puzzle — recomputing row/col/box per query is the dominant avoidable cost.

### 3.2 CandidateGrid

Mutable. 81 nine-bit masks in a `Uint16List`, plus a parallel `Uint8List` of placed
digits.

```dart
class CandidateGrid {
  factory CandidateGrid.fromBoard(SudokuBoard board);
  int  candidateMask(int idx);
  Iterable<int> candidatesOf(int idx);
  int  candidateCount(int idx);
  int  placed(int idx);
  bool eliminate(int idx, int digit);   // true only if it changed something
  void place(int idx, int digit);       // sets digit, clears own mask, eliminates from peers
  bool get isSolved;
  bool get isBroken;                    // a cell with no digit and no candidates
  CandidateGrid clone();
}
```

Deliberately **separate** from `SudokuBoard`, which is a value type with `==`/`hashCode`
over all 81 cells (`sudoku_board.dart:90-100`) and is used as a `copyWith` identity in
`sudoku_grid.dart:17`. Adding mutable elimination state to it would break both.

### 3.3 Deduction

The explanation payload, deliberately **not** prose:

```dart
enum DeductionKind { placement, elimination }

class Deduction {
  final Technique technique;
  final DeductionKind kind;
  final List<(int cellIdx, int digit)> targets;   // to place, or to remove
  final List<int> witnesses;                       // the cells that prove it — highlighted
  final UnitRef? unit;                             // for the R1 "look here" nudge
}
```

**`Deduction` and `UnitRef` require value equality**, with `targets` and `witnesses`
sorted on construction so comparison is order-independent. Four features depend on it:
hint pinning (§5.3) compares `prev.activeHint != curr.activeHint`; hint invalidation is
literally an equality test against a freshly-found deduction; `activeHintJson`
round-tripping; and any future dedup for mastery counting. Without it, identity
comparison makes pinning fire on every recompute.

Copy is generated in the presentation layer, keeping the voice rule out of the engine and
making the ladder testable without string matching.

### 3.4 the ladder

```dart
abstract interface class TechniqueRule {
  Technique get technique;
  TechniqueTier get tier;
  Deduction? find(CandidateGrid grid);
}
```

| tier | techniques | maps to label |
|---|---|---|
| `singles` | naked single, hidden single | easy |
| `pairs` | naked pair, hidden pair | medium |
| `intersections` | pointing pair, box-line reduction | hard, expert |

`hard` and `expert` share a tier ceiling for now and are separated by the clue-count
guard rails (§4.2) — which is honest, and strictly better than today, where they are the
same puzzle (§1.3). R4 may give `expert` its own tier if the data supports building fish.

### 3.5 DeductionEngine

```dart
class DeductionEngine {
  Deduction? nextStep(CandidateGrid grid, {TechniqueTier maxTier});
  List<Deduction> allStepsAt(CandidateGrid grid, {TechniqueTier maxTier});
  SolvePath solve(CandidateGrid grid, {TechniqueTier maxTier});
}

class SolvePath {
  final List<Deduction> steps;
  final bool complete;              // reached a full board with no guessing
  final Technique? hardestTechnique;
}
```

`nextStep` powers hints and stuck detection. `solve` powers generation grading.
`allStepsAt` exists for attribution and is unused until R4.

### 3.6 what gets deleted

`SudokuSolver` keeps `solve` and `hasUniqueSolution` (still needed as a fallback and by
tests). `solveWithTechniques`, `rateDifficulty`, and the `SolveTechnique` enum are
deleted. Full blast radius — larger than v1 admitted:

- `lib/core/routing/route_args.dart:14` (`CompleteRouteArgs.techniques`) and `:34-48`
  (`puzzleDna`). `puzzleDna` maps `backtracking → 'advanced logic'` — a concept with **no
  successor**, since the new engine never guesses. The getter is rewritten against
  `Technique`.
- `game_cubit.dart:46, 64, 84, 105` — all four factories call `solveWithTechniques`; plus
  `:33`, `:35`, `:720`, and `game_screen.dart:94`.
- `test/engine/sudoku_solver_test.dart:77-93` — two groups deleted.

`SudokuBoard.candidates()` stays. `_isValidCandidate` (`game_cubit.dart:290-303`) is
**deleted** and `autoFillNotes` reroutes through `CandidateGrid`, so the codebase ends
with two candidate notions rather than three.

---

## 4. generation

### 4.1 replace the uniqueness check, do not add to it

Measured on a replica of `_digHoles` (`sudoku_generator.dart:92-197`), ms per puzzle:

| target clues | uniqueness only (today) | uniqueness + gate | **gate alone** |
|---|---|---|---|
| 36 | 4.3 | 3.8 | **1.8** |
| 30 | 40.4 | 32.4 | **7.4** |
| 26 | 244.0 | 207.4 | **47.8** |
| 22 | 1968.9 | 1920.1 | **279.1** |

All the time is in `hasUniqueSolution` → `_solveWithCount(maxSolutions: 2)`, exponential
solution-counting called 25–470 times per puzzle. The tier gate is nearly free — sometimes
net negative, because rejected removals keep the clue count higher and make later
backtracking cheaper.

And the uniqueness check is **redundant once the gate passes**: every ladder rule is a
sound forced deduction, so a `SolvePath` with `complete == true` proves the solution
unique. `_digHoles` already receives the ground-truth `solution`, so:

```dart
// replaces hasUniqueSolution — stronger and ~5x cheaper
final path = engine.solve(CandidateGrid.fromBoard(puzzle), maxTier: targetTier);
final ok = path.complete && solvedBoard == solution;
```

This is *strictly stronger*: it also catches an unsound rule, which bare
`hasUniqueSolution` cannot.

**Therefore `PuzzlePool`, the `workmanager` top-up, consumed-row pruning and the retention
window are all cut.** Generation runs at or below today's cost, which is already shipped
and already covered by `GridLoader`. (The pool would also have been Android-only:
`ios/Runner/Info.plist` declares no `BGTaskSchedulerPermittedIdentifiers` and no
`UIBackgroundModes`.)

Caveat carried honestly: the benchmark's proxy ladder was singles-only and allocated two
`Set<int>` per cell per call via `candidates()`, while the real ladder has six rules but
runs on bitmasks with precomputed peers. The two effects push opposite ways. **R1 exits
with a re-measured number on the real engine**, and R2 only proceeds if generation p95
stays under 800 ms for `expert` on a mid-range Android device.

### 4.2 clue ranges stay as guard rails

`Difficulty.clueRange` is **not** deleted. Maximal digging saturates — measured, every
tier converges to 23–27 clues, which would make `easy` a 23-clue singles grid and a
40-minute scan for a beginner. The existing loop bounds (`:98`, `:129`, `:139`, `:160`,
`:182`) and the `generate()` retry exit (`:16`, `:27`) all stay.

The tier is a **ceiling, not a target**. Digging with ceiling T yields a distribution over
tiers ≤ T; hitting T specifically requires **rejection sampling** — generate, grade,
discard if below target, within a bounded *attempt count* (never a wall-clock timeout,
see §4.3). If the budget is exhausted, ship the puzzle at **the tier it actually is** and
label it truthfully. Never silently mislabel.

180° rotational symmetry is preserved in both dig passes (`:112-124`, `:170-180`) and
`test/engine/sudoku_generator_test.dart:63-81` continues to assert it for every
difficulty. Tier-tight digging under strict pair symmetry has lower yield; R1's
measurement reports that yield rate.

### 4.3 daily puzzle

**Fix first (R0): the daily is not currently the same for everyone.** It seeds off
device-local `DateTime.now()` (`game_screen.dart:385`, seed at `:59`), so timezones
diverge. Switch to UTC. This alone makes README:46 true for the first time.

Determinism of seeded generation is otherwise sound and was verified: `candidates()`
returns an insertion-ordered `LinkedHashSet` built ascending, so
`.toList()..shuffle(random)` and `for (final val in cands)` are both deterministic; no
floating point anywhere in generation; and changing how many values are drawn from
`Random` does not matter, since the sequence is consumed in fixed program order for a
fixed seed.

Two constraints follow:

- The rejection-sampling budget on the daily path **must be a deterministic attempt
  count**, never wall-clock. A timeout would give a fast phone one puzzle and a slow phone
  another for the same date.
- The generation change alters daily output, so a `dailyAlgorithmV2Cutover` date constant
  gates it. Set it to **release + 3 days**, not release day: `_startDaily`
  (`home_screen.dart:316-323`) deletes the save and regenerates, so on the cutover day
  itself updated and non-updated users would get different puzzles — exactly what the
  cutover exists to prevent. Once shipped it never moves backward.

v1 proposed retaining the v1 algorithm permanently with pinned golden tests. **Cut.**
There is no past-date daily UI — the only entry point is `/game/daily` with today's date —
and an in-progress daily is already protected because `SavedGames` stores the actual board
and solution. If a daily archive is added later, it must pin the algorithm version per
date at that point.

### 4.4 labels and rotation

Four labels retained, meaning preserved, honest subtitle added:

| label | subtitle |
|---|---|
| easy | singles only |
| medium | pairs |
| hard | intersections |
| expert | intersections, fewest clues |

`home_screen.dart:348` `_clueRanges` is replaced by these subtitles — it is a duplicated
hardcoded copy of `Difficulty.clueRange` and would become false advertising on the primary
CTA. The existing Mon/Tue easy → Sun expert rotation is **unchanged**, so daily-only
players — likely the most loyal segment — see no step change.

No `master` tier. `home_screen.dart:241-303` hand-unrolls `difficulties[0..3]` into two
fixed rows, and `intelligence_engine.dart:17-36` walks `Difficulty.values` by index and
would promote players onto a new top tier as a cliff. Both stay untouched.

---

## 5. hint system

### 5.1 selection awareness

Board-scoped but selection-aware, which turns the reported bug into a teaching moment:

- **nothing selected** → next provable step anywhere.
- **selected and provable now** → explain that cell. Respects intent.
- **selected but not yet provable** → say so: `nothing provable there yet.` then offer the
  board-wide step. Beginners do not know that not every empty cell is solvable yet.
- **selected cell is a given, or already correct** → falls through to the board-wide step.

The hint control is never disabled. There is always a next nudge.

### 5.2 escalation rungs

| rung | content |
|---|---|
| R1 locate | the unit only — `there's something in box 4.` |
| R2 narrow | highlights the target cell. no digit, no name |
| R3 explain | names the technique, highlights the **witness** cells, one dry sentence |
| R4 apply | places the digit, or writes the eliminations into notes |

With `hints just answer` (§6) the button jumps straight to R4.

### 5.3 stability

The active `Deduction` is **pinned in `GameState`** (`activeHint`, `hintRung`), never
recomputed per tap — otherwise tap 1 says box 4 and tap 2 jumps to box 7. It clears when
all `targets` are satisfied, or when a freshly-found deduction no longer equals it (which
requires §3.3's value equality). Undo of a hint restores the prior `activeHint` and
`hintRung`, carried on the action.

### 5.4 elimination lessons

R4 on an elimination first fills basic candidates (via `CandidateGrid`) for un-noted cells
in the affected unit, then applies the eliminations — otherwise "remove 4 and 7" is
meaningless on an empty grid. Both steps are one undoable action.

### 5.5 copy

`lib/features/game/hint_copy.dart` maps `(Deduction, rung)` to a string. All copy lives
there — lowercase, dry, calm, no exclamation points.

### 5.6 accounting

`hintsRemaining` is retired from `GameState` in R3, replaced by `hintsUsed` and
`hintDepthTotal` (sum of rungs taken), so an R1 nudge costs far less than a full R4 reveal.

This changes the quality-score formula, so `formulaVersion` becomes 2 **in R3**. v1 called
the column "precedent"; it has zero writers and zero readers, so every read path is
net-new work and must gain a version filter:

`storage_service.dart` — `getAvgQualityScore:264`, `getAvgQualityByDifficulty:284`,
`getCountByDifficulty:271`, `getBestTimeByDifficulty:297`, `getRecordsForDifficulty:85`;
and `intelligence_engine.dart:19-36` (`recommendDifficulty`, whose `> 80` / `< 45`
thresholds would otherwise mix v1 and v2 scores) plus `:190-220`.

Note `SavedGames.hintsRemaining` is `integer()()` — **not nullable, no default**
(`app_database.dart:82`) — so it is a required companion field. R3 writes a constant `0`
rather than attempting a table rewrite.

---

## 6. settings — three switches, no presets

Escalation self-adjusts: an expert taps once, a beginner taps four times. Presets,
per-row overrides, the onboarding question and the existing-user upgrade card are all cut.

| switch | default | effect |
|---|---|---|
| `hints explain` | on | off = the button jumps straight to R4, today's behavior |
| `flag mistakes instantly` | on | off = the no-oracle mode; a digit reddens only on an actual rule violation |
| `nudge when i'm stuck` | on | off = no unprompted help at all |

Defaults reproduce today's experience except that hints now explain, which is strictly
more informative and cannot burn a scarce resource. `flag mistakes instantly` and the
puzzle's coaching state are recorded per record for the future compete layer.

---

## 7. mastery profile — deferred, and reduced

v1's headline copy — `pointing pair — seen 34. spotted unaided 3.` — **cannot be produced
by v1's algorithm.** Elimination hints write notes, and note actions advance the replay
without attribution, so attribution only ever fires on placements. "Spotted unaided" is
structurally unobservable for every elimination technique, which is all of `pairs` and
`intersections`.

Attribution over wrong digits was also undefined, and worst in the no-oracle mode this
spec adds. Wrong digits stay on the board (`game_cubit.dart:362-431`) and `undo()` **pops**
history rather than appending an inverse (`:563-564`), so undone actions leave no trace and
surviving entries reference board states that no longer exist. Applying a wrong digit to
the grid strips the true digit from a peer, which can drive a cell to zero candidates —
after which every later placement falls into "ahead of the ladder" and all real credit is
lost.

**Deferred to R4**, gated on measurement. If built, the contract is:

- Replay applies only placements matching `solution`; a mismatching `PlaceNumber` is a
  no-op for both grid and attribution. Documented as "attribution reasons about the
  correct board, not the player's board."
- `isBroken` must never arise during replay; asserted by test.
- `maxTier` for attribution is the **full ladder**, not the puzzle's tier, or a player's
  above-tier insight is invisible.
- Metrics are `encountered` and `assisted` only. **No "spotted unaided" claim for
  elimination techniques.**
- `UseHint` carries `technique` and `rung`. Both are added in **R3**, not here — `rung` is
  needed by §5.3's undo restoration regardless of whether attribution is ever built — and
  R4 only starts reading `technique`.
- `aheadOfLadderCount` moves off `PuzzleRecords`, which is insert-only:
  `StorageService.saveRecord` is `Future<void>` over `insert` (`storage_service.dart:27-30`)
  and never returns the autoincrement id, so a value computed after the complete screen
  loads has no update path. It lives on the profile aggregate instead.
- `resetAllData` (`storage_service.dart:321-337`) enumerates tables by hand and must be
  extended, or "delete all my data" silently leaves the mastery profile behind.

---

## 8. stuck detection

**Depends on R0 defect #4.** §9's threshold is a personal p90 over
`PuzzleRecords.solveTimes`, and those deltas are wall-clock — so a single overnight
backgrounding injects a `28800` and poisons the threshold upward permanently. Records
written before the timing fix are excluded from the pool via a data-version marker.

Fires when **all** hold:

- the `nudge when i'm stuck` switch is on, and
- time since last placement (measured from `state.elapsed`, not wall clock) exceeds the
  player's personal p90 for this difficulty, and
- that pause exceeds a 45-second floor, and
- `nextStep()` returns a deduction, and
- fewer than 3 nudges have fired this puzzle, and
- at least one placement has occurred since the last nudge.

The p90 pools every inter-placement delta across that player's records at the same
difficulty. With fewer than 3 qualifying records, a flat 90 seconds is used.

Presentation: one dismissible line near the grid — `there's something in row 7.` Never a
modal. `GameState` gains `stuckNudge` and an elapsed-at-last-placement field (nothing
currently records it). `buildWhen` on the grid must exclude `stuckNudge` while **adding**
`activeHint`/`hintRung` for R2/R3 highlighting; `game_toolbar.dart:16-19` currently keys on
`hintsRemaining`, which §5.6 retires.

---

## 9. the measurement gate

`firebase_analytics` is a dependency and `Log.hintUsed` already exists. R3 adds the rung
reached to that event. After two weeks of data, R4 decides:

- **if more than 10% of hint-using sessions escalate past R1**, build the upper ladder
  (swordfish, xy-wing, coloring), give `expert` its own tier, and build the mastery
  profile per §7.
- **if 10% or fewer do**, the upper ladder and mastery profile are never built. R3 was the
  product.

The threshold is stated numerically on purpose. "A meaningful share" is the kind of phrase
that resolves itself in favour of building the thing.

Cost of the gate: one analytics field. Cost of guessing wrong: several waves.

---

## 10. data model

Schema numbers are **assigned at ship time**, not here — waves may reorder, and v1's
hardcoded 9-through-12 would break if R3 shipped before R2. Each wave takes the next free
`schemaVersion` and follows the existing `if (from < N)` + `customStatement('ALTER TABLE …')`
pattern (`app_database.dart:135-177`). All changes additive; no column dropped.

**R0 — `SavedGames`:** `history` (JSON), `placementDeltas`, `mistakeCells`, `undoCount`,
`usedNotes`, `longestPauseSeconds`, `techniques`. `PuzzleRecords`: `timingVersion`
(default 1; 2 = elapsed-based deltas).

`saveCurrentGame` writes all of them and `fromSaved` restores all of them into both
`GameState` and the cubit's instance fields.

**Write strategy matters.** `_autoSave()` fires on every placement, note toggle, erase,
mode toggle and auto-fill (`game_cubit.dart:287, 442, 472, 500, 507, 633`), and
`StorageService.saveGame` (`:237-244`) does delete-all + insert in a transaction, then a
re-select and a stream broadcast. `history` grows monotonically and every `AutoFillNotes`
carries a full `previousNotes` map (~1–2 KB each, and auto-fill is repeatable). Naive JSON
would re-encode and rewrite 50–150 KB per tap. Therefore: **autosave is debounced (250 ms
trailing) and history is written as a compact non-JSON encoding.** §12 asserts a budget.

`GameAction` becomes serializable: each variant gains `toJson()` and a `type`
discriminator, with a `GameAction.fromJson` factory.

**R2 — `PuzzleRecords`:** `hardestTechnique` (nullable), `tierVersion` (default 1).
**`SavedGames`** gains the same two in R2, not R3 — they are known at generation, so a
puzzle resumed during R2 would otherwise record `hardestTechnique = null` regardless of
what was played. Same defect class as §1.4 #3.

**R3 — `GamePreferencesTable`:** `hintsExplain` (default true), `nudgeWhenStuck` (default
true). `instantOracle` (default true). **`PuzzleRecords`:** `hintDepthTotal` (default 0),
`oracleEnabled` (default true), `hintsExplainEnabled` (default true).

**`SavedGames` also gains, in R3:** `hintsUsed`, `hintDepthTotal`, `activeHintJson`
(nullable), `hintRung`, `oracleEnabled`, `hintsExplainEnabled`. v1 omitted the per-puzzle
settings entirely, which would have reproduced the exact bug §1.4 sets out to fix — a
resumed puzzle recording defaults regardless of what was actually played.

**R4 (only if the gate opens) — `TechniqueStats`:** `technique` (pk), `encounteredCount`,
`assistedCount`, `lastSeenAt`. **`PlayerProfiles`:** `aheadOfLadderTotal`.

`DailyPuzzleCache` (`app_database.dart:61-70`) has **zero call sites** — no reads of
`getCachedDailyPuzzle`, no writes of `cacheDailyPuzzle`. It is deleted in R2 rather than
left in limbo.

---

## 11. delivery waves

### R0 — data integrity and honest controls (ship first, alone)

Every item is a verified defect, independent of the engine.

1. `useHint` works with no selection: falls back to the fewest-candidates empty cell. The
   given-cell and already-correct branches fall through instead of returning.
   `useHint` returns `bool` so the widget can move `Haptics.hint()` after success — v1
   called this a one-line move; it needs an API change.
2. Same silent-return fix for `erase()`.
3. `fromSaved`/`saveCurrentGame` persist and restore `history`, all five velocity
   counters, and `_techniques`.
4. `_recordPlacementTiming` measures from `state.elapsed`, not `DateTime.now()`.
   `timingVersion = 2` on new records.
5. `undo()` decrements `mistakeCount` and pops `_mistakeCells`.
6. Daily seeds from **UTC**.
7. Confirmation before starting a game that would discard an in-progress puzzle.
8. Render `longPressLabel`, or delete the parameter and surface auto-fill properly.
9. Delete the 1500 ms loader floor.

Hints stay capped at 3 here. R0 fixes broken controls, not the economy.

### R1 — engine

`units`, `CandidateGrid`, `Deduction` with value equality, six rules, `DeductionEngine`,
full test suite. No UI, no user-visible change. **Exit criterion: a measured generation
number on the real engine** (§4.1) and a measured tier yield rate (§4.2).

### R2 — honest generation

Replace `hasUniqueSolution` with the tier gate. Keep clue guard rails. Rejection sampling
with a deterministic attempt budget. Daily cutover constant. Delete
`solveWithTechniques`/`rateDifficulty`/`SolveTechnique` and rewrite `puzzleDna`. Replace
`_clueRanges` with tier subtitles. Delete `DailyPuzzleCache` and `_isValidCandidate`.
Proceeds only if R1's number clears the budget.

### R3 — hint system

Pinned deduction, four rungs, elimination lessons, `hint_copy`, three settings switches,
`formulaVersion` 2 with all read paths filtered, rung analytics.

### R4 — gated on measurement

Read the rung distribution. Then and only then: upper ladder, `expert`'s own tier, mastery
profile per §7's contract, stuck detection per §8.

### in parallel — cheap, high-reach, unrelated to the engine

Accessibility (`Semantics` on the grid, text-scale tolerance) — currently **zero** matches
for `Semantics`/`semanticLabel`/`textScaler` across all of `lib/`. And making the streak
freeze visible: it works (`storage_service.dart:142`), auto-applies on one missed day, and
its only trace is an analytics event — mercy already granted with no credit taken.

---

## 12. testing

**Engine**
- one golden test per rule: a grid where it is the only applicable step, asserting exact
  `targets` and `witnesses`.
- negative test per rule: `null` where it does not apply.
- `Deduction` value equality, including order-independence of `targets`/`witnesses`.
- `CandidateGrid` invariants: `place` clears the cell's own mask **and** eliminates from
  exactly its 20 peers; `eliminate` returns true only on real change; `isBroken` detects an
  empty cell.
- property test: over a corpus, `solve()` never places a digit contradicting the solution
  and never reports `complete` on an unsolved grid.

**Generation**
- labelling soundness: a puzzle labelled T is **not** solvable at `maxTier` T−1. (v1's
  "the tier is tight" test was a tautology — it re-asserted the labelling rule, since
  sound rules make the fixpoint confluent and order-independent.)
- **yield rate**: requesting T produces a puzzle labelled T in ≥ X% of attempts within
  budget, with X measured in R1 and written into this spec.
- clue counts remain inside `clueRange` for every difficulty (the existing assertion
  at `sudoku_generator_test.dart:23` keeps passing).
- 180° symmetry preserved for every difficulty.
- daily determinism: same UTC date → identical puzzle across runs; the attempt budget is
  a count, not a clock.

**Persistence**
- `GameAction` round-trip for every variant.
- resume round-trip: save mid-game, restore, undo unwinds the full stack; `_techniques`,
  velocity counters and mistake cells all survive.
- autosave budget: < 5 ms at 300 recorded actions.

**Cubit and widget**
- the reported bug: hint with no selection produces a nudge, not a no-op.
- four taps yield the same deduction at rungs 1→4.
- placing the hinted digit manually clears `activeHint`.
- stuck detection does not fire without a deduction, nor twice without an intervening
  placement, nor from a wall-clock-polluted record.
- starting a new game with a save present prompts before discarding.

---

## 13. out of scope

- compete/share layer — its own spec, after this. Firebase only.
- post-solve technique debrief; wrong-turn warning before committing a digit — both
  declined.
- sound design, new themes, puzzle variants (killer, jigsaw, thermo), home-screen widget,
  daily archive.
- monetization. Worth noting once: ad spend with no revenue model is not durable, and a
  theme pack or tip jar would violate nothing in the brand — themes are already abstracted
  behind `AppThemeColors`. Not a decision for this spec.
- `CLAUDE.md` and `README.md` are both stale: the palette section describes dark `#0A0A0A`
  with lime accent while the shipped default is the `paper` theme, and the README roadmap
  names supabase while this spec uses Firebase. Separate housekeeping.

---

## 14. risks

| risk | mitigation |
|---|---|
| R1's real-engine generation number exceeds the budget | R2 is explicitly gated on it. If it fails, fall back to grading-after-generation with honest labels — no pool |
| Tier yield is too low to fill `expert` by rejection sampling | Yield measured in R1 and written into the spec; if low, `expert` stays separated by clue count alone, which is still better than today |
| Unlimited R4 means any puzzle is auto-solvable, diluting `totalSolved` and streaks | Recorded via `hintDepthTotal`; the compete spec inherits this and must rank on assisted-adjusted results |
| `formulaVersion` 2 creates a visible discontinuity in the sparkline and `avgQuality` | Filter at every read path listed in §5.6; confirm explicitly what the sparkline renders across the boundary |
| Daily cutover mishandled | Cutover is release + 3 days, never moves backward, and the attempt budget is a deterministic count |
| The measurement gate gets skipped under enthusiasm | R4's contents are written here as conditional. Building them without the data is a spec violation, not a judgement call |
