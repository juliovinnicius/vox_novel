# Library and Import Validation

**Date**: 2026-07-17
**Spec**: `.specs/features/library_import/spec.md`
**Diff range**: `e40c552..3ad8dfe`
**Verifier**: independent sub-agent (author ≠ verifier)

---

## Task Completion

| Task | Status | Notes |
| ---- | ------ | ----- |
| T1–T14 | ✅ Done | All task bodies are marked complete and the range contains one matching implementation commit per task. Outcome gaps below prevent feature verification. |

## Spec-Anchored Acceptance Criteria

### LIB-01 — Import a PDF into private storage

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| Import action opens a PDF-only picker | One selection, custom type, allowed extension exactly `pdf` | `test/features/import_book/data/services/file_picker_pdf_picker_test.dart:27` — `expect(capturedAllowMultiple, isFalse)`; `:28` — `expect(capturedType, FileType.custom)`; `:29` — `expect(capturedAllowedExtensions, ['pdf'])` | ✅ PASS |
| Cancellation leaves the library unchanged with no error | `selecting → idle`, no error payload | `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:39` — `expectLater(cubit.stream, emitsInOrder([selecting, idle]))` | ✅ PASS |
| Invalid path leaves library/storage unchanged and shows the standard error | Typed validation failure; no active partial/insert; exact `Não foi possível importar este PDF` | `test/features/import_book/data/services/local_book_file_storage_test.dart:77` — `expectLater(... throwsA(...having(kind, kind)))`; `test/features/import_book/domain/services/import_book_service_test.dart:103` — exact exception-message matcher; `:114` — `expect(storage.partialActive, isFalse)`; `:118` — `expect(repository.inserted, isNull)`; `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:56` — exact error text | ✅ PASS |
| Valid PDF is hashed and copied uniquely without file work on the UI isolate | Exact SHA-256/private copy and filesystem pipeline executed off the UI isolate | `test/features/import_book/data/services/local_book_file_storage_test.dart:53` proves the digest and `:124-127` prove copy outcomes, but no test asserts isolate execution and production calls the storage pipeline directly | ❌ GAP |
| Successful copy persists one exact initial book | Exact ID/title/null author/null cover/name/path/hash/`importing`/0/timestamps | `test/features/import_book/domain/services/import_book_service_test.dart:27` — whole-`Book` equality with every required field; `:43` — `expect(repository.inserted, result)` | ✅ PASS |
| Copy/persistence failure compensates and shows standard error | No partial copy or inserted row; exact error | `test/features/import_book/domain/services/import_book_service_test.dart:103-119` — exact exception, `partialActive == false`, old file retained when applicable, no insert; `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:55-56` — idle plus exact message | ✅ PASS |
| Active import indicates busy, disables import, remains responsive | Indeterminate progress, null action callback, frame can pump while import awaits | `test/features/library/presentation/pages/library_page_test.dart:54-60` — pumps pending import, finds `LinearProgressIndicator`, asserts `button.onPressed == null`; `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:79-82` — readable importing state while pending | ✅ PASS |

### LIB-02 — Replace duplicate content safely

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| New hash creates one new book | Exact inserted result, no replacement | `test/features/import_book/domain/services/import_book_service_test.dart:27-44` — exact new book, inserted same result, exact validate/stage/commit sequence | ✅ PASS |
| Existing hash preserves identity and metadata while replacing approved fields | Stable ID/created/title/author/cover; new name/path/hash/time; `importing`; zero progress | `test/features/import_book/domain/services/import_book_service_test.dart:62` — whole-`Book` equality against `existing.copyWith(...)`; `:73` — exact stable ID | ✅ PASS |
| Superseded PDF is deleted only after new file and row are durable | Backup → commit → repository replacement → backup discard | `test/features/import_book/domain/services/import_book_service_test.dart:74-81` — exact storage event order and `replacementCompletedBeforeCleanup == true` | ✅ PASS |
| Failed replacement restores existing record/file and removes partial replacement | Exact standard failure, no partial active file, old file available, no new insert | `test/features/import_book/domain/services/import_book_service_test.dart:85-119` — all duplicate failure points assert compensation outcomes | ✅ PASS |
| Concurrent imports execute only the first | Picker invoked once during selecting and importing | `test/features/import_book/presentation/cubit/import_book_cubit_test.dart:65-68` and `:77-82` — second calls leave pending state and `expect(picker.calls, 1)` | ✅ PASS |

### LIB-03 — Browse the local library

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| Empty library shows exact copy and accessible import action | `Sua biblioteca está vazia`; `Importar PDF` | `test/features/library/presentation/pages/library_page_test.dart:23-25` — exact visible strings | ✅ PASS |
| Every persisted book renders once with title, optional author, and exact status label | Exact localized label for each possible persisted status | `test/features/library/presentation/widgets/book_item_test.dart:32-34` covers title/author and only `Importando`; no assertion covers `Processando`, `Pronto`, `Falhou`, or `Não suportado` | ❌ GAP |
| Grid shows same ordered books in exactly two columns | Same IDs once, unchanged order/data, `crossAxisCount == 2` | `test/features/library/presentation/pages/library_page_test.dart:35-44` — same keyed IDs before/after and exact column count; `test/features/library/presentation/cubit/library_cubit_test.dart:35-36` — exact books preserved | ✅ PASS |
| List shows same ordered books in one column | Layout becomes list and exact book collection is preserved | `test/features/library/presentation/cubit/library_cubit_test.dart:37-39` — exact list layout and same books | ✅ PASS |
| Restart loads persisted books newest-first and defaults to list | Fresh application/cubit over persistent storage, ordered by latest update | `test/features/library/data/repositories/drift_book_repository_test.dart:38-41` proves ordering and `test/features/library/presentation/cubit/library_cubit_test.dart:40` proves a new Cubit defaults to list, but no restart/persistence conjunction is exercised | ❌ GAP |
| First query and visible result complete within two seconds | Observable result latency `< 2s` under normal local conditions | No timing assertion | ❌ GAP |

### LIB-04 — Edit book metadata

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| Edit form contains current title and author | Input values equal the selected book's current `Title` and `Author` | `test/features/library/presentation/widgets/book_dialogs_test.dart:23-24` only finds fields by label text; it does not inspect controller/input values | ❌ GAP |
| Valid save persists trimmed values, updates time, and displays them | Exact trimmed title/author/timestamp and visible title | `test/features/library/domain/services/library_service_test.dart:25-26` — success and exact payload tuple; `test/widget_test.dart:126` — exact visible renamed title | ✅ PASS |
| Empty title shows exact validation and changes nothing | `Informe o título`; no repository mutation/dialog close | `test/features/library/domain/services/library_service_test.dart:43-45` — failure, exact text, no mutation; `test/features/library/presentation/widgets/book_dialogs_test.dart:28` — exact visible validation | ✅ PASS |
| Persistence failure retains old values and shows exact save error | Old record/collection plus `Não foi possível salvar as alterações` | `test/features/library/domain/services/library_service_test.dart:67-69` — exact failure/message/original book; `test/features/library/presentation/cubit/library_cubit_test.dart:56-57` — old collection plus exact message | ✅ PASS |
| Cancel returns without changing persisted metadata | Dialog returns no edit and repository receives no mutation | No cancellation action or post-cancel mutation assertion; the combined test name says “cancels” but lines 21-34 only validate and save | ❌ GAP |

### LIB-05 — Delete a complete local book

| Criterion | Spec-defined outcome | `file:line` + assertion | Result |
| --------- | -------------------- | ----------------------- | ------ |
| Confirmation names the book | Dialog contains exact selected title | `test/features/library/presentation/widgets/book_dialogs_test.dart:51` — `expect(find.textContaining('Title'), findsOneWidget)` | ✅ PASS |
| Cancellation preserves record and all files | Typed false/cancel result and unchanged repository/files | No cancellation action or unchanged-payload assertion; lines 52-54 exercise confirmation only | ❌ GAP |
| Confirmation removes record, private PDF, and owned cover before visible removal | Row absent and both owned files permanently absent before success | Happy-path assertions exist at `test/features/library/domain/services/library_service_test.dart:89-92` and PDF integration at `test/widget_test.dart:134-135`, but `test/features/library/domain/services/library_service_test.dart:149-151` explicitly accepts success with quarantined files still present after cleanup failure | ❌ GAP |
| Any owned-file deletion failure restores/keeps record and reports exact error | `success == false`, exact delete error, original row/files retained | Pre-commit failures pass at `test/features/library/domain/services/library_service_test.dart:108-112` and `:130-133`; however post-commit deletion failure asserts the opposite at `:149-151` (`success == true`, row null, quarantine remains) | ❌ GAP |
| Success survives restart with no referenced owned file remaining | Durable row absence and zero referenced PDF/cover/trash files | `test/widget_test.dart:134-135` proves visible row/PDF absence in one running app, but no restart, cover, or cleanup-failure assertion; `test/features/library/domain/services/library_service_test.dart:149-151` permits remaining quarantined files | ❌ GAP |

**Status**: ❌ 18/28 acceptance criteria match the spec-defined outcome; 10 have evidence or outcome gaps.

## Edge Cases

| Edge case | Evidence | Result |
| --------- | -------- | ------ |
| Filename exactly `.pdf` uses `Livro sem título` | `test/features/library/domain/entities/book_test.dart:20` — exact fallback equality | ✅ PASS |
| Empty readable PDF imports | `test/features/import_book/data/services/local_book_file_storage_test.dart:30-33` — exact empty SHA-256 | ✅ PASS |
| Source disappears before/during copy rolls back with standard error | Failure matrix `test/features/import_book/domain/services/import_book_service_test.dart:85-119` proves compensation, but no real mid-stream disappearance payload is injected | ❌ GAP |
| Insufficient private storage rolls back with standard error | Generic stage/commit failure matrix proves service compensation but no disk-full-shaped adapter failure is asserted | ❌ GAP |
| Import/edit/replace/delete observation emits one ordered collection without duplicate IDs | `test/features/library/data/repositories/drift_book_repository_test.dart:40-41` proves order/unique IDs and `:145-162` proves no failed-transaction intermediate emission; no test covers one emission for every named mutation | ❌ GAP |
| Empty cover path is skipped while deletion succeeds | No test uses `coverPath: ''` and asserts PDF/row deletion | ❌ GAP |
| Already-missing owned file counts as deleted | `test/features/import_book/data/services/local_book_file_storage_test.dart:203-205` completes missing owned removal without error | ✅ PASS |

## Discrimination Sensor

All mutations ran in a disposable `/tmp` copy; the real implementation/tests were not modified.

| Mutation | Production location | Description | Killed? |
| -------- | ------------------- | ----------- | ------- |
| M1 | `lib/features/import_book/domain/services/import_book_service.dart:69` | Replaced successful duplicate backup discard with restore, violating replacement cleanup/rollback behavior | ✅ Killed by `import_book_service_test.dart:74` and cleanup-failure expectation at `:103` |
| M2 | `lib/features/import_book/data/services/local_book_file_storage.dart:203` | Disabled canonical owned-root rejection, allowing external/traversal deletion | ✅ Killed by `local_book_file_storage_test.dart:192-200` |
| M3 | `lib/features/import_book/presentation/cubit/import_book_cubit.dart:14` | Inverted the idle guard, breaking first-call execution/single-flight behavior | ✅ Killed by `import_book_cubit_test.dart:29`, `:66`, and `:79` |

**Sensor depth**: lightweight, three high-risk behavior mutations  
**Result**: 3/3 killed — PASS ✅

## Payload, Conjunction, and Test-Necessity Checks

- **Payload rule**: Exact whole-`Book`, metadata tuple, error strings, state sequences, ordering, and file-state assertions are present for the covered flows. Gaps are recorded where tests only locate controls/labels instead of asserting current input values or cancelled-operation payloads.
- **Conjunction rule**: Restart + persistence + ordering, and successful deletion + permanent cleanup + restart, are not exercised as joined outcomes. Component-level assertions were not treated as full evidence for those criteria.
- **Test necessity/discrimination**: The three highest-risk targeted mutations were killed. Feature tests otherwise map to an acceptance criterion, listed edge case, task done-when, schema/migration requirement, or composition contract. No feature test deletion or weakened pre-feature assertion was found in the diff.

## Code Quality

| Principle | Status |
| --------- | ------ |
| Minimum code / no unnecessary flexibility | ✅ |
| Surgical scope / no unrelated refactor | ✅ |
| Matches project patterns | ✅ |
| Spec-anchored asserted outcomes | ❌ Post-commit owned-file cleanup failure is asserted as success contrary to LIB-05 |
| Per-layer coverage expectations | ❌ Missing isolate, status variants, restart/performance, cancellation, and several filesystem edge payloads |
| Every in-scope test has a requirement/done-when claim | ✅ |
| Documented guidelines followed | ✅ `analysis_options.yaml`, `.github/workflows/ci.yml`, `docs/spec.md` |
| Senior-engineer approval | ❌ Data-lifecycle failure can be presented as successful deletion |

## Gate Check

- **Gate command**: `dart run build_runner build && flutter analyze && flutter test && flutter build apk --debug`
- **Result**: PASS — build_runner current; analyze 0 issues; 96 passed, 0 failed, 0 skipped; debug APK built
- **Test count before feature (`e40c552`)**: 24
- **Test count after feature (`3ad8dfe`)**: 96
- **Delta**: +72 tests
- **Skipped tests**: none
- **Failures**: none

## Fix Plans

### Fix 1 — Make permanent owned-file cleanup part of deletion success

- **Root cause**: `LibraryService.deleteBook` catches `discardQuarantine` failure and returns success after deleting the row, leaving quarantined application-owned files.
- **Fix task**: Define and implement a recoverable commit boundary that returns the exact delete error and restores/retains the row and owned files whenever permanent cleanup fails; add an integration assertion for PDF, cover, row, visible state, and restart.
- **Priority**: Blocker

### Fix 2 — Prove file work is off the UI isolate

- **Root cause**: The storage service is called directly and no seam/test distinguishes UI-isolate execution from background execution.
- **Fix task**: Add the designed isolate-capable execution boundary and a test that records/asserts isolate identity while preserving pending-frame responsiveness.
- **Priority**: Major

### Fix 3 — Close presentation and lifecycle coverage gaps

- **Root cause**: Tests assert only the importing label, field labels rather than initial values, and confirmation paths rather than cancellation; restart/performance conjunctions are absent.
- **Fix task**: Add exact assertions for all five localized statuses, current edit input values, edit/delete cancellation with unchanged repository/files, fresh-app persistence/order/default layout, and `<2s` visible-result latency.
- **Priority**: Major

### Fix 4 — Close remaining filesystem edge payload gaps

- **Root cause**: Generic failure fakes do not establish mid-stream source disappearance, disk-full behavior, empty-cover deletion, or exactly-one observation for each mutation type.
- **Fix task**: Add adapter/service tests with those exact injected failures and filesystem/stream payload assertions.
- **Priority**: Minor

## Requirement Traceability Update

| Requirement | Previous status | Validation status |
| ----------- | --------------- | ----------------- |
| LIB-01 | Implemented | ❌ Needs fix |
| LIB-02 | Implemented | ✅ Verified |
| LIB-03 | Implemented | ❌ Needs fix |
| LIB-04 | Implemented | ❌ Needs fix |
| LIB-05 | Implemented | ❌ Needs fix |

## Summary

**Overall**: ❌ Not Ready

**Spec-anchored check**: 18/28 acceptance criteria matched; 10 gaps  
**Sensor**: 3/3 mutations killed  
**Gate**: 96 passed, 0 failed, 0 skipped; analysis and APK build passed

The core import, duplicate compensation, repository ordering, metadata mutation, and pre-commit deletion rollback paths are strong. The feature cannot pass while a permanent owned-file cleanup failure is reported as successful deletion, and evidence is still missing for the isolate, restart/performance, cancellation, status-label, and several explicit edge-case outcomes.
