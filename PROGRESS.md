# no bs sudoku — progress

## what this is

a gen-z-first, design-forward sudoku app. no ads, no paywalls, no dark patterns. just sudoku done right.

**tech stack:** flutter (iOS + android), planned nestjs backend + supabase

**repo:** [github.com/HardikSJain/no-bs-sudoku](https://github.com/HardikSJain/no-bs-sudoku)

---

## phase 1 — engine, theme, game

### 1. puzzle engine (pure dart, zero dependencies)

**files:** `lib/engine/`

- **SudokuBoard** (`sudoku_board.dart`, 117 lines) — 9x9 board model. private cell storage with runtime validation (length == 81, values 0-9). provides row/col/box queries, candidate calculation, validity checking, solved detection, and deep copy.

- **SudokuSolver** (`sudoku_solver.dart`, 251 lines) — constraint propagation solver. applies naked singles and hidden singles first, falls back to backtracking. key capabilities:
  - uniqueness checking (counts up to 2 solutions, returns early)
  - technique tracking for difficulty rating
  - fast rejection of inconsistent boards (pre-check before backtracking)
  - `rateDifficulty()` rates a puzzle based on which techniques are needed to solve it

- **SudokuGenerator** (`sudoku_generator.dart`, 185 lines) — generates puzzles with guaranteed unique solutions:
  - builds a random solved board via backtracking with shuffled candidates
  - digs holes using 180-degree rotational symmetry (two-pass: symmetric pairs first, then symmetric fallback)
  - retries with fresh boards if target clue count isn't reached (tracks best attempt)
  - seeded generation for deterministic daily puzzles (`seed = YYYYMMDD`)
  - difficulty targets: easy 36-38, medium 30-33, hard 26-29, expert 22-28 clues

**tests:** 40 passing (`test/engine/`)

### 2. design system

**files:** `lib/core/theme/`

- **AppColors** — `#0A0A0A` background (OLED), `#C8FF00` electric lime accent, `#888888` notes (WCAG compliant)
- **AppTypography** — DM Mono (numbers), Space Mono (UI text)
- **AppTheme** — dark ThemeData, no splash/ripple effects

### 3. game screen

**files:** `lib/features/game/`

- **GameCubit** — all game logic: place/erase/undo/hint, notes mode, auto-clear related notes, timer
- **GameState** — immutable state with full undo history (captures cleared notes for proper restoration)
- **SudokuGrid** — selected/same-number/related/conflict highlighting, `buildWhen` skips timer rebuilds
- **SudokuCell** — entry animation (scale+fade 120ms), conflict shake, 3x3 notes grid
- **NumberPad** — dims completed digits, `buildWhen` optimization
- **GameToolbar** — disabled buttons pass null onTap for accessibility, `buildWhen` optimization
- deep copy on all notes mutations to prevent shared state corruption

### 4. splash + home + routing

- splash: wordmark fade-in → tagline → auto-route to home (1.6s)
- home: difficulty picker (easy/medium/hard/expert) with descriptions
- GoRouter: `/` → `/home` → `/game/:difficulty`

---

## phase 2 — intelligence, persistence, completion (in progress)

### 5. local storage (drift/sqlite)

**files:** `lib/core/storage/`

chose drift over isar (isar abandoned since 2023, no dart 3.x support). drift gives type-safe SQL queries with active maintenance.

- **AppDatabase** (`app_database.dart` + generated `.g.dart`) — 4 tables:
  - `PuzzleRecords` — puzzleId, difficulty, isDaily, timeSeconds, hintsUsed, mistakes, completedAt, solveTimes (comma-separated deltas), undosUsed, usedNotes, longestPauseSeconds, mistakeCells, qualityScore
  - `PlayerProfiles` — singleton row: displayName, currentStreak, longestStreak, lastPlayedDate, totalSolved, totalStarted, preferredDifficulty
  - `GamePreferencesTable` — singleton row: autoRemoveNotes, highlightMatching, showTimer, mistakeLimit, theme
  - `SyncQueueItems` — offline sync queue: type, payload (JSON), queuedAt, attempts

- **StorageService** (`storage_service.dart`) — wraps all DB access:
  - write: saveRecord, updateProfile, updatePreferences
  - read: getProfile, getPreferences, getAllRecords, getRecordsForDifficulty, getRecentRecords, getBestRecord, hasCompletedDailyToday
  - streak logic: increment if yesterday, reset if 2+ days gap, no-op if same day
  - incrementStarted: called when puzzle begins
  - sync queue: addToSyncQueue, getSyncQueue, deleteSyncItem, incrementSyncAttempt
  - resetAllData: clears all records + sync queue, resets profile to defaults

### 6. quality score

**file:** `lib/core/intelligence/quality_score.dart`

composite score (0-100) from 4 components:
- time vs par (40pts): full marks at/under par, scales to 0 at 3x par. par times: easy 600s, medium 900s, hard 1200s, expert 1800s
- accuracy (30pts): -10 per mistake
- self-sufficiency (20pts): -7 per hint
- confidence (10pts): -2 per undo
- labels: clean (90+), solid (75+), decent (60+), rough (40+), chaos (<40)

### 7. velocity tracking (wired into GameCubit)

**updated:** `lib/features/game/game_cubit.dart`

GameState now carries puzzleId, difficulty, isDaily. GameCubit tracks during play:
- `_cellPlacementDeltas` — seconds between each cell fill
- `_longestPause` — largest idle gap > 10s
- `_undoCount` — total undo() calls
- `_notesEverUsed` — boolean, set when notes mode first toggled on
- `_mistakeCells` — flat cell indices where wrong numbers were placed

on puzzle complete (`_onPuzzleComplete`):
- computes QualityScore
- saves PuzzleRecord to drift
- updates streak via StorageService
- exposes qualityScore, hintsUsed, undosUsed, solveTimes for complete screen

---

## project structure

```
lib/
  main.dart                           # entry point + db init
  app.dart                            # MaterialApp + theme + router
  core/
    intelligence/
      quality_score.dart              # score formula + labels
    routing/app_router.dart           # GoRouter setup
    storage/
      app_database.dart               # drift schema (4 tables)
      app_database.g.dart             # generated
      storage_service.dart            # db access + streak logic
    theme/
      app_colors.dart                 # color constants
      app_theme.dart                  # ThemeData
      app_typography.dart             # DM Mono + Space Mono styles
  engine/
    sudoku_board.dart                 # 9x9 board model
    sudoku_generator.dart             # puzzle generation
    sudoku_solver.dart                # constraint solver
  features/
    splash/splash_screen.dart         # boot screen
    home/home_screen.dart             # difficulty picker
    game/
      game_cubit.dart                 # game logic + velocity tracking
      game_screen.dart                # game layout
      game_state.dart                 # state model
      widgets/
        sudoku_grid.dart              # 9x9 grid
        sudoku_cell.dart              # individual cell
        number_pad.dart               # 1-9 input
        game_toolbar.dart             # undo/erase/notes/hint

test/
  engine/
    sudoku_board_test.dart            # 16 tests
    sudoku_solver_test.dart           # 8 tests
    sudoku_generator_test.dart        # 15 tests
  widget_test.dart                    # 1 test
```

---

## git history

```
PR #1: feat/puzzle-engine (merged)
  - SudokuBoard, SudokuSolver, SudokuGenerator
  - unit tests
  - fixes: runtime validation, symmetry, fallback logic, rateDifficulty guard

PR #2: feat/core-theme-and-game (merged)
  - dark theme (colors, typography, ThemeData)
  - game screen (grid, number pad, toolbar, cubit)
  - splash + home screens
  - routing + app entry
  - fixes: buildWhen optimizations, deep copy notes, undo restoration,
    disabled button accessibility, notes contrast, widget test

PR #3: feat/storage-and-tracking (open)
  - drift database (4 tables)
  - StorageService with streak logic
  - QualityScore formula
  - velocity tracking wired into GameCubit
  - db initialization in main.dart
```

---

## what's next (build order)

- [ ] **puzzle complete screen** — "Solved." takeover with checkmark animation, stats grid, quality bar, share text
- [ ] **intelligence engine** — difficulty recommendation, velocity analysis, daily insights
- [ ] **home screen upgrade** — daily puzzle card, stats strip, smart difficulty pre-selection
- [ ] **stats screen** — sparkline, heatmap, difficulty breakdown, best times
- [ ] **settings screen** — preferences, theme toggle, display name, data export/reset
- [ ] **supabase schema** — users, puzzles, completions tables
- [ ] **nestjs backend** — daily puzzle API, completion sync, leaderboard
- [ ] **flutter ↔ backend wiring** — daily puzzle fetch, completion sync
- [ ] **leaderboard screen** — daily/weekly/all-time tabs
- [ ] **offline queue + sync** — local-first with background drain
- [ ] **polish pass** — haptics, micro-animations, empty states, copy voice audit

---

## dependencies

```yaml
# core
flutter_bloc: ^9.1.1        # state management (cubit)
go_router: ^14.8.1           # declarative routing
google_fonts: ^6.2.1         # DM Mono + Space Mono
flutter_animate: ^4.5.2      # animation helpers

# storage
drift: ^2.32.0               # type-safe sqlite
drift_flutter: ^0.3.0        # flutter bindings for drift
path_provider: ^2.1.5        # app documents directory

# dev
drift_dev: ^2.32.0           # code generator
build_runner: ^2.12.2        # runs generators
```

---

## design principles

- **zero bs:** no ads, no paywalls, no dark patterns, no permission grabs
- **premium minimalist:** clean, intentional, lots of negative space
- **smooth + subtle:** animations are fast and understated, never flashy
- **offline-first:** app works fully without network
- **copy voice:** lowercase, dry, calm. no exclamation points. ever.
