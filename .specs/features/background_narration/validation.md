# Background Narration Validation — Iteration 2

**Date**: 2026-08-29
**Spec**: `.specs/features/background_narration/spec.md`
**Diff range**: `main..HEAD` (`8be4c1e`..`22935d0`, 20 commits, branch `feat/background-narration`)
**Iteration**: 2 of 3 — re-verification of the six gaps ranked in iteration 1
**Verifier**: independent sub-agent (author ≠ verifier), read-only over the real tree

**Verdict**: ❌ **FAIL** — five of the six iteration-1 gaps are genuinely closed and
their mutants now die. The sixth (command serialisation) was closed with a
mechanism that is **itself untested and introduces a behavioural regression**:
after a `next()` or `previous()`, a `pause()` can no longer stop the engine.
The build gate is green (729 tests) and the regression is invisible to it.

---

## 1. Iteration-1 gaps re-run adversarially

| # | Iteration-1 gap | Verdict | Evidence |
| --- | --- | --- | --- |
| 1 | Blocker — re-opening the narrated book restarts the session | ⚠️ **Partially closed** | Guard at `lib/features/narration/domain/services/narration_session.dart:105-109`. Covered by `test/features/narration/domain/services/narration_session_test.dart:101` — `expect(session.state.status, NarrationStatus.playing)` + `expect(engine.stopCalls, 0)` + `expect(engine.spoken, ['Texto 1'])`. Mutation **M1** (guard removed) is killed. **But** the guard now blocks a legitimate content refresh — see Gap 5 below. Still no widget-level re-entry test and no UAT case. |
| 2 | Major — `stop()` never left `playing` | ⚠️ **Partially closed** | `narration_session.dart:629-640` now clears content and emits `const NarrationSessionState()`. Covered at `narration_session_test.dart:134` — `expect(session.state, const NarrationSessionState())`. Mutation **M7** (emit removed) is killed. **But** the new emit sits behind `if (!_active(generation)) return;` and is silently skipped when `stop()` loses a race — see Gap 4. |
| 3 | Major — opening a different book left the first speaking | ✅ **Closed** | `narration_session.dart:113-119`. `narration_session_test.dart:120` — `expect(engine.stopCalls, 1)` + `expect(session.state.bookId, 'outro')`. Mutation **M4** (stop removed) is killed with 2 failures. `reloadContent`'s redundant second stop is correctly gone. |
| 4 | Major — concurrent commands dropped, not serialised | ❌ **Still open** | The `_transitioning` drop-guard is gone and `pause(); play();` now ends `playing` (`narration_session_test.dart:150`). But the queue that replaced it is **not discriminated by any test** (mutation **M6**, below) and it broke `pause()` after a skip (Gap 1 in the ranked list). `play()` still beats a `pause()` that arrives during the first-play permission dialog (Gap 3). |
| 5 | Major — three surviving mutants | ✅ **Closed** | All three iteration-1 survivors now die. `audio_session_interruptions.dart` has its own 9-test file — inverting the transient/permanent line (**M9**) fails 3 tests. The `LibraryService → discardBook` wiring (**M10**) fails `configure_dependencies_test.dart` "deleting the narrated book reaches the session". `_stopAndPersist`'s early return (**M8**) fails 4 tests. |
| 6 | Minor — AC13 had no assertion | ✅ **Closed** | `narration_session_test.dart:302-317` — `expect(engine.spoken.take(2), ['Texto 1', 'Texto 1'])`. Mutation **M12** (resume advances to the next block instead of restarting the interrupted one) is killed with 2 failures. Not a tailored test: it asserts the spec's outcome, not the mutation's shape. |

**Tests shaped to their own mutation rather than the requirement:** one, and it is
the important one. `narration_session_test.dart:150` ("a pause then a play ends
playing") passes identically **with the command queue removed entirely** — see
mutation M6. `narration_session_test.dart:165` ("a play then a pause ends paused")
inserts a `pumpEventQueue()` between the two commands, which is exactly the step
that closes the race window it claims to test; without it the assertion fails
(PROBE-A).

---

## 2. Command queue — targeted scrutiny

The riskiest change in `22935d0`, examined against the five hazards named for review.

### 2.1 A command deadlocking behind another — **CONFIRMED, and it is the blocker**

`previous()`/`next()` go through `_serialize` (`narration_session.dart:312-321`),
and `_navigate` ends with `if (wasPlaying && _active(generation)) await _start(target);`
(`:509`). `_start` awaits `_engine.speak(...)` — **the whole destination
paragraph**. So `_navigate` holds the command queue for the length of a
paragraph. The commit message justifies keeping `play()` *outside* the queue for
exactly this reason ("holding it for a paragraph would make pause unable to
interrupt"), but leaves the identical hazard inside `_navigate`.

Probe (scratch state, discarded):

```
PROBE-J  play → next → pause, engine.speak pending
  HEAD    22935d0 : status=paused  stopCalls=1  progressSaves=1  spoken=[Texto 1, Texto 2]
  parent  b13dfd0 : status=paused  stopCalls=2  progressSaves=2
```

On `HEAD` the reader presses pause, every surface flips to paused — and the
engine is never told to stop. Speech continues to the end of the paragraph and
the progress write is deferred with it. On the parent commit the same sequence
stopped the engine, because the old `_navigate` cleared `_transitioning`
*before* `await _start(target)`. **This is a regression introduced by the fix.**

```
PROBE-H  two rapid next() presses while playing
  expected block-3 → actual block-2, spoken=[Texto 1, Texto 2]
```

The second press waits out the whole paragraph before it is applied.

Reachable from every surface the spec names: `NarrationAudioHandler.skipToNext`
→ `_playback.next()` and `.pause()` → `_playback.pause()`
(`lib/features/narration/data/services/narration_audio_handler.dart:26-34`), so
notification, lock screen and headset all hit it. It also weakens **AC11**: a
call arriving right after a skip keeps narration talking over the ring for the
rest of the paragraph.

### 2.2 `play()` racing a queued `pause()` in the wrong order — **CONFIRMED**

`pause()` returns early when `_state.status != playing` (`:302`). `play()` runs
outside the queue and only reaches `playing` inside `_start`, *after*
`await _ensureNotifications()` (`:341`) — a platform round trip that on Android 13+
first play is a **visible system permission dialog**.

```
PROBE-F  play() → (permission dialog open) → pause() → dialog resolves
  expected paused / nothing spoken → actual playing, block spoken
PROBE-A  play(); pause(); in the same tick
  expected paused → actual playing
```

The spec's edge case is symmetric ("a play command and a pause command … applied
in arrival order"). `pause → play` is fixed; `play → pause` is not.

### 2.3 The queue growing unbounded — **no gap found**

`_commands` is a chain of settled futures; each link is collected once it
completes. No accumulation.

### 2.4 An error in one command poisoning the tail — **no gap found**

`_commands = queued.then<void>((_) {}, onError: (_) {});` (`:319`) absorbs the
error into the tail while still handing it to the caller. Verified by probe
PROBE-C: a `next()` whose `engine.stop()` throws is followed by a second `next()`
that lands correctly on `block-3` with a clean message. Passes.

### 2.5 `previous()`/`next()` while playing — **behaves, but see 2.1**

Direction, one-block movement and destination-from-start are all still asserted
and all still discriminating (M12 killed; iteration-1's M1/M6 remain killed).
The failure is only in what a *subsequent* command can do while a skip is
speaking.

### 2.6 Two further findings in the same code

- **`stop()` and `discardBook()` bypass the queue entirely.** Both bump the
  generation and run outside `_serialize`, then guard their terminal emit with
  `if (!_active(generation)) return;` (`:632`, `:620`). When they lose a race
  they no-op silently:

  ```
  PROBE-D  next() then stop()
    expected NarrationSessionState() → actual status=playing block=block-2 spoken=[Texto 1, Texto 2]
  ```

  `NarrationAudioHandler.stop()` then cancels its subscription and calls
  `super.stop()` (`narration_audio_handler.dart:36-40`), so the media session is
  torn down while narration is still audibly speaking. The same shape can lose
  the "book deleted while a session is active" edge case.

- **`pause()` returns the queue tail when it is a no-op** (`:302`). PROBE-E: a
  second `pause()` never settles while an earlier command is in flight;
  `NarrationAudioHandler.pause()` awaits it.

---

## 3. Same-book guard — false negatives

The guard (`narration_session.dart:105-109`) treats `activeContentRunId` as a
content-identity check. It is not one for web books:
`lib/features/web_source/domain/services/web_novel_download_service.dart:157` reads
`final runId = book.activeContentRunId ?? _runId();` — the run id is minted once
and **deliberately reused across every download pass**, so a web book gains
chapters under an unchanged run id.

```
PROBE-B  load(book, 1 chapter) → load(same book, 2 chapters)
  expected state.canNext == true → actual false
```

`VisualReaderCubit.load` re-reads content from the repository on every reader
entry (`lib/features/visual_reader/presentation/cubit/visual_reader_cubit.dart:33`)
and `ReaderNarrationHost._activate` hands it to `load`
(`lib/features/narration/presentation/widgets/reader_narration_host.dart:49`).
So: narrate a downloading web book, return to the library, let chapters land,
re-open the book — the narration queue, `canNext` and `awaitsDownload` are all
frozen at the old chapter set. Before `22935d0` that re-entry rebuilt the queue.

**Mitigation, verified**: `_reloadAtBoundary` (`:452`) still rescues *playback*
at the end of the stale queue while `NarrationQueue.awaitsDownload` is true
(`narration_queue.dart:6-9`), so this degrades the displayed state and delays
recovery rather than losing the book. It is Major, not a Blocker.

**Cases checked and found safe**: `retryInitialization` (error/unavailable states
carry a null `bookId`, so the guard never fires); PDF reprocessing (a new run id
is minted — `drift_text_processing_repository.dart:207`, `:237`); a different
book; a session ended by `stop()`/`discardBook()` (state is emptied, guard cannot
fire); `didUpdateWidget`'s `reloadContent` (fires only on a run-id change, so the
guard passes through).

**A latent trap off that path**: `reloadContent` bumps `_generation` (`:515`)
*before* calling `load`. If `load` early-returns, the bump has already orphaned
the block in flight:

```
PROBE-G  playing → reloadContent(same book, same run id) → speak completes
  expected spoken == ['Texto 1','Texto 2'] → actual ['Texto 1'], status stays playing
```

Narration stalls permanently while every surface reports playing. Only reachable
through the public `NarrationCubit.reloadContent`, not through the host today.

---

## 4. Regression check across the diff

`22935d0` touches exactly one file under `lib/`:
`lib/features/narration/domain/services/narration_session.dart`.

| Surface | Verdict |
| --- | --- |
| PDF reading (`visual_reader`, `pdf_processing`) | ✅ No change reaches it. Reprocessing mints a new run id, so the same-book guard passes through. `reader_page_test.dart` and the PDF import/edit/delete flows in `widget_test.dart` are green. |
| Narration (pre-existing) | ⚠️ **One regression**: `pause()` after a skip no longer stops the engine (§2.1), proven against the parent commit. Everything else — load, play, navigate, end of book, voice repair, progress, degradation, permission — is unchanged and green. |
| Web source | ⚠️ **One regression**: re-entering the reader for a downloading web book no longer refreshes the narration queue (§3). `web_source_integration_test.dart` and the download-boundary cubit tests pass unchanged because none of them exercises reader re-entry. |
| Composition (`configure_dependencies`, `main.dart`) | ✅ Unchanged by this commit; 40 DI tests green, and the `discardBook` wiring is now covered. |

---

## 5. Discrimination Sensor

Scratch state: a detached `git worktree` at `HEAD`, one mutation at a time,
`git checkout --` between each, worktree removed at the end. The real tree was
never modified (verified clean). Mutations weighted to the code `22935d0`
changed: 10 of 14 target `narration_session.dart`, 3 re-inject iteration-1's
survivors, 1 targets the composition wiring.

| # | File:line | Mutation | Scope run | Killed? |
| --- | --- | --- | --- | --- |
| M1 | `narration_session.dart:105` | Same-book guard removed entirely | narration | ✅ Killed (1) |
| M2 | `narration_session.dart:107` | Guard drops the `status != initial` clause | **full 729** | ❌ Survived — **equivalent mutant**: no state carries a `bookId` with `initial` status, so the clause cannot change the result. Redundant code, not a coverage gap. |
| M3 | `narration_session.dart:106` | Guard drops the `activeContentRunId` clause | narration | ✅ Killed (1) |
| M4 | `narration_session.dart:113` | `load` no longer stops a playing engine | narration | ✅ Killed (2) |
| M5 | `narration_session.dart:307` | `pause()` emits inside the queue instead of synchronously | narration | ✅ Killed (3) |
| M6 | `narration_session.dart:317` | **`_serialize` runs the command immediately — no queue at all** | **full 729** | ❌ **Survived** |
| M7 | `narration_session.dart:639` | `stop()` no longer emits the terminal state | narration | ✅ Killed (1) |
| M8 | `narration_session.dart:524` | `_stopAndPersist` early return removed *(iter-1 survivor)* | narration | ✅ Killed (4) |
| M9 | `audio_session_interruptions.dart:38` | Transient/permanent classification inverted *(iter-1 survivor)* | **full 729** | ✅ Killed (3) |
| M10 | `configure_dependencies.dart:208` | `LibraryService(onBookDeleted:)` wiring removed *(iter-1 survivor)* | **full 729** | ✅ Killed (1) |
| M11 | `narration_session.dart:515` | `reloadContent` no longer bumps the generation | **full 729** | ❌ Survived — dead on the reachable path, and a trap off it (PROBE-G) |
| M12 | `narration_session.dart:335` | Resume advances past the interrupted block instead of restarting it | narration | ✅ Killed (2) |
| M13 | `narration_session.dart:632` | `stop()` drops its stale-generation guard | **full 729** | ❌ Survived — the guard that makes `stop()` lose races (PROBE-D) is unasserted |
| M14 | `narration_session.dart:302` | `pause()` no-op returns a settled future rather than the queue tail | **full 729** | ❌ Survived |

**Sensor depth**: 14 behaviour-level mutations (target ≥6).
**Result**: **9/14 killed, 5 survived** (1 equivalent) — ❌ FAIL.

### Behaviour probes (throwaway tests in the same scratch state)

| Probe | Assertion | Actual |
| --- | --- | --- |
| A | `play(); pause();` same tick → `paused` | `playing` |
| B | re-`load` with a chapter that landed → `canNext` true | `false` |
| C | a failing queued command does not poison the tail | ✅ **passes** |
| D | `next(); stop();` → `NarrationSessionState()` | `playing`, block-2, still speaking |
| E | a no-op `pause()` settles while the queue is busy | never settles |
| F | `pause()` during the permission dialog → `paused`, nothing spoken | `playing`, block spoken |
| G | `reloadContent(same run id)` while playing → narration advances | stalls at `playing`, silent |
| H | two rapid `next()` → block-3 | block-2 |
| J | `next(); pause();` → `engine.stopCalls == 2` | `1` (parent commit: `2`) |

---

## 6. Gate Check

- **Gate command**: `flutter analyze && flutter test && flutter build apk --debug`
- **`flutter analyze`**: `No issues found! (ran in 4.0s)`
- **`flutter test`**: **729 passed, 0 failed, 0 skipped**
- **`flutter build apk --debug`**: `✓ Built build/app/outputs/flutter-apk/app-debug.apk` (exit 0)
- **Test count**: `main` 614 → iteration 1 **711** → iteration 2 **729** (**+18**, no decrease, none skipped)
- **Test Integrity**: no test deleted or weakened by `22935d0`; the 18 new tests are 9 in
  `audio_session_interruptions_test.dart`, 7 in `narration_session_test.dart`, 2 in
  `configure_dependencies_test.dart`.

---

## 7. Requirement Traceability Update

| Requirement | Iteration-1 status | Iteration-2 status |
| --- | --- | --- |
| BGN-01, BGN-03, BGN-05, BGN-10, BGN-11, BGN-14, BGN-15 | ✅ Verified | ✅ Verified (unchanged) |
| BGN-02 | ⚠️ Partial | ⚠️ Partial — hold/release configuration still untested |
| BGN-04 | ⚠️ Partial | ⚠️ Partial — Observation B (handler subscription cancelled on stop) still stands |
| BGN-06 | ❌ Needs Fix | ⚠️ **Partial** — `stop()` now emits (Gap closed), but `pause()` after a skip leaves the surfaces claiming paused while speech continues (ranked Gap 1) |
| BGN-07 | ⚠️ Partial | ✅ **Verified** — AC13 asserted, adapter mapping covered |
| BGN-08 | ⚠️ Partial | ✅ **Verified** — adapter mapping covered |
| BGN-09 (P2) | ✅ Verified | ✅ Verified |
| BGN-12 | ❌ Needs Fix | ❌ **Needs Fix** — half the ordering is right, the mechanism is untested, and it regressed pause-after-skip |
| BGN-13 | ⚠️ Partial | ✅ **Verified** — composition wiring covered |
| BGN-16 | ❌ Needs Fix | ⚠️ **Partial** — same-book re-entry fixed; content-refresh re-entry broken (ranked Gap 5) |
| BGN-17 | ❌ Needs Fix | ✅ **Verified** — the live session's state now survives re-entry |
| BGN-18 | ❌ Needs Fix | ✅ **Verified** — `engine.stopCalls == 1` asserted, M4 killed |

---

## 8. Fix Plans

### Fix 1 — `pause()` cannot stop the engine while a skip is speaking (Blocker, regression)

- **Root cause**: `_navigate` runs inside `_serialize` and ends with
  `await _start(target)` (`narration_session.dart:509`), so the command queue is
  held for the length of the destination paragraph. Every command behind it —
  including `pause()`'s engine stop and progress write — waits it out.
- **Fix**: apply to `_navigate` the same split the commit applied to `play()`:
  serialise only the transition (stop the engine, emit the target, persist
  progress) and start speaking **outside** the queue, exactly as `play()` does.
- **Verify**: `play(); next(); pause();` with a pending `engine.speak` →
  `expect(engine.stopCalls, 2)` and `expect(repository.progressSaves.length, 2)`.
  Plus `next(); next();` → `expect(state.current?.blockId, 'block-3')`.
- **Requirements**: BGN-06 (AC7), BGN-12; weakens BGN-07 (AC11).

### Fix 2 — the command queue is untested (Major)

- **Root cause**: `narration_session_test.dart:150` reaches `playing` through
  `pause()`'s synchronous status flip plus `play()`'s `await _commands` on an
  already-settled future; it never observes ordering. Mutation M6 removes the
  queue and all 729 tests pass.
- **Fix**: add a test that fails without serialisation — e.g. two commands whose
  *order of side effects* is observable (assert the sequence of
  `engine`/`repository` calls, not just the end status).
- **Verify**: re-run M6; it must fail.
- **Requirements**: BGN-12.

### Fix 3 — `play()` beats a `pause()` that arrives before the status flips (Major)

- **Root cause**: `pause()` early-returns on `_state.status != playing` (`:302`)
  while `play()` spends the permission round trip (`_ensureNotifications`, `:341`)
  still at `ready`. On Android 13+ first play that window is a visible system
  dialog.
- **Fix**: give `play()` an intent the session can see before speech starts (a
  pending-play flag `pause()` can cancel, or route `play()` through the queue and
  fix Fix 1 so the queue is never held for a paragraph).
- **Verify**: `play(); pause();` in the same tick and across a slow
  `NotificationPermission` → `paused`, `engine.spoken` empty.
- **Requirements**: BGN-12 edge case.

### Fix 4 — `stop()`/`discardBook()` bypass the queue and no-op on a lost race (Major)

- **Root cause**: neither goes through `_serialize`; their terminal emit is
  guarded by `if (!_active(generation)) return;` (`:632`, `:620`), so a command
  that bumps the generation first makes them vanish.
- **Fix**: serialise both, or make the terminal state unconditional.
- **Verify**: `next(); stop();` → `expect(session.state, const NarrationSessionState())`
  and no further speech. Same for `discardBook`.
- **Requirements**: BGN-13; the "book deleted while a session is active" edge case.

### Fix 5 — the same-book guard freezes a web book's queue (Major)

- **Root cause**: `activeContentRunId` is stable across download passes
  (`web_novel_download_service.dart:157`), so it does not identify content.
- **Fix**: compare something that actually changes — the chapter/block count, or
  the queue's entry count — and rebuild the queue in place while preserving
  status and the current entry when it differs.
- **Verify**: `load(1 chapter)` → `load(2 chapters)` same book → `canNext` true,
  status and current entry preserved.
- **Requirements**: BGN-16; the web download boundary.

### Fix 6 — `reloadContent`'s generation bump (Minor)

- Remove `++_generation` at `:515` (M11 shows nothing depends on it) or move it
  after the guard, so a no-op `load` cannot orphan the block in flight (PROBE-G).

### Fix 7 — `pause()` no-op returns the queue tail (Minor)

- Return a settled future (`:302`); M14 shows nothing depends on the current
  behaviour, and PROBE-E shows it can hang `NarrationAudioHandler.pause()`.

### Fix 8 — UAT case still missing (Minor)

- Iteration 1 asked for "narrate, return to the library, re-open the same book".
  `uat.md` is unchanged at 19 cases. Add it, plus one for Fix 5 ("re-open a
  downloading web book after chapters land").

---

## 9. Observations (not ranked)

- **The guard's `_state.status != NarrationStatus.initial` clause is unreachable**
  (M2 survives as an equivalent mutant): no state carries a `bookId` with
  `initial` status. Harmless, but it reads as load-bearing and is not.
- Iteration-1 Observations **A** (the "state it once" message is pinned, not
  one-shot), **B** (`NarrationAudioHandler.stop()` cancels its subscription
  permanently), **C** (`AudioFocusMonitor.start()` only runs when the media
  session came up) and **D** (`resetDependencies` does not stop `AudioService`)
  are all unchanged by `22935d0` and still stand.
- **Known and already recorded, not counted as gaps**: the long-paused reclaim
  risk (UAT-16), the `permission_handler` pin at 12, and the criteria that are
  genuinely device-only and covered by `uat.md` rather than by automated tests
  (AC2, AC3, and the device halves of AC4, AC6, AC11-AC15, AC18-AC20).

---

## 10. Code Quality

| Principle | Status |
| --- | --- |
| Minimum code | ✅ One production file changed, no new abstraction |
| Surgical changes | ✅ |
| No scope creep | ✅ |
| Matches patterns | ✅ Generation counter, `_serialize` tail future, hand-written fakes, pt-BR strings, English code |
| Spec-anchored outcome check | ⚠️ The BGN-12 test asserts an end status the implementation reaches by another route; it does not assert ordering |
| Per-layer Coverage Expectation | ✅ The data-adapter hole from iteration 1 is closed (`audio_session_interruptions_test.dart`, 9 tests) |
| Every test maps to a spec requirement | ✅ |
| Would a senior engineer approve? | ❌ The queue would be sent back: it is held across an `await` on speech in `_navigate`, which is the one thing the design's own comment says must not happen |
| Documented guidelines followed | ✅ `CLAUDE.md` |

---

## Summary

**Overall**: ❌ Not Ready — iteration 2 of a maximum 3.

**Spec-anchored check**: 17/19 P1 criteria matched the spec outcome (up from 15).
AC13, AC16's attach half, AC17 and AC19 are now genuinely covered. AC7 regressed.
**Sensor**: 9/14 mutations killed, 5 survived (1 equivalent).
**Gate**: 729 passed, 0 failed, 0 skipped; analyze clean; APK built.

**What works**: Five of the six iteration-1 gaps are properly closed, not papered
over — every mutant that survived in iteration 1 now dies, the adapter that had
no test at all has nine, and the AC13 test asserts the spec's outcome rather
than the mutation's shape. The same-book guard, the `load`-time engine stop and
the visible `stop()` are all correct for the cases they were written for.

**Issues found**: The command queue is the one change that was not verified as
carefully as it was designed. It holds the queue across a paragraph of speech in
`_navigate`, which silently un-fixes `pause()` after a skip — a regression
against the parent commit, proven by running the same probe on both. The queue
itself is invisible to the suite: deleting it entirely leaves all 729 tests
green. And the guard that closed the re-entry blocker uses a run id that web
downloads deliberately keep stable, so it freezes a downloading book's queue on
re-entry.

**Next steps**: Fix 1 first — it is a regression on a P1 criterion and the fix is
the same split the author already applied to `play()`. Fix 2 alongside it, or the
next iteration will have the same blind spot. Then Fixes 3-5. Re-verify before
the device UAT run, and add the two missing UAT cases.
