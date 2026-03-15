# no bs sudoku — progress

## what this is

a gen-z-first, design-forward sudoku app. no ads, no paywalls, no dark patterns. just sudoku done right.

**tech stack:** flutter (iOS + android)
**status:** v1.0 — fully playable, on-device, offline-first

**repo:** [github.com/HardikSJain/no-bs-sudoku](https://github.com/HardikSJain/no-bs-sudoku)

---

## phase 1 — engine, theme, game

### 1. puzzle engine (pure dart, zero dependencies)

- **SudokuBoard** — 9x9 board model with runtime validation, candidate calculation, validity checking
- **SudokuSolver** — constraint propagation (naked singles → hidden singles → backtracking), uniqueness checking, difficulty rating
- **SudokuGenerator** — symmetric hole-digging, seeded deterministic generation, 180-degree rotational symmetry, retries with best-attempt tracking

### 2. design system

- dark palette (`#0A0A0A` background, `#C8FF00` electric lime accent)
- DM Mono for numbers, Space Mono for UI text
- AMOLED theme variant (`#000000` background)
- no splash/ripple effects

### 3. game screen

- full game logic: place/erase/undo/hint, notes mode, auto-clear related notes
- immutable state with full undo history (captures cleared notes for proper restoration)
- selected/same-number/related/conflict cell highlighting
- entry animation (scale+fade), conflict shake, 3x3 notes grid
- number pad dims completed digits
- `buildWhen` optimizations on all widgets to skip timer-tick rebuilds

### 4. splash + home + routing

- text-only splash with staggered fade-in
- GoRouter with all routes wired

---

## phase 2 — persistence + tracking

### 5. local storage (drift/sqlite)

6 tables: PuzzleRecords, PlayerProfiles, GamePreferencesTable, DailyPuzzleCache, SavedGames, SyncQueueItems

StorageService wraps all DB access: save/load records, streak logic, preferences, game save/restore, data export/reset

### 6. quality score

composite 0-100 score: time vs par (40pts), accuracy (30pts), self-sufficiency (20pts), confidence (10pts). labels: clean/solid/decent/rough/chaos

### 7. velocity tracking

tracks placement timing deltas, longest pause, undo count, notes usage, mistake cells. saves PuzzleRecord + updates streak on complete

---

## phase 3 — surfaces + intelligence

### 8. puzzle complete screen

full-screen takeover with strict staggered animation sequence: checkmark path-draw → "Solved." → stats grid → streak + velocity → quality bar fill → action buttons. contextual comparison (PB/vs avg/first solve — never negative). text-only sharing via share_plus

### 9. intelligence engine

on-device analytics: difficulty recommendation, best time of day, consistency score, longest clean run, performance trend, daily insight (8 prioritized types, deterministic rotation)

### 10. home screen

daily puzzle card with day-of-week difficulty rotation (mon/tue easy, wed/thu medium, fri/sat hard, sun expert). stats strip (streak, solved, avg quality). smart difficulty pre-selection. daily insight. settings gear

### 11. stats screen

overview card, 14-day performance sparkline (fl_chart), difficulty breakdown table, 90-day GitHub-style activity heatmap, best times, insight card. empty state: "play a puzzle. stats show up here."

### 12. settings screen

instant-apply toggles: auto-remove notes, highlight numbers, show timer, mistake limit (off/3). theme picker (dark/amoled) with live switching via ThemeCubit. display name, data export (JSON), reset with two-step confirmation

### 13. game preferences wired

settings actually affect gameplay: highlight matching, show/hide timer, auto-remove notes preference, mistake limit triggers abandoned status

---

## v1.0 sprint — game resume + polish

### 14. game resume

- auto-saves after every meaningful action (place, erase, undo, hint, notes toggle)
- saves on app background (AppLifecycleListener) and back button
- floating resume bar on home screen (Zomato-style) — slides up from bottom, shows difficulty + elapsed time, play icon, dismiss [×]
- full board restore: numbers, notes, timer, hints, mistakes
- filters out stale dailies (yesterday's) and trivial saves (<30s)
- corrupted saves fail gracefully (delete + fresh game)
- starting a new game clears any saved game

---

## project structure

```
lib/
  main.dart
  app.dart
  core/
    intelligence/
      intelligence_engine.dart
      quality_score.dart
      velocity_profile.dart
    routing/app_router.dart
    storage/
      app_database.dart           # drift schema (6 tables)
      app_database.g.dart
      storage_service.dart
    theme/
      app_colors.dart
      app_theme.dart              # dark + amoled
      app_typography.dart
      theme_cubit.dart
  engine/
    sudoku_board.dart
    sudoku_generator.dart
    sudoku_solver.dart
  features/
    splash/splash_screen.dart
    home/
      home_screen.dart
      home_cubit.dart
      widgets/
        daily_puzzle_card.dart
        resume_card.dart
        stats_strip.dart
    stats/
      stats_screen.dart
      stats_cubit.dart
      widgets/
        performance_sparkline.dart
        activity_heatmap.dart
        difficulty_breakdown.dart
        best_times_card.dart
        insight_card.dart
    settings/
      settings_screen.dart
      settings_cubit.dart
    complete/
      complete_screen.dart
      complete_cubit.dart
      widgets/
        checkmark_painter.dart
        quality_bar.dart
        stats_grid.dart
    game/
      game_cubit.dart
      game_screen.dart
      game_state.dart
      widgets/
        sudoku_grid.dart
        sudoku_cell.dart
        number_pad.dart
        game_toolbar.dart

test/
  engine/
    sudoku_board_test.dart
    sudoku_solver_test.dart
    sudoku_generator_test.dart
  intelligence/
    quality_score_test.dart
    velocity_profile_test.dart
  widget_test.dart
```

**total:** 63 tests passing

---

## git history

```
PR #1: feat/puzzle-engine (merged)
PR #2: feat/core-theme-and-game (merged)
PR #3: feat/storage-and-tracking (merged)
PR #4: feat/complete-screen (merged)
PR #5: feat/intelligence-and-home (merged)
PR #6: feat/stats-and-settings (merged)
PR #7: feat/game-resume-and-polish (open)
```

---

## what's done (v1.0)

- [x] puzzle engine with unique solution guarantee
- [x] dark + amoled theme
- [x] full game screen with undo, notes, hints
- [x] puzzle complete screen with staggered animations
- [x] quality score formula
- [x] velocity tracking + analysis
- [x] intelligence engine (insights, recommendations)
- [x] daily puzzle with day-of-week difficulty rotation
- [x] home screen (daily card, stats strip, smart difficulty, insight)
- [x] stats dashboard (sparkline, heatmap, breakdown, best times)
- [x] settings (preferences, theme, export, reset)
- [x] game resume (auto-save, floating resume bar)

## what's next (v2.0)

- [ ] supabase schema + nestjs backend
- [ ] leaderboard (daily/weekly/all-time)
- [ ] anonymous auth + cross-device sync
- [ ] offline queue + background sync
- [ ] polish pass (haptics audit, copy voice check, micro-animations)

---

## dependencies

```yaml
flutter_bloc: ^9.1.1        # state management
go_router: ^14.8.1           # routing
google_fonts: ^6.2.1         # DM Mono + Space Mono
flutter_animate: ^4.5.2      # animations
drift: ^2.32.0               # sqlite
drift_flutter: ^0.3.0        # drift flutter bindings
path_provider: ^2.1.5        # file paths
share_plus: ^12.0.1          # sharing
fl_chart: ^1.2.0             # charts
intl: ^0.20.2                # date formatting
```

---

## design principles

- **zero bs:** no ads, no paywalls, no dark patterns, no permission grabs
- **premium minimalist:** clean, intentional, lots of negative space
- **smooth + subtle:** animations are fast and understated, never flashy
- **offline-first:** app works fully without network
- **copy voice:** lowercase, dry, calm. no exclamation points. ever.
