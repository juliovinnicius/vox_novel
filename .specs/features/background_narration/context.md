# Background Narration Context

**Gathered:** 2026-08-26
**Spec:** `.specs/features/background_narration/spec.md`
**Status:** Ready for design

---

## Feature Boundary

Narration keeps playing with the app backgrounded, the screen locked, or the app
swiped out of recents; it is controllable from a notification, the lock screen,
and external media controls including Bluetooth; it yields and reclaims audio
focus; and reopening the app attaches to the live session without a gap.

The sleep timer, pronunciation rules, bookmarks, and statistics stay in
Milestone 6. Nothing here changes the web download queue or PDF processing.

---

## Implementation Decisions

### Notification and lock-screen controls

- Three actions: previous, play/pause, next.
- Previous and next move **one narration block**, the same unit the in-app
  buttons move — not one chapter. The driving case is repeating a paragraph you
  stopped paying attention to, which chapter-level skipping cannot do.
- The notification names the book on its primary line and the chapter on its
  secondary line. No block number: meaningless out of context.
- No speed control on the notification: sixteen discrete values do not fit a
  media action row.

### Audio focus and interruptions

- **Transient loss** (phone call, navigation prompt): pause, then resume
  automatically when focus returns. Audiobook behaviour.
- **Permanent loss** (the reader starts Spotify or YouTube): pause and stay
  paused. The reader chose other audio; talking over it would be a fight for the
  speaker. The notification stays so resuming is one tap.
- Ducking is not an option for speech — lowering the volume of a narration makes
  it unintelligible rather than unobtrusive. The choice is pause or ignore, and
  it is pause.
- Resuming after any focus loss restarts the interrupted block from its
  beginning, consistent with how pause already behaves in the foreground.

### Service lifetime

- Swiping the app out of recents does **not** stop narration. That is Android
  media-player behaviour, and clearing recents is something people do without
  meaning to stop their audio.
- Reaching the last block stops playback, ends the session, and removes the
  notification. Nothing left to narrate, so holding a service and a lock-screen
  control would be noise.
- The notification is dismissible only while paused, and dismissing it ends the
  session. (Agent default — not discussed; recorded as an assumption in the
  spec.)

### Reopening the app during playback

- Attach to the running session with **no gap and no restart** in speech. The
  in-app player takes the session's real state rather than restoring its own.
- The reader jumps to and highlights the block being spoken, the same rule that
  already applies with the app open. Keeping it avoids two competing notions of
  "where I am".
- Note this is a deliberate narrowing of AD-007, which keeps the visual reading
  position separate from narration progress: AD-007 still governs what is
  *persisted*, while this decision governs only what is *shown* on attach.
- Only one narration session exists at a time; opening a different book ends the
  previous session first.

### Agent's Discretion

- Notification styling, icon, and text formatting beyond the book/chapter lines.
- Whether the media session is expressed through an existing Flutter package or a
  platform channel — a Design decision, pending the Knowledge Verification Chain.
- How the session's state is transported to the UI layer (stream, listener, or
  the existing Cubit registry).

### Declined / Undiscussed Gray Areas → Assumptions

All four offered gray areas were discussed. Four sub-points inside them went
undiscussed and are recorded in the spec's Assumptions table with a default and
rationale: notification dismissal, notification content, headphones unplugged
(specified at P2 as BGN-09), and a denied notification permission.

---

## Specific References

- AD-008 anticipated this work: foreground narration was deliberately placed
  behind the `NarrationEngine` adapter and a route-scoped Cubit so that
  "Milestone 5 can replace foreground ownership with a media service". That
  adapter is the intended seam.
- The behaviour being inverted lives at
  `lib/features/narration/presentation/widgets/reader_narration_host.dart:63`
  (`didChangeAppLifecycleState` → `NarrationCubit.onAppLifecyclePause`).
- `.specs/features/narration/uat.md` UAT-10 asserts the old behaviour and must be
  rewritten by this feature.
- `AndroidManifest.xml` currently declares no service and no permissions.

---

## Deferred Ideas

- **Sleep timer** — Milestone 6. Raised while scoping; it depends on this base.
- **Cover art in the notification** — most imported books have no `coverPath`;
  revisit when covers are common.
- **Speed control from the notification** — does not fit a media action row.
