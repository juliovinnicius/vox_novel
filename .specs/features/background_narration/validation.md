# Background Narration Validation

**Date**: 2026-08-29
**Spec**: `.specs/features/background_narration/spec.md`
**Diff range**: `main..HEAD` (`8be4c1e`..`b13dfd0`, 19 commits, branch `feat/background-narration`)
**Verifier**: independent sub-agent (author ≠ verifier), read-only over the real tree

**Verdict**: ❌ **FAIL** — 3 P1 gaps and 1 spec edge case are not delivered on a
user-reachable path. The build gate is green and the discrimination sensor is
mostly healthy; the failures are behavioural, not cosmetic.

---

## Task Completion

| Task | Status | Notes |
| --- | --- | --- |
| T1 | ✅ Done | Manifest + pubspec + `background_narration_platform_test.dart` (5 tests) |
| T2 | ✅ Done | Spike measured on device, recorded in design Research Findings; no spike code in the tree |
| T3 | ✅ Done | `NarrationSessionState` + 8 tests |
| T4 | ⚠️ Partial | Session exists and carries the extracted logic, but `stop()` has no behavioural test and never leaves `playing` (Gap 2); command serialisation was specified as a tail future and shipped as a drop-guard (Gap 4) |
| T5 | ✅ Done | All 27 pre-existing `narration_cubit_test.dart` tests still present; 2 close-tests deliberately replaced (see Coverage Moved, below) |
| T6 | ⚠️ Partial | Session registered app-scoped, registry reduced to an attach point; `LibraryService → NarrationSession` wiring is untested (sensor M10 survived) |
| T7 | ✅ Done | Handler + 11 tests, all mutations killed |
| T8 | ⚠️ Partial | `AudioFocusMonitor` fully covered (13 tests); its platform adapter `AudioSessionInterruptions` has **no test at all** (sensor M11 survived) |
| T9 | ✅ Done | Lifecycle observer removed; 3 inverted widget tests + 1 structural test |
| T10 | ✅ Done | Composition seam, fire-and-forget, 6 media-session integration tests |
| T11 | ✅ Done | Import-scanning arch test + the `androidForceEnableMediaButtons()` source guard |
| T12 | ✅ Done | Degradation covered at session and composition level |
| T16 | ✅ Done | Permission asked once per session, denial warns, granted stays silent |
| T13 | ✅ Done | Becoming-noisy fully covered (P2) |
| T14 | ⚠️ Partial | `LibraryService` and `NarrationSession` sides both tested; the wire between them is not |
| T15 | ✅ Done | 19 numbered UAT cases |

---

## Spec-Anchored Acceptance Criteria

Legend: **[A]** automated · **[D]** device-only, covered by a numbered UAT case ·
**[A+D]** automated state machine, device confirmation in UAT.

### P1: Keep narrating in the background

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC1 — app backgrounds → keeps speaking, does not pause | status stays `playing`, engine not stopped | `test/features/narration/presentation/widgets/reader_narration_host_test.dart:73` — `expect(fixture.cubit.state.status, NarrationStatus.playing)` + `expect(fixture.engine.stops, 0)`, run for `inactive`/`paused`/`detached`; structural guard at `:93` — `expect(tester.state(...), isNot(isA<WidgetsBindingObserver>()))` | ✅ PASS **[A]** |
| AC2 — screen locks → keeps speaking | speech continues, lock screen shows transport | — genuinely device-only | ⏭️ **[D]** UAT-03 |
| AC3 — swiped from recents → keeps speaking | speech continues | — device-only; measured in T2 spike (4 paragraphs / 19 s). Host activity asserted at `test/architecture/background_narration_platform_test.dart:53` — `expect(activity, contains('AudioServiceActivity'))` | ⏭️ **[D]** UAT-05 |
| AC4 — hold a foreground media session while active or paused, release when the session ends | service held; released on end | Config: `background_narration_platform_test.dart:30` (`foregroundServiceType="mediaPlayback"`), `:42` (MediaButtonReceiver). Release: `test/features/narration/data/services/narration_audio_handler_test.dart:61` — `expect(handler.playbackState.value.playing, isFalse)` after `stop()`. **The hold/release configuration in `narration_media_session.dart` (`androidNotificationOngoing`/`androidStopForegroundOnPause`) has no test**, and the handler cancels its session subscription permanently on `stop()`, so a session restarted after a notification dismissal is never mirrored again | ⚠️ Partial **[A+D]** UAT-14, UAT-15 |
| AC5 — progress persisted in the background exactly as in the foreground | same `reading_progress` rows on the same transitions | `test/features/narration/domain/services/narration_session_test.dart:125` — `expect(repository.progressSaves.last.blockId, 'block-1')` (pause); `:170` — `expect(repository.progressSaves.last.blockId, 'block-2')` + `.completed isFalse` (navigate); `:210` — `expect(repository.progressSaves.last.completed, isTrue)` (end of book). Persistence is background-agnostic by construction (the session has no lifecycle input) | ✅ PASS **[A]** |

### P1: Control narration without unlocking the phone

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC6 — notification offers previous / play-pause / next, same on the lock screen | exactly those three controls, previous/next hidden at the ends | `narration_audio_handler_test.dart:75` — `expect(controls, [MediaControl.skipToPrevious, MediaControl.pause, MediaControl.skipToNext])`; `:87` play control when paused; `:126` no previous on the first block; `:139` no next on the last. Lock-screen rendering itself is device-only | ✅ PASS **[A]** + UAT-03 |
| AC7 — play/pause from notification or lock screen applies to the running session and is reflected on every surface | one command → one session call; every surface re-renders the same value | `narration_audio_handler_test.dart:40` — `expect(playback.calls, ['play','pause','next','previous'])`; `:99` — `expect(handler.playbackState.value.playing, isFalse)` after an app-side change; `test/app/dependency_injection/configure_dependencies_test.dart:301` — `expect(session.state.status, NarrationStatus.paused)` proves the composed monitor and the played session are the same instance | ✅ PASS **[A]** |
| AC8 — next/previous move exactly one block, destination starts from its beginning | one block, whole text re-spoken | `narration_session_test.dart:150` — `expect(session.state.current?.blockId, 'block-2')`; `:159` previous; `:190` — `expect(engine.spoken, ['Texto 1','Texto 2'])`; `narration_audio_handler_test.dart:51` | ✅ PASS **[A]** |
| AC9 — notification names the book and the chapter playing | book on the primary line, chapter on the secondary | `narration_audio_handler_test.dart:117` — `expect(handler.mediaItem.value?.title, 'Obra sintética')` + `expect(handler.mediaItem.value?.artist, 'Capítulo 1')` | ✅ PASS **[A]** |
| AC10 — next on the last block keeps completed, does not wrap, does not speak | status stays `completed`, block unchanged, `spoken` unchanged | `narration_session_test.dart:233` — `expect(session.state.status, NarrationStatus.completed)` + `expect(session.state.current?.blockId, 'block-1')`; `:222` — `expect(engine.spoken, ['Texto 1'])` | ✅ PASS **[A]** |

### P1: Yield audio to the rest of the phone

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC11 — transient loss pauses; returning focus resumes from the block it paused on | pause then play, same block | `test/features/narration/domain/services/audio_focus_monitor_test.dart:31` — `expect(playback.calls, ['pause'])`; `:39` — `expect(playback.calls, ['pause','play'])`. **The "same block" half is not asserted** — the fake playback records call names only | ⚠️ Partial **[A+D]** UAT-09 |
| AC12 — permanent loss pauses and stays paused, notification available | pause; a later focus gain does not play | `audio_focus_monitor_test.dart:49`, `:57` — `expect(playback.calls, ['pause'])` after a `transientGain`; `:68` a permanent loss cancels a pending resume. Notification survival: `narration_audio_handler_test.dart:87` (paused publishes a play control) | ✅ PASS **[A]** + UAT-10 |
| AC13 — resume after any focus loss restarts the interrupted block from its beginning | the same block's full text is spoken again | **no `file:line`** — no test performs pause→play and asserts re-speech. True by construction (`_start` always speaks `entry.normalizedText` whole) but unasserted | ❌ GAP (evidence-or-zero) **[D]** UAT-06, UAT-09 |

### P1: Control narration from a headset

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC14 — external play/pause/play-pause applies identically to the notification's controls | same `NarrationPlayback` methods | `narration_audio_handler_test.dart:40` (one code path serves both surfaces); routing guard at `test/architecture/background_narration_architecture_test.dart:41` — `expect(source, contains('androidForceEnableMediaButtons()'))` | ✅ PASS **[A+D]** UAT-08 |
| AC15 — external next/previous move one block, matching AC8 | one block | `narration_audio_handler_test.dart:51` — `expect(playback.calls, ['next'])` | ✅ PASS **[A+D]** UAT-08 |

### P1: Come back to a session already playing

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC16 — opening the app during playback attaches with no gap or restart in speech | status/block preserved, engine untouched | `test/features/narration/presentation/cubit/narration_cubit_test.dart:468` — `expect(cubit.state.status, session.state.status)` + `expect(cubit.state.blockId, 'block-1')`; `narration_audio_handler_test.dart:108`. **Covers constructing a surface against a live session, not the app's actual re-entry path** — see Gap 1 | ❌ GAP **[A+D]** UAT-12 |
| AC17 — the in-app player shows the session's exact state rather than a freshly restored one | live status/book/chapter/block | same citations as AC16. `ReaderNarrationHost.initState` calls `cubit.load(content)` unconditionally, which *is* a fresh restore — see Gap 1 | ❌ GAP **[A]** |
| AC18 — on attach, the reader shows and highlights the block being spoken | the narrated block is focused | `reader_narration_host_test.dart:28` — `expect(focuses, [('chapter','block')])` (focus on play). Attach-time highlight is not asserted; in practice it only arrives because Gap 1 restarts the session | ⚠️ Partial **[A+D]** UAT-12 |
| AC19 — opening a different book stops the previous session before starting a new one | previous playback stopped | `narration_session_test.dart:86` — asserts `state.bookId == 'outro'` and `state.status == ready` **only**. Verified independently: `load()` never calls `_engine.stop()`; a probe asserting `expect(engine.stopCalls, 1)` fails with `0` — see Gap 3 | ❌ GAP **[A+D]** UAT-13 |

### P2: Pause when the headphones come out

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --- | --- | --- | --- |
| AC20 (BGN-09) — becoming noisy pauses, never continues on the speaker | pause; no auto-resume on reconnect | `audio_focus_monitor_test.dart:98` — `expect(playback.calls, ['pause'])`; `:107` reconnect does not resume; `:118` noop while paused; `:126` cancels a pending transient resume | ✅ PASS **[A]** + UAT-11 |

**Status**: ❌ Gaps present — 15 of 19 P1 criteria fully evidenced, 3 gaps
(AC13, AC16/AC17, AC19), 2 partial (AC4, AC11, AC18). BGN-09 (P2) passes.

---

## Edge Cases

- [x] **Foreground service cannot start** → narration keeps working, states once.
      `configure_dependencies_test.dart:346` — `expect(session.state.message, NarrationSession.mediaSessionMessage)` then `expect(session.state.status, NarrationStatus.playing)`; `narration_session_test.dart:402`–`:455`.
      Caveat: the warning is pinned, not one-shot — see Observation A.
- [x] **Speech engine error mid-block** → error state everywhere, no notification claiming playback.
      `narration_session_test.dart:286` — `expect(session.state.status, NarrationStatus.paused)` + `expect(session.state.message, NarrationSession.speechMessage)`; the handler maps any non-playing status to `playing: false` (`narration_audio_handler_test.dart:87`).
- [x] **Notification permission denied** → still plays, states once.
      `narration_session_test.dart:351` — `expect(engine.spoken, ['Texto 1'])` + `expect(session.state.message, NarrationSession.notificationsMessage)`; `:364` — `expect(notifications.calls, 1)` across three blocks. Same pinning caveat.
- [ ] **Play and pause from two surfaces at nearly the same moment** → applied in
      arrival order, all surfaces agree. **NOT HANDLED.** The design promised a
      tail-future serialisation; the shipped `_transitioning` flag *drops* the
      second command. Verified: `pause(); play();` from a playing session ends
      `paused`, not `playing`. No test exists — see Gap 4.
- [x] **Next while awaiting an undownloaded web chapter** → keeps reporting awaiting.
      `narration_session_test.dart:247` — `expect(session.state.status, NarrationStatus.awaitingDownload)` + `expect(repository.progressSaves.last.completed, isFalse)`; `:260` reload happens exactly once; `narration_audio_handler_test.dart:157` publishes `buffering`, not `completed`.
- [~] **Narrated book deleted while a session is active** → session ends, notification removed.
      Both halves tested (`library_service_test.dart:11`, `narration_session_test.dart:459`), the wire between them is not — see Gap 5.
- [ ] **Reboot / process killed** → no self-restart, persisted block is the last completed.
      **No evidence.** No `BOOT_COMPLETED` receiver is declared and nothing schedules a restart, so it holds by absence, but there is neither a test nor a UAT case. ⚠️ Spec-precision gap.

---

## Discrimination Sensor

Scratch state: a detached `git worktree` at `HEAD`, discarded after each run.
The real working tree was never modified (verified clean at the end).

| # | Target | Mutation | Tests run | Killed? |
| --- | --- | --- | --- | --- |
| 1 | `narration_session.dart:438` | `_navigate` direction inverted: `offset < 0` → `offset > 0` | session | ✅ Killed (3 failures) |
| 2 | `narration_session.dart:357` | `_complete`: `completed: !awaiting && entry == _queue!.last` → `completed: true` | session | ✅ Killed |
| 3 | `narration_session.dart:282` | `play()`: end-of-queue guard removed | session | ✅ Killed |
| 4 | `narration_session.dart:498` | `_stopAndPersist`: engine stopped even with no block held | **full suite (711)** | ❌ **Survived** |
| 5 | `narration_audio_handler.dart:73` | `_controls`: play/pause inverted | handler | ✅ Killed (2 failures) |
| 6 | `narration_audio_handler.dart:30` | `skipToNext()` routed to `previous()` | handler | ✅ Killed (2 failures) |
| 7 | `audio_focus_monitor.dart:47` | permanent loss sets `_resumeWhenFocusReturns = true` | focus | ✅ Killed (2 failures) |
| 8 | `audio_focus_monitor.dart:50` | becoming-noisy no longer pauses | focus | ✅ Killed (2 failures) |
| 9 | `configure_dependencies.dart:495` | `_bringUpMediaSession` catch swallows the failure silently | DI + narration | ✅ Killed |
| 10 | `configure_dependencies.dart:208` | `LibraryService(onBookDeleted: …)` wiring removed | DI + narration + library + widget_test | ❌ **Survived** |
| 11 | `audio_session_interruptions.dart:38` | transient/permanent focus classification inverted | narration + DI + architecture | ❌ **Survived** |
| 12 | `narration_audio_handler.dart:51` | `MediaItem` book title and chapter swapped | handler | ✅ Killed (2 failures) |
| 13 | `narration_session.dart:557` | `_ensureNotifications`: `_askedForNotifications` guard removed | session | ✅ Killed (2 failures) |
| 14 | `narration_session.dart:666` | `_emit`: pending media-session message never re-applied | narration + DI | ✅ Killed (3 failures) |

**Sensor depth**: 14 behaviour-level mutations (target was ≥6), weighted to the
session (6), the handler (4), the focus monitor (2), and composition wiring (2).
**Result**: **11/14 killed, 3 survived** — ❌ FAIL.

Four additional behaviour probes (throwaway tests, not mutations) were run in the
same scratch state and all four failed against the shipped code, confirming
Gaps 1–4:

| Probe | Assertion | Actual |
| --- | --- | --- |
| Re-open the narrated book | after a second `load(sameContent)`, `status == playing` | `ready` |
| Second book stops the first | `engine.stopCalls == 1` after `load(otherBook)` | `0` |
| `stop()` leaves playing | `status != playing` after `stop()` | `playing` |
| Concurrent pause+play | end state `playing` | `paused` |

---

## Gate Check

- **Gate command**: `flutter analyze && flutter test && flutter build apk --debug`
- **`flutter analyze`**: `No issues found! (ran in 4.3s)`
- **`flutter test`**: **711 passed, 0 failed, 0 skipped**
- **`flutter build apk --debug`**: `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (exit 0)
- **Test count before feature** (`main`, measured in a scratch worktree): **614**
- **Test count after feature**: **711**
- **Delta**: **+97**, no decrease
- **Skipped tests**: none
- **Failures**: none

**Test Integrity Check**: `narration_cubit_test.dart` holds 27 tests on both
`main` and `HEAD` — the T5 parity gate holds. Two of them were *replaced*
rather than kept (see below); one host test was added (4 → 5).

### Coverage Moved vs. Kept

| Removed assertion | Where it went |
| --- | --- |
| `narration_cubit_test`: "close awaits stop before persisting current block" | ✅ Moved verbatim to `narration_session_test.dart:519` |
| `narration_cubit_test`: "close with no current block stops safely" — asserted `engine.stopCalls == 1` | ⚠️ **Intent inverted, replacement unasserted.** The session now deliberately does *not* touch the engine; `narration_session_test.dart:541` asserts only `progressSaves isEmpty`, which passes either way (sensor M4 survived) |
| `reader_narration_host_test`: exact progress tuple `['run','chapter','block',false]` on lifecycle pause | ⚠️ Partly relocated — `narration_cubit_test.dart:485` and `narration_integration_test.dart:118` assert the tuple on an explicit pause; the session's own pause test asserts `blockId` only |
| `configure_dependencies_test`: "narration ownership waits prior stop and progress before activation" | ✅ Correctly obsolete under AD-013; replaced by `:385` "every reader route attaches to the one narration session" |

---

## Answers to the specific judgement calls raised for review

**1. `_stopAndPersist` returns early when the session holds no block.**
Behaviourally correct and reachable only when the session was never loaded or was
just discarded — `pause()` cannot reach it (it requires `status == playing`,
which implies a block). **But it is untested**: mutation 4 removed the behaviour
and all 711 tests still passed. It is also redundant with judgement call 2 — both
were introduced to stop `resetDependencies` throwing.

**2. `FlutterTtsNarrationEngine.close()` swallows `NarrationEngineException`.**
No, it hides nothing anyone needed. `close()` has exactly one caller —
`get_it`'s `dispose` hook at `configure_dependencies.dart:308/313` — and
`resetDependencies` is invoked only from tests. No production path reads its
outcome, and the swallow is narrowed to one exception type. Covered by
`flutter_tts_narration_engine_test.dart:8`. **No gap.**

**3. Two Cubit `close` assertions replaced, three lifecycle widget tests inverted.**
The lifecycle inversion is correct and deliberate — it is BGN-01, it is recorded
in the spec's "Known impact outside this feature", and `.specs/features/narration/uat.md`
UAT-10 was rewritten. The new tests assert the *positive* outcome (`status == playing`,
`engine.stops == 0`) rather than merely deleting the old ones, and a structural
test pins the absence of the observer. Of the two Cubit close tests, one moved
verbatim; **the other's intent was inverted without a replacement assertion** —
see the table above. That is a real, if small, loss.

**4. `NarrationSession` emits on a synchronous broadcast controller.**
Safe as wired. The only two listeners are `NarrationCubit._project` (which calls
`Cubit.emit`, itself backed by an *async* controller, and is guarded by
`isClosed`) and `NarrationAudioHandler._publish` (which writes to `BehaviorSubject`s).
Neither re-enters the session, so no re-entrancy or ordering hazard exists today.
One latent fragility worth knowing: because delivery is synchronous, a listener
that threw would propagate back into `_emit`'s caller and, inside `load()`, be
caught by its `catch (_)` and misreported as `initializationMessage`. Not
reachable now; it becomes reachable the moment a third listener is added.

**5. `_pendingMediaSessionMessage` held and re-applied in `_emit`.**
It cannot spuriously reappear, and it is load-bearing — mutation 14 proved that
removing the re-application breaks the denial path outright, because `_start`
immediately emits a fresh state whose `message` is null. **But it can stick
forever.** `clearMessage()` is its only reset, and nothing in `lib/` calls
`NarrationCubit.clearMessage()` — the narration player bar renders `state.message`
inline and never clears it (this dead path predates the feature; the feature is
what made it load-bearing). So once the media session fails or the notification
permission is denied, the warning is pinned under the player bar for the whole
app lifetime, across book loads. That contradicts the field's own documentation
("A one-shot message for the reader, cleared once shown") and, arguably, the
spec's "SHALL state **once**". The test that covers it
(`narration_session_test.dart:424`) calls `clearMessage()` directly — an API no
surface reaches. Recorded as Observation A rather than a ranked gap: it
over-shows rather than under-shows.

---

## Regression Check (shared code touched by this diff)

| Shared surface | Change | Verdict |
| --- | --- | --- |
| `configure_dependencies.dart` | Session/monitor/interruptions registration, `startMediaSession` seam, registry reduced | ✅ 40 DI tests pass, including reset ordering and disposal |
| `lib/main.dart` | `startMediaSession` threaded through both `createApplication` and `_configureDependencies` | ✅ `widget_test.dart` (7 tests) green; PDF import/edit/delete/restart flows unchanged |
| `test/widget_test.dart` | `_noMediaSession` opt-out added at 4 call sites | ✅ No assertion weakened; the opt-out mirrors the existing `_noResume` precedent |
| `library_service.dart` | `onBookDeleted` callback + **a real bug fix**: `book.storedFilePath!` threw for web books, so deleting a web book reported failure | ✅ Fix is correct and newly covered (`library_service_test.dart:44`). Strictly it is scope beyond T14, but it was a blocker for T14's own path. One residual: `onBookDeleted` fires *before* `discardQuarantine`, so if the quarantine discard fails and the deletion is rolled back, the book comes back but the narration session has already ended. Untested, cosmetic. |
| `flutter_tts_narration_engine.dart` `close()` | Swallows `NarrationEngineException` | ✅ See judgement call 2 |
| `reader_narration_host.dart` | Lifecycle observer removed | ✅ Intended; other responsibilities (activation, content reload, settings sheet, focus delivery) unchanged and still tested |
| PDF reading path (`visual_reader`) | Only the `NarrationCubit` constructor call changed in tests | ✅ `reader_page_test.dart` green, including "narration focus does not save visual position" (AD-007 still holds) |
| `web_source` narration boundary | `awaitsDownload` moved with the queue | ✅ `web_source_integration_test.dart` and the 7 download-boundary cubit tests pass unchanged |

**No PDF or pre-existing narration regression found.**

---

## Code Quality

| Principle | Status |
| --- | --- |
| No features beyond what was asked | ✅ (the `storedFilePath` fix is adjacent but load-bearing for T14) |
| No abstractions for single-use code | ✅ `NarrationPlayback` earns its place — it is what makes the handler testable |
| No unnecessary "flexibility" added | ✅ |
| Only touched files required for task | ✅ |
| Didn't "improve" unrelated code | ⚠️ `library_service.deleteBook` web-book fix — justified, tested, and explained in a comment |
| Matches existing patterns/style | ✅ Guarded `isRegistered` registration, injectable seams, hand-written fakes, `_unset` sentinel, pt-BR UI strings, English code |
| Would a senior engineer approve? | ⚠️ Yes for the architecture; the re-entry `load()` (Gap 1) would be flagged in review |
| Tests map to ACs and are non-shallow | ✅ Spot-checked the focus-monitor story: 13 tests, every branch, 2/2 mutants killed |
| Spec-anchored outcome check | ⚠️ AC19's assertion targets the emitted state rather than the spec's "stop the previous session"; AC13 has no assertion |
| Per-layer Coverage Expectation met | ❌ Data adapters: the matrix requires unit tests for `AudioFocusMonitor`'s adapter — `audio_session_interruptions.dart` and `permission_handler_notifications.dart` have none, and the former is injectable (`AudioSessionInterruptions({Future<AudioSession>? session})`) so it could be tested |
| Every test maps to a spec requirement — no unclaimed tests | ✅ |
| Documented guidelines followed | ✅ `CLAUDE.md` (architecture invariants, no mocking package, real `NativeDatabase`, `test/architecture/` scanners) |

---

## Fix Plans

### Fix 1 — Re-opening the narrated book restarts the session (Blocker)

- **Root cause**: `ReaderNarrationHost._activate()` calls `cubit.load(content)`
  unconditionally on `initState`, and `NarrationSession.load()` has no
  "already this book" guard. The reader route builds a fresh `NarrationCubit`
  per entry (`configure_dependencies.dart:458`), so returning to the library and
  re-opening the book being narrated resets the live session from `playing` to
  `ready` at the persisted block. Speech stops advancing after the current
  paragraph; the notification follows the session down to a play button.
  Verified by probe: after a second `load(sameContent)`, `status == ready`.
- **Fix task**: make `NarrationSession.load` a no-op (or a content refresh that
  preserves status and current entry) when `content.book.id == _state.bookId`
  and the run id is unchanged; otherwise load as today.
- **Verify**: a session playing block 2 of book A, then `load(bookA)` → status
  still `playing`, `current.blockId` unchanged, `engine.spoken` unchanged. Add a
  widget-level case that pumps a second `ReaderNarrationHost` over a playing session.
- **Requirements**: BGN-16 (AC16), BGN-17 (AC17), and AC18's attach half.
- **Priority**: **Blocker** — it defeats "reopening never produces a gap, a
  restart, or a player that disagrees", one of the five Success Criteria.
- **Also add** a UAT case: "narrate, return to the library, re-open the same
  book" — UAT-12 only covers foregrounding the app with the reader still mounted.

### Fix 2 — `stop()` never leaves the `playing` state (Major)

- **Root cause**: `NarrationSession.stop()` calls `_stopAndPersist` and emits
  nothing. The engine goes quiet and progress is written, but `_state.status`
  stays `playing`, so `sessionStream` keeps telling every surface that narration
  is playing. Reachable from a headset/car `KEYCODE_MEDIA_STOP` and from
  `audio_service`'s own stop path. `stop()` has no test in
  `narration_session_test.dart`.
- **Fix task**: emit a terminal state from `stop()` (paused, or the empty state
  the design's "end the session" language implies) and decide explicitly whether
  `stop()` should end the session the way `discardBook` does.
- **Verify**: `stop()` from `playing` → `state.status != playing`; the handler
  publishes `playing: false` from the *session*, not only from `super.stop()`.
- **Requirements**: BGN-06 (AC7 "reflect the new state on every surface"), BGN-13.
- **Priority**: **Major**.

### Fix 3 — Opening a different book does not stop the previous speech (Major)

- **Root cause**: `NarrationSession.load()` bumps `_generation` (which stops
  *advancing*) but never calls `_engine.stop()`, so book A's in-flight utterance
  plays to its end underneath book B's reader. `narration_session_test.dart:86`
  asserts only the emitted state, so it passes under this wrong implementation.
- **Fix task**: stop the engine at the top of `load()` when a different book is
  replacing a playing one — the same guard `reloadContent()` already has at
  `narration_session.dart:483`.
- **Verify**: extend `:86` with `expect(engine.stopCalls, 1)`.
- **Requirements**: BGN-18 (AC19). **Priority**: **Major**. UAT-13 would catch it on a device.

### Fix 4 — Concurrent commands are dropped, not serialised (Major)

- **Root cause**: the design specified "the session serialises commands on a
  single tail future … last command in arrival order wins" and the spec's edge
  case requires "apply them in arrival order". The implementation uses a
  `_transitioning` boolean that makes `play()`/`pause()`/`_navigate()` return
  early while another transition is in flight, so the second command is
  discarded. Verified: `pause(); play();` from a playing session ends `paused`.
  Real window: the duration of `engine.stop()` + `saveProgress()`, i.e. a
  platform-channel round trip — a double-tap on the notification or a headset
  play/pause bounce falls inside it.
- **Fix task**: either implement the tail-future queue the design specified, or
  amend the design and spec to state that a command arriving mid-transition is
  dropped (and say why that is acceptable). Do not leave the two disagreeing.
- **Verify**: a test issuing `pause()` then `play()` without awaiting, asserting
  the documented end state.
- **Requirements**: BGN-12. **Priority**: **Major**.

### Fix 5 — Three surviving mutants (Major)

- **5a** `audio_session_interruptions.dart` has **no test at all**. Inverting
  the transient/permanent classification — the single line that separates BGN-07
  from BGN-08 — is invisible to the suite. The class already accepts an
  injectable `Future<AudioSession>`; add a fake and assert the mapping for
  `begin` with `unknown`/`pause`/`duck` types, for `end`, and for becoming-noisy.
- **5b** The `LibraryService → NarrationSession.discardBook` wiring in
  `configure_dependencies.dart:208` is untested; deleting it breaks nothing.
  Add a composition-level test: compose the container, load a session, delete
  the book through `LibraryService`, assert `session.state == NarrationSessionState()`.
- **5c** `_stopAndPersist`'s early return is untested. Add
  `expect(engine.stopCalls, 0)` to `narration_session_test.dart:541`.
- **Priority**: **Major** (5a), **Major** (5b), **Minor** (5c).

### Fix 6 — AC13 has no assertion (Minor)

- Add a session test: play block 1, `pause()`, `play()`, assert
  `engine.spoken == ['Texto 1','Texto 1']`. One test closes AC13 and strengthens AC11.

---

## Observations (not ranked as gaps)

- **A. The "state it once" message is permanent, not one-shot.** See judgement
  call 5. It over-shows rather than under-shows, so it does not fail an AC, but
  the code's own comment claims a behaviour it does not have and the covering
  test drives an API no surface reaches. Worth a decision, not a blocker.
- **B. `NarrationAudioHandler.stop()` cancels its session subscription
  permanently.** After a notification dismissal, narration restarted from inside
  the app is never mirrored to the media session again. Bounded by app lifetime;
  UAT-15 checks the dismissal but not the restart afterwards.
- **C. `AudioFocusMonitor.start()` runs only inside `startNarrationMediaSession`,
  after `AudioService.init()`.** On a device where the media session fails
  (BGN-10), audio-focus and becoming-noisy handling are silently off too — the
  degradation is wider than the spec's "background controls are unavailable".
- **D. `resetDependencies` does not stop `AudioService`.** T10's card says
  "releases the service"; only the Dart-side session and monitor are disposed.
  `resetDependencies` has no production caller, so this is test-only.
- **E. Known and already recorded, not counted as gaps**: a long-paused media
  session may be reclaimed by the system (design risk, UAT-16), and
  `permission_handler` is pinned to 12 because 13 requires an Android SDK this
  machine lacks.

---

## Requirement Traceability Update

| Requirement | Previous Status | New Status |
| --- | --- | --- |
| BGN-01 | Implementing | ✅ Verified (AC1 automated; AC2/AC3 device-only, UAT-03/05) |
| BGN-02 | Implementing | ⚠️ Partial — service config asserted, hold/release configuration untested |
| BGN-03 | Implementing | ✅ Verified |
| BGN-04 | Implementing | ⚠️ Partial — see Observation B |
| BGN-05 | Implementing | ✅ Verified |
| BGN-06 | Implementing | ❌ Needs Fix — `stop()` leaves surfaces disagreeing (Fix 2) |
| BGN-07 | Implementing | ⚠️ Partial — AC13 unasserted (Fix 6); adapter mapping untested (Fix 5a) |
| BGN-08 | Implementing | ⚠️ Partial — adapter mapping untested (Fix 5a) |
| BGN-09 (P2) | Pending | ✅ Verified |
| BGN-10 | Implementing | ✅ Verified |
| BGN-11 | Implementing | ✅ Verified |
| BGN-12 | Implementing | ❌ Needs Fix — commands dropped, not serialised (Fix 4) |
| BGN-13 | Implementing | ⚠️ Partial — composition wiring untested (Fix 5b) |
| BGN-14 | Implementing | ✅ Verified |
| BGN-15 | Implementing | ✅ Verified (device confirmation UAT-08) |
| BGN-16 | Implementing | ❌ Needs Fix — Fix 1 |
| BGN-17 | Implementing | ❌ Needs Fix — Fix 1 |
| BGN-18 | Implementing | ❌ Needs Fix — Fix 3 |

---

## Summary

**Overall**: ❌ Not Ready

**Spec-anchored check**: 15/19 P1 criteria matched the spec outcome; 3 gaps
(AC13, AC16/17, AC19), 3 partial (AC4, AC11, AC18); BGN-09 (P2) passes; 1 of 7
edge cases not handled, 1 with no evidence.
**Sensor**: 11/14 mutations killed, 3 survived.
**Gate**: 711 passed, 0 failed, 0 skipped; analyze clean; APK built.

**What works**: The architecture is sound and the refactor is genuinely
behaviour-preserving where it claims to be — 614 → 711 tests with no deletions
and the full pre-existing narration suite intact. Playback ownership really did
move to one app-scoped session; the handler, the focus monitor, and the
composition wiring are driven entirely through fakes with no device; the
package-confinement and manifest scanners work; the lifecycle inversion is
deliberate, positively asserted, and the old UAT case was rewritten. Nine of
fourteen mutations in the highest-risk new code died immediately.

**Issues found**: The feature's weakest seam is not the platform code — it is
what happens when a *surface* re-enters a session that is already running.
Re-opening the narrated book restarts it (Fix 1), opening a different book
leaves the old paragraph speaking (Fix 3), `stop()` never leaves `playing`
(Fix 2), and near-simultaneous commands are dropped rather than ordered
(Fix 4). Three untested seams let real faults through (Fix 5).

**Next steps**: Fix 1 first — it is the only Blocker and it undoes the
milestone's headline promise. Then Fixes 2–4, then the sensor gaps in Fix 5.
Re-verify before the device UAT run, and add the missing "return to the library
and re-open the same book" case to `uat.md`.
