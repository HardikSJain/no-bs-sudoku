# changelog

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
