# play data safety

What the app sends off the device, and how that maps to Google Play's Data
Safety form. Re-check this on every release — the form must match the build,
and a mismatch found by review is a rejection rather than a note.

Accurate as of **1.2.0+9**.

---

## What changed in 1.2.0

Only the feedback screen. Analytics and Crashlytics have been shipping for
several releases, so if the existing declaration is right, this is **two new
rows**:

| Data type | Why |
|---|---|
| Personal info → **Email address** | The optional "email, only if you want a reply" field |
| App activity → **Other user-generated content** | The feedback message itself |

Everything else the feedback screen attaches — version, platform, screen size,
locale, puzzles solved, streak, technique mastery, the anonymous install id —
falls under categories already declared for Analytics. Nothing new to add.

Remote Config, added in the same release, **collects nothing**. It delivers
configuration; it does not send player data.

---

## The full picture

### Collected

| Category | Type | Source | Required? | Purpose |
|---|---|---|---|---|
| App activity | App interactions | Firebase Analytics | Required | Analytics |
| App activity | Other user-generated content | Feedback message | **Optional** | App functionality |
| Personal info | Email address | Feedback, optional field | **Optional** | App functionality (replying) |
| App info and performance | Crash logs | Crashlytics | Required | Analytics, app functionality |
| App info and performance | Diagnostics | Crashlytics | Required | Analytics, app functionality |
| Device or other IDs | Device or other IDs | Firebase installation ID; the feedback install id | Required | Analytics |

### Not collected

No location gathered by the app, no contacts, no photos, no files, no
financial or health data, no precise location, nothing read from other apps.
The puzzle engine is entirely offline and no gameplay leaves the device except
inside a feedback message the player chose to send.

### Answers to the other questions

- **Is data encrypted in transit?** Yes. Everything goes over HTTPS.
- **Is data shared with third parties?** No. Google processes it on your
  behalf as a service provider, which Play counts as *collected*, not
  *shared*.
- **Can users request deletion?** See the gap below.

---

## Three things that catch people

**1. Approximate location, via Analytics.** Firebase Analytics derives coarse
location from the IP address. Whether that needs declaring under Location →
Approximate location depends on how Google is reading its own guidance this
month. Check Firebase's own Data Safety page before submitting rather than
trusting this file:
<https://firebase.google.com/docs/android/play-data-disclosure>

**2. The anonymous install id is a "Device or other ID", not a "User ID".**
Play's User IDs category means identifiers tied to an identifiable person —
an account name or number. Ours is a random string, app-scoped, tied to
nothing. Play's own examples list "Firebase installation ID" under Device or
other IDs, which is the closest analogue.

**3. Optional means optional, and it is worth saying so.** The email field and
the feedback message are only collected when somebody deliberately writes in.
Mark both as user-choice rather than required. Marking optional data as
required is the more common mistake and it reads worse on the listing.

---

## One real gap

**Nothing lets a player delete feedback they have sent.** Settings has "reset
all data", but that clears the local database only — a Firestore entry stays.

Play asks whether users can request deletion. Declaring email collection while
offering no route to remove it is the sort of inconsistency review notices.
The cheapest fix is a contact address in the privacy policy that a request can
be sent to; the entry can then be deleted from the console. That is a real
obligation, not a formality, once an email address is involved.

A privacy policy URL is required on the listing for any app that collects
anything, which this one has done since Analytics landed. It needs updating to
cover feedback and to name the deletion route.

---

## Where the data lives

- **Firestore**, `sudoku-48937`, collection `feedback`.
- Rules in `firestore.rules`: create only, shape and size checked; reads,
  updates and deletes refused outright, including to whoever wrote the entry.
  Verified against the live database rather than assumed — a valid write
  returns 200, a bad `kind`, an extra field, an empty message and any read all
  return 403.
- Moderation and deletion happen in the console, deliberately. No client can
  remove anything.
