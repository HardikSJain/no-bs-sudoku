# no bs sudoku

just sudoku. no ads. no pop-ups. no energy systems. no bs.

a design-forward sudoku app built with flutter. dark, minimal, fast. the kind of app you actually want on your phone.

---

## what makes it different

**zero ads, zero paywalls, zero dark patterns.** every feature is free. hints are free. there's no "premium tier". no "watch an ad for a hint". no "rate us" banners. none of that.

**it looks like a terminal, not a toy.** near-black OLED background. electric lime accent. monospaced numbers. the grid is the hero — everything else gets out of the way.

**it remembers how you play.** tracks your solve velocity, mistake patterns, and consistency. surfaces one smart insight per day — not notifications, not badges. just a quiet observation when it has something worth saying.

**it stays out of your way.** no account required. no sign-in gate. no onboarding carousel. open the app, tap a difficulty, play.

---

## features

**the game**
- 4 difficulty levels: easy, medium, hard, expert
- pencil notes with auto-clear on correct placement
- full undo stack (every action reversible, including hints)
- smart highlighting: same number, related cells, conflicts
- 3 hints per puzzle (always free)

**daily puzzle**
- new puzzle every day, same for everyone
- difficulty rotates by day of week (mon/tue easy → sun expert)
- seeded generation — deterministic, no server needed

**intelligence**
- quality score (0-100) based on time, accuracy, hints, undos
- velocity analysis: "strong opener." / "thinking in bursts."
- difficulty recommendation based on recent performance
- daily insights: "you solve best in the evenings." / "6 puzzles in a row with zero mistakes."

**stats**
- 14-day performance sparkline
- 90-day activity heatmap (github-style)
- per-difficulty breakdown: solved count, best time, avg quality
- streak tracking

**game resume**
- auto-saves every action
- floating resume bar on home screen
- full state restoration: board, notes, timer, hints

**settings**
- dark / amoled theme
- toggle: auto-remove notes, highlight numbers, show timer
- mistake limit (off / 3)
- export data as JSON
- reset all data with confirmation

---

## design

**palette**
| | |
|---|---|
| background | `#0A0A0A` (dark) / `#000000` (amoled) |
| accent | `#C8FF00` electric lime |
| surface | `#111111` |
| text | `#F5F5F5` / `#666666` / `#333333` |

**typography**
- [DM Mono](https://fonts.google.com/specimen/DM+Mono) — all numbers
- [Space Mono](https://fonts.google.com/specimen/Space+Mono) — all UI text

**copy voice** — lowercase, dry, calm. no exclamation points. ever.
| instead of | we say |
|---|---|
| "Amazing!! You did it!" | "Solved." |
| "You're on fire! 🔥" | "7 days. keep going." |
| "Oops! Something went wrong." | "something broke. try again." |
| "No scores yet!" | "nobody's been here yet." |

---

## tech

- **flutter** — iOS + android from a single codebase
- **flutter_bloc** — state management (cubit pattern)
- **drift** — type-safe sqlite for local persistence
- **go_router** — declarative routing
- **fl_chart** — sparklines and bar charts
- **pure dart puzzle engine** — no external solver dependencies

the entire puzzle engine (generator, solver, board model) is written from scratch in dart. generates puzzles with guaranteed unique solutions using constraint propagation and symmetric hole-digging.

---

## architecture

```
lib/
  engine/          — puzzle generation + solving (pure dart)
  core/
    intelligence/  — quality score, velocity analysis, insights
    storage/       — drift database + storage service
    theme/         — colors, typography, theme switching
    routing/       — go_router setup
  features/
    game/          — game screen, cubit, grid, number pad
    complete/      — solved screen with staggered animations
    home/          — daily card, stats strip, resume bar
    stats/         — performance dashboard
    settings/      — preferences + data management
    splash/        — boot screen
```

fully offline. no network calls. no backend dependency. works on airplane mode from day one.

---

## running locally

```bash
# clone
git clone https://github.com/HardikSJain/no-bs-sudoku.git
cd no-bs-sudoku

# get dependencies
flutter pub get

# generate drift code
dart run build_runner build --delete-conflicting-outputs

# run
flutter run

# test
flutter test
```

---

## roadmap

**v1.0** (current) — fully playable on-device app
- [x] puzzle engine with unique solution guarantee
- [x] game screen with full undo, notes, hints
- [x] daily puzzle with day-of-week rotation
- [x] quality score + velocity tracking
- [x] intelligence engine with daily insights
- [x] stats dashboard
- [x] settings + theme switching
- [x] game resume with floating bar

**v2.0** — social layer
- [ ] supabase backend + anonymous auth
- [ ] daily/weekly/all-time leaderboard
- [ ] cross-device sync
- [ ] offline queue with background drain

---

built with no bs.
