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

## phase 3 — complete screen, intelligence, surfaces (in progress)

### 8. puzzle complete screen

**files:** `lib/features/complete/`

full-screen takeover with staggered animations (not a modal):

- **CheckmarkPainter** (`widgets/checkmark_painter.dart`) — CustomPainter that path-draws a checkmark stroke. Progress driven by AnimationController (0→1 over 600ms).

- **QualityBar** (`widgets/quality_bar.dart`) — thin horizontal bar that fills left-to-right. Score counter animates alongside. Shows score + label ("84 · solid.").

- **StatsGrid** (`widgets/stats_grid.dart`) — 2x2 grid: time, hints, mistakes, contextual comparison. Comparison slot shows one of:
  - "PB ↑ Xm Xs faster than your best" (accent, if new personal best)
  - "−X% vs your avg" (accent dim, if better than average with 3+ records)
  - "first hard solve." (muted, if first completion at this difficulty)
  - nothing (never surfaces negative comparisons)

- **CompleteCubit** (`complete_cubit.dart`) — loads comparison data and velocity analysis from StorageService on init. Emits CompleteState with streak, velocity label, and comparison string.

- **CompleteScreen** (`complete_screen.dart`) — orchestrates the staggered reveal:
  - 100ms: checkmark draws (600ms)
  - 700ms: "Solved." fades in
  - 900ms: difficulty + time label
  - 1050ms: stats grid
  - 1250ms: streak + velocity label slides up
  - 1450ms: quality bar fills (800ms)
  - 2000ms: share + new puzzle buttons

- **Share text** — text-only via share_plus, different format for daily vs quick play. includes quality score, streak, no screenshots.

### 9. velocity profile

**file:** `lib/core/intelligence/velocity_profile.dart`

analyzes solve pace from placement timing deltas:
- splits deltas into thirds, compares averages
- fastStart: first third faster by >20%
- slowStart: last third faster by >20%
- erratic: stddev > 50% of mean
- steady: everything else
- returns null if < 9 data points

shown on complete screen below streak as muted text ("consistent pace.", "thinking in bursts." etc)

### 10. intelligence engine

**file:** `lib/core/intelligence/intelligence_engine.dart`

on-device analytics, reads from drift via StorageService:
- `recommendDifficulty()` — step up if 3/5 quality >80, step down if 3/5 <45, guards unknown difficulty
- `bestTimeOfDay()` — morning/afternoon/evening/night buckets, min 3 records per bucket
- `consistencyScore()` — % of last 30 days with plays
- `longestCleanRun()` — consecutive 0-mistake solves
- `performanceTrend()` — this week vs last week avg quality, guards division by zero
- `dailyInsight()` — 8 prioritized insight types, deterministic daily rotation, null if <3 records

### 11. home screen upgrade

**files:** `lib/features/home/`

- **HomeCubit** — loads profile, records, daily status, difficulty recommendation, insight in parallel
- **DailyPuzzleCard** — accent border, completed/not-played states, rotates difficulty by day of week
- **StatsStrip** — streak, solved count, avg quality (tappable → /stats), invisible with 0 solves
- smart difficulty pre-selection with accent left-border, only writes to DB when changed
- daily insight text from IntelligenceEngine
- settings gear → /settings

### 12. stats screen

**files:** `lib/features/stats/`

personal performance dashboard:
- **overview card** — streak, total solved, avg quality (DM Mono numbers)
- **performance sparkline** — 14-day fl_chart LineChart, gaps on unplayed days, accent line
- **difficulty breakdown** — table of solved count, best time, avg quality per difficulty
- **activity heatmap** — 90-day GitHub-style grid, opacity mapped to quality score
- **best times** — top 3 for preferred difficulty with date and hints
- **insight card** — 2px accent left-border, dry copy
- empty state: "play a puzzle. stats show up here."

### 13. settings screen

**files:** `lib/features/settings/`

instant-apply toggles persisted to drift:
- auto-remove notes, highlight numbers, show timer, mistake limit (off/3)
- theme picker (dark/amoled)
- display name (16 char max, saves on submit)
- export data as JSON via share_plus
- reset all data with two-step confirmation bottom sheet
- "built with no bs" footer

---

## project structure

```
lib/
  main.dart                           # entry point + db init
  app.dart                            # MaterialApp + theme + router
  core/
    intelligence/
      intelligence_engine.dart        # on-device analytics
      quality_score.dart              # score formula + labels
      velocity_profile.dart           # solve pace analysis
    routing/app_router.dart           # GoRouter setup (all routes)
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
    home/
      home_screen.dart                # upgraded with daily card, stats strip
      home_cubit.dart                 # loads profile, daily, insights
      widgets/
        daily_puzzle_card.dart        # daily puzzle with rotation
        stats_strip.dart              # streak, solved, avg quality
    stats/
      stats_screen.dart               # performance dashboard
      stats_cubit.dart                # loads all stats data
      widgets/
        performance_sparkline.dart    # 14-day quality trend
        activity_heatmap.dart         # 90-day GitHub-style grid
        difficulty_breakdown.dart     # per-difficulty table
        best_times_card.dart          # top 3 fastest solves
        insight_card.dart             # intelligence insight display
    settings/
      settings_screen.dart            # preferences + data management
      settings_cubit.dart             # instant-apply toggles
    complete/
      complete_screen.dart            # solved takeover + staggered animations
      complete_cubit.dart             # loads comparison + velocity data
      widgets/
        checkmark_painter.dart        # path-draw checkmark
        quality_bar.dart              # animated score bar
        stats_grid.dart               # 2x2 time/hints/mistakes/comparison
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
  intelligence/
    quality_score_test.dart           # 14 tests
  widget_test.dart                    # 1 test
```

**total:** 54 tests passing

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

PR #3: feat/storage-and-tracking (merged)
  - drift database (4 tables)
  - StorageService with streak logic
  - QualityScore formula + 14 unit tests
  - velocity tracking wired into GameCubit
  - db initialization in main.dart
  - fixes: same-day totalSolved, unawaited storage calls, assert on init

PR #4: feat/complete-screen (merged)
  - puzzle complete screen with staggered animations
  - checkmark path painter, quality bar, stats grid
  - CompleteCubit with comparison + velocity analysis
  - VelocityProfile enum + analysis
  - game → complete navigation wiring
  - share_plus for text-only result sharing

PR #5: feat/intelligence-and-home (merged)
  - IntelligenceEngine (difficulty recommendation, insights, trends)
  - Home screen upgrade (daily card, stats strip, smart pre-selection)
  - Daily puzzle rotation by day of week
  - Daily puzzle caching in drift

PR #6: feat/stats-and-settings (open)
  - Stats screen (sparkline, heatmap, breakdown, best times, insights)
  - Settings screen (toggles, theme, name, export, reset)
  - /stats and /settings routes wired
```

---

## what's next (build order)

- [x] **puzzle complete screen** — "Solved." takeover with checkmark animation, stats grid, quality bar, share text
- [x] **intelligence engine** — difficulty recommendation, velocity analysis, daily insights
- [x] **home screen upgrade** — daily puzzle card, stats strip, smart difficulty pre-selection
- [x] **stats screen** — sparkline, heatmap, difficulty breakdown, best times
- [x] **settings screen** — preferences, theme toggle, display name, data export/reset
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

# sharing
share_plus: ^12.0.1          # text-only result sharing

# charts
fl_chart: ^1.2.0             # sparkline + bar charts

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
