# Narration Context

**Gathered:** 2026-07-18
**Spec:** `.specs/features/narration/spec.md`
**Status:** Ready for confirmation

---

## Feature Boundary

Milestone 4 adds foreground, on-device TTS narration to processed narration
blocks: engine initialization, available voice selection, block queue,
play/pause, automatic advancement, bounded speed, durable narration progress,
and synchronization with the visual reader. Background playback, media
notifications, lock-screen controls, audio focus, Bluetooth, sleep timer, and
pronunciation rules remain outside this milestone.

---

## Implementation Decisions

### Starting and resuming

- An explicit play action after the user selects a paragraph starts from that
  selected block.
- Otherwise play resumes the last valid durable narration progress.
- A paused block resumes from its beginning because character-offset pause
  support is inconsistent across device TTS engines.
- Manual previous/next block controls are included so the foreground player can
  navigate its queue deterministically.

### Voice and speed

- The app stores one global voice/rate preference and permits an optional
  per-book override.
- Default speed is `1.0`; allowed speed is `0.5...2.0` in increments of `0.1`.
- Voice identity is the engine-provided name plus locale. Missing saved voices
  fall back deterministically to the first available voice for the saved
  locale, then the first available voice overall.
- Voice preview speaks the fixed phrase `Esta é uma amostra da voz selecionada`
  and never changes book progress.

### Queue and completion

- The engine receives exactly one complete `normalizedText` block at a time.
- A successful completion persists that block as completed before advancing to
  the next block/chapter.
- At the end of the book, the last block remains durable and progress is marked
  completed; it does not wrap to the beginning.
- Pause, route close, app backgrounding, manual skip, or a new play generation
  invalidates older engine callbacks so stale completion cannot advance state.

### Reader synchronization

- The actively narrated block drives the reader highlight and automatic scroll
  in memory.
- Visual browsing remains separate from durable narration progress per AD-007.
- Selecting text does not mutate narration progress until the user presses play.

### Foreground lifecycle

- Narration is foreground-only in Milestone 4.
- When the app becomes inactive/paused/detached, narration pauses, the engine
  stops, and current progress is persisted.
- Milestone 5 will replace this constraint with a background media service.

### Agent's Discretion

- Exact player bar spacing, icons, animations, and responsive layout, provided
  controls remain accessible and operable without leaving the reader.
- Internal adapter and callback-token implementation details.

---

## Specific References

No external player reference was requested. Follow the current reader's Material
design and accessibility language.

---

## Deferred Ideas

- Background audio, notification, lock screen, focus and Bluetooth: Milestone 5.
- Sleep timer and pronunciation rules: Milestone 6.
- Pitch, volume, paragraph/chapter pauses, neural/cloud voices, and generated
  audio: later milestones.

