# Background Narration Tasks

## Execution Protocol (MANDATORY -- do not skip)

Implement these tasks with the `tlc-spec-driven` skill: **activate it by name and follow its Execute flow and Critical Rules.** Do not search for skill files by filesystem path. The skill is the source of truth for the full flow (per-task cycle, sub-agent delegation, adequacy review, Verifier, discrimination sensor).

**If the skill cannot be activated, STOP and tell the user — do not proceed without it.**

---

**Design**: `.specs/features/background_narration/design.md`
**Spec**: `.specs/features/background_narration/spec.md`
**Status**: Phase 1, 2 and 2b complete. Phase 3 unblocked.

> **T5 and T6 shipped as one commit** (`dd02c48`). They proved inseparable: the
> Cubit cannot take a session the container does not hand it, and the registry's
> ownership contract dies with the change. `onAppLifecyclePause` was kept rather
> than deleted here, so T5 stayed a provably behaviour-preserving refactor;
> removing it is T9's deliberate inversion, where it is tested.

> **T2 is a stop point for Phase 3, not for Phase 2.** It answers whether
> `flutter_tts` keeps speaking once the activity is destroyed. A negative answer
> invalidates Phase 3's premise — that `flutter_tts` renders speech inside the
> `audio_service` handler — and the platform-channel fallback must be decided
> before Phase 3 begins. It does **not** invalidate Phase 2: app-scoped playback
> ownership is required under either approach, and the fallback would swap the
> `NarrationEngine` implementation while leaving `NarrationSession` unchanged.
> (Corrected 2026-08-26; the first draft wrongly gated Phase 2 on this task.)
>
> T2 needs a physical Android device. It is therefore sequenced after Phase 2,
> which needs none.

---

## Test Coverage Matrix

> Generated from codebase, project guidelines, and spec — confirm before Execute. Guidelines found: `CLAUDE.md` (architecture invariants, test conventions: hand-written fakes with no mocking package, real `NativeDatabase` in a temp dir for repositories, fixtures over network) and `.github/workflows/ci.yml` (commands). Conventions sampled from `test/features/narration/**`, `test/app/dependency_injection/configure_dependencies_test.dart`, and `test/architecture/*_test.dart` (source- and platform-config-scanning invariants).

| Code Layer | Required Test Type | Coverage Expectation | Location Pattern | Run Command |
| --- | --- | --- | --- | --- |
| Domain services (`NarrationSession`, `AudioInterruptions` contract) | unit | All branches; 1:1 to spec ACs; every listed edge case has a test | `test/features/narration/domain/**/*_test.dart` | `flutter test` |
| Domain entities / state models | unit | Construction, equality, and every status transition the ACs name | `test/features/narration/domain/entities/*_test.dart` | `flutter test` |
| Data adapters (`NarrationAudioHandler`, `AudioFocusMonitor`) | unit | Happy path plus every failure and interruption kind, over hand-written fakes — never a real foreground service or a device | `test/features/narration/data/services/*_test.dart` | `flutter test` |
| Presentation cubits | unit | Every state transition named in the ACs; existing assertions must survive the refactor unchanged | `test/features/narration/presentation/cubit/*_test.dart` | `flutter test` |
| Presentation widgets (reader host, player bar) | widget | Render plus each interaction and lifecycle path in scope | `test/features/narration/presentation/widgets/*_test.dart` | `flutter test` |
| Composition root wiring | integration | The composed container starts, attaches, and tears down the session | `test/app/dependency_injection/*_test.dart` | `flutter test` |
| Android manifest / platform config | unit | Source-scanning assertions for every required entry (precedent: `macos_pdf_import_entitlements_test.dart`) | `test/architecture/*_test.dart` | `flutter test` |
| Architecture invariants (AD-013 package confinement) | unit | Import-scanning assertion, in the shape used for AD-010 | `test/architecture/*_test.dart` | `flutter test` |
| UAT script (device-only behaviour) | none | Manual checklist; not automatable without hardware | `.specs/features/background_narration/uat.md` | — |

## Gate Check Commands

> Generated from `.github/workflows/ci.yml` — confirm before Execute.

| Gate Level | When to Use | Command |
| --- | --- | --- |
| Quick | After tasks with unit/widget tests only | `flutter test <task's test paths>` |
| Full | After tasks with integration tests, or any task touching shared narration code | `flutter test` |
| Build | After phase completion, or config/manifest-only tasks | `flutter analyze && flutter test && flutter build apk --debug` |

---

## Execution Plan

Phases are ordered and run sequentially — each phase completes before the next begins, and tasks within a phase execute in order.

### Phase 1: Platform ground

```
T1
```

### Phase 2: Session extraction (parity)

```
T3 → T4 → T5 → T6
```

### Phase 2b: The unknown (device-gated stop point)

```
T2
```

### Phase 3: Platform surface

```
T7 → T8 → T9 → T10 → T11
```

### Phase 4: Edges, P2, and hand verification

```
T12 → T16 → T13 → T14 → T15
```

---

## Task Breakdown

### T1: Declare the media service in the Android manifest

**What**: Add `audio_service` and `audio_session` to the project and declare every manifest entry the media service needs.
**Where**: `pubspec.yaml`, `android/app/src/main/AndroidManifest.xml`, `test/architecture/background_narration_platform_test.dart`
**Depends on**: None
**Reuses**: The platform-config scanning pattern in `test/architecture/macos_pdf_import_entitlements_test.dart`
**Requirement**: BGN-02

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `audio_service` and `audio_session` resolve and are declared in `pubspec.yaml`
- [ ] The manifest declares `WAKE_LOCK`, `FOREGROUND_SERVICE`, and `FOREGROUND_SERVICE_MEDIA_PLAYBACK`
- [ ] The manifest declares the audio service with `android:foregroundServiceType="mediaPlayback"` and a `MediaButtonReceiver`
- [ ] A test asserts each of those entries is present, so removing one fails the suite
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`
- [ ] Test count: >=4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: build
**Commit**: `build(narration): declare the android media service`

---

### T2: Answer whether flutter_tts survives the activity (SPIKE — stop point)

**What**: Build the smallest possible handler that speaks on a loop through `flutter_tts` under `audio_service`, run it on a physical device, and record whether speech continues after the app is swiped out of recents and whether media buttons reach the session.
**Where**: `.specs/features/background_narration/design.md` (Research Findings — replace the "Unknown" row with the measured answer), throwaway spike code that is **not** committed
**Depends on**: T1 (sequenced after Phase 2 because it needs a physical device)
**Reuses**: `FlutterTtsNarrationEngine`
**Requirement**: BGN-01, BGN-15

**Tools**: MCP: NONE · Skill: `run` (to launch the app on a device)

**Done when**:
- [ ] The design's Research Findings row states, as measured fact, whether speech continues after the activity is destroyed
- [ ] It records whether media buttons reached the session, and whether `AudioService.androidForceEnableMediaButtons()` was needed
- [ ] Device model, Android version, and commit are recorded alongside the result
- [ ] If either answer is negative, the task STOPS and reports; the platform-channel fallback is decided with the user before Phase 3 begins
- [ ] No spike code remains in the tree
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`

**Tests**: none — device-only measurement; nothing shippable is produced
**Gate**: build
**Commit**: `docs(background-narration): record the tts background spike`

---

### T3: Add the narration session state model

**What**: Introduce `NarrationSessionState` — the single value every surface renders.
**Where**: `lib/features/narration/domain/entities/narration_models.dart`
**Depends on**: T1
**Reuses**: `NarrationStatus`, `NarrationQueueEntry`, and the `_unset` sentinel `copyWith` pattern used across this codebase
**Requirement**: BGN-06

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The model carries status, book id, book title, current entry, `awaitsDownload`, and message
- [ ] `copyWith` distinguishes "not supplied" from an explicit null, matching the project's sentinel pattern
- [ ] Equality and `hashCode` cover every field
- [ ] Gate check passes: `flutter test test/features/narration/domain`
- [ ] Test count: >=4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): add the session state model`

---

### T4: Extract NarrationSession from the Cubit

**What**: Move playback ownership — queue, engine, generation counters, voice repair, speech-failure handling, download-boundary reload, and progress persistence — out of `NarrationCubit` into an application-scoped `NarrationSession`.
**Where**: `lib/features/narration/domain/services/narration_session.dart`
**Depends on**: T3
**Reuses**: `NarrationQueue`, `NarrationEngine`, `NarrationRepository`, `NarrationSettingsResolver`, and the playback logic in `narration_cubit.dart` verbatim where possible
**Requirement**: BGN-03, BGN-05, BGN-13, BGN-18

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `load`, `play`, `pause`, `next`, `previous`, `stop`, `stream`, and `state` exist per the design
- [ ] `play` and `pause` are idempotent — a second call in the same state changes nothing and speaks nothing
- [ ] `next` and `previous` move exactly one block and start the destination block from its beginning
- [ ] `next` on the final block keeps the completed state and does not wrap or speak
- [ ] `load` on a different book stops the previous session before starting
- [ ] Progress is persisted on the same transitions the Cubit persists on today
- [ ] The download boundary still reloads content exactly once and reports awaiting-download rather than end-of-book
- [ ] Commands are serialized so two arriving together apply in arrival order
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=18 tests pass (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `refactor(narration): extract the playback session`

---

### T5: Make NarrationCubit a session client

**What**: Reduce the Cubit to presentation state — render `sessionStream` into `NarrationState` and forward UI intent — and delete `onAppLifecyclePause`.
**Where**: `lib/features/narration/presentation/cubit/narration_cubit.dart`
**Depends on**: T4
**Reuses**: The existing `NarrationState` shape, so the player bar and settings sheet are untouched
**Requirement**: BGN-01, BGN-06, BGN-16, BGN-17

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The Cubit no longer owns the engine, the queue, generation counters, or progress writing
- [ ] Attaching to a session already playing adopts its exact state rather than a restored one, with no restart of speech
- [ ] `onAppLifecyclePause` no longer exists
- [ ] Voice, rate, per-book override, and preview keep working unchanged
- [ ] **Every pre-existing assertion in `narration_cubit_test.dart` passes unchanged** — this is the parity gate for the extraction
- [ ] Gate check passes: `flutter test`
- [ ] Test count: existing narration suite green plus >=6 new tests (no silent deletions)

**Tests**: unit
**Gate**: full
**Commit**: `refactor(narration): drive the cubit from the session`

---

### T6: Register the session in the composition root

**What**: Register `NarrationSession` as an application-scoped singleton and reduce `NarrationCubitRegistry` to an attach point.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`
**Depends on**: T5
**Reuses**: The guarded `if (!locator.isRegistered<T>())` pattern with an optional injection parameter
**Requirement**: BGN-13, BGN-18

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The session is a single application-scoped instance shared by every route
- [ ] Opening two books in sequence produces one session, with the first stopped
- [ ] The registry no longer duplicates ownership; disposal stops the session and releases the engine
- [ ] A test can substitute a fake session through an injection parameter
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=5 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `feat(app): register the narration session`

---

### T7: Implement the media audio handler

**What**: Translate platform media commands into session calls and publish session state to the notification and lock screen.
**Where**: `lib/features/narration/data/services/narration_audio_handler.dart`
**Depends on**: T6, T2
**Reuses**: `sessionStream`; `NarrationQueueEntry.chapterTitle` for the notification's secondary line
**Requirement**: BGN-04, BGN-05, BGN-06, BGN-15

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] `play`, `pause`, `skipToNext`, `skipToPrevious`, and `stop` each call the matching session method exactly once
- [ ] Next and previous move one block, matching the in-app buttons
- [ ] Published metadata names the book on the primary line and the chapter on the secondary line
- [ ] Published playback state follows `sessionStream`, so a state change from the app updates the notification
- [ ] `next` on the final block publishes the completed state and does not wrap
- [ ] Tests drive it through a fake session — no real service, no device
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: >=8 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): add the media audio handler`

---

### T8: Handle audio focus and interruptions

**What**: Add the `AudioInterruptions` domain contract and its `audio_session` implementation, mapping interruptions onto the session.
**Where**: `lib/features/narration/domain/services/audio_interruptions.dart`, `lib/features/narration/data/services/audio_focus_monitor.dart`
**Depends on**: T7
**Reuses**: The adapter-behind-a-domain-interface shape AD-010 established for `WebFetcher`
**Requirement**: BGN-07, BGN-08

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A transient focus loss pauses narration and a returning focus resumes it
- [ ] A permanent focus loss pauses narration and a returning focus does **not** resume it
- [ ] Resuming after any focus loss restarts the interrupted block from its beginning
- [ ] A focus loss while already paused changes nothing and does not cause a resume later
- [ ] Tests drive interruptions through the domain contract with a hand-written fake — no device
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: >=7 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): honor audio focus`

---

### T9: Stop pausing narration when the app backgrounds

**What**: Remove the lifecycle pause from the reader host and rewrite the narration UAT case that asserts the old behaviour.
**Where**: `lib/features/narration/presentation/widgets/reader_narration_host.dart`, `.specs/features/narration/uat.md`
**Depends on**: T8
**Reuses**: The existing host widget and its test
**Requirement**: BGN-01

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Backgrounding the app no longer pauses narration
- [ ] A widget test asserts that an inactive/paused/detached lifecycle event leaves playback running
- [ ] `.specs/features/narration/uat.md` UAT-10 is rewritten to assert the new behaviour, with a note that the inversion is deliberate
- [ ] The host's other responsibilities are unchanged
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: >=4 tests pass (no silent deletions)

**Tests**: widget
**Gate**: quick
**Commit**: `feat(narration): keep speaking in the background`

---

### T10: Start the media session from the composition root

**What**: Initialise `audio_service`, attach the handler and the focus monitor to the session, and tear them down on reset.
**Where**: `lib/app/dependency_injection/configure_dependencies.dart`, `lib/main.dart`
**Depends on**: T9
**Reuses**: The guarded registration and injectable-seam pattern; the `resumeWebDownloads` seam is the precedent for keeping platform work out of widget tests
**Requirement**: BGN-02, BGN-13

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Composition starts the media session and attaches the handler and focus monitor
- [ ] Composition does not block on platform initialisation, and a test can opt out through a seam — awaiting real platform I/O deadlocks widget tests on the fake clock
- [ ] Resetting dependencies stops the session and releases the service
- [ ] The composed container is covered by an integration test using fakes
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`
- [ ] Test count: >=5 tests pass (no silent deletions)

**Tests**: integration
**Gate**: build
**Commit**: `feat(app): start the narration media session`

---

### T11: Confine the media packages to the data layer

**What**: Add the architecture test that keeps `audio_service` and `audio_session` out of domain and presentation (AD-013).
**Where**: `test/architecture/background_narration_architecture_test.dart`
**Depends on**: T10
**Reuses**: The import-scanning shape used for AD-010 in `test/architecture/web_source_architecture_test.dart`
**Requirement**: BGN-06

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] The test scans imports, not type names — a name pattern misses collaborators whose names do not fit it (lesson L-017)
- [ ] Only files under `lib/features/narration/data/` may import `audio_service` or `audio_session`
- [ ] Importing either package into a domain or presentation file fails the suite
- [ ] Gate check passes: `flutter test test/architecture`
- [ ] Test count: >=2 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `test(narration): confine the media packages to data`

---

### T12: Degrade gracefully when the platform says no

**What**: Keep narration working when the foreground service cannot start or the notification permission is denied, stating the limitation once.
**Where**: `lib/features/narration/domain/services/narration_session.dart`, `lib/features/narration/data/services/narration_audio_handler.dart`
**Depends on**: T11
**Reuses**: The existing one-shot `message` field and `clearMessage` path
**Requirement**: BGN-10, BGN-14

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A foreground service that fails to start leaves narration playable in the foreground
- [ ] That failure produces exactly one message, not one per play
- [ ] A denied notification permission still allows playback and produces exactly one message
- [ ] Neither failure leaves a notification claiming playback
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: >=6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): degrade without the media service`

---

### T16: Ask for the notification permission

**What**: Declare `POST_NOTIFICATIONS`, request it when narration first needs the notification, and report once if it is denied.
**Where**: `android/app/src/main/AndroidManifest.xml`, `lib/features/narration/domain/services/notification_permission.dart`, `lib/features/narration/data/services/permission_handler_notifications.dart`, `lib/features/narration/domain/services/narration_session.dart`
**Depends on**: T12
**Reuses**: The one-shot message path added in T12; the adapter-behind-a-domain-interface shape used for `AudioInterruptions`
**Requirement**: BGN-14

**Tools**: MCP: NONE · Skill: NONE

**Origin**: T12 could deliver only half of its card. Neither the project nor
`audio_service` exposes a permission API, so a denial could not be detected —
and the manifest did not even declare the permission, which on Android 13+ means
the media notification may never appear. The user approved adding
`permission_handler` on 2026-08-29 rather than amending the requirement away.

**Done when**:
- [ ] The manifest declares `POST_NOTIFICATIONS`, asserted by the platform test
- [ ] The permission is requested when narration first needs the notification, not at app startup
- [ ] A denial still lets narration play, and states once that controls outside the app are unavailable
- [ ] A granted permission produces no message
- [ ] The permission is requested once per session, not once per block
- [ ] The platform package stays in `features/narration/data/`, per the T11 scan
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`
- [ ] Test count: >=6 tests pass (no silent deletions)

**Tests**: unit
**Gate**: build
**Commit**: `feat(narration): ask for the notification permission`

---

### T13: Pause when the audio output becomes noisy

**What**: Pause narration when wired headphones are unplugged or a Bluetooth device disconnects.
**Where**: `lib/features/narration/domain/services/audio_interruptions.dart`, `lib/features/narration/data/services/audio_focus_monitor.dart`
**Depends on**: T12
**Reuses**: The `AudioInterruptions` contract from T8
**Requirement**: BGN-09 (P2)

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] A becoming-noisy event pauses narration
- [ ] Narration does not continue on the device speaker
- [ ] A becoming-noisy event while paused changes nothing
- [ ] Reconnecting the device does not auto-resume
- [ ] Gate check passes: `flutter test test/features/narration`
- [ ] Test count: >=4 tests pass (no silent deletions)

**Tests**: unit
**Gate**: quick
**Commit**: `feat(narration): pause when the output becomes noisy`

---

### T14: End the session when its book disappears

**What**: Stop the session and tear down its notification when the narrated book is deleted.
**Where**: `lib/features/narration/domain/services/narration_session.dart`, `lib/features/library/domain/services/library_service.dart`
**Depends on**: T13
**Reuses**: The existing deletion path and its cascade
**Requirement**: BGN-13

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Deleting the narrated book stops the session
- [ ] No notification survives the deletion
- [ ] Deleting a different book leaves the session untouched
- [ ] Existing library deletion tests pass unchanged
- [ ] Gate check passes: `flutter test`
- [ ] Test count: >=4 tests pass (no silent deletions)

**Tests**: integration
**Gate**: full
**Commit**: `fix(narration): end the session when its book is deleted`

---

### T15: Write the background narration UAT script

**What**: Produce the device checklist for everything the suite cannot reach — real lock screen, real Bluetooth headset, a real phone call.
**Where**: `.specs/features/background_narration/uat.md`
**Depends on**: T14
**Reuses**: The table format of `.specs/features/narration/uat.md`
**Requirement**: BGN-01, BGN-04, BGN-07, BGN-08, BGN-15

**Tools**: MCP: NONE · Skill: NONE

**Done when**:
- [ ] Every AC that is device-only has a numbered case with an expected result
- [ ] Cases cover: screen locked, app swiped from recents, lock-screen transport controls, a Bluetooth headset, an incoming call, another audio app, and reopening mid-playback
- [ ] Each case states the exact observable outcome, not "works"
- [ ] Gate check passes: `flutter analyze && flutter test && flutter build apk --debug`

**Tests**: none — this task produces a manual checklist, which the coverage matrix lists as `none`
**Gate**: build
**Commit**: `docs(background-narration): add the uat script`

---

## Phase Execution Map

```
Phase 1 → Phase 2 → Phase 2b → Phase 3 → Phase 4

Phase 1:  T1
Phase 2:  T3 ──→ T4 ──→ T5 ──→ T6
Phase 2b: T2   (device-gated stop point)
Phase 3:  T7 ──→ T8 ──→ T9 ──→ T10 ──→ T11
Phase 4:  T12 ──→ T16 ──→ T13 ──→ T14 ──→ T15
```

Execution is strictly sequential — there is no intra-phase parallelism.

**Batch packing** (~7 tasks per worker, whole phases only):

| Batch | Phases | Tasks | Count | Status |
| --- | --- | --- | --- | --- |
| 1 | Phase 1 + Phase 2 | T1, T3–T6 | 5 | Complete |
| — | Phase 2b | T2 | 1 | Complete — spike answered on device 2026-08-28 |
| 2 | Phase 3 | T7–T11 | 5 | Complete |
| 3 | Phase 4 | T12, T16, T13–T15 | 5 | In progress |

Batch 1 fits a single worker budget, so it runs inline. Batch 2 must not be
dispatched until T2 reports.

---

## Task Granularity Check

| Task | Scope | Status |
| --- | --- | --- |
| T1 | 1 manifest + 1 pubspec + its test | ✅ Granular |
| T2 | 1 measurement, no shipped code | ✅ Granular |
| T3 | 1 model | ✅ Granular |
| T4 | 1 service (large, but one cohesive extraction of one existing responsibility) | ⚠️ Fat but atomic — splitting it would leave the Cubit half-owning playback, which is worse |
| T5 | 1 cubit | ✅ Granular |
| T6 | 1 composition-root registration | ✅ Granular |
| T7 | 1 adapter | ✅ Granular |
| T8 | 1 contract + 1 adapter (cohesive pair) | ✅ Granular |
| T9 | 1 widget + 1 doc | ✅ Granular |
| T10 | 1 composition-root wiring | ✅ Granular |
| T11 | 1 architecture test | ✅ Granular |
| T12 | 2 failure paths in 2 files | ✅ Granular |
| T13 | 1 event path | ✅ Granular |
| T14 | 1 lifecycle path | ✅ Granular |
| T15 | 1 document | ✅ Granular |

---

## Diagram-Definition Cross-Check

| Task | Depends On (body) | Diagram Shows | Status |
| --- | --- | --- | --- |
| T1 | None | (phase start) | ✅ Match |
| T3 | T1 | Phase 1 → Phase 2 | ✅ Match |
| T2 | T1 | Phase 2 → Phase 2b | ✅ Match |
| T4 | T3 | T3 → T4 | ✅ Match |
| T5 | T4 | T4 → T5 | ✅ Match |
| T6 | T5 | T5 → T6 | ✅ Match |
| T7 | T6, T2 | Phase 2b → Phase 3 | ✅ Match |
| T8 | T7 | T7 → T8 | ✅ Match |
| T9 | T8 | T8 → T9 | ✅ Match |
| T10 | T9 | T9 → T10 | ✅ Match |
| T11 | T10 | T10 → T11 | ✅ Match |
| T12 | T11 | Phase 3 → Phase 4 | ✅ Match |
| T13 | T12 | T12 → T13 | ✅ Match |
| T14 | T13 | T13 → T14 | ✅ Match |
| T15 | T14 | T14 → T15 | ✅ Match |

No task depends on a later phase.

---

## Test Co-location Validation

| Task | Code Layer Created/Modified | Matrix Requires | Task Says | Status |
| --- | --- | --- | --- | --- |
| T1 | Android manifest / platform config | unit | unit | ✅ OK |
| T2 | none — no shipped code | none | none | ✅ OK |
| T3 | Domain entity | unit | unit | ✅ OK |
| T4 | Domain service | unit | unit | ✅ OK |
| T5 | Presentation cubit | unit | unit | ✅ OK |
| T6 | Composition root | integration | integration | ✅ OK |
| T7 | Data adapter | unit | unit | ✅ OK |
| T8 | Domain service + data adapter | unit | unit | ✅ OK |
| T9 | Presentation widget | widget | widget | ✅ OK |
| T10 | Composition root | integration | integration | ✅ OK |
| T11 | Architecture invariant | unit | unit | ✅ OK |
| T12 | Domain service + data adapter | unit | unit | ✅ OK |
| T13 | Domain service + data adapter | unit | unit | ✅ OK |
| T14 | Domain service + composition | integration | integration | ✅ OK |
| T15 | UAT script | none | none | ✅ OK |

No violations. T2 and T15 are the only `none` entries, and both match a matrix
layer whose required test type is `none` — neither defers another task's tests.
