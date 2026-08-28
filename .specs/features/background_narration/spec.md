# Background Narration Specification

**Milestone**: 5 — Segundo plano (`docs/spec.md`)
**Date**: 2026-08-26

## Problem Statement

Narration today lives entirely in the foreground: leaving the app or locking the
screen pauses it (`reader_narration_host.dart` → `NarrationCubit.onAppLifecyclePause`).
That defeats the product's core promise — hearing a novel while working,
driving, walking, or doing chores — because every one of those situations means
the screen is off or another app is in front. A reader who wants twenty minutes
of narration has to keep the app open and the screen awake.

## Goals

- [ ] Narration keeps playing with the app backgrounded, the screen locked, or
      the app swiped out of recents.
- [ ] The reader can play, pause, and move a paragraph in either direction
      without unlocking the phone — from the notification, the lock screen, or a
      Bluetooth headset.
- [ ] Audio focus is honoured in both directions: narration yields to a call and
      comes back, and yields permanently to another audio app.
- [ ] Reopening the app reconnects to the live session without a gap in speech.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Sleep timer | Milestone 6. Depends on this base existing; the user scoped it out on 2026-08-26 to keep this feature's boundary clean. |
| Pronunciation rules, bookmarks, statistics | Milestone 6. |
| Pre-generating audio files | `docs/spec.md` §5.2 excludes permanent audiobook generation from the MVP. |
| Cover art in the notification | Books have an optional `coverPath` and most imports have none; a metadata-only notification is the MVP. Recorded as an assumption below. |
| Playback speed control from the notification | Speed is a settings-sheet concern with sixteen discrete values; it does not fit a media notification's action row. |
| iOS / macOS background audio | `docs/spec.md` targets Android first; the other platforms have no narration entry point yet. |
| Web download queue behaviour | Owned by `web_source_import`. Narration's download boundary (WEB-04 AC4) already exists and is unchanged here. |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Sleep timer belongs to Milestone 6 | Out of scope here | User decision, 2026-08-26 | y |
| Notification actions | Previous, play/pause, next | User decision, 2026-08-26 | y |
| What previous/next skip | One narration block, matching the in-app buttons | User decision, 2026-08-26 | y |
| Transient focus loss (call, navigation prompt) | Pause, then resume automatically | User decision, 2026-08-26 | y |
| Permanent focus loss (another audio app) | Pause and stay paused; notification remains | User decision, 2026-08-26 | y |
| App swiped out of recents | Narration continues | User decision, 2026-08-26 | y |
| End of book | Stop and end the service | User decision, 2026-08-26 | y |
| Reopening during playback | Reconnect with no gap in speech | User decision, 2026-08-26 | y |
| Reader position on reopen | Follows the narrated block | User decision, 2026-08-26 | y |
| Dismissing the notification | Dismissal is only possible while paused | **Confirmed by the platform, not a choice**: `audio_service` asserts that a non-dismissible notification requires dropping foreground state on pause, so "ongoing while playing, dismissible while paused" is the only configuration available (T2 spike, 2026-08-28). | y |
| Notification content | Book title as the primary line, chapter title as the secondary line | The two facts a listener needs to confirm what is playing; block numbers are meaningless out of context. Not discussed with the user. | n |
| Headphones unplugged | Pause (see BGN-09, P2) | Standard media behaviour: audio must not jump to the speaker. Not discussed with the user; kept at P2 so it can be dropped without touching P1. | n |
| Notification permission denied (Android 13+) | Narration still plays; the app states once that controls are unavailable outside it | Refusing to play would punish the reader for a permission the core feature does not need. Platform behaviour to be confirmed during Design. | n |

**Open questions:** none — every ambiguity above is either confirmed with the
user or recorded with a chosen default and rationale.

### Known impact outside this feature

`.specs/features/narration/uat.md` UAT-10 asserts the *current* behaviour —
"background the app … foreground speech stops, narration remains paused with no
automatic resume". This feature deliberately inverts it. That UAT case must be
rewritten as part of this work; it is not a regression.

---

## Implicit-Requirement Dimensions Sweep

| Dimension | Resolution |
| --- | --- |
| Input validation & bounds | N/A because this feature adds no new user input. Voice, rate, and block bounds are already validated by the narration feature and are unchanged. |
| Failure / partial-failure states | BGN-10, BGN-11 — the service failing to start and the speech engine dying mid-block. |
| Idempotency / retry / duplicate handling | BGN-12 — the same command arriving from two surfaces, and reconnect never starting a second session. |
| Auth boundaries & rate limits | N/A because the feature makes no network or account-bound calls; it is entirely on-device. |
| Concurrency / ordering | BGN-12 — commands from the app, the notification, and media buttons are serialized in arrival order. |
| Data lifecycle / expiry | BGN-13 — durable progress keeps being written from the background, and the session's resources are released when it ends. |
| Observability | N/A because the project has no logging or metrics infrastructure and this feature adds no remote dependency. Failures surface as user-visible state and messages, which the ACs assert. |
| External-dependency failure | BGN-10, BGN-11, BGN-14 — the platform service, the TTS engine, and a denied notification permission. |
| State-transition integrity | BGN-06, BGN-12 — one playback state across every surface, with no transition reachable from one surface that the others cannot represent. |

---

## User Stories

### P1: Keep narrating in the background ⭐ MVP

**User Story**: As a reader, I want narration to keep playing when I leave the
app or lock the screen so that I can listen while doing something else.

**Why P1**: This is the milestone. Without it the product's core promise — a
novel you listen to while your hands and eyes are busy — does not exist.

**Acceptance Criteria**:

1. WHEN narration is playing and the app moves to the background THEN the system
   SHALL continue speaking without interruption and SHALL NOT pause.
2. WHEN narration is playing and the screen locks THEN the system SHALL continue
   speaking.
3. WHEN narration is playing and the app is swiped out of the recents list THEN
   the system SHALL continue speaking.
4. WHEN narration starts THEN the system SHALL hold a foreground media session
   for as long as playback is active or paused, and SHALL release it when the
   session ends.
5. WHEN narration advances blocks in the background THEN the system SHALL persist
   chapter and block progress exactly as it does in the foreground.

**Independent Test**: Start narration, lock the screen, and hear several
paragraphs play in order; relaunch and find progress at the paragraph reached.

---

### P1: Control narration without unlocking the phone ⭐ MVP

**User Story**: As a reader, I want play, pause, and paragraph navigation from
the notification and the lock screen so that I do not have to look at the app.

**Why P1**: `docs/spec.md` §5.1 lists notification and lock-screen controls as
MVP, and background playback with no way to stop it is worse than none.

**Acceptance Criteria**:

6. WHEN a narration session is active THEN the system SHALL show a notification
   offering previous, play/pause, and next, and SHALL show the same controls on
   the lock screen.
7. WHEN the reader presses play or pause on the notification or lock screen THEN
   the system SHALL apply it to the running session and SHALL reflect the new
   state on every surface, including the in-app player.
8. WHEN the reader presses next or previous THEN the system SHALL move exactly
   one narration block in that direction — the same unit the in-app buttons move
   — and SHALL begin the destination block from its start.
9. WHEN the notification is displayed THEN it SHALL name the book being narrated
   and the chapter currently playing.
10. WHEN the reader presses next on the last block of the book THEN the system
    SHALL keep the completed state, SHALL NOT wrap to the start, and SHALL NOT
    speak again.

**Independent Test**: With the screen locked, pause, resume, and step back one
paragraph using only the lock-screen controls, then open the app and see the
in-app player showing that same paragraph and state.

---

### P1: Yield audio to the rest of the phone ⭐ MVP

**User Story**: As a reader, I want narration to get out of the way of calls and
other audio so that it never talks over something that matters.

**Why P1**: An on-device speech app that ignores audio focus is unusable in the
situations this product targets — driving with navigation, walking with the
phone in a pocket.

**Acceptance Criteria**:

11. WHEN audio focus is lost transiently, such as during a phone call or a
    navigation prompt THEN the system SHALL pause narration, and WHEN focus
    returns THEN it SHALL resume from the block it paused on.
12. WHEN audio focus is lost permanently, such as another app starting playback
    THEN the system SHALL pause narration and SHALL remain paused when focus
    returns, keeping its notification available.
13. WHEN narration resumes after any focus loss THEN it SHALL restart the
    interrupted block from its beginning rather than mid-sentence.

**Independent Test**: Start narration, place a call to the device, and hear
narration stop for the call and resume afterwards; then start Spotify and find
narration paused and staying paused.

---

### P1: Control narration from a headset ⭐ MVP

**User Story**: As a reader, I want the buttons on my Bluetooth headset or car
to control narration so that I can listen without touching the phone.

**Why P1**: `docs/spec.md` Milestone 5 names Bluetooth explicitly, and the
listening situations the product targets are exactly the ones where the phone is
out of reach.

**Acceptance Criteria**:

14. WHEN a media play, pause, or play/pause command arrives from a headset, a
    car, or any external media control THEN the system SHALL apply it to the
    running session identically to the notification's own controls.
15. WHEN a media next or previous command arrives from an external control THEN
    the system SHALL move one narration block, matching AC 8.

**Independent Test**: Pair a Bluetooth headset, start narration, and pause,
resume, and skip a paragraph using only the headset buttons.

---

### P1: Come back to a session already playing ⭐ MVP

**User Story**: As a reader, I want opening the app during narration to show me
what is playing so that the app and the audio never disagree.

**Why P1**: Without it, reopening either cuts the audio or shows a player that
contradicts what the reader is hearing.

**Acceptance Criteria**:

16. WHEN the reader opens the app while a background session is playing THEN the
    system SHALL attach to that session with no gap or restart in speech.
17. WHEN the app attaches to a running session THEN the in-app player SHALL show
    that session's exact state — status, book, chapter, and block — rather than
    a freshly restored one.
18. WHEN the app attaches to a running session and the reader opens the book
    being narrated THEN the reader SHALL show and highlight the block being
    spoken.
19. WHEN the reader opens a book other than the one being narrated THEN the
    system SHALL stop the previous session before starting a new one, so that
    only one narration session exists at a time.

**Independent Test**: Start narration, background the app for a minute, reopen
it, and find speech uninterrupted with the player and the reader both on the
paragraph being spoken.

---

### P2: Pause when the headphones come out

**User Story**: As a reader, I want narration to stop when I unplug my
headphones so that my book is not suddenly broadcast to the room.

**Why P2**: Standard media behaviour and a real embarrassment when missing, but
it is not part of the milestone's named scope and can ship after P1.

**Acceptance Criteria**:

20. WHEN the audio output becomes noisy — wired headphones unplugged or a
    Bluetooth device disconnected — THEN the system SHALL pause narration and
    SHALL NOT continue on the device speaker.

**Independent Test**: Play through headphones, unplug them, and hear silence
rather than the speaker.

---

## Edge Cases

- WHEN the foreground service cannot be started THEN the system SHALL keep
  narration working in the foreground and SHALL state once that background
  playback is unavailable, rather than failing the play action.
- WHEN the speech engine reports an error mid-block THEN the system SHALL surface
  the existing narration error state on every surface and SHALL NOT leave a
  notification claiming playback.
- WHEN the notification permission is denied THEN narration SHALL still play, and
  the system SHALL state once that controls outside the app are unavailable.
- WHEN a play command and a pause command arrive from two surfaces at nearly the
  same moment THEN the system SHALL apply them in arrival order and SHALL end in
  a state every surface agrees on.
- WHEN a next command arrives while the queue is waiting on an undownloaded web
  chapter THEN the system SHALL keep reporting the awaiting-download state rather
  than ending the book.
- WHEN the book being narrated is deleted while a session is active THEN the
  system SHALL end the session and remove its notification.
- WHEN the device is rebooted or the process is killed by the system THEN
  narration SHALL NOT restart on its own, and the persisted block SHALL be the
  last one completed.

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| BGN-01 | P1: Keep narrating in the background | Specify | Pending |
| BGN-02 | P1: Keep narrating in the background (session lifetime) | Specify | Pending |
| BGN-03 | P1: Keep narrating in the background (progress from background) | Specify | Pending |
| BGN-04 | P1: Control without unlocking (notification and lock screen) | Specify | Pending |
| BGN-05 | P1: Control without unlocking (block navigation) | Specify | Pending |
| BGN-06 | P1: Control without unlocking (one state across surfaces) | Specify | Pending |
| BGN-07 | P1: Yield audio (transient focus loss) | Specify | Pending |
| BGN-08 | P1: Yield audio (permanent focus loss) | Specify | Pending |
| BGN-09 | P2: Pause when the headphones come out | - | Pending |
| BGN-10 | Edge: foreground service unavailable | Specify | Pending |
| BGN-11 | Edge: speech engine failure during background playback | Specify | Pending |
| BGN-12 | Edge: concurrent commands and duplicate attach | Specify | Pending |
| BGN-13 | P1: Keep narrating in the background (resource release) | Specify | Pending |
| BGN-14 | Edge: notification permission denied | Specify | Pending |
| BGN-15 | P1: Control from a headset | Specify | Pending |
| BGN-16 | P1: Come back to a session already playing | Specify | Pending |
| BGN-17 | P1: Come back to a session already playing (reader follows) | Specify | Pending |
| BGN-18 | P1: Come back to a session already playing (single session) | Specify | Pending |

**ID format:** `BGN-[NUMBER]`

**Status values:** Pending → In Design → In Tasks → Implementing → Verified

**Coverage:** 18 total, 0 mapped to tasks, 18 unmapped ⚠️ (Design pending)

---

## Success Criteria

- [ ] A reader starts narration, locks the phone, and listens to a full chapter
      without touching it.
- [ ] Every control on the lock screen and on a Bluetooth headset produces the
      same result as its in-app counterpart.
- [ ] A phone call interrupts narration and narration comes back by itself;
      starting another audio app does not bring it back.
- [ ] Reopening the app during playback never produces a gap, a restart, or a
      player that disagrees with what is being heard.
- [ ] Existing narration, reader, and web-source tests pass unchanged, except
      the deliberate inversion of background-pause behaviour.
