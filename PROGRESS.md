# no bs sudoku — progress

## what this is

a gen-z-first, design-forward sudoku app. no ads, no paywalls, no dark patterns. just sudoku done right.

**tech stack:** flutter (iOS + android), planned nestjs backend + supabase

**repo:** [github.com/HardikSJain/no-bs-sudoku](https://github.com/HardikSJain/no-bs-sudoku)

---

## what's built

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
- board: get/set, row/col/box, candidates, validity, cloning, invalid input rejection
- solver: known puzzle, invalid boards, empty board, uniqueness, technique tracking, difficulty rating
- generator: all 4 difficulties, determinism, symmetry (all difficulties), bulk uniqueness stress test

---

### 2. design system

**files:** `lib/core/theme/`

- **AppColors** (`app_colors.dart`) — dark palette. `#0A0A0A` background (OLED-friendly), `#111111` surface, `#C8FF00` electric lime accent, semantic colors for errors/success/conflicts. separate given/user/notes colors for the grid.

- **AppTypography** (`app_typography.dart`) — two typefaces:
  - **DM Mono** — all numbers (cells, number pad, wordmark). monospaced = native to sudoku.
  - **Space Mono** — all UI text (labels, buttons, headings). clean and technical.

- **AppTheme** (`app_theme.dart`) — dark ThemeData, transparent app bar, no splash/ripple effects (splashFactory: NoSplash).

---

### 3. game screen (the core)

**files:** `lib/features/game/`

- **GameState** (`game_state.dart`, 104 lines) — immutable state model tracking:
  - puzzle (original clues), board (current state), solution (for validation)
  - given cells set, notes map, undo history stack
  - selection, notes mode toggle, hints remaining, mistake count, timer, game status

- **GameCubit** (`game_cubit.dart`, 283 lines) — all game logic:
  - `selectCell()` — tap a cell to select it
  - `placeNumber()` — enter a digit or toggle a note (if notes mode). validates against solution, auto-clears related notes on correct placement
  - `erase()` — clear selected cell value and notes
  - `toggleNotesMode()` — switch number pad between value/note entry
  - `useHint()` — reveals correct value, costs 1 hint (3 per puzzle)
  - `undo()` — reverses any action (place, note, erase, hint) with full state restoration
  - `countDigit()` — tracks how many of each digit are placed (dims completed digits)
  - timer ticks every second, stops on completion
  - haptic feedback on puzzle completion

- **SudokuGrid** (`widgets/sudoku_grid.dart`, 107 lines) — the 9x9 grid:
  - 3x3 box borders (thicker/brighter than cell borders)
  - selected cell: elevated background + lime left-border accent
  - same-number cells: subtle dark lime tint
  - related cells (same row/col/box): slightly elevated surface
  - conflict cells: dark red background + red number

- **SudokuCell** (`widgets/sudoku_cell.dart`, 115 lines) — individual cell:
  - given numbers: white, semi-bold
  - user numbers: lime accent, regular weight
  - entry animation: scale 0.8→1.0 in 120ms (easeOutCubic) + fade in
  - conflict animation: horizontal shake (4hz, 200ms)
  - notes: 3x3 mini grid of small candidates

- **NumberPad** (`widgets/number_pad.dart`, 69 lines) — flat 1x9 row:
  - completed digits (all 9 placed) dim out
  - notes mode changes number color to grey
  - haptic feedback on tap
  - rounded pill buttons with subtle border

- **GameToolbar** (`widgets/game_toolbar.dart`, 101 lines) — undo / erase / notes / hint:
  - notes button highlights in accent when active
  - hint shows remaining count
  - disabled state for undo (empty history) and hint (0 remaining)
  - haptic on tap

---

### 4. splash screen

**file:** `lib/features/splash/splash_screen.dart` (54 lines)

- pure black, "no bs sudoku" wordmark fades in (DM Mono, 500ms)
- "just sudoku." appears 400ms later in lime accent
- auto-routes to home after 1.6s
- intentionally text-only, no logo animation

---

### 5. home screen

**file:** `lib/features/home/home_screen.dart` (149 lines)

- wordmark at top
- difficulty picker: 4 tiles (easy/medium/hard/expert)
  - each has a label + short description ("the sweet spot", "no hand-holding")
  - tap navigates to game screen with selected difficulty
  - subtle border separators, arrow icon
- "just sudoku." footer in disabled text
- all copy lowercase, no exclamation points

---

### 6. app wiring

- **GoRouter** (`lib/core/routing/app_router.dart`) — `/` (splash) → `/home` → `/game/:difficulty`
- **App** (`lib/app.dart`) — MaterialApp.router with dark theme
- **main.dart** — system UI chrome (transparent status bar, dark nav bar)

---

## project structure

```
lib/
  main.dart                           # entry point
  app.dart                            # MaterialApp + theme + router
  core/
    routing/app_router.dart           # GoRouter setup
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
      game_cubit.dart                 # game logic
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

**total:** 18 dart files, ~1,900 lines of code, 40 tests passing

---

## git history

```
PR #1: feat/puzzle-engine (merged)
  - SudokuBoard model
  - SudokuSolver with constraint propagation
  - SudokuGenerator with symmetric hole digging
  - unit tests
  - fixes: runtime validation, symmetry preservation, fallback logic, rateDifficulty guard

PR #2: feat/core-theme-and-game (open)
  - dark theme (colors, typography, ThemeData)
  - game screen (grid, number pad, toolbar, cubit)
  - splash + home screens
  - routing + app entry
```

---

## what's next (build order)

- [ ] **puzzle complete screen** — "Solved." takeover, stats display, share result text
- [ ] **home screen upgrades** — daily puzzle card, stats preview, streak display
- [ ] **stats screen** — heatmap calendar, solve times, completion rate
- [ ] **local persistence** — hive for puzzle cache, completions, stats
- [ ] **supabase schema** — users, puzzles, completions tables
- [ ] **nestjs backend** — daily puzzle API, completion sync, leaderboard endpoints
- [ ] **flutter ↔ backend wiring** — daily puzzle fetch, completion sync
- [ ] **leaderboard screen** — daily/weekly/all-time tabs
- [ ] **settings + auth** — display name, toggle preferences, magic link
- [ ] **offline queue + sync** — local-first with background sync
- [ ] **polish pass** — haptics refinement, micro-animations, empty states, copy voice audit

---

## dependencies

```yaml
flutter_bloc: ^9.1.1      # state management (cubit)
go_router: ^14.8.1         # declarative routing
google_fonts: ^6.2.1       # DM Mono + Space Mono
flutter_animate: ^4.5.2    # animation helpers
```

---

## design principles

- **zero bs:** no ads, no paywalls, no dark patterns, no permission grabs
- **premium minimalist:** clean, intentional, lots of negative space
- **smooth + subtle:** animations are fast and understated, never flashy
- **offline-first:** app works fully without network
- **copy voice:** lowercase, dry, calm. no exclamation points. ever.
