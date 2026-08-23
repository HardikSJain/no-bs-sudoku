# changelog

## [1.2.0+9] - 2026-08-23

the teaching engine. the app used to tell you where to look; it now tells
you what it saw, names it, and lets you practise it until you can find it
yourself.

### added
- **a technique library.** sixteen named patterns, each with a plain-english
  explanation, a diagram, and a recognition cue you can hold in your head
  while looking at the board. a sudoku app that shows you a "swordfish"
  without ever saying what one is has taught you nothing.
- **hints that explain rather than answer.** four rungs: where to look, which
  cell, why, and finally the digit. the name of the technique appears from
  the third rung on, and links straight to its page. how far you push a hint
  is what costs you quality now — there is no hint counter to run out of.
- **trainer mode.** pick a technique and get a puzzle scaffolded to the exact
  move, so you practise the pattern instead of grinding forty singles to
  reach one.
- **mastery per technique.** measured from drills, where "spotted it unaided"
  is actually observable, and shown on the stats screen as well as in the
  library.
- **two tiers above expert.** fish and chains puzzles are built to *need*
  their technique, not merely to allow it.
- **puzzle import.** type or paste a grid from a newspaper or another app. it
  is checked properly — a grid with two answers is refused rather than
  quietly played — and never counts towards your stats or streak.
- **the daily archive.** the last ninety days as a calendar. a daily you can
  only play on the day is a daily you stop playing the first time life gets
  in the way.
- **two puzzles at once.** the daily and something casual no longer evict each
  other. starting one stopped asking you to throw away the other.
- **hardware keyboard.** arrows or hjkl to move, digits to place, n for notes,
  u to undo, h for a hint, esc to dismiss it. listed in settings.
- **solve-path analysis** on the solved screen, opt-in, showing how the puzzle
  was actually built.

### changed
- **one theme.** dark and amoled are gone. the warm paper palette was the one
  the app was designed around, and maintaining three of them made every
  colour decision three decisions.
- **hints tell the answer from the evidence by shape, not just colour.** the
  cell being settled is ringed solid; each cell that proves it is ringed with
  dashes. three shades of the same yellow is not a distinction you can make
  on a dimmed screen or in sunlight.
- **expert puzzles generate in a sixth of a second** rather than six. no
  puzzle in the app needs a guess.
- **very large system text sizes are capped.** past 2x the layouts stopped
  being layouts. everything is tested at that size now.

### fixed
- **a puzzle left open overnight read "299:09" instead of "4:59:09".** the
  clock also kept counting while the app sat untouched; it stops after ten
  minutes of silence and picks up the moment you touch anything.
- **the board moved under your finger when a hint opened.** you were reading
  a sentence about cells that had just shifted.
- **importing a puzzle played a different puzzle.** the route matched
  "import" as a difficulty name and generated a random medium instead.
- **the whole app is reachable with a screen reader.** every control has a
  name and a role; the board reads its position, its contents and its state.
- four layouts ran off the edge of a small screen with the text size turned
  up, including the difficulty cards on the home screen.
- settings had been reporting version 1.0.1 for four releases.

### internal
- the technique ladder is sixteen rules, fuzzed against the backtracking
  solver on every build so an unsound one cannot ship.
- three techniques are taught but have no drill, because measurement showed
  no puzzle ever truly needs them. saying so beats a menu item that fails
  after seven seconds.
- every screen is rendered narrow in a test and checked for overflow — the
  home screen had never been rendered whole before, which is how a card
  overflowed for months unnoticed.
- guards against the mistakes already made once: unlabelled tap targets,
  platform calls in a cubit, hand-rolled clock formatting, and hint copy over
  budget all fail the build now.

## [1.1.2+8] - 2026-08-22

completes the defect pass. the remaining three of nine, plus the storage
groundwork the rest of the plan is built on.

### fixed
- **backgrounding the app destroyed your undo history.** it also reset
  every timing counter, so quality score and velocity analysis were
  wrong for any puzzle you resumed — and the app used that data to
  recommend your next difficulty. a resumed puzzle also showed an empty
  puzzle breakdown on the solved screen.
- **a single corrupt field used to delete your whole saved game.** the
  restore path caught everything at once and responded by handing you a
  fresh medium puzzle. now the board and notes always survive; only the
  part that failed is lost.
- **streaks could break a day early.** the streak check mixed a local
  date with a utc one, a five-and-a-half hour skew in india.
- factory reset left the resume bar on screen pointing at a game it had
  just erased.

### changed
- autosave now coalesces rapid input instead of rewriting the whole save
  on every tap, and writes immediately when you leave the game.
- new installs open on the paper theme. the schema has said so for a
  while, but a build step was never re-run, so the generated code still
  said dark. existing players keep whatever they have set.

### internal
- dropped two tables nothing ever wrote to.
- split the storage layer into four repositories behind a temporary
  facade, so the call sites could stay untouched.
- migration tests now cover the real upgrade path, and ci fails if
  generated code drifts from the schema — which is what hid the theme
  default for so long.

## [1.1.1+7] - 2026-08-22

first pass of the teaching engine plan. all defect repair — no new
features. six of the nine defects the review found, plus the migration
safety net that has to exist before any schema change.

### fixed
- **the hint button did nothing.** tapping hint without a cell selected
  buzzed to confirm it registered, then silently returned. it now selects
  the easiest remaining cell and spends nothing; a second tap reveals.
- **the daily puzzle was not the same for everyone.** it was seeded from
  device-local time, so different timezones got different puzzles for the
  same day. seven separate places derived "today" independently, which
  also broke completion detection and streaks for anyone not near UTC.
  the daily now rolls at midnight UTC.
- **starting a game silently destroyed your in-progress puzzle.** one
  mistap on a difficulty threw away whatever you were playing, with the
  resume bar for that game sitting directly above. now it asks. tapping
  today's daily while it is in progress resumes instead of prompting.
- **undo did not give back a mistake.** the counter only ever climbed, so
  a mistake you took back still cost quality score and still counted
  toward the mistake limit.
- **thinking time was measured on the wall clock.** returning after a
  night away recorded an eight-hour "pause" into your solve history,
  which the difficulty recommender and daily insights then acted on.
- **sharing crashed on ipad.** the share sheet is a popover there and
  needs an anchor; neither share button passed one.
- erase now reports when it did nothing instead of buzzing anyway.
- auto-fill notes was a hidden long-press with no affordance. the hint
  that was written for it was never actually drawn.

### changed
- new puzzles open as soon as they are generated. there was a mandatory
  1.5 second wait even when generation finished instantly.

### internal
- drift schema snapshots and a migration verifier. there were no
  migration tests at all, and the app has no downgrade path — once a
  schema change ships to a device it cannot be walked back.
- the only widget test in the repo had been failing on main. it asserted
  on copy the home screen never had, and the router is a cached global
  that leaked navigation state between tests.
