# Narration Specification

## Problem Statement

The visual reader can display and navigate durable narration blocks, but users
still cannot listen to them. Milestone 4 must narrate those blocks through an
on-device TTS engine while the app is active, advance in source order, expose
deterministic controls, and preserve a narration position independently from
visual browsing.

## Goals

- [ ] Initialize a local TTS engine and expose deterministic availability/errors.
- [ ] Select, preview, and persist available voices and bounded speech speed.
- [ ] Narrate one exact block at a time with play, pause, previous, and next controls.
- [ ] Advance automatically across blocks and chapters without stale callback races.
- [ ] Persist and restore exact per-book narration progress without changing visual position.
- [ ] Synchronize the narrated block with the visual highlight while the app is active.

## Out of Scope

| Feature | Reason |
| --- | --- |
| Background playback, notification, lock screen, media session, audio focus, and Bluetooth | Milestone 5 |
| Sleep timer, pronunciation rules, bookmarks, and configurable paragraph/chapter pauses | Milestone 6 |
| Cloud/neural voices, generated audio, translation, and multiple character voices | Milestone 7 |
| Pitch, volume, rewind by seconds, forward by seconds, and character-offset resume | Not reliable/required for the foreground MVP |
| Narrating raw PDF text or image-only pages | Narration uses processed active blocks only |

---

## Assumptions & Open Questions

| Assumption / decision | Chosen default | Rationale | Confirmed? |
| --- | --- | --- | --- |
| Playback scope | Foreground only; lifecycle pause on inactive/paused/detached | Background media belongs to Milestone 5 | yes |
| Play origin | Recently selected visual block; otherwise valid durable narration position; otherwise first block | Preserves explicit intent without conflating passive visual browsing with progress | yes |
| Pause/resume granularity | Stop TTS and restart current block from its beginning | Character offsets are not portable across device engines | yes |
| End-of-book behavior | Retain last block and mark progress completed | Avoids unexpected wrap and supports future explicit restart | yes |
| Queue unit | One complete `normalizedText` block per engine speak call | Matches stable persisted TTS unit and makes advancement atomic | delegated |
| Manual queue navigation | Previous and next block controls; crossing chapter boundaries follows source order | Required for a usable foreground queue and already promised by RF-005/RF-009 | delegated |
| Default speed | `1.0`; allowed `0.5...2.0` by `0.1` | Deterministic, accessible, testable MVP range | delegated |
| Voice identity | Engine name + locale; global default with optional book override | Device names may repeat across locales; supports user-confirmed preference scope | yes |
| Missing saved voice | First available voice with saved locale, otherwise first sorted available voice | Deterministic recovery after device voice changes | delegated |
| No available engine/voice | Player unavailable with `Nenhuma voz de narração está disponível neste dispositivo` | Exact actionable foreground state | delegated |
| Engine initialization failure | Player error `Não foi possível iniciar a narração` with retry action | Separates transient engine failure from permanent no-voice state | delegated |
| Speak failure | Remain on current block, persist it, enter paused error state, show `Não foi possível narrar este trecho` | Never skip content silently | delegated |
| Progress commit point | Persist completed block before moving to the next; persist current block on pause/close/background/manual navigation | Meets durability without advancing on failed speech | delegated |
| Stale progress | Validate active run/chapter/block; fall back to first block and repair durably | Reprocessing replaces block identities | delegated |
| Callback concurrency | Monotonic playback generation; callbacks from older generations are ignored | Prevents late completion/error after pause/skip from changing current state | delegated |
| Visual synchronization | Active narration changes in-memory reader selection/highlight/scroll; no durable visual-position write | Conforms to AD-007 | delegated |
| Voice preview | Fixed phrase; interrupt/restore paused player state; never mutate progress | Makes preview deterministic and non-destructive | delegated |
| Authentication/rate limits | N/A because TTS and persistence are entirely device-local | No remote/auth boundary | delegated |
| Data expiry | N/A; settings persist until changed, progress until book deletion | Offline continuity has no useful TTL | delegated |
| Observability | Book/block IDs, engine state, voice ID, speed, timing, sanitized error category; never novel text | Diagnoses playback without content leakage | delegated |

**Open questions:** none — all resolved or explicitly delegated.

---

## User Stories

### P1: Initialize foreground narration ⭐ MVP

**User Story**: As a reader, I want the app to detect and initialize local
narration so that I know whether listening is available on my device.

**Why P1**: No playback behavior is valid until the device engine and voices are
known.

**Acceptance Criteria**:

1. WHEN a ready book reader loads THEN the system SHALL initialize the TTS adapter at most once for the application lifecycle and request installed voices.
2. WHEN initialization succeeds with one or more voices THEN the player SHALL enter `ready`, expose the resolved current voice/rate, and make play available.
3. WHEN initialization succeeds with zero voices THEN the player SHALL enter `unavailable`, disable playback, and show `Nenhuma voz de narração está disponível neste dispositivo`.
4. WHEN initialization fails THEN the player SHALL enter `error`, disable playback, show `Não foi possível iniciar a narração`, and expose one accessible retry action.
5. WHEN retry succeeds THEN the player SHALL leave the error state and expose the exact ready voice/rate without duplicating engine handlers.
6. WHEN the book has no valid active narration blocks THEN the player SHALL be unavailable without calling `speak`.

**Independent Test**: Inject success, empty, failure, and retry engine fixtures
and assert exact states, messages, handler count, and zero unintended speech.

### P1: Select and preview voice and speed ⭐ MVP

**User Story**: As a reader, I want to choose how narration sounds so that it is
comfortable and understandable.

**Why P1**: Voice and rate are explicit Milestone 4 requirements.

**Acceptance Criteria**:

1. WHEN voice settings open THEN the player SHALL list installed voices sorted by locale then name and identify the exact resolved selection.
2. WHEN no saved setting exists THEN the system SHALL select the first sorted available voice and rate `1.0`.
3. WHEN the user selects a voice or valid rate THEN the adapter SHALL receive the exact voice name/locale and normalized rate before the next book speech.
4. WHEN rate decreases or increases THEN it SHALL remain in `0.5...2.0` and change only by `0.1`; the unavailable boundary action SHALL be disabled.
5. WHEN a global setting changes THEN the complete global narration setting SHALL persist atomically.
6. WHEN a per-book override is enabled or changed THEN the complete override SHALL persist for only that book and take precedence over global settings.
7. WHEN a per-book override is removed THEN that book SHALL immediately resolve to current global settings.
8. WHEN a saved voice is missing THEN resolution SHALL choose the first sorted voice with the saved locale, otherwise the first sorted voice overall, and persist the repaired identity.
9. WHEN voice preview is requested THEN the adapter SHALL speak exactly `Esta é uma amostra da voz selecionada`, SHALL not update book progress, and SHALL restore the prior non-playing state after completion/error.
10. WHEN the application restarts THEN global settings and every book override SHALL resolve to their exact durable values.

**Independent Test**: Seed multiple voices/locales, change global and book
settings, preview, remove a saved voice, restart, and verify exact resolution,
adapter calls, durability, and unchanged progress.

### P1: Play and pause the current narration block ⭐ MVP

**User Story**: As a reader, I want to play and pause narration directly in the
reader so that I can alternate between reading and listening.

**Why P1**: Play/pause is the central interaction of this milestone.

**Acceptance Criteria**:

1. WHEN play is activated after an explicit visual block selection THEN the player SHALL make that active-run block current and send its exact `normalizedText` once to `speak`.
2. WHEN play is activated without a newer explicit selection THEN the player SHALL use valid durable narration progress, otherwise the first source-order block.
3. WHEN speech starts THEN state SHALL be `playing`, the exact current chapter/block SHALL be exposed, and the reader SHALL highlight/scroll to that block in memory.
4. WHEN pause is activated while playing THEN the adapter SHALL stop once, state SHALL become `paused`, and the exact current progress SHALL persist without marking the block completed.
5. WHEN play resumes from paused THEN the same complete block text SHALL be sent from its beginning exactly once.
6. WHEN pause/play is activated repeatedly while its transition is pending THEN the player SHALL perform only one corresponding adapter operation.
7. WHEN the reader changes visual chapters/blocks without pressing play THEN durable narration progress SHALL remain unchanged.
8. WHEN a speak or stop operation fails THEN the player SHALL stay on the current block, persist it, enter `paused` with `Não foi possível narrar este trecho`, and ignore completion from that failed generation.

**Independent Test**: Select a block, play/pause/resume with delayed adapter
operations and visual browsing, asserting exact text, states, call counts,
highlight, progress, and failure behavior.

### P1: Advance through the narration queue ⭐ MVP

**User Story**: As a listener, I want narration to continue through the book so
that I do not need to operate the screen after every paragraph.

**Why P1**: Continuous ordered narration is the product's main value.

**Acceptance Criteria**:

1. WHEN the adapter reports successful completion THEN the player SHALL persist the completed current block before sending the next source-order block to `speak`.
2. WHEN the next block is in another chapter THEN the player SHALL advance to that chapter's first block and update the visual highlight in the same state transition.
3. WHEN the final block completes THEN progress SHALL retain that block, set `completed=true`, state SHALL become `completed`, and no additional `speak` call SHALL occur.
4. WHEN next is activated before the end THEN the adapter SHALL stop the current generation, persist the selected next block as incomplete, and speak it only if the player was playing.
5. WHEN previous is activated THEN the adapter SHALL stop the current generation, persist the immediately previous source-order block as incomplete, and speak it only if the player was playing.
6. WHEN previous is activated on the first block or next on the final completed block THEN state, progress, and adapter calls SHALL remain unchanged.
7. WHEN a stale completion/error callback arrives after pause, skip, preview, reload, or a newer play generation THEN it SHALL have no effect on state, progress, highlight, or queue.
8. WHEN block transition is requested THEN the new state/highlight SHALL be observable within 500 ms without blocking frame pumping.

**Independent Test**: Run a multi-chapter queue with delayed/out-of-order
callbacks and manual boundaries, verifying exact persistence-before-speak,
cross-chapter state, terminal behavior, and callback isolation.

### P1: Persist and restore narration progress ⭐ MVP

**User Story**: As a listener, I want narration to resume where I stopped so
that closing or interrupting the app does not lose my place.

**Why P1**: Durable continuity is required by RF-010 and RNF-003.

**Acceptance Criteria**:

1. WHEN narration progress is stored THEN it SHALL contain book ID, active run ID, chapter ID, block ID, completed flag, resolved voice name/locale, rate, and UTC update time as one atomic record.
2. WHEN pause, route close, app inactive/paused/detached, manual block navigation, or successful block completion occurs THEN the latest current progress SHALL persist before lifecycle completion/queue advancement.
3. WHEN overlapping progress saves target one book THEN durable order SHALL follow request order and the newest requested complete record SHALL win.
4. WHEN a book reopens with valid incomplete progress for its active run THEN the player SHALL restore the exact chapter/block in `ready` without speaking automatically.
5. WHEN restored progress is completed THEN the player SHALL restore the last block in `completed` without speaking automatically.
6. WHEN progress references another/old active run, foreign chapter/block, or missing block THEN the player SHALL fall back to the first source-order block, set `completed=false`, and persist the repaired record.
7. WHEN a progress write fails THEN current state SHALL remain usable, no later write SHALL be abandoned, and the player SHALL show `Não foi possível salvar o progresso da narração` once for that failed write.
8. WHEN a book is deleted THEN its narration progress and book override SHALL be deleted in the same database cascade while global narration settings remain.
9. WHEN the player closes or app lifecycle pauses THEN it SHALL await its latest progress write after stopping the engine.

**Independent Test**: Persist, overlap, fail, close, restart, reprocess, and delete
against a file-backed database while asserting complete records, repair,
ordering, lifecycle waits, and cascades.

### P1: Operate an accessible foreground player ⭐ MVP

**User Story**: As a reader using touch or assistive technology, I want playback
controls in the reader so that narration is operable without navigating away.

**Why P1**: The player must be usable by the product's target readers.

**Acceptance Criteria**:

1. WHEN the reader is ready THEN a persistent foreground player bar SHALL expose current chapter title, play/pause, previous block, next block, voice, and speed controls.
2. WHEN player state changes THEN the play/pause control label and enabled state SHALL match exactly `ready`, `playing`, `paused`, `completed`, `unavailable`, or `error`.
3. WHEN a block is narrated THEN the existing text reader SHALL identify that exact block as selected and bring it into view without persisting visual position.
4. WHEN controls are shown THEN each SHALL have an accessible Portuguese label, minimum 48×48 logical-pixel target, and selected/disabled semantics where applicable.
5. WHEN the app enters inactive, paused, or detached lifecycle state THEN the UI SHALL synchronously stop presenting `playing`, request engine stop, and persist current progress.
6. WHEN the user returns from lifecycle pause THEN the player SHALL remain paused and SHALL not resume automatically.
7. WHEN the combined Milestone 3–4 UAT is performed THEN it SHALL verify text/PDF reader continuity, themes, font settings, voice selection, play/pause, automatic block/chapter advance, highlighted paragraph, speed, restart restore, and foreground lifecycle pause.

**Independent Test**: Render the reader with every player state and lifecycle
transition, inspect exact semantics/targets/highlight, and execute the combined
manual UAT checklist on a device.

---

## Edge Cases

- WHEN a chapter has zero narration blocks THEN the queue SHALL skip it in both automatic and manual source-order traversal.
- WHEN all chapters have zero blocks THEN playback SHALL be unavailable without invoking TTS.
- WHEN a block contains multilingual Unicode text THEN `normalizedText` SHALL reach the adapter unchanged.
- WHEN the selected visual block belongs to stale content THEN play SHALL use repaired durable progress or the first active block.
- WHEN the chosen voice disappears between resolution and `speak` THEN the player SHALL re-resolve once and retry the same block once; a second failure uses the standard speak error without advancing.
- WHEN engine completion fires twice for one generation THEN only the first callback SHALL advance/persist.
- WHEN stop triggers a completion callback on a device engine THEN the invalidated generation SHALL prevent advancement.
- WHEN global settings change while a book override exists THEN that book's resolved settings SHALL remain unchanged.
- WHEN the active run is replaced while playback is open THEN the next operation SHALL stop the old generation, reload active content, repair progress, and never speak an old block.
- WHEN the player is disposed with no current block THEN it SHALL stop safely and perform no progress write.

---

## Implicit-Requirement Dimensions

| Dimension | Resolution |
| --- | --- |
| Input validation & bounds | Voice name+locale required; rate 0.5–2.0 by 0.1; active-run/chapter/block ownership; legal player transitions |
| Failure / partial failure | Exact init/no-voice/speak/save states; no silent skip or auto-advance after failure |
| Idempotency / retry / duplicates | Init once; one retry for disappearing voice; duplicate transitions/callbacks ignored |
| Auth boundaries & rate limits | N/A because engine and persistence are device-local |
| Concurrency / ordering | Playback generation invalidates stale callbacks; per-book write tails enforce newest-request order |
| Data lifecycle / expiry | Global setting persists; book progress/override cascade on deletion; no TTL |
| Observability | IDs/state/voice/rate/duration/sanitized category only; no novel text |
| External-dependency failure | Adapter isolates TTS engine and all handler/error behavior; player remains deterministic |
| State-transition integrity | Explicit state machine, active-run validation, persistence-before-advance, lifecycle pause |

---

## Requirement Traceability

| Requirement ID | Story | Phase | Status |
| --- | --- | --- | --- |
| NAR-01 | Initialize foreground narration | Validate | Implemented |
| NAR-02 | Select and preview voice and speed | Validate | Implemented |
| NAR-03 | Play and pause current block | Validate | Implemented |
| NAR-04 | Advance through narration queue | Validate | Implemented |
| NAR-05 | Persist and restore narration progress | Validate | Implemented |
| NAR-06 | Accessible foreground player | Validate | Implemented |

**Coverage:** 6 total, 6 mapped to tasks, 0 pending design.

---

## Success Criteria

- [ ] A local available voice narrates exact active blocks in source order without sending text off-device.
- [ ] Play/pause/manual/automatic transitions remain deterministic under delayed and duplicate callbacks.
- [ ] Voice/rate settings and complete narration progress survive restart and repair stale content safely.
- [ ] Reader highlight follows narration while durable visual and narration positions remain separate.
- [ ] Foreground lifecycle pause, accessibility, analysis, full tests, Android build, and combined Milestone 3–4 UAT pass.
