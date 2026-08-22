# TODOS

Deferred work with enough context to pick up cold. Effort is human-team → CC+gstack.

---

## Completed

- **Persist game history and velocity counters across resume** — v1.1.2+8 (2026-08-22)
- **Drop the two dead tables** — v1.1.2+8 (2026-08-22)
- **Split StorageService** — v1.1.2+8 (2026-08-22), facade retained; DI migration below

## P1 — remaining from the R0 defect pass

### Inject the repositories and delete the StorageService facade
**What:** The four repositories exist and hold all the behaviour. `StorageService`
is now a thin forwarding facade kept so the split could land without touching
the 19 call sites. Migrate those call sites to constructor injection, then
delete the facade and the `instance` singleton.
**Why:** The singleton is why every test needs a real database. The repositories
are already independently constructible, so new tests can use them directly —
this closes out the old path.
**Cons:** Watch the isolate hazard. `newGameAsync`/`dailyAsync` pass closures to
`Isolate.run`; capturing an injected object that transitively holds a drift
`AppDatabase` throws at runtime only, on the new-game path. Guard tests for both
factories landed in v1.1.2+8 — keep them green.
**Effort:** M → S. **Priority:** P1.


## P1 — verify before acting

### Verify the sudoku.coach 27-technique claim
**What:** Confirm directly that sudoku.coach ships 27 human-style strategies across 7 tiers.
**Why:** The r4 CEO review elevated "12 techniques vs 27" to a positioning output, but the
search result linked a Play Store listing whose package id (`com.floppeyapps.infinite_sudoku`)
does not match the product name. A positioning claim should not rest on a mismatched citation.
**Effort:** S → S. **Priority:** P1. **Blocks:** the ladder-expansion decision below.

---

## P2 — reopened by the CEO review

### Variant strategy spec (killer, thermo, jigsaw)
**What:** A dedicated spec for puzzle variants, treating them as one strategic decision.
**Why:** Jigsaw was accepted then deferred once its premise proved false — real cost is
wave-scale: per-puzzle unit tables threaded through 12 rule signatures, variable-arity peer
tables (the 20-peer invariant breaks), a region-layout generator, a region-aware filler,
10 sites of box-geometry surgery (`sudoku_board.dart:35,36,65,66,113,115`,
`sudoku_grid.dart:65,92,93,98,99,122`), schema columns on `SavedGames` and `PuzzleRecords`,
a separate record namespace so jigsaw `hard` does not pollute classic `hard` best times, and
a 13th rule (law of leftovers) without which the ladder systematically over-grades jigsaw.
**Killer is the stronger candidate** — it is what pulls the Cracking the Cryptic audience,
where jigsaw is the least distinctive variant.
**Pros:** biggest retention lever for strong players; "more to do" is the app's weakest axis.
**Cons:** larger than the entire teaching engine. Killer and thermo need constraint types the
ladder does not model at all.
**Effort:** XL → L. **Priority:** P2. **Depends on:** R1 engine complete.

### Expand the ladder past 12 rules
**What:** Add techniques beyond the current 12 toward parity with competitors.
**Why:** Rules are independent `TechniqueRule` implementations behind one interface, so they
add linearly with no architectural change. Worth doing if the head-to-head technique count
starts costing users.
**Effort:** M → S per rule. **Priority:** P2. **Depends on:** the verification TODO above.

### Camera OCR for puzzle import
**What:** Photograph a grid instead of typing it.
**Why:** The higher-value half of E1. Manual entry ships in R6; typing 81 cells is the
feature's real cost even with the paste-a-string path.
**Cons:** 9x9 grid OCR is real computer vision; misreads get blamed on the app, and an
offline model adds bundle size to an app whose pitch is offline-first.
**Effort:** L → M. **Priority:** P2. **Depends on:** R6 shipping and showing usage.

---

## P3 — considered, not scheduled

### External keyboard support
Dropped from E4b as YAGNI — touch-first mobile app, no desktop or web target in
`pubspec.yaml`. The same budget went to the accessibility pass, which reaches far more users.
**Effort:** M → S. **Priority:** P3.

### Monetization: theme pack or tip jar
Paid acquisition with no revenue model is not durable. Themes are already abstracted behind
`AppThemeColors`, so a cosmetic pack is nearly free to build and violates nothing in the
no-ads/no-paywall brand — it adds an option rather than gating anything.
**Effort:** M → S. **Priority:** P3. Flagged twice across reviews; never scheduled.

### Home-screen widget
Highest-leverage retention surface for a daily-habit app. Needs native platform channels.
**Effort:** L → M. **Priority:** P3.

### Daily archive
`generateDaily` is deterministic from the date and `DailyPuzzleCache` is keyed by date, so
playing a past daily is nearly free. A broken streak from one missed day is the single
biggest churn event in a streak app.
**Caveat:** if built, the daily algorithm version must be pinned per date — §4.3 currently
drops v1 retention precisely because no past-date UI exists.
**Effort:** M → S. **Priority:** P3.

### Extract DESIGN.md from the code
**What:** Document the design system that already exists in `app_theme_colors.dart`,
`app_typography.dart` and `app_spacing.dart` as a proper `DESIGN.md`.
**Why:** The system is strong and specific — DM Mono / Space Mono, a 4-48 spacing scale,
cream-and-ink with six accents, 2px borders and zero-blur offset shadows. It is the app's
actual visual differentiator (spec section 1.0). But it lives only in Dart, so every plan
that adds UI has nothing to calibrate against. The design review rated design-system
alignment 5/10 purely because the plan could not cite tokens that are not written down.
**Pros:** Every future UI plan gets specific instead of vague. `/plan-design-review` and
`/design-review` both calibrate against it automatically.
**Cons:** A document that can drift from the code if nobody maintains it.
**Context:** `/design-consultation` generates this. The palette semantics need care —
the design review found six accents already carrying meaning (sun = hint, mint = notes
mode and completed group, cherry = error, lilac = expert) and this release adds roughly
eight more roles. Record which accent means what before adding any.
**Effort:** S → S. **Priority:** P2.

### Stale documentation
`CLAUDE.md` describes the palette as dark `#0A0A0A` with a lime accent; the shipped default
is the `paper` theme. `README.md` names supabase in the roadmap while the spec uses Firebase,
and still claims 4 difficulties. **Effort:** S → S. **Priority:** P3.
