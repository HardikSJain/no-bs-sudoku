# teaching engine — design

date: 2026-08-21
revision: 4 (r2: benchmarked engineering + product review; r3: enthusiast depth; r4: CEO review + adversarial spec review)
notation: delivery waves are **R0–R6**; hint escalation levels are **H1–H4**
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
| `Difficulty.clueRange` is removed; clue count is no longer an input | `_digHoles` is driven end-to-end by clue targets. Deleting them leaves no stopping rule; maximal digging saturates every tier to 23–27 clues, making "easy" a 40-minute beginner scan | Clue ranges **stay** as guard rails. Tier is a ceiling (r3 removed the floor-sampling this row originally proposed — see §0.1) |
| Five technique-defined tiers, `master` added | Every tier's meaning moves at once while the home screen displays old personal bests beside new puzzles. Home screen hardcodes exactly four cards | **Four existing labels kept**, meaning preserved. No `master`. Gate applied underneath |
| Mastery: `pointing pair — seen 34. spotted unaided 3.` | Unobservable. Elimination hints write notes; attribution only fires on placements. The example copy cannot be produced by the algorithm | Mastery deferred behind an instrumentation gate, and reduced to what is observable |
| Four coaching presets + per-row overrides | Escalation is already self-adjusting: an expert taps once, a beginner taps four times | **Three plain switches**, no presets, no onboarding question, no upgrade card |
| "The schema already carries `formulaVersion` as precedent" | It has zero writers and zero readers. One reference in `lib/` and `test/`: the column definition | Treated as net-new work, with read paths enumerated |
| Resume drops `history` and five counters | Correct, and incomplete — `_techniques` is a sixth, placement timing uses wall clock, and `undo()` corrupts `mistakeCount` | R0 expanded to the full inventory |

The net effect: **less engineering, more defect repair, and a gate before the speculative
half.** R0 became the headline rather than the warm-up.

### 0.1 what changed in revision 3

Revision 2 optimised for the mainstream ad-acquired audience the product review measured.
The product owner then stated a broader goal: **a sudoku enthusiast should download this
and feel it is not just another sudoku, while it still suits beginners and intermediates.**
That is a requirement, not a hypothesis, and it overturns one r2 decision.

| r2 position | why it fails the stated goal | r3 |
|---|---|---|
| Upper ladder (fish, chains) gated behind 10% rung-escalation data | An enthusiast opens `expert`, finds a puzzle solvable with pointing pairs, and leaves before ever generating that data. The gate measures an audience that has already churned | **Full ladder built now.** Twelve rules, not six |
| Difficulty tops out at `intersections` | A strong player exhausts the app in a day | **Two technique-defined tiers added above `expert`**, as new entries with no existing personal bests attached |
| Nothing serves beginner and expert through one mechanism | Depth for pros usually means a watered-down mode for everyone else | **Technique trainer**: pick the crux technique, drill it. Beginners drill hidden singles, pros drill chains — same code path |

What r3 does **not** reverse: the four legacy labels keep their exact meaning
(ceiling-only, §4.2), because protecting the acquired base and serving enthusiasts are
solved in different places. And the mastery profile stays gated — for a correctness reason
(§7), not an audience one.

This resolves the ceiling/floor tension honestly: **ceiling-only for the four legacy
labels, floor-targeted for new content.** Sampling for a floor silently makes an existing
label harder; in new content there is no established meaning to break.

### 0.2 what changed in revision 4 (CEO review, 2026-08-21)

Ran `/plan-ceo-review` in **SCOPE EXPANSION** mode. Approach decision: **ship the spec as
written** — scope and structure of R0–R5 unchanged — with expansions added on top.

**The landscape check inverted the differentiation story.** Searched the field before
challenging scope:

- **sudoku.coach** ships **27 human-style strategies across 7 tiers**, every hint
  explaining what and why. This spec proposes 12 rules and 6 tiers. *(Citation caveat: the
  search result linked a Play Store listing whose package id does not match the product
  name. The 27-technique claim is elevated to a positioning output below, so verify it
  against sudoku.coach directly before acting on the number.)*
- [Hodoky](https://amuselabs.com/resources/guides/sudoku-strategy-resources/) already has
  §4.5's technique trainer — pick a technique, every generated puzzle contains it — and
  **auto-solves up to the point the technique becomes applicable.** Ours does not.

Conclusion: explaining hints and a technique trainer are **table stakes**, not innovation.
But every competitor doing this is a website or a utilitarian tool. **Nobody occupies
enthusiast-grade engine inside a design-forward, ad-free, offline app** — and nobody
infers which technique you are personally weak at from how you actually play (§7).

**Required positioning statement.** The spec must state its position rather than implying
it. The moat is the *combination*, not the engine. Note also that 12 techniques versus 27
is a comparison an enthusiast will actually run — see the TODO on ladder expansion.

**Spec defect found (a fix, not an expansion).** §4.5's trainer must **auto-advance**:
pre-solve the puzzle up to the point the target technique becomes applicable. Without it,
drilling swordfish means grinding ~40 singles first. The competitor already solves this.

#### decisions recorded

| id | decision | rationale |
|---|---|---|
| S1-1 | ~~Dual-path unit lookup~~ → **WITHDRAWN.** `units.dart` stays a single static-const table | Moot once jigsaw is deferred (E2). The decision only ever existed to serve jigsaw |
| S1-2 | **Puzzle import gets its own wave, R6**, sequenced after R4 | Unowned work does not happen. Reuses R4's solve-path analysis view |
| S2-1 | **Partial save restore** replaces the `catch (_)` at `game_cubit.dart:842` | R0 adds a growing history blob to a payload whose failure response is silent deletion. Board and notes are required; history and counters degrade to empty. Also covers pre-migration saves |
| S2-2 | **`solve()` progress assertion + iteration cap** | A rule returning a no-op `Deduction` satisfies neither "solved" nor "stuck" — an infinite loop inside generation, i.e. an ANR |
| S3-1 | **Share card allowlist** — puzzle grid, technique spectrum, difficulty label only | The only outbound data path in the plan. Serialization test asserts no profile, streak, or stats field can leak |
| S4-1 | **Confirm before H4** | Escalation is per-tap with no guard; three quick taps fill the answer in. H1–H3 stay instant; the board-changing step needs a distinct deliberate action |
| S5-1 | **Extract `HintController` in R3** | `game_cubit.dart` is 856 lines and this plan roughly doubles it. Writing the hint logic elsewhere from the start costs nothing |
| S6-1 | ~~Doubled test matrix~~ → **WITHDRAWN.** 12 golden tests, one layout | Was the safety net for S1-1, which no longer exists |
| S12-1 | **Attribution-metric spike moves into R1**, time-boxed | Attribution is the only differentiator the landscape check left standing, and §7 proves the current metric is unobservable. Design the observable metric while the engine is fresh, not two waves later |
| S11-1 | **Full app-wide accessibility pass** | Verified: zero `Semantics`, zero `semanticLabel`, zero `textScaler` in all of `lib/`. Three new screens would land on that |
| S8-1 | **Three new log events** | Generation tier fallback, solve-loop abort, trainer budget exhaustion — all silent degradations today |

#### accepted expansions

| id | expansion | effort (human / CC) |
|---|---|---|
| E1 | **Puzzle import, manual entry → wave R6.** Grid entry *and paste-a-string*, plus analysis: logical solvability, hardest technique on the found path, technique spectrum, step-by-step path. Camera OCR deferred. See §4.6 for failure modes | 2wk / 1-1.5d |
| E2 | ~~Jigsaw variant~~ → **DEFERRED.** Accepted on a false premise (see §0.3); true cost is wave-scale, for the least distinctive variant. The whole variant question reopens as its own spec | — |
| E3 | **Puzzle DNA fingerprint + share card** — spectrum built from `SolvePath.steps` (which carries counts), **not** the doomed `puzzleDna` Set. Requires `dnaVersion` + documented canonical rule ordering, else two app versions fingerprint the same grid differently | 2wk / 1-2d |
| E4a | ~~Discoverability fixes~~ → **NOT AN EXPANSION.** Already R0 item 8 and the §11 parallel item; was double-counted. R0 #8's "or delete the parameter" now resolves to **render it** | — |
| E4b | **Input power tools, reduced** — long-press a pad digit to highlight where it can go (**peer-based candidates only**, never the post-elimination view — see §0.3); remaining-count badge per digit. Double-tap **dropped**; external keyboard **deferred** | 2-3h CC |
| E4c | **Feedback polish** — distinct haptic per hint rung; subtle pulse on the hint button when stuck | 1-2h CC |

### 0.3 adversarial spec review — 4/10, FAIL, and the corrections

The r4 expansions were sent to an independent reviewer with no visibility into the
conversation that produced them. It returned **4/10 and a FAIL verdict**. Every code claim
below was then verified directly. **Three of the errors were mine.**

| finding | verified | verdict |
|---|---|---|
| "`units.dart` already abstracts the box, so every technique works unchanged" | `lib/engine/` holds exactly three files; `units.dart` is net-new in R1 | **My error — asserted a fact about code that does not exist** |
| Box geometry is hardcoded | 10 sites: `sudoku_board.dart:35,36,65,66,113,115`; `sudoku_grid.dart:65,92,93,98,99,122` | Confirmed |
| The 20-peer invariant breaks under jigsaw | A region meets a row in 0–8 cells, so peer count varies ~16–24 per cell. §3.2's contract and §12's "exactly 20 peers" assertion both break | Confirmed |
| My technique analysis was inverted | The *inference* generalises, but pointing pair and box-line reduction **iterate the 3 rows a box spans** — a region spans up to 9. Those two need rewriting; x-wing and swordfish, which sound geometric, are the ones genuinely untouched | **My error** |
| Jigsaw needs a 13th rule | Law of leftovers has no classic analogue. Without it the ladder **over-grades** every jigsaw puzzle, §4.4's ceiling subtitles become false, and the §4.1 gate rejects far more digs — regressing the budget R2 is explicitly gated on | Confirmed, and missed entirely |
| §13 already lists jigsaw as out of scope | Line ~955 | **Contradiction with "ship the spec as written," no amendment recorded** |
| E4a was already R0 item 8 | Spec line ~816 | **My error — double-counted with a price tag** |
| E3 "reuses `puzzleDna`" | §3.6 deletes and rewrites it, and a `Set` cannot express per-technique counts | **My error** |
| `sharePositionOrigin` absent | 0 occurrences; two live share sites (`complete_screen.dart:409`, `settings_screen.dart:361`) | **Live iPad popover crash today** |
| `QualityScore.compute` requires `Difficulty` | `quality_score.dart:11` | An imported puzzle has none → no par time → no quality score |
| `onDoubleTap` taxes every tap | `sudoku_cell.dart:107` declares only `onTap`; adding double-tap forces the tap recognizer to wait out the double-tap window | Confirmed |
| Long-press digit highlight is a free hint | Showing post-elimination candidates for digit *d* reveals every hidden single for *d* instantly, outside `hintDepthTotal` — defeating the economy §5.6 calibrates | Confirmed, and missed entirely |
| Import cannot reuse §4.1's uniqueness shortcut | §4.1's proof is "a complete `SolvePath` proves uniqueness." When the ladder stalls on an imported grid you have proven nothing, so you fall back to exponential `_solveWithCount` — benchmarked at ~1969 ms *with the answer in hand* | Confirmed, and missed entirely |

#### corrections taken

**Jigsaw deferred.** Accepted on a false premise; true cost is wave-scale (per-puzzle unit
tables across 12 rule signatures, variable-arity peers, region generator, region-aware
filler, 10 sites of geometry surgery, two schema columns, a separate record namespace so
jigsaw `hard` does not pollute classic `hard` best times, plus a 13th rule) — for the
variant this review itself called least distinctive. **The whole variant question reopens
as its own spec; killer is the stronger candidate.** Cascade: S1-1's dual path is moot,
`units.dart` stays single static-const, and S6-1's doubled matrix drops back to 12 tests.

**Vision reconciled with §7, and the differentiator funded.** The r4 vision's marquee line
— *"you found the pointing pair in box 3 unaided"* — is the exact sentence §7 proves
unobservable, since pointing pair is an elimination technique. Both facts stand, so: the
metric becomes `encountered` / `assisted` plus one genuinely observable elimination
signal — **did the player's own notes change to match the elimination targets before any
hint fired?** Note deltas are already in `history`. And a **time-boxed attribution-metric
spike moves into R1** (S12-1), because attribution is the only differentiator the landscape
check left standing and it cannot stay gated behind a metric that cannot be computed.

**E4b reduced.** Double-tap dropped — duplicates auto-fill *and* taxes every tap.
External keyboard deferred (no desktop target; S11-1's accessibility pass is the better use
of that budget). Long-press highlight restricted to **peer-based candidates only**
(equivalent to today's `SudokuBoard.candidates`), never the post-elimination `CandidateGrid`
view, so it cannot leak pointing pairs or fish. It still accelerates hidden-single
scanning; that is accepted deliberately, being the most basic skill and close to what
`highlightMatching` already does.

**E4a struck** from the expansion list (already R0 #8). R0 #8's "or delete the parameter"
resolves to **render it**.

**E3 re-scoped.** Spectrum is built from `SolvePath.steps`, which carries counts. Gains a
`dnaVersion` field and a documented canonical rule ordering — the DNA is a function of the
path `solve()` picks, so without this two app versions fingerprint the same grid
differently and shared cards are not comparable. **`SavedGames.techniques` changes to
counts in R0**, before it ships, rather than a format change two waves later.

**`sharePositionOrigin` added to R0** — a live iPad crash on two existing share sites, same
defect class as the rest of R0.

### 0.4 outside voice — the corrections that survived verification

A third independent pass, with no visibility into any prior review. Every code claim below
was verified directly before acceptance.

| # | finding | verified | taken |
|---|---|---|---|
| 1 | **The `formulaVersion` filter would delete every personal best.** `getBestTimeByDifficulty` is `MIN(time_seconds) GROUP BY difficulty`; `getCountByDifficulty` is a raw `COUNT`. Neither touches the quality formula | Confirmed in `storage_service.dart` | **Fixed in §5.6.** Worst error in the document — three passes wrote decision 9 to protect personal bests, then specified the change that erases them |
| 2 | **The v2 weight 1.5 was harsher than v1 across the common range**, calibrated only at the zero point | 1 hint: v1 13 / v2 11. 2 hints: v1 6 / v2 2 | **Fixed.** Weight is `7/6`; v1 and v2 now agree at 1, 2 and 3 hints exactly |
| 3 | **`assert` is stripped in release builds** — S2-2's progress assertion would be a no-op in the only build where a hang matters | Dart language behaviour | **Accepted.** Real runtime check returning `complete: false`, never `assert`. The iteration cap becomes a **determinism-critical constant** — it governs which puzzles are rejected, therefore which dailies exist — and is documented alongside `dailyAlgorithmV2Cutover` |
| 4 | **Remote Config destroys daily determinism.** It is per-device with percentage rollout, so a 50% flip gives half your users a different daily for the same date — precisely what the cutover constant exists to prevent. Firebase is also not initialized inside `Isolate.run` | `game_screen.dart:385` | **Accepted.** The flag gates **quick-play generation only**. The daily path stays on the date constant |
| 5 | **R0's hint fallback is worse than the bug.** Today an unselected tap does nothing; R0 as written spends one of three scarce hints revealing a cell the user never pointed at | Spec §11 R0 #1 vs `game_cubit.dart` reveal path | **Accepted.** R0 **selects** the fewest-candidates cell and consumes nothing. Haptic fires on selection |
| 6 | **The H4 confirm contradicts decision 2, §6 and §8.** With `hints explain` off the button jumps straight to H4, so a confirm would fire on every hint — worse than today for the users §6 protects. §8 also says "never a modal" | Spec §6, §8 | **Scoped.** The confirm applies **only on escalation H3→H4**, never when `hints explain` is off. It is not a modal: the control's label changes to `place it`, so the second tap lands on a visibly different control |
| 7 | **Deep tiers touch five more files than §4.4b names** — `difficulty_breakdown.dart:15` hardcodes the four names, `AppThemeColors.difficultyColors` is keyed by name, `parSeconds`/`clueRange` have no values for new tiers, and `notification_service.dart` interpolates `preferredDifficulty` into copy: *"3 days since your last solve. **chains** difficulty is waiting."* | All confirmed | **Accepted.** `fish` and `chains` stay **out of the `Difficulty` enum** — a separate `DeepTier` type with its own routing. Matches §4.4b's own "they do not join the main difficulty grid" |
| 8 | **`HintController` cannot work as specified.** §5.3 requires hint state pinned in `GameState`; a controller either breaks that or is an empty namespace with an extra object `fromSaved` must reconstruct in sync | Spec §5.3 vs S5-1 | **S5-1 reversed.** Replaced by a **stateless `HintResolver`** — `(CandidateGrid, selection) → Deduction?`. State stays in `GameState`, mutation stays in `GameCubit` |
| 9 | **Trainer auto-advance is an unspecified game mode, not a fix.** A puzzle with 40 cells pre-filled and finished in 90s scores 100 against `parSeconds`; pre-solved cells may be erasable; nobody decided whether it writes a record | `quality_score.dart`, `storage_service.dart` | **Decided.** Trainer solves write **no** `PuzzleRecords` row, never touch `totalSolved` or streaks, and pre-solved cells are `given` |
| 10 | **Import cannot guarantee the invariant `GameState` requires.** It needs a `solution` board; an imported grid may have none or many. `_solveWithCount` has no node cap, so adversarial input is unbounded backtracking on the main path | `game_state.dart`, `sudoku_solver.dart` | **Accepted.** A non-unique grid is **analysis-only and never enters `GameState`**. `_solveWithCount` gains a node budget |
| 11 | **The accessibility pass is scheduled to run concurrently with the waves that rewrite the files it touches.** And grid semantics cannot be written before R3 defines `activeHint`/`hintRung` | 23 files contain `Widget build` | **Sequencing fixed** (scope stays full, per S11-1): shared primitives — semantics conventions, a `Semantics(button:)` wrapper, a text-scale policy — land **before** R4/R6 write new screens; per-screen sweeps land **after** the wave that rewrites each screen. Never in parallel |
| 12 | **Debounced autosave has no lifecycle flush**, so the last action before backgrounding is lost. And §12's `< 5 ms` budget measures encoding CPU while the real cost is `saveGame`'s delete-all + insert + re-select + broadcast | `storage_service.dart:237-244` | **Accepted.** Explicit flush on `AppLifecycleState.paused`; the budget measures the full `saveGame` round trip. Partial restore lands **before** the new history encoding, with a format-version byte on the blob |

#### the finding I am not going to soften

**Nobody added up the scope, and the delivery rate says it is a multi-month plan.**
`lib/` is ~9,300 lines. Commit cadence: **96 in 2026-03, 19 in 2026-05, 5 in 2026-08** —
zero in April, June and July. The accepted work roughly doubles the codebase. No document
in this chain contains a total, so no one has been able to ask whether it ships.

**And the premise is unverified.** §1 opens "the app has product-market fit — paid
acquisition converted." Paid acquisition converting means the ad creative works; it is an
install cost, not retention. **No retention number appears anywhere in this spec, in three
reviews, or in the CEO plan** — in an app that already ships `firebase_analytics` and
`Log.*` events throughout.

Therefore, added as **R-1, before R0**: read the analytics you already collect. D1 retention,
D7, session length, hint usage, difficulty distribution, abandon rate. It is hours of work,
it is free, and it is the only thing that can tell you whether "depth, not breadth" is the
right call. Not a gate — a fact-finding step that should precede a multi-month commitment.

Related, and stated plainly rather than dressed up: §9 claims removing the r2 gate removed
its circularity. It did not — post-ship analytics measure the same absent enthusiasts, just
later and after the build is paid for. **The enthusiast bet is a conviction bet.** That is a
legitimate way to build a product. It is not a measured one, and the spec should stop
implying otherwise. Reaching that audience needs distribution work — r/sudoku, forums, the
"how do I solve this position" long tail — and neither document contains a line of it.

---

## 1. context

The app has product-market fit — paid acquisition converted and people play daily. The
next move is depth, not breadth.

### 1.0 positioning

**no bs sudoku is an enthusiast-grade engine inside a design-forward, ad-free, offline
app — and it is the only sudoku that learns which technique *you* are weak at from how you
actually play.**

Stated explicitly because the r4 landscape check found the engine alone is not a moat.
sudoku.coach explains 27 techniques; Hodoky already ships a technique trainer. Those are
table stakes. What none of them is: beautiful, ad-free, offline, and quietly observant.
The moat is the **combination**, plus retroactive attribution (§7). Every scope decision
below should be read against this sentence — if a feature does not serve it, it is
decoration.

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
| 10 | The mastery profile is gated on a correctness demonstration | Its headline metric is unobservable as designed (§7) |
| 11 | **The full twelve-rule ladder is built now, not gated** | An enthusiast who finds no depth churns before generating the data a gate would read. You cannot measure demand from an audience you already lost |
| 12 | **Two technique-defined tiers added above `expert`, on a separate shelf** | Delivers real depth without redefining any label that has a personal best attached, and keeps the primary CTA a four-choice decision |
| 13 | **Technique trainer via floor-targeted generation** | One mechanism serving the whole range — a beginner drills hidden singles, a pro drills swordfish. Nobody gets a watered-down variant of someone else's mode |
| 14 | Success is measured on shipped features, not used as a build gate | Analytics on rung depth, technique picks and deep-tier entry tell us whether the teaching lands — feedback, not permission |

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
    naked_subset.dart          pair + triple, parameterized by size
    hidden_subset.dart         pair + triple, parameterized by size
    pointing_pair.dart
    box_line_reduction.dart
    fish.dart                  x-wing + swordfish, parameterized by size
    xy_wing.dart
    simple_coloring.dart
```

**The full ladder, built now.** Revision 2 cut this to six rules on the product review's
judgement that the upper half serves 1–3% of a mainstream audience. Revision 3 reinstates
it because the stated product goal is that an enthusiast finds the app remarkable — and
the upper ladder is the difference between a strong player staying and leaving.

Two things make the reinstatement cheaper than it looks. The rules are independent
`TechniqueRule` implementations behind one interface, so they add linearly with no
architectural change. And the same ladder that makes a chains-tier puzzle *possible* is
what lets the trainer (§4.5) teach a hidden single to a beginner — one mechanism, both
ends of the range.

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
  final UnitRef? unit;                             // for the H1 "look here" nudge
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

| tier | techniques | surfaced as |
|---|---|---|
| `singles` | naked single, hidden single | easy |
| `pairs` | naked/hidden pair, naked/hidden triple | medium |
| `intersections` | pointing pair, box-line reduction | hard, expert |
| `fish` | x-wing, swordfish | **fish** (new, §4.4) |
| `chains` | xy-wing, simple coloring | **chains** (new, §4.4) |

`hard` and `expert` share the `intersections` ceiling and are separated by clue count
(§4.2) — strictly better than today, where they are literally the same puzzle (§1.3), but
not a technique distinction. The depth an enthusiast wants lives in the two new tiers
rather than in a redefinition of `expert`.

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
`allStepsAt` exists for attribution and is unused until R5.

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
`Set<int>` per cell per call via `candidates()`, while the real ladder has twelve rules but
runs on bitmasks with precomputed peers. The two effects push opposite ways. **R1 exits
with a re-measured number on the real engine.**

The budget is **derived, not invented**: R2 proceeds only if generation p95 is *no worse
than today's shipped cost*, measured on the same device in the same run. Today's generator
benchmarks at `expert` median 324 ms / max 444 ms, and that is already covered by
`GridLoader`. Holding at or below it means the change is free to users by construction —
which is a defensible bar, unlike a round number picked because it sounded reasonable.

### 4.2 clue ranges stay as guard rails

`Difficulty.clueRange` is **not** deleted. Maximal digging saturates — measured, every
tier converges to 23–27 clues, which would make `easy` a 23-clue singles grid and a
40-minute scan for a beginner. The existing loop bounds (`:98`, `:129`, `:139`, `:160`,
`:182`) and the `generate()` retry exit (`:16`, `:27`) all stay.

The tier is a **ceiling, and only ever a ceiling.** Digging with ceiling T yields a
distribution over tiers ≤ T, and that distribution is left alone. There is no rejection
sampling and no floor.

This is load-bearing, so stated plainly: **sampling for a floor would make every label
harder than it is today.** Today's `medium` is a 30–33 clue puzzle that typically needs
nothing past a hidden single; forcing it to genuinely require a pair changes what `medium`
means to someone who has played it for months — the exact harm §2 decision 9 exists to
prevent. Perceived difficulty stays governed by `clueRange`, precisely as it is today.

What the gate therefore buys is one thing, and it is worth having on its own: **every
puzzle is guaranteed solvable by logic, with no guessing, within its ceiling.** That is
the defect from §1.3, and it is fixed.

What it does **not** buy: `hard` and `expert` share the `intersections` ceiling and remain
separated by clue count alone, so they are still the same *kind* of puzzle. Distinguishing
them by technique lives in the new deep tiers (§4.4b), not in a redefinition. Do not describe
R2 as "difficulty is now honest" — describe it as "no puzzle requires a guess."

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

Four labels retained, meaning preserved, honest subtitle added. The subtitles state a
**ceiling**, not a requirement — phrasing matters, because "medium — pairs" would promise
a puzzle that needs pairs, and §4.2 explicitly does not deliver that:

| label | subtitle |
|---|---|
| easy | never needs more than singles |
| medium | never needs more than pairs |
| hard | never needs more than intersections |
| expert | never needs more than intersections, fewest clues |

`home_screen.dart:348` `_clueRanges` is replaced by these subtitles — it is a duplicated
hardcoded copy of `Difficulty.clueRange` and would become false advertising on the primary
CTA. The existing Mon/Tue easy → Sun expert rotation is **unchanged**, so daily-only
players — likely the most loyal segment — see no step change.

### 4.4b the deep tiers — new, additive, never a redefinition

Two technique-defined tiers are added **above** `expert`. They are new entries: nobody has
a personal best in them, no stats row moves, no existing label changes meaning.

| tier | requires | subtitle |
|---|---|---|
| fish | x-wing or swordfish | needs a fish |
| chains | xy-wing or coloring | needs a chain |

Unlike the four legacy labels these are **floor-targeted** (§4.5) — a `fish` puzzle that
did not actually require a fish would be a lie, and this is the audience least willing to
be lied to. Named by technique deliberately: an enthusiast reads "chains" as a promise,
and a beginner who does not recognise the word correctly infers it is not for them yet.

**They do not join the main difficulty grid.** `home_screen.dart:241-303` hand-unrolls
`difficulties[0..3]` into two fixed rows; six cards would mean three rows and would put
`chains` in front of every beginner as though it were a normal choice. Instead they live
in a separate, visually distinct section below — a "going deeper" shelf. That keeps the
primary CTA a four-choice decision and makes the deep tiers feel like a discovery rather
than a wall.

`intelligence_engine.dart:17-36` `recommendDifficulty` walks `Difficulty.values` by index
and would otherwise promote a player from `expert` straight onto `fish` on a 3-of-5
quality streak — a cliff, not a step. **`recommendDifficulty` is clamped to `expert`.** The
deep tiers are entered deliberately, never by recommendation.

### 4.5 technique-targeted generation — the trainer

The one mechanism that serves beginners and experts through the same code path: generate a
puzzle whose **crux** is a named technique.

```dart
({SudokuBoard puzzle, SudokuBoard solution}) generateTargeting(Technique t, {int? seed});
```

Implementation is rejection sampling with a *floor*: dig with ceiling = `t.tier`, run
`solve`, and accept only if `path.steps` contains at least one deduction using `t` **and**
the puzzle is not solvable with `t` removed from the ladder. The second condition is what
makes it a genuine crux rather than an incidental appearance.

This is precisely the floor-targeting §4.2 forbids for legacy labels — and it is safe here
for the same reason it is unsafe there: new content has no established meaning to break.

**Trainer mode** exposes it directly. Pick a technique, get puzzles built around it:

- a beginner drills `hidden single` until spotting them is automatic
- an intermediate drills `pointing pair`
- an enthusiast drills `swordfish` or `xy-wing`

Same feature, same generator, no watered-down variant for anyone. The hint system already
explains every technique in the ladder (§5), so the trainer needs no separate teaching
content — it is the existing engine pointed at one rule.

Cost control: floor-targeting has materially lower yield than ceiling digging, and the
yield varies sharply by technique (a swordfish crux is rare). Trainer puzzles are
therefore generated **on demand with a bounded attempt count**, and if the budget is
exhausted the app says so plainly rather than shipping a puzzle that lacks the crux. R1
measures per-technique yield and that table is written into this spec before R5 starts.

#### auto-advance (r4 fix — §4.5 as originally written was unusable)

Digging with ceiling `t.tier` leaves the puzzle full of lower-tier work, so drilling
swordfish would mean solving ~40 singles first. The fix must be stated precisely, because
"pre-solve until the technique applies" is ambiguous — at a lower-tier stall the applicable
technique may be a **same-tier sibling** (`fish` holds both x-wing and swordfish).

**Rule: apply the fixpoint of (full ladder ∖ {t}), then stop.**

Provable from two properties the spec already asserts. §4.5's crux condition guarantees the
puzzle is *not* solvable with `t` removed, so that fixpoint stalls. §12 asserts sound rules
make the fixpoint confluent and order-independent, so the stall state is unique. The full
ladder does solve the puzzle, therefore `t` is applicable at the stall.

Three consequences that must be handled:

- **The scaffolding is mostly eliminations, not placements.** The trainer must hand the
  player a seeded **candidate/notes state**, or the swordfish is invisible from the board.
  That means the puzzle is no longer reconstructible from a clue string alone, and
  `SavedGames.notes` carries it.
- **Pre-solved cells are not givens.** `state.isGiven` gates hints
  (`game_cubit.dart:518`), erase, mistake counting and rendering. A **third cell class** is
  required — given / pre-solved / player-placed — or the player can erase the scaffolding.
- **By construction the stall state has exactly one applicable technique**, so a trainer
  puzzle is a *one-move drill*, not a full puzzle. That is the intended product: repetition
  of the pattern, not another full solve.

### 4.6 puzzle import — failure modes (R6)

§4.1's uniqueness shortcut **does not transfer to import.** That argument is "a complete
`SolvePath` proves uniqueness." For a user-supplied grid, when the ladder stalls you have
proven nothing.

| case | detection | user sees |
|---|---|---|
| duplicate digit in a unit | `SudokuBoard.isValid` per keystroke | the offending cells mark immediately; analysis stays disabled |
| consistent but unsolvable | `SudokuSolver.solve` returns null | `no solution. check your entry.` |
| multiple solutions | `_solveWithCount(maxSolutions: 2)` — the exponential path, benchmarked ~1969 ms **with the answer in hand**; a typed grid is worse | `more than one answer fits. this isn't a valid puzzle.` |
| budget exhausted | bounded attempt count in an isolate | `couldn't finish checking this one.` — never an indefinite spinner |

Uniqueness counting runs **on an isolate with a bounded budget**. R0 #9 deletes the
1500 ms `GridLoader` floor, so import needs its own progress affordance rather than
inheriting one.

**Imported puzzles are excluded from `PuzzleRecords`, streaks and all stats.** They have no
`Difficulty`, so no `parSeconds`, so no quality score (`quality_score.dart:11`). Including
them would corrupt exactly the data R0 exists to repair. Import is an analysis tool, not a
scored mode.

Entry offers **both** an 81-cell grid and a paste-a-string path — typing 81 cells by hand
is the feature's real cost. Starting an imported game routes through R0 #7's
discard-in-progress confirmation.

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

Written **H1–H4** throughout, to keep them distinct from the delivery waves R0–R5.

| rung | content |
|---|---|
| H1 locate | the unit only — `there's something in box 4.` |
| H2 narrow | highlights the target cell. no digit, no name |
| H3 explain | names the technique, highlights the **witness** cells, one dry sentence |
| H4 apply | places the digit, or writes the eliminations into notes |

With `hints just answer` (§6) the button jumps straight to H4.

### 5.3 stability

The active `Deduction` is **pinned in `GameState`** (`activeHint`, `hintRung`), never
recomputed per tap — otherwise tap 1 says box 4 and tap 2 jumps to box 7. It clears when
all `targets` are satisfied, or when a freshly-found deduction no longer equals it (which
requires §3.3's value equality). Undo of a hint restores the prior `activeHint` and
`hintRung`, carried on the action.

### 5.4 elimination lessons

H4 on an elimination first fills basic candidates (via `CandidateGrid`) for un-noted cells
in the affected unit, then applies the eliminations — otherwise "remove 4 and 7" is
meaningless on an empty grid. Both steps are one undoable action.

### 5.5 copy

`lib/features/game/hint_copy.dart` maps `(Deduction, rung)` to a string. All copy lives
there — lowercase, dry, calm, no exclamation points.

### 5.6 accounting

`hintsRemaining` is retired from `GameState` in R3, replaced by `hintsUsed` and
`hintDepthTotal` (sum of rungs taken), so an H1 nudge costs far less than a full H4 reveal.

**The v2 formula, specified.** v1 and v2 of this spec both said depth "costs less than a
reveal" without giving the arithmetic, which is a TBD hiding in prose. Today
`QualityScore.compute` takes `hints` as a count and applies
`h = max(0, 20 - hints * 7.0)` — meaningless once hints are unlimited, since ten hints
scores the same as three.

v2 replaces the count with weighted depth:

```
rungCost = { H1: 1, H2: 2, H3: 3, H4: 6 }        // per hint, by highest rung reached
hintDepthTotal = Σ rungCost(highestRungReached)
h = max(0, 20 - hintDepthTotal * (7/6))           // was: max(0, 20 - hints * 7.0)
```

The weight is `7/6`, not the `1.5` revisions 1–3 used. r4 correction: 1.5 was calibrated
only at the point where both formulas hit zero, and was **harsher than v1 across the entire
common range** — at one hint v1 gave 13 and v2 gave 11; at two, v1 gave 6 and v2 gave 2.

At `7/6` a full H4 reveal costs exactly 6 × 7/6 = 7, so v1 and v2 agree at **every** old
data point: 1 hint → 13, 2 → 6, 3 → 0. An H1 nudge costs 1.17 instead of 7, so six gentle
nudges still outscore two full reveals — the depth gradient survives, with no discontinuity
to explain to anyone. The other three terms (time,
accuracy, confidence) and `Difficulty.parSeconds` are unchanged.

`formulaVersion` becomes 2 **in R3**. v1 called the column "precedent"; it has zero writers
and zero readers, so every quality-derived read is net-new work and must gain a version
filter.

**Filter these — they read `qualityScore`:** `getAvgQualityScore:264`,
`getAvgQualityByDifficulty:284`, the 14-day sparkline, and `intelligence_engine.dart:19-36`
(`recommendDifficulty`, whose `> 80` / `< 45` thresholds would otherwise mix v1 and v2)
plus `:190-220`.

**Do NOT filter these** — r4 correction, and the most damaging error caught in review:

| query | what it actually computes |
|---|---|
| `getBestTimeByDifficulty:297` | `MIN(time_seconds) GROUP BY difficulty` |
| `getCountByDifficulty:271` | `COUNT(id) GROUP BY difficulty` |
| `getRecordsForDifficulty:85` | raw record list, feeds `BestTimesCard` and the home `bestTimes` map |

None of them touches the quality formula. Filtering them, as revisions 1–3 all specified,
would **empty every existing user's personal bests on R3 update day** and repopulate only
from post-update solves. Three review passes wrote decision 9 — *never silently redefine a
label with a personal best attached* — and then specified the change that deletes them.

Note `SavedGames.hintsRemaining` is `integer()()` — **not nullable, no default**
(`app_database.dart:82`) — so it is a required companion field. R3 writes a constant `0`
rather than attempting a table rewrite.

---

## 6. settings — three switches, no presets

Escalation self-adjusts: an expert taps once, a beginner taps four times. Presets,
per-row overrides, the onboarding question and the existing-user upgrade card are all cut.

| switch | default | effect |
|---|---|---|
| `hints explain` | on | off = the button jumps straight to H4, today's behavior |
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

**Deferred to R5**, gated on the correctness demonstration in §9. If built, the contract is:

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
  R5 only starts reading `technique`.
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
`activeHint`/`hintRung` for H2/H3 highlighting; `game_toolbar.dart:16-19` currently keys on
`hintsRemaining`, which §5.6 retires.

---

## 9. the measurement gate

Revision 2 gated the upper ladder on measured rung usage. **Revision 3 removes that gate**
— the ladder and the deep tiers are now a stated product requirement, and the gate had a
fatal circularity: an enthusiast who finds no depth churns before ever producing the data
that would justify building depth. You cannot measure demand from an audience your product
already lost.

**One gate remains, on the mastery profile only, and for a correctness reason.** Its
headline metric is unobservable as designed (§7): elimination hints write notes, and
attribution fires only on placements, so "spotted unaided" cannot be computed for any
elimination technique. Before mastery is built, §7's replay contract must be implemented
and its `encountered` / `assisted` metrics shown to produce sane numbers on real solve
histories.

Instrumentation still ships in R3 regardless — `firebase_analytics` is already a dependency
and `Log.hintUsed` already exists, so adding the rung reached costs one field. It stops
being a gate and becomes what it should have been: **feedback on whether the teaching
actually lands.** If nobody ever escalates past H1, that is a signal the copy or the
escalation design is wrong, not that the ladder was a mistake.

Two further signals worth the same one-line cost: which techniques trainer users pick, and
how far down the deep tiers people get. Both directly answer whether the enthusiast bet
paid off.

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

**R5 (only if §9's correctness bar is met) — `TechniqueStats`:** `technique` (pk), `encounteredCount`,
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

`units`, `CandidateGrid`, `Deduction` with value equality, **all twelve rules**,
`DeductionEngine`, full test suite. No UI, no user-visible change.

**Exit criteria, all three measured on the real engine, written back into this spec:**
1. generation cost per legacy tier (§4.1),
2. ceiling-dig tier distribution (§4.2),
3. **per-technique floor yield** (§4.5) — how many attempts to produce a genuine crux for
   each of the twelve rules. This is what tells us whether the trainer is viable for
   swordfish, which is the rarest crux and the one an enthusiast will try first.

### R2 — honest generation, legacy labels

Replace `hasUniqueSolution` with the tier gate, ceiling-only, no floor sampling. Keep clue
guard rails. Daily cutover constant and the UTC fix's downstream effects. Delete
`solveWithTechniques`/`rateDifficulty`/`SolveTechnique` and rewrite `puzzleDna`. Replace
`_clueRanges` with the ceiling subtitles. Delete `DailyPuzzleCache` and
`_isValidCandidate`. Proceeds only if R1's number clears the budget (§4.1).

Nothing user-visible changes except that no puzzle requires a guess any more.

### R3 — hint system

Pinned deduction, four rungs, elimination lessons, `hint_copy`, three settings switches,
`formulaVersion` 2 with all read paths filtered, stuck detection per §8, rung analytics.

Stuck detection moves here from revision 2's final wave: it depends only on R0's timing fix and the engine,
and holding it behind a gate that no longer exists made no sense.

### R4 — depth (the enthusiast wave)

`fish` and `chains` tiers on the "going deeper" shelf, floor-targeted per §4.5.
`recommendDifficulty` clamped to `expert`. Trainer mode: technique picker, on-demand
floor-targeted generation with a bounded attempt count and an honest failure message.
Opt-in solve-path analysis on the complete screen — the puzzle's logical skeleton and where
the hard steps actually were, which is the payoff for this audience and stays off by
default for everyone else.

This is the wave that answers "not just another sudoku". It is deliberately last of the
required waves, because it is worth nothing on a foundation that still corrupts its own
data (R0) or ships guess-only puzzles (R2).

Also in R4: the **puzzle DNA fingerprint + share card** (E3), built from `SolvePath.steps`
with a `dnaVersion` field and canonical rule ordering, and the reduced **input power tools**
and **feedback polish** packs (E4b, E4c).

### R5 — mastery

Unblocked by R1's attribution-metric spike (S12-1) rather than gated indefinitely.
Ships once the redesigned metric — `encountered` / `assisted`, plus the note-delta signal
for elimination techniques — produces sane numbers on real solve histories.

### R6 — puzzle import

Manual grid entry and paste-a-string, with the failure modes in §4.6. Reuses R4's
solve-path analysis view. Imported puzzles never touch records, streaks or stats.

### in parallel — accessibility (full pass, S11-1)

Verified: **zero** matches for `Semantics`, `semanticLabel` or `textScaler` across all of
`lib/`. The full pass covers grid semantics with cell position and value announced, labels
on every interactive control, text-scale tolerance replacing hardcoded sizes, and contrast
verification. **Sequencing matters:** land the app-wide pass *before* R4 and R6 add three
new screens, or those screens get retrofitted too.

Also here: making the streak freeze visible — it works (`storage_service.dart:142`),
auto-applies on one missed day, and its only trace is an analytics event.

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
- **ceiling soundness** (legacy labels): every puzzle generated for label L is solvable by
  `solve(maxTier: L.ceiling)` with `complete == true`. No floor is asserted — r3 removed
  floor-sampling for legacy labels precisely so their perceived difficulty does not move
  (§4.2), so a test demanding a floor would re-introduce the bug.
  (v1's "the tier is tight" test was a tautology — it re-asserted the labelling rule, since
  sound rules make the fixpoint confluent and order-independent.)
- **crux soundness** (deep tiers and trainer, §4.5): a puzzle generated targeting technique
  `t` both uses `t` in its solve path **and** is unsolvable with `t` removed from the
  ladder. This is the assertion that makes a `fish` puzzle honestly a fish puzzle.
- **per-technique yield**: targeting `t` succeeds within the attempt budget at the rate
  measured in R1, per technique. Regression guard — a rule change that quietly tanks
  swordfish yield would otherwise surface as a trainer that just fails.
- clue counts remain inside `clueRange` for every difficulty (the existing assertion
  at `sudoku_generator_test.dart:23` keeps passing).
- 180° symmetry preserved for every difficulty.
- daily determinism: same UTC date → identical puzzle across runs; the attempt budget is
  a count, not a clock.

**Persistence**
- `GameAction` round-trip for every variant.
- resume round-trip: save mid-game, restore, undo unwinds the full stack; `_techniques`,
  velocity counters and mistake cells all survive.
- **pre-migration saves**: a `SavedGames` row written before R0 has no `history` and no
  counters. `fromSaved` must degrade gracefully — empty history, counters at zero, no
  crash — rather than relying on the `catch (_)` at `game_cubit.dart:842` that silently
  discards the save and hands the player a fresh medium game. Same for each later wave's
  added columns.
- autosave budget: < 5 ms at 300 recorded actions.

**Quality score**
- v2 formula: three full H4 reveals floor the self-sufficiency term at 0, matching the v1
  three-hint cap (§5.6).
- six H1 nudges score strictly higher than two H4 reveals.
- every read path listed in §5.6 filters by `formulaVersion`; a v1 and a v2 record in the
  same table never average together.

**No-oracle mode** (specced in v1, and until now untested)
- with the oracle off, a wrong-but-legal digit does **not** redden;
  `sudoku_grid.dart:128`'s comparison against `solution` is bypassed.
- with the oracle off, a digit that violates an actual row/column/box rule still renders as
  a conflict.
- `mistakeCount` still increments on a wrong digit with the oracle off, so quality score
  and the mistake-limit rule stay consistent between modes.
- the mode is recorded on the completed record and survives resume.

**Cubit and widget**
- the reported bug: hint with no selection produces a nudge, not a no-op.
- four taps yield the same deduction at H1→H4.
- placing the hinted digit manually clears `activeHint`.
- stuck detection does not fire without a deduction, nor twice without an intervening
  placement, nor from a wall-clock-polluted record.
- starting a new game with a save present prompts before discarding.

---

## 13. out of scope

- compete/share layer — its own spec, after this. Firebase only.
- wrong-turn warning before committing a digit — declined.
- the post-solve technique debrief was declined as an unprompted interruption, and r3
  partially reinstates it as **opt-in solve-path analysis** in R4 (§11). The original
  objection stands and is honoured: it is off by default and never appears unbidden. What
  changed is the audience — for an enthusiast this is the payoff, not an interruption.
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
| Unlimited H4 means any puzzle is auto-solvable, diluting `totalSolved` and streaks | Recorded via `hintDepthTotal`; the compete spec inherits this and must rank on assisted-adjusted results |
| `formulaVersion` 2 creates a visible discontinuity in the sparkline and `avgQuality` | Filter at every read path listed in §5.6; confirm explicitly what the sparkline renders across the boundary |
| Daily cutover mishandled | Cutover is release + 3 days, never moves backward, and the attempt budget is a deterministic count |
| **R2 changes generation for every user at once, with no revert path** | Gate the new generation behind a Firebase Remote Config flag (`firebase_core` is already a dependency; only `firebase_remote_config` is new). If yield, cost or puzzle character go wrong in the wild, flip back to clue-count digging without shipping a build. Remove the flag once R2 has been stable for two releases |
| The enthusiast bet does not land — deep tiers and trainer go unused | Cheap to detect: R3's analytics already report technique picks and deep-tier entry (§9). Unlike the removed gate this measures a *shipped* feature, so the audience exists to be measured |
| Trainer yield for rare cruxes (swordfish) is too low to be usable | Measured per technique in R1, before R4 starts. If a technique cannot be targeted within budget it is omitted from the picker rather than shipped as a control that usually fails |
| §7's mastery gate gets skipped under enthusiasm | R5's contents are written here as conditional on a correctness demonstration, not a preference. Building it without that is a spec violation, not a judgement call |

---

## GSTACK REVIEW REPORT

| Review | Trigger | Why | Runs | Status | Findings |
|--------|---------|-----|------|--------|----------|
| CEO Review | `/plan-ceo-review` | Scope & strategy | 1 | CLEAR | mode SCOPE_EXPANSION; 6 proposals, 4 accepted, 5 deferred; 0 critical gaps remaining |
| Adversarial Spec Review | subagent | Independent challenge of r4 scope | 1 | ISSUES FIXED | 4/10 FAIL → all findings corrected; 3 were authoring errors |
| Outside Voice | `/codex review` → claude fallback | Independent 2nd opinion | 1 | RAN | codex unavailable (`gpt-5.4` unsupported on ChatGPT account); claude subagent used |
| Eng Review | `/plan-eng-review` | Architecture & tests (required) | 0 | — | not run |
| Design Review | `/plan-design-review` | UI/UX gaps | 0 | — | not run |
| DX Review | `/plan-devex-review` | Developer experience gaps | 0 | — | n/a — no developer-facing surface |

**CODEX:** unavailable — `codex exec` returned `The 'gpt-5.4' model is not supported when
using Codex with a ChatGPT account`. Fell back to a Claude subagent per skill contract.

**CROSS-MODEL:** not available. Both independent passes were Claude subagents with fresh
context, so they provide context independence but not model diversity.

**UNRESOLVED:** 0. All 10 review decisions answered; all adversarial findings corrected in
revision 4.

**VERDICT:** CEO CLEARED — scope, strategy and positioning settled. **Eng review required
before implementation.** The engine architecture changed materially in r4 (dual-path
withdrawn, `units.dart` back to single static-const, attribution spike moved into R1, R6
added), and no engineering review has seen the current shape.
